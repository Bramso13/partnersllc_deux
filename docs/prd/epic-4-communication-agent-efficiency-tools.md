# Epic 4: Communication & Agent Efficiency Tools

**Epic Goal:** Complete the platform with real-time bidirectional messaging enabling seamless user-agent communication within dossier context, a comprehensive agent dashboard displaying key performance metrics and workload, enhanced admin tools for product/workflow configuration and payment link management, and analytics dashboards providing visibility into conversion rates, dossier completion, and agent performance.

---

## Story 4.1: Real-Time Messaging System (User ↔ Agent)

As a **user**,
I want **to send messages to agents about my dossier and receive responses in real-time**,
so that **I can ask questions, provide clarifications, and communicate without leaving the platform**.

### Acceptance Criteria

1. Message thread component embedded in dossier detail page (`/dashboard/dossiers/[id]`)
2. Messages fetched from `messages` table filtered by `dossier_id` with RLS enforcement
3. Messages displayed chronologically (oldest first or newest first, user preference toggle)
4. Each message shows: Sender name/avatar, Message text, Timestamp, Read status
5. User messages aligned right (blue background), agent messages aligned left (gray background), system messages centered (light background)
6. Message input textarea at bottom with "Send" button
7. Textarea supports multi-line input, expands up to 5 lines, includes character counter (max 2000 characters)
8. Send button disabled when textarea empty or exceeds character limit
9. Sending message creates `messages` record: `dossier_id`, `sender_type: USER`, `sender_id`, `message_text`, `created_at`
10. Message appears immediately in thread (optimistic UI update)
11. Supabase Realtime subscription on `messages` table filtered by dossier_id
12. New messages from agent appear in real-time without page refresh with subtle notification sound (optional, user can mute)
13. Sending message creates `MESSAGE_SENT` event triggering notification to assigned agent
14. Unread message count badge shown on dossier card and in notifications bell
15. Messages marked as read when user views dossier (`read_at: now()`)
16. File attachment support: Allow attaching images/PDFs (stored in Supabase Storage, link in `attachments` JSONB field)
17. Agent view (at `/admin/dossiers/[id]`) includes same message thread with agent's ability to respond
18. Typing indicator shows "Agent is typing..." when agent is composing response (via Supabase Realtime presence)

---

## Story 4.2: Agent Dashboard with Key Metrics

As an **agent**,
I want **a dashboard showing my workload, pending tasks, and performance metrics**,
so that **I can prioritize my work and track my productivity**.

### Acceptance Criteria

1. Agent dashboard at `/admin/dashboard` displays personalized metrics for logged-in agent
2. Stats cards at top showing:
   - Pending Reviews: Count of documents with `status: PENDING` (clickable, links to review queue)
   - Assigned Dossiers: Count of active dossiers assigned to agent
   - Completed Today: Count of documents reviewed today
   - Avg Review Time: Average time between upload and review completion
3. Recent activity feed showing last 20 events across all agent's assigned dossiers
4. Activity feed displays: Event type icon, Description ("John Doe uploaded Passport for LLC-123"), Timestamp (relative)
5. "My Dossiers" section listing dossiers assigned to agent with quick actions
6. Dossier quick view cards show: Client name, Product, Current step, Pending documents count, Last activity
7. Unread messages indicator on dossiers with new client messages
8. Quick action buttons: "Review Docs", "View Dossier", "Send Message"
9. Performance charts (optional enhancement): Line chart showing reviews completed per day over last 30 days
10. Dashboard refreshes every 60 seconds to show updated counts
11. Empty states with helpful messages when no pending tasks
12. Dashboard responsive: Stacked cards on mobile, grid layout on desktop

---

## Story 4.3: Enhanced Agent Dossier Management View

As an **agent**,
I want **comprehensive tools to manage dossiers including status changes, internal notes, and assignment**,
so that **I can handle exceptional cases and maintain clear records**.

### Acceptance Criteria

