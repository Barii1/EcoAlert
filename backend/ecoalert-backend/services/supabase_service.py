import os
from supabase import Client, create_client
from dotenv import load_dotenv

load_dotenv()

supabase: Client | None = None


def _get_supabase() -> Client:
    global supabase
    if supabase is not None:
        return supabase
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_KEY")
    if not url or not key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set.")
    supabase = create_client(url, key)
    return supabase


def upload_report_image(file_bytes: bytes, report_id: str, image_index: int) -> str:
    """
    Uploads a single image to Supabase Storage under report-images bucket.
    Returns the public URL of the uploaded image.
    """
    path = f"{report_id}/image_{image_index}.jpg"

    _get_supabase().storage.from_("report-images").upload(
        path=path,
        file=file_bytes,
        file_options={"content-type": "image/jpeg"},
    )

    public_url = _get_supabase().storage.from_("report-images").get_public_url(path)
    return public_url


def upload_profile_picture(file_bytes: bytes, user_uid: str) -> str:
    """
    Uploads a profile picture to Supabase Storage.
    Returns the public URL.
    """
    path = f"{user_uid}/avatar.jpg"

    # Delete existing if present (upsert manually)
    try:
        _get_supabase().storage.from_("profile-pictures").remove([path])
    except Exception:
        pass

    _get_supabase().storage.from_("profile-pictures").upload(
        path=path,
        file=file_bytes,
        file_options={"content-type": "image/jpeg"},
    )

    public_url = _get_supabase().storage.from_("profile-pictures").get_public_url(path)
    return public_url


def delete_report_images(report_id: str) -> None:
    """
    Deletes all images for a given report from Supabase.
    """
    files = _get_supabase().storage.from_("report-images").list(report_id)
    paths = [f"{report_id}/{f['name']}" for f in files]
    if paths:
        _get_supabase().storage.from_("report-images").remove(paths)


def delete_report_image_paths(paths: list[str]) -> None:
    """
    Deletes specific report image paths from Supabase.
    """
    if not paths:
        return
    _get_supabase().storage.from_("report-images").remove(paths)


def log_event(table: str, payload: dict) -> None:
    """
    Inserts a row into a Supabase table for analytics/audit logging.
    """
    try:
        _get_supabase().table(table).insert(payload).execute()
    except Exception:
        # Avoid breaking request flows if logging fails.
        return


def log_prediction(payload: dict) -> None:
    log_event("prediction_logs", payload)


def log_upload(payload: dict) -> None:
    log_event("upload_logs", payload)


def log_audit(payload: dict) -> None:
    log_event("audit_logs", payload)


# ── Auth helpers (Supabase equivalents of the old firestore_service functions) ──

def report_belongs_to_user(report_id: str, uid: str) -> bool:
    """Returns True if the report exists in Supabase and its reporter_uid matches uid."""
    try:
        result = (
            _get_supabase()
            .table("reports")
            .select("reporter_uid")
            .eq("id", report_id)
            .single()
            .execute()
        )
        return (result.data or {}).get("reporter_uid") == uid
    except Exception:
        return False


def user_is_admin(uid: str) -> bool:
    """Returns True if the user's profile has role='admin' in Supabase."""
    try:
        result = (
            _get_supabase()
            .table("profiles")
            .select("role")
            .eq("id", uid)
            .single()
            .execute()
        )
        return (result.data or {}).get("role") == "admin"
    except Exception:
        return False


def update_report_image_urls(report_id: str, image_urls: list[str]) -> None:
    """Writes image URLs and count back to the reports table."""
    _get_supabase().table("reports").update({
        "image_urls": image_urls,
        "image_count": len(image_urls),
    }).eq("id", report_id).execute()


def update_user_profile_picture(uid: str, photo_url: str) -> None:
    """Updates the user's photo_url in the profiles table."""
    _get_supabase().table("profiles").update({
        "photo_url": photo_url,
    }).eq("id", uid).execute()
