# PARTNERSLLC - Project Brief for PRD

**Project Name:** PARTNERSLLC
**Document Type:** Product Brief for PRD Development
**Date:** January 2026
**Status:** Database Schema Complete - Ready for PRD Creation
**Prepared for:** Product Manager

---

## 📋 Executive Summary

**PARTNERSLLC** est une plateforme SaaS modulaire permettant de vendre et gérer des services business structurés (formation LLC, création société Dubai, compliance, comptabilité, banking) avec un workflow automatisé de bout en bout.

**Proposition de valeur unique:**
- Parcours client simplifié : 1 lien de paiement → Inscription + Paiement en une étape → Dossier créé automatiquement
- Gestion workflow complète par produit avec étapes configurables, documents versionnés, et revues agents
- Automatisation totale via events et notifications multi-canaux

**Tech Stack:**
- Frontend: Next.js (React)
- Backend: Supabase (PostgreSQL + Auth + RLS + Storage)
- Payments: Stripe (Checkout, Webhooks)
- Notifications: WhatsApp, Email, SMS, In-App, Push

---

## 🎯 Business Objectives

### Primary Goals
1. **Automatiser la vente** : Générer des liens de paiement, convertir prospects en clients payants
2. **Gérer les workflows** : Suivre chaque dossier client de A à Z avec étapes prédéfinies
3. **Scalabilité** : Supporter plusieurs types de services (LLC, CORP, Dubai, Banking, Compliance, etc.)
4. **Efficacité agent** : Centraliser reviews, validations, communications dans une interface unique

### Success Metrics
- **Conversion rate** : % de liens de paiement → paiements réussis (Target: >60%)
- **Time to completion** : Durée moyenne d'un dossier du paiement à la clôture (Target: <30 jours)
- **Client satisfaction** : NPS score (Target: >70)
- **Agent productivity** : Nombre de dossiers traités par agent/jour (Target: 10+)
- **Payment recovery** : % de SUSPENDED users qui finissent par payer (Target: >40%)

---

## 👥 User Personas

### Persona 1: Client (End User)
**Profil:** Entrepreneur, freelance, ou business owner qui a besoin d'une LLC, société Dubai, ou services compliance.

**Besoins:**
- Processus simple et guidé
- Transparence sur l'avancement
- Upload facile de documents
- Communication rapide avec les agents
- Notifications claires à chaque étape

**Pain Points:**
- Trop de steps compliqués
- Manque de visibilité sur le statut
- Délais de réponse longs
- Ne sait pas quels documents fournir

### Persona 2: Agent (Internal)
**Profil:** Employé interne qui gère les dossiers clients, valide documents, et communique avec les clients.

**Besoins:**
- Dashboard avec tous les dossiers assignés
- Review facile de documents (approve/reject)
- Messagerie intégrée par dossier
- Historique complet des actions

**Pain Points:**
- Trop d'outils dispersés
- Manque de contexte sur le client
- Difficulté à prioriser les tâches urgentes
- Documents difficiles à retrouver

### Persona 3: Admin (Super User)
**Profil:** Manager ou ops lead qui configure les produits, génère payment links, et supervise l'activité.

**Besoins:**
- Créer et gérer les produits/services
- Générer des payment links pour prospects
- Analytics et reporting
- Gérer les agents et assignments

**Pain Points:**
- Impossible de tracker les conversions
- Pas de vue d'ensemble sur la performance
- Configuration manuelle fastidieuse

---

## 🔑 Core Features

### 1. Payment Link System (Pre-Registration + Payment)

**User Flow:**
```
Admin génère link → Prospect reçoit email → Prospect s'inscrit (nom, email, password, tel)
→ Redirect Stripe Checkout → Paiement → Webhook → User ACTIVE + Dossier créé
```

**Key Capabilities:**
- Admin génère lien unique par prospect (1 lien = 1 produit)
- Lien contient email pré-rempli
- Expiration configurable (ex: 30 jours)
- Tracking: lien utilisé par qui, quand
- Single-use (cannot be reused)

**Technical Details:**
- Table: `payment_links`
- Token: 32 caractères sécurisés (via `generate_payment_link_token()`)
- Stripe Checkout Session créée après pre-registration
- Metadata: `order_id`, `user_id`, `product_id`

