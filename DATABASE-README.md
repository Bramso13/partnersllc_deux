# Partners VRAI - Database Documentation

## 📚 Documentation Overview

This folder contains complete database documentation for the Partners VRAI platform - a modular SaaS platform for business services (LLC formation, company setup, compliance, etc.) with payment link workflow integration.

---

## 📁 Files in This Package

### 1. `database-v2.sql` ⭐ **MAIN SCHEMA FILE**
Complete, production-ready PostgreSQL schema including:
- ✅ All tables (20+ tables)
- ✅ All enums (9 enums)
- ✅ All foreign key constraints (properly defined)
- ✅ 50+ performance indexes
- ✅ Auto-update triggers for `updated_at`
- ✅ Event sourcing triggers
- ✅ Complete RLS policies
- ✅ Utility functions
- ✅ Table comments/documentation

**Use this file for:**
- New project setup
- Fresh database initialization
- Reference implementation

---

### 2. `database-erd.md` 📊 **VISUAL DIAGRAMS**
Visual representation of the database schema:
- **Full ERD diagram** (Mermaid format - viewable in GitHub, VS Code, etc.)
- **Flow diagrams** for payment and workflow processes
- **Table relationship summary**
- **Index strategy documentation**
- **Domain grouping** (authentication, payments, workflow, documents, etc.)

**Use this for:**
- Understanding table relationships
- Onboarding new developers
- Architecture reviews
- System documentation

---

### 3. `business-processes.md` 🔄 **PROCESS DOCUMENTATION**
Step-by-step business process implementation guides:

#### Covered Processes:
1. **Payment Link Generation & User Onboarding**
   - Admin generates link → User pre-registers → Payment → Account activation
2. **Dossier Creation & Workflow Initialization**
   - Automatic dossier creation after successful payment
3. **Step Execution & Document Management**
   - User uploads documents → Version tracking
4. **Document Review Process**
   - Agent reviews → Approve/Reject → User notifications
5. **Status Transitions & State Management**
   - Moving through workflow steps
6. **Event & Notification System**
   - Event creation → Multi-channel notifications
7. **Payment Reminders for Suspended Users**
   - Automated email reminders for unpaid accounts
8. **Stripe Webhook Handling**
   - Complete webhook implementation examples

**Each process includes:**
- SQL queries with real examples
- TypeScript/Next.js code snippets
- Data flow explanations
- Edge case handling

**Use this for:**
- Implementing backend logic
- Understanding business rules
- Debugging issues
- Developer training

---

### 4. `migration-guide.md` 🔧 **MIGRATION INSTRUCTIONS**
Complete guide for migrating from `database.sql` (v1) to `database-v2.sql`:

**Includes:**
- What changed (new tables, modified tables, new enums)
- Two migration strategies:
  - **Option A**: Fresh start (drop & recreate)
  - **Option B**: Incremental migration (preserve data)
- 7 sequential migration SQL files
- Post-migration tasks (seeding, app updates, cron jobs)
- Verification checklist
- Rollback plan

**Use this for:**
- Upgrading existing databases
- Production deployments
- Understanding changes from v1 to v2

---

### 5. `database.sql` 📜 **ORIGINAL SCHEMA (v1)**
Your original database schema (preserved for reference).

**Status:** Replaced by `database-v2.sql`

**Issues fixed in v2:**
- ❌ Missing foreign key constraints
- ❌ No indexes (performance issues)
- ❌ Incomplete RLS policies
- ❌ No payment/product tables
- ❌ No updated_at triggers
- ❌ Missing utility functions

---

## 🚀 Quick Start Guide

### For New Projects

```bash
# 1. Create database
psql -U postgres -c "CREATE DATABASE partners_vrai;"

# 2. Apply schema
psql -U postgres -d partners_vrai -f database-v2.sql

# 3. Verify
psql -U postgres -d partners_vrai -c "\dt"

# 4. Seed initial data (see migration-guide.md Step "Seed Initial Data")
```

### For Existing Projects

