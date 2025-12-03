from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
import random

router = APIRouter()

# Global state to track if scenario is active
_scenario_active = False


class FloodPrediction(BaseModel):
    location: str
    latitude: float
    longitude: float
    flood_probability: float
    predicted_depth_cm: float
    risk_level: str
    population_affected: int
    evacuation_recommended: bool


class StormScenario(BaseModel):
    scenario_id: str
    storm_name: str
    intensity: str
    current_location: str
    target_area: str
    estimated_landfall: str
    current_weather: dict
    forecast_6h: dict
    forecast_12h: dict
    forecast_24h: dict
    flood_predictions: List[FloodPrediction]
    affected_municipalities: List[str]
    total_population_at_risk: int
    recommended_actions: List[str]


# Pampanga municipalities and their coordinates
PAMPANGA_LOCATIONS = [
    {"name": "Angeles City", "lat": 15.1450, "lon": 120.5887, "pop": 411634},
    {"name": "San Fernando", "lat": 15.0285, "lon": 120.6897, "pop": 327326},
    {"name": "Mabalacat", "lat": 15.2267, "lon": 120.5714, "pop": 250799},
    {"name": "Guagua", "lat": 14.9650, "lon": 120.6333, "pop": 117845},
    {"name": "Mexico", "lat": 15.0667, "lon": 120.7167, "pop": 173403},
    {"name": "Apalit", "lat": 14.9500, "lon": 120.7500, "pop": 117160},
    {"name": "Porac", "lat": 15.0667, "lon": 120.5333, "pop": 140751},
    {"name": "Lubao", "lat": 14.9333, "lon": 120.5833, "pop": 173502},
    {"name": "Candaba", "lat": 15.0833, "lon": 120.8333, "pop": 119497},
    {"name": "Macabebe", "lat": 14.8833, "lon": 120.7000, "pop": 78490},
]


def calculate_flood_risk(rainfall_mm: float, elevation_factor: float, population: int) -> FloodPrediction:
    """
    Simulate ML model predictions based on rainfall and terrain
    """
    # Simulate model prediction based on rainfall intensity
    base_probability = min(0.95, (rainfall_mm / 150.0) * elevation_factor)
    flood_probability = round(base_probability + random.uniform(-0.05, 0.05), 3)
    flood_probability = max(0.0, min(1.0, flood_probability))
    
    # Predict depth based on probability and rainfall
    if flood_probability > 0.7:
        predicted_depth = rainfall_mm * 0.8 * elevation_factor + random.uniform(10, 30)
    elif flood_probability > 0.4:
        predicted_depth = rainfall_mm * 0.5 * elevation_factor + random.uniform(5, 15)
    else:
        predicted_depth = rainfall_mm * 0.2 * elevation_factor + random.uniform(0, 10)
    
    predicted_depth = round(predicted_depth, 1)
    
    # Determine risk level
    if flood_probability >= 0.7 or predicted_depth >= 50:
        risk_level = "CRITICAL"
    elif flood_probability >= 0.5 or predicted_depth >= 30:
        risk_level = "HIGH"
    elif flood_probability >= 0.3 or predicted_depth >= 15:
        risk_level = "MODERATE"
    else:
        risk_level = "LOW"
    
    # Calculate affected population
    affected_ratio = min(1.0, flood_probability * 1.2)
    population_affected = int(population * affected_ratio)
    
    return flood_probability, predicted_depth, risk_level, population_affected


