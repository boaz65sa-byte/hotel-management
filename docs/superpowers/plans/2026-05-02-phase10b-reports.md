# Phase 10b — Reports / Excel Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Excel export of guest requests and feedback to the Flutter hotel app, accessible to managers and hotel admins.

**Architecture:** A pure `GuestExportService` class builds the Excel workbook from in-memory data and returns a file path. Both `GuestRequestsListScreen` and `GuestFeedbackScreen` call it and pass the result to `Share.shareXFiles`. No new providers or DB queries — uses data already in existing providers.

**Tech Stack:** Flutter + `excel` + `share_plus` + `path_provider` (all already in `pubspec.yaml`)

---

## File Map

| Action | File |
|--------|------|
| Create | `lib/features/guest_requests/data/guest_export_service.dart` |
| Modify | `lib/features/guest_requests/presentation/guest_requests_list.dart` — add export button |
| Modify | `lib/features/guest_requests/presentation/guest_feedback_screen.dart` — add export button |

---

### Task 1: GuestExportService

**Files:**
- Create: `lib/features/guest_requests/data/guest_export_service.dart`

- [ ] **Step 1: Create the export service**

```dart
// lib/features/guest_requests/data/guest_export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

class GuestExportService {
  static const _categoryHe = {
    'housekeeping': 'חדרניות',
    'maintenance':  'תחזוקה',
    'reception':    'קבלה',
  };

  static const _statusHe = {
    'open':        'פתוחה',
    'assigned':    'הוקצתה',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה',
    'cancelled':   'בוטלה',
  };

  static const _createdByHe = {
    'guest':     'אורח',
    'reception': 'קבלה',
  };

  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }

  static String _fmtDay(DateTime dt) {
    final d = dt.toLocal();
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year}';
  }

  /// Builds an Excel file with two sheets and returns the file path.
  static Future<String> export({
    required List<GuestRequest> requests,
    required List<GuestFeedback> feedback,
  }) async {
    final excel = Excel.createExcel();

    // ── Sheet 1: בקשות ──────────────────────────────────────────────────────
    final reqSheet = excel['בקשות אורחים'];
    excel.setDefaultSheet('בקשות אורחים');

    final reqHeaders = [
      'חדר', 'שם אורח', 'קטגוריה', 'סטטוס',
      'נוצר על ידי', 'תיאור', 'תאריך יצירה',
    ];
    reqSheet.appendRow(reqHeaders.map(TextCellValue.new).toList());

    for (final r in requests) {
      reqSheet.appendRow([
        TextCellValue(r.roomNumber),
        TextCellValue(r.guestName),
        TextCellValue(_categoryHe[r.category] ?? r.category),
        TextCellValue(_statusHe[r.status] ?? r.status),
        TextCellValue(_createdByHe[r.createdBy] ?? r.createdBy),
        TextCellValue(r.description ?? ''),
        TextCellValue(_fmtDate(r.createdAt)),
      ]);
    }

    // ── Sheet 2: משובים ──────────────────────────────────────────────────────
    final fbSheet = excel['משובי אורחים'];

    final fbHeaders = ['חדר', 'שם אורח', 'דירוג', 'תגובה', 'תאריך'];
    fbSheet.appendRow(fbHeaders.map(TextCellValue.new).toList());

    for (final f in feedback) {
      fbSheet.appendRow([
        TextCellValue(f.roomNumber),
        TextCellValue(f.guestName),
        TextCellValue('${'★' * f.rating}${'☆' * (5 - f.rating)}'),
        TextCellValue(f.comment ?? ''),
        TextCellValue(_fmtDay(f.createdAt)),
      ]);
    }

    // Remove default empty sheet
    excel.delete('Sheet1');

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename =
        'guest_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';
    final path = '${dir.path}/$filename';
    final bytes = excel.encode();
    if (bytes == null) throw Exception('שגיאה ביצירת הקובץ');
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add lib/features/guest_requests/data/guest_export_service.dart && git commit -m "feat: add GuestExportService for Excel export"
```

---

### Task 2: Export button in GuestRequestsListScreen

**Files:**
- Modify: `lib/features/guest_requests/presentation/guest_requests_list.dart`

The screen watches `allGuestRequestsProvider` (requests). It also needs `guestFeedbackProvider` for the combined export.