**Edge Cases:**
- Lien expiré → Message clair + contact admin
- Lien déjà utilisé → Redirect login
- Paiement échoue → User SUSPENDED, reminders automatiques

---

### 2. User Status Management

**3 Status:**
- **PENDING**: Inscrit mais pas payé (accès limité au payment)
- **ACTIVE**: Payé, peut accéder à son dashboard
- **SUSPENDED**: Paiement échoué ou compte suspendu

**Suspended User Flow:**
- Login → Banner "Complete Payment" persistant
- Email automatique tous les 3 jours (configurable)
- Click email → Nouveau Stripe Checkout Session
- Paiement réussi → ACTIVE, dossier créé

**Technical:**
- Table: `profiles.status`
- Cron job: Check SUSPENDED users daily
- Table: `payment_reminders` track envois

---

### 3. Product Catalog & Workflow Configuration

**Product Structure:**
```
Product (LLC Formation - $999)
  ├── Step 1: Qualification
  ├── Step 2: Document Collection (requires: Passport, Proof of Address)
  ├── Step 3: Form Submission
  ├── Step 4: Processing
  └── Step 5: Completion
```

**Admin Capabilities:**
- Create/edit products (name, description, price, Stripe product ID)
- Define workflow steps per product (via `product_steps`)
- Set required documents per step (via `document_types.required_step_id`)
- Set initial dossier status (ex: QUALIFICATION)

**Technical:**
- Tables: `products`, `product_steps`, `steps`, `document_types`
- One product → Multiple steps (ordered by `position`)
- Steps réutilisables entre produits

---

### 4. Dossier Management (Client Dashboard)

**Client sees:**
- Liste de ses dossiers (peut avoir plusieurs si achète plusieurs services)
- Statut actuel (QUALIFICATION, IN_PROGRESS, COMPLETED, etc.)
- Étape courante avec label + description
- Progress bar (Step 2/5)
- Documents à uploader pour cette étape
- Messages/communication avec agents
- Historique complet (timeline)

**Actions:**
- Upload document (PDF, JPG, PNG)
- Envoyer message à l'agent
- Voir statut de validation de chaque document (PENDING, APPROVED, REJECTED)
- Télécharger documents validés

**Technical:**
- Table: `dossiers`
- Relation: `dossiers.current_step_instance_id` → `step_instances`
- Query: Join avec `products`, `step_instances`, `steps`, `documents`

---

### 5. Document Upload & Versioning

**User Flow:**
```
User upload doc → Version 1 créée (status: PENDING)
→ Agent review → APPROVED ou REJECTED
→ Si REJECTED: User upload nouvelle version (version 2, ancienne = OUTDATED)
→ Agent re-review → APPROVED
```

**Features:**
- Versioning automatique (v1, v2, v3...)
- Metadata: file size, mime type, uploaded by (USER/AGENT/SYSTEM)
- Storage: Supabase Storage (buckets par type de doc)
- Preview: Inline pour PDF, image viewer pour JPG/PNG

**Technical:**
- Tables: `documents`, `document_versions`, `document_reviews`
- `documents.current_version_id` pointe vers latest version
- Trigger: `create_document_upload_event()` auto-crée event + notification

---

### 6. Agent Review System

**Agent Dashboard:**
- Liste des documents PENDING (tous dossiers)
- Filtres: par type de doc, par dossier, par date upload
- Preview du document
- Actions: Approve, Reject (avec raison)

**Review Flow:**
```
Agent ouvre doc → Preview → Décision:
  - APPROVE: doc.status = APPROVED, event créé, user notifié
  - REJECT: doc.status = REJECTED, reason mandatory, user notifié avec message
```

**Technical:**
- Table: `document_reviews`
- Chaque review liée à une version spécifique (`document_version_id`)
- `reviewer_id` = agent qui a fait la review
- Notification automatique au user après review

---

### 7. Workflow Progression

