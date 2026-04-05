# Ticket System — Implementation Plan (Phase 8)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** מערכת קריאות מרכזית לכל מחלקות המלון — פתיחה, שיבוץ, צ'אט, סגירה מלאה ע"י מנהל, היסטוריה.

**Architecture:** מרחיבים את טבלת `tickets` הקיימת בעמודות חדשות + מוסיפים 2 טבלאות (`ticket_assignments`, `ticket_messages`) + מוסיפים תפקיד `hotel_admin` + 2 מסכי Flutter חדשים + עדכון מסכים קיימים.

**Tech Stack:** Supabase (PostgreSQL + RLS), Flutter + Riverpod, Dart

---

## מפת קבצים

### Supabase migrations (חדשים)
- Create: `supabase/migrations/20260405000001_hotel_admin_role.sql`
- Create: `supabase/migrations/20260405000002_tickets_department_ext.sql`
- Create: `supabase/migrations/20260405000003_ticket_assignments.sql`
- Create: `supabase/migrations/20260405000004_ticket_messages.sql`
- Create: `supabase/migrations/20260405000005_requires_media_trigger.sql`
- Create: `supabase/migrations/20260405000006_ticket_close_workflow.sql`

### Flutter (מודל)
- Modify: `lib/features/tickets/domain/ticket_model.dart` — הוספת `assignedTo`, `requiresMedia`, `pendingClose` + מודל `TicketMessage`
- Modify: `lib/features/tickets/data/ticket_repository.dart` — `assignTicket`, `markDone`, `managerClose`, `fetchMessages`, `sendMessage`

### Flutter (מסכים)
- Modify: `lib/features/tickets/presentation/tickets_list_screen.dart` — פילטר מחלקה + badge דחיפות
- Modify: `lib/features/tickets/presentation/new_ticket_screen.dart` — בוחן מחלקה + דחיפות ויזואלית
- Modify: `lib/features/tickets/presentation/ticket_detail_screen.dart` — כפתור "סיימתי" + "סגור" (מנהל)
- Create: `lib/features/tickets/presentation/assign_staff_screen.dart` — שיבוץ עובד עם עומס
- Create: `lib/features/tickets/presentation/ticket_chat_screen.dart` — צ'אט בין-מחלקתי

### Flutter (tests)
- Modify: `test/features/tickets/ticket_repository_test.dart`

---

## Task 1: הוספת `hotel_admin` לאנום

**Files:**
- Create: `supabase/migrations/20260405000001_hotel_admin_role.sql`

- [ ] **Step 1: צור את ה-migration**

```sql
-- supabase/migrations/20260405000001_hotel_admin_role.sql
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'hotel_admin' AFTER 'super_admin';
```

- [ ] **Step 2: החל את ה-migration**

```bash
cd "/Users/boazsaada/manegmant resapceon"
supabase db push
```

Expected: `Applied migration 20260405000001_hotel_admin_role`

- [ ] **Step 3: ודא ב-SQL Editor של Supabase**

```sql
SELECT unnest(enum_range(NULL::user_role));
```

Expected: רואים `hotel_admin` ברשימה.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260405000001_hotel_admin_role.sql
git commit -m "feat: add hotel_admin role to user_role enum"
```

---

## Task 2: הרחבת טבלת `tickets`

**Files:**
- Create: `supabase/migrations/20260405000002_tickets_department_ext.sql`

- [ ] **Step 1: צור את ה-migration**

```sql
-- supabase/migrations/20260405000002_tickets_department_ext.sql

-- assigned_to: שיבוץ ידני ע"י מנהל (שונה מ-claimed_by שהוא self-claim)
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS assigned_to    uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS requires_media boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pending_close  boolean NOT NULL DEFAULT false;

-- ודא ש-assigned_dept מוגבל לערכים נכונים (אם אין כבר CHECK)
ALTER TABLE tickets
  DROP CONSTRAINT IF EXISTS tickets_assigned_dept_check;

ALTER TABLE tickets
  ADD CONSTRAINT tickets_assigned_dept_check
  CHECK (assigned_dept IN ('maintenance','reception','security','housekeeping'));

