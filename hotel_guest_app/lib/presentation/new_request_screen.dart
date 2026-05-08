// hotel_guest_app/lib/presentation/new_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});
  @override
  ConsumerState<NewRequestScreen> createState() =>
      _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'housekeeping';
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  List<(String, String)> _categories(AppLocalizations loc) => [
    ('housekeeping', '🛏️ ${loc.categoryHousekeeping}'),
    ('maintenance',  '🔧 ${loc.categoryMaintenance}'),
    ('reception',    '🛎️ ${loc.categoryReception}'),
  ];

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception(loc.errorNoSession);
      await ref.read(guestRepositoryProvider).submitRequest(
            hotelId:     session.hotelId,
            roomNumber:  session.roomNumber,
            guestName:   session.guestName,
            category:    _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.errorGeneric(e.toString())),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final categories = _categories(loc);
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: Text(loc.newRequestTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.newRequestCategoryLabel,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories
                    .map((c) => GestureDetector(
                          onTap: () =>
                              setState(() => _category = c.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _category == c.$1
                                  ? const Color(0xFFC9A84C)
                                  : const Color(0xFF0F1F3D),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _category == c.$1
                                    ? const Color(0xFFC9A84C)
                                    : const Color(0xFF1E3A5F),
                              ),
                            ),
                            child: Text(
                              c.$2,
                              style: TextStyle(
                                color: _category == c.$1
                                    ? Colors.black
                                    : const Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(loc.newRequestDetailsLabel,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFFE2E8F0)),
                decoration: InputDecoration(
                  hintText: loc.newRequestDetailsHint,
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F1F3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : Text(loc.newRequestSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
