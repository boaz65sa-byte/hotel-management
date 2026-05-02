import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class NewGuestRequestScreen extends ConsumerStatefulWidget {
  const NewGuestRequestScreen({super.key});
  @override
  ConsumerState<NewGuestRequestScreen> createState() =>
      _NewGuestRequestScreenState();
}

class _NewGuestRequestScreenState
    extends ConsumerState<NewGuestRequestScreen> {
  final _roomCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'housekeeping';
  bool _loading = false;

  static const _categories = [
    ('housekeeping', '🛏️ חדרניות'),
    ('maintenance',  '🔧 תחזוקה'),
    ('reception',    '🛎️ קבלה'),
  ];

  @override
  void dispose() {
    _roomCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final room = _roomCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (room.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא למלא מספר חדר ושם אורח')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id']?.toString();
      if (hotelId == null) throw Exception('לא מחובר');
      await ref.read(guestRequestRepositoryProvider).create(
            hotelId:     hotelId,
            roomNumber:  room,
            guestName:   name,
            category:    _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdBy:   'reception',
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה: $e'),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('בקשה ידנית',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('מספר חדר'),
            _field(_roomCtrl, 'לדוגמה: 205', TextInputType.number),
            const SizedBox(height: 16),
            _label('שם האורח'),
            _field(_nameCtrl, 'שם מלא'),
            const SizedBox(height: 16),
            _label('קטגוריה'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories
                  .map((c) => ChoiceChip(
                        label: Text(c.$2),
                        selected: _category == c.$1,
                        onSelected: (_) =>
                            setState(() => _category = c.$1),
                        selectedColor: const Color(0xFFC9A84C),
                        labelStyle: TextStyle(
                          color: _category == c.$1
                              ? Colors.black
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: const Color(0xFF0F1F3D),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            _label('פרטים (אופציונלי)'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFFE2E8F0)),
              decoration: _inputDeco('מה האורח צריך?'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('שלח בקשה'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      [TextInputType? type]) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Color(0xFFE2E8F0)),
        decoration: _inputDeco(hint),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFF0F1F3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC9A84C)),
        ),
      );
}
