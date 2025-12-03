from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime, date
from app.core.database import get_db
from app.models.models import Report, ReportUpvote, IncidentType
from app.schemas.schemas import (
    ReportCreate, 
    ReportResponse, 
    ReportUpdate,
    ReportStats
)
import math

router = APIRouter()


@router.post("/", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(report: ReportCreate, user_id: int = 1, db: Session = Depends(get_db)):
    """Create a new incident report"""
    db_report = Report(
        user_id=user_id,
        incident_type=report.incident_type,
        latitude=report.latitude,
        longitude=report.longitude,
        description=report.description
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    return db_report


@router.get("/", response_model=List[ReportResponse])
async def get_reports(
    skip: int = 0, 
    limit: int = 100,
    incident_type: str = None,
    db: Session = Depends(get_db)
):
    """Get all reports with optional filtering"""
    query = db.query(Report)
    
    if incident_type:
        query = query.filter(Report.incident_type == incident_type)
    
    reports = query.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()
    return reports


@router.get("/stats", response_model=ReportStats)
async def get_report_stats(db: Session = Depends(get_db)):
    """Get statistics about reports"""
    today = date.today()
    
    # Count reports by type
    info_count = db.query(Report).filter(
        Report.incident_type == IncidentType.INFO
    ).count()
    
    critical_count = db.query(Report).filter(
        Report.incident_type == IncidentType.CRITICAL
    ).count()
    
    warning_count = db.query(Report).filter(
        Report.incident_type == IncidentType.WARNING
    ).count()
    
    total_count = db.query(Report).count()
    
    return ReportStats(
        info_count=info_count,
        critical_count=critical_count,
        warning_count=warning_count,
        total_count=total_count,
        date=today.strftime("%b %d, %Y")
    )


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(report_id: int, db: Session = Depends(get_db)):
    """Get a specific report by ID"""
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    return report


@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(
    report_id: int, 
    report_update: ReportUpdate, 
    db: Session = Depends(get_db)
):
    """Update a report"""
    db_report = db.query(Report).filter(Report.id == report_id).first()
    if not db_report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    update_data = report_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_report, field, value)
    
    db_report.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_report)
    return db_report


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(report_id: int, db: Session = Depends(get_db)):
    """Delete a report"""
    db_report = db.query(Report).filter(Report.id == report_id).first()
    if not db_report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    db.delete(db_report)
    db.commit()
    return None


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points in meters using Haversine formula"""
    R = 6371000  # Earth's radius in meters
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


@router.get("/nearby/{latitude}/{longitude}", response_model=List[ReportResponse])
async def get_nearby_reports(
    latitude: float,
    longitude: float,
    radius: float = 100.0,  # Default 100 meters
    incident_type: str = None,
    db: Session = Depends(get_db)
):
    """Get reports within a certain radius of a location"""
    query = db.query(Report)
    
    if incident_type:
        query = query.filter(Report.incident_type == incident_type)
    
    all_reports = query.all()
    
    # Filter by distance
    nearby_reports = []
    for report in all_reports:
        distance = haversine_distance(latitude, longitude, report.latitude, report.longitude)
        if distance <= radius:
            nearby_reports.append(report)
    
    # Sort by distance (closest first)
    nearby_reports.sort(key=lambda r: haversine_distance(latitude, longitude, r.latitude, r.longitude))
    
    return nearby_reports


@router.post("/{report_id}/upvote", response_model=ReportResponse)
async def upvote_report(
    report_id: int,
    user_id: int = 1,  # In production, get from JWT token
    db: Session = Depends(get_db)
):
    """Upvote a report (one upvote per user per report)"""
    # Check if report exists
    db_report = db.query(Report).filter(Report.id == report_id).first()
    if not db_report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    # Check if user already upvoted this report
    existing_upvote = db.query(ReportUpvote).filter(
        ReportUpvote.report_id == report_id,
        ReportUpvote.user_id == user_id
    ).first()
    
    if existing_upvote:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already upvoted this report"
        )
    
    # Create upvote
    new_upvote = ReportUpvote(
        report_id=report_id,
        user_id=user_id
    )
    db.add(new_upvote)
    
    # Increment upvote count
    db_report.upvote_count += 1
    db_report.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(db_report)
    
    return db_report


@router.delete("/{report_id}/upvote", response_model=ReportResponse)
async def remove_upvote(
    report_id: int,
    user_id: int = 1,  # In production, get from JWT token
    db: Session = Depends(get_db)
):
    """Remove an upvote from a report"""
    # Check if report exists
    db_report = db.query(Report).filter(Report.id == report_id).first()
    if not db_report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    # Check if upvote exists
    existing_upvote = db.query(ReportUpvote).filter(
        ReportUpvote.report_id == report_id,
        ReportUpvote.user_id == user_id
    ).first()
    
    if not existing_upvote:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have not upvoted this report"
        )
    
    # Remove upvote
    db.delete(existing_upvote)
    
    # Decrement upvote count
    if db_report.upvote_count > 0:
        db_report.upvote_count -= 1
    db_report.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(db_report)
    
    return db_report
