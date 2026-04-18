from flask import Flask
from flask_cors import CORS
from routes.upload_routes import upload_bp

app = Flask(__name__)
CORS(app)

app.register_blueprint(upload_bp)


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok", "service": "EcoAlert Backend"}, 200


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
