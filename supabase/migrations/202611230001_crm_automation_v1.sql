-- Persianas 360 CRM + Automation v1
-- Apply only after reviewing and configuring a Supabase project.
-- Migration is additive and does not seed real customer data.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  timezone text not null default 'Europe/Madrid',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  preferred_language text not null default 'es' check (preferred_language in ('es','ca','en','other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'technician' check (role in ('owner','admin','dispatcher','technician','viewer')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (organization_id,user_id)
);

create or replace function public.is_org_member(p_org_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_org_id and m.user_id = auth.uid() and m.active
  );
$$;

create or replace function public.has_org_role(p_org_id uuid, p_roles text[])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_org_id and m.user_id = auth.uid()
      and m.active and m.role = any(p_roles)
  );
$$;

create or replace function public.is_profile_in_same_org(p_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.organization_members mine
    join public.organization_members theirs on theirs.organization_id = mine.organization_id
    where mine.user_id = auth.uid() and mine.active
      and theirs.user_id = p_user_id and theirs.active
  );
$$;

revoke all on function public.is_org_member(uuid) from public;
revoke all on function public.has_org_role(uuid,text[]) from public;
revoke all on function public.is_profile_in_same_org(uuid) from public;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_org_role(uuid,text[]) to authenticated;
grant execute on function public.is_profile_in_same_org(uuid) to authenticated;

create or replace function public.handle_new_auth_user_profile()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,full_name,preferred_language)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name'),
    case when new.raw_user_meta_data->>'preferred_language' in ('es','ca','en','other') then new.raw_user_meta_data->>'preferred_language' else 'es' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user_profile();

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name text,
  phone_e164 text not null,
  email text,
  preferred_language text not null default 'es' check (preferred_language in ('es','ca','en','other')),
  whatsapp_opt_in boolean not null default false,
  marketing_opt_in boolean not null default false,
  notes text,
  source_first text,
  source_last text,
  last_contact_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,phone_e164)
);
create index if not exists customers_org_name_idx on public.customers(organization_id,full_name);

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  label text,
  address_line text,
  postal_code text,
  municipality text not null,
  neighborhood text,
  country_code text not null default 'ES',
  latitude double precision,
  longitude double precision,
  access_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists sites_org_municipality_idx on public.sites(organization_id,municipality);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  conversation_id uuid,
  source text not null default 'whatsapp',
  source_detail text,
  service_type text check (service_type in ('repair','installation','dismantling','motorization','quote','other')),
  problem_type text check (problem_type in ('broken_strap','stuck','off_track','broken_slats','noise','wont_open','wont_close','crank','motor','other')),
  shutter_type text,
  operation_type text check (operation_type in ('manual_strap','crank','motorized','unknown')),
  description text,
  ai_summary text,
  ai_confidence numeric(4,3) check (ai_confidence between 0 and 1),
  urgency text not null default 'normal' check (urgency in ('normal','soon','urgent','critical')),
  status text not null default 'new' check (status in ('new','contacted','qualified','quote_pending','quote_sent','booking_pending','booked','in_progress','completed','review_requested','needs_human','follow_up','no_response','lost','cancelled')),
  human_required boolean not null default false,
  human_reason text,
  preferred_days text[] not null default '{}',
  preferred_periods text[] not null default '{}',
  preferred_date date,
  estimated_duration_minutes integer check (estimated_duration_minutes > 0),
  budget_estimate_min numeric(10,2),
  budget_estimate_max numeric(10,2),
  budget_currency char(3) not null default 'EUR',
  consent_recorded_at timestamptz,
  closed_reason text,
  assigned_to uuid references public.profiles(id) on delete set null,
  last_activity_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists leads_org_status_created_idx on public.leads(organization_id,status,created_at desc);
