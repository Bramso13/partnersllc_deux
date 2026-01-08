# PARTNERSLLC Product Requirements Document (PRD)

**Version:** 1.0
**Date:** January 6, 2026
**Status:** Ready for Architecture Phase
**Project:** PARTNERSLLC - Business Services SaaS Platform

---

## Goals and Background Context

### Goals

1. **Automate sales conversion** through payment link generation, transforming prospects into paying clients in a single streamlined flow
2. **Manage end-to-end client workflows** with configurable steps, versioned document management, and agent review capabilities
3. **Enable scalability** to support multiple service types (LLC formation, Dubai company creation, compliance, accounting, banking, etc.)
4. **Maximize agent efficiency** through a unified interface centralizing reviews, validations, and client communications
5. **Deliver transparency** to clients with real-time visibility into dossier status, progress tracking, and multi-channel notifications

### Background Context

PARTNERSLLC is a modular SaaS platform designed to revolutionize how structured business services are sold and managed. Traditional providers in the LLC formation, international company setup, and compliance space face significant operational challenges: fragmented tools requiring clients to navigate multiple systems, lack of transparency causing client anxiety and support overhead, manual processes that don't scale, and no unified workflow management for service delivery.

This platform addresses these pain points through three core innovations: (1) **Simplified client acquisition** via unique payment links that combine registration and payment in one step, (2) **Comprehensive workflow orchestration** with product-specific configurable steps, versioned document management, and structured agent review processes, and (3) **Event-driven automation** with multi-channel notifications (WhatsApp, Email, SMS, In-App, Push) ensuring all stakeholders stay informed without manual intervention.

The database schema has been fully designed and documented, providing a solid technical foundation. This PRD translates that technical architecture into user-facing features and development epics ready for implementation.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-01-06 | 1.0 | Initial PRD creation from project brief | John (PM Agent) |

---

## Requirements

### Functional Requirements

**FR1:** The system shall generate unique, single-use payment links with 32-character secure tokens that expire after a configurable period (default: 30 days)

**FR2:** The system shall combine user registration and Stripe payment in a single flow, creating auth user, profile, and order records before redirecting to Stripe Checkout

**FR3:** The system shall manage user status through three states: PENDING (registered but unpaid), ACTIVE (payment successful), and SUSPENDED (payment failed or account suspended)

**FR4:** The system shall automatically create a dossier with all associated step instances upon successful payment webhook receipt from Stripe

**FR5:** The system shall provide a product catalog where admins can define services with configurable workflow steps, required documents, and pricing

**FR6:** The system shall support document versioning, allowing users to upload new versions when documents are rejected, marking old versions as OUTDATED

**FR7:** The system shall enable agents to review documents with approve or reject actions, requiring rejection reasons and triggering automatic user notifications

**FR8:** The system shall enforce workflow progression logic, allowing step completion only when all required documents are APPROVED, then automatically advancing to the next step

**FR9:** The system shall implement event-driven architecture capturing all significant actions (dossier created, document uploaded, step completed, payment received, etc.) in an immutable event log

**FR10:** The system shall deliver notifications through multiple channels (WhatsApp, Email, SMS, In-App, Push) with delivery status tracking per channel

**FR11:** The system shall provide a messaging system enabling bidirectional communication between users and agents within dossier context, with real-time updates

**FR12:** The system shall automatically send payment reminders to SUSPENDED users every 3 days (configurable interval) until payment is completed

**FR13:** The system shall enforce Row-Level Security (RLS) policies ensuring users can only access their own dossiers, documents, and messages

**FR14:** The system shall display a complete timeline/history view showing all events and status changes for each dossier

**FR15:** The system shall provide an analytics dashboard for admins showing revenue metrics, conversion rates, dossier completion rates, and agent performance

**FR16:** The system shall support agent management, allowing admins to add agents, assign dossiers, and track agent workload

**FR17:** The system shall handle Stripe webhooks (checkout.session.completed, payment_intent.succeeded) with signature verification and idempotent processing

