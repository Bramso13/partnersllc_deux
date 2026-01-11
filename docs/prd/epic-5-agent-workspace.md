# Epic 5: Agent Workspace & Step Processing

**Epic Goal:** Create a dedicated agent workspace (`/agent`) separate from the admin portal, enabling agents to view their assigned steps, process them efficiently, review documents, and communicate with clients. This workspace is designed for task execution while the admin portal (`/admin`) handles management, supervision, and assignment.

---

## Context & Business Rules

### Role Separation

| Role | Workspace | Capabilities |
|------|-----------|--------------|
| **ADMIN** | `/admin` | Full platform management: clients, agents, products, analytics, assign steps to agents |
| **AGENT** | `/agent` | Process assigned steps, review documents, communicate with clients |
| **CLIENT** | `/dashboard` | View own dossiers, upload documents, track progress |

### Assignment Model

- **Admin assigns steps** (via `step_instances.assigned_to`) to agents
- Each agent sees **only their assigned steps**
- One agent can be assigned multiple steps from the same dossier
- Admin can reassign steps between agents
- Unassigned steps appear in admin dashboard (not visible to agents until assigned)

---

## Story 5.1: Agent Workspace Setup & Navigation

As an **agent**,
I want **a dedicated workspace at `/agent` with its own navigation**,
so that **I can access my assigned work without confusion with admin tools**.

### Acceptance Criteria

1. Agent workspace root at `/agent` displays agent's personal dashboard
2. Workspace accessible only to users with `profiles.role = 'AGENT'` or `'ADMIN'`
3. Clients (`profiles.role = 'CLIENT'`) redirected to `/dashboard` with 403 error
4. Agent navigation config (`agentNavConfig`) created with menu items:
   - Tableau de bord (href: `/agent`, icon: `fa-gauge-high`)
   - Mes étapes (href: `/agent/steps`, icon: `fa-list-check`)
   - Documents à reviewer (href: `/agent/reviews`, icon: `fa-file-circle-check`)
   - Messages (href: `/agent/messages`, icon: `fa-comments`) - if messaging implemented
5. Agent layout uses same dark theme as admin but with distinct accent or header to differentiate
6. User profile dropdown shows role badge ("Agent")
7. Navigation sidebar responsive: collapsible on mobile, persistent on desktop
8. Quick stats on dashboard: Assigned steps count, Pending reviews count, Unread messages count
9. Agent can switch to admin view if they have ADMIN role (via profile dropdown)

---

## Story 5.2: Agent Assigned Steps Queue

As an **agent**,
I want **to see all steps assigned to me in a queue**,
so that **I can prioritize and process my work efficiently**.

### Acceptance Criteria

1. Steps queue page at `/agent/steps` displays all step_instances where `assigned_to = current_agent_id`
2. Only incomplete steps shown by default (`completed_at IS NULL`)
3. Each step card displays:
   - Step name (from `steps.label`)
   - Dossier info: Product name, Client name/email, Dossier ID
   - Step status indicator (not started, in progress, blocked)
   - Pending documents count for this step
   - Time assigned (how long ago step was assigned)
   - Priority indicator (optional: based on dossier age or manual priority)
4. Cards arranged in list view (not grid) for easier scanning
5. Sortable by: Date assigned (default), Step type, Client name, Pending documents
6. Filterable by: Step type (dropdown), Has pending documents (toggle)
7. Search by client name, email, or dossier ID
8. Clicking step card navigates to `/agent/steps/[step_instance_id]`
9. Toggle to show completed steps (historical view)
10. Empty state: "Aucune étape assignée. Contactez votre administrateur."
11. Badge on navigation showing total incomplete assigned steps count
12. Auto-refresh every 60 seconds to show newly assigned steps

---

## Story 5.3: Agent Step Processing View

As an **agent**,
I want **a detailed view of an assigned step with all actions needed to process it**,
so that **I can review documents, fill information, and complete the step**.

### Acceptance Criteria