**Step Completion Logic:**
```sql
-- Step peut être complété si:
SELECT are_step_documents_complete('<step_instance_id>');
-- Returns TRUE si tous les docs requis sont APPROVED

-- Quand step complété:
1. Mark step_instance.completed_at = now()
2. Get next step: SELECT get_next_step_for_dossier('<dossier_id>')
3. Start next step: step_instance.started_at = now()
4. Update dossier.current_step_instance_id
5. Event créé: STEP_COMPLETED
6. Notification user: "Étape X terminée, passez à l'étape Y"
```

**Manual vs Automatic:**
- **Manual**: Agent clique "Complete Step" après vérification
- **Automatic** (future): Trigger auto si `are_step_documents_complete() = TRUE`

---

### 8. Event-Driven Architecture

**Events Automatiques:**
- `DOSSIER_CREATED` - Dossier créé après paiement
- `DOSSIER_STATUS_CHANGED` - Status change (via trigger)
- `STEP_STARTED` - Step commence
- `STEP_COMPLETED` - Step terminé
- `DOCUMENT_UPLOADED` - Doc uploadé (via trigger)
- `DOCUMENT_REVIEWED` - Agent review
- `PAYMENT_RECEIVED` - Paiement réussi (webhook)
- `PAYMENT_FAILED` - Paiement échoué
- `MESSAGE_SENT` - Message envoyé

**Event → Notification Flow:**
```
Event créé → Notification générée → Deliveries créées (Email, WhatsApp, In-App, SMS)
→ Background job process queue → Delivery status updated (SENT/FAILED)
```

**Technical:**
- Table: `events` (immutable, never delete)
- Payload: JSONB avec context
- Actor: Who triggered (USER, AGENT, SYSTEM)

---

### 9. Multi-Channel Notifications

**Channels Supported:**
- **EMAIL**: Transactional emails (SendGrid, AWS SES, etc.)
- **WHATSAPP**: WhatsApp Business API (Twilio, Meta)
- **IN_APP**: Dashboard notifications (bell icon)
- **SMS**: Fallback si WhatsApp fail
- **PUSH**: Mobile notifications (future)

**Notification Types:**
- Welcome (after payment)
- Document uploaded confirmation
- Document approved/rejected
- Step completed
- Payment reminder (SUSPENDED users)
- Message from agent

**Technical:**
- Tables: `notifications`, `notification_deliveries`
- One notification → Multiple deliveries (cross-channel)
- Provider tracking: `provider_message_id`, `provider_response`
- Retry logic for failed deliveries

---

### 10. Messaging System

**Features:**
- One thread per dossier
- User ↔ Agent communication
- Real-time updates (Supabase Realtime)
- File attachments support (JSONB array)
- Read receipts (`read_at`)

**Technical:**
- Table: `messages`
- Polymorphic sender: `sender_type` (USER, AGENT, SYSTEM) + `sender_id`
- RLS: Users can only see messages for their dossiers
- Notification created on new message

---

## 🔐 Security & Permissions

### Row Level Security (RLS)

**User Permissions:**
- ✅ Read: Own profile, own dossiers, own documents, own orders, own notifications
- ✅ Write: Upload documents for own dossiers, send messages, update profile
- ❌ Cannot: See other users' data, modify documents after upload, delete anything

**Agent Permissions:**
- ✅ Read: All dossiers, all documents, all users
- ✅ Write: Review documents, send messages, update dossier status, assign steps
- ❌ Cannot: Delete dossiers, modify payment records

**Admin Permissions:**
- ✅ Full access via service role (bypasses RLS)
- Manage products, agents, generate payment links, analytics

### Authentication
- Supabase Auth (email/password)
- JWT tokens (managed by Supabase)
- Session management (refresh tokens)

---

## 🎨 User Interfaces (High-Level)

### Client Interface

**1. Registration Page** (`/register/{token}`)
- Payment link info display
- Form: Full Name, Phone, Password
- "Complete Registration & Pay" button → Stripe

**2. Dashboard** (`/dashboard`)
- Hero: Account status (ACTIVE/SUSPENDED)
- If SUSPENDED: Payment banner
- List of dossiers (cards with status, progress)
- Recent notifications

**3. Dossier Detail** (`/dashboard/dossiers/{id}`)
- Header: Product name, status badge, progress bar
- Current step section with description
- Document upload area (drag & drop)
- Document list with status badges
- Message thread
- Timeline (history of events)

