# Hotel Management App - Plan 3: Flutter Tickets Feature

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete ticket lifecycle in Flutter — open ticket, department queue, ticket detail with timeline, claiming, status updates, photo capture/upload (with offline queue), approval workflow UI, and realtime updates.

**Architecture:** Riverpod for state, Repository pattern for Supabase calls. Offline writes go to SyncQueue (Plan 2). Realtime uses Supabase channels. Permissions checked via role from JWT claim.

**Tech Stack:** Flutter, flutter_riverpod, supabase_flutter, image_picker, sqflite (sync queue from Plan 2)

---

## Prerequisites

- Plan 1 (Supabase Backend) complete
- Plan 2 (Flutter Foundation) complete — auth, offline queue, routing all working

---

## File Structure

```
lib/features/tickets/
├── data/
│   ├── ticket_repository.dart         # Supabase CRUD + realtime
│   └── ticket_local_cache.dart        # SQLite read/write for cached tickets
├── domain/
│   ├── ticket_model.dart              # Ticket + TicketUpdate + TicketPhoto
│   ├── ticket_status.dart             # Enums and permission logic
│   └── routing_rules.dart             # Which dept can route where
├── presentation/
│   ├── tickets_list_screen.dart       # List with filters
│   ├── ticket_detail_screen.dart      # Timeline + action buttons
│   ├── new_ticket_screen.dart         # Open ticket form
│   ├── ticket_card.dart               # List item widget
│   ├── timeline_entry.dart            # Single timeline event widget
│   └── approval_sheet.dart            # Bottom sheet for approve/reject
└── providers/
    ├── tickets_provider.dart          # List + filters state
    └── ticket_detail_provider.dart    # Single ticket + realtime
```

---

## Task 1: Domain Models

**Files:**
- Create: `lib/features/tickets/domain/ticket_model.dart`
- Create: `lib/features/tickets/domain/ticket_status.dart`
- Create: `lib/features/tickets/domain/routing_rules.dart`

- [ ] **Step 1: Write ticket models**

```dart
// lib/features/tickets/domain/ticket_model.dart
class Ticket {
  final String id;
  final String hotelId;
  final String roomId;
  final String openedBy;
  final String assignedDept;
  final String? claimedBy;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? resolutionType;
  final DateTime? slaDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  // Joined fields
  final String? roomNumber;
  final String? openerName;
  final String? claimerName;

  const Ticket({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.openedBy,
    required this.assignedDept,
    this.claimedBy,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.resolutionType,
    this.slaDeadline,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.roomNumber,
    this.openerName,
    this.claimerName,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
    id: j['id'],
    hotelId: j['hotel_id'],
    roomId: j['room_id'],
    openedBy: j['opened_by'],
    assignedDept: j['assigned_dept'],
    claimedBy: j['claimed_by'],
    title: j['title'],
    description: j['description'],
    priority: j['priority'],
    status: j['status'],
    resolutionType: j['resolution_type'],
    slaDeadline: j['sla_deadline'] != null ? DateTime.parse(j['sla_deadline']) : null,
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
    resolvedAt: j['resolved_at'] != null ? DateTime.parse(j['resolved_at']) : null,
    roomNumber: j['room']?['room_number'],
    openerName: j['opener']?['full_name'],
    claimerName: j['claimer']?['full_name'],
  );

  bool get isOverSla =>
    slaDeadline != null && DateTime.now().isAfter(slaDeadline!) && resolvedAt == null;
}

class TicketUpdate {
  final String id;
  final String ticketId;
  final String userId;
  final String? message;
  final String updateType;
  final DateTime createdAt;
  final String? userName;

  const TicketUpdate({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.message,
    required this.updateType,
    required this.createdAt,
    this.userName,
  });

  factory TicketUpdate.fromJson(Map<String, dynamic> j) => TicketUpdate(
    id: j['id'],
    ticketId: j['ticket_id'],
    userId: j['user_id'],
    message: j['message'],
    updateType: j['update_type'],
    createdAt: DateTime.parse(j['created_at']),
    userName: j['user']?['full_name'],
  );
}

class TicketPhoto {
  final String id;
  final String ticketId;
  final String photoUrl;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final String? uploaderName;

  const TicketPhoto({
    required this.id,
    required this.ticketId,
    required this.photoUrl,
    this.fileSizeBytes,
    required this.createdAt,
    this.uploaderName,
  });

  factory TicketPhoto.fromJson(Map<String, dynamic> j) => TicketPhoto(
    id: j['id'],
    ticketId: j['ticket_id'],
    photoUrl: j['photo_url'],
    fileSizeBytes: j['file_size_bytes'],
    createdAt: DateTime.parse(j['created_at']),
    uploaderName: j['uploader']?['full_name'],
  );
}
```

