// lib/features/tickets/presentation/new_ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/routing_rules.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../data/ticket_repository.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});
  @override ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedRoom;
  String? _selectedDept;
  String _priority = 'normal';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist'
    );
    final availableDepts = allowedDepts(role);

    return Scaffold(
      appBar: AppBar(title: Text(l.newTicket)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Room selector (populated from rooms provider in Plan 4)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Room'),
            value: _selectedRoom,
            items: const [], // populated from rooms provider
            onChanged: (v) => setState(() => _selectedRoom = v),
          ),
          const SizedBox(height: 12),
          // Department selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Department'),
            value: _selectedDept,
            items: availableDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _selectedDept = v),
          ),
          const SizedBox(height: 12),
          // Priority
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Priority'),
            value: _priority,
            items: ['low', 'normal', 'high', 'urgent']
              .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          _loading
            ? const CircularProgressIndicator()
            : FilledButton(
                onPressed: _submit,
                child: Text(l.saveChanges),
              ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedDept == null || _titleCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = ref.read(currentUserProvider)!;
      final hotelId = user.appMetadata['hotel_id'] as String;
      final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
      // Fetch hotel SLA hours to set sla_deadline
      final hotelRes = await supabase
        .from('users')
        .select('hotel:hotels(default_sla_hours)')
        .eq('id', user.id)
        .single();
      final slaHours = (hotelRes['hotel']?['default_sla_hours'] as int?) ?? 4;
      final slaDeadline = DateTime.now().add(Duration(hours: slaHours));

      await repo.openTicket(
        hotelId: hotelId,
        roomId: _selectedRoom ?? '',
        openedBy: user.id,
        assignedDept: _selectedDept!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priority: _priority,
        slaDeadline: slaDeadline,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
