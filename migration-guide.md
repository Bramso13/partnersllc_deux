# Migration Guide: v1 → v2

## Overview

This guide helps you migrate from your current `database.sql` (v1) to the new `database-v2.sql` schema.

## ⚠️ IMPORTANT: Pre-Migration Checklist

- [ ] **Backup your database** before running any migration
- [ ] Test migration on a staging/development environment first
- [ ] Review all changes in this document
- [ ] Coordinate downtime window with your team
- [ ] Update your application code to match new schema

---

## What's Changed

### New Tables Added
1. `products` - Service catalog
2. `product_steps` - Workflow definitions per product
3. `payment_links` - Pre-registration payment links
4. `orders` - Purchase tracking
5. `payment_reminders` - Automated reminder system

### Modified Tables
1. `profiles` - Added `status` and `stripe_customer_id`
2. `dossiers` - Added `product_id` and `metadata`
3. `step_instances` - Added `assigned_to`
4. `documents` - Added `step_instance_id`
5. `events` - Added `actor_type` and `actor_id`
6. All tables with `updated_at` now have auto-update triggers

### New Enums
1. `user_status` - PENDING, ACTIVE, SUSPENDED
2. `order_status` - PENDING, PAID, FAILED, REFUNDED, CANCELLED
3. `actor_type` - USER, AGENT, SYSTEM

### Enhanced Enums
1. `dossier_type` - Added DUBAI, COMPLIANCE, ACCOUNTING
2. `dossier_status_code` - Added IN_PROGRESS, UNDER_REVIEW, COMPLETED
3. `event_type` - Added DOSSIER_CREATED, PAYMENT_RECEIVED, PAYMENT_FAILED, MESSAGE_SENT
4. `notification_status` - Added BOUNCED

### New Indexes
- 50+ performance indexes added
- See `database-v2.sql` lines 670-760

### New Triggers
- `update_*_updated_at` - Auto-update timestamps
- `create_dossier_status_event` - Auto-create events on status change
- `create_document_upload_event` - Auto-create events on upload

### Enhanced RLS Policies
- Complete CRUD policies for all user-facing tables
- Polymorphic actor support in policies

### New Utility Functions
- `get_next_step_for_dossier(uuid)`
- `are_step_documents_complete(uuid)`
- `generate_payment_link_token()`

---

## Migration Strategy Options

### Option A: Fresh Start (Recommended for Development)

If you don't have production data yet:

```bash
# 1. Drop existing database
psql -U postgres -c "DROP DATABASE IF EXISTS partners_vrai;"

# 2. Create new database
psql -U postgres -c "CREATE DATABASE partners_vrai;"

# 3. Apply new schema
psql -U postgres -d partners_vrai -f database-v2.sql

# 4. Verify
psql -U postgres -d partners_vrai -c "\dt"
```

### Option B: Incremental Migration (For Production)

If you have existing data to preserve:

```bash
# 1. Create migration files (see below)
# 2. Apply migrations sequentially
# 3. Verify data integrity
# 4. Update application code
```

---

## Incremental Migration SQL

### Step 1: Add New Enums

```sql
-- migration_001_add_enums.sql

-- User status
CREATE TYPE user_status AS ENUM (
  'PENDING',
  'ACTIVE',
  'SUSPENDED'
);

-- Order status
CREATE TYPE order_status AS ENUM (
  'PENDING',
  'PAID',
  'FAILED',
  'REFUNDED',
  'CANCELLED'
);

-- Actor type
CREATE TYPE actor_type AS ENUM (
  'USER',
  'AGENT',
  'SYSTEM'
);

-- Extend existing dossier_type
ALTER TYPE dossier_type ADD VALUE IF NOT EXISTS 'DUBAI';
ALTER TYPE dossier_type ADD VALUE IF NOT EXISTS 'COMPLIANCE';
ALTER TYPE dossier_type ADD VALUE IF NOT EXISTS 'ACCOUNTING';

-- Extend existing dossier_status_code
ALTER TYPE dossier_status_code ADD VALUE IF NOT EXISTS 'IN_PROGRESS';
ALTER TYPE dossier_status_code ADD VALUE IF NOT EXISTS 'UNDER_REVIEW';
ALTER TYPE dossier_status_code ADD VALUE IF NOT EXISTS 'COMPLETED';

-- Extend existing document_status
ALTER TYPE document_status ADD VALUE IF NOT EXISTS 'OUTDATED';

-- Extend existing event_type
ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'DOSSIER_CREATED';
ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'PAYMENT_RECEIVED';
ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'PAYMENT_FAILED';
ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'MESSAGE_SENT';

-- Extend existing notification_status
ALTER TYPE notification_status ADD VALUE IF NOT EXISTS 'BOUNCED';
```

