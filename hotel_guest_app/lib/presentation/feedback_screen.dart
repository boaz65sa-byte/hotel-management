// hotel_guest_app/lib/presentation/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});
  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.feedbackErrorNoRating)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception(loc.errorNoSession);
      await ref.read(guestRepositoryProvider).submitFeedback(
            hotelId:    session.hotelId,
            roomNumber: session.roomNumber,
            guestName:  session.guestName,
            rating:     _rating,
            comment:    _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      await GuestSession.markFeedbackDone();
      ref.invalidate(sessionProvider);
      setState(() => _submitted = true);
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

    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF4ADE80), size: 64),
              const SizedBox(height: 16),
              Text(loc.feedbackThanksTitle,
                  style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(loc.feedbackThanksSubtitle,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                ),
                child: Text(loc.feedbackBackHome,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: Text(loc.feedbackTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Text(loc.feedbackQuestion,
                  style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFC9A84C),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFFE2E8F0)),
                decoration: InputDecoration(
                  hintText: loc.feedbackCommentHint,
                  hintStyle:
                      const TextStyle(color: Color(0xFF64748B)),
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
                      : Text(loc.feedbackSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
