# Cloudburst Prediction Module

Machine learning module for predicting cloudburst (sudden heavy rainfall) events using weather data.

## Features

- **Multiple ML Models**: Logistic Regression, SVM, Decision Tree
- **Real-time Predictions**: Integrates with Open-Meteo weather API
- **Risk Classification**: Categorizes predictions as Low, Moderate, or High risk
- **Training Pipeline**: Automated model training and evaluation

## Project Structure

```
cloudburst/
├── src/
│   ├── train_model.py          # Model training script
│   ├── predict_openmeteo.py    # Real-time prediction using API
│   ├── predict_from_csv.py     # Batch prediction from CSV
│   ├── config.py               # Configuration settings
│   └── utils.py                # Utility functions
├── models/
│   ├── best_cloudburst_model.pkl    # Trained model (generated)
│   └── model_metadata.json          # Model metadata
├── results/
│   ├── model_comparison_results.csv  # Training results
│   ├── testing_predictions.csv       # Test predictions
│   └── openmeteo_api_predictions.csv # API predictions
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Prepare training data (place in `data/` folder):
   - `CB_TRAINING_DATA.csv` - Training dataset
   - `CB_TESTING_DATA.csv` - Testing dataset

## Usage

### Train the model:
```bash
python src/train_model.py
```

### Make predictions from API (real-time weather):
```bash
python src/predict_openmeteo.py --latitude 31.5173 --longitude 74.3411 --start-date 2026-04-20 --end-date 2026-05-04
```

### Make predictions from CSV:
```bash
python src/predict_from_csv.py
```

## Features Used

- Temperature
- Humidity
- Pressure
- Cloud Cover
- Wind Speed
- Dew Point

## Risk Thresholds

- **Low Risk**: < 0.30 probability
- **Moderate Risk**: 0.30 - 0.60 probability
- **High Risk**: > 0.60 probability
