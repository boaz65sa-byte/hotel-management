// lib/features/amenity_orders/providers/amenity_order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/amenity_orders/data/amenity_order_repository.dart';
import 'package:hotel_app/features/amenity_orders/domain/amenity_order_model.dart';

final amenityOrderRepositoryProvider =
    Provider<AmenityOrderRepository>((_) => AmenityOrderRepository());

/// All amenity orders for the current user's hotel.
final allAmenityOrdersProvider = StreamProvider<List<AmenityOrder>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id']?.toString();
  if (hotelId == null) return const Stream.empty();
  return ref.watch(amenityOrderRepositoryProvider).streamAll(hotelId);
});

/// The hotel's amenity catalog, keyed by id — resolves order.amenityId to a name.
final amenityCatalogProvider = FutureProvider<Map<String, HotelAmenity>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id']?.toString();
  if (hotelId == null) return {};
  return ref.watch(amenityOrderRepositoryProvider).fetchCatalog(hotelId);
});
