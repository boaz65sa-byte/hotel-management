# Guest Requests — Hotel App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add guest request management to the existing hotel app — reception creates requests, manager monitors and reassigns, housekeeping and maintenance staff handle their department's requests, manager views guest feedback.

**Architecture:** New `lib/features/guest_requests/` feature folder following the existing pattern (domain → data → providers → presentation). Four existing home screens get a new tab. Supabase `.stream()` filtered client-side for realtime updates (same pattern as housekeeping).

**Tech Stack:** Flutter + Riverpod (StreamProvider/FutureProvider) + Supabase (stream, insert, update) + dark theme (#0a1628 bg, #0f1f3d surface, #c9a84c gold, #e2e8f0 text)

---

## File Map

| Action | File |
|--------|------|
| SQL | Supabase dashboard — 2 tables + trigger + RLS |
| Create | `lib/features/guest_requests/domain/guest_request_model.dart` |
| Create | `lib/features/guest_requests/data/guest_request_repository.dart` |
| Create | `lib/features/guest_requests/providers/guest_request_providers.dart` |
| Create | `lib/features/guest_requests/presentation/guest_request_card.dart` |
| Create | `lib/features/guest_requests/presentation/guest_requests_list.dart` |
| Create | `lib/features/guest_requests/presentation/new_guest_request_screen.dart` |
| Create | `lib/features/guest_requests/presentation/guest_feedback_screen.dart` |
| Create | `lib/features/guest_requests/presentation/staff_requests_screen.dart` |
| Modify | `lib/features/home/presentation/reception_home.dart` |
| Modify | `lib/features/home/presentation/manager_home.dart` |
| Modify | `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart` |
| Modify | `lib/features/home/presentation/maintenance_home.dart` |
| Create | `test/features/guest_requests/guest_request_test.dart` |

---

### Task 1: SQL migration

**Files:** SQL run in Supabase dashboard → SQL Editor

- [ ] **Step 1: Run this SQL in Supabase dashboard**

```sql
-- guest_requests table
CREATE TABLE IF NOT EXISTS guest_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      uuid NOT NULL REFERENCES hotels(id),
  room_number   text NOT NULL,
  guest_name    text NOT NULL,
  category      text NOT NULL,
  description   text,
  status        text NOT NULL DEFAULT 'open',
  assigned_dept text,
  assigned_to   uuid REFERENCES auth.users(id),
  created_by    text NOT NULL DEFAULT 'guest',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- guest_feedback table
CREATE TABLE IF NOT EXISTS guest_feedback (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id),
  room_number text NOT NULL,
  guest_name  text NOT NULL,
  rating      int  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Auto-routing trigger: sets assigned_dept from category on insert
CREATE OR REPLACE FUNCTION route_guest_request()
RETURNS TRIGGER AS $$
BEGIN
  NEW.assigned_dept := CASE NEW.category
    WHEN 'housekeeping' THEN 'housekeeping'
    WHEN 'maintenance'  THEN 'maintenance'
    ELSE 'reception'
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_route_request
  BEFORE INSERT ON guest_requests
  FOR EACH ROW EXECUTE FUNCTION route_guest_request();

-- RLS
ALTER TABLE guest_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_feedback ENABLE ROW LEVEL SECURITY;

-- Hotel staff: full access to their hotel's data
CREATE POLICY "hotel staff access guest_requests"
  ON guest_requests FOR ALL
  USING (hotel_id IN (SELECT hotel_id FROM users WHERE id = auth.uid()));

-- Anon guests: insert requests
CREATE POLICY "anon insert guest_requests"
  ON guest_requests FOR INSERT TO anon WITH CHECK (true);

-- Anon guests: read (filtered client-side by room_number + guest_name)
CREATE POLICY "anon read guest_requests"
  ON guest_requests FOR SELECT TO anon USING (true);

-- Manager/admin: full access to feedback
CREATE POLICY "hotel staff access guest_feedback"
  ON guest_feedback FOR ALL
  USING (hotel_id IN (SELECT hotel_id FROM users WHERE id = auth.uid()));

-- Anon guests: insert feedback
CREATE POLICY "anon insert guest_feedback"
  ON guest_feedback FOR INSERT TO anon WITH CHECK (true);

-- Enable Realtime for guest_requests
ALTER PUBLICATION supabase_realtime ADD TABLE guest_requests;
```

- [ ] **Step 2: Verify in Supabase Table Editor**

Confirm `guest_requests` and `guest_feedback` tables appear with correct columns.

---

### Task 2: Domain models + unit tests

**Files:**
- Create: `lib/features/guest_requests/domain/guest_request_model.dart`
- Create: `test/features/guest_requests/guest_request_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/features/guest_requests/guest_request_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

void main() {
  group('GuestRequest.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'req-1',
        'hotel_id': 'h-1',
        'room_number': '205',
        'guest_name': 'דנה כהן',
        'category': 'housekeeping',
        'description': 'מגבות נוספות',
        'status': 'open',
        'assigned_dept': 'housekeeping',
        'assigned_to': null,
        'created_by': 'guest',
        'created_at': '2026-05-01T10:00:00.000Z',
        'updated_at': '2026-05-01T10:00:00.000Z',
      };
      final req = GuestRequest.fromJson(json);
      expect(req.id, 'req-1');
      expect(req.roomNumber, '205');
      expect(req.guestName, 'דנה כהן');
      expect(req.category, 'housekeeping');
      expect(req.description, 'מגבות נוספות');
      expect(req.status, 'open');
      expect(req.assignedDept, 'housekeeping');
      expect(req.assignedTo, isNull);
      expect(req.createdBy, 'guest');
    });

    test('defaults nullable fields to null', () {
      final json = {
        'id': 'req-2',
        'hotel_id': 'h-1',
        'room_number': '101',
        'guest_name': 'אורח',
        'category': 'reception',
        'status': 'open',
        'created_by': 'reception',
        'created_at': '2026-05-01T10:00:00.000Z',
        'updated_at': '2026-05-01T10:00:00.000Z',
      };
      final req = GuestRequest.fromJson(json);
      expect(req.description, isNull);
      expect(req.assignedDept, isNull);
      expect(req.assignedTo, isNull);
    });
  });

  group('GuestFeedback.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'fb-1',
        'hotel_id': 'h-1',
        'room_number': '205',
        'guest_name': 'דנה כהן',
        'rating': 5,
        'comment': 'שירות מצוין!',
        'created_at': '2026-05-01T12:00:00.000Z',
      };
      final fb = GuestFeedback.fromJson(json);
      expect(fb.rating, 5);
      expect(fb.comment, 'שירות מצוין!');
    });

    test('parses null comment', () {
      final json = {
        'id': 'fb-2',
        'hotel_id': 'h-1',
        'room_number': '101',
        'guest_name': 'אורח',
        'rating': 4,
        'comment': null,
        'created_at': '2026-05-01T12:00:00.000Z',
      };
      final fb = GuestFeedback.fromJson(json);
      expect(fb.comment, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

Expected: FAIL — `GuestRequest` not found.

- [ ] **Step 3: Create model file**

```dart
// lib/features/guest_requests/domain/guest_request_model.dart

class GuestRequest {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final String category;
  final String? description;
  final String status;
  final String? assignedDept;
  final String? assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestRequest({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.guestName,
    required this.category,
    this.description,
    required this.status,
    this.assignedDept,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuestRequest.fromJson(Map<String, dynamic> j) => GuestRequest(
    id:           j['id'] as String,
    hotelId:      j['hotel_id'] as String,
    roomNumber:   j['room_number'] as String,
    guestName:    j['guest_name'] as String,
    category:     j['category'] as String,
    description:  j['description'] as String?,
    status:       j['status'] as String,
    assignedDept: j['assigned_dept'] as String?,
    assignedTo:   j['assigned_to'] as String?,
    createdBy:    j['created_by'] as String,
    createdAt:    DateTime.parse(j['created_at'] as String),
    updatedAt:    DateTime.parse(j['updated_at'] as String),
  );
}

class GuestFeedback {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const GuestFeedback({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.guestName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory GuestFeedback.fromJson(Map<String, dynamic> j) => GuestFeedback(
    id:         j['id'] as String,
    hotelId:    j['hotel_id'] as String,
    roomNumber: j['room_number'] as String,
    guestName:  j['guest_name'] as String,
    rating:     j['rating'] as int,
    comment:    j['comment'] as String?,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/guest_requests/domain/guest_request_model.dart \
        test/features/guest_requests/guest_request_test.dart
git commit -m "feat: add GuestRequest and GuestFeedback domain models"
```

---

### Task 3: GuestRequestRepository

**Files:**
- Create: `lib/features/guest_requests/data/guest_request_repository.dart`

- [ ] **Step 1: Create repository**

```dart
// lib/features/guest_requests/data/guest_request_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

class GuestRequestRepository {
  /// Streams all requests for a hotel, newest first.
  /// Filters client-side because .stream() only supports one .eq() filter.
  Stream<List<GuestRequest>> streamAll(String hotelId) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Streams active requests for a specific department (staff view).
  /// Excludes resolved and cancelled — filtered client-side.
  Stream<List<GuestRequest>> streamMyDept(String hotelId, String dept) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .where((r) =>
                r.assignedDept == dept &&
                r.status != 'resolved' &&
                r.status != 'cancelled')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Creates a new request. DB trigger auto-sets assigned_dept from category.
  Future<void> create({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required String category,
    String? description,
    String createdBy = 'reception',
  }) async {
    await supabase.from('guest_requests').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'category':    category,
      if (description != null && description.isNotEmpty)
        'description': description,
      'created_by': createdBy,
    });
  }

  /// Updates the status of a request (e.g., open → in_progress → resolved).
  Future<void> updateStatus(String id, String status) async {
    await supabase.from('guest_requests').update({
      'status':     status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    // TODO(Module 4): send push notification to assigned dept
  }

  /// Manager reassigns a request to a different department.
  Future<void> reassign(String id, String dept) async {
    await supabase.from('guest_requests').update({
      'assigned_dept': dept,
      'status':        'assigned',
      'updated_at':    DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Fetches all feedback for a hotel (manager/admin only).
  Future<List<GuestFeedback>> fetchFeedback(String hotelId) async {
    final res = await supabase
        .from('guest_feedback')
        .select()
        .eq('hotel_id', hotelId)
        .order('created_at', ascending: false);
    return (res as List).map((j) => GuestFeedback.fromJson(j)).toList();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guest_requests/data/guest_request_repository.dart
git commit -m "feat: add GuestRequestRepository"
```

---

### Task 4: Providers

**Files:**
- Create: `lib/features/guest_requests/providers/guest_request_providers.dart`

- [ ] **Step 1: Create providers file**

```dart
// lib/features/guest_requests/providers/guest_request_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/guest_requests/data/guest_request_repository.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

final guestRequestRepositoryProvider =
    Provider<GuestRequestRepository>((_) => GuestRequestRepository());

/// All requests for the hotel — reception and manager view.
final allGuestRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return const Stream.empty();
  return ref.read(guestRequestRepositoryProvider).streamAll(hotelId);
});

/// Requests for current user's department — housekeeping and maintenance staff.
final myDeptRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  final role = (user?.appMetadata['role'] as String?) ?? '';
  final dept = _roleToDept(role);
  if (hotelId == null || dept == null) return const Stream.empty();
  return ref.read(guestRequestRepositoryProvider).streamMyDept(hotelId, dept);
});

String? _roleToDept(String role) => switch (role) {
  'housekeeping' || 'housekeeping_manager' => 'housekeeping',
  'maintenance'                             => 'maintenance',
  'receptionist' || 'hotel_admin' || 'super_admin' => 'reception',
  _ => null,
};

/// Guest feedback list — manager/admin only.
final guestFeedbackProvider = FutureProvider<List<GuestFeedback>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref.read(guestRequestRepositoryProvider).fetchFeedback(hotelId);
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guest_requests/providers/guest_request_providers.dart
git commit -m "feat: add guest request providers"
```

---

### Task 5: GuestRequestCard widget

**Files:**
- Create: `lib/features/guest_requests/presentation/guest_request_card.dart`
- Modify: `test/features/guest_requests/guest_request_test.dart`

- [ ] **Step 1: Add widget tests**

Append inside `main()` in `test/features/guest_requests/guest_request_test.dart`:

```dart
// Add these imports at the top of the test file:
// import 'package:hotel_app/features/guest_requests/presentation/guest_request_card.dart';

group('GuestRequestCard', () {
  GuestRequest _makeReq({String status = 'open', String category = 'housekeeping'}) =>
      GuestRequest(
        id: 'r1',
        hotelId: 'h1',
        roomNumber: '205',
        guestName: 'דנה כהן',
        category: category,
        description: 'מגבות נוספות',
        status: status,
        createdBy: 'guest',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  testWidgets('shows room number and guest name', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuestRequestCard(request: _makeReq())),
    ));
    expect(find.textContaining('חדר 205'), findsOneWidget);
    expect(find.textContaining('דנה כהן'), findsOneWidget);
  });

  testWidgets('shows category label for housekeeping', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuestRequestCard(request: _makeReq())),
    ));
    expect(find.text('🛏️ חדרניות'), findsOneWidget);
  });

  testWidgets('shows status badge for in_progress', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuestRequestCard(request: _makeReq(status: 'in_progress'))),
    ));
    expect(find.text('בטיפול'), findsOneWidget);
  });

  testWidgets('shows resolved status badge', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GuestRequestCard(request: _makeReq(status: 'resolved'))),
    ));
    expect(find.text('טופלה'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

Expected: FAIL — `GuestRequestCard` not found.

- [ ] **Step 3: Create card widget**

```dart
// lib/features/guest_requests/presentation/guest_request_card.dart
import 'package:flutter/material.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

class GuestRequestCard extends StatelessWidget {
  final GuestRequest request;
  final VoidCallback? onTap;

  const GuestRequestCard({super.key, required this.request, this.onTap});

  static const _categoryLabel = {
    'housekeeping': '🛏️ חדרניות',
    'maintenance':  '🔧 תחזוקה',
    'reception':    '🛎️ קבלה',
  };

  static const _statusColor = {
    'open':        Color(0xFFF87171),
    'assigned':    Color(0xFFFB923C),
    'in_progress': Color(0xFFFB923C),
    'resolved':    Color(0xFF4ADE80),
    'cancelled':   Color(0xFF64748B),
  };

  static const _statusLabel = {
    'open':        'פתוחה',
    'assigned':    'הוקצתה',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה',
    'cancelled':   'בוטלה',
  };

  String _elapsed() {
    final diff = DateTime.now().difference(request.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} דק\'';
    if (diff.inHours < 24)   return '${diff.inHours} שע\'';
    return '${diff.inDays} ימים';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor[request.status] ?? const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'חדר ${request.roomNumber} · ${request.guestName}',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _categoryLabel[request.category] ?? request.category,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  if (request.description != null && request.description!.isNotEmpty)
                    Text(
                      request.description!,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel[request.status] ?? request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _elapsed(),
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_request_card.dart \
        test/features/guest_requests/guest_request_test.dart
git commit -m "feat: add GuestRequestCard widget"
```

---

### Task 6: GuestRequestsListScreen (reception + manager view)

**Files:**
- Create: `lib/features/guest_requests/presentation/guest_requests_list.dart`
- Modify: `test/features/guest_requests/guest_request_test.dart`

- [ ] **Step 1: Add widget tests**

Add these imports to the top of `test/features/guest_requests/guest_request_test.dart`:

```dart
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';
```

Append inside `main()`:

```dart
group('GuestRequestsListScreen', () {
  GuestRequest _makeReq({String status = 'open', String roomNumber = '101'}) =>
      GuestRequest(
        id: roomNumber,
        hotelId: 'h1',
        roomNumber: roomNumber,
        guestName: 'אורח',
        category: 'housekeeping',
        status: status,
        createdBy: 'guest',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  testWidgets('shows all requests', (tester) async {
    final requests = [
      _makeReq(roomNumber: '101'),
      _makeReq(roomNumber: '202', status: 'in_progress'),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allGuestRequestsProvider.overrideWith((_) => Stream.value(requests)),
      ],
      child: const MaterialApp(home: GuestRequestsListScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('חדר 101'), findsOneWidget);
    expect(find.textContaining('חדר 202'), findsOneWidget);
  });

  testWidgets('shows empty state when no requests', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allGuestRequestsProvider.overrideWith((_) => Stream.value([])),
      ],
      child: const MaterialApp(home: GuestRequestsListScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('אין בקשות'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

Expected: FAIL — `GuestRequestsListScreen` not found.

- [ ] **Step 3: Create the screen**

```dart
// lib/features/guest_requests/presentation/guest_requests_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_request_card.dart';
import 'package:hotel_app/features/guest_requests/presentation/new_guest_request_screen.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

const _filters = ['הכול', 'פתוחות', 'בטיפול', 'טופלו'];

bool _matchesFilter(GuestRequest r, String filter) => switch (filter) {
  'פתוחות' => r.status == 'open' || r.status == 'assigned',
  'בטיפול'  => r.status == 'in_progress',
  'טופלו'   => r.status == 'resolved',
  _         => true,
};

class GuestRequestsListScreen extends ConsumerStatefulWidget {
  const GuestRequestsListScreen({super.key});
  @override
  ConsumerState<GuestRequestsListScreen> createState() =>
      _GuestRequestsListScreenState();
}

class _GuestRequestsListScreenState
    extends ConsumerState<GuestRequestsListScreen> {
  String _filter = 'הכול';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allGuestRequestsProvider);
    return requestsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Text('שגיאה: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (all) {
        final requests =
            all.where((r) => _matchesFilter(r, _filter)).toList();
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'בקשות אורחים',
                    style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                                selectedColor: const Color(0xFFC9A84C),
                                labelStyle: TextStyle(
                                  color: _filter == f
                                      ? Colors.black
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(0xFF0F1F3D),
                                checkmarkColor: Colors.black,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: requests.isEmpty
                      ? const Center(
                          child: Text('אין בקשות',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 16)),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: requests.length,
                          itemBuilder: (_, i) => GuestRequestCard(
                            request: requests[i],
                            onTap: () => _showActions(requests[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NewGuestRequestScreen()),
            ),
            backgroundColor: const Color(0xFFC9A84C),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('בקשה ידנית',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  void _showActions(GuestRequest request) {
    final repo = ref.read(guestRequestRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'חדר ${request.roomNumber} · ${request.guestName}',
              style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (request.status == 'open' || request.status == 'assigned')
              ListTile(
                leading: const Icon(Icons.play_arrow,
                    color: Color(0xFFFB923C)),
                title: const Text('התחל טיפול',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(context);
                  repo.updateStatus(request.id, 'in_progress');
                },
              ),
            if (request.status == 'in_progress')
              ListTile(
                leading: const Icon(Icons.check_circle,
                    color: Color(0xFF4ADE80)),
                title: const Text('סמן כטופל',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () {
                  Navigator.pop(context);
                  repo.updateStatus(request.id, 'resolved');
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz,
                  color: Color(0xFF94A3B8)),
              title: const Text('שנה מחלקה',
                  style: TextStyle(color: Color(0xFFE2E8F0))),
              onTap: () => _showReassignSheet(request),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignSheet(GuestRequest request) {
    Navigator.pop(context);
    final repo = ref.read(guestRequestRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('שנה הקצאה',
                style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final entry in const [
              ('housekeeping', '🛏️ חדרניות'),
              ('maintenance', '🔧 תחזוקה'),
              ('reception', '🛎️ קבלה'),
            ])
              ListTile(
                title: Text(entry.$2,
                    style: const TextStyle(color: Color(0xFFE2E8F0))),
                trailing: request.assignedDept == entry.$1
                    ? const Icon(Icons.check, color: Color(0xFFC9A84C))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  repo.reassign(request.id, entry.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_requests_list.dart \
        test/features/guest_requests/guest_request_test.dart
git commit -m "feat: add GuestRequestsListScreen"
```

---

### Task 7: NewGuestRequestScreen

**Files:**
- Create: `lib/features/guest_requests/presentation/new_guest_request_screen.dart`

- [ ] **Step 1: Create screen**

```dart
// lib/features/guest_requests/presentation/new_guest_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class NewGuestRequestScreen extends ConsumerStatefulWidget {
  const NewGuestRequestScreen({super.key});
  @override
  ConsumerState<NewGuestRequestScreen> createState() =>
      _NewGuestRequestScreenState();
}

class _NewGuestRequestScreenState
    extends ConsumerState<NewGuestRequestScreen> {
  final _roomCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'housekeeping';
  bool _loading = false;

  static const _categories = [
    ('housekeeping', '🛏️ חדרניות'),
    ('maintenance',  '🔧 תחזוקה'),
    ('reception',    '🛎️ קבלה'),
  ];

  @override
  void dispose() {
    _roomCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final room = _roomCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (room.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא למלא מספר חדר ושם אורח')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      if (hotelId == null) throw Exception('לא מחובר');
      await ref.read(guestRequestRepositoryProvider).create(
            hotelId:     hotelId,
            roomNumber:  room,
            guestName:   name,
            category:    _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdBy:   'reception',
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה: $e'),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('בקשה ידנית',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('מספר חדר'),
            _field(_roomCtrl, 'לדוגמה: 205', TextInputType.number),
            const SizedBox(height: 16),
            _label('שם האורח'),
            _field(_nameCtrl, 'שם מלא'),
            const SizedBox(height: 16),
            _label('קטגוריה'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories
                  .map((c) => ChoiceChip(
                        label: Text(c.$2),
                        selected: _category == c.$1,
                        onSelected: (_) =>
                            setState(() => _category = c.$1),
                        selectedColor: const Color(0xFFC9A84C),
                        labelStyle: TextStyle(
                          color: _category == c.$1
                              ? Colors.black
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: const Color(0xFF0F1F3D),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            _label('פרטים (אופציונלי)'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFFE2E8F0)),
              decoration: _inputDeco('מה האורח צריך?'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('שלח בקשה'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      [TextInputType? type]) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Color(0xFFE2E8F0)),
        decoration: _inputDeco(hint),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFF0F1F3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guest_requests/presentation/new_guest_request_screen.dart
git commit -m "feat: add NewGuestRequestScreen"
```

---

### Task 8: GuestFeedbackScreen

**Files:**
- Create: `lib/features/guest_requests/presentation/guest_feedback_screen.dart`

- [ ] **Step 1: Create screen**

```dart
// lib/features/guest_requests/presentation/guest_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class GuestFeedbackScreen extends ConsumerWidget {
  const GuestFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(guestFeedbackProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: feedbackAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white)),
          ),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text('אין משובים עדיין',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 16)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'משובי אורחים',
                        style: TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final fb = items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1F3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF1E3A5F)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'חדר ${fb.roomNumber} · ${fb.guestName}',
                                      style: const TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (idx) => Icon(
                                          idx < fb.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color:
                                              const Color(0xFFC9A84C),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (fb.comment != null &&
                                    fb.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    fb.comment!,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_feedback_screen.dart
git commit -m "feat: add GuestFeedbackScreen"
```

---

### Task 9: StaffRequestsScreen

**Files:**
- Create: `lib/features/guest_requests/presentation/staff_requests_screen.dart`
- Modify: `test/features/guest_requests/guest_request_test.dart`

- [ ] **Step 1: Add widget tests**

Add import at the top of `guest_request_test.dart`:

```dart
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';
```

Append inside `main()`:

```dart
group('StaffRequestsScreen', () {
  GuestRequest _makeReq({String status = 'open'}) => GuestRequest(
        id: 'r1',
        hotelId: 'h1',
        roomNumber: '303',
        guestName: 'אורח',
        category: 'maintenance',
        status: status,
        createdBy: 'guest',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  testWidgets('shows assigned request with התחל טיפול', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myDeptRequestsProvider.overrideWith((_) => Stream.value([_makeReq()])),
      ],
      child: const MaterialApp(home: StaffRequestsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('חדר 303'), findsOneWidget);
    expect(find.text('התחל טיפול'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myDeptRequestsProvider.overrideWith((_) => Stream.value([])),
      ],
      child: const MaterialApp(home: StaffRequestsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('אין בקשות להיום ✅'), findsOneWidget);
  });

  testWidgets('shows סמן כטופל for in_progress', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myDeptRequestsProvider.overrideWith(
            (_) => Stream.value([_makeReq(status: 'in_progress')])),
      ],
      child: const MaterialApp(home: StaffRequestsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('סמן כטופל'), findsOneWidget);
  });
});
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

- [ ] **Step 3: Create screen**

```dart
// lib/features/guest_requests/presentation/staff_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class StaffRequestsScreen extends ConsumerWidget {
  const StaffRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myDeptRequestsProvider);
    return requestsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Text('שגיאה: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (requests) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'הבקשות שלי',
                  style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${requests.length} בקשות פעילות',
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
              Expanded(
                child: requests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF4ADE80), size: 48),
                            SizedBox(height: 12),
                            Text('אין בקשות להיום ✅',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: requests.length,
                        itemBuilder: (_, i) =>
                            _StaffRequestCard(request: requests[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffRequestCard extends ConsumerWidget {
  final GuestRequest request;
  const _StaffRequestCard({required this.request});

  static const _categoryLabel = {
    'housekeeping': '🛏️ חדרניות',
    'maintenance':  '🔧 תחזוקה',
    'reception':    '🛎️ קבלה',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress = request.status == 'in_progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'חדר ${request.roomNumber} · ${request.guestName}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _categoryLabel[request.category] ?? request.category,
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 12),
          ),
          if (request.description != null &&
              request.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                request.description!,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(guestRequestRepositoryProvider)
                    .updateStatus(request.id,
                        isInProgress ? 'resolved' : 'in_progress'),
                style: FilledButton.styleFrom(
                  backgroundColor: isInProgress
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Text(isInProgress ? 'סמן כטופל' : 'התחל טיפול'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/features/guest_requests/guest_request_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/guest_requests/presentation/staff_requests_screen.dart \
        test/features/guest_requests/guest_request_test.dart
git commit -m "feat: add StaffRequestsScreen"
```

---

### Task 10: Wire tabs into all home screens

**Files:**
- Modify: `lib/features/home/presentation/reception_home.dart`
- Modify: `lib/features/home/presentation/manager_home.dart`
- Modify: `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart`
- Modify: `lib/features/home/presentation/maintenance_home.dart`

- [ ] **Step 1: Update `reception_home.dart`**

Replace entire file content:

```dart
// lib/features/home/presentation/reception_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/rooms/presentation/rooms_grid_screen.dart';
import 'package:hotel_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class ReceptionHomeScreen extends ConsumerStatefulWidget {
  const ReceptionHomeScreen({super.key});
  @override
  ConsumerState<ReceptionHomeScreen> createState() =>
      _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState
    extends ConsumerState<ReceptionHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.hotel,            label: l.rooms,         screen: const RoomsGridScreen()),
      (icon: Icons.confirmation_num, label: l.myTickets,     screen: const TicketsListScreen()),
      (icon: Icons.room_service,     label: 'בקשות אורחים', screen: const GuestRequestsListScreen()),
      (icon: Icons.person,           label: l.profile,       screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `manager_home.dart`**

Replace entire file content:

```dart
// lib/features/home/presentation/manager_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_feedback_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});
  @override
  ConsumerState<ManagerHomeScreen> createState() =>
      _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.dashboard,    label: 'דשבורד',    screen: const _ManagerDashboard()),
      (icon: Icons.room_service, label: 'בקשות',     screen: const GuestRequestsListScreen()),
      (icon: Icons.star,         label: 'משובים',    screen: const GuestFeedbackScreen()),
      (icon: Icons.bar_chart,    label: l.analytics, screen: const AnalyticsScreen()),
      (icon: Icons.people,       label: l.users,     screen: const UsersScreen()),
      (icon: Icons.person,       label: l.profile,   screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _ManagerDashboard extends ConsumerWidget {
  const _ManagerDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(managerKpisProvider);
    return kpis.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (k) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 52),
            Text('דשבורד מנהל',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _KpiCard(label: 'קריאות פתוחות',    value: k.openTickets,       color: Colors.blue),
                _KpiCard(label: 'בטיפול',            value: k.inProgressTickets, color: Colors.orange),
                _KpiCard(label: 'חריגות SLA',        value: k.overdueTickets,    color: Colors.red),
                _KpiCard(label: 'אוטומציות פעילות', value: k.activeAutomations, color: Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: Card(
          color: color.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
```

- [ ] **Step 3: Update `housekeeping_staff_screen.dart`**

Add import after existing imports:

```dart
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';
```

In `_HousekeepingStaffScreenState.build`, replace the `tabs` list:

```dart
final tabs = [
  (icon: Icons.cleaning_services, label: 'החדרים שלי', screen: const _StaffRoomList()),
  (icon: Icons.room_service,      label: 'בקשות',      screen: const StaffRequestsScreen()),
  (icon: Icons.person,            label: 'פרופיל',     screen: const ProfileScreen()),
];
```

- [ ] **Step 4: Update `maintenance_home.dart`**

Add import after existing imports:

```dart
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';
```

In `_MaintenanceHomeScreenState.build`, replace the `tabs` list:

```dart
final tabs = [
  (icon: Icons.queue,        label: 'קריאות',  screen: const _MaintenanceQueue()),
  (icon: Icons.room_service, label: 'בקשות',   screen: const StaffRequestsScreen()),
  (icon: Icons.person,       label: l.profile, screen: const ProfileScreen()),
];
```

- [ ] **Step 5: Run all tests**

```bash
flutter test -v
```

Expected: All tests pass (no regressions).

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/reception_home.dart \
        lib/features/home/presentation/manager_home.dart \
        lib/features/housekeeping/presentation/housekeeping_staff_screen.dart \
        lib/features/home/presentation/maintenance_home.dart
git commit -m "feat: wire guest request tabs into reception, manager, housekeeping, maintenance screens"
```
