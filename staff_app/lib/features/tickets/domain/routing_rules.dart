// lib/features/tickets/domain/routing_rules.dart
import 'ticket_status.dart';

// Per spec Section 6: managers (all 5) + CEO + superAdmin can route to any dept.
// housekeepingManager: maintenance only (intentional — security issues escalate via reception).
const Map<UserRole, List<String>> deptRoutingRules = {
  UserRole.receptionist:        ['maintenance', 'housekeeping', 'security'],
  UserRole.deputyReception:     ['maintenance', 'housekeeping', 'security'],
  UserRole.receptionManager:    ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.housekeepingManager: ['maintenance'],  // intentional per spec
  UserRole.maintenanceTech:     ['security'],
  UserRole.repairman:           ['security'],
  UserRole.maintenanceManager:  ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.securityGuard:       ['maintenance', 'reception'],
  UserRole.securityManager:     ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.ceo:                 ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.hotelAdmin:          ['maintenance', 'housekeeping', 'security', 'reception'],
  UserRole.superAdmin:          ['maintenance', 'housekeeping', 'security', 'reception'],
};

List<String> allowedDepts(UserRole role) =>
  deptRoutingRules[role] ?? ['maintenance'];
