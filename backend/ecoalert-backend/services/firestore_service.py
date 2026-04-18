import firebase_admin
from firebase_admin import credentials, firestore
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
