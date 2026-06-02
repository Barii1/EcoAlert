# EcoAlert Models Presentation Guide

This guide summarizes the current EcoAlert model pipeline, backend routes,
Flutter integration, local demo steps, and important presentation notes.

## Current Model Set

EcoAlert currently uses three ML/model components:

1. Cloudburst / flood prediction model
2. Numerical AQI prediction model
3. AQI image classification model

The app also uses Open-Meteo/CAMS as the live environmental data reference.
Open-Meteo is not treated as the trained model. It provides live weather and
pollutant inputs that the app and backend use for prediction, validation, and
reference display.

## 1. Cloudburst / Flood Prediction Model

Purpose:
- Predict cloudburst probability and flood risk from live weather conditions.
- Used by the Flood Risk screen and flood detail page.

Backend route:

```text
POST /api/predict/cloudburst
```

Example request:

```json
{
  "latitude": 31.5204,
  "longitude": 74.3587,
  "city": "Lahore"
}
```

Model file:

```text
cloudburst/models/best_cloudburst_model.pkl
```

Feature columns reported by backend:

```text
temperature
humidity
pressure
cloud_cover
wind_speed
dew_point
```

Current backend behavior:
- Backend fetches live weather features.
- It runs the trained cloudburst model if the model file is loaded.
- It returns `cloudburst_probability`, `risk_level`, `predicted_class`,
  `features_used`, and `using_model`.
- Flutter separates flood risk score from cloudburst probability so the UI does
  not show inflated flood risk during low rain.

Local test result from June 2, 2026:

```json
{
  "city": "Lahore",
  "cloudburst_probability": 0.0941,
  "predicted_class": 0,
  "risk_level": "Low",
  "using_model": true
}
```

Presentation wording:

```text
The flood module uses live weather inputs and a trained cloudburst model to
estimate cloudburst probability. The app then displays both practical flood
risk and model probability so users understand current danger.
```

## 2. Numerical AQI Prediction Model

Purpose:
- Predict an EcoAlert AQI score/category from pollutant readings.
- Used as the model-based AQI shown on the home card and AQI detail hero.

Backend route:

```text
POST /api/predict/aqi
```

Example request:

```json
{
  "city": "Lahore",
  "pm25": 48.4,
  "pm10": 163.9,
  "no2": 37,
  "so2": 13,
  "o3": 196,
  "co": 531
}
```

Model file:

```text
AQI/models/best_aqi_openmeteo_model.pkl
```

Feature columns reported by backend:

```text
components_co
components_no2
components_so2
components_o3
components_pm2_5
components_pm10
```

Current backend behavior:
- Receives pollutant readings.
- Maps them into the trained AQI model feature format.
- Runs the trained model if loaded.
- Returns `predicted_aqi`, `predicted_category`, `predicted_class`,
  `confidence`, `features_used`, and `using_model`.

Local test result from June 2, 2026:

```json
{
  "city": "Lahore",
  "predicted_aqi": 250,
  "predicted_category": "Very Unhealthy",
  "predicted_class": 5,
  "confidence": 0.7722,
  "using_model": true
}
```

Flutter display behavior:
- Home AQI card shows `EcoAlert AQI`, using `predictedAqi` and
  `predictedCategory` when available.
- AQI detail page top gauge also shows the EcoAlert ML predicted AQI.
- Below pollutants, the app shows a separate `Open-Meteo US AQI Reference`
  card for comparison.
- Pollutants card shows live pollutant values from Open-Meteo/CAMS.

Presentation wording:

```text
The dashboard highlights EcoAlert's model-based AQI score. The detail screen
also shows the live Open-Meteo US AQI reference and pollutant breakdown so the
model output can be compared against external live data.
```

## 3. AQI Image Classification Model

Purpose:
- Classify a captured image into an air-quality class.
- Used by the AQI Scan screen after tapping `Capture & Classify`.

