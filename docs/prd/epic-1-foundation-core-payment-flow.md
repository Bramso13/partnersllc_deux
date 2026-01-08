# Epic 1: Foundation & Core Payment Flow

**Epic Goal:** Establish the technical foundation for PARTNERSLLC (Next.js application, Supabase database, authentication, Stripe integration) and deliver the first critical business capability: converting prospects into paying customers through payment link generation, streamlined user registration combined with Stripe payment, and webhook-driven automatic account activation.

---

## Story 1.1: Project Initialization and Development Environment Setup

As a **developer**,
I want **the Next.js project initialized with TypeScript, Tailwind CSS, and essential tooling configured**,
so that **the team has a consistent, production-ready development environment from day one**.

### Acceptance Criteria

1. Next.js 14+ project created using `create-next-app` with TypeScript and App Router enabled
2. Tailwind CSS 3+ configured with custom design tokens file (`tailwind.config.ts`)
3. pnpm installed and configured as package manager with workspace settings
4. ESLint configured with TypeScript rules and Prettier for code formatting
5. Husky installed with pre-commit hooks running linting and type checking
6. Environment variables template created (`.env.example`) documenting all required keys
7. `.gitignore` configured to exclude `.env.local`, `node_modules`, `.next`, and build artifacts
8. README.md created with setup instructions, available scripts, and project structure overview
9. Basic folder structure established: `/app` (routes), `/components`, `/lib`, `/types`, `/styles`
10. Project builds successfully (`pnpm build`) and runs locally (`pnpm dev`) showing Next.js default page

---

## Story 1.2: Supabase Database Schema Implementation

As a **developer**,
I want **the complete database schema deployed to Supabase with all tables, functions, triggers, and RLS policies**,
so that **the application has a secure, fully-configured PostgreSQL database ready for integration**.

### Acceptance Criteria

1. Supabase project created (development environment) with PostgreSQL 15+ enabled
2. Database schema from `database-v2.sql` deployed successfully (all 21 tables created)
3. All SQL functions implemented: `generate_payment_link_token()`, `are_step_documents_complete()`, `get_next_step_for_dossier()`
4. All triggers configured: `create_dossier_status_change_event`, `create_document_upload_event`, `on_profile_status_change`
5. Row-Level Security (RLS) enabled on all user-facing tables (`profiles`, `dossiers`, `documents`, `messages`, `notifications`)
6. RLS policies created for USER role (read own data), AGENT role (read all, write reviews), and service role (bypass RLS)
7. Seed data inserted for development: 2 sample products (LLC Formation, Dubai Company Setup), 5 workflow steps, 3 document types
8. Test agent account created with AGENT role in Supabase Auth
9. Database connection tested from local Next.js app using Supabase client
10. ERD documentation (`database-erd.md`) matches deployed schema exactly

---

## Story 1.3: Authentication System with Supabase Auth

As a **user**,
I want **to create an account and log in securely using email and password**,
so that **I can access my personalized dashboard and dossiers**.

### Acceptance Criteria

