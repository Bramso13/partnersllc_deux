# Epic 2: Dossier Management & Document Workflow

**Epic Goal:** Build the core case management system that enables automatic dossier creation after payment, allows clients to upload documents with full versioning support, provides agents with document review capabilities including approve/reject actions, and implements basic workflow step progression. This epic delivers the first complete client journey from payment through document submission to agent review.

---

## Story 2.1: Client Dashboard with Dossier List

As a **client**,
I want **to see all my dossiers in a dashboard with their current status and progress**,
so that **I have a clear overview of my active services and know what actions are required**.

### Acceptance Criteria

1. Dashboard page at `/dashboard` displays hero section with user name and account status badge
2. Dossiers fetched from database filtering by `user_id` with RLS enforcement
3. Each dossier displayed as a card showing: Product name, Status badge, Progress indicator (X/Y steps), Current step title
4. Progress bar visually represents completion percentage (completed steps / total steps)
5. Status badge color-coded: QUALIFICATION (blue), IN_PROGRESS (yellow), PENDING_REVIEW (orange), COMPLETED (green), CANCELLED (red)
6. Empty state shown when user has no dossiers: "No active dossiers. Contact support if you recently made a payment."
7. Each dossier card clickable, navigating to `/dashboard/dossiers/[id]`
8. Recent notifications section displays last 5 notifications with timestamp and message preview
9. Dashboard responsive: Cards stack vertically on mobile, 2-column grid on tablet, 3-column on desktop
10. Loading skeleton shown while fetching dossiers
11. Error state handles network failures with retry button

---

## Story 2.2: Dossier Detail Page with Current Step Display

As a **client**,
I want **to view my dossier details including the current step and required actions**,
so that **I understand exactly what I need to do next to progress my case**.

### Acceptance Criteria

