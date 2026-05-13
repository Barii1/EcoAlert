# EcoAlert — Trained Model Files

Drop your exported model files here. The backend will auto-detect them on startup.

---

## Supported formats

| File name | Format | How to export |
|-----------|--------|--------------|
| `flood_model.pkl` | scikit-learn / joblib | `joblib.dump(model, 'flood_model.pkl')` |
| `aqi_model.pkl` | scikit-learn / joblib | `joblib.dump(model, 'aqi_model.pkl')` |
| `flood_model.h5` | Keras / TensorFlow | `model.save('flood_model.h5')` |
| `aqi_model.h5` | Keras / TensorFlow | `model.save('aqi_model.h5')` |

## Feature contract

### Flood model input features (in this exact order):
```
rainfall_24h      → float, mm in past 24 hours
rainfall_48h      → float, mm in past 48 hours
rainfall_per_hour → float, mm/hour intensity
temperature       → float, celsius
humidity          → float, percentage (0-100)
city_risk_score   → int, city risk score (auto-added by backend)
```

### AQI model input features (in this exact order):
```
pm25        → float, µg/m³
pm10        → float, µg/m³
no2         → float, µg/m³
o3          → float, µg/m³
co          → float, mg/m³
temperature → float, celsius
humidity    → float, percentage
wind_speed  → float, km/h
```

### Expected output
- **Flood model:** classification → 0=low, 1=moderate, 2=high, 3=critical
- **AQI model:** regression → single float (predicted AQI value 0-500)

## If features differ from above
Edit `FLOOD_FEATURE_COLUMNS` and `AQI_FEATURE_COLUMNS` in:
`backend/ecoalert-backend/services/model_service.py`

## Verify the model loaded
After dropping the file and restarting the server, hit:
`GET /api/predict/status`
→ should show `"flood_model_loaded": true`
