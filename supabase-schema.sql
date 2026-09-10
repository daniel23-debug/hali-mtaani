-- ============================================================
-- HALI MTAANI — Supabase schema
-- Dashboard → SQL editor → paste → Run. Safe to re-run.
--
-- The app works fully offline without this (data stays on the
-- device), but live sharing between devices needs these tables.
--
-- NOTE (prototype): policies below let anyone with the anon key
-- read/write. Fine for a demo; add auth + tighter policies before
-- any real-world use.
-- ============================================================

-- ---------- tables ----------
create table if not exists public.incidents (
  id text primary key,
  title text not null default 'Untitled report',
  category text not null default 'Other',
  description text not null default '',
  severity text not null default 'medium',
  status text not null default 'active',
  confidence integer not null default 20,
  confirmations integer not null default 0,
  "reportedBy" text not null default 'Anonymous resident',
  "createdAt" bigint not null default ((extract(epoch from now()) * 1000)::bigint),
  lat double precision null,
  lng double precision null,
  timeline jsonb not null default '[]'::jsonb,
  "confirmedBy" jsonb not null default '[]'::jsonb
);

create table if not exists public.providers (
  id text primary key,
  name text not null default 'Unnamed provider',
  category text not null default 'General',
  blurb text not null default '',
  price text not null default '',
  verified boolean not null default false,
  lat double precision null,
  lng double precision null,
  "createdAt" bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

create table if not exists public.bookings (
  id text primary key,
  "providerId" text not null default '',
  "providerName" text not null default 'Provider',
  "desc" text not null default '',
  requester text not null default 'Anonymous resident',
  "deviceId" text not null default '',
  status text not null default 'pending',
  time bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

create table if not exists public.alerts (
  id text primary key,
  title text not null default 'Alert',
  body text not null default '',
  time bigint not null default ((extract(epoch from now()) * 1000)::bigint),
  level text not null default 'info',
  read boolean not null default false
);

create table if not exists public.cases (
  id text primary key,
  "incidentId" text not null default '',
  org text not null default 'Responding organization',
  title text not null default 'Untitled case',
  status text not null default 'in-progress',
  priority text not null default 'medium',
  "assignedTeam" text not null default 'Unassigned',
  "updatedAt" bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

create table if not exists public.orgs (
  id text primary key,
  name text not null default 'Unnamed organization',
  sector text not null default '',
  verified boolean not null default false,
  "createdAt" bigint not null default ((extract(epoch from now()) * 1000)::bigint)
);

-- ---------- indexes ----------
create index if not exists incidents_created_idx on public.incidents ("createdAt" desc);
create index if not exists bookings_time_idx on public.bookings (time desc);
create index if not exists alerts_time_idx on public.alerts (time desc);
create index if not exists cases_updated_idx on public.cases ("updatedAt" desc);

-- ---------- access (prototype-open) ----------
do $do$
declare t text;
begin
  foreach t in array array['incidents','providers','bookings','alerts','cases','orgs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "open all" on public.%I', t);
    execute format('create policy "open all" on public.%I for all using (true) with check (true)', t);
  end loop;
end $do$;

-- ---------- realtime (live sync between devices) ----------
do $do$
declare t text;
begin
  foreach t in array array['incidents','providers','bookings','alerts','cases','orgs'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $do$;
