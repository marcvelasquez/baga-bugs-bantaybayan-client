from fastapi import APIRouter, HTTPException
import httpx
from typing import Optional
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

# Import scenario module to check if storm scenario is active
try:
    from app.api import scenario
except ImportError:
    scenario = None


class WeatherResponse(BaseModel):
    latitude: float
    longitude: float
    temperature: float  # Celsius
    humidity: Optional[float] = None
    precipitation: float  # mm
    rain: float  # mm
    weather_code: int
    wind_speed: float  # km/h
    wind_direction: Optional[float] = None
    timestamp: str
    description: str


def get_weather_description(weather_code: int) -> str:
    """Convert WMO weather code to description"""
    weather_codes = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Foggy",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        56: "Light freezing drizzle",
        57: "Dense freezing drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        66: "Light freezing rain",
        67: "Heavy freezing rain",
        71: "Slight snow",
        73: "Moderate snow",
        75: "Heavy snow",
        77: "Snow grains",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        85: "Slight snow showers",
        86: "Heavy snow showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail",
    }
    return weather_codes.get(weather_code, "Unknown")


@router.get("/current", response_model=WeatherResponse)
async def get_current_weather(latitude: float, longitude: float):
    """
    Get current weather conditions for a specific location using Open-Meteo API
    
    - **latitude**: Latitude of the location
    - **longitude**: Longitude of the location
    
    Note: If storm scenario is active, returns simulated typhoon data instead.
    """
    # Check if scenario mode is active
    if scenario and hasattr(scenario, 'is_scenario_active') and scenario.is_scenario_active():
        scenario_data = scenario.get_scenario_weather_data(latitude, longitude)
        return WeatherResponse(**scenario_data)
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # Open-Meteo API endpoint
            url = "https://api.open-meteo.com/v1/forecast"
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "current": [
                    "temperature_2m",
                    "relative_humidity_2m",
                    "precipitation",
                    "rain",
                    "weather_code",
                    "wind_speed_10m",
                    "wind_direction_10m"
                ],
                "timezone": "auto"
            }
            
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            
            current = data.get("current", {})
            weather_code = current.get("weather_code", 0)
            
            return WeatherResponse(
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                temperature=current.get("temperature_2m", 0.0),
                humidity=current.get("relative_humidity_2m"),
                precipitation=current.get("precipitation", 0.0),
                rain=current.get("rain", 0.0),
                weather_code=weather_code,
                wind_speed=current.get("wind_speed_10m", 0.0),
                wind_direction=current.get("wind_direction_10m"),
                timestamp=current.get("time", datetime.utcnow().isoformat()),
                description=get_weather_description(weather_code)
            )
            
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Failed to fetch weather data: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing weather data: {str(e)}"
        )


@router.get("/forecast", response_model=dict)
async def get_weather_forecast(
    latitude: float,
    longitude: float,
    days: int = 7
):
    """
    Get weather forecast for a specific location
    
    - **latitude**: Latitude of the location
    - **longitude**: Longitude of the location
    - **days**: Number of days to forecast (1-16, default: 7)
    """
    if days < 1 or days > 16:
        raise HTTPException(
            status_code=400,
            detail="Days must be between 1 and 16"
        )
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            url = "https://api.open-meteo.com/v1/forecast"
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "daily": [
                    "temperature_2m_max",
                    "temperature_2m_min",
                    "precipitation_sum",
                    "rain_sum",
                    "weather_code",
                    "wind_speed_10m_max"
                ],
                "forecast_days": days,
                "timezone": "auto"
            }
            
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            
            # Format the forecast data
            daily = data.get("daily", {})
            forecast_days = []
            
            for i in range(len(daily.get("time", []))):
                weather_code = daily["weather_code"][i]
                forecast_days.append({
                    "date": daily["time"][i],
                    "temperature_max": daily["temperature_2m_max"][i],
                    "temperature_min": daily["temperature_2m_min"][i],
                    "precipitation": daily["precipitation_sum"][i],
                    "rain": daily["rain_sum"][i],
                    "weather_code": weather_code,
                    "description": get_weather_description(weather_code),
                    "wind_speed_max": daily["wind_speed_10m_max"][i]
                })
            
            return {
                "latitude": data.get("latitude"),
                "longitude": data.get("longitude"),
                "timezone": data.get("timezone"),
                "forecast": forecast_days
            }
            
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Failed to fetch forecast data: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing forecast data: {str(e)}"
        )
