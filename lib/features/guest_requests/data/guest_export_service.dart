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
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }

  static String _fmtDay(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
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
