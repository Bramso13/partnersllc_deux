# Epic 3: Workflow Automation & Notifications

**Epic Goal:** Transform the platform from manual coordination to self-service automation by implementing comprehensive event-driven architecture that captures all system actions, delivering multi-channel notifications (Email, WhatsApp, SMS, In-App) to keep clients and agents informed, enabling automated workflow step completion when documents are approved, and implementing suspended user payment recovery with automatic reminder sequences.

---

## Story 3.1: Event-Driven Architecture Foundation

As the **system**,
I want **all significant actions automatically captured as immutable events with complete context**,
so that **the platform can trigger notifications, audit actions, and enable future analytics without manual intervention**.

### Acceptance Criteria

1. Database trigger `create_dossier_status_change_event` fires on any `dossiers.status` change
2. Database trigger `create_document_upload_event` fires when new `document_versions` record created
3. Database trigger `create_document_review_event` fires when `document_reviews` record created
4. Events table populated with standardized structure: `event_type`, `actor_type`, `actor_id`, `resource_type`, `resource_id`, `payload` (JSONB), `created_at`
5. Event types enum includes: `DOSSIER_CREATED`, `DOSSIER_STATUS_CHANGED`, `STEP_STARTED`, `STEP_COMPLETED`, `DOCUMENT_UPLOADED`, `DOCUMENT_REVIEWED`, `PAYMENT_RECEIVED`, `PAYMENT_FAILED`, `MESSAGE_SENT`
6. Actor types enum includes: `USER`, `AGENT`, `SYSTEM`
7. Payload includes all relevant context (e.g., for DOCUMENT_REVIEWED: document_type, reviewer_name, review_status, rejection_reason if applicable)
8. Events are immutable (no UPDATE or DELETE allowed, only INSERT)
9. Event query utilities created: `getEventsByDossier(dossier_id)`, `getEventsByUser(user_id)`, `getEventsByType(event_type)`
10. Event timeline component renders events chronologically with human-readable descriptions
11. Event retention policy documented (recommendation: keep forever for audit, or archive after 2 years)
12. TypeScript types created for all event payloads with strict typing

---

## Story 3.2: Email Notification Delivery System

As a **user**,
I want **to receive email notifications for important updates (document reviewed, step completed, payment received)**,
so that **I stay informed about my dossier progress even when not logged into the platform**.

### Acceptance Criteria

1. Email provider configured (SendGrid or Resend) with API key in environment variables
2. Email service module created (`lib/notifications/email.ts`) with `sendEmail(to, subject, html, text)` function
3. Email templates created for each notification type using template engine (Handlebars or React Email):
   - Welcome email (after payment)
   - Document upload confirmation
   - Document approved notification
   - Document rejected notification (with reason)
   - Step completed notification
   - Payment reminder (for SUSPENDED users)
4. Edge Function or background job processes new `notifications` records filtering `channel: EMAIL`
5. For each email notification, `notification_deliveries` record created with `status: PENDING`
6. Email sent via provider API with error handling (retry up to 3 times with exponential backoff)
7. Successful send updates delivery record: `status: SENT`, `sent_at: now()`, `provider_message_id`
8. Failed send updates delivery record: `status: FAILED`, `error_message`, increments `retry_count`
9. Provider webhook (if supported) updates delivery status for opens/clicks (optional enhancement)
10. Emails include unsubscribe link (future: notification preferences page)
11. Test mode uses email capture service (MailHog, Ethereal) for development
12. E2E test verifies email sent when document is approved

---

## Story 3.3: WhatsApp Notification Delivery System

As a **user**,
I want **to receive WhatsApp messages for critical updates**,
so that **I get instant notifications on my preferred communication channel**.

### Acceptance Criteria

1. Twilio WhatsApp Business API configured with account SID, auth token, and WhatsApp phone number
2. WhatsApp service module created (`lib/notifications/whatsapp.ts`) with `sendWhatsApp(to, message, mediaUrl?)` function
3. WhatsApp message templates created for each notification type following Twilio template requirements
4. User phone numbers validated to E.164 format before sending (international format with country code)
5. For each WhatsApp notification, `notification_deliveries` record created with `status: PENDING`
6. Message sent via Twilio API with error handling
7. Successful send updates delivery: `status: SENT`, `provider_message_id` (Twilio SID)
8. Failed send (e.g., invalid number, user not on WhatsApp) updates delivery: `status: FAILED`, `error_message`
9. Twilio webhook configured to receive delivery status updates (delivered, read, failed)
10. Webhook updates delivery status based on Twilio events
11. WhatsApp notification priority: Try WhatsApp first, if fails, fallback to SMS (handled in notification orchestrator)
12. Message includes call-to-action link when applicable (e.g., "View your dossier: {link}")
13. Test mode uses Twilio sandbox for development testing
14. Rate limiting implemented (Twilio limits): Max 60 messages/minute per number

---

## Story 3.4: SMS Notification Delivery (Fallback Channel)

As a **user**,
I want **to receive SMS notifications if WhatsApp delivery fails**,
so that **I'm guaranteed to receive critical updates regardless of my app usage**.

### Acceptance Criteria

