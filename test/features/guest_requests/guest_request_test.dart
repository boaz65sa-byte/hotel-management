// test/features/guest_requests/guest_request_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_request_card.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';

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
}