-- ודא ש-priority מוגבל לערכים נכונים
ALTER TABLE tickets
  DROP CONSTRAINT IF EXISTS tickets_priority_check;

ALTER TABLE tickets
  ADD CONSTRAINT tickets_priority_check
  CHECK (priority IN ('low','normal','urgent','emergency'));
```

- [ ] **Step 2: החל את ה-migration**

```bash
supabase db push
```

Expected: `Applied migration 20260405000002_tickets_department_ext`

- [ ] **Step 3: ודא**

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'tickets'
  AND column_name IN ('assigned_to','requires_media','pending_close');
```

Expected: 3 שורות עם הטיפוסים הנכונים.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260405000002_tickets_department_ext.sql
git commit -m "feat: extend tickets with assigned_to, requires_media, pending_close"
```

---

## Task 3: טבלת `ticket_assignments`

**Files:**
- Create: `supabase/migrations/20260405000003_ticket_assignments.sql`

- [ ] **Step 1: צור את ה-migration**

```sql
-- supabase/migrations/20260405000003_ticket_assignments.sql
CREATE TABLE IF NOT EXISTS ticket_assignments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  assigned_to uuid NOT NULL REFERENCES users(id),
  assigned_by uuid NOT NULL REFERENCES users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  note        text
);

CREATE INDEX idx_ticket_assignments_ticket ON ticket_assignments(ticket_id);

-- RLS
ALTER TABLE ticket_assignments ENABLE ROW LEVEL SECURITY;

-- כל אחד מהמלון יכול לראות
CREATE POLICY "hotel members can view assignments"
  ON ticket_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

-- רק מנהלים יכולים לשבץ
CREATE POLICY "managers can insert assignments"
  ON ticket_assignments FOR INSERT
  WITH CHECK (
    (auth.jwt()->>'role') IN (
      'super_admin','hotel_admin',
      'reception_manager','maintenance_manager',
      'housekeeping_manager','security_manager',
      'deputy_reception'
    )
  );
```

- [ ] **Step 2: החל את ה-migration**

```bash
supabase db push
```

Expected: `Applied migration 20260405000003_ticket_assignments`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260405000003_ticket_assignments.sql
git commit -m "feat: add ticket_assignments table with RLS"
```

---

## Task 4: טבלת `ticket_messages` (צ'אט)

**Files:**
- Create: `supabase/migrations/20260405000004_ticket_messages.sql`

- [ ] **Step 1: צור את ה-migration**

```sql
-- supabase/migrations/20260405000004_ticket_messages.sql
CREATE TABLE IF NOT EXISTS ticket_messages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id  uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  sender_id  uuid NOT NULL REFERENCES users(id),
  body       text NOT NULL CHECK (char_length(body) > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ticket_messages_ticket ON ticket_messages(ticket_id);
CREATE INDEX idx_ticket_messages_created ON ticket_messages(created_at);

-- RLS
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;

-- כל אחד מהמלון יכול לקרוא ולשלוח
CREATE POLICY "hotel members can read messages"
  ON ticket_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

CREATE POLICY "hotel members can send messages"
  ON ticket_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

-- Enable Realtime for ticket_messages
ALTER PUBLICATION supabase_realtime ADD TABLE ticket_messages;
```

- [ ] **Step 2: החל את ה-migration**

```bash
supabase db push
```

Expected: `Applied migration 20260405000004_ticket_messages`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260405000004_ticket_messages.sql
git commit -m "feat: add ticket_messages table + realtime"
```

---

## Task 5: טריגר `requires_media` + workflow סגירה

**Files:**
- Create: `supabase/migrations/20260405000005_requires_media_trigger.sql`
- Create: `supabase/migrations/20260405000006_ticket_close_workflow.sql`

- [ ] **Step 1: צור migration לטריגר requires_media**

```sql
-- supabase/migrations/20260405000005_requires_media_trigger.sql

-- urgent + emergency → requires_media = true אוטומטי
CREATE OR REPLACE FUNCTION set_requires_media()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.priority IN ('urgent','emergency') THEN
    NEW.requires_media = true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_requires_media ON tickets;