### Step 2: Modify Existing Tables

```sql
-- migration_002_modify_tables.sql

-- Profiles: Add new columns
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS status user_status DEFAULT 'PENDING' NOT NULL,
ADD COLUMN IF NOT EXISTS stripe_customer_id text UNIQUE;

-- For existing users, set them as ACTIVE
UPDATE profiles SET status = 'ACTIVE' WHERE status IS NULL;

-- Dossiers: Add new columns
ALTER TABLE dossiers
ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES products(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- Step instances: Add assigned_to
ALTER TABLE step_instances
ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES agents(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- Documents: Add step_instance_id
ALTER TABLE documents
ADD COLUMN IF NOT EXISTS step_instance_id uuid REFERENCES step_instances(id) ON DELETE SET NULL;

-- Document versions: Add more metadata
ALTER TABLE document_versions
ADD COLUMN IF NOT EXISTS file_name text,
ADD COLUMN IF NOT EXISTS file_size_bytes bigint,
ADD COLUMN IF NOT EXISTS mime_type text,
ADD COLUMN IF NOT EXISTS uploaded_by_type actor_type,
ADD COLUMN IF NOT EXISTS version_number int DEFAULT 1;

-- For existing document_versions, set uploaded_by_type
UPDATE document_versions SET uploaded_by_type = 'USER' WHERE uploaded_by_type IS NULL;
ALTER TABLE document_versions ALTER COLUMN uploaded_by_type SET NOT NULL;

-- Rename uploaded_by to uploaded_by_id
ALTER TABLE document_versions RENAME COLUMN uploaded_by TO uploaded_by_id;
ALTER TABLE document_versions ALTER COLUMN uploaded_by_id SET NOT NULL;

-- Document reviews: Add notes
ALTER TABLE document_reviews
ADD COLUMN IF NOT EXISTS notes text;

-- Messages: Polymorphic sender
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS sender_type actor_type,
ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS read_at timestamptz;

-- For existing messages, set sender_type
UPDATE messages SET sender_type = 'USER' WHERE sender_type IS NULL;
ALTER TABLE messages ALTER COLUMN sender_type SET NOT NULL;

-- Rename sender_id (it's already correct, just ensure it's not null)
ALTER TABLE messages ALTER COLUMN sender_id SET NOT NULL;

-- Events: Add actor
ALTER TABLE events
ADD COLUMN IF NOT EXISTS actor_type actor_type,
ADD COLUMN IF NOT EXISTS actor_id uuid;

-- Notifications: Add more fields
ALTER TABLE notifications
ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES events(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS action_url text;

-- Notification deliveries: Add more fields
ALTER TABLE notification_deliveries
ADD COLUMN IF NOT EXISTS provider text,
ADD COLUMN IF NOT EXISTS provider_message_id text,
ADD COLUMN IF NOT EXISTS failed_at timestamptz;

-- Dossier status history: Polymorphic changed_by
ALTER TABLE dossier_status_history
ADD COLUMN IF NOT EXISTS changed_by_type actor_type,
ADD COLUMN IF NOT EXISTS old_status dossier_status_code,
ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- Rename new_status column (status → new_status)
-- First add the new column
ALTER TABLE dossier_status_history ADD COLUMN IF NOT EXISTS new_status dossier_status_code;
-- Copy data
UPDATE dossier_status_history SET new_status = status WHERE new_status IS NULL;
-- Make it NOT NULL
ALTER TABLE dossier_status_history ALTER COLUMN new_status SET NOT NULL;
-- Drop old column (optional - keep for backwards compatibility)
-- ALTER TABLE dossier_status_history DROP COLUMN status;

-- Rename changed_by to changed_by_id
ALTER TABLE dossier_status_history RENAME COLUMN changed_by TO changed_by_id;

-- Document types: Add more metadata
ALTER TABLE document_types
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS max_file_size_mb int DEFAULT 10,
ADD COLUMN IF NOT EXISTS allowed_extensions text[] DEFAULT array['pdf', 'jpg', 'png'],
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Steps: Add description
ALTER TABLE steps
ADD COLUMN IF NOT EXISTS description text;

-- Agents: Add active status
ALTER TABLE agents
ADD COLUMN IF NOT EXISTS active boolean DEFAULT true NOT NULL,
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
```

