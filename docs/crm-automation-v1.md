# Persianas 360 — CRM & Automation v1

Status: implementation specification for the first operational CRM. This branch does not provision cloud services or store secrets.

## Architecture / source of truth

- **Supabase Postgres**: canonical source of truth for customers, leads, conversations, messages, appointments, work orders and workflow events.
- **Existing Persianas 360 app**: operator UI and dashboard. It must read/write through authenticated Supabase APIs; no browser-side service-role key.
- **WhatsApp Business Platform**: inbound/outbound channel, behind a webhook adapter.
- **Automation runner (n8n or small serverless functions)**: orchestration, AI calls, calendar sync and notifications. Keep business rules in versioned functions, not only visual workflows.
- **Google Calendar**: availability/appointment mirror in v1. The database reservation is authoritative; calendar sync is retryable.
- **AI agent**: drafts replies and extracts structured facts. Deterministic code validates service coverage, status changes, pricing and booking.

## MVP boundaries

1. WhatsApp intake, language detection, service/problem classification.
2. Lead creation/update with idempotent inbound message handling.
3. Ask for missing facts in a single-question conversational flow.
4. Save photo/video metadata and private storage keys.
5. Human escalation and team notification.
6. Appointment proposal and double-checked booking.
7. Calendar event creation/update/cancel via outbox.
8. Reminder and post-job follow-up tasks.
9. Dashboard queries: new leads, qualified, pending human, bookings today, completed jobs, source and conversion.

No automatic definitive diagnosis or price quote in v1. No unverified appointment promises. No payment collection. Customer messages may be AI-assisted; disclose that it is a virtual assistant.

## Lead lifecycle

`NEW → CONTACTED → QUALIFIED → QUOTE_PENDING → QUOTE_SENT → BOOKING_PENDING → BOOKED → IN_PROGRESS → COMPLETED → REVIEW_REQUESTED`

Alternate states: `NEEDS_HUMAN`, `FOLLOW_UP`, `NO_RESPONSE`, `LOST`, `CANCELLED`.

- `QUALIFIED` requires service type, problem summary, location and a valid contact.
- `BOOKED` requires a confirmed appointment row.
- `COMPLETED` requires a work order marked complete by a technician/operator.
- Any complaint, safety concern, unsupported work, low confidence or customer request for human sets `human_required=true` and status `NEEDS_HUMAN`.
- A lead can have multiple appointments, conversations and work orders over time.

## Intake workflow (WF-01)

Trigger: WhatsApp webhook message.

1. Verify Meta signature and webhook token.
2. Normalize sender to E.164; map channel account and organization.
3. Insert message with unique `provider_message_id`; if conflict, return 200 and do not process twice.
4. Find or create customer by organization + phone.
5. Find open conversation; create if none.
6. Find or create lead attached to conversation; merge extracted facts without overwriting known values with null.
7. Store media metadata and private storage key; asynchronously analyze images, never expose public URLs.
8. Detect language and intent. Ask only the next missing question based on state.
9. AI response must return structured intent/facts/next_question/escalation; validate against allowed enums.
10. Send WhatsApp reply via provider adapter; persist outbound message and provider ID.
11. Record workflow event and update lead's `last_activity_at`.
12. If escalation, create follow-up task + notification outbox entry.

Failure behavior: acknowledge provider webhook after durable receipt; process asynchronously. Retry transient failures with exponential backoff. Dead-letter after max retries and notify operator.

## Workflow catalog

### WF-01 WhatsApp Intake
Webhook → signature verification → idempotency → customer/conversation/lead upsert → media metadata → AI extraction → state machine → reply → event log.

### WF-02 Human handoff
Triggers: customer asks for human, complaint, critical safety, unsupported service, confidence below configured threshold, pricing exception, out-of-area, or repeated misunderstanding.
Create task priority; notify owners; pause autonomous outbound except a short acknowledgement. Resume only when task is resolved or human explicitly returns control.

### WF-03 Appointment booking
1. Ask for preferred day/period only when not already supplied.
2. Query availability rules, existing appointments, technician working hours, travel buffers and blackout dates.
3. Offer 2–3 slots.
4. On selection, re-check availability inside booking transaction.
5. Insert appointment with status `confirmed`; overlap exclusion prevents collisions.
6. Insert outbox event `calendar.create`; worker syncs Google Calendar and stores event ID.
7. Send confirmation only after database booking succeeds. Calendar sync can be pending; notify internal team if it fails.

### WF-04 Reminders
Scheduled runner checks appointments due in 24h and 2h, using `reminder_24h_sent_at` and `reminder_2h_sent_at` as idempotency fields. Send only within WhatsApp messaging policy/consent windows; use approved templates where required. Customer can confirm, reschedule or cancel.

### WF-05 Reschedule / cancel
Customer intent → identify appointment → confirm cancellation or collect preferred windows → recheck slots → update appointment → outbox calendar update/delete → notify technicians → customer confirmation.

### WF-06 Work order
Appointment accepted/created → create work order or link existing one → operator/technician marks in progress → completed. Never auto-complete from AI. At completion, queue thank-you and review request, subject to messaging policy.

### WF-07 Follow-up
Scheduled task for incomplete leads: one reminder around 24h and one final around 72h (configurable); stop immediately on reply, booking, opt-out or human handoff. Avoid repeated or promotional messages without valid consent.

### WF-08 Dashboard aggregates
Read-only SQL views or API endpoints for: lead counts by state, source, service, urgency; appointments today/next 7 days; human tasks; completed work; quote/revenue fields when introduced. Dashboard uses organization-scoped RLS.

## Appointment states

`proposed → confirmed → completed`; alternate `cancelled`, `rescheduled`, `no_show`.

Only `confirmed` appointments reserve capacity. Cancellation releases the slot. Technician assignment may be null during MVP; once assigned, prevent overlapping appointments.

## AI contract

The model is not allowed to write directly to the database. It returns JSON with:
- `intent`
- `language`
- `facts` (only supported fields)
- `confidence`
- `next_question` (one question)
- `reply`
- `escalation_reason`
- `requires_human`

Backend validates, applies state transitions, calls tools and persists data. Model can never make a booking, send an unapproved price, or claim dispatch without a successful tool result.

## Data retention / privacy checklist

- Minimize personal data; collect full address only when a visit is accepted.
- Media stored in private bucket; signed links expire.
- Consent/opt-out recorded.
- Provide access, correction and deletion workflow; preserve legal records only where required.
- Secrets belong in provider secrets/environment, never Git or frontend.
- Before production: configure privacy notice, lawful basis, WhatsApp templates, data processor agreements and retention policy.

## Implementation order

1. Apply migration in `supabase/migrations/202611230001_crm_automation_v1.sql`.
2. Configure organization + memberships; seed service catalog and availability.
3. Build authenticated CRM UI against tables/views.
4. Deploy webhook adapter and workflow runner.
5. Connect WhatsApp test number; test with synthetic data.
6. Calendar integration; test conflicts, reschedules, cancellations and retry behavior.
7. End-to-end test before publishing to customers.
