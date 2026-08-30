// lib/features/tickets/domain/routing_rules.dart
import 'ticket_status.dart';

// Per spec Section 6: managers (all 5) + CEO + superAdmin can route to any dept.
// housekeepingManager: maintenance only (intentional — security issues escalate via reception).
const Map<UserRole, List<String>> deptRoutingRules = {
  UserRole.receptionist:        ['maintenance', 'housekeeping', 'security', 'kitchen'],
  UserRole.deputyReception:     ['maintenance', 'housekeeping', 'security', 'kitchen'],
  UserRole.receptionManager:    ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.housekeepingManager: ['maintenance'],  // intentional per spec
  UserRole.maintenanceTech:     ['security'],
  UserRole.repairman:           ['security'],
  UserRole.maintenanceManager:  ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.securityGuard:       ['maintenance', 'reception'],
  UserRole.securityManager:     ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.kitchenManager:      ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.ceo:                 ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.hotelAdmin:          ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
  UserRole.superAdmin:          ['maintenance', 'housekeeping', 'security', 'reception', 'kitchen'],
};

List<String> allowedDepts(UserRole role) =>
  deptRoutingRules[role] ?? ['maintenance'];