```bash
# 1. BACKUP YOUR DATABASE FIRST!
pg_dump -U postgres partners_vrai > backup_$(date +%Y%m%d).sql

# 2. Follow migration-guide.md for incremental migration
# Apply migrations 001 through 007 sequentially

# 3. Verify and update application code
```

---

## 🎯 Key Features

### Payment Flow Integration
- **Pre-registration workflow**: User registers → Pays → Account activated
- **Payment links**: Admin-generated unique links per prospect
- **Suspended user handling**: Automated reminders for unpaid accounts
- **Stripe integration**: Webhooks, checkout sessions, payment intents

### Workflow Management
- **Product-based workflows**: Each product defines its own steps
- **Step instances**: Track execution per dossier
- **Document requirements**: Per-step document requirements
- **Progress tracking**: Current step, completion status

### Document Management
- **Versioning**: Full version history per document
- **Review system**: Agent approval/rejection workflow
- **Type safety**: Document type definitions
- **Audit trail**: Who uploaded, when, from which step

### Event-Driven Architecture
- **Event sourcing**: Immutable event log
- **Auto-triggers**: Events created automatically on key actions
- **Notification system**: Multi-channel delivery (Email, WhatsApp, SMS, In-App)
- **Audit trail**: Complete history of all actions

### Security & Performance
- **Row Level Security (RLS)**: Users can only see their own data
- **50+ indexes**: Optimized for common queries
- **Polymorphic relationships**: Flexible actor types (USER, AGENT, SYSTEM)
- **Constraints**: Data integrity enforced at database level

---

## 📋 Database Statistics

### Tables
- **Total**: 21 tables
- **Core entities**: profiles, agents, products, dossiers
- **Workflow**: steps, product_steps, step_instances
- **Documents**: document_types, documents, document_versions, document_reviews
- **Payment**: payment_links, orders, payment_reminders
- **Communication**: messages, events, notifications, notification_deliveries

### Enums
- `user_status` (3 values)
- `dossier_type` (6 values)
- `dossier_status_code` (13 values)
- `document_status` (4 values)
- `review_status` (2 values)
- `event_type` (9 values)
- `notification_channel` (5 values)
- `notification_status` (4 values)
- `order_status` (5 values)
- `actor_type` (3 values)

### Indexes
- **Total**: 50+ indexes
- **User queries**: user_id, dossier_id, status
- **Admin queries**: assigned_to, reviewer_id
- **Webhooks**: stripe_checkout_session_id, stripe_payment_intent_id
- **Events**: entity_type+entity_id, created_at
- **Performance**: All foreign keys indexed

### Functions
- `get_next_step_for_dossier(uuid)` - Get next workflow step
- `are_step_documents_complete(uuid)` - Check if step can be completed
- `generate_payment_link_token()` - Generate secure tokens
- `update_updated_at_column()` - Auto-update timestamps

### Triggers
- 7 auto-update triggers for `updated_at`
- 2 event creation triggers (status changes, document uploads)

---

## 🔐 Security Implementation

### Row Level Security (RLS)

**Enabled on all user-facing tables:**
- profiles, dossiers, step_instances
- documents, document_versions, document_reviews
- orders, messages, events
- notifications, notification_deliveries, payment_reminders

**Policy Examples:**
```sql
-- Users can only see their own dossiers
CREATE POLICY "Users can view own dossiers"
  ON dossiers FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only upload docs for their dossiers
CREATE POLICY "Users can upload documents"
  ON documents FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM dossiers
      WHERE dossiers.id = documents.dossier_id
      AND dossiers.user_id = auth.uid()
    )
  );
```

**Admin Access:**
Admins bypass RLS using service role key (never exposed to frontend).

---

## 📊 Common Queries

### Get User Dashboard Data
```sql
SELECT
  d.id,
  d.status,
  p.name as product_name,
  s.label as current_step,
  d.created_at,
  (
    SELECT count(*)
    FROM documents doc
    WHERE doc.dossier_id = d.id
    AND doc.status = 'PENDING'
  ) as pending_documents
FROM dossiers d
JOIN products p ON p.id = d.product_id
LEFT JOIN step_instances si ON si.id = d.current_step_instance_id
LEFT JOIN steps s ON s.id = si.step_id
WHERE d.user_id = '<user_id>'
ORDER BY d.created_at DESC;
```