- [ ] **Step 2: Write permission logic**

```dart
// lib/features/tickets/domain/ticket_status.dart
enum TicketStatus { open, inProgress, pendingApproval, resolved, closed }

enum UserRole {
  superAdmin, ceo, receptionManager, maintenanceManager,
  housekeepingManager, securityManager, deputyReception,
  receptionist, securityGuard, maintenanceTech, repairman;

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == _toCamel(s),
      orElse: () => UserRole.receptionist,
    );
  }

  static String _toCamel(String s) {
    final parts = s.split('_');
    return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  bool get canClaimAndUpdate => this != UserRole.receptionist;
  bool get canApproveRoomClose => [
    superAdmin, ceo, receptionManager, maintenanceManager,
    housekeepingManager, securityManager
  ].contains(this);
  bool get isManager => [
    superAdmin, ceo, receptionManager, maintenanceManager,
    housekeepingManager, securityManager
  ].contains(this);
  bool get isRequiredApprover =>
    this == UserRole.receptionManager || this == UserRole.maintenanceManager;
}
```

- [ ] **Step 3: Write routing rules**

```dart
// lib/features/tickets/domain/routing_rules.dart
import 'ticket_status.dart';

// Per spec Section 6: managers (all 5) + CEO + superAdmin can route to any dept.
// housekeepingManager: maintenance only (intentional — security issues escalate via reception).
const Map<UserRole, List<String>> deptRoutingRules = {
  UserRole.receptionist:        ['maintenance', 'housekeeping', 'security'],
  UserRole.deputyReception:     ['maintenance', 'housekeeping', 'security'],
  UserRole.receptionManager:    ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.housekeepingManager: ['maintenance'],  // intentional per spec
  UserRole.maintenanceTech:     ['security'],
  UserRole.repairman:           ['security'],
  UserRole.maintenanceManager:  ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.securityGuard:       ['maintenance', 'reception'],
  UserRole.securityManager:     ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.ceo:                 ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.superAdmin:          ['maintenance', 'housekeeping', 'security', 'reception'],
};

List<String> allowedDepts(UserRole role) =>
  deptRoutingRules[role] ?? ['maintenance'];
```

- [ ] **Step 4: Write model tests**

```dart
// test/features/tickets/domain/ticket_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/tickets/domain/routing_rules.dart';

void main() {
  test('Ticket.fromJson parses correctly', () {
    final t = Ticket.fromJson({
      'id': 'abc', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'claimed_by': null, 'title': 'Broken AC',
      'description': null, 'priority': 'high',
      'status': 'open', 'resolution_type': null,
      'sla_deadline': null,
      'created_at': '2026-03-22T10:00:00Z',
      'updated_at': '2026-03-22T10:00:00Z',
      'resolved_at': null,
    });
    expect(t.title, 'Broken AC');
    expect(t.status, 'open');
    expect(t.isOverSla, false);
  });

  test('receptionist cannot claim or update', () {
    expect(UserRole.receptionist.canClaimAndUpdate, false);
  });

  test('maintenanceTech can claim and update', () {
    expect(UserRole.maintenanceTech.canClaimAndUpdate, true);
  });

  test('housekeepingManager can only route to maintenance', () {
    expect(allowedDepts(UserRole.housekeepingManager), ['maintenance']);
  });

  test('ceo can route to any dept', () {
    final depts = allowedDepts(UserRole.ceo);
    expect(depts, containsAll(['maintenance', 'housekeeping', 'security', 'reception']));
  });
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/tickets/domain/
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/domain/ test/features/tickets/
git commit -m "feat: add ticket domain models and permission logic"
```

---

## Task 2: Ticket Repository

**Files:**
- Create: `lib/features/tickets/data/ticket_repository.dart`

