import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/auth/role_helpers.dart';
import 'package:hotel_app/features/guest_requests/data/guest_export_service.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

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
    final feedbackAsync = ref.watch(guestFeedbackProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        automaticallyImplyLeading: false,
        title: const Text(
          'משובי אורחים',
          style: TextStyle(
            color: Color(0xFFC9A84C),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (canExportData(ref.watch(authRepositoryProvider).role)) ...[
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
                icon: const Icon(Icons.file_download, color: Color(0xFFC9A84C)),
                tooltip: 'ייצוא Excel',
                onPressed: () {
                  final items = feedbackAsync.value;
                  if (items != null && items.isNotEmpty) _export(items);
                },
              ),
          ],
        ],
      ),
      body: SafeArea(
        child: feedbackAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white)),
          ),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text('אין משובים עדיין',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final fb = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1F3D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E3A5F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'חדר ${fb.roomNumber} · ${fb.guestName}',
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (idx) => Icon(
                                    idx < fb.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFFC9A84C),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (fb.comment != null && fb.comment!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              fb.comment!,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
