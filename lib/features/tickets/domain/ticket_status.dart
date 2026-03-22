// lib/features/tickets/domain/ticket_status.dart
enum TicketStatus { open, inProgress, pendingApproval, resolved, closed }

enum UserRole {
  superAdmin, ceo, receptionManager, maintenanceManager,
  housekeepingManager, securityManager, deputyReception,
  receptionist, securityGuard, maintenanceTech, repairman;

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == _toCamel(s),
      orElse: () => UserRole.receptionist,
    );
  }

  static String _toCamel(String s) {
    final parts = s.split('_');
    return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  bool get canClaimAndUpdate => this != UserRole.receptionist;
  bool get canApproveRoomClose => [
    superAdmin, ceo, receptionManager, maintenanceManager,
    housekeepingManager, securityManager
  ].contains(this);
  bool get isManager => [
    superAdmin, ceo, receptionManager, maintenanceManager,
    housekeepingManager, securityManager
  ].contains(this);
  bool get isRequiredApprover =>
    this == UserRole.receptionManager || this == UserRole.maintenanceManager;
}