- [ ] **Step 1: Write repository**

```dart
// lib/features/tickets/data/ticket_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/database/sync_queue.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../domain/ticket_model.dart';

class TicketRepository {
  final bool isOnline;
  TicketRepository({required this.isOnline});

  static const _select = '''
    id, hotel_id, room_id, opened_by, assigned_dept, claimed_by,
    title, description, priority, status, resolution_type,
    sla_deadline, created_at, updated_at, resolved_at,
    room:rooms(room_number, floor),
    opener:users!tickets_opened_by_fkey(full_name),
    claimer:users!tickets_claimed_by_fkey(full_name)
  ''';

  Future<List<Ticket>> fetchForDept(String dept) async {
    final res = await supabase
      .from('tickets')
      .select(_select)
      .eq('assigned_dept', dept)
      .order('created_at', ascending: false);
    return (res as List).map((j) => Ticket.fromJson(j)).toList();
  }

  Future<List<Ticket>> fetchMyTickets(String userId) async {
    final res = await supabase
      .from('tickets')
      .select(_select)
      .or('opened_by.eq.$userId,claimed_by.eq.$userId')
      .order('created_at', ascending: false);
    return (res as List).map((j) => Ticket.fromJson(j)).toList();
  }

  Future<Ticket> fetchById(String id) async {
    final res = await supabase.from('tickets').select(_select).eq('id', id).single();
    return Ticket.fromJson(res);
  }

  /// Open a new ticket. Works offline — queued if no connection.
  Future<void> openTicket({
    required String hotelId,
    required String roomId,
    required String openedBy,
    required String assignedDept,
    required String title,
    String? description,
    String priority = 'normal',
    DateTime? slaDeadline,
  }) async {
    final payload = {
      'hotel_id': hotelId,
      'room_id': roomId,
      'opened_by': openedBy,
      'assigned_dept': assignedDept,
      'title': title,
      'description': description,
      'priority': priority,
      'sla_deadline': slaDeadline?.toIso8601String(),
    };

    if (isOnline) {
      await supabase.from('tickets').insert(payload);
    } else {
      await SyncQueue.enqueue('create_ticket', payload);
    }
  }

  /// Claim a ticket. Requires online connection — uses conditional update.
  Future<bool> claimTicket(String ticketId, String userId) async {
    // Returns true if claimed successfully, false if already claimed
    final res = await supabase.rpc('claim_ticket', params: {
      'p_ticket_id': ticketId,
      'p_user_id': userId,
    });
    return res as bool;
  }

  Future<void> addComment(String ticketId, String hotelId, String userId, String message) async {
    final payload = {
      'hotel_id': hotelId,
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'update_type': 'comment',
    };
    if (isOnline) {
      await supabase.from('ticket_updates').insert(payload);
    } else {
      await SyncQueue.enqueue('add_comment', payload);
    }
  }

  Future<void> resolveTicket(String ticketId, String hotelId, String userId,
      String resolutionType) async {
    final now = DateTime.now().toIso8601String();
    final payload = {
      'status': resolutionType == 'room_closed' ? 'pending_approval' : 'resolved',
      'resolution_type': resolutionType,
      'resolved_at': now,
      'updated_at': now,
    };
    if (isOnline) {
      await supabase.from('tickets').update(payload).eq('id', ticketId);
      await supabase.from('ticket_updates').insert({
        'hotel_id': hotelId, 'ticket_id': ticketId,
        'user_id': userId, 'update_type': 'status_change',
        'message': 'Resolved as: $resolutionType',
      });
      // If room_closed, create approval rows (handled by Supabase RPC for atomicity)
      if (resolutionType == 'room_closed') {
        await supabase.rpc('create_approval_request', params: {'p_ticket_id': ticketId});
      }
    } else {
      await SyncQueue.enqueue('resolve_ticket', {'ticket_id': ticketId, 'hotel_id': hotelId,
        'user_id': userId, 'resolution_type': resolutionType});
    }
  }

  Future<List<TicketUpdate>> fetchUpdates(String ticketId) async {
    final res = await supabase
      .from('ticket_updates')
      .select('*, user:users(full_name)')
      .eq('ticket_id', ticketId)
      .order('created_at');
    return (res as List).map((j) => TicketUpdate.fromJson(j)).toList();
  }

  Future<List<TicketPhoto>> fetchPhotos(String ticketId) async {
    final res = await supabase
      .from('ticket_photos')
      .select('*, uploader:users(full_name)')
      .eq('ticket_id', ticketId)
      .order('created_at');
    return (res as List).map((j) => TicketPhoto.fromJson(j)).toList();
  }

  /// Subscribe to realtime updates for a ticket
  Stream<Map<String, dynamic>> watchTicket(String ticketId) {
    return supabase
      .from('tickets')
      .stream(primaryKey: ['id'])
      .eq('id', ticketId)
      .map((rows) => rows.isNotEmpty ? rows.first : {});
  }
}
```

