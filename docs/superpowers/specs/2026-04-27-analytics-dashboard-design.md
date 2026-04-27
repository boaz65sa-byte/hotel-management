# Analytics Dashboard — Design Spec
**Date:** 2026-04-27
**Phase:** 9 — Module 1 of 5
**Status:** Approved

---

## Overview

A role-based analytics dashboard for hotel staff. Each user sees data relevant to their role; managers see full hotel-wide stats; admins control visibility permissions. Built on top of existing skeleton (`analytics_screen.dart`, `analytics_repository.dart`, `analytics_models.dart`).

---

## Role-Based Visibility

| Section | maintenance_tech / housekeeping | reception_manager / maintenance_manager | hotel_admin / super_admin |
|---|---|---|---|
| KPI Cards | own tickets only (via `myStatsProvider`) | hotel-wide (via `ticketStatsProvider`) | hotel-wide |
| Daily Chart | own | hotel-wide | hotel-wide |
| Department Breakdown | hidden | visible | visible |
| Staff Performance | hidden | visible | visible |
| Problem Rooms | hidden | visible | visible |
| Export button | hidden | visible | visible |

Visibility is derived from the JWT custom claims (`role` field). No separate API call needed.

Admin can override visibility per-role via a future settings screen (out of scope for this phase — architecture must accommodate it via a `analytics_permissions` table later).

---

## Time Range

Four options available in a chip row at the top:
- **היום** — today (00:00 → now)
- **7 ימים** — last 7 days
- **חודש** — last 30 days
- **📅 Custom** — opens a `DateRangePicker`, user selects start + end date

Selected range is held in a `analyticsRangeProvider` (`StateProvider<AnalyticsRange>`). All data providers watch this provider and re-fetch on change.

`AnalyticsRange` is a simple value class:
```dart
class AnalyticsRange {
  final DateTime from;
  final DateTime to;
  static AnalyticsRange last7() => ...
  static AnalyticsRange last30() => ...
  static AnalyticsRange today() => ...
}
```

---

## Data Model Additions

Add `DepartmentStats` to `analytics_models.dart`:

```dart
class DepartmentStats {
  final String department;
  final int count;
  final double pct;
}
```

Add `MyStats` (for non-manager users viewing own performance):

```dart
class MyStats {
  final int handled;
  final int open;
  final double avgCloseHours;
  final double slaCompliancePct;
}
```

---

## Riverpod Providers

Replace `FutureBuilder` pattern with proper Riverpod providers in `analytics_provider.dart`:

```
analyticsRangeProvider       — StateProvider<AnalyticsRange>
ticketStatsProvider          — FutureProvider, watches range
dailyCountsProvider          — FutureProvider, watches range
departmentStatsProvider      — FutureProvider, watches range
techStatsProvider            — FutureProvider, watches range
roomStatsProvider            — FutureProvider, watches range
myStatsProvider              — FutureProvider (current user only)
```

Each provider passes `from`/`to` DateTime from the active range to the repository.

---

## Repository Changes

Add `fetchDepartmentStats({DateTime? from, DateTime? to})` to `AnalyticsRepository`:
- Groups tickets by `department` column
- Returns list of `DepartmentStats` sorted by count descending

Add `fetchMyStats(String userId, {DateTime? from, DateTime? to})`:
- Filters by `claimed_by = userId`
- Returns `MyStats`

Existing methods (`fetchStats`, `fetchDailyCounts`, `fetchTechStats`, `fetchRoomStats`) remain unchanged — just called via providers instead of directly.

---

## Screen Architecture

`AnalyticsScreen` becomes a `ConsumerWidget`:

```
AnalyticsScreen
  ├── AppBar (title + role badge + export icon button)
  ├── TimeRangeChips (chip row: היום / 7 / חודש / Custom)
  ├── SingleChildScrollView
  │   ├── KpiRow (4 cards: Open / Resolved / Avg / SLA)
  │   ├── _DailyChartSection (expandable)
  │   ├── _DepartmentSection (expandable, manager+ only)
  │   ├── _StaffSection (expandable, manager+ only)
  │   └── _RoomSection (expandable)
  └── (export logic in screen method)
```

Each `_XxxSection` is a private widget using `ExpansionTile` styled to match Navy theme.

---

## Export

The existing export button creates an empty Excel file. Replace with real implementation:

1. Fetch all tickets in the selected range (id, room, department, title, status, priority, created_at, resolved_at, claimed_by)
2. Populate Excel sheet with all columns
3. Use `path_provider` to save to device documents directory
4. Use `share_plus` to open system share sheet (email, AirDrop, Files, etc.)

No PDF in this phase (added in Module 5 — Reports).

---

## UI Details

- **Theme:** Navy dark (`#0a1628` bg, `#0f1f3d` surface, `#c9a84c` primary/gold)
- **KPI cards:** 4-column grid, colored values (orange=open, green=resolved, blue=avg, gold=SLA)
- **SLA card color:** green if ≥ 80%, red if < 80%
- **Charts:** `fl_chart` BarChart for daily counts; horizontal LinearProgressIndicator-style bars for departments and rooms
- **Staff list:** avatar initials + name + department + count + avg time, sorted by count desc
- **Expandable sections:** `ExpansionTile` with custom tile color matching Navy surface

---

## Files to Create / Modify

| File | Action |
|---|---|
| `lib/features/analytics/domain/analytics_models.dart` | Add `DepartmentStats`, `MyStats` |
| `lib/features/analytics/data/analytics_repository.dart` | Add `fetchDepartmentStats`, `fetchMyStats` |
| `lib/features/analytics/providers/analytics_provider.dart` | Create — all Riverpod providers |
| `lib/features/analytics/presentation/analytics_screen.dart` | Full rewrite — Navy theme, expandable sections, role-based |

---

## Out of Scope (this phase)

- PDF export (Module 5)
- Admin permission settings UI
- Push notifications on SLA breach (Module 4)
- Comparison between time periods (e.g., this week vs last week)