**4. Profile** (`/dashboard/profile`)
- Edit name, phone
- View orders/invoices
- Notification preferences

---

### Agent Interface

**1. Dashboard** (`/admin/dashboard`)
- Stats cards: Pending reviews, Active dossiers, Completed today
- Recent activity feed
- Assigned dossiers list

**2. Review Queue** (`/admin/reviews`)
- Table: Document, Client, Uploaded, Type, Actions
- Filters: Type, Date, Status
- Bulk actions

**3. Document Review Modal**
- Document preview (PDF viewer, image viewer)
- Client info sidebar
- Review history
- Actions: Approve, Reject (with reason text area)

**4. Dossier Management** (`/admin/dossiers/{id}`)
- Full dossier view (same as client but with admin actions)
- Assign to agent
- Change status manually
- Add internal notes
- View full event log

**5. Messaging** (`/admin/messages`)
- Inbox style (list of dossiers with unread count)
- Click → Message thread opens
- Send message to client

---

### Admin Interface

**1. Products** (`/admin/products`)
- Table: Name, Type, Price, Active, Actions
- Create/Edit product modal
- Configure workflow steps per product

**2. Payment Links** (`/admin/payment-links`)
- Generate new link form (select product, enter prospect email)
- Table: Token (copyable), Prospect, Product, Created, Used, Status
- Analytics: Conversion rate

**3. Analytics** (`/admin/analytics`)
- Revenue metrics
- Conversion funnel
- Dossier completion rates
- Agent performance
- Document approval rates

**4. Settings** (`/admin/settings`)
- Manage agents (add/remove, assign roles)
- Notification templates
- Stripe integration settings
- Email/WhatsApp provider configs

---

## 🗺️ User Journeys

### Journey 1: New Client Purchase (Happy Path)

```
1. Admin generates payment link for john@example.com (Product: LLC Formation - $999)
2. John receives email: "You're invited to start your LLC formation"
3. John clicks link → /register/{token}
4. John fills form: Name, Phone, Password
5. John clicks "Complete Registration & Pay"
6. Backend:
   - Creates auth user
   - Creates profile (status: PENDING)
   - Creates order (status: PENDING)
   - Marks payment link as used
   - Creates Stripe Checkout Session
7. John redirected to Stripe
8. John enters card, pays $999
9. Stripe webhook: checkout.session.completed
10. Backend:
    - Updates order (status: PAID)
    - Updates profile (status: ACTIVE)
    - Creates dossier (type: LLC, status: QUALIFICATION)
    - Creates step instances (5 steps)
    - Sets current step to Step 1
    - Sends welcome notification (Email, WhatsApp, In-App)
11. John receives email: "Welcome! Your dossier is ready. Next step: Qualification"
12. John logs in → Dashboard
13. John sees dossier card: "LLC Formation - Step 1/5 - QUALIFICATION"
14. John clicks dossier → Current step: "Please upload Passport and Proof of Address"
15. John uploads 2 documents
16. Events created: DOCUMENT_UPLOADED × 2
17. Notifications sent to John: "Documents received, under review"
18. Agent Sarah sees 2 pending reviews in her queue
19. Sarah opens Passport → Approves
20. Sarah opens Proof of Address → Rejects (reason: "Document is blurry")
21. John receives notification: "Passport approved ✅, Proof of Address rejected ❌"
22. John uploads new version of Proof of Address
23. Sarah reviews → Approves
24. All docs approved → Agent clicks "Complete Step 1"
25. Backend:
    - Marks step 1 completed
    - Starts step 2
    - Updates dossier.current_step_instance_id
    - Event: STEP_COMPLETED
26. John receives notification: "Step 1 completed! Next: Form Submission"
27. ... Process continues through 5 steps ...
28. Final step completed → Dossier status = COMPLETED
29. John receives notification: "🎉 Your LLC formation is complete!"
```

### Journey 2: Suspended User Recovery

```
1. John registers but payment fails (card declined)
2. Profile status: SUSPENDED
3. Order status: PENDING
4. John tries to login → Redirected to dashboard
5. Dashboard shows: "⚠️ Complete your payment to access your dossier"
6. Banner with "Pay Now" button
7. Click → New Stripe Checkout Session created
8. John pays successfully
9. Webhook triggers activation (same as Journey 1 step 9-10)
10. John can now access dossier
```