CREATE TRIGGER trg_requires_media
  BEFORE INSERT OR UPDATE OF priority ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_requires_media();
```

- [ ] **Step 2: צור migration לזרימת סגירה**

```sql
-- supabase/migrations/20260405000006_ticket_close_workflow.sql

-- RPC: עובד מסמן "סיימתי" → pending_close = true
CREATE OR REPLACE FUNCTION mark_ticket_done(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- ודא שיש תמונת "אחרי" אם requires_media
  IF EXISTS (
    SELECT 1 FROM tickets
    WHERE id = p_ticket_id
      AND requires_media = true
      AND photo_after_url IS NULL
  ) THEN
    RAISE EXCEPTION 'requires_after_photo';
  END IF;

  UPDATE tickets
  SET pending_close = true, updated_at = now()
  WHERE id = p_ticket_id
    AND (claimed_by = auth.uid() OR assigned_to = auth.uid());
END;
$$;

-- RPC: מנהל סוגר סופית
CREATE OR REPLACE FUNCTION manager_close_ticket(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_role text;
BEGIN
  v_role := auth.jwt()->>'role';

  IF v_role NOT IN (
    'super_admin','hotel_admin',
    'reception_manager','maintenance_manager',
    'housekeeping_manager','security_manager'
  ) THEN
    RAISE EXCEPTION 'insufficient_role';
  END IF;

  UPDATE tickets
  SET status = 'resolved',
      resolved_at = now(),
      pending_close = false,
      updated_at = now()
  WHERE id = p_ticket_id;
END;
$$;
```

- [ ] **Step 3: החל את שני ה-migrations**

```bash
supabase db push
```

Expected: שניהם applied.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260405000005_requires_media_trigger.sql \
        supabase/migrations/20260405000006_ticket_close_workflow.sql
git commit -m "feat: requires_media trigger + mark_done + manager_close RPCs"
```

---

## Task 6: עדכון `TicketModel` + `TicketRepository`

**Files:**
- Modify: `lib/features/tickets/domain/ticket_model.dart`
- Modify: `lib/features/tickets/data/ticket_repository.dart`

- [ ] **Step 1: כתוב בדיקות כושלות**

ב-`test/features/tickets/ticket_repository_test.dart` הוסף:

```dart
test('Ticket.fromJson maps assignedTo and requiresMedia', () {
  final json = {
    'id': 'tid', 'hotel_id': 'hid', 'room_id': 'rid',
    'opened_by': 'uid', 'assigned_dept': 'maintenance',
    'claimed_by': null, 'assigned_to': 'worker-uuid',
    'title': 'Test', 'description': null,
    'priority': 'emergency', 'status': 'open',
    'resolution_type': null, 'requires_media': true,
    'pending_close': false,
    'sla_deadline': null, 'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'resolved_at': null, 'accepted_at': null,
    'photo_before_url': null, 'photo_after_url': null,
    'room': null, 'opener': null, 'claimer': null, 'assignee': null,
  };
  final ticket = Ticket.fromJson(json);
  expect(ticket.assignedTo, equals('worker-uuid'));
  expect(ticket.requiresMedia, isTrue);
  expect(ticket.pendingClose, isFalse);
});

test('TicketMessage.fromJson parses correctly', () {
  final json = {
    'id': 'mid', 'ticket_id': 'tid', 'sender_id': 'uid',
    'body': 'הגעתי לחדר', 'created_at': '2026-01-01T10:00:00Z',
    'sender': {'full_name': 'משה לוי'},
  };
  final msg = TicketMessage.fromJson(json);
  expect(msg.body, equals('הגעתי לחדר'));
  expect(msg.senderName, equals('משה לוי'));
});
```

- [ ] **Step 2: הרץ לוודא שנכשל**

```bash
~/flutter/bin/flutter test test/features/tickets/ticket_repository_test.dart
```

Expected: FAIL — `assignedTo`, `TicketMessage` לא קיימים.

- [ ] **Step 3: עדכן `ticket_model.dart`**

```dart
// lib/features/tickets/domain/ticket_model.dart
class Ticket {
  final String id;
  final String hotelId;
  final String roomId;
  final String openedBy;
  final String assignedDept;
  final String? claimedBy;
  final String? assignedTo;      // NEW: שיבוץ ידני ע"י מנהל
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? resolutionType;
  final DateTime? slaDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? acceptedAt;
  final String? photoBeforeUrl;
  final String? photoAfterUrl;
  final bool requiresMedia;      // NEW
  final bool pendingClose;       // NEW

  // Joined fields
  final String? roomNumber;
  final String? openerName;
  final String? claimerName;
  final String? assigneeName;    // NEW

  const Ticket({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.openedBy,
    required this.assignedDept,
    this.claimedBy,
    this.assignedTo,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.resolutionType,
    this.slaDeadline,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.acceptedAt,
    this.photoBeforeUrl,
    this.photoAfterUrl,
    this.requiresMedia = false,
    this.pendingClose = false,
    this.roomNumber,
    this.openerName,
    this.claimerName,
    this.assigneeName,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
    id: j['id'] as String,
    hotelId: j['hotel_id'] as String,
    roomId: j['room_id'] as String,
    openedBy: j['opened_by'] as String,
    assignedDept: j['assigned_dept'] as String,
    claimedBy: j['claimed_by'] as String?,
    assignedTo: j['assigned_to'] as String?,
    title: j['title'] as String,
    description: j['description'] as String?,
    priority: j['priority'] as String,
    status: j['status'] as String,
    resolutionType: j['resolution_type'] as String?,
    slaDeadline: j['sla_deadline'] != null ? DateTime.parse(j['sla_deadline'] as String) : null,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    resolvedAt: j['resolved_at'] != null ? DateTime.parse(j['resolved_at'] as String) : null,
    acceptedAt: j['accepted_at'] != null ? DateTime.parse(j['accepted_at'] as String) : null,
    photoBeforeUrl: j['photo_before_url'] as String?,
    photoAfterUrl: j['photo_after_url'] as String?,
    requiresMedia: j['requires_media'] as bool? ?? false,
    pendingClose: j['pending_close'] as bool? ?? false,
    roomNumber: j['room'] != null ? (j['room'] as Map<String, dynamic>)['room_number'] as String? : null,
    openerName: j['opener'] != null ? (j['opener'] as Map<String, dynamic>)['full_name'] as String? : null,
    claimerName: j['claimer'] != null ? (j['claimer'] as Map<String, dynamic>)['full_name'] as String? : null,
    assigneeName: j['assignee'] != null ? (j['assignee'] as Map<String, dynamic>)['full_name'] as String? : null,
  );

  bool get isOverSla =>
    slaDeadline != null && DateTime.now().isAfter(slaDeadline!) && resolvedAt == null;

  bool get canResolve => !requiresMedia || photoAfterUrl != null;
}

// NEW: מודל הודעת צ'אט
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final String? senderName;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.senderName,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
    id: j['id'] as String,
    ticketId: j['ticket_id'] as String,
    senderId: j['sender_id'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    senderName: j['sender'] != null
        ? (j['sender'] as Map<String, dynamic>)['full_name'] as String?
        : null,
  );
}

// שאר המחלקות הקיימות (TicketUpdate, TicketPhoto) — ללא שינוי
```

- [ ] **Step 4: עדכן `_select` ב-`ticket_repository.dart`**

```dart
static const _select = '''
  id, hotel_id, room_id, opened_by, assigned_dept, claimed_by,
  assigned_to, title, description, priority, status, resolution_type,
  sla_deadline, created_at, updated_at, resolved_at,
  accepted_at, photo_before_url, photo_after_url,
  requires_media, pending_close,
  room:rooms(room_number, floor),
  opener:users!tickets_opened_by_fkey(full_name),
  claimer:users!tickets_claimed_by_fkey(full_name),
  assignee:users!tickets_assigned_to_fkey(full_name)
''';
```

- [ ] **Step 5: הוסף מתודות חדשות ל-`ticket_repository.dart`**

```dart
/// שיבוץ עובד ע"י מנהל
Future<void> assignTicket({
  required String ticketId,
  required String assignedTo,
  required String assignedBy,
  String? note,
}) async {
  await supabase.from('tickets').update({
    'assigned_to': assignedTo,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', ticketId);
  await supabase.from('ticket_assignments').insert({
    'ticket_id': ticketId,
    'assigned_to': assignedTo,
    'assigned_by': assignedBy,
    if (note != null) 'note': note,
  });
}

/// עובד מסמן "סיימתי"
Future<void> markDone(String ticketId) async {
  await supabase.rpc('mark_ticket_done', params: {'p_ticket_id': ticketId});
}

/// מנהל סוגר סופית
Future<void> managerClose(String ticketId) async {
  await supabase.rpc('manager_close_ticket', params: {'p_ticket_id': ticketId});
}

/// שליפת הודעות צ'אט
Future<List<TicketMessage>> fetchMessages(String ticketId) async {
  final res = await supabase
    .from('ticket_messages')
    .select('*, sender:users(full_name)')
    .eq('ticket_id', ticketId)
    .order('created_at');
  return (res as List)
    .map((j) => TicketMessage.fromJson(j as Map<String, dynamic>))
    .toList();
}

/// שליחת הודעת צ'אט
Future<void> sendMessage({
  required String ticketId,
  required String senderId,
  required String body,
}) async {
  await supabase.from('ticket_messages').insert({
    'ticket_id': ticketId,
    'sender_id': senderId,
    'body': body,
  });
}

/// Realtime stream להודעות צ'אט
Stream<List<Map<String, dynamic>>> watchMessages(String ticketId) {
  return supabase
    .from('ticket_messages')
    .stream(primaryKey: ['id'])
    .eq('ticket_id', ticketId)
    .order('created_at');
}

/// שליפת עובדים לשיבוץ לפי מחלקה
Future<List<Map<String, dynamic>>> fetchDeptStaff(String dept) async {
  final deptRoles = {
    'maintenance': ['maintenance_manager','maintenance_tech','repairman'],
    'reception':   ['reception_manager','deputy_reception','receptionist'],
    'security':    ['security_manager','security_guard'],
    'housekeeping':['housekeeping_manager'],
  };
  final roles = deptRoles[dept] ?? [];
  final res = await supabase
    .from('users')
    .select('id, full_name, role, is_active')
    .inFilter('role', roles)
    .eq('is_active', true);
  return (res as List).cast<Map<String, dynamic>>();
}
```

- [ ] **Step 6: הרץ tests**

```bash
~/flutter/bin/flutter test test/features/tickets/ticket_repository_test.dart
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/tickets/domain/ticket_model.dart \
        lib/features/tickets/data/ticket_repository.dart \
        test/features/tickets/ticket_repository_test.dart
git commit -m "feat: extend Ticket model + repository (assignedTo, requiresMedia, pendingClose, messages)"
```

---

## Task 7: מסך חדש — `AssignStaffScreen`

**Files:**
- Create: `lib/features/tickets/presentation/assign_staff_screen.dart`

- [ ] **Step 1: צור את הקובץ**

```dart
// lib/features/tickets/presentation/assign_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/data/ticket_repository.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

class AssignStaffScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  const AssignStaffScreen({super.key, required this.ticket});

  @override
  ConsumerState<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends ConsumerState<AssignStaffScreen> {
  String? _selectedId;
  String? _selectedName;
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final repo = ref.read(ticketRepoProvider);
    final staff = await repo.fetchDeptStaff(widget.ticket.assignedDept);
    setState(() => _staff = staff);
  }

  Future<void> _assign() async {
    if (_selectedId == null) return;
    setState(() => _loading = true);
    try {
      final me = ref.read(authRepositoryProvider).currentUser!.id;
      final repo = ref.read(ticketRepoProvider);
      await repo.assignTicket(
        ticketId: widget.ticket.id,
        assignedTo: _selectedId!,
        assignedBy: me,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('שבץ מטפל', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('#${widget.ticket.id.substring(0,8)} · ${widget.ticket.title}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _staff.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'עובדים זמינים — ${widget.ticket.assignedDept}',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: cs.onSurface.withOpacity(0.5),
                            letterSpacing: 0.06,
                          ),
                        ),
                      );
                    }
                    final s = _staff[i - 1];
                    final id = s['id'] as String;
                    final name = s['full_name'] as String;
                    final role = s['role'] as String;
                    final selected = _selectedId == id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedId = id;
                        _selectedName = name;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? cs.primaryContainer : cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? cs.primary : cs.outline,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: cs.primary.withOpacity(0.15),
                              child: Text(
                                name.characters.first,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_circle, color: cs.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          if (_selectedId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  hintText: 'הערה לשיבוץ (אופציונלי)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedId == null || _loading ? null : _assign,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _selectedName != null ? 'שבץ את $_selectedName ←' : 'בחר עובד',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: הוסף route ב-router.dart**

ב-`lib/navigation/router.dart` הוסף:

```dart
GoRoute(
  path: '/tickets/:id/assign',
  builder: (context, state) {
    final ticket = state.extra as Ticket;
    return AssignStaffScreen(ticket: ticket);
  },
),
```

- [ ] **Step 3: ודא שה-app מקמפל**

```bash
~/flutter/bin/flutter analyze
```

Expected: no errors (info בלבד).

- [ ] **Step 4: Commit**

```bash
git add lib/features/tickets/presentation/assign_staff_screen.dart \
        lib/navigation/router.dart
git commit -m "feat: AssignStaffScreen with department staff list"
```

---

## Task 8: מסך חדש — `TicketChatScreen`

**Files:**
- Create: `lib/features/tickets/presentation/ticket_chat_screen.dart`
- Create: `lib/features/tickets/providers/ticket_messages_provider.dart`

- [ ] **Step 1: צור provider להודעות**

```dart
// lib/features/tickets/providers/ticket_messages_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/tickets/data/ticket_repository.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

final ticketMessagesProvider = StreamProvider.family<
    List<TicketMessage>, String>((ref, ticketId) {
  final repo = ref.read(ticketRepoProvider);
  return repo.watchMessages(ticketId).map(
    (rows) => rows
        .map((j) => TicketMessage.fromJson(j))
        .toList(),
  );
});
```

- [ ] **Step 2: צור את מסך הצ'אט**

```dart
// lib/features/tickets/presentation/ticket_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/data/ticket_repository.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';
import 'package:hotel_app/features/tickets/providers/ticket_messages_provider.dart';

class TicketChatScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  const TicketChatScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    final me = ref.read(authRepositoryProvider).currentUser?.id;
    if (me == null) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ref.read(ticketRepoProvider).sendMessage(
        ticketId: widget.ticket.id,
        senderId: me,
        body: body,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = ref.watch(authRepositoryProvider).currentUser?.id;
    final msgsAsync = ref.watch(ticketMessagesProvider(widget.ticket.id));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💬 ${widget.ticket.title}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text('${widget.ticket.assignedDept} · #${widget.ticket.id.substring(0,8)}',
              style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('שגיאה: $e')),
              data: (messages) => messages.isEmpty
                ? Center(
                    child: Text('אין הודעות עדיין',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.4))))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == me;
                      return Align(
                        alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Column(
                            crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3, right: 4),
                                  child: Text(
                                    msg.senderName ?? 'עובד',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: cs.primary),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: isMe ? cs.primary : cs.surfaceVariant,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isMe ? cs.onPrimary : cs.onSurface),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '${msg.createdAt.hour.toString().padLeft(2,'0')}:${msg.createdAt.minute.toString().padLeft(2,'0')}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: cs.onSurface.withOpacity(0.4)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'הקלד הודעה...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: cs.outline)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: cs.surfaceVariant,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: הוסף route**

