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

  test('isOverSla is true when sla_deadline is in the past and not resolved', () {
    final t = Ticket.fromJson({
      'id': 'abc', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'claimed_by': null, 'title': 'Broken AC',
      'description': null, 'priority': 'high',
      'status': 'open', 'resolution_type': null,
      'sla_deadline': '2020-01-01T00:00:00Z',  // far in the past
      'created_at': '2026-03-22T10:00:00Z',
      'updated_at': '2026-03-22T10:00:00Z',
      'resolved_at': null,
    });
    expect(t.isOverSla, true);
  });

  test('UserRole.fromString converts snake_case to camelCase', () {
    expect(UserRole.fromString('housekeeping_manager'), UserRole.housekeepingManager);
    expect(UserRole.fromString('maintenance_tech'), UserRole.maintenanceTech);
    expect(UserRole.fromString('receptionist'), UserRole.receptionist);
  });

  test('Ticket.fromJson parses nested joined fields', () {
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
      'room': {'room_number': '101', 'floor': 1},
      'opener': {'full_name': 'Alice'},
      'claimer': null,
    });
    expect(t.roomNumber, '101');
    expect(t.openerName, 'Alice');
    expect(t.claimerName, isNull);
  });
}
