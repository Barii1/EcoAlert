-- EcoAlert Backend Logging Tables
-- Run this once in Supabase Dashboard → SQL Editor
-- These tables are written by the Flask backend (using the service key, bypassing RLS).

-- ── prediction_logs ────────────────────────────────────────────────────────
-- Stores every cloudburst and AQI prediction made via the Flask API.
CREATE TABLE IF NOT EXISTS prediction_logs (
    id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    type               text        NOT NULL,           -- 'cloudburst' | 'cloudburst_features' | 'aqi'
    city               text,
    using_model        boolean,                        -- true = real ML model, false = rule-based
    risk_level         text,                           -- 'Low' | 'Moderate' | 'High' (cloudburst)
    probability        numeric,                        -- cloudburst_probability 0-1
    predicted_aqi      integer,                        -- aqi predictions
    predicted_category text,                           -- 'Good' | 'Moderate' | ...
    predicted_class    integer,
    created_at         timestamptz NOT NULL DEFAULT now()
);

-- Index for dashboard queries (latest N predictions by type)
CREATE INDEX IF NOT EXISTS prediction_logs_type_created
    ON prediction_logs (type, created_at DESC);

-- ── upload_logs ────────────────────────────────────────────────────────────
-- Stores every image upload (report images and profile pictures).
CREATE TABLE IF NOT EXISTS upload_logs (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    type       text        NOT NULL,   -- 'report_images' | 'profile_picture'
    report_id  text,                   -- set for report_images uploads
    actor_uid  text,                   -- Supabase user UUID
    count      integer,                -- number of images (report_images only)
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS upload_logs_actor_created
    ON upload_logs (actor_uid, created_at DESC);

-- ── audit_logs ─────────────────────────────────────────────────────────────
-- Stores admin actions (e.g. reading logs, approving reports via admin panel).
CREATE TABLE IF NOT EXISTS audit_logs (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_uid  text        NOT NULL,   -- Supabase user UUID of the admin
    action     text        NOT NULL,   -- e.g. 'read_logs', 'approve_report'
    context    jsonb,                  -- arbitrary key/value payload
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_logs_actor_created
    ON audit_logs (actor_uid, created_at DESC);

-- ── RLS: block direct client access ───────────────────────────────────────
-- The Flask backend uses the service key (bypasses RLS) to write these tables.
-- No Flutter client should ever read or write them directly.
ALTER TABLE prediction_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE upload_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs      ENABLE ROW LEVEL SECURITY;

-- No RLS policies = all client requests are blocked.
-- Service key from Flask bypasses RLS entirely.
