-- Restrict the Data API roles to the operations required by the app.
-- RLS remains enabled and continues to enforce per-user row ownership.
revoke all privileges on table
  public.profiles,
  public.devices,
  public.playlists,
  public.favorite_channels,
  public.user_preferences,
  public.sync_receipts,
  public.sync_cursors
from public, anon, authenticated;

grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table
  public.devices,
  public.playlists,
  public.favorite_channels,
  public.user_preferences
to authenticated;
grant select, insert on table public.sync_receipts to authenticated;
grant select, insert, update, delete on table public.sync_cursors to authenticated;
