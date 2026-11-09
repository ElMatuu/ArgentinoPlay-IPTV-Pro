-- Tighten table privileges to the minimum required by the authenticated client.
-- Row ownership remains enforced by the existing RLS policies.
-- This migration does not apply itself to the hosted project; deploy through the
-- reviewed Supabase migration workflow after approval.
begin;

revoke all privileges on table
  public.profiles,
  public.devices,
  public.playlists,
  public.favorite_channels,
  public.user_preferences,
  public.sync_receipts,
  public.sync_cursors
from public, anon, authenticated;

grant select, update
  on table public.profiles
  to authenticated;

grant select, insert, update, delete
  on table
    public.devices,
    public.playlists,
    public.favorite_channels,
    public.user_preferences
  to authenticated;

grant select, insert
  on table public.sync_receipts
  to authenticated;

grant select, insert, update, delete
  on table public.sync_cursors
  to authenticated;

commit;
