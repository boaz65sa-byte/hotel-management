// lib/features/tickets/presentation/new_ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/routing_rules.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/rooms/providers/rooms_provider.dart';
import '../data/ticket_repository.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';

// ── Static maps ───────────────────────────────────────────────────────────────
const _deptMeta = {
  'maintenance': (icon: '🔧', label: 'אחזקה'),
  'reception':   (icon: '🛎️', label: 'קבלה'),
  'security':    (icon: '🔒', label: 'ביטחון'),
  'housekeeping':(icon: '🧹', label: 'משק בית'),
};

const _priorities = [
  (value: 'low',    label: 'נמוך',   emoji: '🟢'),
  (value: 'normal', label: 'רגיל',   emoji: '⚪'),
  (value: 'high',   label: 'דחוף',   emoji: '🟠'),
  (value: 'urgent', label: 'חירום',  emoji: '🔴'),
];

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});
  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _selectedRoomId;
  String? _selectedDept;
  String  _priority = 'normal';
  bool    _loading  = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
        (user?.appMetadata['role'] as String?) ?? 'receptionist');
    final availableDepts = allowedDepts(role);
    final roomsAsync = ref.watch(roomsProvider);

    final isEmergency = _priority == 'urgent';

    return Scaffold(
      appBar: AppBar(
        title: const Text('קריאה חדשה'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dept selector ─────────────────────────────────────────────
            _SectionLabel(label: 'מחלקה'),
            const SizedBox(height: 8),
            _DeptGrid(
              available: availableDepts,
              selected: _selectedDept,
              onSelect: (d) => setState(() => _selectedDept = d),
            ),

            const SizedBox(height: 16),

            // ── Room selector ─────────────────────────────────────────────
            _SectionLabel(label: 'מיקום (חדר / אזור)'),
            const SizedBox(height: 8),
            roomsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'מספר חדר',
                  prefixIcon: Icon(Icons.meeting_room_outlined,
                      color: cs.onSurfaceVariant),
                ),
              ),
              data: (rooms) => DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: InputDecoration(
                  hintText: 'בחר חדר',
                  prefixIcon: Icon(Icons.meeting_room_outlined,
                      color: cs.onSurfaceVariant),
                ),
                items: rooms
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text('חדר ${r.roomNumber}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoomId = v),
              ),
            ),

            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────────────────
            _SectionLabel(label: 'תיאור קצר'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'לדוגמה: עשן מהמזגן...',
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────────────
            _SectionLabel(label: 'פירוט (אופציונלי)'),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'תאר את הבעיה בפירוט...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 16),

            // ── Priority ──────────────────────────────────────────────────
            _SectionLabel(label: 'דחיפות'),
            const SizedBox(height: 8),
            _PriorityGrid(
              selected: _priority,
              onSelect: (p) => setState(() => _priority = p),
            ),

            // ── Photo notice for emergency ────────────────────────────────
            if (isEmergency) ...[
              const SizedBox(height: 16),
              _PhotoNotice(),
            ],

            // ── Error ─────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, size: 16, color: cs.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          fontSize: 12, color: cs.onErrorContainer),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────────────────
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'שלח קריאה ←',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedRoomId == null) {
      setState(() => _error = 'יש לבחור חדר');
      return;
    }
    if (_selectedDept == null) {
      setState(() => _error = 'יש לבחור מחלקה');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'יש להזין תיאור קצר');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user    = ref.read(currentUserProvider)!;
      final hotelId = user.appMetadata['hotel_id'] as String;
      final repo    = TicketRepository(isOnline: () => ref.read(isOnlineProvider));

      final hotelRes = await supabase
          .from('hotels')
          .select('default_sla_hours')
          .eq('id', hotelId)
          .single();
      final slaHours   = (hotelRes['default_sla_hours'] as int?) ?? 4;
      final slaDeadline = DateTime.now().add(Duration(hours: slaHours));

      await repo.openTicket(
        hotelId: hotelId,
        roomId: _selectedRoomId!,
        openedBy: user.id,
        assignedDept: _selectedDept!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
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

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: cs.primary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Dept selector grid ────────────────────────────────────────────────────────
class _DeptGrid extends StatelessWidget {
  final List<String> available;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _DeptGrid(
      {required this.available, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final depts = _deptMeta.keys.where(available.contains).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: depts.map((d) {
        final meta     = _deptMeta[d]!;
        final isSelect = selected == d;
        return GestureDetector(
          onTap: () => onSelect(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelect ? cs.primaryContainer : cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelect ? cs.primary : cs.outline,
                width: isSelect ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(meta.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  meta.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelect ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Priority grid ─────────────────────────────────────────────────────────────
const _priorityCardColors = {
  'low':    Color(0xFF16A34A),
  'normal': Color(0xFF6B7280),
  'high':   Color(0xFFFB923C),
  'urgent': Color(0xFFF87171),
};

class _PriorityGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PriorityGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _priorities.map((p) {
        final color    = _priorityCardColors[p.value]!;
        final isSelect = selected == p.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelect ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelect ? color : color.withOpacity(0.35),
                  width: isSelect ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Photo notice ──────────────────────────────────────────────────────────────
class _PhotoNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFF87171).withOpacity(0.5), width: 1.5),
      ),
      child: const Row(
        children: [
          Text('📷', style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'נדרשת תמונה לחירום',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF87171)),
                ),
                SizedBox(height: 2),
                Text(
                  'צלם תמונה מהמקום לאחר פתיחת הקריאה',
                  style: TextStyle(fontSize: 11, color: Color(0xFFF87171)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
