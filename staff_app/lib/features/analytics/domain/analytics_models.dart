// lib/features/analytics/domain/analytics_models.dart

class AnalyticsRange {
  final DateTime from;
  final DateTime to;

  const AnalyticsRange({required this.from, required this.to});

  static AnalyticsRange today() {
    final now = DateTime.now();
    return AnalyticsRange(
      from: DateTime(now.year, now.month, now.day),
      to: now,
    );
  }

  static AnalyticsRange last7() {
    final now = DateTime.now();
    return AnalyticsRange(
      from: now.subtract(const Duration(days: 7)),
      to: now,
    );
  }

  static AnalyticsRange last30() {
    final now = DateTime.now();
    return AnalyticsRange(
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
  }
}

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
  const TechStats({
    required this.techName,
    required this.handled,
    required this.avgHours,
  });
}

class RoomStats {
  final String roomNumber;
  final int ticketCount;
  const RoomStats({required this.roomNumber, required this.ticketCount});
}

class DepartmentStats {
  final String department;
  final int count;
  final double pct;
  const DepartmentStats({
    required this.department,
    required this.count,
    required this.pct,
  });
}

class MyStats {
  final int handled;
  final int open;
  final double avgCloseHours;
  final double slaCompliancePct;

  const MyStats({
    required this.handled,
    required this.open,
    required this.avgCloseHours,
    required this.slaCompliancePct,
  });
}
