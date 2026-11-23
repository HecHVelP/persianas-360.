# CRM v1 setup & acceptance checklist

## Current project constraints

- Existing Lovable project: Persianas 360 Service Hub.
- Cloud database is currently disabled.
- Lovable workspace currently reports out of credits; this work is prepared in GitHub and has not been applied to the live Lovable app.
- Do not provision a paid service or connect real customer data until Héctor and José approve the provider, costs and privacy setup.

## Supabase setup (when approved)

1. Create/enable the project using the free tier, after verifying current limits.
2. Run migrations in order:
   - `202611230001_crm_automation_v1.sql`
   - `202611230002_dashboard_views_v1.sql`
3. Create the private Storage bucket `private-lead-media`; disallow public access. Set file size/MIME limits. Storage policies should authorize signed-in members through their organization and lead-media metadata.
4. Bootstrap the Persianas 360 organization and initial owner membership with the service role (one-time server-side action). Never place service-role key in browser code.
5. Configure authentication for Héctor and José; profile rows are created by the auth trigger.
6. Add initial coverage, business hours and service durations in `automation_settings` and `availability_rules`. Keep the automation master switch off until end-to-end tests pass.
7. Configure secrets in the automation host: Supabase URL, service-role key, WhatsApp provider token/phone-number ID, webhook verification token, AI provider key, Google Calendar OAuth. Secret names only; never commit values.
8. Configure WhatsApp webhook and verify Meta challenge/signature handling.
9. Configure Google Calendar target calendar and OAuth; test create/update/delete events.
10. Configure monitoring, retry/dead-letter alert and a human handoff notification channel.

## Synthetic test cases

1. New repair lead: broken strap, Barcelona, image received → lead qualified; ask next missing fact.
2. User sends multiple messages quickly → provider message IDs deduplicate; no duplicate leads or replies.
3. User sends media → metadata linked to correct lead; storage remains private.
4. Critical safety message → human task, high priority, automation paused.
5. Unsupported/out-of-area service → human review; no promise.
6. User asks for price → only configured price rules; otherwise transparent estimate/human review.
7. Slot offered, then taken by another booking → confirmation fails gracefully and offers new slots.
8. Confirmed booking → appointment row, calendar outbox, WhatsApp confirmation; idempotent retry does not duplicate calendar event.
9. Reschedule/cancel → DB and calendar synchronized; old slot released.
10. Calendar API outage → booking remains in CRM, sync pending, alert/task created.
11. 24h reminder → sent once; opt-out suppresses future reminders.
12. No response → 24h and 72h follow-ups only; stops when customer replies.
13. Technician marks work completed → thank-you/review workflow runs only once.
14. Complaint → human handoff, no AI argument or automatic refund promise.
15. Dashboard user from another organization cannot read data.
16. Mobile usability test on Android with Héctor and José.

## Go-live gate

All tests above pass with synthetic data; business coverage, pricing, appointment durations, travel buffer, privacy notice, consent, messaging templates, retention and technical scope have been validated. Start with a test number and manual confirmation of appointments; enable autonomous confirmation only after successful conflict and failure tests.
