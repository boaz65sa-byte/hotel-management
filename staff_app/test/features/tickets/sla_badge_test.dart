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
