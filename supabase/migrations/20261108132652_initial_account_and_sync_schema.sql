-- ArgentinoPlay IPTV Pro: initial cloud account and opt-in sync schema.
-- Local playback remains independent. Never store raw M3U URLs or stream credentials here.
begin;
create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin new.updated_at = now(); return new; end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 80),
  locale text not null default 'es-AR' check (char_length(locale) <= 16),
  timezone text not null default 'America/Argentina/Buenos_Aires' check (char_length(timezone) <= 64),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_label text not null default 'My device' check (char_length(device_label) between 1 and 80),
  platform text not null check (platform in ('android', 'android_tv', 'ios', 'windows', 'macos', 'web', 'other')),
  app_version text not null default '' check (char_length(app_version) <= 32),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (user_id, id)
);
create index if not exists devices_user_active_idx on public.devices(user_id, last_seen_at desc) where revoked_at is null;

-- Cloud playlist rows contain metadata only. The source URI and M3U body stay on device.
create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  source_kind text not null check (source_kind in ('file', 'url', 'manual')),
  content_hash text check (content_hash is null or content_hash ~ '^[a-f0-9]{64}$'),
  sync_enabled boolean not null default false,
  rights_reference text check (rights_reference is null or char_length(rights_reference) <= 512),
  revision bigint not null default 1 check (revision > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists playlists_user_name_ci_idx on public.playlists(user_id, lower(name));
create index if not exists playlists_user_updated_idx on public.playlists(user_id, updated_at desc);

-- channel_key is a client-generated stable UUID; never upload stream URLs or tokens.
create table if not exists public.favorite_channels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  channel_key uuid not null,
  playlist_id uuid references public.playlists(id) on delete set null,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 160),
  created_at timestamptz not null default now(),
  unique (user_id, channel_key)
);
create index if not exists favorite_channels_user_created_idx on public.favorite_channels(user_id, created_at desc);
create index if not exists favorite_channels_playlist_id_idx on public.favorite_channels(playlist_id) where playlist_id is not null;

create table if not exists public.user_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  preference_key text not null check (preference_key ~ '^[a-z][a-z0-9_.-]{0,63}$'),
  preference_value jsonb not null check (pg_column_size(preference_value) <= 8192),
  updated_at timestamptz not null default now(),
  primary key (user_id, preference_key)
);

-- Idempotency receipts support retry-safe sync batches. They are not a substitute
-- for the transactional sync RPC, which will be introduced in a later migration.
create table if not exists public.sync_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid not null,
  idempotency_key uuid not null,
  entity_type text not null check (entity_type in ('playlist_metadata', 'favorite', 'user_preference')),
  entity_id uuid not null,
  operation text not null check (operation in ('upsert', 'delete')),
  base_revision bigint check (base_revision is null or base_revision >= 0),
  applied_revision bigint check (applied_revision is null or applied_revision > 0),
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key),
  foreign key (user_id, device_id) references public.devices(user_id, id) on delete cascade
);
create index if not exists sync_receipts_user_created_idx on public.sync_receipts(user_id, created_at desc);
create index if not exists sync_receipts_user_device_idx on public.sync_receipts(user_id, device_id);

create table if not exists public.sync_cursors (
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid not null,
  entity_type text not null check (entity_type in ('playlist_metadata', 'favorite', 'user_preference')),
  cursor_value text not null default '' check (char_length(cursor_value) <= 2048),
  updated_at timestamptz not null default now(),
  primary key (user_id, device_id, entity_type),
  foreign key (user_id, device_id) references public.devices(user_id, id) on delete cascade
);

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''))
  on conflict (id) do nothing;
  return new;
end;
$;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute procedure public.set_updated_at();
drop trigger if exists playlists_set_updated_at on public.playlists;
create trigger playlists_set_updated_at before update on public.playlists
  for each row execute procedure public.set_updated_at();
drop trigger if exists user_preferences_set_updated_at on public.user_preferences;
create trigger user_preferences_set_updated_at before update on public.user_preferences
  for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.playlists enable row level security;
alter table public.favorite_channels enable row level security;
alter table public.user_preferences enable row level security;
alter table public.sync_receipts enable row level security;
alter table public.sync_cursors enable row level security;

drop policy if exists "profile owner can read" on public.profiles;
create policy "profile owner can read" on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
drop policy if exists "profile owner can update" on public.profiles;
create policy "profile owner can update" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "device owner can manage" on public.devices;
create policy "device owner can manage" on public.devices for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "playlist owner can manage" on public.playlists;
create policy "playlist owner can manage" on public.playlists for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "favorite owner can manage" on public.favorite_channels;
create policy "favorite owner can manage" on public.favorite_channels for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "preference owner can manage" on public.user_preferences;
create policy "preference owner can manage" on public.user_preferences for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "sync receipt owner can read" on public.sync_receipts;
create policy "sync receipt owner can read" on public.sync_receipts for select to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists "sync receipt owner can create" on public.sync_receipts;
create policy "sync receipt owner can create" on public.sync_receipts for insert to authenticated
  with check ((select auth.uid()) = user_id and exists (
    select 1 from public.devices d where d.id = device_id
      and d.user_id = (select auth.uid()) and d.revoked_at is null
  ));

drop policy if exists "sync cursor owner can manage" on public.sync_cursors;
create policy "sync cursor owner can manage" on public.sync_cursors for all to authenticated
  using ((select auth.uid()) = user_id) with check (
    (select auth.uid()) = user_id and exists (
      select 1 from public.devices d where d.id = device_id
        and d.user_id = (select auth.uid()) and d.revoked_at is null
    )
  );

revoke all on public.profiles, public.devices, public.playlists,
  public.favorite_channels, public.user_preferences,
  public.sync_receipts, public.sync_cursors from anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.devices, public.playlists,
  public.favorite_channels, public.user_preferences to authenticated;
grant select, insert on public.sync_receipts to authenticated;
grant select, insert, update, delete on public.sync_cursors to authenticated;
commit;
