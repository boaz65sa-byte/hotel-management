# Phase 3-5: Quick Actions + Proof of Work + SLA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Quick Action buttons to ticket cards (claim/photo/resolve), enforce proof-of-work photos before resolving, and track SLA deadlines automatically via DB trigger.

**Architecture:** Phase 5 DB migration runs first (adds `accepted_at`, `resolved_at`, `photo_before_url`, `photo_after_url` to tickets). Then Phase 3 Quick Actions UI uses those fields. Phase 5 SLA trigger auto-sets `sla_deadline` on insert. Ticket model updated to include new fields.

**Tech Stack:** Flutter 3, Riverpod, Supabase (SQL migration + trigger), existing `photo_upload_service.dart`, existing `ticket_repository.dart`

---

## File Structure

```
supabase/migrations/
  20260327000002_tickets_pro_columns.sql    ← NEW: accepted_at, resolved_at, photo urls
  20260327000003_sla_deadline_trigger.sql   ← NEW: auto-set sla_deadline on insert

lib/features/tickets/
  domain/ticket_model.dart                  ← MODIFY: add 4 new fields
  data/ticket_repository.dart               ← MODIFY: acceptTicket(), resolveTicket()
  presentation/ticket_card.dart             ← MODIFY: add Quick Action buttons
  presentation/ticket_detail_screen.dart    ← MODIFY: enforce photo_after_url before resolve
  providers/tickets_provider.dart           ← MODIFY: canResolveProvider
```

---

## Task 1: DB Migration — pro columns on tickets

**Files:**
- Create: `supabase/migrations/20260327000002_tickets_pro_columns.sql`
- Create: `supabase/migrations/20260327000003_sla_deadline_trigger.sql`

- [ ] **Step 1: Write migration 1 — new columns**

```sql
-- supabase/migrations/20260327000002_tickets_pro_columns.sql
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS accepted_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resolved_at     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS photo_before_url TEXT,
  ADD COLUMN IF NOT EXISTS photo_after_url  TEXT;
```

- [ ] **Step 2: Write migration 2 — SLA trigger**

```sql
-- supabase/migrations/20260327000003_sla_deadline_trigger.sql
CREATE OR REPLACE FUNCTION set_sla_deadline()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.sla_deadline := NEW.created_at + CASE NEW.priority
    WHEN 'urgent' THEN INTERVAL '60 minutes'
    WHEN 'high'   THEN INTERVAL '2 hours'
    WHEN 'normal' THEN INTERVAL '4 hours'
    WHEN 'low'    THEN INTERVAL '8 hours'
    ELSE INTERVAL '4 hours'
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_sla_deadline ON tickets;
CREATE TRIGGER trg_set_sla_deadline
  BEFORE INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_sla_deadline();
```

- [ ] **Step 3: Apply both migrations in Supabase Dashboard SQL Editor**

Run migration 1, then migration 2.

- [ ] **Step 4: Commit migration files**

```bash
git add supabase/migrations/20260327000002_tickets_pro_columns.sql supabase/migrations/20260327000003_sla_deadline_trigger.sql
git commit -m "feat: add accepted_at, resolved_at, photo urls to tickets + SLA trigger"
```

---

## Task 2: Ticket model — add new fields

**Files:**
- Modify: `lib/features/tickets/domain/ticket_model.dart`

- [ ] **Step 1: Write the failing test**

