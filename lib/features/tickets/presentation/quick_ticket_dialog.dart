// lib/features/tickets/presentation/quick_ticket_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';
import 'package:hotel_app/features/tickets/providers/tickets_provider.dart';

/// Compact ticket-creation dialog reachable from a long-press on a room tile.
/// Saves a few taps vs. drilling into the room detail → "+ ticket" flow.
class QuickTicketDialog extends ConsumerStatefulWidget {
  final Room room;
  const QuickTicketDialog({super.key, required this.room});

  @override
  ConsumerState<QuickTicketDialog> createState() => _QuickTicketDialogState();
}

class _QuickTicketDialogState extends ConsumerState<QuickTicketDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _dept = 'maintenance';
  String _priority = 'normal';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'יש להזין כותרת');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      if (user == null || hotelId == null) {
        throw 'משתמש לא מחובר למלון';
      }
      await ref.read(ticketRepoProvider).openTicket(
            hotelId: hotelId,
            roomId: widget.room.id,
            openedBy: user.id,
            assignedDept: _dept,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            priority: _priority,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('קריאה נפתחה לחדר ${widget.room.roomNumber}'),
          backgroundColor: const Color(0xFF4ADE80),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('קריאה מהירה — חדר ${widget.room.roomNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'כותרת *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'תיאור (אופציונלי)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _dept,
              decoration: const InputDecoration(
                labelText: 'מחלקה',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'maintenance', child: Text('🔧 תחזוקה')),
                DropdownMenuItem(value: 'housekeeping', child: Text('🛏️ חדרניות')),
                DropdownMenuItem(value: 'reception', child: Text('🛎️ קבלה')),
                DropdownMenuItem(value: 'security', child: Text('🛡️ אבטחה')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _dept = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'דחיפות',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('נמוכה')),
                DropdownMenuItem(value: 'normal', child: Text('רגילה')),
                DropdownMenuItem(value: 'high', child: Text('גבוהה')),
                DropdownMenuItem(value: 'critical', child: Text('קריטית')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('פתח קריאה'),
        ),
      ],
    );
  }
}
