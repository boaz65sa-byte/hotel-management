import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';

void main() {
  test('maintenance roles route to maintenance', () {
    expect(UserRole.maintenanceTech.homeScreen, 'maintenance');
    expect(UserRole.repairman.homeScreen, 'maintenance');
    expect(UserRole.maintenanceManager.homeScreen, 'maintenance');
  });
  test('housekeeping routes to housekeeping', () {
    expect(UserRole.housekeepingManager.homeScreen, 'housekeeping');
  });
  test('manager roles route to manager', () {
    expect(UserRole.ceo.homeScreen, 'manager');
    expect(UserRole.superAdmin.homeScreen, 'manager');
  });
  test('reception/security routes to reception', () {
    expect(UserRole.receptionist.homeScreen, 'reception');
    expect(UserRole.securityGuard.homeScreen, 'reception');
    expect(UserRole.receptionManager.homeScreen, 'reception');
  });
}