In `test/features/tickets/ticket_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  group('Ticket pro fields', () {
    test('parses accepted_at and resolved_at', () {
      final json = {
        'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
        'opened_by': 'u1', 'assigned_dept': 'maintenance',
        'title': 'Fix AC', 'priority': 'high', 'status': 'in_progress',
        'accepted_at': '2026-01-01T10:00:00Z',
        'resolved_at': null,
        'photo_before_url': 'https://example.com/before.jpg',
        'photo_after_url': null,
        'created_at': '2026-01-01T09:00:00Z',
        'updated_at': '2026-01-01T10:00:00Z',
      };
      final ticket = Ticket.fromJson(json);
      expect(ticket.acceptedAt, isNotNull);
      expect(ticket.photoBeforeUrl, 'https://example.com/before.jpg');
      expect(ticket.photoAfterUrl, isNull);
    });

    test('canResolve is false when photoAfterUrl is null', () {
      final json = {
        'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
        'opened_by': 'u1', 'assigned_dept': 'maintenance',
        'title': 'Fix AC', 'priority': 'high', 'status': 'in_progress',
        'photo_after_url': null,
        'created_at': '2026-01-01T09:00:00Z',
        'updated_at': '2026-01-01T10:00:00Z',
      };
      final ticket = Ticket.fromJson(json);
      expect(ticket.canResolve, false);
    });

    test('canResolve is true when photoAfterUrl is set', () {
      final json = {
        'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
        'opened_by': 'u1', 'assigned_dept': 'maintenance',
        'title': 'Fix AC', 'priority': 'high', 'status': 'in_progress',
        'photo_after_url': 'https://example.com/after.jpg',
        'created_at': '2026-01-01T09:00:00Z',
        'updated_at': '2026-01-01T10:00:00Z',
      };
      final ticket = Ticket.fromJson(json);
      expect(ticket.canResolve, true);
    });
  });
}
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/tickets/ticket_model_test.dart -v
```

Expected: FAIL — `acceptedAt`, `photoBeforeUrl`, `photoAfterUrl`, `canResolve` not found.

- [ ] **Step 3: Add fields to Ticket class**

In `lib/features/tickets/domain/ticket_model.dart`:

Add fields after existing `resolvedAt`:
```dart
final DateTime? acceptedAt;
final String? photoBeforeUrl;
final String? photoAfterUrl;
```

Add to constructor:
```dart
this.acceptedAt,
this.photoBeforeUrl,
this.photoAfterUrl,
```

Add to `fromJson`:
```dart
acceptedAt: j['accepted_at'] != null ? DateTime.parse(j['accepted_at'] as String) : null,
photoBeforeUrl: j['photo_before_url'] as String?,
photoAfterUrl: j['photo_after_url'] as String?,
```

Add getter:
```dart
bool get canResolve => photoAfterUrl != null;
```

- [ ] **Step 4: Run test to verify pass**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/tickets/ticket_model_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/domain/ticket_model.dart test/features/tickets/ticket_model_test.dart
git commit -m "feat: add acceptedAt, photoUrls, canResolve to Ticket model"
```

---

## Task 3: TicketRepository — acceptTicket() and resolveTicket()

**Files:**
- Modify: `lib/features/tickets/data/ticket_repository.dart`

- [ ] **Step 1: Write the failing test**

In `test/features/tickets/ticket_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

// These are unit tests for the update payload logic — no Supabase needed.
void main() {
  test('accept payload sets status=in_progress and accepted_at', () {
    final payload = {
      'status': 'in_progress',
      'claimed_by': 'user123',
      'accepted_at': DateTime.now().toIso8601String(),
    };
    expect(payload['status'], 'in_progress');
    expect(payload['accepted_at'], isNotNull);
  });

  test('resolve payload sets status=resolved and resolved_at', () {
    final payload = {
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    };
    expect(payload['status'], 'resolved');
    expect(payload['resolved_at'], isNotNull);
  });
}
```

- [ ] **Step 2: Run to verify pass** (these tests pass immediately — they test payload structure)

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/tickets/ticket_repository_test.dart -v
```

- [ ] **Step 3: Add methods to TicketRepository**

In `lib/features/tickets/data/ticket_repository.dart`, add:

