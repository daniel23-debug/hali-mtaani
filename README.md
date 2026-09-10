# Hali Mtaani — Know what's happening in your mtaa

A single-file web app (`index.html`, no build step): community incident reports on a
real map, local service providers, and organization responses — with live sync between
devices via Supabase.

## Run it

Any static server works:

```bash
cd hali-mtaani
python3 -m http.server 8080
# open http://localhost:8080
```

You can also just double-click `index.html`. Note: browser geolocation ("Use my
location") requires a secure context — `localhost` or `https`.

## Connect live sync (Supabase)

The app works fully **offline** without any setup — reports, providers, bookings and
cases are saved on-device and sync automatically when the server is reachable.

For live sharing between devices:

1. Create a free project at [supabase.com](https://supabase.com).
2. In the Dashboard, open the **SQL editor** and run everything in
   [`supabase-schema.sql`](supabase-schema.sql) (creates the 6 tables, access
   policies, and realtime sync — safe to re-run).
3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_KEY` (Project Settings → API →
   `URL` + `anon public` key).

The sidebar status pill shows **Live sync on** when connected, or **Offline · saved
on this device — tap to retry** when not. Tapping it forces a sync attempt.

## How it stays error-free

- **Offline-first storage** — every write lands in on-device storage first, then
  syncs; a failed sync goes to a persistent outbox and retries automatically.
- **Missing/broken backend tolerated** — absent tables, permission errors, blocked
  CDNs, denied GPS, and failed map tiles each degrade to a working fallback
  (list views, manual coordinates) instead of a blank page or console spam.
- ** Defensive rendering** — every view null-checks server rows, escapes all
  user content (text, attributes, and inline handlers), and a crashing view falls
  back to a safe screen with a "Go to Home" button.
- **No lost typing** — background syncs never redraw a form you are filling in,
  and typed input + cursor position survive re-renders.
- **Per-device state** — alert read-status, bookings ("My Requests"), and
  one-confirmation-per-device are scoped to each device, not shared globally.
- **No save races** — single-row upserts instead of whole-collection overwrites,
  plus double-submit guards on every action.

> Prototype note: the bundled SQL uses open access policies so the demo works
> immediately. Add authentication and restrictive policies before real-world use.
