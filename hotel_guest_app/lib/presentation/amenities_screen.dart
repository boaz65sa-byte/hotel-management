// hotel_guest_app/lib/presentation/amenities_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_guest_app/domain/amenity_item.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/providers/providers.dart';

const _categories = ['restaurant', 'spa', 'room_service'];
const _categoryIcons = {
  'restaurant': '🍽️',
  'spa': '💆',
  'room_service': '🛎️',
};

class AmenitiesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const AmenitiesScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends ConsumerState<AmenitiesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialCategory != null
        ? _categories.indexOf(widget.initialCategory!).clamp(0, _categories.length - 1)
        : 0;
    _tabController = TabController(
        length: _categories.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category, AppLocalizations loc) {
    switch (category) {
      case 'restaurant':   return loc.categoryRestaurant;
      case 'spa':           return loc.categorySpa;
      case 'room_service':  return loc.categoryRoomService;
      default:               return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final amenitiesAsync = ref.watch(amenitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: Text(loc.amenitiesTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC9A84C),
          labelColor: const Color(0xFFC9A84C),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: _categories
              .map((c) => Tab(
                    text: '${_categoryIcons[c]} ${_categoryLabel(c, loc)}',
                  ))
              .toList(),
        ),
      ),
      body: amenitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Color(0xFF94A3B8)))),
        data: (items) => TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            final filtered =
                items.where((i) => i.category == category).toList();
            if (filtered.isEmpty) {
              return Center(
                child: Text(loc.amenitiesEmpty,
                    style: const TextStyle(color: Color(0xFF64748B))),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _AmenityTile(item: filtered[i]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final AmenityItem item;
  const _AmenityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.description!,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12)),
                  ),
                if (item.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${item.price} ${item.currency}',
                        style: const TextStyle(
                            color: Color(0xFFC9A84C),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF0F1F3D),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _OrderSheet(item: item),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC9A84C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(AppLocalizations.of(context)!.amenitiesOrderButton),
          ),
        ],
      ),
    );
  }
}

class _OrderSheet extends ConsumerStatefulWidget {
  final AmenityItem item;
  const _OrderSheet({required this.item});

  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  int _quantity = 1;
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception(loc.errorNoSession);
      await ref.read(guestRepositoryProvider).submitAmenityOrder(
            hotelId:    session.hotelId,
            roomNumber: session.roomNumber,
            guestName:  session.guestName,
            amenityId:  widget.item.id,
            quantity:   _quantity,
            notes:      _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.errorGeneric(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 56),
            const SizedBox(height: 12),
            Text(loc.amenitiesOrderSuccessTitle,
                style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(loc.amenitiesOrderSuccessSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: Colors.black,
              ),
              child: Text(loc.amenitiesBackToMenu),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.item.name,
              style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(loc.amenitiesQuantityLabel,
                  style: const TextStyle(color: Color(0xFF94A3B8))),
              const Spacer(),
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline,
                    color: Color(0xFFC9A84C)),
              ),
              Text('$_quantity',
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFFC9A84C)),
              ),
            ],
          ),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: Color(0xFFE2E8F0)),
            decoration: InputDecoration(
              hintText: loc.amenitiesNotesHint,
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF1A3160),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2D4A7A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2D4A7A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC9A84C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text(loc.amenitiesOrderButton),
          ),
        ],
      ),
    );
  }
}
