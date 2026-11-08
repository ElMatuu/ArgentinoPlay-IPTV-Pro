# Local-first and cloud synchronization architecture

**Decision:** Option C — local operation with optional cloud synchronization.
**Implementation status:** synchronization contracts are being introduced; there is no deployed backend, login, SQLite migration or live sync yet.

## Product guarantees

- Core library browsing, playlist management, favorites and playback must continue without an account or internet connection.
- The device database is the immediate read/write source for the app.
- Cloud synchronization is an optional transport and backup layer, never a runtime dependency for opening the app.
- A failed, interrupted or unauthorized sync must not roll back local changes.
- No stream is bundled or retransmitted by this sync layer. Users remain responsible for importing sources they are authorized to use.

## Data flow

```text
Flutter UI
   |
Repository interfaces
   |
Local SQLite transaction + pending outbox
   |                         |
Offline reads/writes         Sync worker (network available + user opted in)
                             |
                       HTTPS API (future)
                             |
                   Account-scoped server DB (future)
```

SQLite and the outbox are the next implementation stage. A future server must be accessed only through an authenticated HTTPS API; the mobile app must never contain database administrator or service-role credentials.

## Sync scope and privacy defaults

| Data | Default behavior |
|---|---|
| Favorites | Eligible for opt-in account sync |
| User preferences | Eligible for opt-in account sync |
| Playlist display metadata | Sync only after explicit user opt-in |
| M3U/M3U8 source URLs and contents | Never upload by default; explicit per-playlist choice and rights/security review required |
| Channel stream URLs | Do not copy into cloud catalog by default |
| EPG source URLs and imported XMLTV | Local by default; explicit opt-in only |
| Playback history | Not collected or synced by default |
| Credentials embedded in URLs | Reject at import; never sync |
| Rights evidence | Keep provenance; do not treat public reachability as a license |

## Conflict and delivery protocol

1. Every local mutation is committed in one SQLite transaction together with an outbox record.
2. Each change has an opaque idempotency ID, entity ID, entity type, operation, UTC timestamp, originating device ID and optional base server revision.
3. The client sends batches over TLS. The server authenticates the session and derives the account owner from the token, never from a client-supplied owner ID.
4. The server deduplicates by idempotency ID and returns accepted revisions, rejected changes and an opaque incremental cursor.
5. A revision mismatch is a conflict, not permission to overwrite silently. Favorites/preferences may later use documented merge rules; playlist metadata requires conflict-aware field handling. Deletions require tombstones until every active device has advanced beyond them.
6. The client applies remote changes and advances the cursor in one local transaction. A crash before commit safely replays the batch.
7. Retry transient network failures with bounded exponential backoff and jitter. Authentication/authorization failures pause sync and ask the user to sign in again.

## Security requirements

- HTTPS/TLS only; short-lived access tokens and refresh-token rotation.
- Store tokens only in platform-backed secure storage, never SharedPreferences or source files.
- Enforce account ownership and device revocation on every API operation.
- Validate payload sizes, identifiers, enum values and schema versions on both client and server.
- Never log tokens, playlist URLs, query credentials, personal identifiers or full playback URLs.
- Do not fetch arbitrary imported URLs on the sync server. Any future URL fetcher requires SSRF protections, redirect limits, timeouts and private/reserved IP blocking.
- Provide user-controlled export, disconnect, delete-account and local-only modes before general availability.

## Phased implementation and gates

### C1 — local database foundation
- Add SQLite schema versioning, repositories and transactional migrations.
- Import current JSON manifests, M3U files, XMLTV and favorites idempotently.
- Keep legacy data until row counts and hashes verify; test rollback and interrupted migration.
- Do not switch UI repositories until migration tests pass.

### C2 — local outbox and sync contracts
- Persist outbox entries and cursor locally.
- Add idempotency, revision checks, tombstones and conflict records.
- Test replay, duplicate delivery, partial batch failure, conflict and offline operation.

### C3 — backend and account model
- Select an owner-approved provider, region, budget, privacy/retention policy and recovery process.
- Deploy an HTTPS API and account-scoped relational database; add threat model, backups and restore tests.
- No provider or paid resource is selected or provisioned by this change.

### C4 — opt-in multi-device synchronization
- Implement authentication, device registration/revocation, incremental pull/push and user consent.
- Start with favorites and preferences. Add playlist metadata only after explicit opt-in.
- Keep playlist source bodies and stream URLs local unless a separate explicit feature decision and rights review approve otherwise.

### C5 — release readiness
- Test two-device sync, offline edits, reconnect, duplicate requests, conflict resolution, account deletion, revoked devices and backup restore.
- Verify no secrets or private stream URLs appear in app bundles, logs or CI artifacts.

## Current repository implementation note

The existing client still uses app-private files and SharedPreferences for portions of its local library. This architecture document does not claim that SQLite, accounts, a server, or cloud sync are already implemented. The first code change introduces portable synchronization value objects only; replacing the current repositories is gated on the SQLite migration and tests.
