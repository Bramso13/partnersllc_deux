-- =========================================================
-- EXTENSION
-- =========================================================
create extension if not exists "pgcrypto";

-- =========================================================
-- ENUMS
-- =========================================================
create type dossier_type as enum (
  'LLC',
  'CORP',
  'BANKING'
);

create type dossier_status_code as enum (
  'QUALIFICATION',
  'FORM_SUBMITTED',
  'NM_PENDING',
  'LLC_ACCEPTED',
  'EIN_PENDING',
  'BANK_PREPARATION',
  'BANK_OPENED',
  'WAITING_48H',
  'CLOSED',
  'ERROR'
);

create type document_status as enum (
  'PENDING',
  'APPROVED',
  'REJECTED'
);

create type review_status as enum (
  'APPROVED',
  'REJECTED'
);

create type event_type as enum (
  'DOSSIER_STATUS_CHANGED',
  'STEP_STARTED',
  'STEP_COMPLETED',
  'DOCUMENT_UPLOADED',
  'DOCUMENT_REVIEWED',
  'ERROR'
);

create type notification_channel as enum (
  'WHATSAPP',
  'EMAIL',
  'IN_APP',
  'SMS',
  'PUSH'
);

create type notification_status as enum (
  'PENDING',
  'SENT',
  'FAILED'
);

-- =========================================================
-- PROFILES (lié à auth.users)
-- =========================================================
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz default now()
);

-- =========================================================
-- AGENTS
-- =========================================================
create table agents (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text,
  created_at timestamptz default now()
);

-- =========================================================
-- DOSSIERS
-- =========================================================
create table dossiers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  type dossier_type not null,
  status dossier_status_code not null,
  current_step_id uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =========================================================
-- DOSSIER STATUS HISTORY
-- =========================================================
create table dossier_status_history (
  id uuid primary key default gen_random_uuid(),
  dossier_id uuid references dossiers(id) on delete cascade,
  status dossier_status_code not null,
  changed_by uuid,
  reason text,
  created_at timestamptz default now()
);

-- =========================================================
-- STEPS
-- =========================================================
create table steps (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  label text,
  position int not null
);

create table step_instances (
  id uuid primary key default gen_random_uuid(),
  dossier_id uuid references dossiers(id) on delete cascade,
  step_id uuid references steps(id),
  started_at timestamptz,
  completed_at timestamptz
);

-- =========================================================
-- DOCUMENTS
-- =========================================================
create table document_types (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  label text,
  required_step_id uuid references steps(id)
);

create table documents (
  id uuid primary key default gen_random_uuid(),
  dossier_id uuid references dossiers(id) on delete cascade,
  document_type_id uuid references document_types(id),
  status document_status default 'PENDING',
  created_at timestamptz default now()
);

create table document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id) on delete cascade,
  file_url text not null,
  uploaded_by uuid,
  uploaded_at timestamptz default now()
);

create table document_reviews (
  id uuid primary key default gen_random_uuid(),
  document_version_id uuid references document_versions(id) on delete cascade,
  reviewer_id uuid references agents(id),
  status review_status not null,
  reason text,
  reviewed_at timestamptz default now()
);

-- =========================================================
-- MESSAGES
-- =========================================================
create table messages (
  id uuid primary key default gen_random_uuid(),
  dossier_id uuid references dossiers(id) on delete cascade,
  sender_id uuid,
  content text not null,
  created_at timestamptz default now()
);

-- =========================================================
-- EVENTS
-- =========================================================
create table events (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  event_type event_type not null,
  payload jsonb,
  created_at timestamptz default now()
);

-- =========================================================
-- NOTIFICATIONS (logique)
-- =========================================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  dossier_id uuid references dossiers(id) on delete cascade,
  title text,
  message text,
  template_code text,
  payload jsonb,
  read_at timestamptz,
  created_at timestamptz default now()
);

-- =========================================================
-- NOTIFICATION DELIVERIES (multi-canal)
-- =========================================================
create table notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid references notifications(id) on delete cascade,
  channel notification_channel not null,
  recipient text,
  status notification_status default 'PENDING',
  provider_response jsonb,
  sent_at timestamptz,
  created_at timestamptz default now()
);

-- =========================================================
-- RLS : DOSSIERS
-- =========================================================
alter table dossiers enable row level security;

create policy "Users can read their dossiers"
on dossiers
for select
using (user_id = auth.uid());

-- =========================================================
-- RLS : NOTIFICATIONS
-- =========================================================
alter table notifications enable row level security;

create policy "Users can read their notifications"
on notifications
for select
using (user_id = auth.uid());