**FR18:** The system shall provide document preview capabilities for agents supporting PDF viewing and image display (JPG, PNG)

**FR19:** The system shall support bulk operations allowing agents to process multiple document reviews efficiently

**FR20:** The system shall provide a product and workflow configuration UI for admins to create products, define steps, and specify required document types per step

### Non-Functional Requirements

**NFR1:** Page load time must be under 2 seconds for 95th percentile of requests

**NFR2:** API response time must be under 500ms for 95th percentile of requests

**NFR3:** Document upload must support files up to 10MB in size

**NFR4:** The system must handle 1,000+ concurrent users without performance degradation

**NFR5:** Database architecture must efficiently handle 100,000+ dossiers with associated documents and events

**NFR6:** System availability must meet 99.9% uptime SLA (less than 43 minutes downtime per month)

**NFR7:** Row-Level Security (RLS) must be enforced on all user-accessible tables to prevent unauthorized data access

**NFR8:** Document storage URLs must be signed with expiration times to prevent unauthorized access

**NFR9:** All communication must be HTTPS-only with no fallback to HTTP

**NFR10:** The system must be GDPR compliant, supporting data export and deletion upon user request

**NFR11:** Automated daily backups must be performed with Recovery Time Objective (RTO) of less than 4 hours

**NFR12:** Stripe webhook requests must be verified using signature validation to prevent spoofing

**NFR13:** Payment processing must use Stripe Checkout Sessions supporting one-time payments with metadata tracking

**NFR14:** Notification delivery must implement retry logic with exponential backoff for failed deliveries

**NFR15:** Real-time message updates must use Supabase Realtime subscriptions with automatic reconnection handling

---

## User Interface Design Goals

### Overall UX Vision

The PARTNERSLLC platform prioritizes **clarity, transparency, and efficiency** across three distinct user experiences. For **clients**, the interface must eliminate confusion through guided workflows, clear progress indicators, and instant feedback on document status. For **agents**, the interface must optimize review throughput with streamlined document queues, batch operations, and contextual client information. For **admins**, the interface must provide comprehensive oversight through analytics dashboards and flexible configuration tools. All interfaces should feel modern, professional, and trustworthy, reflecting the serious nature of business formation services while remaining approachable for non-technical users.

### Key Interaction Paradigms

**Progressive Disclosure:** Show users only what they need at each step. Clients see current step requirements without overwhelming them with the entire workflow. Agents see pending items first, with deeper details available on demand.

**Status-Driven UI:** Interface adapts based on user state. SUSPENDED users see persistent payment completion prompts. ACTIVE users see their dossier dashboard. Empty states guide users toward next actions.

**Real-Time Feedback:** Document uploads trigger immediate confirmation. Agent reviews update client views instantly via Supabase Realtime. Message threads update without page refresh.

**Drag & Drop Simplicity:** Document upload areas accept drag-and-drop with clear visual feedback (hover states, upload progress, success confirmation).

**Contextual Actions:** Actions appear where users need them. Review buttons on document cards. "Complete Step" button appears only when all documents are approved.

### Core Screens and Views

**Client Interface:**
- Registration Page (`/register/{token}`) - Payment link landing with pre-filled email, registration form, and Stripe redirect
- Dashboard (`/dashboard`) - Account status hero, dossier cards with progress indicators, recent notifications feed
- Dossier Detail (`/dashboard/dossiers/{id}`) - Current step section, document upload area, document list with status badges, message thread, timeline
- Profile (`/dashboard/profile`) - Personal information editing, order/invoice history, notification preferences

**Agent Interface:**
- Agent Dashboard (`/admin/dashboard`) - Stats cards (pending reviews, active dossiers, completed today), recent activity feed, assigned dossiers
- Review Queue (`/admin/reviews`) - Sortable/filterable table of pending documents, bulk action support
- Document Review Modal - Full-screen document preview, client context sidebar, approve/reject actions
- Dossier Management (`/admin/dossiers/{id}`) - Comprehensive dossier view with admin actions (assign, change status, internal notes)
- Messaging Inbox (`/admin/messages`) - Conversation list with unread counts, threaded message view

