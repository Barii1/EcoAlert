"""
Supabase JWT verification for Flask backend.
Replaces firebase_admin.auth.verify_id_token() in all auth-gated routes.

Setup:
  1. Get your JWT secret from Supabase Dashboard → Project Settings → API → JWT Secret
  2. Add SUPABASE_JWT_SECRET=<secret> to backend/.env
  3. PyJWT must be in requirements.txt (already added)

Token source on Flutter side:
  final token = Supabase.instance.client.auth.currentSession!.accessToken;
  Then send as:  Authorization: Bearer <token>
"""

import os
import logging

import jwt as pyjwt
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)


def verify_supabase_token(token: str) -> dict:
    """
    Verifies a Supabase access token and returns the decoded payload.

    Raises:
        jwt.InvalidTokenError  — on invalid signature, expiry, wrong audience
        RuntimeError           — if SUPABASE_JWT_SECRET is not set

    Returns dict with at least:
        'sub'   — user UUID (use this as uid everywhere)
        'email' — user email
        'role'  — 'authenticated'
    """
    secret = os.getenv("SUPABASE_JWT_SECRET")
    if not secret:
        raise RuntimeError(
            "SUPABASE_JWT_SECRET is not set. "
            "Copy it from Supabase Dashboard → Project Settings → API → JWT Secret "
            "and add it to your .env file."
        )

    payload = pyjwt.decode(
        token,
        secret,
        algorithms=["HS256"],
        audience="authenticated",
    )
    logger.debug("[SupabaseAuth] Token verified for uid=%s", payload.get("sub"))
    return payload


def get_uid_from_token(token: str) -> str:
    """Convenience wrapper — returns just the user UUID ('sub' claim)."""
    return verify_supabase_token(token)["sub"]
