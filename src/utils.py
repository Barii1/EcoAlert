import json
import math
from typing import Dict, Any

import joblib
import numpy as np
import pandas as pd

from config import (
    FEATURE_COLS,
    MODEL_PATH,
    METADATA_PATH,
    THRESHOLD,
    LOW_RISK_CUTOFF,
    MODERATE_RISK_CUTOFF,
)


def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [col.strip().lower() for col in df.columns]
    return df


def dew_point_celsius(temp_c: float, humidity: float) -> float:
    if temp_c is None or humidity is None:
        return np.nan

    humidity = max(1.0, min(float(humidity), 100.0))
    temp_c = float(temp_c)

    a = 17.27
    b = 237.7
    gamma = math.log(humidity / 100.0) + (a * temp_c / (b + temp_c))
    return (b * gamma) / (a - gamma)


def normalize_cloud_cover(series: pd.Series) -> pd.Series:
    series = pd.to_numeric(series, errors="coerce")
    if series.dropna().empty:
        return series

    max_val = series.max()

    # Only convert when the data is clearly on a 0-100 percentage scale
    if max_val > 10:
        return (series / 100.0) * 8.0

    # Keep training-style 0-9 cloud values as they are
    return series


def map_target_to_binary(series: pd.Series) -> pd.Series:
    if pd.api.types.is_numeric_dtype(series):
        return pd.to_numeric(series, errors="coerce")

    mapping = {
        "yes": 1,
        "no": 0,
        "1": 1,
        "0": 0,
        "true": 1,
        "false": 0,
    }
    return series.astype(str).str.strip().str.lower().map(mapping)


def ensure_feature_frame(df: pd.DataFrame) -> pd.DataFrame:
    df = standardize_columns(df.copy())

    missing = [col for col in FEATURE_COLS if col not in df.columns]

    if "dew_point" in missing:
        if "temperature" in df.columns and "humidity" in df.columns:
            df["dew_point"] = df.apply(
                lambda row: dew_point_celsius(row["temperature"], row["humidity"]),
                axis=1,
            )
            missing = [col for col in FEATURE_COLS if col not in df.columns]

    if missing:
        raise ValueError(f"Missing required feature columns: {missing}")

    df["cloud_cover"] = normalize_cloud_cover(df["cloud_cover"])

    for col in FEATURE_COLS:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    return df[FEATURE_COLS].copy()


def get_risk_level(prob: float) -> str:
    if prob < LOW_RISK_CUTOFF:
        return "Low"
    if prob < MODERATE_RISK_CUTOFF:
        return "Moderate"
    return "High"


def load_model_and_metadata():
    model = joblib.load(MODEL_PATH)

    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    return model, metadata


def score_dataframe(df: pd.DataFrame, model, threshold: float = THRESHOLD) -> pd.DataFrame:
    scored = df.copy()
    features = ensure_feature_frame(scored)

    probabilities = model.predict_proba(features)[:, 1]
    scored["cloudburst_probability"] = probabilities
    scored["predicted_class"] = (scored["cloudburst_probability"] >= threshold).astype(int)
    scored["risk_level"] = scored["cloudburst_probability"].apply(get_risk_level)

    return scored


def normalize_api_payload(payload: Dict[str, Any]) -> pd.DataFrame:
    current = payload.get("current", payload)
    main = current.get("main", current)
    clouds = current.get("clouds", payload.get("clouds", {}))
    wind = current.get("wind", payload.get("wind", {}))
    coord = payload.get("coord", {})

    cloud_value = None
    if isinstance(clouds, dict):
        cloud_value = clouds.get("all", clouds.get("cloud_cover"))
    elif isinstance(clouds, (int, float)):
        cloud_value = clouds

    wind_speed = None
    if isinstance(wind, dict):
        wind_speed = wind.get("speed", wind.get("wind_speed"))
    elif isinstance(wind, (int, float)):
        wind_speed = wind

    temperature = current.get("temp", main.get("temp"))
    humidity = current.get("humidity", main.get("humidity"))
    pressure = (
        current.get("sea_level")
        or main.get("sea_level")
        or current.get("pressure")
        or main.get("pressure")
    )
    dew_point = current.get("dew_point", main.get("dew_point"))

    if dew_point is None and temperature is not None and humidity is not None:
        dew_point = dew_point_celsius(temperature, humidity)

    row = {
        "date": payload.get("dt_txt") or current.get("dt"),
        "city": payload.get("name") or payload.get("city", {}).get("name"),
        "latitude": coord.get("lat"),
        "longitude": coord.get("lon"),
        "temperature": temperature,
        "humidity": humidity,
        "pressure": pressure,
        "cloud_cover": cloud_value,
        "wind_speed": wind_speed,
        "dew_point": dew_point,
    }

    df = pd.DataFrame([row])
    df["cloud_cover"] = normalize_cloud_cover(df["cloud_cover"])
    return df