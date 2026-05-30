import os
import logging
from typing import Optional

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