ב-`lib/navigation/router.dart` הוסף:

```dart
GoRoute(
  path: '/tickets/:id/chat',
  builder: (context, state) {
    final ticket = state.extra as Ticket;
    return TicketChatScreen(ticket: ticket);
  },
),
```

- [ ] **Step 4: ודא שה-app מקמפל**

```bash
~/flutter/bin/flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/presentation/ticket_chat_screen.dart \
        lib/features/tickets/providers/ticket_messages_provider.dart \
        lib/navigation/router.dart
git commit -m "feat: TicketChatScreen with realtime messages"
```

---

## Task 9: עדכון `TicketDetailScreen` — כפתורי "סיימתי" + "סגור" + ניווט

**Files:**
- Modify: `lib/features/tickets/presentation/ticket_detail_screen.dart`

- [ ] **Step 1: קרא את הקובץ הקיים**

```bash
cat lib/features/tickets/presentation/ticket_detail_screen.dart
```

- [ ] **Step 2: הוסף את כפתורי הפעולה החדשים**

בסוף ה-`build()`, במקום (או בנוסף ל-) כפתורי הסגירה הקיימים הוסף:

```dart
// בתחתית TicketDetailScreen — Row של כפתורים
Row(
  children: [
    // כפתור צ'אט
    Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline, size: 16),
        label: const Text('צ\'אט'),
        onPressed: () => context.push(
          '/tickets/${ticket.id}/chat',
          extra: ticket,
        ),
      ),
    ),
    const SizedBox(width: 8),
    // כפתור שיבוץ (למנהלים)
    if (_isManager) Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: const Text('שבץ'),
        onPressed: () => context.push(
          '/tickets/${ticket.id}/assign',
          extra: ticket,
        ),
      ),
    ),
    const SizedBox(width: 8),
    // כפתור "סיימתי" (לעובד המשובץ)
    if (_isAssignee && !ticket.pendingClose) Expanded(
      child: FilledButton.icon(
        icon: const Icon(Icons.check, size: 16),
        label: const Text('סיימתי'),
        onPressed: _canMarkDone ? _markDone : null,
        style: FilledButton.styleFrom(backgroundColor: Colors.green),
      ),
    ),
    // כפתור "סגור" (למנהל בלבד)
    if (_isManager && ticket.pendingClose) Expanded(
      child: FilledButton.icon(
        icon: const Icon(Icons.verified, size: 16),
        label: const Text('סגור קריאה'),
        onPressed: _managerClose,
        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade800),
      ),
    ),
  ],
),
```

