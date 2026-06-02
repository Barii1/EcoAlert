import os
import logging
from typing import Optional, List

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from services.model_service import model_service, CITY_COORDS

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ecoalert.fastapi")


class CloudburstRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None


class CloudburstFeaturesRequest(BaseModel):
    temperature: float
    humidity: float
    pressure: float
    cloud_cover: float
    wind_speed: float
    dew_point: Optional[float] = None
    city: Optional[str] = None


class AqiRequest(BaseModel):
    pm25: float
    pm10: float
    no2: float
    o3: float
    co: float
    city: Optional[str] = None


app = FastAPI(title="EcoAlert FastAPI (temporary)")

cors_env = os.getenv(
    "CORS_ALLOWED_ORIGINS",
    "http://localhost:3000,http://127.0.0.1:3000",
)
allowed = [o.strip() for o in cors_env.split(",") if o.strip()]
origins = ["*"] if allowed == ["*"] else allowed

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "EcoAlert FastAPI"}


@app.get("/api/predict/status")
def predict_status():
    return model_service.status


@app.post("/api/predict/cloudburst")
def predict_cloudburst(payload: CloudburstRequest):
    city = payload.city or ""
    latitude = payload.latitude
    longitude = payload.longitude

    if (latitude is None or longitude is None) and city:
        coords = model_service.city_to_coords(city)
        if coords:
            latitude, longitude = coords
        else:
            raise HTTPException(
                status_code=400,
                detail={
                    "error": f"Unknown city '{city}'. Supported: {list(CITY_COORDS.keys())}",
                },
            )

    if latitude is None or longitude is None:
        raise HTTPException(
            status_code=400,
            detail={
                "error": "Provide either 'latitude'+'longitude' or a known 'city' name.",
            },
        )

    try:
        return model_service.predict_cloudburst(
            latitude=float(latitude),
            longitude=float(longitude),
            city=city,
        )
    except Exception as exc:
        logger.exception("cloudburst prediction failed")
        raise HTTPException(status_code=500, detail={"error": str(exc)})


@app.post("/api/predict/cloudburst/features")
def predict_cloudburst_features(payload: CloudburstFeaturesRequest):
    data = payload.model_dump()
    city = data.pop("city", "")
    try:
        return model_service.predict_cloudburst_from_features(data, city)
    except Exception as exc:
        logger.exception("cloudburst feature prediction failed")
        raise HTTPException(status_code=500, detail={"error": str(exc)})


@app.post("/api/predict/aqi")
def predict_aqi(payload: AqiRequest):
    data = payload.model_dump()
    city = data.pop("city", "")
    try:
        return model_service.predict_aqi(data, city)
    except Exception as exc:
        logger.exception("aqi prediction failed")
        raise HTTPException(status_code=500, detail={"error": str(exc)})


# ── AI Daily Brief & Chatbot ──────────────────────────────────────────────────

OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
OPENAI_MODEL   = "gpt-4o-mini"   # fast + cheap for this use case


class DailySummaryRequest(BaseModel):
    city: str
    aqi: Optional[int]   = None
    aqi_category: Optional[str] = None
    flood_risk: Optional[str]   = None
    flood_probability: Optional[float] = None
    cloudburst_risk: Optional[str]     = None
    temperature: Optional[float]       = None
    humidity: Optional[float]          = None
    weather_desc: Optional[str]        = None
    health_conditions: List[str]       = []


class ChatMessage(BaseModel):
    role: str    # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    message: str
    city: str
    aqi: Optional[int]   = None
    aqi_category: Optional[str] = None
    flood_risk: Optional[str]   = None
    cloudburst_risk: Optional[str] = None
    temperature: Optional[float] = None
    weather_desc: Optional[str]  = None
    history: List[ChatMessage]   = []
    health_conditions: List[str] = []


def _build_context(city: str, aqi, aqi_category, flood_risk,
                   flood_probability, cloudburst_risk, temperature,
                   humidity, weather_desc, health_conditions=None) -> str:
    parts = [f"Location: {city}, Pakistan"]
    if aqi is not None:
        parts.append(f"Current AQI: {aqi} ({aqi_category or 'unknown'})")
    if flood_risk:
        prob = f" ({round((flood_probability or 0)*100)}% probability)" if flood_probability else ""
        parts.append(f"Flood risk: {flood_risk}{prob}")
    if cloudburst_risk:
        parts.append(f"Cloudburst risk: {cloudburst_risk}")
    if temperature is not None:
        parts.append(f"Temperature: {temperature:.1f}°C")
    if humidity is not None:
        parts.append(f"Humidity: {humidity:.0f}%")
    if weather_desc:
        parts.append(f"Weather: {weather_desc}")
    if health_conditions:
        parts.append(f"User health conditions: {', '.join(health_conditions)}")
    return "\n".join(parts)


def _health_persona(health_conditions: List[str]) -> str:
    """Returns a personalisation clause for the AI system prompt."""
    if not health_conditions:
        return ""
    cond_str = ", ".join(health_conditions)
    notes = []
    lc = [c.lower() for c in health_conditions]
    if any("asthma" in c or "copd" in c for c in lc):
        notes.append("respiratory conditions (flag AQI above 50 as a personal risk)")
    if any("heart" in c or "hypertension" in c for c in lc):
        notes.append("cardiovascular conditions (heat and air pollution are extra dangerous)")
    if any("diabetes" in c for c in lc):
        notes.append("diabetes (dehydration and heat stress require extra caution)")
    if any("elderly" in c for c in lc):
        notes.append("elderly household member (lower thresholds for all hazards)")
    if any("child" in c for c in lc):
        notes.append("children (sensitive to AQI and heat; keep indoors if AQI > 100)")
    if any("allerg" in c for c in lc):
        notes.append("allergies (pollen and smog can trigger reactions)")
    if not notes:
        notes.append(f"{cond_str} (adjust advice accordingly)")
    return (
        f" The user has the following health conditions: {cond_str}. "
        f"Personalise every response for these: {'; '.join(notes)}. "
        "Always mention the specific condition by name when giving relevant advice."
    )


