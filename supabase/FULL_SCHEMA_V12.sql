-- TeoriX v1.2 FULL SCHEMA — run once in Supabase SQL Editor
-- Includes base progress/report tables + v1.2 profiles/entitlements/content packs.

-- TeoriX / Senshi Labs - v1.1 Global Supabase schema
create extension if not exists pgcrypto;

create table if not exists public.question_bank (
  id text primary key,
  country_code text not null default 'TR',
  region_code text not null default '',
  content_locale text not null default 'tr',
  category text not null,
  lesson_id text,
  question_text text not null,
  options jsonb not null,
  correct_index int not null check (correct_index between 0 and 5),
  explanation text not null default '',
  difficulty text not null default 'medium',
  penalty_points int not null default 0,
  image_url text,
  version int not null default 1,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One cloud snapshot per user AND country pack. Switching countries no longer
-- overwrites the user's other country's progress.
create table if not exists public.user_progress_snapshots (
  user_id uuid not null references auth.users(id) on delete cascade,
  country_id text not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, country_id)
);

create table if not exists public.question_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  country_id text not null default 'tr',
  question_id text not null,
  reason text not null,
  detail text not null default '',
  status text not null default 'open',
  created_at timestamptz not null default now()
);

alter table public.question_bank enable row level security;
alter table public.user_progress_snapshots enable row level security;
alter table public.question_reports enable row level security;

do $$ begin
  create policy "active questions readable" on public.question_bank for select using (is_active = true);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "own snapshot read" on public.user_progress_snapshots for select using (auth.uid() = user_id);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "own snapshot insert" on public.user_progress_snapshots for insert with check (auth.uid() = user_id);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "own snapshot update" on public.user_progress_snapshots for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "report insert" on public.question_reports for insert with check (auth.uid() = user_id or user_id is null);
exception when duplicate_object then null; end $$;

-- Production billing entitlement mirror. The entitlement is account-wide, so
-- one Pro purchase works across all TeoriX country packs.
create table if not exists public.billing_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  pro boolean not null default false,
  ad_free boolean not null default false,
  source_product_id text,
  purchase_token_hash text,
  expires_at timestamptz,
  verified_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.billing_entitlements enable row level security;
do $$ begin
  create policy "own billing entitlement read" on public.billing_entitlements
    for select using (auth.uid() = user_id);
exception when duplicate_object then null; end $$;

-- TeoriX v1.2 - account, billing, remote content and zero-cost AI-ready backend
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  ui_locale text not null default 'tr',
  study_locale text not null default 'tr',
  active_country_id text not null default 'tr',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Canonical account entitlement mirror. The client can READ this table but
-- cannot write it; only the RevenueCat webhook (service role) updates it.
create table if not exists public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan text not null default 'free' check (plan in ('free','plus','pro')),
  plus_active boolean not null default false,
  pro_active boolean not null default false,
  product_id text,
  store text,
  environment text,
  will_renew boolean,
  expires_at timestamptz,
  last_event_id text,
  verified_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Webhook idempotency/audit. RevenueCat retries reuse the same event id.
create table if not exists public.purchase_events (
  event_id text primary key,
  app_user_id text,
  event_type text not null,
  product_id text,
  entitlement_ids text[] not null default '{}',
  store text,
  environment text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

-- Versioned, remotely updateable master course packs. One row contains a JSON
-- array of lessons/questions/signs. Bundled assets remain the offline fallback.
create table if not exists public.content_packs (
  id uuid primary key default gen_random_uuid(),
  country_id text not null,
  content_type text not null check (content_type in ('questions','lessons','traffic_signs')),
  locale text not null,
  version integer not null default 1,
  payload jsonb not null,
  source_note text not null default 'TeoriX original study content',
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(country_id, content_type, locale, version)
);

create table if not exists public.content_versions (
  country_id text not null,
  content_type text not null,
  locale text not null,
  current_version integer not null default 1,
  updated_at timestamptz not null default now(),
  primary key (country_id, content_type, locale)
);

-- Reserved for future paid AI. v1.2 uses prepared explanations, therefore the
-- app can launch with zero AI API spend while the quota architecture is ready.
create table if not exists public.ai_usage_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_day date not null default current_date,
  generated_requests integer not null default 0,
  cached_requests integer not null default 0,
  primary key (user_id, usage_day)
);

create index if not exists idx_progress_user on public.user_progress_snapshots(user_id);
create index if not exists idx_content_packs_lookup on public.content_packs(country_id, content_type, locale, is_active, version desc);
create index if not exists idx_question_reports_user on public.question_reports(user_id);
create index if not exists idx_purchase_events_user on public.purchase_events(app_user_id);

alter table public.profiles enable row level security;
alter table public.entitlements enable row level security;
alter table public.purchase_events enable row level security;
alter table public.content_packs enable row level security;
alter table public.content_versions enable row level security;
alter table public.ai_usage_daily enable row level security;

-- Profiles: users manage only their own profile.
do $$ begin
  create policy "profile own read" on public.profiles for select to authenticated
    using ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "profile own insert" on public.profiles for insert to authenticated
    with check ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "profile own update" on public.profiles for update to authenticated
    using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;

-- Billing: client read only. No insert/update/delete policy is intentionally
-- present for authenticated/anon users.
do $$ begin
  create policy "entitlement own read" on public.entitlements for select to authenticated
    using ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;

-- Content is public read-only while active/current. Writes happen from the
-- dashboard/service role only.
do $$ begin
  create policy "active content packs readable" on public.content_packs for select to anon, authenticated
    using (is_active = true and valid_from <= now() and (valid_until is null or valid_until > now()));
exception when duplicate_object then null; end $$;
do $$ begin
  create policy "content versions readable" on public.content_versions for select to anon, authenticated
    using (true);
exception when duplicate_object then null; end $$;

-- Future AI usage is visible to the owner but written server-side only.
do $$ begin
  create policy "ai usage own read" on public.ai_usage_daily for select to authenticated
    using ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;

-- Tighten the older progress policies with explicit authenticated role.
do $$ begin
  create policy "own snapshot delete v12" on public.user_progress_snapshots for delete to authenticated
    using ((select auth.uid()) = user_id);
exception when duplicate_object then null; end $$;

-- Compatibility view for older app builds that queried billing_entitlements.
-- Keep the old table if it already exists; v1.2 reads `entitlements`.
