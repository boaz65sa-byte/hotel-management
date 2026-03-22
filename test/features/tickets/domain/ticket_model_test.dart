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