Backend routes:

```text
GET  /api/aqi-image/health
POST /api/aqi-image/predict
```

Model file:

```text
IMAGE_AQI/models/best_aqi_image_model.keras
```

Class names:

```text
Good
Moderate
Unhealthy for Sensitive Groups
Unhealthy
Very Unhealthy
Severe
```

Current backend behavior:
- Receives multipart image upload under key `image`.
- Decodes image bytes.
- Resizes/preprocesses image for the Keras model.
- Returns raw model `predictedLabel`, `confidence`, `topK`, and full
  `probabilities`.

Local health result from June 2, 2026:

```json
{
  "model_loaded": true,
  "class_names_loaded": true,
  "num_classes": 6,
  "image_size": [224, 224]
}
```

Local prediction test from June 2, 2026:

```json
{
  "predictedLabel": "Good",
  "confidence": 0.916652500629425,
  "topK": [
    {"label": "Good", "confidence": 0.916652500629425},
    {"label": "Unhealthy for Sensitive Groups", "confidence": 0.05038977041840553},
    {"label": "Very Unhealthy", "confidence": 0.01700422167778015}
  ]
}
```

Important behavior:
- This is an image classifier, not an AQI-number regressor.
- It does not output exact AQI numbers such as 156.
- It outputs class + confidence.
- The app must not fabricate an exact AQI number from the image model.

Recent UI correction:
- Before capture: top scan pill shows live AQI reference.
- After successful capture: top scan pill shows `ML`, raw image model label,
  and confidence percentage.
- Bottom scan card shows raw model output only.
- Live AQI reference is displayed separately and does not overwrite the model
  result.
- If backend is unavailable, app clearly says the image model did not run.

Presentation wording:

```text
The image AQI model is a classifier. It predicts the visual air-quality class
from the captured image and returns confidence. We show the raw model class and
keep live AQI as a separate reference.
```

## Why Image Results Can Vary Between Captures

Variation is expected because:
- Each frame is different.
- Motion blur changes image features.
- Indoor lights, ceilings, walls, and people are outside the intended outdoor
  smog/sky image domain.
- Exposure and focus can change between captures.
- The model is trained on limited regional data.

This is not dummy behavior. It is real model inference. For best demo results:
- Use outdoor/sky/smog scene images.
- Avoid random indoor room images.
- Hold the camera still before capture.
- Keep the backend running locally.

## Open-Meteo / CAMS Integration

Current API source:

```text
https://air-quality-api.open-meteo.com/v1/air-quality
```

Current requested variables:

```text
current:
nitrogen_dioxide, pm2_5, pm10, ozone, us_aqi, carbon_monoxide, sulphur_dioxide

hourly:
us_aqi, pm10, pm2_5, carbon_monoxide, nitrogen_dioxide, ozone, sulphur_dioxide
```

Flutter behavior:
- Uses user/city location coordinates.
- Fetches live pollutant values.
- Uses `current.us_aqi` as the live external AQI reference.
- Displays PM2.5, PM10, O3, NO2, SO2, and CO in the AQI detail page.
- Uses pollutants as input for the numerical AQI model.

## Map / Hazard Zone Changes

Map behavior:
- Base map tiles are OpenStreetMap.
- Hazard zones are EcoAlert generated zones, not IQAir station markers.
- Lahore now has a denser AQI and flood overlay.
- AQI zones derive from live AQI plus deterministic zone variation.
- Flood zones derive from rainfall/flood inputs plus local terrain bias
  such as drains, underpasses, Ravi corridor, and low-lying areas.

Presentation wording:

```text
The hazard map visualizes EcoAlert-generated risk zones from live model and
weather inputs. It is not a direct station network like IQAir; it is an
interpreted risk layer for the app.
```

## Local Demo Setup For Presentation

Use this setup for a fast and stable wired phone demo.

### 1. Start Flask backend

Open PowerShell:

