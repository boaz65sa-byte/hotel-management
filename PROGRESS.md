# Hotel Management App - Progress Tracker

## Current Status
**Phase**: Brainstorming - Clarifying Questions (Q9 of 9 - waiting for answer)
**Date**: 2026-03-22
**Next Step**: Propose 2-3 architectural approaches after Q9 answer

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
| 1 | docs/superpowers/plans/2026-03-22-plan-1-supabase-backend.md | Ready |
| 2 | docs/superpowers/plans/2026-03-22-plan-2-flutter-foundation.md | Ready |
| 3 | docs/superpowers/plans/2026-03-22-plan-3-flutter-tickets.md | Ready |
| 4 | docs/superpowers/plans/2026-03-22-plan-4-flutter-rooms-analytics-users.md | Ready |
| 5 | docs/superpowers/plans/2026-03-22-plan-5-nextjs-super-admin.md | Ready |

**Start with Plan 1. Each plan depends on the previous.**

## Future Features (V2)
- WhatsApp Business API notifications
- Optima system integration