- [ ] **Step 2: Add `claim_ticket` RPC to Supabase**

In Supabase SQL editor, create:
```sql
-- Atomic claim: returns true if claimed, false if already taken
CREATE OR REPLACE FUNCTION claim_ticket(p_ticket_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE rows_updated integer;
BEGIN
  UPDATE tickets
  SET claimed_by = p_user_id, status = 'in_progress', updated_at = now()
  WHERE id = p_ticket_id AND claimed_by IS NULL;

  GET DIAGNOSTICS rows_updated = ROW_COUNT;

  -- Log the claim
  IF rows_updated > 0 THEN
    INSERT INTO ticket_updates (hotel_id, ticket_id, user_id, update_type, message)
    SELECT hotel_id, p_ticket_id, p_user_id, 'claim', 'Ticket claimed'
    FROM tickets WHERE id = p_ticket_id;
  END IF;

  RETURN rows_updated > 0;
END;
$$;

-- Create approval rows atomically
CREATE OR REPLACE FUNCTION create_approval_request(p_ticket_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_hotel_id uuid;
  v_round integer;
  v_maintenance_manager_id uuid;
  v_reception_manager_id uuid;
BEGIN
  SELECT hotel_id INTO v_hotel_id FROM tickets WHERE id = p_ticket_id;
  SELECT COALESCE(MAX(submission_round), 0) + 1 INTO v_round
    FROM ticket_approvals WHERE ticket_id = p_ticket_id;

  -- Find current managers
  SELECT id INTO v_maintenance_manager_id FROM users
    WHERE hotel_id = v_hotel_id AND role = 'maintenance_manager' AND is_active = true LIMIT 1;
  SELECT id INTO v_reception_manager_id FROM users
    WHERE hotel_id = v_hotel_id AND role = 'reception_manager' AND is_active = true LIMIT 1;

  INSERT INTO ticket_approvals
    (hotel_id, ticket_id, resolution_type, submission_round, approver_id, approver_role)
  VALUES
    (v_hotel_id, p_ticket_id, 'room_closed', v_round, v_maintenance_manager_id, 'maintenance_manager'),
    (v_hotel_id, p_ticket_id, 'room_closed', v_round, v_reception_manager_id, 'reception_manager');
END;
$$;
```

Then apply with: Supabase Dashboard → SQL Editor → Run

- [ ] **Step 3: Commit**

```bash
git add lib/features/tickets/data/
git commit -m "feat: add ticket repository with offline-first support"
```

---

## Task 3: New Ticket Screen

**Files:**
- Create: `lib/features/tickets/presentation/new_ticket_screen.dart`

- [ ] **Step 1: Write new ticket screen**

