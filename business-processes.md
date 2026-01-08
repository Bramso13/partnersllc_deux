# Business Processes - Partners VRAI Platform

## Table of Contents
1. [Payment Link Generation & User Onboarding](#1-payment-link-generation--user-onboarding)
2. [Dossier Creation & Workflow Initialization](#2-dossier-creation--workflow-initialization)
3. [Step Execution & Document Management](#3-step-execution--document-management)
4. [Document Review Process](#4-document-review-process)
5. [Status Transitions & State Management](#5-status-transitions--state-management)
6. [Event & Notification System](#6-event--notification-system)
7. [Payment Reminders for Suspended Users](#7-payment-reminders-for-suspended-users)
8. [Stripe Webhook Handling](#8-stripe-webhook-handling)

---

## 1. Payment Link Generation & User Onboarding

### Process Flow

```
Admin → Generate Payment Link → Email Sent → User Pre-Registration →
Stripe Checkout → Webhook → User Activated → Dossier Created
```

### Step-by-Step Implementation

#### 1.1 Admin Generates Payment Link

```sql
-- Admin creates a payment link for a prospect
INSERT INTO payment_links (
  token,
  product_id,
  prospect_email,
  prospect_name,
  created_by,
  expires_at
)
VALUES (
  generate_payment_link_token(),  -- Custom function
  (SELECT id FROM products WHERE code = 'LLC_FORMATION'),
  'john.doe@example.com',
  'John Doe',
  '<admin_uuid>',
  now() + interval '30 days'  -- Link expires in 30 days
)
RETURNING token, prospect_email;

-- Result: token = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'
```

#### 1.2 Send Email with Payment Link

```typescript
// Email template
const emailBody = `
Hi ${prospectName},

You've been invited to register for our LLC Formation service.

Click here to get started:
https://partnervrai.com/register/${token}

This link expires in 30 days.

Best regards,
Partners VRAI Team
`;
```

#### 1.3 User Pre-Registration (Before Payment)

```typescript
// Frontend: User fills registration form at /register/{token}
// Backend creates Supabase auth user + profile

// Step 1: Verify payment link
const paymentLink = await supabase
  .from('payment_links')
  .select('*, products(*)')
  .eq('token', token)
  .is('used_at', null)
  .single();

if (!paymentLink) {
  throw new Error('Invalid or already used payment link');
}

if (paymentLink.expires_at && new Date(paymentLink.expires_at) < new Date()) {
  throw new Error('Payment link has expired');
}

// Step 2: Create Supabase Auth user
const { data: authUser, error } = await supabase.auth.signUp({
  email: formData.email,
  password: formData.password,
});

// Step 3: Create profile with PENDING status
await supabase.from('profiles').insert({
  id: authUser.user.id,
  full_name: formData.fullName,
  phone: formData.phone,
  status: 'PENDING',  // Critical: Not active until payment
});

// Step 4: Create order
const order = await supabase.from('orders').insert({
  user_id: authUser.user.id,
  product_id: paymentLink.product_id,
  payment_link_id: paymentLink.id,
  amount: paymentLink.products.price_amount,
  currency: paymentLink.products.currency,
  status: 'PENDING',
}).select().single();

// Step 5: Mark payment link as used
await supabase.from('payment_links').update({
  used_at: new Date().toISOString(),
  used_by: authUser.user.id,
}).eq('id', paymentLink.id);

// Step 6: Create Stripe Checkout Session
const session = await stripe.checkout.sessions.create({
  customer_email: formData.email,
  mode: 'payment',
  payment_method_types: ['card'],
  line_items: [{
    price: paymentLink.products.stripe_price_id,
    quantity: 1,
  }],
  metadata: {
    order_id: order.id,
    user_id: authUser.user.id,
    product_id: paymentLink.product_id,
  },
  success_url: `${process.env.APP_URL}/dashboard?payment=success`,
  cancel_url: `${process.env.APP_URL}/register/${token}?payment=cancelled`,
});

// Step 7: Update order with Stripe session ID
await supabase.from('orders').update({
  stripe_checkout_session_id: session.id,
}).eq('id', order.id);

// Step 8: Redirect user to Stripe
return { redirectUrl: session.url };
```

#### 1.4 Payment Success - Webhook Handler (See Section 8)

---

## 2. Dossier Creation & Workflow Initialization

### Process: Automatic Dossier Creation After Payment

```sql
-- This happens in the Stripe webhook handler after payment success

-- Step 1: Get order and product info
SELECT
  o.id as order_id,
  o.user_id,
  p.id as product_id,
  p.dossier_type,
  p.initial_status
FROM orders o
JOIN products p ON p.id = o.product_id
WHERE o.stripe_checkout_session_id = 'cs_xxxxx';

-- Step 2: Create dossier
INSERT INTO dossiers (
  user_id,
  product_id,
  type,
  status,
  metadata
)
VALUES (
  '<user_id>',
  '<product_id>',
  'LLC',  -- From products.dossier_type
  'QUALIFICATION',  -- From products.initial_status
  jsonb_build_object(
    'order_id', '<order_id>',
    'created_via', 'payment_link'
  )
)
RETURNING id;

-- Step 3: Create initial step instances based on product workflow
WITH product_workflow AS (
  SELECT ps.step_id, ps.position
  FROM product_steps ps
  WHERE ps.product_id = '<product_id>'
  ORDER BY ps.position
)
INSERT INTO step_instances (dossier_id, step_id, started_at)
SELECT
  '<dossier_id>',
  pw.step_id,
  CASE WHEN pw.position = 0 THEN now() ELSE NULL END  -- Only start first step
FROM product_workflow pw;

-- Step 4: Link first step as current step
UPDATE dossiers
SET current_step_instance_id = (
  SELECT si.id
  FROM step_instances si
  JOIN product_steps ps ON ps.step_id = si.step_id
  WHERE si.dossier_id = '<dossier_id>'
  ORDER BY ps.position
  LIMIT 1
)
WHERE id = '<dossier_id>';

-- Step 5: Link dossier to order
UPDATE orders
SET dossier_id = '<dossier_id>'
WHERE id = '<order_id>';
```

### Event Triggered

The trigger `dossier_status_changed` automatically creates:
```sql
INSERT INTO events (entity_type, entity_id, event_type, payload)
VALUES (
  'dossier',
  '<dossier_id>',
  'DOSSIER_CREATED',
  jsonb_build_object(
    'user_id', '<user_id>',
    'product_id', '<product_id>',
    'type', 'LLC',
    'status', 'QUALIFICATION'
  )
);
```

---

## 3. Step Execution & Document Management

### Process: User Uploads Documents for Current Step

```sql
-- Step 1: Get current step and required documents
SELECT
  d.id as dossier_id,
  d.current_step_instance_id,
  si.step_id,
  s.code as step_code,
  s.label as step_label,
  array_agg(
    jsonb_build_object(
      'document_type_id', dt.id,
      'code', dt.code,
      'label', dt.label,
      'required', true
    )
  ) as required_documents
FROM dossiers d
JOIN step_instances si ON si.id = d.current_step_instance_id
JOIN steps s ON s.id = si.step_id
LEFT JOIN document_types dt ON dt.required_step_id = s.id
WHERE d.id = '<dossier_id>'
GROUP BY d.id, si.id, s.id;

-- Step 2: User uploads document
INSERT INTO documents (
  dossier_id,
  document_type_id,
  step_instance_id,
  status
)
VALUES (
  '<dossier_id>',
  '<document_type_id>',  -- e.g., PASSPORT
  '<current_step_instance_id>',
  'PENDING'
)
RETURNING id;

-- Step 3: Create first version
INSERT INTO document_versions (
  document_id,
  file_url,
  file_name,
  file_size_bytes,
  mime_type,
  uploaded_by_type,
  uploaded_by_id,
  version_number
)
VALUES (
  '<document_id>',
  'https://storage.supabase.co/documents/passport_123.pdf',
  'passport_john_doe.pdf',
  2457600,  -- 2.4 MB
  'application/pdf',
  'USER',
  '<user_id>',
  1
)
RETURNING id;

-- Step 4: Link current version to document
UPDATE documents
SET current_version_id = '<version_id>'
WHERE id = '<document_id>';

-- Event automatically created by trigger: 'DOCUMENT_UPLOADED'
```

### Frontend: Check if Step Can be Completed

```typescript
// Query to check if all required docs are uploaded and approved
const { data: stepCompletion } = await supabase.rpc(
  'are_step_documents_complete',
  { p_step_instance_id: currentStepInstanceId }
);

if (stepCompletion) {
  // Show "Mark Step as Complete" button
}
```

---

## 4. Document Review Process

### Process: Agent Reviews Uploaded Document

```sql
-- Step 1: Agent fetches pending documents for review
SELECT
  d.id as document_id,
  d.dossier_id,
  dos.user_id,
  p.full_name as user_name,
  dt.label as document_type,
  dv.file_url,
  dv.file_name,
  dv.uploaded_at,
  dv.version_number
FROM documents d
JOIN document_versions dv ON dv.id = d.current_version_id
JOIN document_types dt ON dt.id = d.document_type_id
JOIN dossiers dos ON dos.id = d.dossier_id
JOIN profiles p ON p.id = dos.user_id
WHERE d.status = 'PENDING'
ORDER BY dv.uploaded_at ASC;

-- Step 2: Agent reviews and approves
INSERT INTO document_reviews (
  document_version_id,
  reviewer_id,
  status,
  notes
)
VALUES (
  '<version_id>',
  '<agent_id>',
  'APPROVED',
  'Document is valid and clear'
);

-- Step 3: Update document status
UPDATE documents
SET status = 'APPROVED'
WHERE current_version_id = '<version_id>';

-- OR: Agent rejects
INSERT INTO document_reviews (
  document_version_id,
  reviewer_id,
  status,
  reason,
  notes
)
VALUES (
  '<version_id>',
  '<agent_id>',
  'REJECTED',
  'Document is blurry and unreadable',
  'Please upload a clearer scan of your passport'
);

UPDATE documents
SET status = 'REJECTED'
WHERE current_version_id = '<version_id>';

-- Step 4: Create event
INSERT INTO events (entity_type, entity_id, event_type, payload)
VALUES (
  'document',
  '<document_id>',
  'DOCUMENT_REVIEWED',
  jsonb_build_object(
    'version_id', '<version_id>',
    'reviewer_id', '<agent_id>',
    'status', 'APPROVED',  -- or 'REJECTED'
    'dossier_id', '<dossier_id>'
  )
);

-- Step 5: Notify user
INSERT INTO notifications (
  user_id,
  dossier_id,
  title,
  message,
  template_code,
  payload
)
VALUES (
  '<user_id>',
  '<dossier_id>',
  'Document Reviewed',
  'Your passport document has been approved',
  'DOCUMENT_REVIEWED',
  jsonb_build_object(
    'document_type', 'Passport',
    'status', 'APPROVED'
  )
);
```

---

## 5. Status Transitions & State Management

### Process: Moving Dossier to Next Step

```sql
-- Step 1: Verify current step is complete
SELECT are_step_documents_complete('<current_step_instance_id>');
-- Returns: true

-- Step 2: Mark current step as completed
UPDATE step_instances
SET completed_at = now()
WHERE id = '<current_step_instance_id>';

-- Step 3: Get next step
SELECT get_next_step_for_dossier('<dossier_id>');
-- Returns: <next_step_id>

-- Step 4: Start next step
UPDATE step_instances
SET started_at = now()
WHERE dossier_id = '<dossier_id>'
AND step_id = '<next_step_id>';

-- Step 5: Update dossier current step
UPDATE dossiers
SET
  current_step_instance_id = (
    SELECT id FROM step_instances
    WHERE dossier_id = '<dossier_id>'
    AND step_id = '<next_step_id>'
  ),
  status = 'IN_PROGRESS'  -- Or appropriate status
WHERE id = '<dossier_id>';

-- Events automatically created by trigger
```

### Dossier Completion

```sql
-- When all steps are done
UPDATE dossiers
SET
  status = 'COMPLETED',
  completed_at = now(),
  current_step_instance_id = NULL
WHERE id = '<dossier_id>';

-- Create completion event
INSERT INTO events (entity_type, entity_id, event_type, payload)
VALUES (
  'dossier',
  '<dossier_id>',
  'DOSSIER_STATUS_CHANGED',
  jsonb_build_object(
    'old_status', 'IN_PROGRESS',
    'new_status', 'COMPLETED',
    'completed_at', now()
  )
);

-- Notify user
INSERT INTO notifications (
  user_id,
  dossier_id,
  title,
  message,
  template_code
)
VALUES (
  '<user_id>',
  '<dossier_id>',
  'Congratulations!',
  'Your LLC formation process is complete',
  'DOSSIER_COMPLETED'
);
```

---

## 6. Event & Notification System

### Process: Event → Notification → Multi-Channel Delivery

```sql
-- Step 1: Event is created (automatically via triggers or manually)
INSERT INTO events (entity_type, entity_id, event_type, actor_type, actor_id, payload)
VALUES (
  'dossier',
  '<dossier_id>',
  'STEP_COMPLETED',
  'AGENT',
  '<agent_id>',
  jsonb_build_object(
    'step_code', 'DOCUMENT_COLLECTION',
    'next_step', 'BANK_PREPARATION'
  )
);

-- Step 2: Create notification
INSERT INTO notifications (
  user_id,
  dossier_id,
  event_id,
  title,
  message,
  template_code,
  payload,
  action_url
)
VALUES (
  '<user_id>',
  '<dossier_id>',
  '<event_id>',
  'Next Step Ready',
  'Document collection is complete. You can now proceed to bank preparation.',
  'STEP_COMPLETED',
  jsonb_build_object(
    'step_name', 'Document Collection',
    'next_step_name', 'Bank Preparation'
  ),
  '/dashboard/dossiers/<dossier_id>'
)
RETURNING id;

-- Step 3: Create multi-channel deliveries
INSERT INTO notification_deliveries (notification_id, channel, recipient, status)
VALUES
  ('<notification_id>', 'EMAIL', 'user@example.com', 'PENDING'),
  ('<notification_id>', 'WHATSAPP', '+1234567890', 'PENDING'),
  ('<notification_id>', 'IN_APP', '<user_id>', 'PENDING');

-- Step 4: Background job processes deliveries
-- For each delivery:
UPDATE notification_deliveries
SET
  status = 'SENT',
  sent_at = now(),
  provider = 'sendgrid',
  provider_message_id = 'msg_xxxxx',
  provider_response = jsonb_build_object(
    'message_id', 'msg_xxxxx',
    'status', 'delivered'
  )
WHERE id = '<delivery_id>';

-- If delivery fails:
UPDATE notification_deliveries
SET
  status = 'FAILED',
  failed_at = now(),
  provider_response = jsonb_build_object(
    'error', 'Invalid phone number'
  )
WHERE id = '<delivery_id>';
```

---

## 7. Payment Reminders for Suspended Users

### Process: Automated Reminders for Unpaid Users

```sql
-- Step 1: Identify suspended users with pending orders
SELECT
  p.id as user_id,
  p.full_name,
  p.email,
  p.phone,
  o.id as order_id,
  o.amount,
  o.created_at,
  pl.token as payment_link_token,
  EXTRACT(day FROM now() - o.created_at) as days_since_registration
FROM profiles p
JOIN orders o ON o.user_id = p.id
LEFT JOIN payment_links pl ON pl.id = o.payment_link_id
WHERE p.status = 'SUSPENDED'
AND o.status = 'PENDING'
AND NOT EXISTS (
  -- Don't send if we sent a reminder in the last 3 days
  SELECT 1 FROM payment_reminders pr
  WHERE pr.user_id = p.id
  AND pr.order_id = o.id
  AND pr.sent_at > now() - interval '3 days'
)
ORDER BY o.created_at ASC;

-- Step 2: Send reminder via email
INSERT INTO payment_reminders (user_id, order_id, sent_via)
VALUES ('<user_id>', '<order_id>', 'EMAIL')
RETURNING id;

-- Step 3: Create notification
INSERT INTO notifications (
  user_id,
  title,
  message,
  template_code,
  payload,
  action_url
)
VALUES (
  '<user_id>',
  'Complete Your Payment',
  'Your LLC formation service is waiting. Complete payment to get started.',
  'PAYMENT_REMINDER',
  jsonb_build_object(
    'amount', 999.00,
    'currency', 'USD',
    'product_name', 'LLC Formation'
  ),
  '/payment/complete/<order_id>'
);

-- Step 4: On login, frontend shows popup
-- User clicks "Complete Payment" → Recreate Stripe Checkout Session
```

### Frontend: Show Payment Banner for Suspended Users

```typescript
// In user dashboard
const { data: profile } = await supabase
  .from('profiles')
  .select('status')
  .eq('id', userId)
  .single();

if (profile.status === 'SUSPENDED') {
  const { data: pendingOrder } = await supabase
    .from('orders')
    .select('*, products(*)')
    .eq('user_id', userId)
    .eq('status', 'PENDING')
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (pendingOrder) {
    // Show persistent banner with "Complete Payment" button
    showPaymentBanner(pendingOrder);
  }
}
```

---

## 8. Stripe Webhook Handling

### Process: `checkout.session.completed` Webhook

```typescript
// Webhook endpoint: POST /api/webhooks/stripe
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function POST(req: Request) {
  const sig = req.headers.get('stripe-signature');
  const body = await req.text();

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;

    // Extract metadata
    const { order_id, user_id, product_id } = session.metadata;

    // Step 1: Update order
    await supabase
      .from('orders')
      .update({
        status: 'PAID',
        paid_at: new Date().toISOString(),
        stripe_payment_intent_id: session.payment_intent,
        stripe_customer_id: session.customer,
      })
      .eq('id', order_id);

    // Step 2: Activate user
    await supabase
      .from('profiles')
      .update({
        status: 'ACTIVE',
        stripe_customer_id: session.customer,
      })
      .eq('id', user_id);

    // Step 3: Get product info
    const { data: product } = await supabase
      .from('products')
      .select('*')
      .eq('id', product_id)
      .single();

    // Step 4: Create dossier
    const { data: dossier } = await supabase
      .from('dossiers')
      .insert({
        user_id,
        product_id,
        type: product.dossier_type,
        status: product.initial_status,
        metadata: {
          order_id,
          created_via: 'payment_link',
        },
      })
      .select()
      .single();

    // Step 5: Initialize workflow steps
    const { data: productSteps } = await supabase
      .from('product_steps')
      .select('step_id, position')
      .eq('product_id', product_id)
      .order('position');

    for (const ps of productSteps) {
      await supabase.from('step_instances').insert({
        dossier_id: dossier.id,
        step_id: ps.step_id,
        started_at: ps.position === 0 ? new Date().toISOString() : null,
      });
    }

    // Step 6: Set current step to first step
    const { data: firstStep } = await supabase
      .from('step_instances')
      .select('id')
      .eq('dossier_id', dossier.id)
      .order('started_at', { ascending: true })
      .limit(1)
      .single();

    await supabase
      .from('dossiers')
      .update({ current_step_instance_id: firstStep.id })
      .eq('id', dossier.id);

    // Step 7: Link dossier to order
    await supabase
      .from('orders')
      .update({ dossier_id: dossier.id })
      .eq('id', order_id);

    // Step 8: Create payment success event
    await supabase.from('events').insert({
      entity_type: 'order',
      entity_id: order_id,
      event_type: 'PAYMENT_RECEIVED',
      payload: {
        amount: session.amount_total / 100,
        currency: session.currency,
        stripe_payment_intent_id: session.payment_intent,
        dossier_id: dossier.id,
      },
    });

    // Step 9: Send welcome notification
    await supabase.from('notifications').insert({
      user_id,
      dossier_id: dossier.id,
      title: 'Welcome to Partners VRAI!',
      message: `Your ${product.name} dossier has been created. Let's get started!`,
      template_code: 'WELCOME',
      action_url: `/dashboard/dossiers/${dossier.id}`,
    });

    console.log(`✅ Payment processed for order ${order_id}`);
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
}
```

---

## Key Business Rules Summary

### User Status Lifecycle
- `PENDING`: Registered but not paid
- `ACTIVE`: Paid and can access platform
- `SUSPENDED`: Payment failed or account issues

### Order Status Lifecycle
- `PENDING`: Awaiting payment
- `PAID`: Payment successful
- `FAILED`: Payment attempt failed
- `REFUNDED`: Payment was refunded
- `CANCELLED`: Order cancelled

### Dossier Status Flow
```
QUALIFICATION → FORM_SUBMITTED → NM_PENDING → LLC_ACCEPTED →
EIN_PENDING → BANK_PREPARATION → BANK_OPENED → COMPLETED
```

### Document Status Flow
```
PENDING → (Agent Review) → APPROVED or REJECTED
If REJECTED → User uploads new version → PENDING (old version becomes OUTDATED)
```

### Critical Constraints
1. **User cannot access platform if status != ACTIVE**
2. **One payment = One dossier**
3. **Documents must be approved before step can complete**
4. **Events are immutable** (never delete, only insert)
5. **Payment links are single-use** (used_at timestamp prevents reuse)
6. **Suspended users get reminders every 3 days** (configurable)

---

## Database Functions Usage Examples

### Get Next Step
```sql
SELECT get_next_step_for_dossier('dossier-uuid-here');
```

### Check Step Completion
```sql
SELECT are_step_documents_complete('step-instance-uuid-here');
```

### Generate Payment Link Token
```sql
SELECT generate_payment_link_token();
```

---

## Performance Considerations

### High-Traffic Queries
1. **User Dashboard**: Use indexed queries on `dossiers.user_id`
2. **Document List**: Use indexed queries on `documents.dossier_id`
3. **Event Log**: Paginate using `events.created_at` index
4. **Notifications**: Filter unread using `notifications.read_at IS NULL`

### Background Jobs
1. **Payment Reminders**: Run daily at 9 AM (cron job)
2. **Notification Deliveries**: Process queue every 30 seconds
3. **Event Cleanup**: Archive events older than 2 years (optional)

### Caching Strategy
- Cache product catalog (rarely changes)
- Cache step definitions (rarely changes)
- Cache document types (rarely changes)
- DO NOT cache: dossiers, orders, documents (frequently updated)