**Admin Interface:**
- Products (`/admin/products`) - Product catalog table, workflow step configuration per product
- Payment Links (`/admin/payment-links`) - Link generation form, tracking table with usage analytics
- Analytics (`/admin/analytics`) - Revenue metrics, conversion funnel, completion rates, agent performance
- Settings (`/admin/settings`) - Agent management, notification templates, integration configurations

### Accessibility: WCAG AA

The platform will target **WCAG 2.1 Level AA compliance**, ensuring:
- Sufficient color contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Keyboard navigation support for all interactive elements
- Screen reader compatibility with semantic HTML and ARIA labels
- Form validation with clear error messaging
- Focus indicators for keyboard users
- Alt text for all meaningful images (document thumbnails, status icons)

### Branding

**To be defined by stakeholder input.** Recommendations:
- Professional color palette conveying trust and competence (blues, grays, with accent colors for status states)
- Clean, modern typography (sans-serif for clarity)
- Consistent iconography for document types, status indicators, and actions
- White-label capability for potential multi-tenant future expansion

### Target Device and Platforms: Web Responsive

**Primary Target:** Web Responsive supporting desktop, tablet, and mobile devices

**Desktop (1280px+):** Full multi-column layouts, side-by-side document preview and metadata, expanded tables with all columns visible

**Tablet (768px-1279px):** Adaptive layouts collapsing to single column where appropriate, drawer-based navigation, touch-optimized interactive elements

**Mobile (< 768px):** Mobile-first simplified views, bottom sheet modals for actions, vertical stacking of all content, touch-friendly 44px minimum touch targets

**Browser Support:** Modern evergreen browsers (Chrome, Firefox, Safari, Edge - last 2 versions)

**Future Consideration:** Native mobile apps for iOS/Android to enable push notifications and offline document access (not in MVP scope)

---

## Technical Assumptions

### Repository Structure: Monorepo

The project will use a **monorepo structure** with a single Next.js application containing all frontend code, server components, API routes, and Edge Functions.

**Rationale:** Monorepo simplifies deployment coordination, enables code sharing between client and server, and aligns with Next.js App Router architecture. For MVP scale (single product with clear boundaries), monorepo provides optimal developer experience without the overhead of managing multiple repositories.

### Service Architecture: Monolithic Next.js with Supabase Backend

**Architecture Pattern:** Serverless monolith using Next.js 14+ App Router with Supabase as Backend-as-a-Service (BaaS)

**Components:**
- **Next.js Frontend & API:** React Server Components, Client Components, Server Actions, API Routes
- **Supabase Services:** PostgreSQL database, Auth, Storage, Realtime, Edge Functions
- **External Integrations:** Stripe for payments, Twilio/SendGrid for notifications

**Rationale:** This architecture minimizes operational complexity for MVP while providing production-grade scalability. Supabase handles database scaling, auth, and storage, eliminating need for custom backend infrastructure. Next.js Server Components optimize performance. Edge Functions handle webhooks and cron jobs without separate service deployments.

**Future Migration Path:** If specific services require independent scaling (e.g., notification processing), they can be extracted to standalone services without rewriting the entire application.

### Testing Requirements

**Testing Strategy:** Comprehensive testing pyramid with focus on critical payment and workflow paths

**Levels:**
1. **Unit Tests:** Business logic, utility functions, React hooks (Vitest or Jest)
2. **Integration Tests:** API routes, Server Actions, database interactions (Vitest with Supabase test client)
3. **Component Tests:** React components in isolation (React Testing Library)
4. **E2E Tests:** Critical user journeys (Playwright)
   - Payment link registration → payment → dossier creation
   - Document upload → agent review → approval flow
   - Workflow step progression
   - SUSPENDED user payment recovery

**Manual Testing Support:** Seed scripts for development data, Stripe test mode configuration, mock notification providers for local development

**Coverage Targets:** 80%+ for business logic, 100% for payment-related code

