# Hotel Management App - Progress Tracker

## Current Status
**Phase**: Implementation - Plan 2 Complete, Starting Plan 3
**Date**: 2026-03-23
**Next Step**: Plan 3 - Flutter Tickets (ticket models, screens, photos, approvals)

---

## Decisions Made

| Topic | Decision |
|-------|----------|
| Platform type | Multi-tenant - starts with 1 hotel, supports chains |
| Languages | Full multilingual: Hebrew (RTL) + English + Arabic + more |
| Offline mode | Full offline - open/update tickets, auto-sync when back online |
| Optima integration | Version 2 - V1 is standalone |
| Notifications | V1: Push in-app only / V2: WhatsApp Business API |
| Mobile app | Flutter (Android + iOS + Web) |
| Room setup | Manual entry + CSV/Excel import (both) |
| Photos per ticket | Unlimited |
| Theming | White-label: logo + color palette per hotel/chain (Super Admin) |

## Admin Levels

| Level | Who | What |
|-------|-----|-------|
| Super Admin | App owner (Boaz) | Manage hotels, tenants, users, theming, global data |
| Hotel Manager | CEO / Reception Manager | Manage rooms, tickets, reports - inside the app |

---

## App Description
Hotel service ticket management system:
1. Reception opens a ticket for a room issue
2. Ticket goes to maintenance
3. Maintenance handles, photographs, updates
4. Reception gets confirmation: Fixed / Room on hold / Room closed

## 10 Roles
1. CEO (מנכ"ל)
2. Reception Manager (מנהל קבלה)
3. Maintenance Manager (מנהל אחזקה)
4. Housekeeping Manager (מנהל משק)
5. Security Manager (מנהל ביטחון)
6. Deputy Reception (סגן קבלה)
7. Receptionist (פקיד קבלה)
8. Security Guard (קב"ט)
9. Maintenance Tech (אחזקה)
10. Repairman (תיקונציק)

## Known Features
- Mobile app (Flutter) + Web
- Full offline + auto sync
- Multi-tenant (hotel + chains)
- Super Admin panel (app owner only)
- In-app hotel management panel (per hotel)
- Service ticket workflow
- White-label theming
- Unlimited photos per ticket
- Reports & analytics (level TBD - Q9 pending)
- Future: WhatsApp Business API
- Future: Optima integration

---

## Brainstorming Checklist
- [x] 1. Explore project context
- [x] 2. Offer visual companion
- [x] 3. Clarifying questions (all 9 answered)
- [x] 4. Propose 2-3 architectural approaches (chose A: Supabase monolith)
- [x] 5. Present design sections + get approval
- [x] 6. Write spec doc → docs/superpowers/specs/2026-03-22-hotel-management-design.md
- [x] 7. Spec review loop (3 rounds, all issues fixed)
- [x] 8. User reviewed spec
- [x] 9. Implementation plans written (5 plans)

## Implementation Plans
| Plan | File | Status |
|------|------|--------|
| 1 | docs/superpowers/plans/2026-03-22-plan-1-supabase-backend.md | ✅ Done |
| 2 | docs/superpowers/plans/2026-03-22-plan-2-flutter-foundation.md | ✅ Done |
| 3 | docs/superpowers/plans/2026-03-22-plan-3-flutter-tickets.md | 🔄 Next |
| 4 | docs/superpowers/plans/2026-03-22-plan-4-flutter-rooms-analytics-users.md | Ready |
| 5 | docs/superpowers/plans/2026-03-22-plan-5-nextjs-super-admin.md | Ready |

**Plan 2 complete. Start Plan 3 next.**

## Environment
- **Supabase project**: vetwlonyzyzvhrtdwbzj (account: boaz65sa@icloud.com)
- **GitHub**: https://github.com/boaz65sa-byte/hotel-management
- **Flutter**: /Users/boazsaada/flutter/bin/flutter (v3.24.5)
- **Flutter PATH**: added to ~/.zshrc
- **Supabase CLI**: linked, push with `supabase db push --include-all`

## Pending Manual Actions
- [ ] Supabase Dashboard → Authentication → Hooks → Custom Access Token → select `custom_jwt_claims`
- [ ] Create test auth users in Supabase dashboard for testing login

## Plan 1 - Completed Migrations (on Supabase: vetwlonyzyzvhrtdwbzj)
- ✅ 20260322000001 - hotels table
- ✅ 20260322000002 - users table + is_primary_contact
- ✅ 20260322000003 - rooms table
- ✅ 20260322000004 - tickets table
- ✅ 20260322000005 - ticket_updates (append-only)
- ✅ 20260322000006 - ticket_photos (append-only)
- ✅ 20260322000007 - ticket_approvals + view
- ✅ 20260322000008 - RLS policies (all 7 tables)
- ✅ 20260322000009 - custom JWT claims function
- ✅ 20260322000010 - storage bucket (ticket-photos, private)
- ✅ 20260322000011 - seed test data (Hotel Alpha + Beta)
- ✅ 20260322000012 - RPCs (claim_ticket, create_approval_request, check_and_close_ticket)
- ✅ 20260322000013 - tickets trigger repair
- ✅ Edge Function: export-excel (deployed)
- ✅ GitHub: https://github.com/boaz65sa-byte/hotel-management

## Plan 2 - Completed Flutter Foundation
- ✅ Task 1: Flutter project setup (pubspec.yaml, 170 deps, directory structure)
- ✅ Task 2: i18n (Hebrew/English/Arabic ARB files, flutter gen-l10n, locale_provider)
- ✅ Task 3: Supabase client (dotenv init) + HotelTheme engine (fromJson/toThemeData)
- ✅ Task 4: Connectivity service (StreamProvider) + OfflineBanner widget
- ✅ Task 5: SQLite local cache (4 tables) + SyncQueue (enqueue/pending/remove)
- ✅ Task 6: AuthRepository (signIn/signOut/hotelId/role) + LoginScreen + auth_state providers
- ✅ Task 7: GoRouter with auth guard redirect + HotelApp + main.dart init
- ✅ Task 8: SessionTimeoutService (resetTimer/dispose) + fetchSessionTimeoutMinutes
- ✅ All 11 tests passing
- ✅ flutter analyze: no issues

## Added in Plan 1 (beyond original spec)
- is_primary_contact on users: one primary contact per hotel (support + billing representative)

## Future Features (V2)
- WhatsApp Business API notifications
- Optima system integration
