// lib/features/tickets/domain/ticket_status.dart
enum TicketStatus { open, inProgress, pendingApproval, resolved, closed }

enum UserRole {
  superAdmin, ceo, receptionManager, maintenanceManager,
  housekeepingManager, securityManager, deputyReception,
  receptionist, securityGuard, maintenanceTech, repairman;

  static UserRole fromString(String s) {
    final camel = _toCamel(s);
    final match = UserRole.values.where((r) => r.name == camel).firstOrNull;
    assert(match != null, 'Unknown role string: $s');
    return match ?? UserRole.receptionist;
  }

  static String _toCamel(String s) {
    final parts = s.split('_');
    return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  static const _managerRoles = [
    superAdmin, ceo, receptionManager, maintenanceManager,
    housekeepingManager, securityManager,
  ];

  bool get canClaimAndUpdate => this != UserRole.receptionist;
  bool get canApproveRoomClose => _managerRoles.contains(this);
  bool get isManager => _managerRoles.contains(this);
  bool get isRequiredApprover =>
    this == UserRole.receptionManager || this == UserRole.maintenanceManager;
}
