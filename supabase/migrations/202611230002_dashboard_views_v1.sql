-- Dashboard views v1. PostgreSQL 15 / Supabase.
-- Views run with invoker permissions so underlying RLS remains effective.

create or replace view public.dashboard_lead_counts
with (security_invoker = true)
as
select
  organization_id,
  count(*) filter (where created_at >= date_trunc('day', now())) as leads_today,
  count(*) filter (where created_at >= now() - interval '7 days') as leads_7d,
  count(*) filter (where status not in ('completed','lost','cancelled')) as leads_open,
  count(*) filter (where status = 'qualified') as leads_qualified,
  count(*) filter (where status = 'needs_human' or human_required) as leads_needs_human,
  count(*) filter (where status = 'booked') as leads_booked,
  count(*) filter (where status = 'completed') as leads_completed
from public.leads
group by organization_id;

create or replace view public.dashboard_leads_by_status
with (security_invoker = true)
as
select organization_id, status, count(*) as total
from public.leads
group by organization_id,status;

create or replace view public.dashboard_leads_by_source
with (security_invoker = true)
as
select organization_id, coalesce(source,'unknown') as source, count(*) as total
from public.leads
group by organization_id,coalesce(source,'unknown');

create or replace view public.dashboard_service_mix
with (security_invoker = true)
as
select organization_id, coalesce(service_type,'unknown') as service_type, count(*) as total
from public.leads
group by organization_id,coalesce(service_type,'unknown');

create or replace view public.dashboard_appointments
with (security_invoker = true)
as
select
  a.organization_id,
  count(*) filter (where a.status = 'confirmed' and (a.starts_at at time zone coalesce(o.timezone,'Europe/Madrid'))::date = (now() at time zone coalesce(o.timezone,'Europe/Madrid'))::date as appointments_today,
  count(*) filter (where a.status = 'confirmed' and a.starts_at >= now() and a.starts_at < now() + interval '7 days') as appointments_next_7d,
  count(*) filter (where a.status = 'confirmed') as appointments_confirmed,
  count(*) filter (where a.status = 'cancelled') as appointments_cancelled
from public.appointments a
join public.organizations o on o.id = a.organization_id
group by a.organization_id;

create or replace view public.dashboard_work_orders
with (security_invoker = true)
as
select
  organization_id,
  count(*) filter (where status = 'in_progress') as work_orders_in_progress,
  count(*) filter (where status = 'waiting_material') as work_orders_waiting_material,
  count(*) filter (where status = 'blocked_safety') as work_orders_blocked_safety,
  count(*) filter (where status = 'completed' and completed_at >= now() - interval '7 days') as work_orders_completed_7d
from public.work_orders
group by organization_id;

create or replace view public.dashboard_human_tasks
with (security_invoker = true)
as
select
  organization_id,
  count(*) filter (where status in ('open','in_progress')) as tasks_open,
  count(*) filter (where priority in ('high','urgent') and status in ('open','in_progress')) as tasks_priority
from public.follow_up_tasks
group by organization_id;