1. Dossier detail page at `/dashboard/dossiers/[id]` shows comprehensive dossier information
2. Page header displays: Product name, Status badge, Overall progress bar (3/5 steps completed)
3. Current step section prominently displayed with: Step title, Step description, Step position (e.g., "Step 3 of 5")
4. Required documents for current step listed with document type names and descriptions
5. Document upload area visible only for current step (future steps hidden)
6. Completed steps shown in accordion above current step with checkmark icons
7. Future steps shown in accordion below current step with lock icons (disabled state)
8. Timeline section displays chronological history of all events (dossier created, document uploaded, step completed)
9. RLS policy enforces user can only view their own dossiers (403 error if accessing another user's dossier)
10. Page responsive: Single column on mobile, sidebar layout on desktop (main content + timeline sidebar)
11. Loading state shown while fetching dossier data
12. 404 page shown if dossier ID doesn't exist

---

## Story 2.3: Document Upload with Versioning Support

As a **client**,
I want **to upload required documents for my dossier with drag-and-drop support**,
so that **I can easily submit the materials needed to progress my case**.

### Acceptance Criteria

1. Document upload area supports drag-and-drop for files (PDF, JPG, PNG)
2. Click-to-browse alternative for users who prefer file picker
3. File type validation: Only PDF, JPG, PNG accepted (show error for other types)
4. File size validation: Maximum 10MB per file (show error if exceeded)
5. Upload progress bar shown during file transfer to Supabase Storage
6. On successful upload, `documents` record created with: `dossier_id`, `document_type_id`, `step_instance_id`, `uploaded_by: USER`
7. `document_versions` record created with: `document_id`, `version_number: 1`, `file_path`, `file_size`, `mime_type`, `status: PENDING`
8. `documents.current_version_id` set to newly created version
9. File uploaded to Supabase Storage in organized bucket: `documents/{dossier_id}/{document_type_slug}/{version}.{ext}`
10. Upload trigger fires `create_document_upload_event()` creating event in `events` table
11. Document appears in document list immediately with "Under Review" status badge
12. Multiple documents can be uploaded for same type (if re-uploading after rejection)
13. Error handling: Storage errors show user-friendly message with retry option
14. Success toast notification: "Document uploaded successfully. You'll be notified when it's reviewed."
15. Upload disabled for documents already APPROVED (show "Approved" checkmark instead)

---

## Story 2.4: Agent Review Queue Interface

As an **agent**,
I want **a centralized queue showing all pending document reviews across all dossiers**,
so that **I can efficiently process reviews in priority order without missing any submissions**.

### Acceptance Criteria

1. Agent review queue page at `/admin/reviews` accessible to users with AGENT or ADMIN role
2. Table displays all documents with `status: PENDING` from latest version across all dossiers
3. Table columns: Document Type, Client Name, Dossier Product, Uploaded Date, File Size, Actions
4. Table sortable by Uploaded Date (default: oldest first to ensure SLA compliance)
5. Table filterable by: Document Type (dropdown), Date Range (date picker), Dossier Product (dropdown)
6. Search bar filters by client name or dossier ID
7. Pagination implemented: 25 reviews per page with page navigation
8. Each row shows "Review" button opening document review modal
9. Badge shows total count of pending reviews in page header
10. Auto-refresh every 60 seconds to show newly uploaded documents
11. Empty state when no pending reviews: "All caught up! No pending reviews."
12. Loading skeleton shown while fetching reviews
13. RLS policy allows agents to read all documents (not just their assigned dossiers)

---

## Story 2.5: Document Review and Approval Workflow

As an **agent**,
I want **to review document previews and approve or reject them with clear feedback**,
so that **clients receive timely validation of their submissions and know if corrections are needed**.

### Acceptance Criteria

1. Review modal opens when "Review" button clicked, displaying full-screen document preview
2. PDF documents rendered using PDF viewer library (react-pdf or similar) with zoom and navigation controls
3. Image documents (JPG, PNG) displayed with zoom and pan capabilities
4. Sidebar shows document metadata: Document Type, Client Name, Dossier ID, Upload Date, File Size, Version Number
5. If document has previous versions, version history shown with links to view older versions
6. "Approve" button (green) and "Reject" button (red) prominently displayed
7. Clicking "Approve" creates `document_reviews` record with: `document_version_id`, `reviewer_id` (current agent), `review_status: APPROVED`, `reviewed_at: now()`
8. Approval updates `document_versions.status: APPROVED`
9. Approval creates event: `DOCUMENT_REVIEWED` with payload including review details
10. Clicking "Reject" shows text area requiring rejection reason (minimum 10 characters)
11. Rejection creates `document_reviews` record with: `review_status: REJECTED`, `rejection_reason`
12. Rejection updates `document_versions.status: REJECTED`
13. Rejection creates event: `DOCUMENT_REVIEWED`
14. After approve or reject, modal closes and next pending document loads automatically (for efficiency)
15. Toast notification confirms action: "Document approved" or "Document rejected. Client will be notified."
16. Review actions logged in agent activity history for audit trail

---

## Story 2.6: Rejected Document Handling and Re-Upload

As a **client**,
I want **clear notification when my document is rejected with the reason, and the ability to upload a corrected version**,
so that **I can fix issues and resubmit without confusion**.

### Acceptance Criteria

1. When document rejected, notification created (via event trigger - will be implemented in Epic 3, for now just UI state)
2. Dossier detail page shows rejected document with red "Rejected" badge
3. Rejection reason displayed clearly below document: "This document was rejected: [agent's reason]"
4. "Upload New Version" button appears next to rejected document
5. Clicking "Upload New Version" opens file upload dialog for that specific document type
6. New upload creates new `document_versions` record with incremented version number (v2, v3, etc.)
7. Old version marked as `status: OUTDATED`
8. New version becomes `current_version_id` on parent `documents` record
9. New version starts with `status: PENDING` requiring new agent review
10. Document list shows version history: "Version 2 (Under Review)" with expandable "View previous versions" section
11. Previous versions display with status and review history
12. Agent reviewing new version can see all previous versions and rejection reasons in modal sidebar
13. Approved documents cannot be re-uploaded (upload button hidden for APPROVED documents)
14. Re-upload follows same validation rules (file type, size) as initial upload

---

## Story 2.7: Basic Workflow Step Completion

As an **agent**,
I want **to manually complete workflow steps once all required documents are approved**,
so that **dossiers progress through the workflow and clients move to the next stage**.

### Acceptance Criteria

1. Dossier detail page (agent view at `/admin/dossiers/[id]`) includes "Complete Step" button for current step
2. Button disabled (grayed out) until all required documents for step are APPROVED
3. Button enabled (green) when `are_step_documents_complete(step_instance_id)` returns TRUE
4. Clicking "Complete Step" triggers Server Action validating completion requirements
5. Server Action marks `step_instances.completed_at: now()` for current step
6. Server Action calls `get_next_step_for_dossier(dossier_id)` to retrieve next step instance ID
7. If next step exists, mark `step_instances.started_at: now()` for next step
8. Update `dossiers.current_step_instance_id` to next step instance ID
9. Create event: `STEP_COMPLETED` with payload including completed step and next step info
10. If no next step exists (final step completed), update `dossiers.status: COMPLETED`, set `completed_at: now()`
11. Create event: `DOSSIER_STATUS_CHANGED` when status changes to COMPLETED
12. Client dashboard immediately reflects updated progress (via page refresh or optimistic UI update)
13. Timeline shows new entry: "Step X completed by [Agent Name]"
14. Confirmation toast: "Step completed. Client will be notified of next steps."
15. E2E test covers: Upload docs → Agent approves → Complete step → Verify next step active
