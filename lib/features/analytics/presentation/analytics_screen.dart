// lib/features/analytics/presentation/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = AnalyticsRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportExcel(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // KPI Cards
          FutureBuilder<TicketStats>(
            future: repo.fetchStats(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final s = snap.data!;
              return Row(children: [
                _kpi('Open', s.totalOpen.toString(), Colors.orange),
                _kpi('Resolved', s.totalResolved.toString(), Colors.green),
                _kpi('Avg Close', '${s.avgCloseHours.toStringAsFixed(1)}h', Colors.blue),
                _kpi('SLA', '${s.slaCompliancePct.toStringAsFixed(0)}%',
                  s.slaCompliancePct >= 80 ? Colors.green : Colors.red),
              ]);
            },
          ),
          const SizedBox(height: 24),
          // Daily chart
          Text('Tickets per day (30d)', style: Theme.of(context).textTheme.titleSmall),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<DailyCount>>(
              future: repo.fetchDailyCounts(days: 30),
              builder: (_, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final data = snap.data!;
                return BarChart(BarChartData(
                  barGroups: data.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: e.value.count.toDouble(),
                        color: Theme.of(context).colorScheme.primary, width: 8),
                    ])).toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                ));
              },
            ),
          ),
          const SizedBox(height: 24),
          // Top rooms
          Text('Most Reported Rooms', style: Theme.of(context).textTheme.titleSmall),
          FutureBuilder<List<RoomStats>>(
            future: repo.fetchRoomStats(),
            builder: (_, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Column(
                children: snap.data!.map((r) => ListTile(
                  leading: const Icon(Icons.hotel),
                  title: Text('Room ${r.roomNumber}'),
                  trailing: Text('${r.ticketCount} tickets'),
                )).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final session = supabase.auth.currentSession;
    if (session == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing export...')));

    final workbook = Excel.createExcel();
    final sheet = workbook.sheets[workbook.getDefaultSheet()!]!;
    sheet.appendRow([
      TextCellValue('ID'), TextCellValue('Room'), TextCellValue('Dept'),
      TextCellValue('Title'), TextCellValue('Status'), TextCellValue('Created'),
    ]);

    final bytes = workbook.encode();
    if (bytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready')));
    }
  }
}
