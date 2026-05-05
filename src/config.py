from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
MODEL_DIR = BASE_DIR / "models"
RESULTS_DIR = BASE_DIR / "results"

TRAIN_DATA_PATH = DATA_DIR / "CB_TRAINING_DATA.csv"
TEST_DATA_PATH = DATA_DIR / "CB_TESTING_DATA.csv"

MODEL_PATH = MODEL_DIR / "best_cloudburst_model.pkl"
METADATA_PATH = MODEL_DIR / "model_metadata.json"

RESULTS_CSV_PATH = RESULTS_DIR / "model_comparison_results.csv"
PREDICTIONS_CSV_PATH = RESULTS_DIR / "testing_predictions.csv"
OPENMETEO_PREDICTIONS_CSV_PATH = RESULTS_DIR / "openmeteo_api_predictions.csv"
LIVE_PREDICTION_JSON_PATH = RESULTS_DIR / "live_api_prediction.json"
FEATURES_PATH = RESULTS_DIR / "feature_columns.txt"

MODEL_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)

FEATURE_COLS = [
    "temperature",
    "humidity",
    "pressure",
    "cloud_cover",
    "wind_speed",
    "dew_point",
]

THRESHOLD = 0.50
LOW_RISK_CUTOFF = 0.30
MODERATE_RISK_CUTOFF = 0.60

# Optional generic API config, only keep if you later use another API
WEATHER_API_BASE_URL = os.getenv("WEATHER_API_BASE_URL", "")
WEATHER_API_KEY = os.getenv("WEATHER_API_KEY", "")
WEATHER_API_KEY_PARAM = os.getenv("WEATHER_API_KEY_PARAM", "appid")
WEATHER_API_TIMEOUT = int(os.getenv("WEATHER_API_TIMEOUT", "20"))