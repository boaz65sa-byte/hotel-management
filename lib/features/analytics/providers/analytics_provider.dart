// lib/features/analytics/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

final _repo = AnalyticsRepository();

// ── Time range ────────────────────────────────────────────────────────────────

final analyticsRangeProvider = StateProvider<AnalyticsRange>(
  (ref) => AnalyticsRange.last7(),
);

// ── Hotel-wide stats (managers+) ──────────────────────────────────────────────

final ticketStatsProvider = FutureProvider<TicketStats>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return _repo.fetchStats(from: range.from, to: range.to);
});

final dailyCountsProvider = FutureProvider<List<DailyCount>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return _repo.fetchDailyCounts(from: range.from, to: range.to);
});

final departmentStatsProvider = FutureProvider<List<DepartmentStats>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return _repo.fetchDepartmentStats(from: range.from, to: range.to);
});

final techStatsProvider = FutureProvider<List<TechStats>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return _repo.fetchTechStats(from: range.from, to: range.to);
});

final roomStatsProvider = FutureProvider<List<RoomStats>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  return _repo.fetchRoomStats(from: range.from, to: range.to);
});

// ── Personal stats (non-manager users) ───────────────────────────────────────

final myStatsProvider = FutureProvider<MyStats>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Future.value(const MyStats(
      handled: 0,
      open: 0,
      avgCloseHours: 0,
      slaCompliancePct: 100,
    ));
  }
  return _repo.fetchMyStats(user.id, from: range.from, to: range.to);
});