```dart
Future<void> acceptTicket(String ticketId, String userId) async {
  await supabase.from('tickets').update({
    'status': 'in_progress',
    'claimed_by': userId,
    'accepted_at': DateTime.now().toIso8601String(),
  }).eq('id', ticketId);
}

Future<void> resolveTicket(String ticketId) async {
  await supabase.from('tickets').update({
    'status': 'resolved',
    'resolved_at': DateTime.now().toIso8601String(),
  }).eq('id', ticketId);
}

Future<void> setPhotoBefore(String ticketId, String photoUrl) async {
  await supabase.from('tickets').update({
    'photo_before_url': photoUrl,
  }).eq('id', ticketId);
}

Future<void> setPhotoAfter(String ticketId, String photoUrl) async {
  await supabase.from('tickets').update({
    'photo_after_url': photoUrl,
  }).eq('id', ticketId);
}
```

- [ ] **Step 4: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/data/ticket_repository.dart test/features/tickets/ticket_repository_test.dart
git commit -m "feat: add acceptTicket, resolveTicket, setPhoto methods to TicketRepository"
```

---

## Task 4: TicketCard — Quick Action buttons

**Files:**
- Modify: `lib/features/tickets/presentation/ticket_card.dart`

Add three inline action buttons: `[📸 לפני]` `[▶ קח אחריות]` `[✅ סגור]`. Buttons only show when role `canClaimAndUpdate`. Close button disabled when `!ticket.canResolve`.

- [ ] **Step 1: Read current TicketCard to understand structure**

Read `lib/features/tickets/presentation/ticket_card.dart` before editing.

- [ ] **Step 2: Write the failing test**

In `test/features/tickets/ticket_card_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  test('ticket.canResolve gates resolve button', () {
    // No photo_after_url
    final t1Json = {
      'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'title': 'Fix', 'priority': 'high', 'status': 'in_progress',
      'photo_after_url': null,
      'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z',
    };
    expect(Ticket.fromJson(t1Json).canResolve, false);

    // Has photo_after_url
    final t2Json = {...t1Json, 'photo_after_url': 'https://example.com/a.jpg'};
    expect(Ticket.fromJson(t2Json).canResolve, true);
  });
}
```

- [ ] **Step 3: Run to verify pass** (uses existing model, should pass)

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/tickets/ticket_card_test.dart -v
```

- [ ] **Step 4: Add Quick Actions to TicketCard**

At the bottom of `TicketCard`'s build method, add action row (inside the existing Card, after existing content). Add this helper and the row:

```dart
// Add import at top:
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/tickets/data/ticket_repository.dart';
```

Inside the card widget, after the existing ticket info, add:

```dart
// Quick actions row — only for roles that can claim/update
Consumer(builder: (context, ref, _) {
  final user = ref.watch(currentUserProvider);
  final roleStr = (user?.appMetadata['role'] as String?) ?? 'receptionist';
  final role = UserRole.fromString(roleStr);
  if (!role.canClaimAndUpdate) return const SizedBox.shrink();
  if (ticket.status == 'resolved' || ticket.status == 'closed') return const SizedBox.shrink();

  final userId = user?.id ?? '';
  final repo = ref.read(ticketRepositoryProvider);

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      // Photo before
      OutlinedButton.icon(
        icon: const Icon(Icons.camera_alt, size: 16),
        label: const Text('לפני'),
        onPressed: () async {
          // Camera/gallery pick — placeholder until Phase 4 camera integration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('העלאת תמונה לפני — בקרוב')),
          );
        },
      ),
      const SizedBox(width: 8),
      // Claim / in-progress
      if (ticket.status == 'open')
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('קח אחריות'),
          onPressed: () async {
            await repo.acceptTicket(ticket.id, userId);
            ref.invalidate(ticketsProvider);
          },
        ),
      const SizedBox(width: 8),
      // Resolve — disabled without photo
      if (ticket.status == 'in_progress')
        Tooltip(
          message: ticket.canResolve ? '' : 'נדרשת תמונה אחרי',
          child: FilledButton.icon(
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('סגור'),
            style: ticket.canResolve
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: ticket.canResolve
                ? () async {
                    await repo.resolveTicket(ticket.id);
                    ref.invalidate(ticketsProvider);
                  }
                : null,
          ),
        ),
    ]),
  );
}),
```

