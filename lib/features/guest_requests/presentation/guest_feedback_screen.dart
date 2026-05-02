import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class GuestFeedbackScreen extends ConsumerWidget {
  const GuestFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(guestFeedbackProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'משובי אורחים',
                        style: TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final fb = items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1F3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF1E3A5F)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          color:
                                              const Color(0xFFC9A84C),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (fb.comment != null &&
                                    fb.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    fb.comment!,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