1. Supabase Auth configured in Next.js app with environment variables (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`)
2. Server-side Supabase client created (`lib/supabase/server.ts`) using cookies for session management
3. Client-side Supabase client created (`lib/supabase/client.ts`) for browser interactions
4. Auth helper utilities created: `getUser()`, `getSession()`, `signOut()`
5. Login page created (`/login`) with email/password form using React Hook Form + Zod validation
6. Login form validates email format and password length (min 8 characters)
7. Successful login redirects to `/dashboard` with session cookie set
8. Failed login shows clear error message ("Invalid credentials")
9. Logout functionality implemented clearing session and redirecting to `/login`
10. Protected route middleware created redirecting unauthenticated users from `/dashboard/*` to `/login`
11. Auth state persists across page refreshes using Supabase session management
12. TypeScript types created for User and Session objects

---

## Story 1.4: Health Check Endpoint and Basic Deployment

As a **developer**,
I want **a health check API endpoint that verifies database connectivity and returns system status**,
so that **we can confirm the application is deployable and infrastructure is working correctly**.

### Acceptance Criteria

1. API route created at `/api/health` returning JSON status response
2. Health check verifies Supabase database connection by executing simple query (`SELECT 1`)
3. Response includes: `{ status: "healthy", database: "connected", timestamp: ISO8601 }`
4. Database connection failure returns `{ status: "unhealthy", database: "disconnected", error: message }` with 503 status code
5. Health check endpoint is publicly accessible (no authentication required)
6. Application deployed to Vercel (preview environment) successfully
7. Health check endpoint accessible at deployed URL and returns "healthy" status
8. Environment variables configured in Vercel (Supabase URL, anon key, service role key for backend)
9. Deployment logs show no errors, build completes in under 3 minutes
10. Vercel deployment URL shared with team for testing

---

## Story 1.5: Stripe Integration Setup and Configuration

As a **developer**,
I want **Stripe configured for test mode with Products, Prices, and webhook endpoints ready**,
so that **the application can create Checkout Sessions and handle payment events**.

### Acceptance Criteria

1. Stripe account created (or existing account configured) with test mode enabled
2. Stripe API keys added to environment variables (`STRIPE_SECRET_KEY`, `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`)
3. Stripe TypeScript SDK installed (`stripe` package) and initialized in server utility (`lib/stripe.ts`)
4. Two test products created in Stripe Dashboard: "LLC Formation - $999", "Dubai Company Setup - $1,499"
5. Stripe Product IDs and Price IDs documented in `.env.example`
6. Stripe webhook endpoint URL configured (pointing to deployed Vercel URL `/api/webhooks/stripe`)
7. Webhook events subscribed: `checkout.session.completed`, `payment_intent.succeeded`
8. Webhook signing secret added to environment variables (`STRIPE_WEBHOOK_SECRET`)
9. Stripe webhook test event sent successfully to endpoint (returns 200 OK)
10. Stripe CLI installed locally for webhook testing during development

---

## Story 1.6: Payment Link Generation (Admin Interface)

As an **admin**,
I want **to generate unique payment links for prospects by selecting a product and entering their email**,
so that **I can send personalized registration links that track conversions**.

### Acceptance Criteria

1. Admin page created at `/admin/payment-links` (protected, requires AGENT or ADMIN role)
2. Payment link generation form includes: Product dropdown, Prospect Email input, Expiration Days input (default: 30)
3. Form validation: Email format validated, Product selection required, Expiration Days must be 1-90
4. On submit, Server Action creates record in `payment_links` table with generated 32-character token
5. Token generated using `generate_payment_link_token()` database function ensuring uniqueness
6. Record includes: `product_id`, `prospect_email`, `expires_at` (calculated from expiration days), `status: ACTIVE`
7. Success message displays with copyable link: `{BASE_URL}/register/{token}`
8. Payment links table displayed below form showing: Token (truncated with copy button), Prospect Email, Product Name, Created Date, Status, Expiration Date
9. Table supports filtering by status (ACTIVE, USED, EXPIRED) and sorting by created date
10. Expired links automatically marked as EXPIRED (handled by database constraint or daily cron - note for future epic)

---

## Story 1.7: Payment Link Registration Page (Client-Facing)

As a **prospect**,
I want **to click a payment link and complete my registration in a single guided flow**,
so that **I can quickly sign up and proceed to payment without friction**.

### Acceptance Criteria

1. Registration page created at `/register/[token]` accepting payment link token as URL parameter
2. Page fetches payment link from database using token, verifying it exists and is not expired/used
3. Expired or invalid tokens show error page: "This link has expired. Please contact support."
4. Valid link displays: Product name, Price, Description, Pre-filled email (read-only)
5. Registration form includes fields: Full Name (required), Phone (required, international format), Password (required, min 8 chars, show/hide toggle)
6. Form validation using React Hook Form + Zod with real-time error display
7. "Complete Registration & Pay" button submits form and triggers Server Action
8. Server Action creates Supabase Auth user with email/password
9. Server Action creates `profiles` record with status: PENDING, linked to auth user
10. Server Action creates `orders` record with status: PENDING, linked to profile and product
11. Server Action marks payment link as USED (`used_at: now()`, `used_by_user_id: user.id`)
12. Server Action creates Stripe Checkout Session with metadata: `order_id`, `user_id`, `product_id`
13. Checkout Session configured with success URL (`/dashboard?payment=success`) and cancel URL (`/register/{token}?payment=cancelled`)
14. User redirected to Stripe Checkout Session URL
15. Loading state shown during all async operations with spinner
16. Error handling: Duplicate email shows "Account already exists. Please login.", network errors show retry option

---

## Story 1.8: Stripe Checkout Session Integration

As a **user**,
I want **a seamless Stripe payment experience that feels integrated with the platform**,
so that **I trust the payment process and complete my purchase confidently**.

### Acceptance Criteria

1. Stripe Checkout Session displays product name, price, and description from metadata
2. Checkout Session pre-fills customer email from registration
3. Checkout Session accepts test card numbers (4242 4242 4242 4242) in Stripe test mode
4. Payment method options enabled: Card only (no Apple Pay/Google Pay in MVP)
5. Successful payment redirects to success URL: `/dashboard?payment=success`
6. Cancelled payment redirects to cancel URL: `/register/{token}?payment=cancelled` with message "Payment was cancelled. Please try again."
7. Checkout Session expires after 24 hours if not completed
8. Checkout Session metadata includes all required fields for webhook processing: `order_id`, `user_id`, `product_id`
9. Stripe customer created automatically on successful payment with email and name
10. Receipt email sent automatically by Stripe upon successful payment

---

## Story 1.9: Stripe Webhook Handler for Payment Completion

As the **system**,
I want **to automatically activate user accounts and create dossiers when Stripe payments succeed**,
so that **users can immediately access their dashboard without manual intervention**.

### Acceptance Criteria

1. API route created at `/api/webhooks/stripe` handling POST requests
2. Webhook signature verified using `STRIPE_WEBHOOK_SECRET` before processing
3. Invalid signatures return 400 error immediately
4. `checkout.session.completed` event handler extracts metadata: `order_id`, `user_id`, `product_id`
5. Order record updated: `status: PAID`, `stripe_session_id`, `paid_at: now()`, `amount_paid`
6. Profile record updated: `status: ACTIVE`
7. Dossier record created with: `user_id`, `product_id`, `status: QUALIFICATION`, `created_by: SYSTEM`
8. Step instances created for all product steps (query `product_steps` joined with `steps`)
9. First step instance marked as started: `started_at: now()`
10. Dossier `current_step_instance_id` set to first step instance ID
11. Event created: `DOSSIER_CREATED` with actor: SYSTEM, payload including dossier ID
12. Event created: `PAYMENT_RECEIVED` with payment details
13. Webhook responds with 200 OK and `{ received: true }` within 5 seconds (Stripe timeout)
14. Idempotency handled: If webhook received twice (retry), check if order already PAID and skip processing
15. Error handling: Database errors logged to Sentry, webhook returns 500 causing Stripe retry
16. Webhook processing tested with Stripe CLI (`stripe trigger checkout.session.completed`)

---

## Story 1.10: User Status Management and Dashboard Access Control

As a **user**,
I want **my dashboard access and available features to reflect my account status (PENDING, ACTIVE, SUSPENDED)**,
so that **I understand what actions I need to take and what functionality is available to me**.

### Acceptance Criteria

1. Middleware created checking user status on all `/dashboard/*` routes
2. PENDING users accessing dashboard see message: "⏳ Your payment is being processed. You'll receive an email when your account is activated."
3. PENDING users can access `/dashboard/profile` to view order status but cannot access dossiers
4. ACTIVE users can access full dashboard: dossier list, dossier details, profile, notifications
5. SUSPENDED users accessing dashboard see persistent banner: "⚠️ Your payment was unsuccessful. Please complete your payment to access your dossier."
6. SUSPENDED users see "Complete Payment" button in banner redirecting to new Stripe Checkout Session
7. New Checkout Session for SUSPENDED users created with same product and order, new session ID
8. Dashboard homepage (`/dashboard`) shows different content based on status:
   - PENDING: Order status card with "Processing" indicator
   - ACTIVE: Dossier list cards with progress indicators
   - SUSPENDED: Payment required card with action button
9. TypeScript type guard created: `isActiveUser(user)`, `isPendingUser(user)`, `isSuspendedUser(user)`
10. Status-based UI components render conditionally without layout shift
11. Profile badge displays status with color coding: PENDING (yellow), ACTIVE (green), SUSPENDED (red)
12. E2E test created covering full flow: payment link → registration → payment → webhook → dashboard access