### Step 3: Create New Tables

```sql
-- migration_003_create_new_tables.sql

-- Products
CREATE TABLE IF NOT EXISTS products (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  dossier_type dossier_type not null,
  stripe_product_id text unique,
  stripe_price_id text,
  price_amount integer not null,
  currency text default 'USD' not null,
  initial_status dossier_status_code default 'QUALIFICATION' not null,
  active boolean default true not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint price_amount_positive check (price_amount >= 0)
);

-- Product Steps
CREATE TABLE IF NOT EXISTS product_steps (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  step_id uuid not null references steps(id) on delete cascade,
  position int not null,
  is_required boolean default true not null,
  estimated_duration_hours int,
  created_at timestamptz default now() not null,
  unique(product_id, step_id),
  unique(product_id, position),
  constraint position_positive check (position >= 0)
);

-- Payment Links
CREATE TABLE IF NOT EXISTS payment_links (
  id uuid primary key default gen_random_uuid(),
  token text unique not null,
  product_id uuid not null references products(id) on delete restrict,
  prospect_email text not null,
  prospect_name text,
  stripe_checkout_session_id text unique,
  created_by uuid references agents(id) on delete set null,
  expires_at timestamptz,
  used_at timestamptz,
  used_by uuid references profiles(id) on delete set null,
  created_at timestamptz default now() not null,
  constraint token_format check (length(token) >= 16),
  constraint expires_after_creation check (expires_at is null or expires_at > created_at)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  payment_link_id uuid references payment_links(id) on delete set null,
  dossier_id uuid references dossiers(id) on delete set null,
  amount integer not null,
  currency text default 'USD' not null,
  status order_status default 'PENDING' not null,
  stripe_checkout_session_id text unique,
  stripe_payment_intent_id text unique,
  stripe_customer_id text,
  metadata jsonb default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  constraint amount_positive check (amount > 0)
);

-- Payment Reminders
CREATE TABLE IF NOT EXISTS payment_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  order_id uuid not null references orders(id) on delete cascade,
  sent_via notification_channel not null,
  sent_at timestamptz default now() not null,
  clicked_at timestamptz
);
```

### Step 4: Add Indexes

