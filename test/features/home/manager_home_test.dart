import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';

void main() {
  test('ManagerKpis holds correct counts', () {
    const kpis = ManagerKpis(openTickets: 5, inProgressTickets: 3, overdueTickets: 1);
    expect(kpis.openTickets, 5);
    expect(kpis.overdueTickets, 1);
  });
}
