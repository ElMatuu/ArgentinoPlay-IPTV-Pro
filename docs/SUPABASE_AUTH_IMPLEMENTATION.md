# Supabase authentication implementation notes

The Flutter client uses only the project URL and publishable API key. Never compile an `sb_secret_` key, Supabase personal access token, database password, or service-role credential into an app.

`SupabaseAuthService` provides email sign-up, password sign-in, password-recovery email requests, sign-out, and current-user state. It is a service boundary only; user-facing screens, redirect/deep-link registration, email templates, and end-to-end auth tests remain separate tasks.

Cloud accounts are optional. Local playlist playback and locally stored data must remain available when a user is signed out or offline.

Before enabling account creation in production:
1. Configure the project's Auth site URL and allowed redirect URLs for the actual Android/iOS/web app identifiers.
2. Verify email confirmation and password recovery behavior in the Supabase dashboard.
3. Test duplicate accounts, invalid credentials, expired sessions, recovery links, and sign-out.
4. Keep all database tables protected by RLS and test cross-user isolation with two independent accounts.
5. Never log passwords, access tokens, refresh tokens, or full auth responses.