בחלק ה-state של המסך הוסף:

```dart
bool get _isManager {
  final role = ref.read(authRepositoryProvider).role;
  return ['super_admin','hotel_admin','reception_manager',
          'maintenance_manager','housekeeping_manager','security_manager']
      .contains(role);
}

bool get _isAssignee {
  final me = ref.read(authRepositoryProvider).currentUser?.id;
  return ticket.assignedTo == me || ticket.claimedBy == me;
}

bool get _canMarkDone =>
    !ticket.requiresMedia || ticket.photoAfterUrl != null;

Future<void> _markDone() async {
  try {
    await ref.read(ticketRepoProvider).markDone(ticket.id);
    ref.invalidate(ticketDetailProvider(ticket.id));
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().contains('requires_after_photo')
          ? 'נדרשת תמונת "אחרי" לפני הסגירה'
          : e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _managerClose() async {
  await ref.read(ticketRepoProvider).managerClose(ticket.id);
  ref.invalidate(ticketDetailProvider(ticket.id));
}
```

- [ ] **Step 3: ודא שה-app מקמפל**

```bash
~/flutter/bin/flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tickets/presentation/ticket_detail_screen.dart
git commit -m "feat: ticket detail — mark done (employee) + manager close + chat/assign buttons"
```

---

## Task 10: עדכון `TicketListScreen` — פילטר מחלקה + badge דחיפות