**Rationale:** E2E tests protect critical revenue-generating flows. Integration tests ensure database schema and business logic alignment. Unit tests enable confident refactoring.

### Additional Technical Assumptions and Requests

**Frontend Stack:**
- **Framework:** Next.js 14+ (App Router, React Server Components, Server Actions)
- **Language:** TypeScript 5+ with strict mode enabled
- **Styling:** Tailwind CSS 3+ with custom design tokens
- **UI Components:** shadcn/ui for consistent, accessible component library
- **State Management:** React Context for global state (user session, notifications), Zustand for complex client-side state (multi-step forms)
- **Forms:** React Hook Form with Zod schema validation for type-safe form handling
- **Data Fetching:** Supabase Client (server-side and client-side), SWR or TanStack Query for client-side caching

**Backend & Infrastructure:**
- **Database:** PostgreSQL 15+ via Supabase (includes Row-Level Security, triggers, functions)
- **Authentication:** Supabase Auth with JWT tokens, email/password initially (OAuth future consideration)
- **File Storage:** Supabase Storage with signed URLs, organized by document type buckets
- **Real-Time:** Supabase Realtime for messages and notification updates
- **Webhooks & Cron:** Supabase Edge Functions (Deno runtime)
- **Database Schema:** Already defined in `database-v2.sql` (21 tables, full ERD available)

**Payments:**
- **Provider:** Stripe
- **Products:** Stripe Products with one-time Prices (no subscriptions in MVP)
- **Checkout:** Stripe Checkout Sessions with metadata (`order_id`, `user_id`, `product_id`)
- **Webhooks:** `checkout.session.completed`, `payment_intent.succeeded` handled via Edge Function with signature verification

**Notifications:**
- **Email Provider:** SendGrid (preferred) or Resend (fallback) - decision pending stakeholder accounts
- **WhatsApp Provider:** Twilio WhatsApp Business API (initial), Meta Business API (future for cost optimization)
- **SMS Provider:** Twilio
- **In-App:** Supabase Realtime subscriptions to `notifications` table
- **Push Notifications:** Not in MVP (requires native mobile apps)

**Deployment & Hosting:**
- **Frontend Hosting:** Vercel (optimal Next.js support, edge network, preview deployments)
- **Database & Backend:** Supabase Cloud (managed PostgreSQL, auto-scaling)
- **CDN:** Vercel Edge Network (automatic)
- **Monitoring:** Sentry for error tracking, Vercel Analytics for performance, Supabase Dashboard for database metrics
- **CI/CD:** GitHub Actions for tests, Vercel auto-deployment on merge to main

**Development Tools:**
- **Package Manager:** pnpm (faster, more efficient than npm/yarn)
- **Linting:** ESLint with TypeScript rules, Prettier for formatting
- **Git Hooks:** Husky for pre-commit linting and type checking
- **Environment Management:** .env.local for local, Vercel Environment Variables for production
- **API Documentation:** TypeScript types as source of truth, consider generating API docs from Supabase schema

**Security Assumptions:**
- All sensitive keys (Stripe, Supabase service role, notification providers) stored in environment variables, never committed
- Supabase RLS enforced on all tables - no service role usage in client code
- Document URLs signed with 1-hour expiration
- Stripe webhooks verified with signature before processing
- CORS configured to allow only production domain
- Rate limiting on public endpoints (registration, login) via Supabase Edge Functions or Vercel middleware

**Data Migration & Seeding:**
- Migration scripts for database schema updates (Supabase Migrations)
- Seed data for development: sample products (LLC Formation, Dubai Company), test agents, mock documents
- Production data import plan if migrating from existing system (not indicated in brief)

---

## Epic List

The PARTNERSLLC platform will be developed through **four sequential epics**, each delivering significant end-to-end functionality that can be deployed and tested independently. This structure ensures continuous value delivery while building toward the complete platform.

### Epic 1: Foundation & Core Payment Flow

Establish project infrastructure (Next.js app, Supabase database, authentication, Stripe integration) while delivering the first critical business capability: converting prospects into paying customers through payment link generation, user registration combined with payment, and webhook-driven account activation.