### Journey 3: Agent Daily Workflow

```
1. Sarah logs in → Agent Dashboard
2. Sees: "12 pending reviews, 8 assigned dossiers, 3 new messages"
3. Clicks "Review Queue"
4. Sees table sorted by upload date (oldest first)
5. Clicks first document (Passport - uploaded 2 days ago)
6. Modal opens with PDF preview
7. Sarah zooms, checks validity
8. Clicks "Approve"
9. Document status updated, client notified
10. Modal auto-closes, next document loads
11. Sarah processes 12 reviews in 20 minutes
12. Checks "Messages" inbox
13. Responds to 3 client questions
14. Goes to "My Dossiers" (assigned to her)
15. Clicks dossier #1234
16. Sees all 3 documents approved → Clicks "Complete Step"
17. Dossier moves to next step, client notified
```

---

## 📊 Data Model Summary

**See `database-v2.sql` and `database-erd.md` for full details.**

### Core Tables (21 total)

**Users & Auth:**
- `profiles` - User accounts (linked to Supabase auth.users)
- `agents` - Internal staff

**Products & Catalog:**
- `products` - Services catalog (LLC, CORP, Dubai, etc.)
- `steps` - Workflow step definitions
- `product_steps` - Which steps per product
- `document_types` - Document type definitions

**Payment Flow:**
- `payment_links` - Generated links for prospects
- `orders` - Purchase records
- `payment_reminders` - Reminder tracking

**Dossiers & Workflow:**
- `dossiers` - Client cases
- `dossier_status_history` - Audit trail
- `step_instances` - Step execution per dossier

**Documents:**
- `documents` - Logical documents
- `document_versions` - Version history
- `document_reviews` - Agent reviews

**Communication:**
- `messages` - User ↔ Agent messaging
- `events` - Event log (immutable)
- `notifications` - Logical notifications
- `notification_deliveries` - Multi-channel delivery tracking

---

## 🚀 Technical Architecture

### Frontend (Next.js 14+)
- **Framework**: Next.js App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: shadcn/ui
- **State Management**: React Context + Zustand (for complex state)
- **Forms**: React Hook Form + Zod validation
- **API**: Supabase Client (server & client components)

### Backend (Supabase)
- **Database**: PostgreSQL 15+
- **Auth**: Supabase Auth (JWT)
- **Storage**: Supabase Storage (documents)
- **Realtime**: Supabase Realtime (messages, notifications)
- **Edge Functions**: Webhook handlers, cron jobs

### Payments (Stripe)
- **Products**: Stripe Products
- **Prices**: Stripe Prices (one-time payments)
- **Checkout**: Stripe Checkout Sessions
- **Webhooks**: `checkout.session.completed`, `payment_intent.succeeded`

### Notifications
- **Email**: SendGrid, AWS SES, or Resend
- **WhatsApp**: Twilio, Meta Business API
- **SMS**: Twilio
- **In-App**: Supabase Realtime subscriptions

### Hosting & Deployment
- **Frontend**: Vercel
- **Database**: Supabase Cloud
- **CDN**: Vercel Edge Network
- **Monitoring**: Sentry, Vercel Analytics

---

## 📅 Development Phases (Suggested)

### Phase 1: Core Platform (MVP) - 8 weeks
**Goal:** Payment link → User registration → Dossier creation → Document upload → Agent review

**Features:**
- Payment link generation (admin)
- User registration + Stripe payment
- Webhook handler (activate user, create dossier)
- Client dashboard (view dossier, upload docs)
- Agent dashboard (review docs, approve/reject)
- Basic notifications (email only)

**Deliverables:**
- Working payment flow
- 1 product (LLC Formation)
- 5 steps configured
- 2 document types (Passport, Proof of Address)
- Email notifications

### Phase 2: Workflow & Communication - 4 weeks
**Goal:** Full workflow progression + messaging

**Features:**
- Step completion logic
- Automatic step progression
- Messaging system (user ↔ agent)
- Timeline/history view
- Enhanced notifications (WhatsApp, In-App)

### Phase 3: Multi-Product & Admin - 4 weeks
**Goal:** Scale to multiple products + admin tools

