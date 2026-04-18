# EcoAlert Backend (Flask + Supabase + Firestore)

## 1. Prerequisites

- Python 3.10+ (recommended: Python 3.11)
- `pip` installed and available in terminal
- Firebase Admin SDK service account JSON file (`firebase-adminsdk.json`)
- Supabase account and project

## 2. Setup Steps (In Exact Order)

1. Clone the repo or navigate to this folder:
   - `backend/ecoalert-backend`
2. Create a virtual environment:
   - `python -m venv venv`
3. Activate the virtual environment:
   - Mac/Linux: `source venv/bin/activate`
   - Windows: `venv\Scripts\activate`
4. Install dependencies:
   - `pip install -r requirements.txt`
5. Copy `.env.example` to `.env`, then fill these values:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`
   - `FIREBASE_PROJECT_ID`
6. Place `firebase-adminsdk.json` in the project root (`backend/ecoalert-backend`).
7. Start the server:
   - `python app.py`

## 3. How To Get Credentials

- `firebase-adminsdk.json`:
  - Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
- `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`:
  - Supabase Console -> Project Settings -> API -> Project API keys
- `FIREBASE_PROJECT_ID`:
  - Firebase Console -> Project Settings -> General -> Project ID

## 4. Available Endpoints

- `GET /health`
- `POST /api/upload/report-images`
  - Form fields: `report_id`, `images[]`
- `POST /api/upload/profile-picture`
  - Form fields: `uid`, `image`

## 5. Important Security Notes

- Never commit `.env` or `firebase-adminsdk.json` to Git.
- The Supabase `service_role` key is private; never put it in Flutter code.
