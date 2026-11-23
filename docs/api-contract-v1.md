# API contract v1 (automation adapter)

All endpoints below are design contracts. Deploy behind HTTPS; verify WhatsApp signatures; use Supabase Auth for operator endpoints and service-role credentials only on server.

## Provider webhook

`POST /webhooks/whatsapp`

- Verify provider signature and challenge.
- Normalize event.
- Durable insert/idempotency.
- Return `200` after persistence; asynchronous processing follows.

## CRM operator endpoints

- `GET /api/dashboard/summary?range=7d`
- `GET /api/leads?status=&source=&service=&urgency=&q=&page=`
- `GET /api/leads/:id`
- `PATCH /api/leads/:id` (operator edits; audit event)
- `POST /api/leads/:id/handoff`
- `POST /api/leads/:id/reopen`
- `GET /api/appointments?from=&to=&technician_id=`
- `GET /api/appointments/slots?lead_id=&date_from=&date_to=`
- `POST /api/appointments` (server re-checks slot, transactionally inserts)
- `PATCH /api/appointments/:id/reschedule`
- `POST /api/appointments/:id/cancel`
- `POST /api/work-orders/:id/start`
- `POST /api/work-orders/:id/complete`

## Appointment create payload

```json
{
  "lead_id": "uuid",
  "site_id": "uuid",
  "technician_id": "uuid-or-null",
  "starts_at": "2026-11-25T09:00:00+01:00",
  "ends_at": "2026-11-25T10:00:00+01:00",
  "customer_confirmed": true,
  "notes": "Optional"
}
```

## Error shape

```json
{
  "error": {
    "code": "SLOT_TAKEN",
    "message": "La franja ya no está disponible.",
    "retryable": true,
    "request_id": "uuid"
  }
}
```

## Dashboard response

```json
{
  "leads": {"today": 0, "open": 0, "qualified": 0, "needs_human": 0},
  "appointments": {"today": 0, "next_7_days": 0},
  "work_orders": {"in_progress": 0, "completed_7_days": 0},
  "sources": [],
  "service_mix": []
}
```
