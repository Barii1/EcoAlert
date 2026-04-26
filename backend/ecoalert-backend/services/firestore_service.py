import firebase_admin
from firebase_admin import auth, credentials, firestore
from dotenv import load_dotenv

load_dotenv()

db = None


def _get_db():
    global db
    if db is not None:
        return db
    # Initialize Firebase Admin SDK
    # Looks for firebase-adminsdk.json in the project root
    cred = credentials.Certificate("firebase-adminsdk.json")
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    return db


def verify_id_token(id_token: str) -> dict:
    """
    Verifies Firebase ID token and returns decoded claims.
    """
    if not id_token:
        raise ValueError("Missing Firebase ID token")
    _get_db()
    return auth.verify_id_token(id_token)


def report_belongs_to_user(report_id: str, uid: str) -> bool:
    """
    Checks whether a report exists and belongs to uid.
    """
    snapshot = _get_db().collection("reports").document(report_id).get()
    if not snapshot.exists:
        return False
    data = snapshot.to_dict() or {}
    return data.get("reporterUid") == uid


def user_is_admin(uid: str) -> bool:
    """
    Returns true when the Firestore user document has admin role.
    """
    snapshot = _get_db().collection("users").document(uid).get()
    if not snapshot.exists:
        return False
    data = snapshot.to_dict() or {}
    return data.get("role") == "admin"


def update_report_image_urls(report_id: str, image_urls: list[str]) -> None:
    """
    Writes image URLs back to the Firestore report document.
    """
    _get_db().collection("reports").document(report_id).update(
        {
            "imageUrls": image_urls,
            "imageCount": len(image_urls),
        }
    )


def update_user_profile_picture(uid: str, photo_url: str) -> None:
    """
    Updates the user's profile picture URL in Firestore.
    """
    _get_db().collection("users").document(uid).update(
        {
            "photoUrl": photo_url,
        }
    )