### Get Pending Reviews for Agent
```sql
SELECT
  d.id as document_id,
  dt.label as document_type,
  dos.id as dossier_id,
  p.full_name as user_name,
  dv.file_url,
  dv.uploaded_at
FROM documents d
JOIN document_versions dv ON dv.id = d.current_version_id
JOIN document_types dt ON dt.id = d.document_type_id
JOIN dossiers dos ON dos.id = d.dossier_id
JOIN profiles p ON p.id = dos.user_id
WHERE d.status = 'PENDING'
ORDER BY dv.uploaded_at ASC;
```

### Get Suspended Users for Reminders
```sql
SELECT
  p.id,
  p.email,
  p.full_name,
  o.id as order_id,
  o.amount,
  pr.name as product_name,
  o.created_at
FROM profiles p
JOIN orders o ON o.user_id = p.id
JOIN products pr ON pr.id = o.product_id
WHERE p.status = 'SUSPENDED'
AND o.status = 'PENDING'
AND NOT EXISTS (
  SELECT 1 FROM payment_reminders rem
  WHERE rem.user_id = p.id
  AND rem.order_id = o.id
  AND rem.sent_at > now() - interval '3 days'
);
```

---

## 🎨 Architecture Patterns

### Event Sourcing
All significant actions create immutable events:
- Dossier status changes
- Document uploads
- Step completions
- Payment events

**Benefits:**
- Complete audit trail
- Debugging capabilities
- Analytics & reporting
- Notification triggering

### Polymorphic Relationships
Using `type + id` pattern for flexibility:
- `messages.sender_type` + `sender_id` (USER, AGENT, SYSTEM)
- `events.actor_type` + `actor_id`
- `document_versions.uploaded_by_type` + `uploaded_by_id`

**Benefits:**
- Flexible actor types
- Easy to extend
- Clean queries

### Document Versioning
Separate tables for documents and versions:
- `documents` - Logical document
- `document_versions` - Physical versions
- `documents.current_version_id` points to latest

**Benefits:**
- Full version history
- Easy rollback
- Review tracking per version

---

## 🛠️ Development Tips

### Local Development with Supabase

```bash
# Start Supabase locally
supabase start

# Apply migrations
supabase db reset

# Or apply specific file
psql -h localhost -p 54322 -U postgres -d postgres -f database-v2.sql
```

### Testing Queries

```sql
-- Enable timing
\timing on

-- Explain query plans
EXPLAIN ANALYZE
SELECT * FROM dossiers WHERE user_id = '...';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan;
```

### Monitoring Performance

```sql
-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 📞 Support & Questions

For questions or issues:
1. Check `business-processes.md` for implementation examples
2. Review `database-erd.md` for relationship understanding
3. Consult `migration-guide.md` for upgrade paths
4. Examine `database-v2.sql` for schema details

---

## ✅ Validation Checklist

Before deploying to production:

- [ ] All migrations applied successfully
- [ ] Indexes created (verify with `\di`)
- [ ] RLS enabled on user tables
- [ ] Triggers active
- [ ] Utility functions working
- [ ] Sample data seeded (products, steps, document types)
- [ ] Stripe webhooks configured
- [ ] Application code updated to match schema
- [ ] TypeScript types generated
- [ ] Tests passing
- [ ] Backup strategy in place
- [ ] Monitoring configured

---

## 🎉 Summary

You now have:

✅ **Production-ready database schema** with all constraints, indexes, and security
✅ **Visual documentation** with ERD diagrams and flow charts
✅ **Complete business process guides** with SQL and code examples
✅ **Migration path** from v1 to v2 with step-by-step instructions
✅ **Utility functions** for common operations
✅ **Event-driven architecture** with automatic triggers
✅ **Multi-channel notifications** system
✅ **Payment link workflow** fully integrated

**Next Steps:**
1. Review the ERD diagram to understand relationships
2. Read business processes for your use case
3. Apply the schema or run migrations
4. Implement Stripe webhook handler
5. Build your Next.js frontend with confidence!

**Good luck building your platform! 🚀**
