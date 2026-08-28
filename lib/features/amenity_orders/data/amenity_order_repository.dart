// lib/features/amenity_orders/data/amenity_order_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/amenity_orders/domain/amenity_order_model.dart';

class AmenityOrderRepository {
  /// Streams all amenity orders for a hotel, newest first.
  Stream<List<AmenityOrder>> streamAll(String hotelId) {
    return supabase
        .from('amenity_orders')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => AmenityOrder.fromJson(j))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Fetches the hotel's amenity catalog, keyed by id for display lookups.
  Future<Map<String, HotelAmenity>> fetchCatalog(String hotelId) async {
    final res = await supabase
        .from('hotel_amenities')
        .select()
        .eq('hotel_id', hotelId);
    return {
      for (final j in res) (j['id'] as String): HotelAmenity.fromJson(j),
    };
  }

  /// Updates the status of an order (open → confirmed → delivered, or cancelled).
  Future<void> updateStatus(String id, String status) async {
    await supabase.from('amenity_orders').update({
      'status':     status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