```dart
// lib/features/tickets/presentation/new_ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/routing_rules.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import '../data/ticket_repository.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});
  @override ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedRoom;
  String? _selectedDept;
  String _priority = 'normal';
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist'
    );
    final availableDepts = allowedDepts(role);

    return Scaffold(
      appBar: AppBar(title: Text(l.newTicket)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Room selector (loaded from cached_rooms in Plan 4)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Room'),
            value: _selectedRoom,
            items: const [], // populated from rooms provider
            onChanged: (v) => setState(() => _selectedRoom = v),
          ),
          const SizedBox(height: 12),
          // Department selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Department'),
            value: _selectedDept,
            items: availableDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _selectedDept = v),
          ),
          const SizedBox(height: 12),
          // Priority
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Priority'),
            value: _priority,
            items: ['low','normal','high','urgent']
              .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          _loading
            ? const CircularProgressIndicator()
            : FilledButton(
                onPressed: _submit,
                child: Text(l.saveChanges),
              ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedRoom == null || _selectedDept == null || _titleCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = ref.read(currentUserProvider)!;
      final hotelId = user.appMetadata['hotel_id'] as String;
      final isOnline = ref.read(isOnlineProvider);
      final repo = TicketRepository(isOnline: isOnline);
      // Fetch hotel SLA hours to set sla_deadline
      final hotelRes = await supabase
        .from('users')
        .select('hotel:hotels(default_sla_hours)')
        .eq('id', user.id)
        .single();
      final slaHours = (hotelRes['hotel']?['default_sla_hours'] as int?) ?? 4;
      final slaDeadline = DateTime.now().add(Duration(hours: slaHours));

      await repo.openTicket(
        hotelId: hotelId,
        roomId: _selectedRoom!,
        openedBy: user.id,
        assignedDept: _selectedDept!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priority: _priority,
        slaDeadline: slaDeadline,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }
}
```

- [ ] **Step 2: Write widget test**

```dart
// test/features/tickets/presentation/new_ticket_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/tickets/presentation/new_ticket_screen.dart';

void main() {
  testWidgets('NewTicketScreen shows required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: NewTicketScreen())),
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/features/tickets/presentation/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tickets/presentation/new_ticket_screen.dart test/
git commit -m "feat: add new ticket screen with routing rules"
```

---

## Task 4: Tickets List Screen + Card

**Files:**
- Create: `lib/features/tickets/presentation/tickets_list_screen.dart`
- Create: `lib/features/tickets/presentation/ticket_card.dart`
- Create: `lib/features/tickets/providers/tickets_provider.dart`

- [ ] **Step 1: Write tickets provider**

```dart
// lib/features/tickets/providers/tickets_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';
import '../domain/ticket_status.dart';

final ticketRepoProvider = Provider<TicketRepository>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  return TicketRepository(isOnline: isOnline);
});

final myTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(ticketRepoProvider).fetchMyTickets(user.id);
});

final deptTicketsProvider = FutureProvider.family<List<Ticket>, String>((ref, dept) async {
  return ref.watch(ticketRepoProvider).fetchForDept(dept);
});
```

- [ ] **Step 2: Write ticket card**

```dart
// lib/features/tickets/presentation/ticket_card.dart
import 'package:flutter/material.dart';
import '../domain/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  Color get _statusColor => switch (ticket.status) {
    'open'             => Colors.orange,
    'in_progress'      => Colors.blue,
    'pending_approval' => Colors.red,
    'resolved'         => Colors.green,
    'closed'           => Colors.grey,
    _                  => Colors.grey,
  };

  IconData get _statusIcon => switch (ticket.status) {
    'resolved' => Icons.check_circle,
    'closed'   => Icons.lock,
    'pending_approval' => Icons.pending,
    _          => Icons.radio_button_unchecked,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(_statusIcon, color: _statusColor),
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Room ${ticket.roomNumber ?? "?"} • ${ticket.assignedDept}'),
        trailing: ticket.isOverSla
          ? const Icon(Icons.warning, color: Colors.red, size: 18)
          : null,
      ),
    );
  }
}
```

- [ ] **Step 3: Write tickets list screen**

```dart
// lib/features/tickets/presentation/tickets_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/shared/widgets/offline_banner.dart';
import '../providers/tickets_provider.dart';
import 'ticket_card.dart';

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final myTickets = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.myTickets)),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: myTickets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (tickets) => tickets.isEmpty
              ? Center(child: Text(l.loading))
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (_, i) => TicketCard(
                    ticket: tickets[i],
                    onTap: () => context.push('/tickets/${tickets[i].id}'),
                  ),
                ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/new'),
        label: Text(l.newTicket),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tickets/presentation/ lib/features/tickets/providers/
git commit -m "feat: add tickets list screen with offline banner"
```

---

## Task 5: Ticket Detail Screen + Timeline

**Files:**
- Create: `lib/features/tickets/presentation/ticket_detail_screen.dart`
- Create: `lib/features/tickets/presentation/timeline_entry.dart`
- Create: `lib/features/tickets/presentation/approval_sheet.dart`
- Create: `lib/features/tickets/providers/ticket_detail_provider.dart`