1. Twilio SMS configured (can use same account as WhatsApp)
2. SMS service module created (`lib/notifications/sms.ts`) with `sendSMS(to, message)` function
3. SMS templates created (shorter versions of email templates due to 160-character limitation)
4. For each SMS notification, `notification_deliveries` record created with `status: PENDING`
5. Message sent via Twilio SMS API
6. Successful send updates delivery: `status: SENT`, `provider_message_id`
7. Failed send updates delivery: `status: FAILED`, `error_message`
8. SMS webhook receives delivery receipts from Twilio
9. Link shortening implemented for SMS (use URL shortener or custom short domain) to save character count
10. SMS notifications sent only when: WhatsApp fails OR user has no WhatsApp number OR user preference is SMS
11. Character limit validation: Messages truncated to 160 chars with "..." if longer
12. Cost tracking: Log SMS costs per message for budget monitoring (Twilio provides pricing via API)
13. Opt-out handling: "Reply STOP to unsubscribe" included in messages (Twilio handles automatically)

---

## Story 3.5: In-App Notification System

As a **user**,
I want **to see notifications in the application dashboard**,
so that **I have a persistent record of all updates and can review them at any time**.

### Acceptance Criteria

1. Notifications table UI component created for dashboard showing unread count badge
2. Notification bell icon in header with red badge showing unread count
3. Clicking bell opens dropdown showing last 10 notifications
4. Each notification displays: Icon (based on type), Title, Message preview, Timestamp (relative: "2 hours ago")
5. Unread notifications bold, read notifications normal weight
6. Clicking notification marks it as read (`read_at: now()`) and navigates to relevant resource (e.g., dossier detail)
7. "Mark all as read" action in dropdown
8. "View all notifications" link at bottom navigates to `/dashboard/notifications` full page
9. Full notifications page shows all notifications with pagination (50 per page)
10. Filters available: All, Unread, Document Updates, Payment Updates, Messages
11. Real-time updates using Supabase Realtime subscription to `notifications` table filtered by user_id
12. New notification appears immediately without page refresh with subtle animation
13. Browser notification permission requested (for future push notifications - not implemented in this story)
14. Empty state when no notifications: "No notifications yet"
15. Notification retention: Keep all notifications indefinitely (user can manually delete if desired - future feature)

---

## Story 3.6: Automated Workflow Step Completion

As the **system**,
I want **to automatically complete workflow steps when all required documents are approved**,
so that **dossiers progress without requiring manual agent intervention for straightforward cases**.

### Acceptance Criteria

1. Database trigger or Edge Function monitors `document_reviews` table for new APPROVED reviews
2. When document approved, check if step completion conditions met: `are_step_documents_complete(step_instance_id)`
3. If TRUE (all required docs approved), automatically mark step as completed: `step_instances.completed_at: now()`
4. Call `get_next_step_for_dossier(dossier_id)` to get next step
5. If next step exists, start it: `step_instances.started_at: now()`
6. Update `dossiers.current_step_instance_id` to next step
7. Create event: `STEP_COMPLETED` with actor: SYSTEM
8. Create event: `STEP_STARTED` for next step
9. Create notification: "Step X completed! You can now proceed to Step Y."
10. If final step completed, update `dossiers.status: COMPLETED`, `completed_at: now()`
11. Create notification: "Congratulations! Your [Product Name] dossier is complete."
12. Automation can be disabled per product via `products.auto_complete_steps` flag (defaults to TRUE)
13. Manual override still available: Agents can manually complete steps from admin interface
14. Audit log shows whether step was auto-completed or manually completed (actor_type: SYSTEM vs AGENT)
15. E2E test: Upload all docs → Agent approves all → Verify step auto-completes within 5 seconds

---

## Story 3.7: Suspended User Payment Recovery Automation

As the **system**,
I want **to automatically send payment reminders to SUSPENDED users and enable easy payment completion**,
so that **revenue recovery is maximized without manual follow-up**.

### Acceptance Criteria

1. Daily cron job (Supabase Edge Function scheduled via cron) runs at 9 AM UTC checking for SUSPENDED users
2. Query finds profiles with `status: SUSPENDED` and unpaid orders (`orders.status: PENDING`)
3. Check `payment_reminders` table to see if reminder already sent in last 3 days
4. If no recent reminder, create new Stripe Checkout Session for the unpaid order
5. Create `payment_reminders` record: `user_id`, `order_id`, `stripe_session_id`, `sent_at: now()`, `reminder_number` (1, 2, 3...)
6. Create notification with all channels (Email, WhatsApp, SMS) with message: "Complete your payment to access your [Product Name] dossier. Pay now: {stripe_checkout_url}"
7. Email template includes prominent "Complete Payment" button linking to Stripe Checkout
8. WhatsApp/SMS messages include short link to Stripe Checkout
9. In-app notification created for SUSPENDED users (shown on next login)
10. Reminder cadence: Day 1, Day 4, Day 7, Day 14, Day 30 (then stop to avoid spam)
11. After 5 reminders with no payment, mark order as `status: CANCELLED`, send final notification
12. When SUSPENDED user completes payment via reminder link, webhook processes normally (Epic 1 story 1.9)
13. Payment success notification sent: "Payment successful! Welcome back. Your dossier is ready."
14. Reminder history visible in admin dashboard for each user
15. Analytics track: Reminder sent count, Reminder → Payment conversion rate