1. Step processing page at `/agent/steps/[step_instance_id]`
2. Page only accessible if step is assigned to current agent (403 if not assigned)
3. Header shows: Step name, Dossier info (product, client name, dossier ID)
4. Progress indicator showing step position in workflow (e.g., "Étape 2 sur 5")
5. **Documents Section**:
   - List of required documents for this step (from `document_types` where `required_step_id = step_id`)
   - For each document type: Show uploaded document or "Non soumis" placeholder
   - Document status badge: PENDING (yellow), APPROVED (green), REJECTED (red), Not submitted (gray)
   - Quick actions: "Approuver", "Rejeter" buttons for pending documents
   - Rejection requires reason input (minimum 10 characters)
   - View document button opens preview modal (PDF viewer, image viewer)
6. **Form Fields Section** (if step has custom fields):
   - Display custom fields defined in `step_fields` for this step
   - Show current values from `step_field_values` (read-only for agent)
   - Agent can see what client submitted but NOT edit (client responsibility)
7. **Actions Section**:
   - "Marquer comme complété" button (enabled only if all required docs approved)
   - Manual override checkbox: "Compléter malgré documents manquants" (for exceptions)
   - Completion creates `STEP_COMPLETED` event and advances dossier workflow
8. **Notes Section**:
   - View internal notes for this dossier (from `dossier_notes`)
   - Add new note (visible to all agents, not clients)
9. **Client Communication**:
   - Send message to client button (opens message composer)
   - View recent messages related to this dossier
10. Back button returns to `/agent/steps` queue

---

## Story 5.4: Agent Document Review Interface

As an **agent**,
I want **a centralized queue to review all pending documents across my assigned steps**,
so that **I can process document reviews efficiently without navigating to each step individually**.

### Acceptance Criteria

1. Document review queue at `/agent/reviews` displays all pending documents
2. Queue shows documents where:
   - `documents.status = 'PENDING'`
   - AND document belongs to a step instance assigned to current agent
3. Each document row displays:
   - Document type name
   - Client name and dossier info
   - Step name (which step this document belongs to)
   - Uploaded date
   - File size
   - Version number
4. Table sortable by: Upload date (default oldest first), Document type, Client name
5. Filterable by: Document type (dropdown), Step type (dropdown)
6. Search by client name, dossier ID
7. "Review" button opens document review modal:
   - Full-screen document preview (PDF/image viewer)
   - Document metadata sidebar
   - "Approuver" button (green)
   - "Rejeter" button (red) with required reason textarea
   - After action, modal closes and next document loads automatically
8. Bulk review option:
   - Checkbox selection for multiple documents
   - "Approuver sélection" button (all selected documents approved)
   - "Rejeter sélection" button (requires single reason applied to all)
9. Empty state: "Aucun document à reviewer. Bon travail !"
10. Badge on navigation showing pending documents count
11. Auto-refresh every 60 seconds

---

## Story 5.5: Agent Dashboard Overview

As an **agent**,
I want **a dashboard showing my workload summary and recent activity**,
so that **I can quickly understand my current tasks and priorities**.

### Acceptance Criteria

1. Dashboard at `/agent` (root of agent workspace)
2. **Summary Cards** at top:
   - Étapes assignées: Count of incomplete assigned step_instances
   - Documents à reviewer: Count of pending documents in assigned steps
   - Complétées aujourd'hui: Count of steps completed today by agent
   - Temps moyen de review: Average time from document upload to review
3. Cards clickable: Navigate to respective queue/list
4. **My Steps Queue** (compact view):
   - Show top 5 assigned steps sorted by urgency
   - "Voir tout" link to `/agent/steps`
5. **Pending Reviews** (compact view):
   - Show top 5 pending documents
   - "Voir tout" link to `/agent/reviews`
6. **Recent Activity Feed**:
   - Last 10 actions by current agent
   - Actions: step completed, document reviewed, note added, message sent
   - Timestamp (relative: "il y a 2 heures")
7. **Performance Metrics** (optional):
   - Steps completed this week (bar chart)
   - Documents reviewed this week
8. Welcome message with agent's name
9. Auto-refresh dashboard every 60 seconds