- [ ] **Step 1: Write ticket detail provider (with realtime)**

```dart
// lib/features/tickets/providers/ticket_detail_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';

final ticketDetailProvider = StreamProvider.family<Ticket, String>((ref, ticketId) {
  final isOnline = ref.watch(isOnlineProvider);
  final repo = TicketRepository(isOnline: isOnline);
  return repo.watchTicket(ticketId).map((json) => Ticket.fromJson(json));
});

final ticketUpdatesProvider = FutureProvider.family<List<TicketUpdate>, String>((ref, ticketId) async {
  final isOnline = ref.watch(isOnlineProvider);
  return TicketRepository(isOnline: isOnline).fetchUpdates(ticketId);
});

final ticketPhotosProvider = FutureProvider.family<List<TicketPhoto>, String>((ref, ticketId) async {
  final isOnline = ref.watch(isOnlineProvider);
  return TicketRepository(isOnline: isOnline).fetchPhotos(ticketId);
});
```

- [ ] **Step 2: Write timeline entry widget**

```dart
// lib/features/tickets/presentation/timeline_entry.dart
import 'package:flutter/material.dart';
import '../domain/ticket_model.dart';

class TimelineEntry extends StatelessWidget {
  final TicketUpdate update;
  const TimelineEntry({super.key, required this.update});

  IconData get _icon => switch (update.updateType) {
    'claim'            => Icons.person_add,
    'status_change'    => Icons.sync,
    'photo_added'      => Icons.photo_camera,
    'approval_request' => Icons.approval,
    _                  => Icons.comment,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Icon(_icon, size: 20, color: Theme.of(context).colorScheme.primary),
          Container(width: 2, height: 40, color: Colors.grey.shade300),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(update.userName ?? 'System', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (update.message != null) Text(update.message!),
              Text(
                update.createdAt.toLocal().toString().substring(0, 16),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Write approval bottom sheet**

```dart
// lib/features/tickets/presentation/approval_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/auth/auth_state.dart';

class ApprovalSheet extends ConsumerStatefulWidget {
  final String ticketId;
  final String approvalId;
  const ApprovalSheet({super.key, required this.ticketId, required this.approvalId});

