// lib/features/tickets/presentation/assign_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/providers/tickets_provider.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

class AssignStaffScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  const AssignStaffScreen({super.key, required this.ticket});

  @override
  ConsumerState<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends ConsumerState<AssignStaffScreen> {
  String? _selectedId;
  String? _selectedName;
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _staff = [];
  bool _staffLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final repo = ref.read(ticketRepoProvider);
    final staff = await repo.fetchDeptStaff(widget.ticket.assignedDept);
    if (mounted) setState(() { _staff = staff; _staffLoading = false; });
  }

  Future<void> _assign() async {
    if (_selectedId == null) return;
    setState(() => _loading = true);
    try {
      final me = ref.read(authRepositoryProvider).currentUser?.id;
      if (me == null) throw Exception('לא מחובר');
      await ref.read(ticketRepoProvider).assignTicket(
        ticketId: widget.ticket.id,
        assignedTo: _selectedId!,
        assignedBy: me,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('שבץ מטפל',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              widget.ticket.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _staffLoading
                ? const Center(child: CircularProgressIndicator())
                : _staff.isEmpty
                    ? Center(
                        child: Text(
                          'אין עובדים זמינים במחלקה זו',
                          style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _staff.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'עובדים זמינים — ${widget.ticket.assignedDept}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface.withOpacity(0.5),
                                  letterSpacing: 0.06,
                                ),
                              ),
                            );
                          }
                          final s = _staff[i - 1];
                          final id = s['id'] as String;
                          final name = s['full_name'] as String? ?? 'עובד';
                          final role = s['role'] as String? ?? '';
                          final selected = _selectedId == id;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedId = id;
                              _selectedName = name;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primaryContainer
                                    : cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? cs.primary : cs.outline,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        cs.primary.withOpacity(0.15),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name.characters.first
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        Text(role,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurface
                                                    .withOpacity(0.5))),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check_circle, color: cs.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_selectedId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _noteCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'הערה לשיבוץ (אופציונלי)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedId == null || _loading ? null : _assign,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _selectedName != null
                            ? 'שבץ את $_selectedName ←'
                            : 'בחר עובד',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
