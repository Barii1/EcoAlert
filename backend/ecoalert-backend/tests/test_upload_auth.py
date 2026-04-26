import io
import unittest
from unittest.mock import patch

from app import app


class UploadAuthTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_profile_upload_requires_bearer_token(self):
        response = self.client.post(
            "/api/upload/profile-picture",
            data={
                "uid": "user-1",
                "image": (io.BytesIO(b"img"), "avatar.jpg", "image/jpeg"),
            },
            content_type="multipart/form-data",
        )
        self.assertEqual(response.status_code, 401)

    @patch("routes.upload_routes.verify_id_token", return_value={"uid": "user-1"})
    @patch("routes.upload_routes.user_is_admin", return_value=False)
    @patch("routes.upload_routes.report_belongs_to_user", return_value=False)
    def test_report_upload_rejects_non_owner(
        self, _belongs_mock, _admin_mock, _verify_mock
    ):
        response = self.client.post(
            "/api/upload/report-images",
            data={
                "uid": "user-1",
                "report_id": "report-2",
                "images": (io.BytesIO(b"img"), "evidence.jpg", "image/jpeg"),
            },
            headers={"Authorization": "Bearer fake-token"},
            content_type="multipart/form-data",
        )
        self.assertEqual(response.status_code, 403)


if __name__ == "__main__":
    unittest.main()
