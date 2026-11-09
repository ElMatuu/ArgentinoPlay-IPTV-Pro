# Supabase authentication implementation notes

The Flutter client uses only the project URL and publishable API key. Never compile an `sb_secret_` key, Supabase personal access token, database password, or service-role credential into an app.

`SupabaseAuthService` provides email sign-up, password sign-in, password-recovery email requests, password updates after a recovery callback, sign-out, and current-user state. `AccountScreen` exposes sign-up, sign-in, recovery-email request, and new-password entry after the SDK emits the `passwordRecovery` auth event.

The Android CI scaffold registers the app callback URI:

`io.supabase.argentinoplay://login-callback`

Before recovery can work against the hosted project, an administrator must add that exact URI to **Authentication → URL Configuration → Redirect URLs** in the Supabase dashboard. The app cannot verify or modify that hosted allowlist through its client configuration. The site URL and email templates must also be configured for the intended production experience.

Cloud accounts are optional. Local playlist playback and locally stored data must remain available when a user is signed out or offline.

Before enabling account creation in production:
1. Add and verify the exact Android callback URI in the hosted Auth redirect allowlist.
2. Configure email confirmation and password-recovery templates, then test the complete email round trip on a physical Android device.
3. Test duplicate accounts, invalid credentials, expired recovery links, password updates, session refresh, and sign-out.
4. Keep all database tables protected by RLS and test cross-user isolation with two independent accounts.
5. Never log passwords, access tokens, refresh tokens, or full auth responses.

The automated tests validate local input handling and cloud-unconfigured UI behavior. They do not replace hosted email delivery, deep-link, or physical-device end-to-end tests. CI runs strict `dart format`, fatal static analysis, the full Flutter test suite, and a debug APK build.
