# Deployment Guide

This repo is a multi-target project. Each layer ships to a different host.

| Layer | Path | Host | Notes |
|-------|------|------|-------|
| Admin Panel | `admin/` | **Vercel** | Next.js 16 — monorepo config in `vercel.json` |
| Guest PWA | `hotel_guest_app/` | **Netlify** | already live at `exquisite-cocada-7966bd.netlify.app` |
| Staff App | `staff_app/` | Android Play Store / iOS App Store | mobile build, not a hosted website |
| Backend | `supabase/` | **Supabase** | migrations + edge functions + auth + storage |

---

## 1. Admin Panel → Vercel

> **CRITICAL** — this is a monorepo. The Next.js app lives in `admin/`, not at the repo root. You MUST tell Vercel where it is, otherwise you get a 404 on the deployed URL.

### One-time setup (5 minutes)

#### If creating a new project:
1. Go to <https://vercel.com/new> → **Import Git Repository** → pick `boaz65sa-byte/hotel-management`.
2. **Root Directory** → click **Edit** → select **`admin`** from the tree → confirm.
3. Vercel auto-detects Next.js (via `admin/vercel.json` + `admin/package.json`). Leave Build/Output overrides empty.
4. **Environment Variables** — add all four (apply to Production + Preview + Development):

   | Key | Where to find |
   |-----|---------------|
   | `SUPABASE_URL` | Supabase → Project → Settings → API → Project URL |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API → `service_role` key (keep secret) |
   | `NEXT_PUBLIC_SUPABASE_URL` | same as `SUPABASE_URL` |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase → Settings → API → `anon public` |

5. Click **Deploy**. First build ≈ 90 seconds.
6. Open the assigned `*.vercel.app` URL — should redirect to `/login`. Log in with `superadmin@hotel.com / Admin1234!`.

#### If you already created the project (and got a 404):
1. Vercel → Project → **Settings** → **General** → **Root Directory** → click **Edit**.
2. Pick **`admin`** from the tree → **Save**.
3. **Deployments** → latest → ⋯ menu → **Redeploy**.

### Updates
Every push to `main` auto-deploys. To skip deploys when only non-`admin/` paths change, in Vercel Settings → Git → **Ignored Build Step** set:
```
git diff --quiet HEAD^ HEAD ./
```
(Vercel applies this relative to the project Root Directory, which is `admin/`, so this skips the build whenever nothing inside `admin/` changed.)

### Custom domain
Vercel → Project → Settings → Domains → add your domain. Free TLS via Let's Encrypt.

---

## 2. Backend → Supabase (mandatory before admin works)

```bash
cd "/Users/boazsaada/manegmant resapceon"

# 1. Login + link
supabase login
supabase link --project-ref vetwlonyzyzvhrtdwbzj

# 2. Run all migrations
supabase db push

# 3. Deploy edge functions
# send-push is called by pg_net DB triggers, which never carry a Supabase
# JWT — it authenticates via its own x-webhook-secret header instead, so it
# must be deployed without JWT verification. This is now also declared in
# supabase/config.toml ([functions.send-push] verify_jwt = false), but pass
# the flag explicitly too — deploying without it once already caused every
# push webhook to fail with 401 UNAUTHORIZED_NO_AUTH_HEADER in production.
supabase functions deploy send-push --no-verify-jwt
supabase functions deploy invite-user
supabase functions deploy manage-user
supabase functions deploy export-excel
supabase functions deploy run-scheduled-tasks
```

### Auth Hook (must be configured in Dashboard)
Authentication → **Auth Hooks** → Add hook:
- Hook type: **Custom Access Token**
- Function: `public.custom_jwt_claims`

Without this, JWTs won't contain `hotel_id` and RLS will reject most queries.

### Database Webhooks (6 total — for OneSignal push)
Implemented as `pg_net`/`net.http_post` calls inside `SECURITY DEFINER` trigger functions (see `supabase/migrations/20260515000003_send_push_webhooks.sql`, `20260827000003_amenities_ordering.sql`, and `20260828000001_webhook_secret_vault.sql`), not as Dashboard-configured Database Webhooks — all hit `{SUPABASE_URL}/functions/v1/send-push` with header `x-webhook-secret` set to the value looked up at runtime from Supabase Vault (secret name `webhook_secret`), never a literal in the migration file.

