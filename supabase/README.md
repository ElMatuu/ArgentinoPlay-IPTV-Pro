# Supabase infrastructure for ArgentinoPlay IPTV Pro

This folder contains the database foundation for the approved Option C architecture (local-first + optional cloud sync).

## Connected Supabase project

- Project ref: `hjymbvbeygfgngvzetgp`
- Region: `us-east-1`
- Current status: active and healthy (checked 2026-11-08)
- Applied migration version: `20261108132652` (`initial_account_and_sync_schema`)

The project was inspected before applying the migration; it had no existing application tables or migration history. The migration is now applied to this project. This is the current connected project, not a claim that production launch is complete.

## What the migration creates

- profiles: account profile tied to Supabase Auth.
- devices: user-owned device registrations and revocation state.
- playlists: opt-in cloud metadata only; no M3U body, source URL, stream URL or embedded credential.
- favorite_channels: favorites keyed by a client-generated stable UUID, without playback URLs.
- user_preferences: small JSON preferences, bounded in size.
- sync_receipts and sync_cursors: initial idempotency/cursor records for a later transactional sync API.

All seven tables have Row Level Security enabled. Owner policies scope user rows to `auth.uid()`. Sync receipt creation and sync cursor writes additionally require an active device. Anonymous table privileges are revoked. The auth profile trigger function is not directly executable by anon/authenticated roles.

A follow-up migration, `20261109021431_tighten_authenticated_table_grants.sql`, revokes broad table grants from `PUBLIC`, `anon` and `authenticated`, then grants only the operations required by each table. This migration is committed to the infrastructure PR but has **not** been applied to the hosted project. Review and deploy it through the migration workflow before enabling cloud sync.

## Validation performed

- Confirmed the seven expected public tables exist.
- Confirmed RLS is enabled on all seven tables.
- Confirmed policies exist for each table.
- Confirmed the profile trigger function cannot be executed directly by anon/authenticated roles.
- Security and health advisors returned no findings at the time of validation.
- Performance advisor reports unused-index INFO notices on a new, empty schema; those are expected before application traffic. Foreign-key coverage was added for the reported relations.

## Not implemented yet

- Transactional push/pull sync API, conflict resolver, tombstone retention or Edge Functions.
- Flutter sign-in/sign-up screens and account recovery.
- Device registration and device-list/revocation UI are implemented on the open Flutter auth PR #7 branch; they are not merged yet. Hosted RLS and physical-device checks remain pending.
- SQLite local database migration and live synchronization.
- End-to-end tests with multiple users/devices and cross-user isolation.

## Security and operation

1. Keep the app local-first: playback and locally stored playlists must continue to work without network access.
2. Keep M3U bodies, playlist source URLs, stream URLs, EPG URLs and credentials on-device by default.
3. For Flutter, use only the project URL and publishable `sb_publishable_` key. RLS is mandatory; a publishable key is not an authorization mechanism.
4. Never put an `sb_secret_` key, database password or Supabase personal access token in Flutter, APKs, source files or logs.
5. GitHub Actions only needs the project URL and publishable key for the optional client initialization build. Administrative tokens are not consumed by the Flutter workflow.
6. Do not merge the infrastructure PR or enable production sync until authentication, ownership checks, conflict handling, backups and restore have been tested.

## Local CLI workflow

On a trusted development computer with Supabase CLI and Docker installed:

```sh
supabase start
supabase db reset
supabase db lint
```

To link the already-created project:

```sh
supabase link --project-ref hjymbvbeygfgngvzetgp
supabase migration list
```

Do not paste database passwords, access tokens or secret API keys into chat. Use the connected Supabase integration for authorized management tasks.
