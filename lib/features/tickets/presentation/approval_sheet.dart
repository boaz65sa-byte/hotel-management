// lib/features/tickets/presentation/approval_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

class ApprovalSheet extends ConsumerStatefulWidget {
  final String ticketId;
  final String approvalId;
  const ApprovalSheet({super.key, required this.ticketId, required this.approvalId});

  @override ConsumerState<ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends ConsumerState<ApprovalSheet> {
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _decide(bool approved) async {
    setState(() => _loading = true);
    try {
      await supabase.from('ticket_approvals').update({
        'approved': approved,
        'approved_at': DateTime.now().toIso8601String(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      }).eq('id', widget.approvalId);

      if (approved) {
        await supabase.rpc('check_and_close_ticket',
          params: {'p_ticket_id': widget.ticketId});
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Approval Decision', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _loading
            ? const CircularProgressIndicator()
            : Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(false),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _decide(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ]),
        ]),
      ),
    );
  }
}