```sql
-- migration_004_add_indexes.sql

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id ON profiles(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;

-- Products
CREATE INDEX IF NOT EXISTS idx_products_code ON products(code);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_products_dossier_type ON products(dossier_type);

-- Product Steps
CREATE INDEX IF NOT EXISTS idx_product_steps_product_id ON product_steps(product_id);
CREATE INDEX IF NOT EXISTS idx_product_steps_step_id ON product_steps(step_id);

-- Payment Links
CREATE INDEX IF NOT EXISTS idx_payment_links_token ON payment_links(token);
CREATE INDEX IF NOT EXISTS idx_payment_links_prospect_email ON payment_links(prospect_email);
CREATE INDEX IF NOT EXISTS idx_payment_links_product_id ON payment_links(product_id);
CREATE INDEX IF NOT EXISTS idx_payment_links_used_at ON payment_links(used_at);

-- Orders
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_link_id ON orders(payment_link_id);
CREATE INDEX IF NOT EXISTS idx_orders_dossier_id ON orders(dossier_id);
CREATE INDEX IF NOT EXISTS idx_orders_stripe_checkout_session_id ON orders(stripe_checkout_session_id);
CREATE INDEX IF NOT EXISTS idx_orders_stripe_payment_intent_id ON orders(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Dossiers
CREATE INDEX IF NOT EXISTS idx_dossiers_user_id ON dossiers(user_id);
CREATE INDEX IF NOT EXISTS idx_dossiers_product_id ON dossiers(product_id);
CREATE INDEX IF NOT EXISTS idx_dossiers_type ON dossiers(type);
CREATE INDEX IF NOT EXISTS idx_dossiers_status ON dossiers(status);
CREATE INDEX IF NOT EXISTS idx_dossiers_created_at ON dossiers(created_at DESC);

-- Step Instances
CREATE INDEX IF NOT EXISTS idx_step_instances_dossier_id ON step_instances(dossier_id);
CREATE INDEX IF NOT EXISTS idx_step_instances_step_id ON step_instances(step_id);
CREATE INDEX IF NOT EXISTS idx_step_instances_assigned_to ON step_instances(assigned_to);

-- Documents
CREATE INDEX IF NOT EXISTS idx_documents_dossier_id ON documents(dossier_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_step_instance_id ON documents(step_instance_id);

-- Document Versions
CREATE INDEX IF NOT EXISTS idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_document_versions_uploaded_at ON document_versions(uploaded_at DESC);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_entity ON events(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_actor ON events(actor_type, actor_id);
CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at DESC);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_dossier_id ON messages(dossier_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_type, sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Payment Reminders
CREATE INDEX IF NOT EXISTS idx_payment_reminders_user_id ON payment_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_reminders_order_id ON payment_reminders(order_id);
```

### Step 5: Add Triggers

```sql
-- migration_005_add_triggers.sql

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_types_updated_at BEFORE UPDATE ON document_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dossiers_updated_at BEFORE UPDATE ON dossiers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Event triggers
CREATE OR REPLACE FUNCTION create_dossier_status_event()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO events (entity_type, entity_id, event_type, payload)
    VALUES (
      'dossier',
      NEW.id,
      'DOSSIER_STATUS_CHANGED',
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status,
        'dossier_type', NEW.type
      )
    );

    INSERT INTO dossier_status_history (dossier_id, old_status, new_status)
    VALUES (NEW.id, OLD.status, NEW.status);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dossier_status_changed AFTER UPDATE ON dossiers
  FOR EACH ROW EXECUTE FUNCTION create_dossier_status_event();

CREATE OR REPLACE FUNCTION create_document_upload_event()
RETURNS TRIGGER AS $$
DECLARE
  v_dossier_id uuid;
BEGIN
  SELECT dossier_id INTO v_dossier_id FROM documents WHERE id = NEW.document_id;

  INSERT INTO events (entity_type, entity_id, event_type, payload)
  VALUES (
    'document',
    NEW.document_id,
    'DOCUMENT_UPLOADED',
    jsonb_build_object(
      'version_id', NEW.id,
      'version_number', NEW.version_number,
      'file_name', NEW.file_name,
      'dossier_id', v_dossier_id,
      'uploaded_by_type', NEW.uploaded_by_type,
      'uploaded_by_id', NEW.uploaded_by_id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER document_version_created AFTER INSERT ON document_versions
  FOR EACH ROW EXECUTE FUNCTION create_document_upload_event();
```

### Step 6: Add Utility Functions

