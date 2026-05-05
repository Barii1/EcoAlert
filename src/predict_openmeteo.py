import argparse
import requests
import pandas as pd
import joblib

from config import (
    MODEL_PATH,
    FEATURE_COLS,
    THRESHOLD,
    OPENMETEO_PREDICTIONS_CSV_PATH,
)
from utils import get_risk_level

OPEN_METEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"

HOURLY_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
    "dew_point_2m",
    "precipitation",
    "rain",
    "pressure_msl",
    "cloud_cover",
    "wind_speed_100m",
]


def fetch_open_meteo_archive(latitude: float, longitude: float, start_date: str, end_date: str) -> dict:
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "hourly": ",".join(HOURLY_VARS),
        "timezone": "auto",
        "wind_speed_unit": "kmh",
        "timeformat": "iso8601",
    }

    response = requests.get(OPEN_METEO_ARCHIVE_URL, params=params, timeout=30)
    response.raise_for_status()
    return response.json()


def openmeteo_hourly_to_daily_df(payload: dict) -> pd.DataFrame:
    if "hourly" not in payload:
        raise ValueError("Open-Meteo response does not contain 'hourly' data.")

    hourly = payload["hourly"]

    required_keys = [
        "time",
        "temperature_2m",
        "relative_humidity_2m",
        "dew_point_2m",
        "pressure_msl",
        "cloud_cover",
        "wind_speed_100m",
    ]

    missing_keys = [key for key in required_keys if key not in hourly]
    if missing_keys:
        raise ValueError(f"Missing hourly keys in API response: {missing_keys}")

    df = pd.DataFrame({
        "datetime": pd.to_datetime(hourly["time"], errors="coerce"),
        "temperature": hourly["temperature_2m"],
        "humidity": hourly["relative_humidity_2m"],
        "dew_point": hourly["dew_point_2m"],
        "pressure": hourly["pressure_msl"],
        "cloud_cover": hourly["cloud_cover"],
        "wind_speed": hourly["wind_speed_100m"],
        "precipitation": hourly.get("precipitation", [None] * len(hourly["time"])),
        "rain": hourly.get("rain", [None] * len(hourly["time"])),
    })

    if df["datetime"].isna().all():
        raise ValueError("Could not parse API timestamps.")

    df["date"] = df["datetime"].dt.date.astype(str)

    # Convert Open-Meteo cloud cover from 0-100 to the model's 0-8 style scale
    df["cloud_cover"] = (pd.to_numeric(df["cloud_cover"], errors="coerce") / 100.0) * 8.0

    daily_df = (
        df.groupby("date", as_index=False)
        .agg({
            "temperature": "mean",
            "humidity": "mean",
            "dew_point": "mean",
            "pressure": "mean",
            "cloud_cover": "mean",
            "wind_speed": "mean",
            "precipitation": "sum",
            "rain": "sum",
        })
    )

    daily_df["latitude"] = payload.get("latitude")
    daily_df["longitude"] = payload.get("longitude")
    daily_df["elevation"] = payload.get("elevation")
    daily_df["timezone"] = payload.get("timezone")

    return daily_df


def main():
    parser = argparse.ArgumentParser(description="Predict cloudburst from Open-Meteo archive API data.")
    parser.add_argument("--latitude", type=float, required=True, help="Latitude")
    parser.add_argument("--longitude", type=float, required=True, help="Longitude")
    parser.add_argument("--start-date", type=str, required=True, help="YYYY-MM-DD")
    parser.add_argument("--end-date", type=str, required=True, help="YYYY-MM-DD")
    args = parser.parse_args()

    print("Loading model...")
    model = joblib.load(MODEL_PATH)
    print("Model loaded successfully.")

    print("Fetching data from Open-Meteo...")
    payload = fetch_open_meteo_archive(
        latitude=args.latitude,
        longitude=args.longitude,
        start_date=args.start_date,
        end_date=args.end_date,
    )

    print("Transforming hourly data to daily feature rows...")
    daily_df = openmeteo_hourly_to_daily_df(payload)

    print("Daily feature sample:")
    print(daily_df.head())

    X = daily_df[FEATURE_COLS].copy()

    daily_df["cloudburst_probability"] = model.predict_proba(X)[:, 1]
    daily_df["predicted_class"] = (daily_df["cloudburst_probability"] >= THRESHOLD).astype(int)
    daily_df["risk_level"] = daily_df["cloudburst_probability"].apply(get_risk_level)

    daily_df.to_csv(OPENMETEO_PREDICTIONS_CSV_PATH, index=False)

    print(f"\nPredictions saved to: {OPENMETEO_PREDICTIONS_CSV_PATH}")

    print("\nPrediction summary:")
    print(daily_df["predicted_class"].value_counts(dropna=False))

    print("\nRisk level summary:")
    print(daily_df["risk_level"].value_counts(dropna=False))

    print("\nTop highest-risk rows:")
    top_rows = daily_df.sort_values("cloudburst_probability", ascending=False).head(10)
    print(top_rows.to_string(index=False))

    print("\nOpen-Meteo API prediction run complete.")


if __name__ == "__main__":
    main()