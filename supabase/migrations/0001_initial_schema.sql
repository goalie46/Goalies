-- CreaseLog schema / RLS design draft. Apply only after review in a development project.
create extension if not exists pgcrypto;
create extension if not exists citext;
create type public.member_role as enum ('owner','coach','staff');
create type public.access_role as enum ('coach','athlete','parent');
create type public.session_state as enum ('draft','published','archived');
create type public.assignment_state as enum ('planned','active','athlete_done','coach_verified');
create type public.report_state as enum ('draft','approved','needs_review');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  created_at timestamptz not null default now()
);
create table public.organizations (
  id uuid primary key default gen_random_uuid(), name text not null,
  created_by uuid not null references public.users(id), created_at timestamptz not null default now()
);
create table public.memberships (
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  role public.member_role not null, revoked_at timestamptz,
  primary key (organization_id,user_id)
);
create table public.athletes (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  display_name text not null, birth_year int check (birth_year between 1900 and 2200), team_name text,
  created_by uuid not null references public.users(id), created_at timestamptz not null default now()
);
create table public.athlete_access (
  athlete_id uuid references public.athletes(id) on delete cascade, user_id uuid references public.users(id) on delete cascade,
  role public.access_role not null, granted_by uuid not null references public.users(id), granted_at timestamptz not null default now(), revoked_at timestamptz,
  primary key (athlete_id,user_id,role)
);
create table public.invitations (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  athlete_id uuid references public.athletes(id) on delete cascade, email citext not null, role public.access_role not null,
  token_hash text not null unique, expires_at timestamptz not null, accepted_at timestamptz, revoked_at timestamptz,
  created_by uuid not null references public.users(id), created_at timestamptz not null default now(),
  check (expires_at > created_at), check (role <> 'coach' or athlete_id is not null)
);
create table public.goals (
  id uuid primary key default gen_random_uuid(), athlete_id uuid not null references public.athletes(id) on delete cascade,
  kind text not null check(kind in ('season','current')), body text not null, active boolean not null default true,
  created_by uuid not null references public.users(id), created_at timestamptz not null default now()
);
create table public.sessions (
  id uuid primary key default gen_random_uuid(), athlete_id uuid not null references public.athletes(id) on delete cascade,
  coach_id uuid not null references public.users(id), occurred_on date not null, lesson_type text not null check(lesson_type in ('private','team','game_review')),
  topic text not null, status public.session_state not null default 'draft', idempotency_key uuid not null unique,
  published_at timestamptz, updated_at timestamptz not null default now(), created_at timestamptz not null default now(),
  check ((status = 'published' and published_at is not null) or status <> 'published')
);
create table public.session_feedback (
  session_id uuid primary key references public.sessions(id) on delete cascade,
  strengths text[] not null check(cardinality(strengths) between 1 and 2), improvement text not null,
  additional_details text, next_check text not null
);
create table public.private_coach_notes (
  session_id uuid primary key references public.sessions(id) on delete cascade,
  coach_id uuid not null references public.users(id), body text not null, updated_at timestamptz not null default now()
);
create table public.assignments (
  id uuid primary key default gen_random_uuid(), session_id uuid not null unique references public.sessions(id) on delete cascade,
  athlete_id uuid not null references public.athletes(id) on delete cascade, body text not null, success_criteria text not null,
  due_at timestamptz, status public.assignment_state not null default 'planned', athlete_completed_at timestamptz, coach_verified_at timestamptz,
  check (status <> 'coach_verified' or coach_verified_at is not null)
);
create table public.self_checks (
  id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.assignments(id) on delete cascade,
  athlete_user_id uuid not null references public.users(id), rating smallint check(rating between 1 and 5), note text,
  created_at timestamptz not null default now(), unique(assignment_id,athlete_user_id)
);
create table public.media_assets (
  id uuid primary key default gen_random_uuid(), session_id uuid not null references public.sessions(id) on delete cascade,
  athlete_id uuid not null references public.athletes(id), storage_path text not null unique, mime_type text not null check(mime_type in ('video/mp4','video/quicktime')),
  byte_size bigint not null check(byte_size between 1 and 524288000), duration_ms int check(duration_ms > 0), upload_state text not null check(upload_state in ('pending','uploading','ready','failed')),
  created_by uuid not null references public.users(id), created_at timestamptz not null default now()
);
create table public.media_annotations (
  id uuid primary key default gen_random_uuid(), media_asset_id uuid not null references public.media_assets(id) on delete cascade,
  start_ms int not null check(start_ms >= 0), end_ms int not null, comment text,
  check(end_ms > start_ms)
);
create table public.monthly_reports (
  id uuid primary key default gen_random_uuid(), athlete_id uuid not null references public.athletes(id) on delete cascade,
  period_start date not null, period_end date not null, state public.report_state not null default 'draft',
  goal text, observed_change text, continue_practice text, next_plan text, coach_summary text,
  approved_by uuid references public.users(id), approved_at timestamptz, updated_at timestamptz not null default now(),
  unique(athlete_id,period_start), check(period_end >= period_start), check(state <> 'approved' or approved_at is not null)
);
create table public.consent_logs (
  id uuid primary key default gen_random_uuid(), athlete_id uuid not null references public.athletes(id) on delete cascade,
  guardian_user_id uuid not null references public.users(id), policy_version text not null, action text not null check(action in ('granted','revoked')),
  occurred_at timestamptz not null default now()
);

