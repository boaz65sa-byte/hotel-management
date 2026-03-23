// lib/features/analytics/domain/analytics_models.dart
class TicketStats {
  final int totalOpen;
  final int totalResolved;
  final double avgCloseHours;
  final double slaCompliancePct;

  const TicketStats({
    required this.totalOpen,
    required this.totalResolved,
    required this.avgCloseHours,
    required this.slaCompliancePct,
  });
}

class DailyCount {
  final DateTime date;
  final int count;
  const DailyCount({required this.date, required this.count});
}

class TechStats {
  final String techName;
  final int handled;
  final double avgHours;
  const TechStats({required this.techName, required this.handled, required this.avgHours});
}

class RoomStats {
  final String roomNumber;
  final int ticketCount;
  const RoomStats({required this.roomNumber, required this.ticketCount});
}
