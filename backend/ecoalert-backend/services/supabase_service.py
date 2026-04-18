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
