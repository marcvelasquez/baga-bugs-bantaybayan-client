from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import json
import re
import google.generativeai as genai
from app.core.config import settings

router = APIRouter()

# Configure Gemini
genai.configure(api_key=settings.GEMINI_API_KEY)


class SafetyTip(BaseModel):
    title: str
    description: str
    priority: str  # "high", "medium", "low"


class HandbookRequest(BaseModel):
    weather_description: str
    temperature: float
    precipitation: float
    rain: float
    latitude: float
    longitude: float


class HandbookResponse(BaseModel):
    weather_summary: str
    safety_tips: List[SafetyTip]
    flood_risk_level: str  # "low", "moderate", "high", "severe"


@router.post("/generate", response_model=HandbookResponse)
async def generate_handbook(request: HandbookRequest):
    """
    Generate contextual safety handbook based on current weather conditions
    using Gemini AI
    """
    if not settings.GEMINI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Gemini API key not configured"
        )
    
    try:
        # Create the prompt for Gemini
        prompt = f"""You are a flood safety expert in the Philippines. Based on the current weather conditions, generate a safety handbook with actionable tips.

Current Weather:
- Description: {request.weather_description}
- Temperature: {request.temperature}°C
- Precipitation: {request.precipitation}mm
- Rain: {request.rain}mm
- Location: {request.latitude}, {request.longitude}

Please provide:
1. A brief weather summary (2-3 sentences)
2. 5-7 specific safety tips based on these conditions
3. Flood risk assessment (low/moderate/high/severe)

Format your response as JSON with this structure:
{{
  "weather_summary": "Brief summary here",
  "flood_risk_level": "low/moderate/high/severe",
  "safety_tips": [
    {{
      "title": "Tip title",
      "description": "Detailed description",
      "priority": "high/medium/low"
    }}
  ]
}}

Focus on:
- Flood preparedness and prevention
- Immediate actions to take
- What to avoid
- Emergency contacts and resources
- Specific concerns for the Philippines (monsoon, typhoons, etc.)

Make it practical, actionable, and relevant to the current weather conditions."""

        # Generate content using Gemini
        model = genai.GenerativeModel('gemini-flash-latest')
        response = model.generate_content(prompt)
        
        # Parse the response
        response_text = response.text
        
        # Try to find JSON in the response
        json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if json_match:
            json_str = json_match.group()
            data = json.loads(json_str)
        else:
            # Fallback: try parsing the entire response
            data = json.loads(response_text)
        
        # Validate and return
        return HandbookResponse(
            weather_summary=data.get("weather_summary", "Weather conditions monitored"),
            safety_tips=[
                SafetyTip(**tip) for tip in data.get("safety_tips", [])
            ],
            flood_risk_level=data.get("flood_risk_level", "moderate")
        )
        
    except json.JSONDecodeError as e:
        # Fallback response if JSON parsing fails
        return HandbookResponse(
            weather_summary=f"Current weather: {request.weather_description} at {request.temperature}°C",
            safety_tips=[
                SafetyTip(
                    title="Stay Informed",
                    description="Monitor weather updates and official advisories from PAGASA.",
                    priority="high"
                ),
                SafetyTip(
                    title="Prepare Emergency Kit",
                    description="Keep food, water, flashlight, radio, and first aid supplies ready.",
                    priority="high"
                ),
                SafetyTip(
                    title="Know Evacuation Routes",
                    description="Familiarize yourself with local evacuation centers and routes.",
                    priority="medium"
                ),
                SafetyTip(
                    title="Avoid Flooded Areas",
                    description="Do not walk or drive through floodwaters. Just 6 inches can knock you down.",
                    priority="high"
                ),
                SafetyTip(
                    title="Secure Your Home",
                    description="Clear drainage systems and secure outdoor items that could be swept away.",
                    priority="medium"
                )
            ],
            flood_risk_level="moderate" if request.rain > 5 else "low"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating handbook: {str(e)}"
        )


@router.get("/static-tips", response_model=List[SafetyTip])
async def get_static_tips():
    """
    Get static general safety tips (fallback if AI fails)
    """
    return [
        SafetyTip(
            title="Monitor Weather Updates",
            description="Stay tuned to PAGASA weather bulletins and local news for flood warnings and advisories.",
            priority="high"
        ),
        SafetyTip(
            title="Prepare Emergency Kit",
            description="Keep a waterproof bag with essential items: flashlight, battery-powered radio, first aid kit, important documents, cash, non-perishable food, and drinking water.",
            priority="high"
        ),
        SafetyTip(
            title="Know Your Evacuation Plan",
            description="Identify the nearest evacuation center and plan multiple routes to get there. Keep emergency contact numbers handy.",
            priority="high"
        ),
        SafetyTip(
            title="Never Walk or Drive Through Floods",
            description="Just 15cm (6 inches) of moving water can knock you down. 60cm (2 feet) of water can sweep away most vehicles. Turn around, don't drown!",
            priority="high"
        ),
        SafetyTip(
            title="Secure Your Property",
            description="Clear gutters and drains. Store valuables on higher floors. Move furniture and electronics away from windows and potential flood areas.",
            priority="medium"
        ),
        SafetyTip(
            title="Avoid Electrocution Hazards",
            description="Stay away from downed power lines. Turn off electricity if flooding is imminent. Don't use electrical appliances if you're wet or standing in water.",
            priority="high"
        ),
        SafetyTip(
            title="Store Safe Drinking Water",
            description="Fill clean containers with water before a flood. Flood water is contaminated and unsafe to drink. Boil water if supplies run low.",
            priority="medium"
        ),
        SafetyTip(
            title="Help Your Community",
            description="Check on elderly neighbors and those with special needs. Share verified information through barangay channels.",
            priority="low"
        )
    ]
