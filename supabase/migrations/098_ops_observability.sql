-- 098_ops_observability.sql (renumbered from 087)
-- ==========================================
-- Observability Tables: Incidents, Jobs, Middleware Events
-- Uses UUID for IDs to be compatible with ops_audit_log entity_id
-- ==========================================

-- ========== Incidents ==========
create table if not exists public.ops_incidents (
  id uuid primary key default gen_random_uuid(),
  severity text not null check (severity in ('P0','P1','P2')),
  component text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  summary text not null,
  root_cause text,
  fix_action text,
  owner_staff_id uuid references public.auth.users(id),
  correlation_id text,
  related_refs jsonb not null default '{}'::jsonb
);

create index if not exists ops_incidents_started_at_idx on public.ops_incidents (started_at desc);
create index if not exists ops_incidents_open_idx on public.ops_incidents (ended_at) where ended_at is null;
create index if not exists ops_incidents_component_idx on public.ops_incidents (component, started_at desc);

-- ========== Jobs ==========
create table if not exists public.ops_jobs (
  id uuid primary key default gen_random_uuid(),
  job_type text not null,
  status text not null check (status in ('started','succeeded','failed')),
  trigger text not null default 'system', -- cron/manual/webhook/system
  attempt int not null default 1,
  max_attempts int not null default 1,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_ms int,
  correlation_id text,
  error_code text,
  error_message text,
  meta jsonb not null default '{}'::jsonb
);

create index if not exists ops_jobs_started_at_idx on public.ops_jobs (started_at desc);
create index if not exists ops_jobs_type_status_idx on public.ops_jobs (job_type, status, started_at desc);
create index if not exists ops_jobs_corr_idx on public.ops_jobs (correlation_id);

-- ========== Middleware events ==========
create table if not exists public.ops_mw_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null, -- rate_limited/schema_invalid/circuit_open/abuse_suspected
  route text,
  actor_id uuid references public.auth.users(id),
  correlation_id text,
  created_at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb
);

create index if not exists ops_mw_events_created_at_idx on public.ops_mw_events (created_at desc);
create index if not exists ops_mw_events_type_idx on public.ops_mw_events (event_type, created_at desc);
create index if not exists ops_mw_events_route_idx on public.ops_mw_events (route, created_at desc);

-- ========== RLS (Skeleton implemented with is_ops_staff) ==========
alter table public.ops_incidents enable row level security;
alter table public.ops_jobs enable row level security;
alter table public.ops_mw_events enable row level security;

-- Policies for ops_incidents
create policy "ops read incidents" on public.ops_incidents
  for select to authenticated using (public.is_ops_staff());
create policy "ops insert incidents" on public.ops_incidents
  for insert to authenticated with check (public.is_ops_staff('operator'));
create policy "ops update incidents" on public.ops_incidents
  for update to authenticated using (public.is_ops_staff('operator'));
create policy "ops delete incidents" on public.ops_incidents
  for delete to authenticated using (public.is_ops_staff('admin'));

-- Policies for ops_jobs
create policy "ops read jobs" on public.ops_jobs
  for select to authenticated using (public.is_ops_staff());
create policy "ops insert jobs" on public.ops_jobs
  for insert to authenticated with check (public.is_ops_staff('operator'));
create policy "ops update jobs" on public.ops_jobs
  for update to authenticated using (public.is_ops_staff('operator'));
create policy "ops delete jobs" on public.ops_jobs
  for delete to authenticated using (public.is_ops_staff('admin'));

-- Policies for ops_mw_events
create policy "ops read mw events" on public.ops_mw_events
  for select to authenticated using (public.is_ops_staff());
create policy "ops insert mw events" on public.ops_mw_events
  for insert to authenticated with check (public.is_ops_staff('operator'));
create policy "ops update mw events" on public.ops_mw_events
  for update to authenticated using (public.is_ops_staff('operator'));
create policy "ops delete mw events" on public.ops_mw_events
  for delete to authenticated using (public.is_ops_staff('admin'));

-- ========== GRANTS (least-privilege: authenticated=SELECT, service_role=full) ==========
revoke all on public.ops_incidents from authenticated;
grant select on public.ops_incidents to authenticated;
grant insert, update, delete on public.ops_incidents to service_role;

revoke all on public.ops_jobs from authenticated;
grant select on public.ops_jobs to authenticated;
grant insert, update, delete on public.ops_jobs to service_role;

revoke all on public.ops_mw_events from authenticated;
grant select on public.ops_mw_events to authenticated;
grant insert, update, delete on public.ops_mw_events to service_role;

-- ========== Triggers for Audit Logging ==========
create or replace function public.trg_ops_incidents_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_ops_audit('insert', 'ops_incidents', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    perform public.log_ops_audit('update', 'ops_incidents', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  elsif tg_op = 'DELETE' then
    perform public.log_ops_audit('delete', 'ops_incidents', old.id, to_jsonb(old), null);
    return old;
  end if;
  return new;
end;
$$;

create trigger ops_incidents_audit_tg
  after insert or update or delete on public.ops_incidents
  for each row execute function public.trg_ops_incidents_audit();

create or replace function public.trg_ops_jobs_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_ops_audit('insert', 'ops_jobs', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    perform public.log_ops_audit('update', 'ops_jobs', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  elsif tg_op = 'DELETE' then
    perform public.log_ops_audit('delete', 'ops_jobs', old.id, to_jsonb(old), null);
    return old;
  end if;
  return new;
end;
$$;

create trigger ops_jobs_audit_tg
  after insert or update or delete on public.ops_jobs
  for each row execute function public.trg_ops_jobs_audit();

create or replace function public.trg_ops_mw_events_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_ops_audit('insert', 'ops_mw_events', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    perform public.log_ops_audit('update', 'ops_mw_events', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  elsif tg_op = 'DELETE' then
    perform public.log_ops_audit('delete', 'ops_mw_events', old.id, to_jsonb(old), null);
    return old;
  end if;
  return new;
end;
$$;

create trigger ops_mw_events_audit_tg
  after insert or update or delete on public.ops_mw_events
  for each row execute function public.trg_ops_mw_events_audit();