  @override ConsumerState<ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends ConsumerState<ApprovalSheet> {
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _decide(bool approved) async {
    setState(() => _loading = true);
    await supabase.from('ticket_approvals').update({
      'approved': approved,
      'approved_at': DateTime.now().toIso8601String(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    }).eq('id', widget.approvalId);

    // Check if all approvals done → close ticket (handled server-side via DB trigger or client check)
    if (approved) await _checkAndClose();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _checkAndClose() async {
    final round = await supabase.rpc('check_and_close_ticket',
      params: {'p_ticket_id': widget.ticketId});
    // RPC handles closing the ticket and updating room status if both approved
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Approval Decision', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _loading
            ? const CircularProgressIndicator()
            : Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(false),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _decide(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ]),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Add `check_and_close_ticket` RPC to Supabase**

```sql
CREATE OR REPLACE FUNCTION check_and_close_ticket(p_ticket_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_round integer;
  v_approvals integer;
  v_room_id uuid;
BEGIN
  SELECT MAX(submission_round) INTO v_round FROM ticket_approvals WHERE ticket_id = p_ticket_id;

  SELECT COUNT(*) INTO v_approvals FROM ticket_approvals
  WHERE ticket_id = p_ticket_id
    AND submission_round = v_round
    AND approved = true;

  IF v_approvals = 2 THEN
    -- Close ticket
    UPDATE tickets SET status = 'closed', updated_at = now() WHERE id = p_ticket_id
    RETURNING room_id INTO v_room_id;

    -- Close room
    UPDATE rooms SET status = 'closed', status_changed_at = now() WHERE id = v_room_id;
  END IF;

  -- Check for any rejection → return ticket to in_progress
  IF EXISTS (
    SELECT 1 FROM ticket_approvals
    WHERE ticket_id = p_ticket_id AND submission_round = v_round AND approved = false
  ) THEN
    UPDATE tickets SET status = 'in_progress', updated_at = now() WHERE id = p_ticket_id;
  END IF;
END;
$$;
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/
git commit -m "feat: add ticket detail, timeline, and approval workflow"
```

---

## Task 6: Photo Capture + Upload

**Files:**
- Create: `lib/features/tickets/data/photo_upload_service.dart`

- [ ] **Step 1: Write photo upload service**

```dart
// lib/features/tickets/data/photo_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/database/sync_queue.dart';

const _maxBytes = 10 * 1024 * 1024; // 10MB

class PhotoUploadService {
  final bool isOnline;
  PhotoUploadService({required this.isOnline});

  Future<XFile?> pickPhoto() async {
    return ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<void> uploadPhoto({
    required String ticketId,
    required String hotelId,
    required String uploadedBy,
    required XFile photo,
  }) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length > _maxBytes) {
      throw Exception('Photo exceeds 10MB limit');
    }

    final ext = photo.path.split('.').last;
    final filename = '${const Uuid().v4()}.$ext';
    final storagePath = '$hotelId/$ticketId/$filename';

    if (isOnline) {
      await supabase.storage.from('ticket-photos').uploadBinary(storagePath, bytes);
      // Bucket is private — use signed URL (1 week expiry). Re-sign when displaying.
      final signedResponse = await supabase.storage
        .from('ticket-photos')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 7); // 7 days
      final url = signedResponse;
      await supabase.from('ticket_photos').insert({
        'hotel_id': hotelId,
        'ticket_id': ticketId,
        'uploaded_by': uploadedBy,
        'photo_url': url,
        'file_size_bytes': bytes.length,
      });
    } else {
      // Save to local temp file, queue for upload
      final tempPath = '${Directory.systemTemp.path}/$filename';
      await File(tempPath).writeAsBytes(bytes);
      await SyncQueue.enqueue('upload_photo', {
        'ticket_id': ticketId,
        'hotel_id': hotelId,
        'uploaded_by': uploadedBy,
        'local_path': tempPath,
        'storage_path': storagePath,
        'file_size_bytes': bytes.length,
      });
    }
  }
}
```

- [ ] **Step 2: Write photo service test**

```dart
// test/features/tickets/data/photo_upload_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/data/photo_upload_service.dart';

void main() {
  test('PhotoUploadService is instantiated with isOnline flag', () {
    final service = PhotoUploadService(isOnline: true);
    expect(service.isOnline, true);
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/features/tickets/data/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tickets/data/photo_upload_service.dart test/
git commit -m "feat: add photo capture and offline-queued upload"
```

---

## Task 6b: Ticket Detail Screen

**Files:**
- Create: `lib/features/tickets/presentation/ticket_detail_screen.dart`

- [ ] **Step 1: Write TicketDetailScreen**

```dart
// lib/features/tickets/presentation/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import '../providers/ticket_detail_provider.dart';
import '../data/ticket_repository.dart';
import '../data/photo_upload_service.dart';
import 'timeline_entry.dart';
import 'approval_sheet.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final updatesAsync = ref.watch(ticketUpdatesProvider(ticketId));
    final photosAsync = ref.watch(ticketPhotosProvider(ticketId));
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist');

    return Scaffold(
      appBar: AppBar(title: Text(l.myTickets)),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (ticket) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(ticket.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Room ${ticket.roomNumber} • ${ticket.assignedDept} • ${ticket.priority}',
              style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            _statusChip(ticket.status),
            const Divider(height: 32),

            // Timeline
            Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...updatesAsync.maybeWhen(
              data: (updates) => updates.map((u) => TimelineEntry(update: u)).toList(),
              orElse: () => [const CircularProgressIndicator()],
            ),

            // Photos
            if (photosAsync.maybeWhen(data: (p) => p.isNotEmpty, orElse: () => false)) ...[
              const Divider(height: 32),
              Text('Photos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              photosAsync.maybeWhen(
                data: (photos) => Wrap(spacing: 8, runSpacing: 8, children: photos.map((p) =>
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.photoUrl, width: 100, height: 100, fit: BoxFit.cover))).toList()),
                orElse: () => const SizedBox.shrink(),
              ),
            ],

            const SizedBox(height: 32),

            // Actions
            if (role.canClaimAndUpdate && ticket.claimedBy == null && ticket.status == 'open')
              FilledButton(
                onPressed: isOnline ? () async {
                  final repo = TicketRepository(isOnline: isOnline);
                  await repo.claimTicket(ticket.id, user!.id);
                  ref.invalidate(ticketDetailProvider(ticketId));
                } : null,
                child: Text(isOnline ? l.claimTicket : l.claimRequiresConnection),
              ),

            if (role.canClaimAndUpdate && ticket.claimedBy == user?.id &&
                ticket.status == 'in_progress') ...[
              // Add photo button
              OutlinedButton.icon(
                onPressed: () async {
                  final svc = PhotoUploadService(isOnline: isOnline);
                  final photo = await svc.pickPhoto();
                  if (photo != null) {
                    await svc.uploadPhoto(
                      ticketId: ticket.id,
                      hotelId: ticket.hotelId,
                      uploadedBy: user!.id,
                      photo: photo,
                    );
                    ref.invalidate(ticketPhotosProvider(ticketId));
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(l.addPhoto),
              ),
              const SizedBox(height: 12),
              // Resolve buttons
              Row(children: [
                Expanded(child: FilledButton.icon(
                  onPressed: () async {
                    final repo = TicketRepository(isOnline: isOnline);
                    await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'fixed');
                    ref.invalidate(ticketDetailProvider(ticketId));
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l.ticketFixed),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () async {
                    final repo = TicketRepository(isOnline: isOnline);
                    await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'on_hold');
                    ref.invalidate(ticketDetailProvider(ticketId));
                  },
                  icon: const Icon(Icons.pause),
                  label: Text(l.ticketOnHold),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () async {
                    final repo = TicketRepository(isOnline: isOnline);
                    await repo.resolveTicket(ticket.id, ticket.hotelId, user!.id, 'room_closed');
                    ref.invalidate(ticketDetailProvider(ticketId));
                  },
                  icon: const Icon(Icons.lock),
                  label: Text(l.ticketRoomClosed),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                )),
              ]),
            ],

            // Approval buttons for managers when ticket is pending_approval
            if (role.isRequiredApprover && ticket.status == 'pending_approval')
              FutureBuilder(
                future: supabase.from('ticket_approvals')
                  .select()
                  .eq('ticket_id', ticketId)
                  .eq('approver_id', user!.id)
                  .is_('approved', null)
                  .maybeSingle(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                  return FilledButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => ApprovalSheet(
                        ticketId: ticketId,
                        approvalId: snap.data!['id'],
                      ),
                    ),
                    child: Text(l.pendingApproval),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'open': Colors.orange, 'in_progress': Colors.blue,
      'pending_approval': Colors.red, 'resolved': Colors.green, 'closed': Colors.grey,
    };
    return Chip(
      label: Text(status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: colors[status] ?? Colors.grey,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/tickets/presentation/ticket_detail_screen.dart
git commit -m "feat: add ticket detail screen with timeline, photos, and actions"
```

---

## Task 7: Wire Routes

Update `lib/navigation/router.dart` to add ticket routes:

- [ ] **Step 1: Add routes**

```dart
// Add inside GoRouter routes list:
GoRoute(path: '/tickets', builder: (_, __) => const TicketsListScreen()),
GoRoute(path: '/tickets/new', builder: (_, __) => const NewTicketScreen()),
GoRoute(
  path: '/tickets/:id',
  builder: (_, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!),
),
```

- [ ] **Step 2: Run app and verify flow**

```bash
flutter run -d chrome
```
Test: Login → see tickets list → tap + → fill new ticket form → submit → see ticket in list → tap → see detail.

- [ ] **Step 3: Commit**

```bash
git add lib/navigation/router.dart
git commit -m "feat: wire ticket routes in go_router"
```

---

## Verification Checklist

Before moving to Plan 4, confirm:

- [ ] `flutter test` passes all tests
- [ ] Can open a new ticket (online)
- [ ] Ticket appears in list with correct color/icon
- [ ] Ticket detail shows timeline of updates
- [ ] Claiming a ticket while offline shows disabled button + message
- [ ] Photo capture respects 10MB limit (test with a large image)
- [ ] Approval sheet appears for managers on pending_approval tickets
- [ ] `check_and_close_ticket` RPC closes ticket when both approve
