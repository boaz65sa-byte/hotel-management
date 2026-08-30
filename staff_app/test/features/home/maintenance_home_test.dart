import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

void main() {
  test('Ticket fromJson parses maintenance ticket', () {
    final json = {
      'id': 't1', 'hotel_id': 'h1', 'room_id': 'r1',
      'opened_by': 'u1', 'assigned_dept': 'maintenance',
      'title': 'AC broken', 'priority': 'high', 'status': 'open',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };
    final ticket = Ticket.fromJson(json);
    expect(ticket.assignedDept, 'maintenance');
  });
}
