# Analytics Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing analytics skeleton with a fully functional, role-based, Navy-themed analytics dashboard with time range filtering, expandable sections, and real Excel export.

**Architecture:** Four files to create/modify. Models and repository are extended first, then a new providers file wires Riverpod, and finally the screen is fully rewritten to consume those providers with role-based section visibility.

**Tech Stack:** Flutter + Riverpod (manual providers) + fl_chart + excel + share_plus + path_provider + Supabase

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | Modify | Add share_plus, path_provider |
| `lib/features/analytics/domain/analytics_models.dart` | Modify | Add `AnalyticsRange`, `DepartmentStats`, `MyStats` |
| `lib/features/analytics/data/analytics_repository.dart` | Modify | Add `fetchDepartmentStats`, `fetchMyStats`; update `fetchDailyCounts` to accept from/to |
| `lib/features/analytics/providers/analytics_provider.dart` | Create | All Riverpod providers |
| `lib/features/analytics/presentation/analytics_screen.dart` | Rewrite | Navy UI, expandable sections, role-based visibility |

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add share_plus and path_provider to pubspec.yaml**

Find the `# Utilities` section and add the two packages:

```yaml
  share_plus: ^10.0.0
  path_provider: ^2.1.4
```

- [ ] **Step 2: Install packages**

```bash
flutter pub get
```

Expected output: ends with `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add share_plus and path_provider for analytics export"
```

---

## Task 2: Extend Domain Models

**Files:**
- Modify: `lib/features/analytics/domain/analytics_models.dart`

- [ ] **Step 1: Replace the file contents with the extended version**

```dart
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
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/analytics/domain/analytics_models.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/analytics/domain/analytics_models.dart
git commit -m "feat: extend analytics models — AnalyticsRange, DepartmentStats, MyStats"
```

---

## Task 3: Extend Repository

**Files:**
- Modify: `lib/features/analytics/data/analytics_repository.dart`

- [ ] **Step 1: Replace the file with the extended version**

```dart
// lib/features/analytics/data/analytics_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  Future<TicketStats> fetchStats({DateTime? from, DateTime? to}) async {
    var query = supabase.from('tickets').select(
        'id, status, sla_deadline, resolved_at, created_at');

    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final open = rows.where((r) => !['resolved', 'closed'].contains(r['status'])).length;
    final resolved = rows.where((r) => ['resolved', 'closed'].contains(r['status'])).length;

    final closedWithTimes = rows
        .where((r) => r['resolved_at'] != null && r['created_at'] != null)
        .toList();
    final avgClose = closedWithTimes.isEmpty
        ? 0.0
        : closedWithTimes.map((r) {
              final diff = DateTime.parse(r['resolved_at'])
                  .difference(DateTime.parse(r['created_at']));
              return diff.inMinutes / 60.0;
            }).reduce((a, b) => a + b) /
            closedWithTimes.length;

    final withSla =
        rows.where((r) => r['sla_deadline'] != null && r['resolved_at'] != null);
    final slaOk = withSla
        .where((r) => DateTime.parse(r['resolved_at'])
            .isBefore(DateTime.parse(r['sla_deadline'])))
        .length;
    final slaPct = withSla.isEmpty ? 100.0 : slaOk / withSla.length * 100;

    return TicketStats(
      totalOpen: open,
      totalResolved: resolved,
      avgCloseHours: avgClose,
      slaCompliancePct: slaPct,
    );
  }

  Future<List<DailyCount>> fetchDailyCounts({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await supabase
        .from('tickets')
        .select('created_at')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());

    final map = <String, int>{};
    for (final r in rows as List) {
      final day =
          DateTime.parse(r['created_at']).toLocal().toString().substring(0, 10);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map.entries
        .map((e) => DailyCount(date: DateTime.parse(e.key), count: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TechStats>> fetchTechStats({DateTime? from, DateTime? to}) async {
    var query = supabase.from('tickets').select(
        'claimed_by, resolved_at, created_at, claimer:users!tickets_claimed_by_fkey(full_name)').not('claimed_by', 'is', null);

    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final map = <String, List<Map>>{};
    for (final r in rows) {
      final id = r['claimed_by'] as String;
      map.putIfAbsent(id, () => []).add(r as Map);
    }

    return map.entries.map((e) {
      final name =
          (e.value.first['claimer']?['full_name'] as String?) ?? e.key;
      final withTime = e.value
          .where((r) => r['resolved_at'] != null && r['created_at'] != null);
      final avg = withTime.isEmpty
          ? 0.0
          : withTime
                  .map((r) => DateTime.parse(r['resolved_at'])
                      .difference(DateTime.parse(r['created_at']))
                      .inMinutes /
                      60.0)
                  .reduce((a, b) => a + b) /
              withTime.length;
      return TechStats(
          techName: name, handled: e.value.length, avgHours: avg);
    }).toList()
      ..sort((a, b) => b.handled.compareTo(a.handled));
  }

  Future<List<RoomStats>> fetchRoomStats({
    int limit = 10,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = supabase.from('tickets').select('room:rooms(room_number), created_at');
    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final map = <String, int>{};
    for (final r in rows) {
      final rn = r['room']?['room_number'] as String? ?? '?';
      map[rn] = (map[rn] ?? 0) + 1;
    }
    final list = map.entries
        .map((e) => RoomStats(roomNumber: e.key, ticketCount: e.value))
        .toList()
      ..sort((a, b) => b.ticketCount.compareTo(a.ticketCount));
    return list.take(limit).toList();
  }

  Future<List<DepartmentStats>> fetchDepartmentStats({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = supabase.from('tickets').select('department, created_at');
    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final map = <String, int>{};
    for (final r in rows) {
      final dept = (r['department'] as String?) ?? 'unknown';
      map[dept] = (map[dept] ?? 0) + 1;
    }
    final total = map.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];

    return map.entries
        .map((e) => DepartmentStats(
              department: e.key,
              count: e.value,
              pct: e.value / total * 100,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  Future<MyStats> fetchMyStats(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = supabase
        .from('tickets')
        .select('id, status, sla_deadline, resolved_at, created_at')
        .eq('claimed_by', userId);
    if (from != null) query = query.gte('created_at', from.toIso8601String()) as dynamic;
    if (to != null) query = query.lte('created_at', to.toIso8601String()) as dynamic;

    final rows = (await query) as List;
    final open =
        rows.where((r) => !['resolved', 'closed'].contains(r['status'])).length;
    final handled =
        rows.where((r) => ['resolved', 'closed'].contains(r['status'])).length;

    final closedWithTimes =
        rows.where((r) => r['resolved_at'] != null && r['created_at'] != null);
    final avgClose = closedWithTimes.isEmpty
        ? 0.0
        : closedWithTimes
                .map((r) => DateTime.parse(r['resolved_at'])
                    .difference(DateTime.parse(r['created_at']))
                    .inMinutes /
                    60.0)
                .reduce((a, b) => a + b) /
            closedWithTimes.length;

    final withSla =
        rows.where((r) => r['sla_deadline'] != null && r['resolved_at'] != null);
    final slaOk = withSla
        .where((r) => DateTime.parse(r['resolved_at'])
            .isBefore(DateTime.parse(r['sla_deadline'])))
        .length;
    final slaPct = withSla.isEmpty ? 100.0 : slaOk / withSla.length * 100;

    return MyStats(
      handled: handled,
      open: open,
      avgCloseHours: avgClose,
      slaCompliancePct: slaPct,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTicketsForExport({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await supabase
        .from('tickets')
        .select(
            'id, title, department, priority, status, created_at, resolved_at, claimed_by, room:rooms(room_number)')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String())
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/analytics/data/analytics_repository.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/analytics/data/analytics_repository.dart
git commit -m "feat: extend analytics repository — department/my stats, date range on all queries"
```

