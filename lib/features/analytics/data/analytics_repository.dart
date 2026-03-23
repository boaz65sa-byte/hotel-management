// lib/features/analytics/data/analytics_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  Future<TicketStats> fetchStats({DateTime? from, DateTime? to}) async {
    var query = supabase.from('tickets').select(
      'id, status, sla_deadline, resolved_at, created_at');

    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to   != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final open = rows.where((r) => !['resolved','closed'].contains(r['status'])).length;
    final resolved = rows.where((r) => ['resolved','closed'].contains(r['status'])).length;

    final closedWithTimes = rows.where((r) =>
      r['resolved_at'] != null && r['created_at'] != null).toList();
    final avgClose = closedWithTimes.isEmpty ? 0.0 :
      closedWithTimes.map((r) {
        final diff = DateTime.parse(r['resolved_at']).difference(DateTime.parse(r['created_at']));
        return diff.inMinutes / 60.0;
      }).reduce((a, b) => a + b) / closedWithTimes.length;

    final withSla = rows.where((r) => r['sla_deadline'] != null && r['resolved_at'] != null);
    final slaOk = withSla.where((r) =>
      DateTime.parse(r['resolved_at']).isBefore(DateTime.parse(r['sla_deadline']))).length;
    final slaPct = withSla.isEmpty ? 100.0 : slaOk / withSla.length * 100;

    return TicketStats(
      totalOpen: open,
      totalResolved: resolved,
      avgCloseHours: avgClose,
      slaCompliancePct: slaPct,
    );
  }

  Future<List<DailyCount>> fetchDailyCounts({required int days}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final rows = await supabase
      .from('tickets')
      .select('created_at')
      .gte('created_at', from.toIso8601String());

    final map = <String, int>{};
    for (final r in rows as List) {
      final day = DateTime.parse(r['created_at']).toLocal().toString().substring(0, 10);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map.entries
      .map((e) => DailyCount(date: DateTime.parse(e.key), count: e.value))
      .toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TechStats>> fetchTechStats() async {
    final rows = await supabase
      .from('tickets')
      .select('claimed_by, resolved_at, created_at, claimer:users!tickets_claimed_by_fkey(full_name)')
      .not('claimed_by', 'is', null);

    final map = <String, List<Map>>{}; // tech_id → tickets
    for (final r in rows as List) {
      final id = r['claimed_by'] as String;
      map.putIfAbsent(id, () => []).add(r);
    }

    return map.entries.map((e) {
      final name = (e.value.first['claimer']?['full_name'] as String?) ?? e.key;
      final withTime = e.value.where((r) => r['resolved_at'] != null && r['created_at'] != null);
      final avg = withTime.isEmpty ? 0.0 :
        withTime.map((r) {
          return DateTime.parse(r['resolved_at']).difference(
            DateTime.parse(r['created_at'])).inMinutes / 60.0;
        }).reduce((a, b) => a + b) / withTime.length;
      return TechStats(techName: name, handled: e.value.length, avgHours: avg);
    }).toList()..sort((a, b) => b.handled.compareTo(a.handled));
  }

  Future<List<RoomStats>> fetchRoomStats({int limit = 10}) async {
    final rows = await supabase.from('tickets').select('room:rooms(room_number)');
    final map = <String, int>{};
    for (final r in rows as List) {
      final rn = r['room']?['room_number'] as String? ?? '?';
      map[rn] = (map[rn] ?? 0) + 1;
    }
    final list = map.entries.map((e) =>
      RoomStats(roomNumber: e.key, ticketCount: e.value)).toList()
      ..sort((a, b) => b.ticketCount.compareTo(a.ticketCount));
    return list.take(limit).toList();
  }
}