| Name | Table | Event | Header `x-event-type` |
|------|-------|-------|------------------------|
| whk_guest_request_insert | guest_requests | INSERT | guest_request_insert |
| whk_guest_request_status | guest_requests | UPDATE | guest_request_status |
| whk_ticket_insert | tickets | INSERT | ticket_insert |
| whk_ticket_assigned | ticket_assignments | INSERT | ticket_assigned |
| whk_room_assigned | rooms | UPDATE | room_assigned |
| whk_amenity_order_insert | amenity_orders | INSERT | amenity_order_insert |

### Edge Function Secrets
```bash
supabase secrets set ONESIGNAL_APP_ID=...
supabase secrets set ONESIGNAL_REST_API_KEY=...
```

`WEBHOOK_SECRET` is rotated separately — see "Rotating the webhook secret" below; never set it directly here without also updating Vault, or the two sides will disagree and every push will 401.

### Rotating the webhook secret
The 6 trigger functions above read their auth header from Supabase Vault (`vault.decrypted_secrets`, name `webhook_secret`) rather than a hardcoded literal — this replaced an earlier version that had the plaintext secret committed directly in a migration file (`20260515000003_send_push_webhooks.sql`), which is why it must never go back to a literal. To rotate:
```bash
NEW_SECRET=$(openssl rand -hex 32)
# 1. Update the Edge Function side FIRST, so there's no window where the
#    trigger sends a new secret to a function still expecting the old one.
supabase secrets set WEBHOOK_SECRET="$NEW_SECRET"
# 2. Update the Vault side (use vault.update_secret if 'webhook_secret'
#    already exists, vault.create_secret only the first time):
supabase db query --linked "select vault.update_secret(
  (select id from vault.secrets where name = 'webhook_secret'),
  '$NEW_SECRET'
);"
unset NEW_SECRET
```
Verify by inserting a test row on Hotel Alpha/Beta (never the real customer hotel) and checking `net._http_response` for a 200 instead of 401:
```sql
select id, status_code, content from net._http_response order by id desc limit 3;
```

---

## 3. Guest PWA → Netlify (already deployed)

To redeploy after changes:
```bash
cd hotel_guest_app
flutter build web --release
# drag-and-drop build/web/ into Netlify, or use:
netlify deploy --prod --dir=build/web
```

Before redeploying, replace `YOUR_ONESIGNAL_APP_ID` in `hotel_guest_app/web/index.html` with the real OneSignal App ID.

---

## 4. Staff App → Mobile Stores

```bash
cd staff_app

# Android
flutter build appbundle --release
# upload build/app/outputs/bundle/release/app-release.aab to Google Play Console

# iOS (Mac required)
flutter build ipa --release
# upload via Xcode → Transporter, or:
# xcrun altool --upload-app -f build/ios/ipa/*.ipa ...
```

For OneSignal on iOS: register an APNs `.p8` key in Apple Developer portal and upload it to OneSignal → Settings → Platforms → Apple iOS.

---

## Quick env reference

| Where | Variable | Source |
|-------|----------|--------|
| Vercel (Admin) | `SUPABASE_URL` | Supabase API settings |
| Vercel (Admin) | `SUPABASE_SERVICE_ROLE_KEY` | Supabase API settings (secret!) |
| Vercel (Admin) | `NEXT_PUBLIC_SUPABASE_URL` | Supabase API settings |
| Vercel (Admin) | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase API settings |
| Supabase secrets | `ONESIGNAL_APP_ID` | OneSignal app overview |
| Supabase secrets | `ONESIGNAL_REST_API_KEY` | OneSignal Settings → Keys |
| Supabase secrets | `WEBHOOK_SECRET` | `openssl rand -hex 32` |
| PWA `web/index.html` | OneSignal `appId` | OneSignal app overview |
