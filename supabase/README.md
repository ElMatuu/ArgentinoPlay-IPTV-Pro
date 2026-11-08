# Supabase infrastructure for ArgentinoPlay IPTV Pro

This folder contains the versioned database foundation for the approved Option C architecture (local-first + optional cloud sync).

## What this migration creates

- profiles: account profile tied to Supabase Auth.
- devices: user-owned device registrations and revocation state.
- playlists: opt-in cloud metadata only; no M3U body, source URL, stream URL or embedded credential.
- favorite_channels: favorites keyed by a client-generated stable UUID, without playback URLs.
- user_preferences: small JSON preferences, bounded in size.
- sync_receipts and sync_cursors: initial idempotency/cursor records for a later transactional sync API.

All tables enable Row Level Security (RLS). Anonymous access is revoked. Policies scope records to auth.uid() and device ownership.

## Not implemented by this migration

- A hosted Supabase project or production database.
- A transactional push/pull RPC, conflict resolver, tombstone retention or Edge Function.
- Flutter authentication screens, secure token storage, SQLite or live synchronization.
- Upload of playlist files or stream URLs.

## Owner setup (required once the Supabase integration is connected)

1. Create a Supabase organization/project owned by the project owner. Choose a region close to intended users and confirm current pricing/limits in the Dashboard before provisioning.
2. Apply this migration to a development project first. Review the SQL and inspect RLS policies before production.
3. Keep the database password and sb_secret key server-side only. Never put them in Flutter, GitHub source, build artifacts or chat.
4. For Flutter, use only the project URL and publishable sb_publishable key. The publishable key is not an authorization mechanism; RLS is mandatory.
5. Do not add GitHub Actions secrets until a workflow actually consumes them. For deployment automation, use narrowly scoped credentials and a protected GitHub environment.
6. Test signup, profile creation, device ownership, cross-user isolation, revoked-device rejection, migration rollback and restore before enabling any real sync.

## Apply locally

Install Supabase CLI and Docker on a trusted development computer, then run:

```sh
supabase start
supabase db reset
supabase db lint
```

Link a hosted development project only after the owner creates it:

```sh
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Do not paste database passwords, access tokens or secret API keys into chat. If direct management through the connected Supabase integration is enabled, use that authenticated connection instead of copying credentials around.