**[View Epic 1 Details →](prd/epic-1-foundation-core-payment-flow.md)**

**Stories:** 10 stories covering project setup, database deployment, authentication, Stripe integration, payment link generation, registration flow, checkout, webhook processing, and user status management.

---

### Epic 2: Dossier Management & Document Workflow

Build the core case management system enabling automatic dossier creation post-payment, client document uploads with versioning, agent document review capabilities with approve/reject actions, and basic workflow step progression, allowing the first complete client journey from payment to document submission and review.

**[View Epic 2 Details →](prd/epic-2-dossier-management-document-workflow.md)**

**Stories:** 7 stories covering client dashboard, dossier detail view, document upload with versioning, agent review queue, document review workflow, rejected document handling, and step completion.

---

### Epic 3: Workflow Automation & Notifications

Implement event-driven architecture capturing all system actions, multi-channel notification delivery (Email, WhatsApp, SMS, In-App), automated workflow step completion when documents are approved, and suspended user payment recovery with automatic reminders, transforming the platform from manual coordination to self-service automation.

**[View Epic 3 Details →](prd/epic-3-workflow-automation-notifications.md)**

**Stories:** 7 stories covering event architecture, email notifications, WhatsApp notifications, SMS notifications, in-app notifications, automated step completion, and payment recovery automation.

---

### Epic 4: Communication & Agent Efficiency Tools

Complete the platform with real-time user-agent messaging, comprehensive agent dashboard with review queue and bulk operations, admin tools for product/workflow configuration and payment link management, and analytics dashboards providing visibility into conversion rates, dossier completion, and agent performance.

**[View Epic 4 Details →](prd/epic-4-communication-agent-efficiency-tools.md)**

**Stories:** 7 stories covering real-time messaging, agent dashboard, enhanced dossier management, bulk review operations, product management UI, payment link analytics, and admin analytics dashboard.

---

**Epic Sequencing Rationale:**

This epic structure follows agile best practices by ensuring each epic delivers **deployable, testable business value**:

- **Epic 1** establishes foundational infrastructure but immediately delivers revenue-generating capability (payment links → conversions)
- **Epic 2** enables the core service delivery workflow (dossiers, documents, reviews)
- **Epic 3** removes manual intervention through automation and notifications
- **Epic 4** optimizes operations with communication tools and admin capabilities

Importantly, Epic 1 includes a "health check" milestone where basic authentication and database connectivity are verified, ensuring technical foundation is solid before building business features. Cross-cutting concerns like logging, error handling, and security are built into stories within each epic rather than deferred to the end.

---

## Checklist Results Report

### Executive Summary

**Overall PRD Completeness:** 83% ✅

**MVP Scope Appropriateness:** Just Right ✅
- Epic structure delivers incremental value
- Stories appropriately sized for AI agent execution
- Clear progression from infrastructure to automation to optimization
- No apparent scope bloat or feature creep

**Readiness for Architecture Phase:** Ready ✅
- Technical assumptions comprehensive and well-documented
- Database schema already defined (database-v2.sql)
- Integration points clearly identified
- Performance and security requirements specified
- Minor refinements recommended but not blocking

**Most Critical Gaps:**
1. Competitive analysis missing (medium priority - not blocking for architecture)
2. MVP validation approach and learning goals undefined (should define before development starts)
3. No diagrams/visuals in PRD (ERD exists separately but should be referenced)
4. Stakeholder alignment section missing (communication plan, approval process)

### Category Analysis Table

| Category                         | Status  | Critical Issues                                      |
| -------------------------------- | ------- | ---------------------------------------------------- |
| 1. Problem Definition & Context  | PARTIAL | Missing competitive analysis, no baseline metrics    |
| 2. MVP Scope Definition          | PARTIAL | No explicit "Out of Scope" section, validation plan  |
| 3. User Experience Requirements  | PASS    | Minor: branding TBD, content requirements light      |
| 4. Functional Requirements       | PASS    | None - comprehensive and well-structured             |
| 5. Non-Functional Requirements   | PASS    | Minor: maintenance/support details, security testing |
| 6. Epic & Story Structure        | PASS    | None - excellent structure and completeness          |
| 7. Technical Guidance            | PARTIAL | Missing tech debt guidance, investigation areas      |
| 8. Cross-Functional Requirements | PARTIAL | Data retention policies incomplete, support needs    |
| 9. Clarity & Communication       | PARTIAL | No diagrams, stakeholder section missing             |