```sql
-- migration_006_add_functions.sql

-- Get next step for dossier
CREATE OR REPLACE FUNCTION get_next_step_for_dossier(p_dossier_id uuid)
RETURNS uuid AS $$
DECLARE
  v_product_id uuid;
  v_current_position int;
  v_next_step_id uuid;
BEGIN
  SELECT
    d.product_id,
    ps.position
  INTO v_product_id, v_current_position
  FROM dossiers d
  LEFT JOIN step_instances si ON si.id = d.current_step_instance_id
  LEFT JOIN product_steps ps ON ps.step_id = si.step_id AND ps.product_id = d.product_id
  WHERE d.id = p_dossier_id;

  SELECT ps.step_id INTO v_next_step_id
  FROM product_steps ps
  WHERE ps.product_id = v_product_id
  AND ps.position > COALESCE(v_current_position, -1)
  ORDER BY ps.position
  LIMIT 1;

  RETURN v_next_step_id;
END;
$$ LANGUAGE plpgsql;

-- Check if step documents are complete
CREATE OR REPLACE FUNCTION are_step_documents_complete(p_step_instance_id uuid)
RETURNS boolean AS $$
DECLARE
  v_missing_count int;
BEGIN
  SELECT count(*)
  INTO v_missing_count
  FROM document_types dt
  JOIN step_instances si ON si.step_id = dt.required_step_id
  WHERE si.id = p_step_instance_id
  AND NOT EXISTS (
    SELECT 1 FROM documents d
    WHERE d.step_instance_id = si.id
    AND d.document_type_id = dt.id
    AND d.status = 'APPROVED'
  );

  RETURN v_missing_count = 0;
END;
$$ LANGUAGE plpgsql;

-- Generate payment link token
CREATE OR REPLACE FUNCTION generate_payment_link_token()
RETURNS text AS $$
BEGIN
  RETURN encode(gen_random_bytes(16), 'hex');
END;
$$ LANGUAGE plpgsql;
```

### Step 7: Update RLS Policies

```sql
-- migration_007_update_rls.sql

-- Enable RLS on new tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_reminders ENABLE ROW LEVEL SECURITY;

-- Orders: Users can view their own
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);

-- Payment Reminders: Users can view their own
CREATE POLICY "Users can view own payment reminders"
  ON payment_reminders FOR SELECT
  USING (auth.uid() = user_id);

-- Update existing policies for new columns
-- Drop old policies if they conflict
DROP POLICY IF EXISTS "Users can read their dossiers" ON dossiers;
DROP POLICY IF EXISTS "Users can read their notifications" ON notifications;

-- Recreate with better names
CREATE POLICY "Users can view own dossiers"
  ON dossiers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## Post-Migration Tasks

### 1. Seed Initial Data

```sql
-- Seed products
INSERT INTO products (code, name, description, dossier_type, price_amount, stripe_product_id, stripe_price_id, initial_status)
VALUES
  ('LLC_FORMATION', 'LLC Formation', 'Complete LLC formation service', 'LLC', 99900, 'prod_xxx', 'price_xxx', 'QUALIFICATION'),
  ('CORP_FORMATION', 'Corporation Formation', 'Complete corporation formation service', 'CORP', 149900, 'prod_yyy', 'price_yyy', 'QUALIFICATION'),
  ('DUBAI_SETUP', 'Dubai Business Setup', 'Complete Dubai business setup', 'DUBAI', 499900, 'prod_zzz', 'price_zzz', 'QUALIFICATION');

-- Seed steps
INSERT INTO steps (code, label, description, position)
VALUES
  ('QUALIFICATION', 'Qualification', 'Initial qualification and information gathering', 0),
  ('DOCUMENT_COLLECTION', 'Document Collection', 'Collect all required documents', 1),
  ('FORM_SUBMISSION', 'Form Submission', 'Submit formation documents', 2),
  ('PROCESSING', 'Processing', 'Processing with authorities', 3),
  ('COMPLETION', 'Completion', 'Final steps and delivery', 4);

-- Link steps to products
INSERT INTO product_steps (product_id, step_id, position, is_required)
SELECT
  p.id,
  s.id,
  s.position,
  true
FROM products p
CROSS JOIN steps s
WHERE p.code = 'LLC_FORMATION';

