from flask import Blueprint, jsonify, request
from services.supabase_auth_service import verify_supabase_token
from services.supabase_service import _get_supabase, log_audit, user_is_admin

admin_bp = Blueprint("admin", __name__, url_prefix="/api/admin")


def _extract_bearer_token() -> str | None:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    return auth_header.split(" ", 1)[1].strip()


def _require_admin():
    """
    Verifies the Supabase JWT and checks that the user has role='admin' in profiles.
    Returns (uid, None) on success or (None, error_response) on failure.
    """
    token = _extract_bearer_token()
    if not token:
        return None, (jsonify({"error": "Missing Authorization bearer token"}), 401)

    try:
        claims = verify_supabase_token(token)
    except Exception:
        return None, (jsonify({"error": "Invalid or expired auth token"}), 401)

    uid = claims.get("sub")
    if not uid or not user_is_admin(uid):
        return None, (jsonify({"error": "Forbidden"}), 403)

    return uid, None


@admin_bp.route("/logs", methods=["GET"])
def get_logs():
    """
    Admin-only log query.
    Query params:
      - type:  prediction | upload | audit
      - limit: int (default 50)
    Headers:
      - Authorization: Bearer <supabase_access_token>
    """
    uid, auth_error = _require_admin()
    if auth_error is not None:
        return auth_error

    log_type = request.args.get("type", "prediction")
    limit = int(request.args.get("limit", "50"))

    table_map = {
        "prediction": "prediction_logs",
        "upload":     "upload_logs",
        "audit":      "audit_logs",
    }
    table = table_map.get(log_type, "prediction_logs")

    try:
        result = (
            _get_supabase()
            .table(table)
            .select("*")
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        log_audit({
            "actor_uid": uid,
            "action": "read_logs",
            "context": {"type": log_type, "limit": limit},
        })
        return jsonify({"data": result.data}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
