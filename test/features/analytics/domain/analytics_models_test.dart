// test/features/analytics/domain/analytics_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/analytics/domain/analytics_models.dart';

void main() {
  test('TicketStats holds correct values', () {
    const stats = TicketStats(
      totalOpen: 5, totalResolved: 20,
      avgCloseHours: 3.5, slaCompliancePct: 85.0,
    );
    expect(stats.totalOpen, 5);
    expect(stats.slaCompliancePct, 85.0);
  });
}