---

## Task 4: Create Riverpod Providers

**Files:**
- Create: `lib/features/analytics/providers/analytics_provider.dart`

- [ ] **Step 1: Create the providers file**

```dart
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
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/analytics/providers/analytics_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/analytics/providers/analytics_provider.dart
git commit -m "feat: analytics Riverpod providers — range, stats, dept, tech, rooms, myStats"
```

---

## Task 5: Rewrite Analytics Screen

**Files:**
- Modify: `lib/features/analytics/presentation/analytics_screen.dart`

- [ ] **Step 1: Replace the file with the full Navy-themed implementation**

```dart
// lib/features/analytics/presentation/analytics_screen.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_repository.dart';
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
    final cs = Theme.of(context).colorScheme;
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
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze lib/features/analytics/
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/analytics/presentation/analytics_screen.dart
git commit -m "feat: Analytics screen — Navy theme, role-based sections, time range, expandable"
```

---

## Task 6: Wire Analytics to Navigation

**Files:**
- Check: `lib/navigation/router.dart` — verify `/analytics` route exists

- [ ] **Step 1: Verify the route**

```bash
grep -n "analytics" lib/navigation/router.dart
```

If the route exists, skip to Step 3. If not, proceed to Step 2.

- [ ] **Step 2 (if missing): Add route**

Find the route list in `router.dart` and add:

```dart
GoRoute(
  path: '/analytics',
  builder: (context, state) => const AnalyticsScreen(),
),
```

And add the import at the top:
```dart
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
```

- [ ] **Step 3: Verify manager home shows analytics tab**

```bash
grep -n "analytics\|Analytics" lib/features/home/presentation/manager_home.dart
```

If missing, add an Analytics tab to `manager_home.dart`. Open the file and find the tabs list, then add:

```dart
(icon: Icons.bar_chart_rounded, label: 'Analytics', screen: const AnalyticsScreen()),
```

With the import:
```dart
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
```

- [ ] **Step 4: Run full analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/navigation/router.dart lib/features/home/presentation/manager_home.dart
git commit -m "feat: wire analytics screen to manager home and router"
```

---

## Task 7: Manual Test Checklist

- [ ] Run the app: `flutter run`
- [ ] Log in as `manager@hotel.com` / `Manager1234!`
- [ ] Navigate to Analytics tab
- [ ] Verify 4 KPI cards render with real data
- [ ] Tap "היום", "7 ימים", "חודש" — verify cards and chart update
- [ ] Tap "Custom" — verify date picker opens, selecting a range updates data
- [ ] Verify Department, Staff, and Room sections visible
- [ ] Collapse and expand each section
- [ ] Tap export button — verify share sheet opens with .xlsx file
- [ ] Log in as `tech@hotel.com` / `Tech1234!`
- [ ] Navigate to Analytics (if accessible for this role)
- [ ] Verify only own KPIs shown, Department/Staff sections hidden
- [ ] Run `flutter analyze` — confirm zero issues

- [ ] **Final commit if any fixes made**

```bash
git add -A
git commit -m "fix: analytics manual test fixes"
```
