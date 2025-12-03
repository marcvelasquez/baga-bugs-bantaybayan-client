from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
from enum import Enum


class IncidentType(str, Enum):
    INFO = "info"
    CRITICAL = "critical"
    WARNING = "warning"


# User schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: int
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


# Report schemas
class ReportBase(BaseModel):
    incident_type: IncidentType
    latitude: float
    longitude: float
    description: Optional[str] = None


class ReportCreate(ReportBase):
    pass


class ReportResponse(ReportBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    is_verified: bool
    upvote_count: int

    class Config:
        from_attributes = True


class ReportUpdate(BaseModel):
    incident_type: Optional[IncidentType] = None
    description: Optional[str] = None


# Incident schemas
class IncidentBase(BaseModel):
    title: str
    incident_type: IncidentType
    latitude: float
    longitude: float
    description: Optional[str] = None
    severity_score: Optional[float] = 0.0
    affected_area_radius: Optional[float] = 300.0


class IncidentCreate(IncidentBase):
    pass


class IncidentResponse(IncidentBase):
    id: int
    created_at: datetime
    updated_at: datetime
    is_active: bool
    report_count: int

    class Config:
        from_attributes = True


class IncidentUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    severity_score: Optional[float] = None
    is_active: Optional[bool] = None


# Statistics schemas
class ReportStats(BaseModel):
    info_count: int
    critical_count: int
    warning_count: int
    total_count: int
    date: str
