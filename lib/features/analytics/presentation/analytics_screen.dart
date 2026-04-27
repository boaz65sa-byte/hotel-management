// lib/features/analytics/presentation/analytics_screen.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';
import '../providers/analytics_provider.dart';

// Roles that see hotel-wide data and manager-only sections
const _managerRoles = {
  'reception_manager',
  'maintenance_manager',
  'hotel_admin',
  'super_admin',
};

bool _isManager(String? role) => _managerRoles.contains(role);

// ── Screen ────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.read(authRepositoryProvider).role;
    final isManager = _isManager(role);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role ?? 'staff',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer),
              ),
            ),
          ],
        ),
        actions: [
          if (isManager)
            IconButton(
              icon: Icon(Icons.download_rounded, color: cs.primary),
              tooltip: 'Export Excel',
              onPressed: () => _exportExcel(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          _TimeRangeChips(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KpiRow(isManager: isManager),
                  const SizedBox(height: 12),
                  _DailyChartSection(isManager: isManager),
                  if (isManager) ...[
                    const SizedBox(height: 8),
                    _DepartmentSection(),
                    const SizedBox(height: 8),
                    _StaffSection(),
                  ],
                  const SizedBox(height: 8),
                  _RoomSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final range = ref.read(analyticsRangeProvider);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('מכין ייצוא...')));

    try {
      final rows =
          await AnalyticsRepository().fetchTicketsForExport(from: range.from, to: range.to);

      final workbook = Excel.createExcel();
      final sheet = workbook.sheets[workbook.getDefaultSheet()!]!;

      // Header row
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Room'),
        TextCellValue('Department'),
        TextCellValue('Title'),
        TextCellValue('Priority'),
        TextCellValue('Status'),
        TextCellValue('Created'),
        TextCellValue('Resolved'),
      ]);

      for (final r in rows) {
        sheet.appendRow([
          TextCellValue(r['id']?.toString() ?? ''),
          TextCellValue(r['room']?['room_number']?.toString() ?? ''),
          TextCellValue(r['department']?.toString() ?? ''),
          TextCellValue(r['title']?.toString() ?? ''),
          TextCellValue(r['priority']?.toString() ?? ''),
          TextCellValue(r['status']?.toString() ?? ''),
          TextCellValue(r['created_at']?.toString() ?? ''),
          TextCellValue(r['resolved_at']?.toString() ?? ''),
        ]);
      }

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tickets_export.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Tickets Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    }
  }
}

// ── Time range chips ──────────────────────────────────────────────────────────

class _TimeRangeChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final range = ref.watch(analyticsRangeProvider);

    // Determine active label by comparing from date (approximation)
    final now = DateTime.now();
    final diffDays = now.difference(range.from).inDays;
    String active;
    if (diffDays == 0) {
      active = 'היום';
    } else if (diffDays <= 7) {
      active = '7';
    } else if (diffDays <= 30) {
      active = '30';
    } else {
      active = 'custom';
    }

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(context, ref, label: 'היום', key: 'היום', active: active,
              range: AnalyticsRange.today()),
          const SizedBox(width: 6),
          _chip(context, ref, label: '7 ימים', key: '7', active: active,
              range: AnalyticsRange.last7()),
          const SizedBox(width: 6),
          _chip(context, ref, label: 'חודש', key: '30', active: active,
              range: AnalyticsRange.last30()),
          const Spacer(),
          _customChip(context, ref, active: active),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, WidgetRef ref,
      {required String label,
      required String key,
      required String active,
      required AnalyticsRange range}) {
    final cs = Theme.of(context).colorScheme;
    final isActive = active == key;
    return GestureDetector(
      onTap: () => ref.read(analyticsRangeProvider.notifier).state = range,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : Colors.transparent,
          border: Border.all(
              color: isActive ? cs.primary : cs.outline.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _customChip(BuildContext context, WidgetRef ref,
      {required String active}) {
    final cs = Theme.of(context).colorScheme;
    final isActive = active == 'custom';
    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
          builder: (context, child) => Theme(
            data: Theme.of(context),
            child: child!,
          ),
        );
        if (picked != null) {
          ref.read(analyticsRangeProvider.notifier).state =
              AnalyticsRange(from: picked.start, to: picked.end);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : Colors.transparent,
          border: Border.all(
              color: isActive
                  ? cs.primary
                  : cs.primary.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 14,
                color: isActive ? cs.onPrimaryContainer : cs.primary),
            const SizedBox(width: 4),
            Text(
              'Custom',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? cs.onPrimaryContainer : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends ConsumerWidget {
  final bool isManager;
  const _KpiRow({required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isManager) {
      final statsAsync = ref.watch(ticketStatsProvider);
      return statsAsync.when(
        loading: () => const _KpiSkeleton(),
        error: (e, _) => Text('שגיאה: $e'),
        data: (s) => _KpiCards(
          open: s.totalOpen,
          resolved: s.totalResolved,
          avgHours: s.avgCloseHours,
          slaPct: s.slaCompliancePct,
        ),
      );
    } else {
      final myAsync = ref.watch(myStatsProvider);
      return myAsync.when(
        loading: () => const _KpiSkeleton(),
        error: (e, _) => Text('שגיאה: $e'),
        data: (s) => _KpiCards(
          open: s.open,
          resolved: s.handled,
          avgHours: s.avgCloseHours,
          slaPct: s.slaCompliancePct,
        ),
      );
    }
  }
}

class _KpiCards extends StatelessWidget {
  final int open;
  final int resolved;
  final double avgHours;
  final double slaPct;

  const _KpiCards({
    required this.open,
    required this.resolved,
    required this.avgHours,
    required this.slaPct,
  });

  @override
  Widget build(BuildContext context) {
    final slaColor = slaPct >= 80 ? const Color(0xFF4ade80) : const Color(0xFFf87171);
    return Row(
      children: [
        _KpiCard(label: 'פתוחות', value: open.toString(), color: const Color(0xFFfb923c)),
        const SizedBox(width: 8),
        _KpiCard(label: 'נסגרו', value: resolved.toString(), color: const Color(0xFF4ade80)),
        const SizedBox(width: 8),
        _KpiCard(label: 'ממוצע', value: '${avgHours.toStringAsFixed(1)}h', color: const Color(0xFF60a5fa)),
        const SizedBox(width: 8),
        _KpiCard(label: 'SLA', value: '${slaPct.toStringAsFixed(0)}%', color: slaColor),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SizedBox(height: 60)),
        SizedBox(width: 8),
        Expanded(child: SizedBox(height: 60)),
        SizedBox(width: 8),
        Expanded(child: SizedBox(height: 60)),
        SizedBox(width: 8),
        Expanded(child: SizedBox(height: 60)),
      ],
    );
  }
}

// ── Section base ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;
  final bool managerOnly;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.managerOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            if (managerOnly) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('מנהל',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer)),
              ),
            ],
          ],
        ),
        children: [child],
      ),
    );
  }
}