@router.get("/storm-scenario", response_model=StormScenario)
async def get_storm_scenario():
    """
    Simulate a typhoon scenario hitting Pampanga with realistic weather and flood predictions
    """
    
    # Storm details
    scenario = {
        "scenario_id": "TY-SIMULATED-2025",
        "storm_name": "Typhoon Rosing",
        "intensity": "Severe Tropical Storm",
        "current_location": "West Philippine Sea, 200km west of Zambales",
        "target_area": "Central Luzon (Pampanga)",
        "estimated_landfall": (datetime.now() + timedelta(hours=6)).strftime("%Y-%m-%d %H:%M"),
    }
    
    # Current weather (storm approaching)
    current_weather = {
        "temperature": 26.5,
        "rainfall": 15.2,
        "rainfall_6h": 45.8,
        "wind_speed": 65.0,
        "wind_gusts": 85.0,
        "pressure": 985.0,
        "humidity": 92,
        "weather_code": 95,  # Thunderstorm
        "description": "Heavy rain and strong winds as typhoon approaches",
        "visibility": 2.5
    }
    
    # 6-hour forecast (landfall)
    forecast_6h = {
        "temperature": 24.8,
        "rainfall": 85.5,
        "rainfall_cumulative": 131.3,
        "wind_speed": 95.0,
        "wind_gusts": 125.0,
        "pressure": 975.0,
        "humidity": 95,
        "weather_code": 95,
        "description": "Intense rainfall and damaging winds - LANDFALL",
        "visibility": 1.0
    }
    
    # 12-hour forecast (peak intensity)
    forecast_12h = {
        "temperature": 23.5,
        "rainfall": 125.0,
        "rainfall_cumulative": 256.3,
        "wind_speed": 110.0,
        "wind_gusts": 145.0,
        "pressure": 970.0,
        "humidity": 97,
        "weather_code": 95,
        "description": "Torrential rain and violent winds - PEAK INTENSITY",
        "visibility": 0.5
    }
    
    # 24-hour forecast (weakening)
    forecast_24h = {
        "temperature": 25.0,
        "rainfall": 45.0,
        "rainfall_cumulative": 301.3,
        "wind_speed": 75.0,
        "wind_gusts": 95.0,
        "pressure": 980.0,
        "humidity": 90,
        "weather_code": 63,
        "description": "Moderate to heavy rain, weakening storm",
        "visibility": 3.0
    }
    
    # Generate flood predictions for each municipality
    flood_predictions = []
    total_population_at_risk = 0
    high_risk_areas = []
    
    for location in PAMPANGA_LOCATIONS:
        # Elevation factor: lower areas more prone to flooding
        # Simulate varying terrain - areas near rivers have lower elevation
        if location["name"] in ["Candaba", "Apalit", "Macabebe", "Guagua"]:
            elevation_factor = 1.8  # Low-lying, near wetlands/rivers
        elif location["name"] in ["Lubao", "Mexico", "San Fernando"]:
            elevation_factor = 1.4  # Moderate elevation
        else:
            elevation_factor = 1.0  # Higher elevation
        
        # Use peak rainfall (12h forecast) for predictions
        peak_rainfall = forecast_12h["rainfall"]
        
        prob, depth, risk, pop_affected = calculate_flood_risk(
            peak_rainfall, 
            elevation_factor, 
            location["pop"]
        )
        
        prediction = FloodPrediction(
            location=location["name"],
            latitude=location["lat"],
            longitude=location["lon"],
            flood_probability=prob,
            predicted_depth_cm=depth,
            risk_level=risk,
            population_affected=pop_affected,
            evacuation_recommended=(risk in ["CRITICAL", "HIGH"])
        )
        
        flood_predictions.append(prediction)
        total_population_at_risk += pop_affected
        
        if risk in ["CRITICAL", "HIGH"]:
            high_risk_areas.append(location["name"])
    
    # Sort by risk level
    risk_order = {"CRITICAL": 0, "HIGH": 1, "MODERATE": 2, "LOW": 3}
    flood_predictions.sort(key=lambda x: (risk_order[x.risk_level], -x.flood_probability))
    
    # Recommended actions
    recommended_actions = [
        "IMMEDIATE: Pre-emptive evacuation of residents in flood-prone areas",
        "IMMEDIATE: Activate all disaster response teams and emergency shelters",
        "Deploy rescue boats and equipment to high-risk municipalities",
        "Suspend classes and work in all affected areas",
        "Monitor water levels in Pampanga River and its tributaries",
        "Coordinate with PAGASA for real-time weather updates",
        "Ensure backup power systems are operational in critical facilities",
        "Stock emergency supplies (food, water, medicine) in evacuation centers",
        "Issue public advisories through all available channels",
        "Restrict movement and travel in affected areas during peak intensity"
    ]
    
    scenario.update({
        "current_weather": current_weather,
        "forecast_6h": forecast_6h,
        "forecast_12h": forecast_12h,
        "forecast_24h": forecast_24h,
        "flood_predictions": flood_predictions,
        "affected_municipalities": [loc["name"] for loc in PAMPANGA_LOCATIONS],
        "total_population_at_risk": total_population_at_risk,
        "recommended_actions": recommended_actions
    })
    
    return scenario


@router.get("/scenario-weather/{latitude}/{longitude}")
async def get_scenario_weather_for_location(latitude: float, longitude: float):
    """
    Get simulated weather data for a specific location during the storm scenario
    """
    # Find nearest municipality
    nearest = min(
        PAMPANGA_LOCATIONS,
        key=lambda loc: ((loc["lat"] - latitude)**2 + (loc["lon"] - longitude)**2)**0.5
    )
    
    distance_km = ((nearest["lat"] - latitude)**2 + (nearest["lon"] - longitude)**2)**0.5 * 111
    
    # Adjust rainfall based on distance (rainfall can vary by location)
    rainfall_factor = max(0.7, 1.0 - (distance_km / 50))
    
    return {
        "location": f"Near {nearest['name']}",
        "latitude": latitude,
        "longitude": longitude,
        "current": {
            "temperature": 26.5,
            "rainfall": round(15.2 * rainfall_factor, 1),
            "wind_speed": 65.0,
            "humidity": 92,
            "weather_code": 95,
            "description": "Heavy rain - Typhoon approaching"
        },
        "forecast_6h_rainfall": round(85.5 * rainfall_factor, 1),
        "forecast_12h_rainfall": round(125.0 * rainfall_factor, 1),
        "forecast_24h_rainfall": round(45.0 * rainfall_factor, 1),
        "cumulative_24h_rainfall": round(270.7 * rainfall_factor, 1),
        "warning": "SEVERE WEATHER WARNING: Typhoon Rosing expected to make landfall in 6 hours"
    }