create index if not exists leads_org_urgency_idx on public.leads(organization_id,urgency,created_at desc);
create index if not exists leads_customer_idx on public.leads(customer_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  channel text not null check (channel in ('whatsapp','web','instagram','phone','email','other')),
  provider text,
  provider_account_id text,
  external_conversation_id text,
  status text not null default 'open' check (status in ('open','closed','paused_human')),
  automation_enabled boolean not null default true,
  language text not null default 'es' check (language in ('es','ca','en','other')),
  last_message_at timestamptz,
  summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists conversations_org_status_idx on public.conversations(organization_id,status,last_message_at desc);
create unique index if not exists conversations_external_unique on public.conversations(provider,provider_account_id,external_conversation_id) where external_conversation_id is not null;

alter table public.leads add constraint leads_conversation_fk
  foreign key (conversation_id) references public.conversations(id) on delete set null;

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  direction text not null check (direction in ('inbound','outbound')),
  channel text not null default 'whatsapp',
  provider_message_id text,
  message_type text not null default 'text' check (message_type in ('text','image','video','audio','document','location','interactive','template','other')),
  body text,
  provider_status text,
  sent_at timestamptz,
  received_at timestamptz,
  error_code text,
  error_message text,
  created_at timestamptz not null default now()
);
create unique index if not exists messages_provider_id_unique on public.messages(channel,provider_message_id) where provider_message_id is not null;
create index if not exists messages_conversation_time_idx on public.messages(conversation_id,created_at);