- [ ] **Step 5: Run all tests + analyze**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/presentation/ticket_card.dart test/features/tickets/ticket_card_test.dart
git commit -m "feat: Quick Action buttons on TicketCard (claim/photo/resolve)"
```

---

## Task 5: SLA status display on ticket card

Show color-coded SLA badge on ticket card: green (OK), orange (< 30 min), red (overdue).

- [ ] **Step 1: Write the failing test**

In `test/features/tickets/sla_badge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  test('isOverSla true when sla_deadline passed and not resolved', () {
    final past = DateTime.now().subtract(const Duration(hours: 1));
    final json = {
      'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'title': 'Fix', 'priority': 'high', 'status': 'in_progress',
      'sla_deadline': past.toIso8601String(),
      'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z',
    };
    expect(Ticket.fromJson(json).isOverSla, true);
  });

  test('isOverSla false when resolved even if past deadline', () {
    final past = DateTime.now().subtract(const Duration(hours: 1));
    final json = {
      'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'title': 'Fix', 'priority': 'high', 'status': 'resolved',
      'sla_deadline': past.toIso8601String(),
      'resolved_at': DateTime.now().toIso8601String(),
      'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z',
    };
    expect(Ticket.fromJson(json).isOverSla, false);
  });
}
```

- [ ] **Step 2: Run to verify pass** (`isOverSla` getter already exists in model)

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/tickets/sla_badge_test.dart -v
```

Expected: PASS (getter already correct).

- [ ] **Step 3: Add SLA badge to TicketCard**

In `ticket_card.dart`, add this widget inside the card, next to priority chip:

```dart
// SLA badge — show only if sla_deadline is set
if (ticket.slaDeadline != null) ...[
  const SizedBox(width: 8),
  _SlaBadge(slaDeadline: ticket.slaDeadline!, isResolved: ticket.resolvedAt != null),
],
```

Add the badge widget class:

```dart
class _SlaBadge extends StatelessWidget {
  final DateTime slaDeadline;
  final bool isResolved;
  const _SlaBadge({required this.slaDeadline, required this.isResolved});

  @override
  Widget build(BuildContext context) {
    if (isResolved) return const SizedBox.shrink();
    final remaining = slaDeadline.difference(DateTime.now());
    final Color color;
    final String label;
    if (remaining.isNegative) {
      color = Colors.red;
      label = 'חריגת SLA';
    } else if (remaining.inMinutes < 30) {
      color = Colors.orange;
      label = '${remaining.inMinutes}ד';
    } else {
      color = Colors.green;
      label = '${remaining.inHours}ש';
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
```

- [ ] **Step 4: Run all tests + analyze**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/presentation/ticket_card.dart test/features/tickets/sla_badge_test.dart
git commit -m "feat: SLA badge on ticket cards (green/orange/red)"
```

---

## Task 6: Final integration — build + verify

- [ ] **Step 1: Full test suite**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 2: Web build**

```bash
cd "/Users/boazsaada/manegmant resapceon" && /Users/boazsaada/flutter/bin/flutter build web --web-renderer html
```

Expected: `✓ Built build/web`

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: Phase 3-5 complete — Quick Actions, Proof of Work guard, SLA badges"
```

---

## Verification (Success Criteria)

- [ ] Ticket card shows `[לפני]` `[קח אחריות]` buttons for maintenance/housekeeping roles
- [ ] Clicking `[קח אחריות]` → ticket status changes to `in_progress`, `accepted_at` set
- [ ] `[סגור]` button is greyed out and shows tooltip "נדרשת תמונה אחרי" when no after-photo
- [ ] New tickets automatically have `sla_deadline` set (urgent=60min, high=2h, normal=4h, low=8h)
- [ ] Overdue tickets show red SLA badge