@router.post("/activate")
async def activate_scenario():
    """
    Activate the storm scenario - this will cause weather and handbook endpoints
    to return simulated typhoon data instead of real data.
    """
    global _scenario_active
    _scenario_active = True
    
    return {
        "status": "activated",
        "message": "🌪️ STORM SCENARIO ACTIVATED! All weather endpoints will now return simulated typhoon data. Users will see extreme weather warnings.",
        "scenario": "Typhoon Rosing - Severe Tropical Storm",
        "timestamp": datetime.now().isoformat(),
        "next_steps": [
            "Weather API will return storm data",
            "Handbook will generate typhoon-specific safety tips",
            "Users will see flood predictions and evacuation warnings"
        ]
    }


@router.post("/deactivate")
async def deactivate_scenario():
    """
    Deactivate the storm scenario and return to normal weather data.
    Notifies users that the storm has passed and weather is improving.
    """
    global _scenario_active
    _scenario_active = False
    
    return {
        "status": "deactivated",
        "message": "✅ Storm scenario deactivated. Typhoon Rosing has passed. Weather conditions improving.",
        "timestamp": datetime.now().isoformat(),
        "recovery_info": {
            "all_clear": True,
            "post_storm_summary": "Typhoon Rosing has moved away from Pampanga. Flood waters receding.",
            "current_conditions": "Weather conditions returning to normal. Rain has stopped.",
            "safety_status": "Safe to exit shelters in non-flooded areas",
            "next_steps": [
                "Assess damage to homes and property",
                "Report remaining flood issues through the app",
                "Avoid damaged power lines and infrastructure",
                "Check for updates from local authorities before returning home",
                "Continue monitoring water levels in previously flooded areas"
            ],
            "warning": "Some areas may still have standing water. Exercise caution."
        }
    }


@router.get("/status")
async def get_scenario_status():
    """
    Check if scenario mode is currently active
    """
    return {
        "active": _scenario_active,
        "scenario": "Typhoon Rosing" if _scenario_active else None,
        "message": "Storm scenario is active" if _scenario_active else "Normal operations"
    }


def is_scenario_active() -> bool:
    """Helper function for other modules to check scenario status"""
    return _scenario_active


def get_scenario_weather_data(latitude: float, longitude: float) -> dict:
    """
    Get scenario weather data for a specific location.
    Called by weather.py when scenario is active.
    """
    if not _scenario_active:
        # Return post-storm conditions
        return get_post_storm_weather_data(latitude, longitude)
    
    # Find nearest municipality
    nearest = min(
        PAMPANGA_LOCATIONS,
        key=lambda loc: ((loc["lat"] - latitude)**2 + (loc["lon"] - longitude)**2)**0.5
    )
    
    distance_km = ((nearest["lat"] - latitude)**2 + (nearest["lon"] - longitude)**2)**0.5 * 111
    rainfall_factor = max(0.7, 1.0 - (distance_km / 50))
    
    return {
        "latitude": latitude,
        "longitude": longitude,
        "temperature": 26.5,
        "humidity": 92.0,
        "precipitation": round(15.2 * rainfall_factor, 1),
        "rain": round(15.2 * rainfall_factor, 1),
        "weather_code": 95,  # Thunderstorm
        "wind_speed": 65.0,
        "wind_direction": 270.0,
        "timestamp": datetime.now().isoformat(),
        "description": f"Heavy rain - Typhoon Rosing approaching (near {nearest['name']})",
        "is_scenario": True,
        "warning": "⚠️ SEVERE WEATHER WARNING: Typhoon expected to make landfall in 6 hours"
    }


def get_post_storm_weather_data(latitude: float, longitude: float) -> dict:
    """
    Get post-storm weather data showing improved conditions.
    Called after scenario is deactivated.
    """
    # Find nearest municipality
    nearest = min(
        PAMPANGA_LOCATIONS,
        key=lambda loc: ((loc["lat"] - latitude)**2 + (loc["lon"] - longitude)**2)**0.5
    )
    
    return {
        "latitude": latitude,
        "longitude": longitude,
        "temperature": 28.5,
        "humidity": 75.0,
        "precipitation": 0.0,
        "rain": 0.0,
        "weather_code": 3,  # Overcast but no rain
        "wind_speed": 15.0,
        "wind_direction": 90.0,
        "timestamp": datetime.now().isoformat(),
        "description": f"Overcast skies - Post-typhoon conditions (near {nearest['name']})",
        "is_scenario": True,
        "warning": None,
        "all_clear": "✅ Typhoon has passed. Weather improving. Some areas may still be flooded."
    }
