-- Supabase schema for EcoAlert analytics and audit logs.

create table if not exists prediction_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null,
  city text,
  using_model boolean,
  risk_level text,
  probability double precision,
  predicted_aqi integer,
  predicted_category text,
  predicted_class integer
);

create table if not exists upload_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null,
  actor_uid text,
  report_id text,
  count integer
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  actor_uid text,
  action text not null,
  context jsonb
);
