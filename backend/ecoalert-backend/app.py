import os

from flask import Flask
from flask_cors import CORS
from routes.upload_routes import upload_bp

app = Flask(__name__)
allowed_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:3000").split(",")
    if origin.strip()
]
CORS(app, resources={r"/api/*": {"origins": allowed_origins}})

app.register_blueprint(upload_bp)


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok", "service": "EcoAlert Backend"}, 200


if __name__ == "__main__":
    debug_mode = os.getenv("FLASK_DEBUG", "0") == "1"
    host = os.getenv("FLASK_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    app.run(debug=debug_mode, host=host, port=port)
