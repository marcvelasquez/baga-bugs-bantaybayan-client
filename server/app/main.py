from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import reports, incidents, auth, users, weather, handbook, scenario
from app.core.config import settings
from app.core.database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="BantayBayan Backend API - Flood monitoring and incident reporting system"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(incidents.router, prefix="/api/incidents", tags=["Incidents"])
app.include_router(weather.router, prefix="/api/weather", tags=["Weather"])
app.include_router(handbook.router, prefix="/api/handbook", tags=["Handbook"])
app.include_router(scenario.router, prefix="/api/scenario", tags=["Storm Scenario"])


@app.get("/")
async def root():
    return {
        "message": "BantayBayan API",
        "version": settings.VERSION,
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