**Files:**
- Modify: `lib/features/tickets/presentation/tickets_list_screen.dart`

- [ ] **Step 1: קרא את הקובץ הקיים**

```bash
cat lib/features/tickets/presentation/tickets_list_screen.dart
```

- [ ] **Step 2: הוסף פילטר מחלקה בראש המסך**

```dart
// הוסף state
String? _deptFilter; // null = הכל
String? _priorityFilter;

// הוסף tabs/chips לסינון מחלקה
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: Row(
    children: [
      _deptChip(null, 'הכל', Icons.grid_view),
      _deptChip('maintenance', 'אחזקה', Icons.build),
      _deptChip('reception', 'קבלה', Icons.desk),
      _deptChip('security', 'ביטחון', Icons.security),
      _deptChip('housekeeping', 'משק בית', Icons.cleaning_services),
    ],
  ),
),

// Widget עזר
Widget _deptChip(String? dept, String label, IconData icon) {
  final selected = _deptFilter == dept;
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 14),
      label: Text(label),
      onSelected: (_) => setState(() => _deptFilter = dept),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
    ),
  );
}
```

- [ ] **Step 3: עדכן את הsort — חירום → דחוף → רגיל → נמוך**

```dart
// בפונקציה שמחזירה רשימת tickets
final priorityOrder = {'emergency': 0, 'urgent': 1, 'normal': 2, 'low': 3};

tickets.sort((a, b) =>
  (priorityOrder[a.priority] ?? 2)
      .compareTo(priorityOrder[b.priority] ?? 2));
```

