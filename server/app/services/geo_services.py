from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.models import Report, Incident, IncidentType
from math import radians, cos, sin, asin, sqrt


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees).
    Returns distance in meters.
    """
    # Convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    
    # Radius of earth in meters
    r = 6371000
    return c * r


def find_nearby_reports(
    db: Session,
    latitude: float,
    longitude: float,
    radius_meters: float = 1000,
    incident_type: Optional[IncidentType] = None
) -> List[Report]:
    """
    Find reports within a certain radius of a given location.
    """
    query = db.query(Report)
    
    if incident_type:
        query = query.filter(Report.incident_type == incident_type)
    
    all_reports = query.all()
    
    # Filter by distance
    nearby_reports = []
    for report in all_reports:
        distance = haversine_distance(latitude, longitude, report.latitude, report.longitude)
        if distance <= radius_meters:
            nearby_reports.append(report)
    
    return nearby_reports


def cluster_reports_to_incident(
    db: Session,
    reports: List[Report],
    min_reports: int = 3
) -> Optional[Incident]:
    """
    Cluster nearby reports into a single incident if there are enough reports.
    """
    if len(reports) < min_reports:
        return None
    
    # Calculate average position
    avg_lat = sum(r.latitude for r in reports) / len(reports)
    avg_lon = sum(r.longitude for r in reports) / len(reports)
    
    # Determine incident type based on majority
    type_counts = {}
    for report in reports:
        type_counts[report.incident_type] = type_counts.get(report.incident_type, 0) + 1
    
    incident_type = max(type_counts, key=type_counts.get)
    
    # Calculate severity based on report count and types
    severity_score = len(reports) * 10
    if incident_type == IncidentType.CRITICAL:
        severity_score *= 2
    elif incident_type == IncidentType.WARNING:
        severity_score *= 1.5
    
    # Create incident
    incident = Incident(
        title=f"{incident_type.value.title()} Incident - {len(reports)} reports",
        incident_type=incident_type,
        latitude=avg_lat,
        longitude=avg_lon,
        description=f"Clustered from {len(reports)} reports",
        severity_score=min(severity_score, 100),
        report_count=len(reports)
    )
    
    db.add(incident)
    db.commit()
    db.refresh(incident)
    
    return incident


def calculate_incident_severity(
    report_count: int,
    incident_type: IncidentType,
    affected_population: Optional[int] = None
) -> float:
    """
    Calculate severity score for an incident based on various factors.
    Returns a score between 0-100.
    """
    base_score = min(report_count * 5, 50)
    
    # Type multiplier
    type_multipliers = {
        IncidentType.INFO: 0.5,
        IncidentType.WARNING: 1.0,
        IncidentType.CRITICAL: 2.0
    }
    
    score = base_score * type_multipliers.get(incident_type, 1.0)
    
    # Population factor (if available)
    if affected_population:
        population_factor = min(affected_population / 1000, 30)
        score += population_factor
    
    return min(score, 100.0)