// ── Daily Chart Section ───────────────────────────────────────────────────────

class _DailyChartSection extends ConsumerWidget {
  final bool isManager;
  const _DailyChartSection({required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(dailyCountsProvider);
    return _Section(
      title: 'קריאות לפי יום',
      icon: '📈',
      child: countsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('שגיאה: $e'),
        data: (counts) {
          if (counts.isEmpty) {
            return const Text('אין נתונים לתקופה זו',
                style: TextStyle(color: Colors.grey));
          }
          final maxY =
              counts.map((c) => c.count.toDouble()).reduce((a, b) => a > b ? a : b);
          final cs = Theme.of(context).colorScheme;
          return SizedBox(
            height: 140,
            child: BarChart(BarChartData(
              maxY: maxY + 1,
              barGroups: counts.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    color: cs.primary,
                    width: counts.length <= 10 ? 16 : 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: cs.outline.withOpacity(0.15), strokeWidth: 1),
              ),
            )),
          );
        },
      ),
    );
  }
}

// ── Department Section ────────────────────────────────────────────────────────

class _DepartmentSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptAsync = ref.watch(departmentStatsProvider);
    const colors = [Color(0xFFc9a84c), Color(0xFF60a5fa), Color(0xFF4ade80), Color(0xFFfb923c)];
    return _Section(
      title: 'פילוח מחלקות',
      icon: '🏢',
      managerOnly: true,
      child: deptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('שגיאה: $e'),
        data: (depts) {
          if (depts.isEmpty) return const Text('אין נתונים', style: TextStyle(color: Colors.grey));
          return Column(
            children: depts.asMap().entries.map((e) {
              final color = colors[e.key % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(e.value.department,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value.pct / 100,
                          backgroundColor:
                              Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text('${e.value.pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ── Staff Section ─────────────────────────────────────────────────────────────

class _StaffSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techAsync = ref.watch(techStatsProvider);
    return _Section(
      title: 'ביצועי צוות',
      icon: '👷',
      managerOnly: true,
      child: techAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('שגיאה: $e'),
        data: (techs) {
          if (techs.isEmpty) return const Text('אין נתונים', style: TextStyle(color: Colors.grey));
          final cs = Theme.of(context).colorScheme;
          return Column(
            children: techs.take(5).map((t) {
              final initials = t.techName.isNotEmpty
                  ? t.techName.trim().split(' ').map((w) => w[0]).take(2).join()
                  : '?';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primaryContainer,
                      child: Text(initials,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.techName,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('avg ${t.avgHours.toStringAsFixed(1)}h',
                              style: TextStyle(
                                  fontSize: 10, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Text('${t.handled}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4ade80))),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ── Room Section ──────────────────────────────────────────────────────────────

class _RoomSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomStatsProvider);
    return _Section(
      title: 'חדרים בעייתיים',
      icon: '🚨',
      child: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('שגיאה: $e'),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Text('אין נתונים', style: TextStyle(color: Colors.grey));
          }
          final max = rooms.first.ticketCount.toDouble();
          final cs = Theme.of(context).colorScheme;
          return Column(
            children: rooms.take(8).map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.outline.withOpacity(0.3)),
                      ),
                      child: Text('חדר ${r.roomNumber}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.ticketCount / max,
                          backgroundColor:
                              cs.outline.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFfb923c)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${r.ticketCount}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFfb923c))),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