---

## Technical Notes

### Database Queries

**Get agent's assigned steps:**
```sql
SELECT 
  si.*,
  s.code, s.label, s.description,
  d.id as dossier_id, d.status as dossier_status,
  p.name as product_name,
  u.full_name as client_name, u.email as client_email
FROM step_instances si
JOIN steps s ON s.id = si.step_id
JOIN dossiers d ON d.id = si.dossier_id
JOIN products p ON p.id = d.product_id
JOIN profiles u ON u.id = d.user_id
WHERE si.assigned_to = $agent_id
  AND si.completed_at IS NULL
ORDER BY si.started_at ASC NULLS LAST, si.created_at ASC;
```

**Get agent's pending documents:**
```sql
SELECT 
  doc.*,
  dt.label as document_type_label,
  dv.file_url, dv.file_name, dv.uploaded_at, dv.version_number,
  si.step_id,
  s.label as step_label,
  d.id as dossier_id,
  u.full_name as client_name
FROM documents doc
JOIN document_types dt ON dt.id = doc.document_type_id
JOIN document_versions dv ON dv.id = doc.current_version_id
JOIN step_instances si ON si.id = doc.step_instance_id
JOIN steps s ON s.id = si.step_id
JOIN dossiers d ON d.id = doc.dossier_id
JOIN profiles u ON u.id = d.user_id
WHERE doc.status = 'PENDING'
  AND si.assigned_to = $agent_id
ORDER BY dv.uploaded_at ASC;
```

### Navigation Config

Add to `lib/navigation-config.ts`:

```typescript
export const agentNavConfig: NavConfig = {
  sections: [
    {
      label: "Espace Agent",
      items: [
        {
          href: "/agent",
          icon: "fa-gauge-high",
          label: "Tableau de bord",
        },
        {
          href: "/agent/steps",
          icon: "fa-list-check",
          label: "Mes étapes",
        },
        {
          href: "/agent/reviews",
          icon: "fa-file-circle-check",
          label: "Documents à reviewer",
        },
      ],
    },
  ],
};
```

### Route Structure

```
partnersllc-app/app/(protected)/agent/
├── layout.tsx              # Agent workspace layout with agentNavConfig
├── page.tsx                # Dashboard (Story 5.5)
├── steps/
│   ├── page.tsx            # Steps queue (Story 5.2)
│   └── [id]/
│       └── page.tsx        # Step processing view (Story 5.3)
└── reviews/
    └── page.tsx            # Document review queue (Story 5.4)
```

### Authentication

Use new `requireAgentRoleAuth()` function (from Story 4.9):

```typescript
// Only allows AGENT or ADMIN roles (not CLIENT)
export async function requireAgentRoleAuth(): Promise<User> {
  const user = await getCurrentUser();
  if (!user || !['AGENT', 'ADMIN'].includes(user.role)) {
    redirect('/unauthorized');
  }
  return user;
}
```

### Agent vs Admin Access

| User Role | `/admin/*` | `/agent/*` | `/dashboard/*` |
|-----------|------------|------------|----------------|
| CLIENT    | ❌ 403     | ❌ 403     | ✅ Access      |
| AGENT     | ❌ 403     | ✅ Access  | ❌ Redirect    |
| ADMIN     | ✅ Access  | ✅ Access  | ✅ Access      |

---

## Dependencies

### Prerequisite Stories (must be completed first)

1. **Story 4.9**: User Role Migration - Required for `profiles.role` field
2. **Story 4.3**: Agent assignment mechanism at step_instance level (already done)

### Related Stories

- Story 4.10: Admin Client Management - Admin manages clients
- Story 4.11: Admin Agent Management - Admin manages agents, invites new agents
- Story 4.8: Admin Dossiers List - Admin views all dossiers

---

## Success Metrics

- Agent can see only steps assigned to them (no data leakage)
- Average step processing time reduced by having dedicated workspace
- Document review throughput maintained or improved
- Clear separation between admin (management) and agent (execution) workflows
- Agents can complete their work without accessing admin tools
