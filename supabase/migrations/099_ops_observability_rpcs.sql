-- 099_ops_observability_rpcs.sql (renumbered from 088)
-- Converted from SQL to PL/pgSQL to add is_ops_staff() authorization check

create or replace function public.ops_get_daily_summary()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if not public.is_ops_staff() then
    raise exception 'ops_access_denied: not authorized';
  end if;

  select jsonb_build_object(
    'open_incidents', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select severity, component, count(*) as open_cnt
        from public.ops_incidents
        where ended_at is null
        group by severity, component
        order by severity, open_cnt desc
      ) t
    ),
    'jobs_failures', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select job_type,
               count(*) as total,
               count(*) filter (where status='failed') as failed,
               percentile_cont(0.95) within group (order by duration_ms) as p95_ms
        from public.ops_jobs
        where started_at >= now() - interval '24 hours'
          and duration_ms is not null
        group by job_type
        order by failed desc, p95_ms desc
      ) t
    ),
    'mw_events_top', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select event_type, count(*) as cnt
        from public.ops_mw_events
        where created_at >= now() - interval '24 hours'
        group by event_type
        order by cnt desc
      ) t
    )
  ) into result;

  return result;
end;
$$;

create or replace function public.ops_get_weekly_trend()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if not public.is_ops_staff() then
    raise exception 'ops_access_denied: not authorized';
  end if;

  select jsonb_build_object(
    'incidents_trend', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select date_trunc('day', started_at) as day,
               severity,
               count(*) as incidents,
               avg(extract(epoch from (ended_at - started_at)))/60 as avg_mttr_min
        from public.ops_incidents
        where started_at >= now() - interval '7 days'
        group by 1,2
        order by 1,2
      ) t
    ),
    'jobs_failures_trend', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select date_trunc('day', started_at) as day,
               job_type,
               count(*) filter (where status='failed') as failed,
               count(*) as total
        from public.ops_jobs
        where started_at >= now() - interval '7 days'
        group by 1,2
        order by 1,2
      ) t
    ),
    'mw_rate_limited_trend', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select date_trunc('day', created_at) as day,
               route,
               count(*) as rate_limited
        from public.ops_mw_events
        where created_at >= now() - interval '7 days'
          and event_type='rate_limited'
        group by 1,2
        order by 1,3 desc
      ) t
    )
  ) into result;

  return result;
end;
$$;

grant execute on function public.ops_get_daily_summary() to authenticated;
grant execute on function public.ops_get_weekly_trend() to authenticated;