- [ ] **Step 4: הוסף badge דחיפות ל-TicketCard**

ב-`lib/features/tickets/presentation/ticket_card.dart`, עדכן את ה-badge:

```dart
Color _priorityColor(String priority) => switch (priority) {
  'emergency' => Colors.red.shade700,
  'urgent'    => Colors.orange.shade600,
  'normal'    => Colors.grey.shade500,
  'low'       => Colors.green.shade600,
  _           => Colors.grey,
};

String _priorityLabel(String priority) => switch (priority) {
  'emergency' => '🔴 חירום',
  'urgent'    => '🟠 דחוף',
  'normal'    => '⚪ רגיל',
  'low'       => '🟢 נמוך',
  _           => priority,
};
```

- [ ] **Step 5: הרץ tests**

```bash
~/flutter/bin/flutter test
```

Expected: כל ה-tests עוברים.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/presentation/tickets_list_screen.dart \
        lib/features/tickets/presentation/ticket_card.dart
git commit -m "feat: ticket list — department filter + priority sort + badges"
```

---

## Task 11: בדיקת קצה לקצה

- [ ] **Step 1: הרץ את האפליקציה**

```bash
cd "/Users/boazsaada/manegmant resapceon"
~/flutter/bin/flutter run
```

- [ ] **Step 2: התחבר כ-manager@hotel.com / Manager1234! ובדוק:**
  - [ ] רשימת קריאות מציגה badges נכונות
  - [ ] פילטר מחלקה עובד
  - [ ] לחיצה על קריאה → מסך פרטים עם כפתורי שיבוץ + צ'אט
  - [ ] שיבוץ עובד → מסך AssignStaffScreen
  - [ ] לחיצה על צ'אט → TicketChatScreen

- [ ] **Step 3: התחבר כ-tech@hotel.com / Tech1234! ובדוק:**
  - [ ] רואה קריאות שמשובצות אליו
  - [ ] לחיצה "סיימתי" — אם emergency ואין תמונת אחרי → שגיאה
  - [ ] אחרי הוספת תמונת אחרי → "סיימתי" עובד

- [ ] **Step 4: חזור ל-manager וסגור קריאה בסטטוס pending_close**

- [ ] **Step 5: הרץ test suite מלא**

```bash
~/flutter/bin/flutter test
```

Expected: כל ה-tests עוברים.

- [ ] **Step 6: Commit סופי**

```bash
git add .
git commit -m "feat: Phase 8 — complete ticket system with departments, assignment, chat, manager close"
```

---

## סיכום

| Task | מה בונה | זמן משוער |
|------|---------|-----------|
| 1 | hotel_admin role | 5 דק' |
| 2 | tickets ext (assigned_to, requires_media, pending_close) | 10 דק' |
| 3 | ticket_assignments table | 10 דק' |
| 4 | ticket_messages + realtime | 10 דק' |
| 5 | requires_media trigger + RPCs | 15 דק' |
| 6 | Flutter model + repository | 20 דק' |
| 7 | AssignStaffScreen | 20 דק' |
| 8 | TicketChatScreen + provider | 20 דק' |
| 9 | TicketDetailScreen updates | 15 דק' |
| 10 | TicketListScreen filter + sort | 15 דק' |
| 11 | E2E testing | 20 דק' |
