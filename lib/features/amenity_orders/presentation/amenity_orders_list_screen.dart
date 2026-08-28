// lib/features/amenity_orders/presentation/amenity_orders_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/amenity_orders/data/amenity_order_repository.dart';
import 'package:hotel_app/features/amenity_orders/domain/amenity_order_model.dart';
import 'package:hotel_app/features/amenity_orders/providers/amenity_order_providers.dart';

const _filters = ['הכל', 'פתוחות', 'אושרו', 'נמסרו'];

bool _matchesFilter(AmenityOrder o, String filter) => switch (filter) {
  'פתוחות' => o.status == 'open',
  'אושרו'   => o.status == 'confirmed',
  'נמסרו'   => o.status == 'delivered',
  _         => o.status != 'cancelled',
};

const _categoryEmoji = {
  'restaurant':   '🍽️',
  'spa':          '💆',
  'room_service': '🛎️',
};

class AmenityOrdersListScreen extends ConsumerStatefulWidget {
  const AmenityOrdersListScreen({super.key});
  @override
  ConsumerState<AmenityOrdersListScreen> createState() =>
      _AmenityOrdersListScreenState();
}

class _AmenityOrdersListScreenState
    extends ConsumerState<AmenityOrdersListScreen> {
  String _filter = 'הכל';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allAmenityOrdersProvider);
    final catalogAsync = ref.watch(amenityCatalogProvider);

    return ordersAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Text('שגיאה: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (all) {
        final catalog = catalogAsync.valueOrNull ?? const {};
        final orders = all.where((o) => _matchesFilter(o, _filter)).toList();
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1628),
            automaticallyImplyLeading: false,
            title: const Text(
              'הזמנות אורחים',
              style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                                selectedColor: const Color(0xFFC9A84C),
                                labelStyle: TextStyle(
                                  color: _filter == f
                                      ? Colors.black
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(0xFF0F1F3D),
                                checkmarkColor: Colors.black,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text('אין הזמנות',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 16)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: orders.length,
                          itemBuilder: (_, i) => _AmenityOrderCard(
                            order: orders[i],
                            amenity: catalog[orders[i].amenityId],
                            onTap: () => _showActions(orders[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActions(AmenityOrder order) {
    final repo = ref.read(amenityOrderRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'חדר ${order.roomNumber} · ${order.guestName}',
              style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (order.status == 'open')
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF60A5FA)),
                title: const Text('אשר הזמנה',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () => _updateStatus(repo, order.id, 'confirmed'),
              ),
            if (order.status == 'confirmed')
              ListTile(
                leading: const Icon(Icons.done_all, color: Color(0xFF4ADE80)),
                title: const Text('סמן כנמסר',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () => _updateStatus(repo, order.id, 'delivered'),
              ),
            if (order.status == 'open' || order.status == 'confirmed')
              ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFF87171)),
                title: const Text('בטל הזמנה',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () => _updateStatus(repo, order.id, 'cancelled'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      AmenityOrderRepository repo, String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await repo.updateStatus(id, status);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _AmenityOrderCard extends StatelessWidget {
  final AmenityOrder order;
  final HotelAmenity? amenity;
  final VoidCallback onTap;

  const _AmenityOrderCard({
    required this.order,
    required this.amenity,
    required this.onTap,
  });

  static const _statusLabel = {
    'open':      ('ממתין', Color(0xFFFBBF24)),
    'confirmed': ('אושר', Color(0xFF60A5FA)),
    'delivered': ('נמסר', Color(0xFF4ADE80)),
    'cancelled': ('בוטל', Color(0xFF94A3B8)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusLabel[order.status] ?? (order.status, Colors.grey);
    final emoji = _categoryEmoji[amenity?.category] ?? '🛎️';
    final name = amenity?.name ?? order.amenityId;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              children: [
                Expanded(
                  child: Text(
                    'חדר ${order.roomNumber} · ${order.guestName}',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$emoji $name × ${order.quantity}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  order.notes!,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