- [ ] **Step 1: Add imports**

At the top of `guest_requests_list.dart`, add:
```dart
import 'package:share_plus/share_plus.dart';
import 'package:hotel_app/features/guest_requests/data/guest_export_service.dart';
```

- [ ] **Step 2: Add `_exporting` state to `_GuestRequestsListScreenState`**

Add field:
```dart
  bool _exporting = false;
```

- [ ] **Step 3: Add `_export` method to `_GuestRequestsListScreenState`**

```dart
  Future<void> _export(List<GuestRequest> requests) async {
    setState(() => _exporting = true);
    try {
      final feedback = await ref.read(guestFeedbackProvider.future);
      final path = await GuestExportService.export(
        requests: requests,
        feedback: feedback,
      );
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'דוח בקשות אורחים',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
```

- [ ] **Step 4: Add export action to the AppBar**

In the `AppBar` actions list (alongside the QR button added in Phase 10a), add:
```dart
                if (_exporting)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFC9A84C)),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.file_download,
                        color: Color(0xFFC9A84C)),
                    tooltip: 'ייצוא Excel',
                    onPressed: () => _export(all),
                  ),
```

> Note: `all` is already available in the `data:` callback scope.

- [ ] **Step 5: Run tests**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter test test/features/guest_requests/guest_request_test.dart -v 2>&1 | tail -5
```

Expected: 13/13 pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_requests_list.dart
git commit -m "feat: add Excel export button to GuestRequestsListScreen"
```

---

### Task 3: Export button in GuestFeedbackScreen

**Files:**
- Modify: `lib/features/guest_requests/presentation/guest_feedback_screen.dart`

`GuestFeedbackScreen` is a `ConsumerWidget`. Convert it to `ConsumerStatefulWidget` to add the `_exporting` state.

- [ ] **Step 1: Read the current file**

Read `lib/features/guest_requests/presentation/guest_feedback_screen.dart` to see the current class structure.

- [ ] **Step 2: Convert to ConsumerStatefulWidget**

Replace:
```dart
class GuestFeedbackScreen extends ConsumerWidget {
  const GuestFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
```

With:
```dart
class GuestFeedbackScreen extends ConsumerStatefulWidget {
  const GuestFeedbackScreen({super.key});

  @override
  ConsumerState<GuestFeedbackScreen> createState() =>
      _GuestFeedbackScreenState();
}

class _GuestFeedbackScreenState extends ConsumerState<GuestFeedbackScreen> {
  bool _exporting = false;

  Future<void> _export(List<GuestFeedback> feedback) async {
    setState(() => _exporting = true);
    try {
      final path = await GuestExportService.export(
        requests: const [],
        feedback: feedback,
      );
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'דוח משובי אורחים',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
```

- [ ] **Step 3: Add imports**

At the top of the file:
```dart
import 'package:share_plus/share_plus.dart';
import 'package:hotel_app/features/guest_requests/data/guest_export_service.dart';
```

- [ ] **Step 4: Add AppBar with export action**

The current `Scaffold` has no AppBar. In the `data: (items)` branch, the outer `Scaffold` needs an AppBar. Find:

```dart
          data: (items) => items.isEmpty
```

And replace the parent Scaffold (the one wrapping the `SafeArea`) to include an AppBar:

```dart
      body: SafeArea(
        child: feedbackAsync.when(
```

→ The `Scaffold` above this already exists. Add an `appBar:` parameter to that top-level Scaffold:

```dart
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        automaticallyImplyLeading: false,
        title: const Text('משובי אורחים',
            style: TextStyle(
              color: Color(0xFFC9A84C),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            )),
        actions: [
          feedbackAsync.whenData((items) => items).valueOrNull?.isNotEmpty == true
              ? (_exporting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFC9A84C)),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.file_download,
                          color: Color(0xFFC9A84C)),
                      tooltip: 'ייצוא Excel',
                      onPressed: () => _export(
                          feedbackAsync.value ?? const []),
                    ))
              : const SizedBox.shrink(),
        ],
      ),
```

- [ ] **Step 5: Run tests**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter test test/features/guest_requests/guest_request_test.dart -v 2>&1 | tail -5
```

Expected: 13/13 pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_feedback_screen.dart
git commit -m "feat: add Excel export button to GuestFeedbackScreen"
```