**Features:**
- Product management UI
- Workflow builder (admin can configure steps)
- Document type configuration
- Analytics dashboard
- Agent management

### Phase 4: Optimization & Scale - 4 weeks
**Goal:** Performance, UX polish, automation

**Features:**
- Payment reminder automation (cron)
- Bulk operations (agent review multiple docs)
- Mobile responsive polish
- Performance optimization
- Advanced analytics
- Notification preferences

---

## 🎯 Key Business Rules

### Payment
- ✅ One payment = One dossier
- ✅ Payment links are single-use
- ✅ SUSPENDED users can retry payment unlimited times
- ✅ Reminders sent every 3 days to SUSPENDED users

### Dossiers
- ✅ One user can have multiple dossiers (different products)
- ✅ Dossiers follow product-specific workflows
- ✅ Status transitions logged in history (audit trail)

### Documents
- ✅ Versioning: User can upload new version if rejected
- ✅ Reviews tied to specific version
- ✅ Old versions marked OUTDATED, not deleted

### Steps
- ✅ Step can only complete if all required docs APPROVED
- ✅ Steps executed in order (position)
- ✅ Cannot skip steps

### Notifications
- ✅ Multi-channel: Try WhatsApp first, fallback to Email/SMS
- ✅ Delivery status tracked per channel
- ✅ In-App notifications always created

---

## 🔢 Non-Functional Requirements

### Performance
- Page load: < 2 seconds
- API response: < 500ms (p95)
- Document upload: Support up to 10MB
- Concurrent users: Support 1000+ simultaneous

### Scalability
- Database: Handle 100K+ dossiers
- Storage: Unlimited documents (Supabase handles scaling)
- Webhook processing: Queue-based (handle spikes)

### Security
- RLS enforced on all user tables
- API keys never exposed to frontend
- Stripe webhooks verified with signature
- Document URLs signed (expiring URLs)
- HTTPS only

### Compliance
- GDPR compliant (data export, deletion on request)
- Audit trail (events table tracks all actions)
- Document retention policy (configurable)

### Availability
- Uptime: 99.9% SLA
- Backup: Daily automated backups
- Disaster recovery: < 4 hour RTO

---

## 📝 Open Questions for PM

1. **Document Retention:** How long should we keep OLD versions of documents? Forever or auto-delete after X months?

2. **Agent Assignment:** Should dossiers auto-assign to agents (round-robin) or manual assignment?

3. **Refunds:** What happens if a client requests refund after dossier started? Manual process or automated?

4. **Multi-language:** Do we need i18n support? Which languages?

5. **Mobile App:** Native mobile app in roadmap or web-responsive enough?

6. **Pricing:** Dynamic pricing per client (coupons, discounts) or fixed prices only?

7. **Webhook Failures:** If Stripe webhook fails, do we have manual reconciliation UI?

8. **Document Expiry:** Should documents expire (e.g., passport expires in 6 months)?

9. **Agent Roles:** Different agent roles (reviewer, manager, support) or all same permissions?

10. **Notifications Preferences:** Can users opt-out of certain notification channels?

---

## 📦 Deliverables for PRD Creation

### Included in this package:
✅ `database-v2.sql` - Complete database schema
✅ `database-erd.md` - Visual ERD diagrams
✅ `business-processes.md` - Process flows with SQL/code examples
✅ `migration-guide.md` - Migration instructions
✅ `DATABASE-README.md` - Complete database documentation
✅ **This document** - Project brief for PRD

### What PM needs to create:
📝 Detailed PRD with:
- User stories (As a [user], I want [feature], so that [benefit])
- Acceptance criteria per feature
- Wireframes/mockups (Figma designs)
- Edge case handling
- Error message copy
- Email templates copy
- Success metrics per feature
- A/B test hypotheses

---

## 🎉 Next Steps

1. **Review this brief** with stakeholders
2. **Answer open questions** above
3. **Create wireframes** for key screens
4. **Write detailed PRD** with user stories
5. **Prioritize features** for MVP
6. **Dev team estimation** (story points)
7. **Kick off Phase 1** development

---

**Questions?** Contact the technical architect or review the database documentation files.

**Ready to build!** 🚀