create table if not exists public.lead_media (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  message_id uuid references public.messages(id) on delete set null,
  storage_bucket text not null default 'private-lead-media',
  storage_key text not null,
  media_type text not null check (media_type in ('image','video','audio','document','other')),
  mime_type text,
  file_size_bytes bigint check (file_size_bytes >= 0),
  caption text,
  ai_description text,
  uploaded_at timestamptz not null default now(),
  unique(storage_bucket,storage_key)
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  technician_id uuid references public.profiles(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null check (ends_at > starts_at),
  status text not null default 'proposed' check (status in ('proposed','confirmed','completed','cancelled','rescheduled','no_show')),
  booking_source text not null default 'whatsapp',
  customer_confirmed_at timestamptz,
  calendar_provider text,
  calendar_event_id text,
  calendar_sync_status text not null default 'pending' check (calendar_sync_status in ('pending','synced','failed','not_required')),
  calendar_sync_error text,
  reminder_24h_sent_at timestamptz,
  reminder_2h_sent_at timestamptz,
  cancellation_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists appointments_org_starts_idx on public.appointments(organization_id,starts_at,status);
create index if not exists appointments_technician_idx on public.appointments(technician_id,starts_at,status);
alter table public.appointments add constraint appointments_no_tech_overlap
  exclude using gist (organization_id with =, technician_id with =, tstzrange(starts_at,ends_at,'[)') with &&)
  where (technician_id is not null and status = 'confirmed');

create table if not exists public.work_orders (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  customer_id uuid not null references public.customers(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  technician_id uuid references public.profiles(id) on delete set null,
  code text,
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','waiting_material','blocked_safety','quality_check','completed','cancelled')),
  service_summary text,
  work_notes text,
  materials_used jsonb not null default '[]',
  started_at timestamptz,
  completed_at timestamptz,
  completion_summary text,
  customer_satisfaction text check (customer_satisfaction in ('positive','neutral','negative','unknown')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists work_orders_org_status_idx on public.work_orders(organization_id,status,created_at desc);

create table if not exists public.follow_up_tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete cascade,
  conversation_id uuid references public.conversations(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete cascade,
  assigned_to uuid references public.profiles(id) on delete set null,
  task_type text not null check (task_type in ('human_handoff','follow_up_24h','follow_up_72h','complaint','coverage_check','technical_review','calendar_failure','other')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  title text not null,
  description text,
  due_at timestamptz,
  status text not null default 'open' check (status in ('open','in_progress','done','cancelled')),
  resolved_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists follow_up_org_status_due_idx on public.follow_up_tasks(organization_id,status,due_at);

create table if not exists public.workflow_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  conversation_id uuid references public.conversations(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  work_order_id uuid references public.work_orders(id) on delete set null,
  event_type text not null,
  source text not null default 'system',
  idempotency_key text,
  payload jsonb not null default '{}',
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(organization_id,idempotency_key)
);
create index if not exists workflow_events_org_time_idx on public.workflow_events(organization_id,occurred_at desc);

create table if not exists public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  event_type text not null check (event_type in ('whatsapp.send','calendar.create','calendar.update','calendar.cancel','team.notify','review.request')),
  aggregate_type text not null,
  aggregate_id uuid not null,
  idempotency_key text not null unique,
  payload jsonb not null,
  status text not null default 'pending' check (status in ('pending','processing','sent','failed','dead_letter')),
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists outbox_pending_idx on public.notification_outbox(status,available_at) where status in ('pending','failed');

create table if not exists public.availability_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  technician_id uuid references public.profiles(id) on delete cascade,
  weekday smallint check (weekday between 0 and 6),
  starts_local time not null,
  ends_local time not null check (ends_local > starts_local),
  service_type text,
  slot_duration_minutes integer not null default 60 check (slot_duration_minutes between 15 and 480),
  travel_buffer_minutes integer not null default 30 check (travel_buffer_minutes between 0 and 240),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.availability_exceptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  technician_id uuid references public.profiles(id) on delete cascade,
  exception_date date not null,
  starts_local time,
  ends_local time,
  is_available boolean not null default false,
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.automation_settings (
  organization_id uuid primary key references public.organizations(id) on delete cascade,
  enabled boolean not null default false,
  timezone text not null default 'Europe/Madrid',
  coverage_municipalities text[] not null default '{}',
  business_hours jsonb not null default '{}',
  follow_up_24h_enabled boolean not null default true,
  follow_up_72h_enabled boolean not null default true,
  reminders_enabled boolean not null default true,
  ai_confidence_threshold numeric(4,3) not null default 0.700 check (ai_confidence_threshold between 0 and 1),
  default_visit_duration_minutes integer not null default 60 check (default_visit_duration_minutes between 15 and 480),
  default_travel_buffer_minutes integer not null default 30 check (default_travel_buffer_minutes between 0 and 240),
  updated_at timestamptz not null default now()
);

-- updated_at triggers
do $$
declare t text;
begin
  foreach t in array array['organizations','profiles','customers','sites','leads','conversations','appointments','work_orders','follow_up_tasks','notification_outbox','automation_settings'] loop
    execute format('drop trigger if exists trg_%I_updated_at on public.%I',t,t);
    execute format('create trigger trg_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()',t,t);
  end loop;
end $$;

-- RLS: authenticated team members can access records only within their organization.
alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_members enable row level security;
alter table public.customers enable row level security;
alter table public.sites enable row level security;
alter table public.leads enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.lead_media enable row level security;
alter table public.appointments enable row level security;
alter table public.work_orders enable row level security;
alter table public.follow_up_tasks enable row level security;
alter table public.workflow_events enable row level security;
alter table public.notification_outbox enable row level security;
alter table public.availability_rules enable row level security;
alter table public.availability_exceptions enable row level security;
alter table public.automation_settings enable row level security;

create policy org_select_members on public.organizations for select to authenticated using (public.is_org_member(id));
create policy profile_select_self on public.profiles for select to authenticated using (id = auth.uid() or public.is_profile_in_same_org(id));
create policy profile_update_self on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy members_select_org on public.organization_members for select to authenticated using (public.is_org_member(organization_id));
create policy members_insert_admin on public.organization_members for insert to authenticated with check (public.has_org_role(organization_id,array['owner','admin']));
create policy members_update_admin on public.organization_members for update to authenticated using (public.has_org_role(organization_id,array['owner','admin'])) with check (public.has_org_role(organization_id,array['owner','admin']));
create policy members_delete_admin on public.organization_members for delete to authenticated using (public.has_org_role(organization_id,array['owner','admin']));

do $$
declare t text;
begin
  foreach t in array array['customers','sites','leads','conversations','messages','lead_media','appointments','work_orders','follow_up_tasks','workflow_events','notification_outbox','availability_rules','availability_exceptions','automation_settings'] loop
    execute format('create policy %I on public.%I for select to authenticated using (public.is_org_member(organization_id))',t||'_select_org',t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.is_org_member(organization_id))',t||'_insert_org',t);
    execute format('create policy %I on public.%I for update to authenticated using (public.is_org_member(organization_id)) with check (public.is_org_member(organization_id))',t||'_update_org',t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.has_org_role(organization_id,array[''owner'',''admin'']))',t||'_delete_admin',t);
  end loop;
end $$;

-- Public access is intentionally not granted. Webhook/automation services must use
-- a server-side service role, never a key shipped to the browser.
