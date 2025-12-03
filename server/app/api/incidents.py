from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app.core.database import get_db
from app.models.models import Incident
from app.schemas.schemas import (
    IncidentCreate, 
    IncidentResponse, 
    IncidentUpdate
)

router = APIRouter()


@router.post("/", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
async def create_incident(incident: IncidentCreate, db: Session = Depends(get_db)):
    """Create a new incident"""
    db_incident = Incident(
        title=incident.title,
        incident_type=incident.incident_type,
        latitude=incident.latitude,
        longitude=incident.longitude,
        description=incident.description,
        severity_score=incident.severity_score,
        affected_area_radius=incident.affected_area_radius
    )
    db.add(db_incident)
    db.commit()
    db.refresh(db_incident)
    return db_incident


@router.get("/", response_model=List[IncidentResponse])
async def get_incidents(
    skip: int = 0,
    limit: int = 100,
    is_active: Optional[bool] = Query(None),
    incident_type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Get all incidents with optional filtering"""
    query = db.query(Incident)
    
    if is_active is not None:
        query = query.filter(Incident.is_active == (1 if is_active else 0))
    
    if incident_type:
        query = query.filter(Incident.incident_type == incident_type)
    
    incidents = query.order_by(Incident.created_at.desc()).offset(skip).limit(limit).all()
    return incidents


@router.get("/active", response_model=List[IncidentResponse])
async def get_active_incidents(db: Session = Depends(get_db)):
    """Get all active incidents"""
    incidents = db.query(Incident).filter(
        Incident.is_active == 1
    ).order_by(Incident.severity_score.desc()).all()
    return incidents


@router.get("/{incident_id}", response_model=IncidentResponse)
async def get_incident(incident_id: int, db: Session = Depends(get_db)):
    """Get a specific incident by ID"""
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident not found"
        )
    return incident


@router.put("/{incident_id}", response_model=IncidentResponse)
async def update_incident(
    incident_id: int, 
    incident_update: IncidentUpdate, 
    db: Session = Depends(get_db)
):
    """Update an incident"""
    db_incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not db_incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident not found"
        )
    
    update_data = incident_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "is_active":
            setattr(db_incident, field, 1 if value else 0)
        else:
            setattr(db_incident, field, value)
    
    db_incident.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_incident)
    return db_incident


@router.delete("/{incident_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_incident(incident_id: int, db: Session = Depends(get_db)):
    """Delete an incident"""
    db_incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not db_incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident not found"
        )
    
    db.delete(db_incident)
    db.commit()
    return None
