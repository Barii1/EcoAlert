import os
import logging

# Configure logging FIRST, before any module imports that may log
logging.basicConfig(level=logging.INFO)

from dotenv import load_dotenv
from flask import Flask
from flask_cors import CORS
from routes.upload_routes import upload_bp
from routes.predict_routes import predict_bp

# Load .env so CORS_ALLOWED_ORIGINS, FLASK_HOST, PORT etc. are available
# before any blueprint or model initialises.
load_dotenv()

app = Flask(__name__)

# CORS — on Railway/Render we allow * so any device can hit the API.
# Set CORS_ALLOWED_ORIGINS env var to a comma list to lock down in production.
# "*" is safe here because all endpoints require auth tokens for writes;
# the prediction endpoints are read-only ML inference.
_cors_env = os.getenv("CORS_ALLOWED_ORIGINS", "*")
if _cors_env.strip() == "*":
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    logging.info("[CORS] Allowing all origins (*)")
else:
    allowed_origins = [o.strip() for o in _cors_env.split(",") if o.strip()]
    CORS(app, resources={r"/api/*": {"origins": allowed_origins}})
    logging.info("[CORS] Allowed origins: %s", allowed_origins)

app.register_blueprint(upload_bp)
app.register_blueprint(predict_bp)


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok", "service": "EcoAlert Backend"}, 200


if __name__ == "__main__":
    debug_mode = os.getenv("FLASK_DEBUG", "0") == "1"
    host = os.getenv("FLASK_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    app.run(debug=debug_mode, host=host, port=port)
