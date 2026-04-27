// lib/features/analytics/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(),
);

// ── Time range ────────────────────────────────────────────────────────────────

final analyticsRangeProvider = StateProvider<AnalyticsRange>(
  (ref) => AnalyticsRange.last7(),
);

// ── Hotel-wide stats (managers+) ──────────────────────────────────────────────

final ticketStatsProvider = FutureProvider<TicketStats>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.fetchStats(from: range.from, to: range.to);
});

final dailyCountsProvider = FutureProvider<List<DailyCount>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.fetchDailyCounts(from: range.from, to: range.to);
});

final departmentStatsProvider = FutureProvider<List<DepartmentStats>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.fetchDepartmentStats(from: range.from, to: range.to);
});

final techStatsProvider = FutureProvider<List<TechStats>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.fetchTechStats(from: range.from, to: range.to);
});

final roomStatsProvider = FutureProvider<List<RoomStats>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.fetchRoomStats(from: range.from, to: range.to);
});

// ── Personal stats (non-manager users) ───────────────────────────────────────

final myStatsProvider = FutureProvider<MyStats>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
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
  return repo.fetchMyStats(user.id, from: range.from, to: range.to);
});