-- Seed document types
INSERT INTO document_types (code, label, description, required_step_id)
SELECT
  'PASSPORT',
  'Passport',
  'Valid passport copy',
  id
FROM steps WHERE code = 'DOCUMENT_COLLECTION';

INSERT INTO document_types (code, label, description, required_step_id)
SELECT
  'PROOF_ADDRESS',
  'Proof of Address',
  'Utility bill or bank statement (less than 3 months old)',
  id
FROM steps WHERE code = 'DOCUMENT_COLLECTION';
```

### 2. Update Application Code

Update your Next.js app to use new schema:

```typescript
// Old way
const { data: dossier } = await supabase
  .from('dossiers')
  .select('*')
  .eq('user_id', userId);

// New way (with product info)
const { data: dossier } = await supabase
  .from('dossiers')
  .select(`
    *,
    product:products(*),
    current_step:step_instances!current_step_instance_id(*)
  `)
  .eq('user_id', userId);
```

### 3. Set Up Stripe Webhooks

```bash
# Configure webhook endpoint
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# In production, set webhook URL in Stripe Dashboard:
# https://yourdomain.com/api/webhooks/stripe

# Events to listen for:
# - checkout.session.completed
# - payment_intent.succeeded
# - payment_intent.payment_failed
```

### 4. Create Cron Jobs

```typescript
// app/api/cron/payment-reminders/route.ts
export async function GET(req: Request) {
  // Verify cron secret
  if (req.headers.get('Authorization') !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  // Find suspended users
  const { data: suspendedUsers } = await supabase
    .from('profiles')
    .select('id, email, orders!inner(*)')
    .eq('status', 'SUSPENDED')
    .eq('orders.status', 'PENDING');

  // Send reminders
  for (const user of suspendedUsers) {
    // Send email reminder
    // Track in payment_reminders table
  }

  return new Response('OK', { status: 200 });
}
```

### 5. Update TypeScript Types

```typescript
// types/database.types.ts
export type UserStatus = 'PENDING' | 'ACTIVE' | 'SUSPENDED';
export type OrderStatus = 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED' | 'CANCELLED';
export type ActorType = 'USER' | 'AGENT' | 'SYSTEM';

export interface Profile {
  id: string;
  full_name: string | null;
  phone: string | null;
  status: UserStatus;
  stripe_customer_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: string;
  code: string;
  name: string;
  description: string | null;
  dossier_type: DossierType;
  stripe_product_id: string | null;
  stripe_price_id: string | null;
  price_amount: number;
  currency: string;
  initial_status: DossierStatusCode;
  active: boolean;
  created_at: string;
  updated_at: string;
}

// ... etc
```

---

## Verification Checklist

After migration:

- [ ] All tables exist: `\dt` in psql
- [ ] All indexes created: `\di` in psql
- [ ] All triggers active: `SELECT * FROM pg_trigger;`
- [ ] RLS enabled on user tables: `SELECT tablename FROM pg_tables WHERE rowsecurity = true;`
- [ ] Utility functions work: `SELECT get_next_step_for_dossier(null);` (should not error)
- [ ] Sample product created successfully
- [ ] Sample payment link created successfully
- [ ] Stripe webhook endpoint responds correctly
- [ ] Application loads without errors
- [ ] User can see their dossiers
- [ ] User can upload documents

---

## Rollback Plan

If migration fails:

```bash
# 1. Restore from backup
pg_restore -U postgres -d partners_vrai backup.dump

# 2. Or revert migrations one by one in reverse order
psql -U postgres -d partners_vrai -f migration_007_revert.sql
psql -U postgres -d partners_vrai -f migration_006_revert.sql
# ... etc
```

---

## Support

If you encounter issues during migration:

1. Check the error message carefully
2. Verify your PostgreSQL version (requires 12+)
3. Ensure Supabase is up to date
4. Review the `database-v2.sql` file for reference
5. Test on a separate database first

**Remember**: Always backup before migrating!