1. Agent dossier view at `/admin/dossiers/[id]` shows all client-visible info plus admin controls
2. Admin actions sidebar includes:
   - Change Status dropdown (manually override status: QUALIFICATION, IN_PROGRESS, PENDING_REVIEW, COMPLETED, CANCELLED)
   - Assign to Agent dropdown (reassign dossier to different agent)
   - Add Internal Note text area (notes visible only to agents, not clients)
   - Complete Step button (manual override for step completion)
   - Cancel Dossier button (with confirmation modal)
3. Status change creates `DOSSIER_STATUS_CHANGED` event and notification to client
4. Internal notes stored in `dossier_notes` table: `dossier_id`, `agent_id`, `note_text`, `created_at`
5. Notes timeline displayed in agent view showing all historical notes
6. Assignment change updates `dossiers.assigned_agent_id`, creates event, notifies new agent
7. Full event log displayed in expandable section showing all system events with technical details (JSON payload)
8. Document history shows all versions of all documents with review details
9. Manual step completion bypasses auto-completion logic, allows completing even if docs not all approved (for exceptional cases)
10. Cancel dossier confirmation modal warns about implications, requires cancellation reason
11. Cancelled dossiers marked `status: CANCELLED`, `cancelled_at: now()`, `cancellation_reason` stored
12. Client notification sent when dossier cancelled
13. Audit trail tracks all agent actions (status changes, notes, assignments) with timestamps and agent names

---

## Story 4.4: Bulk Document Review Operations

As an **agent**,
I want **to approve or reject multiple documents at once**,
so that **I can process reviews more efficiently when handling batches of similar documents**.

### Acceptance Criteria

1. Review queue table includes checkbox column for selecting multiple documents
2. "Select All" checkbox in header selects all documents on current page
3. Bulk action bar appears when one or more documents selected
4. Bulk action bar shows: "X documents selected", "Approve All" button, "Reject All" button, "Clear Selection" link
5. "Approve All" button processes all selected documents, creating APPROVED reviews for each
6. "Reject All" button requires rejection reason (single reason applied to all selected documents)
7. Bulk operations process asynchronously (background job) for large selections (>10 documents)
8. Progress indicator shows "Processing X of Y documents..." during bulk operation
9. Success notification shows summary: "15 documents approved, 3 failed (errors listed)"
10. Failed documents remain selected, allowing agent to retry or handle individually
11. Bulk operation creates individual `document_reviews` records for each document (not a single batch record)
12. Events and notifications created for each document individually (not batched notification)
13. Bulk approve disabled if selected documents are from different document types (safety check - agent should review similar docs together)
14. Action history logs bulk operations with count and affected document IDs

---

## Story 4.5: Admin Product Management UI

As an **admin**,
I want **to create and configure products with their workflow steps and required documents**,
so that **I can add new services without requiring developer involvement**.

### Acceptance Criteria

1. Products page at `/admin/products` lists all products in table
2. Table columns: Product Name, Type, Price, Active Status, Created Date, Actions (Edit, Delete)
3. "Create Product" button opens modal with form fields:
   - Name (required, text)
   - Description (optional, textarea)
   - Type (dropdown: LLC, CORP, DUBAI, BANKING, COMPLIANCE, OTHER)
   - Price (required, number with currency symbol)
   - Stripe Product ID (required, text - created in Stripe Dashboard)
   - Stripe Price ID (required, text)
   - Active (checkbox, default: true)
4. Saving product creates `products` record and redirects to workflow configuration
5. Workflow configuration page shows step builder interface:
   - List of steps with drag-and-drop reordering
   - Add Step button opens modal selecting from predefined steps (from `steps` table)
   - Each step shows position, name, description, required documents
6. Required documents configuration for each step:
   - Multi-select dropdown choosing from `document_types` table
   - Create new document type inline (name, description, accepted file types)