**Legend:**
- **PASS:** 90%+ complete, ready for next phase
- **PARTIAL:** 60-89% complete, minor gaps exist
- **FAIL:** <60% complete, significant work needed

### Final Decision

**✅ READY FOR ARCHITECT**

The PRD and epics are comprehensive, properly structured, and provide sufficient guidance for architectural design to commence. The epic breakdown is logical, stories are well-defined with detailed acceptance criteria, and technical assumptions are clear.

**Rationale:**
- All critical requirements documented (functional, non-functional, user experience)
- Epic structure delivers incremental value with clear sequencing
- Technical constraints and integration points well-defined
- Database schema already designed (strong foundation)
- Story acceptance criteria comprehensive and testable
- Identified gaps are refinements, not blockers

**Architect can proceed immediately** with designing:
- Next.js application architecture
- Supabase Edge Functions for webhooks and cron
- API route structure
- Component architecture for UI
- Event processing system design
- Notification delivery orchestration

---

## Next Steps

### UX Expert Prompt

```
Review the PARTNERSLLC PRD (docs/prd.md) and create comprehensive UX/UI design deliverables.

Focus areas:
1. High-fidelity wireframes for all core screens (client dashboard, dossier detail, agent review queue, admin interfaces)
2. User flow diagrams for critical paths (payment link → registration → payment → dossier creation → document upload → review → completion)
3. Component library design system (buttons, cards, forms, modals, status badges, progress indicators)
4. Mobile responsive breakpoints and adaptive layouts
5. Accessibility annotations (WCAG AA compliance requirements)
6. Branding recommendations (color palette, typography, iconography)

Deliverables:
- Figma design file with all screens and components
- User journey flow diagrams
- Design system documentation
- Accessibility compliance checklist

Reference: PROJECT-BRIEF-PARTNERSLLC.md for user personas and UI requirements section in PRD for detailed screen definitions.
```

### Architect Prompt

```
Review the PARTNERSLLC PRD (docs/prd.md), database schema (database-v2.sql), and project brief (PROJECT-BRIEF-PARTNERSLLC.md) to create technical architecture specification.

Key design areas:
1. Next.js App Router structure (server components, client components, server actions, API routes)
2. Supabase integration architecture (database client, auth, storage, realtime, edge functions)
3. Stripe payment flow (checkout session creation, webhook processing, idempotency)
4. Event-driven architecture (event triggers, notification generation, delivery orchestration)
5. Multi-channel notification system (email, WhatsApp, SMS, in-app) with fallback logic
6. File upload and storage strategy (Supabase Storage buckets, signed URLs, versioning)
7. Real-time messaging implementation (Supabase Realtime subscriptions, presence)
8. RLS policy implementation strategy and performance optimization
9. Error handling, logging, and monitoring approach
10. Testing strategy architecture (unit, integration, E2E test structure)

Deliverables:
- Architecture specification document (docs/architecture.md)
- Component architecture diagrams
- Data flow diagrams for critical paths
- API endpoint specifications
- Edge Function designs for webhooks and cron jobs
- Security implementation plan
- Performance optimization strategy

Use the sharded PRD epics (docs/prd/epic-*.md) for detailed story-level requirements.
```

---

**Document Status:** Complete and ready for stakeholder review and architect handoff.

**Project Brief Reference:** See [PROJECT-BRIEF-PARTNERSLLC.md](../PROJECT-BRIEF-PARTNERSLLC.md) for additional context.

**Database Documentation:** See [database-v2.sql](../database-v2.sql) and [database-erd.md](../database-erd.md) for complete schema.