create or replace function public.has_athlete_access(target uuid, allowed public.access_role[])
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.athlete_access aa where aa.athlete_id=target and aa.user_id=auth.uid() and aa.role=any(allowed) and aa.revoked_at is null)
$$;
revoke all on function public.has_athlete_access(uuid,public.access_role[]) from public;
grant execute on function public.has_athlete_access(uuid,public.access_role[]) to authenticated;

alter table public.athletes enable row level security;
alter table public.sessions enable row level security;
alter table public.session_feedback enable row level security;
alter table public.private_coach_notes enable row level security;
alter table public.assignments enable row level security;
alter table public.self_checks enable row level security;
alter table public.monthly_reports enable row level security;
alter table public.media_assets enable row level security;

create policy athlete_read on public.athletes for select to authenticated using (public.has_athlete_access(id,array['coach','athlete','parent']::public.access_role[]));
create policy session_read on public.sessions for select to authenticated using (
 public.has_athlete_access(athlete_id,array['coach']::public.access_role[]) or
 (status='published' and public.has_athlete_access(athlete_id,array['athlete','parent']::public.access_role[]))
);
create policy session_coach_write on public.sessions for all to authenticated
 using (coach_id=auth.uid() and public.has_athlete_access(athlete_id,array['coach']::public.access_role[]))
 with check (coach_id=auth.uid() and public.has_athlete_access(athlete_id,array['coach']::public.access_role[]));
create policy feedback_read on public.session_feedback for select to authenticated using (
 exists(select 1 from public.sessions s where s.id=session_id and (public.has_athlete_access(s.athlete_id,array['coach']::public.access_role[]) or (s.status='published' and public.has_athlete_access(s.athlete_id,array['athlete','parent']::public.access_role[]))))
);
create policy private_note_owner_only on public.private_coach_notes for all to authenticated using (coach_id=auth.uid()) with check(coach_id=auth.uid());
create policy assignment_read on public.assignments for select to authenticated using (
 public.has_athlete_access(athlete_id,array['coach']::public.access_role[]) or
 (public.has_athlete_access(athlete_id,array['athlete','parent']::public.access_role[]) and exists(select 1 from public.sessions s where s.id=session_id and s.status='published'))
);
create policy report_read on public.monthly_reports for select to authenticated using (
 public.has_athlete_access(athlete_id,array['coach']::public.access_role[]) or
 (state='approved' and public.has_athlete_access(athlete_id,array['athlete','parent']::public.access_role[]))
);
create policy media_read on public.media_assets for select to authenticated using (
 public.has_athlete_access(athlete_id,array['coach']::public.access_role[]) or
 (public.has_athlete_access(athlete_id,array['athlete','parent']::public.access_role[]) and exists(select 1 from public.sessions s where s.id=session_id and s.status='published'))
);

-- Storage policies and mutating policies are intentionally deferred to authenticated Edge Functions.
-- The functions must validate organization membership, access revocation, annotation duration and invitation single-use atomically.