def _call_openai(system: str, messages: list, max_tokens: int = 400) -> str:
    api_key = os.getenv("OPENAI_API_KEY", "")
    if not api_key:
        return ("AI summary unavailable — set OPENAI_API_KEY on the Railway server. "
                "Your current environmental data is shown above.")
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    # OpenAI format: system message goes first in the messages array
    openai_messages = [{"role": "system", "content": system}] + messages
    body = {
        "model": OPENAI_MODEL,
        "max_tokens": max_tokens,
        "messages": openai_messages,
    }
    with httpx.Client(timeout=20) as client:
        resp = client.post(OPENAI_API_URL, headers=headers, json=body)
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


@app.post("/api/ai/summary")
def daily_summary(payload: DailySummaryRequest):
    """
    Generates a plain-language daily environmental brief for the user's city.
    Returns: { summary, safety_tip, guide_title, guide_steps }
    """
    ctx = _build_context(
        payload.city, payload.aqi, payload.aqi_category,
        payload.flood_risk, payload.flood_probability,
        payload.cloudburst_risk, payload.temperature,
        payload.humidity, payload.weather_desc,
        payload.health_conditions,
    )
    persona = _health_persona(payload.health_conditions)
    system = (
        "You are EcoAlert, a friendly environmental safety assistant for Pakistan."
        + persona +
        " Write in simple English. Be concise, warm, and practical. "
        "Never use markdown symbols like ** or ##. Use plain sentences only."
    )
    has_conditions = bool(payload.health_conditions)
    summary_prompt = (
        f"Current conditions:\n{ctx}\n\n"
        + (
            f"The user has: {', '.join(payload.health_conditions)}. "
            "Write a 2-3 sentence daily brief that directly addresses how today's conditions "
            "affect their specific health profile. Name the condition explicitly."
            if has_conditions else
            "Write a 2-3 sentence daily environmental brief for this city. "
            "Start with the most important hazard. Be specific and actionable."
        )
    )
    tip_prompt = (
        f"Current conditions:\n{ctx}\n\n"
        + (
            f"The user has: {', '.join(payload.health_conditions)}. "
            "Give ONE safety tip specifically for their health condition today. "
            "Name the condition. Start with an action verb. One sentence only."
            if has_conditions else
            "Give ONE specific safety tip for today in one sentence. "
            "Start with an action verb. No generic advice."
        )
    )
    guide_prompt = (
        f"Current conditions:\n{ctx}\n\n"
        + (
            f"The user has: {', '.join(payload.health_conditions)}. "
            "Give a personalised safety guide for their conditions under today's hazards. "
            if has_conditions else
            "Based on the dominant hazard today, give a dynamic safety guide. "
        ) +
        "Respond with exactly this format:\n"
        "TITLE: <3-6 word title>\n"
        "STEP1: <action>\nSTEP2: <action>\nSTEP3: <action>\nSTEP4: <action>"
    )

    try:
        summary  = _call_openai(system, [{"role": "user", "content": summary_prompt}], 200)
        tip      = _call_openai(system, [{"role": "user", "content": tip_prompt}],     80)
        guide_raw = _call_openai(system, [{"role": "user", "content": guide_prompt}],  200)

        # Parse guide
        lines = {l.split(":")[0].strip(): ":".join(l.split(":")[1:]).strip()
                 for l in guide_raw.strip().splitlines() if ":" in l}
        guide_steps = [lines.get(f"STEP{i}", "") for i in range(1, 5) if lines.get(f"STEP{i}")]

        return {
            "summary":     summary.strip(),
            "safety_tip":  tip.strip(),
            "guide_title": lines.get("TITLE", "Today's Safety Guide"),
            "guide_steps": guide_steps,
            "city":        payload.city,
        }
    except Exception as exc:
        logger.exception("ai summary failed")
        raise HTTPException(status_code=500, detail={"error": str(exc)})


@app.post("/api/ai/chat")
def ai_chat(payload: ChatRequest):
    """
    Contextual chatbot that knows the user's current environmental conditions.
    Returns: { reply }
    """
    ctx = _build_context(
        payload.city, payload.aqi, payload.aqi_category,
        payload.flood_risk, None, payload.cloudburst_risk,
        payload.temperature, None, payload.weather_desc,
        payload.health_conditions,
    )
    persona = _health_persona(payload.health_conditions)
    system = (
        "You are EcoAlert, a helpful environmental safety assistant for Pakistan."
        + persona +
        f" The user is in {payload.city}. Current conditions:\n{ctx}\n\n"
        "Answer questions about air quality, floods, cloudbursts, weather, and safety. "
        "Be concise (2-4 sentences max). Give specific, actionable advice personalised "
        "to the user's health profile when relevant. "
        "Never use markdown symbols. If asked something unrelated to environment or safety, "
        "politely redirect to your purpose."
    )
    messages = [{"role": m.role, "content": m.content} for m in payload.history]
    messages.append({"role": "user", "content": payload.message})

    try:
        reply = _call_openai(system, messages, 300)
        return {"reply": reply.strip()}
    except Exception as exc:
        logger.exception("ai chat failed")
        raise HTTPException(status_code=500, detail={"error": str(exc)})
