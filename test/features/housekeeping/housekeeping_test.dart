// test/features/housekeeping/housekeeping_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_manager_screen.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_staff_screen.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

Room _makeRoom({
  String id = 'r1',
  String roomNumber = '101',
  int? floor = 2,
  String housekeepingStatus = 'dirty',
  String? assignedTo,
  String? assignedToName,
}) =>
    Room(
      id: id,
      hotelId: 'h1',
      roomNumber: roomNumber,
      floor: floor,
      status: 'available',
      housekeepingStatus: housekeepingStatus,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      createdAt: DateTime(2026),
    );

void main() {
  group('Room model', () {
    test('fromJson parses assignedTo and assignedToName', () {
      final json = {
        'id': 'r1',
        'hotel_id': 'h1',
        'room_number': '101',
        'floor': 1,
        'room_type': 'standard',
        'status': 'available',
        'notes': null,
        'housekeeping_status': 'dirty',
        'assigned_to': 'user-uuid-123',
        'assigned_to_name': 'Dana Cohen',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, 'user-uuid-123');
      expect(room.assignedToName, 'Dana Cohen');
    });

    test('fromJson defaults assignedTo to null when absent', () {
      final json = {
        'id': 'r2',
        'hotel_id': 'h1',
        'room_number': '102',
        'status': 'available',
        'housekeeping_status': 'clean',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, isNull);
      expect(room.assignedToName, isNull);
    });
  });

  group('HousekeepingManagerScreen', () {
    testWidgets('shows summary counts from stream data', (tester) async {
      final rooms = [
        _makeRoom(id: 'r1', roomNumber: '101', housekeepingStatus: 'dirty'),
        _makeRoom(id: 'r2', roomNumber: '102', housekeepingStatus: 'cleaning'),
        _makeRoom(id: 'r3', roomNumber: '103', housekeepingStatus: 'dirty'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allHousekeepingRoomsProvider.overrideWith((_) => Stream.value(rooms)),
            housekeepingStaffProvider.overrideWith((_) async => []),
          ],
          child: const MaterialApp(home: HousekeepingManagerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 מלוכלכים'), findsOneWidget);
      expect(find.text('1 בניקיון'), findsOneWidget);
      expect(find.text('0 נקיים'), findsOneWidget);
    });

    testWidgets('shows room card with assignedToName', (tester) async {
      final rooms = [
        _makeRoom(id: 'r1', roomNumber: '205', assignedToName: 'Dana Cohen'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allHousekeepingRoomsProvider.overrideWith((_) => Stream.value(rooms)),
            housekeepingStaffProvider.overrideWith((_) async => []),
          ],
          child: const MaterialApp(home: HousekeepingManagerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('חדר 205'), findsOneWidget);
      expect(find.text('Dana Cohen'), findsOneWidget);
    });

    testWidgets('shows לא מוקצה when room has no assignee', (tester) async {
      final rooms = [_makeRoom(id: 'r1', roomNumber: '101')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allHousekeepingRoomsProvider.overrideWith((_) => Stream.value(rooms)),
            housekeepingStaffProvider.overrideWith((_) async => []),
          ],
          child: const MaterialApp(home: HousekeepingManagerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('לא מוקצה'), findsOneWidget);
    });
  });

  group('HousekeepingStaffScreen', () {
    testWidgets('shows empty state when no rooms assigned', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myAssignedRoomsProvider.overrideWith((_) => Stream.value([])),
          ],
          child: const MaterialApp(home: HousekeepingStaffScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('אין חדרים להיום ✅'), findsOneWidget);
    });

    testWidgets('shows assigned room with התחל button when dirty', (tester) async {
      final rooms = [_makeRoom(id: 'r1', roomNumber: '303', housekeepingStatus: 'dirty')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myAssignedRoomsProvider.overrideWith((_) => Stream.value(rooms)),
          ],
          child: const MaterialApp(home: HousekeepingStaffScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('חדר 303'), findsOneWidget);
      expect(find.text('התחל'), findsOneWidget);
    });

    testWidgets('shows המשך button when room is cleaning', (tester) async {
      final rooms = [_makeRoom(id: 'r1', roomNumber: '404', housekeepingStatus: 'cleaning')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myAssignedRoomsProvider.overrideWith((_) => Stream.value(rooms)),
          ],
          child: const MaterialApp(home: HousekeepingStaffScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('חדר 404'), findsOneWidget);
      expect(find.text('המשך'), findsOneWidget);
    });
  });
}
