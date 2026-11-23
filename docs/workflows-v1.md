# Persianas 360 — Workflow runbooks v1

These are provider-neutral workflows to implement in n8n or serverless functions. Credentials and provider IDs are intentionally placeholders.

## WF-01: WhatsApp inbound

**Trigger:** `POST /webhooks/whatsapp`

1. Verify provider signature; reject invalid request.
2. Normalize payload to `InboundMessage`.
3. Persist raw provider event in a protected log (exclude unnecessary personal data from logs).
4. Idempotency key: provider message ID. Duplicate → HTTP 200, no repeated side effects.
5. Upsert customer by `organization_id + phone_e164`.
6. Find open conversation for that customer/channel; create if absent.
7. Persist inbound message.
8. Attach media metadata; enqueue private media download. Media download URLs are short-lived.
9. Load lead/conversation context and CRM service coverage.
10. Call AI extraction endpoint with current context and allowed schema.
11. Validate extraction. If unsupported/low confidence, escalate.
12. Apply deterministic state-machine transition and persist facts.
13. Send reply. Save outbound message and provider ID.
14. If escalation, create task + outbox notification.
15. Mark processing complete and emit workflow event.

## WF-02: AI extraction/reply

Input includes latest user message, previous conversation summary, known fields, service catalog, coverage rules and state.

Output schema:
```json
{
  "intent": "repair|installation|dismantling|motorization|quote|other|unknown",
  "language": "es|ca|other",
  "problem_type": "broken_strap|stuck|off_track|broken_slats|noise|wont_open|wont_close|crank|motor|other|null",
  "facts": {
    "shutter_type": null,
    "operation": null,
    "municipality": null,
    "neighborhood": null,
    "urgency": "normal|soon|urgent|critical|null",
    "description": null,
    "customer_name": null,
    "availability": []
  },
  "confidence": 0.0,
  "requires_human": false,
  "escalation_reason": null,
  "next_question": "one short question or null",
  "reply": "customer-facing text"
}
```
Never include invented price/slot or unsafe DIY instructions. A question should ask for the highest-priority missing fact only. Backend controls actual state transitions and tool execution.

## WF-03: Appointment slots

**Input:** lead ID, optional date range/preferences, service duration, location.

- Resolve timezone: `Europe/Madrid`.
- Use configured working hours and exceptions.
- Query confirmed appointments and technician availability.
- Add travel buffer (initial configurable default, not a promise).
- Return at most 3 slots.
- Do not expose other customers' details.

## WF-04: Confirm booking (atomic)

- Client selects one proposed slot.
- Re-query availability immediately.
- Begin transaction; insert confirmed appointment.
- Conflict constraint/transaction failure → return alternate slots.
- Insert `calendar.create` event into outbox.
- On success send confirmation; on calendar failure, booking remains confirmed in CRM and team is notified that calendar sync is pending.

## WF-05: Calendar outbox worker

- Poll `notification_outbox` rows with status pending.
- Claim rows atomically (worker lock / `FOR UPDATE SKIP LOCKED`).
- Process `calendar.create|update|cancel`.
- Store external event ID on appointment.
- Retry transient errors with exponential backoff.
- After max attempts mark failed and create `NEEDS_HUMAN` task.
- Idempotency key = outbox event UUID.

## WF-06: Appointment reminders

Scheduled every 15 minutes:
- Find confirmed appointments starting in 24h window (and 2h window, configurable).
- Ensure sent timestamp is null.
- Check conversation opt-out and messaging policy.
- Send approved template or allowed session message.
- Update sent timestamp only after provider acceptance.
- On reply, route to reschedule/confirm/cancel intent.

## WF-07: Human handoff

Triggers:
- explicit human request
- critical safety/risk
- complaint or payment dispute
- unsupported work
- low confidence or repeated failed understanding
- outside coverage or price exception

Create follow-up task with priority, lead, conversation and summary. Send short acknowledgement. Set conversation automation paused. Notify owners via configured channel.

## WF-08: No-response follow-up

- At 24h: one helpful nudge if still waiting for required information.
- At 72h: final nudge, then mark `NO_RESPONSE`.
- Stop on customer reply, booking, opt-out, escalation or closure.
- Do not send marketing messages without consent/legal basis.

## WF-09: Job completion/post-sale

Technician/operator marks work order complete and records work summary. Queue:
1. Thank-you message.
2. Review request after configurable delay, only if eligible.
3. Optional referral prompt.
Do not generate/send review requests before completion.

## WF-10: Dashboard refresh

Use organization-scoped views/API. KPIs:
- leads today / 7 days / month
- lead funnel by state
- lead source
- service mix
- urgent leads
- human handoffs open
- appointments today/next 7 days
- jobs completed
- conversion and revenue only once quote/invoice data is reliable.

## Error/retry policy

- Validation/business errors: no automatic retry; show operator actionable error.
- Provider/network 429/5xx: exponential backoff + jitter.
- Webhook must acknowledge after durable receipt, not after AI response.
- Failed jobs go to dead-letter queue and create alert.
- All automation actions have idempotency keys and workflow event records.