```powershell
cd C:\Users\bilal\Desktop\Cloudburst_project\backend\ecoalert-backend
.\venv\Scripts\uvicorn.exe app:asgi_app --host 0.0.0.0 --port 5000 --reload
```

Expected:

```text
Uvicorn running on http://0.0.0.0:5000
```

Test backend:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/health
Invoke-RestMethod http://127.0.0.1:5000/api/predict/status
Invoke-RestMethod http://127.0.0.1:5000/api/aqi-image/health
```

### 2. Connect Android phone by USB

Check device:

```powershell
adb devices
```

Enable phone-to-laptop localhost tunnel:

```powershell
adb reverse tcp:5000 tcp:5000
adb reverse --list
```

Expected:

```text
tcp:5000 tcp:5000
```

### 3. Run Flutter locally on phone

From project root:

```powershell
cd C:\Users\bilal\Desktop\Cloudburst_project
flutter run -d ZY22GFMX9V --dart-define=UPLOAD_API_BASE_URL=http://127.0.0.1:5000
```

If using this laptop's Flutter path:

```powershell
& 'C:\Users\bilal\Desktop\UNI\sem 8\MOB\flutter\bin\flutter.bat' run -d ZY22GFMX9V --dart-define=UPLOAD_API_BASE_URL=http://127.0.0.1:5000
```

### 4. Build/install APK instead of flutter run

```powershell
& 'C:\Users\bilal\Desktop\UNI\sem 8\MOB\flutter\bin\flutter.bat' build apk --debug --no-pub --dart-define=UPLOAD_API_BASE_URL=http://127.0.0.1:5000
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell monkey -p com.example.ecoalert -c android.intent.category.LAUNCHER 1
```

## Why USB Alone Is Not Enough

USB cable only connects the phone for debugging. It does not automatically make
the laptop Flask server reachable.

For the phone to call laptop Flask using `http://127.0.0.1:5000`, this command
must be active:

```powershell
adb reverse tcp:5000 tcp:5000
```

If the cable is removed, the reverse tunnel stops working.

For no-wire demos, the backend must either be deployed or the app must use the
laptop's Wi-Fi IP address, for example:

```powershell
flutter run -d DEVICE_ID --dart-define=UPLOAD_API_BASE_URL=http://192.168.x.x:5000
```

The phone and laptop must be on the same Wi-Fi, and Windows firewall must allow
port 5000.

## Current Model Endpoint Test Summary

Tested locally on June 2, 2026:

```text
/health                         OK
/api/predict/status             OK, cloudburst + AQI models loaded
/api/predict/cloudburst          OK, using_model true
/api/predict/aqi                 OK, using_model true
/api/aqi-image/health            OK, image model loaded
/api/aqi-image/predict           OK, returns class/confidence/topK
```

Known caveat:
- AQI image model works, but indoor scenes can produce unstable classes because
  the dataset is limited and the model is intended for outdoor/smog imagery.

## Presentation Talking Points

Use these points:

```text
EcoAlert combines live environmental data with project-trained models.

The AQI model predicts an EcoAlert AQI category/score from pollutant inputs.

The Open-Meteo US AQI card is shown as a live external reference, not as our
trained model.

The cloudburst model predicts probability using live weather features.

The image AQI model is a classifier. It returns air-quality class and
confidence from the camera image.

The app clearly separates model predictions from live reference data to avoid
misleading the user.
```

## What Not To Say

Avoid:

```text
The image model predicts exact AQI number.
```

Correct:

```text
The image model predicts AQI class and confidence.
```

Avoid:

```text
Open-Meteo AQI is our ML model.
```

Correct:

```text
Open-Meteo AQI is the live reference. Our model output is shown separately.
```

Avoid:

```text
The hazard map is an IQAir station map.
```

Correct:

```text
The hazard map is EcoAlert's generated risk-zone visualization from live data
and model outputs.
```
