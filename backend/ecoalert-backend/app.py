import os
import logging

# Configure logging FIRST, before any module imports that may log
logging.basicConfig(level=logging.INFO)

from dotenv import load_dotenv
from flask import Flask
from flask_cors import CORS
from routes.aqi_image_routes import aqi_image_bp
from asgiref.wsgi import WsgiToAsgi
from routes.upload_routes import upload_bp
from routes.predict_routes import predict_bp
from routes.admin_routes import admin_bp

# Load .env so CORS_ALLOWED_ORIGINS, FLASK_HOST, PORT etc. are available
# before any blueprint or model initialises.
load_dotenv()

app = Flask(__name__)

# CORS — default to localhost for safety; override via CORS_ALLOWED_ORIGINS.
_cors_env = os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
allowed_origins = [o.strip() for o in _cors_env.split(",") if o.strip()]
origins = "*" if allowed_origins == ["*"] else allowed_origins
CORS(app, resources={r"/api/*": {"origins": origins}})
logging.info("[CORS] Allowed origins: %s", origins)

app.register_blueprint(upload_bp)
app.register_blueprint(aqi_image_bp)
app.register_blueprint(predict_bp)
app.register_blueprint(admin_bp)


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok", "service": "EcoAlert Backend"}, 200


asgi_app = WsgiToAsgi(app)


if __name__ == "__main__":
    debug_mode = os.getenv("FLASK_DEBUG", "0") == "1"
    host = os.getenv("FLASK_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    app.run(debug=debug_mode, host=host, port=port)