7. Saving workflow configuration creates/updates `product_steps` records with position ordering
8. Delete product requires confirmation, checks if product has active dossiers (prevent deletion if so)
9. Edit product allows changing all fields except Stripe IDs (warning that price change doesn't affect existing orders)
10. Inactive products hidden from payment link generation but existing dossiers continue processing
11. Step reordering only affects new dossiers, existing dossiers keep original step sequence
12. Preview mode shows sample client view of workflow steps before saving

---

## Story 4.6: Admin Payment Link Analytics

As an **admin**,
I want **to track payment link performance with conversion metrics and usage analytics**,
so that **I understand which prospects are converting and optimize outreach strategies**.

### Acceptance Criteria

1. Payment links page at `/admin/payment-links` displays enhanced table with analytics
2. Table columns: Token (truncated, copyable), Prospect Email, Product, Created Date, Expires Date, Status (ACTIVE, USED, EXPIRED), Used Date, Converted (Yes/No)
3. Status badges color-coded: ACTIVE (green), USED (blue), EXPIRED (gray)
4. Converted column shows checkmark if payment completed, X if user registered but didn't pay
5. Filters: Status (multi-select), Product (multi-select), Date Range (created date)
6. Search bar filters by prospect email
7. Sort by: Created Date, Expiration Date, Used Date
8. Analytics summary cards above table:
   - Total Links Created (with date range filter)
   - Active Links (not yet used, not expired)
   - Conversion Rate (USED links with successful payment / Total USED links)
   - Average Time to Conversion (time from link creation to payment completion)
9. Clicking link row expands details: Full token URL (copyable), User who used it (if used), Order status, Payment amount, Timeline of events
10. "Generate Link" button prominently placed, opens creation form (from Epic 1)
11. Bulk actions: Expire selected links (mark as EXPIRED, disable further use)
12. Export functionality: CSV export of all links with full details for external analysis
13. Conversion funnel visualization (optional): Link Created → Link Clicked → Registration → Payment
14. Email reminders for admins: Daily digest of unused links expiring soon

---

## Story 4.7: Admin Analytics Dashboard

As an **admin**,
I want **comprehensive analytics showing revenue, conversion rates, dossier completion, and agent performance**,
so that **I can make data-driven decisions to optimize operations and grow the business**.

### Acceptance Criteria

1. Analytics dashboard at `/admin/analytics` displays multiple metric categories
2. **Revenue Metrics** section:
   - Total Revenue (sum of all PAID orders)
   - Revenue This Month (current month)
   - Revenue Trend chart (line chart showing daily revenue over last 90 days)
   - Revenue by Product (pie chart or bar chart)
   - Average Order Value
3. **Conversion Metrics** section:
   - Payment Link Conversion Rate (payment links → paid orders)
   - Registration → Payment Conversion (registered users → ACTIVE users)
   - SUSPENDED User Recovery Rate (SUSPENDED users who eventually paid)
   - Funnel chart: Links Created → Links Used → Registrations → Payments
4. **Dossier Performance** section:
   - Total Dossiers (all time)
   - Active Dossiers (IN_PROGRESS, not completed/cancelled)
   - Completed Dossiers This Month
   - Average Time to Completion (days from dossier created to completed)
   - Completion Rate by Product (% of dossiers reaching COMPLETED status)
   - Bottleneck analysis: Which steps have longest average duration
5. **Agent Performance** section:
   - Documents Reviewed (total and per agent)
   - Average Review Time (per agent and overall)
   - Assigned Dossiers per Agent (workload distribution chart)
   - Agent Leaderboard (top reviewers by volume and speed)
6. **Document Metrics** section:
   - Approval Rate (% of documents approved on first review)
   - Rejection Reasons (grouped bar chart showing most common rejection reasons)
   - Average Versions per Document (indicates quality of initial submissions)
7. Date range selector (Last 7 days, Last 30 days, Last 90 days, All Time, Custom Range)
8. Export functionality: PDF report export for stakeholder sharing
9. Auto-refresh: Dashboard refreshes every 5 minutes to show latest data
10. Charts built with charting library (Recharts, Chart.js, or similar) with responsive design
11. Drill-down capability: Clicking chart segments filters data (e.g., click product in pie chart filters all metrics to that product)
12. Empty states with sample data for new installations
