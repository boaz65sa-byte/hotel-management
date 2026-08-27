import 'package:hotel_guest_app/core/supabase_init.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';
import 'package:hotel_guest_app/domain/amenity_item.dart';

class HotelBranding {
  final String name;
  final String? logoUrl;
  final Map<String, dynamic> enabledFeatures;
  const HotelBranding({
    required this.name,
    this.logoUrl,
    this.enabledFeatures = const {},
  });

  bool get amenitiesOrderingEnabled => enabledFeatures['amenities_ordering'] == true;
  bool get guidedMenuEnabled => enabledFeatures['guided_menu'] == true;
}

class GuestRepository {
  /// Fetches the hotel's public branding (name + logo).
  /// Uses a SECURITY DEFINER RPC so that anonymous PWA visitors can see
  /// the hotel name and logo without us opening up RLS on the full hotels row.
  /// Returns null if hotelId is invalid or the row is missing.
  Future<HotelBranding?> getHotelBranding(String hotelId) async {
    try {
      final data = await supabase
          .rpc('get_hotel_branding', params: {'p_hotel_id': hotelId});
      if (data is! List || data.isEmpty) return null;
      final row = data.first as Map<String, dynamic>;
      final name = row['name'];
      if (name is! String || name.isEmpty) return null;
      final features = row['enabled_features'];
      return HotelBranding(
        name: name,
        logoUrl: row['logo_url'] as String?,
        enabledFeatures: features is Map
            ? Map<String, dynamic>.from(features)
            : const {},
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches the active amenities catalog for a hotel, optionally filtered
  /// to one category (restaurant/spa/room_service).
  Future<List<AmenityItem>> getAmenities(String hotelId, {String? category}) async {
    var query = supabase
        .from('hotel_amenities')
        .select('id, category, name, description, price, currency')
        .eq('hotel_id', hotelId)
        .eq('is_active', true);
    if (category != null) query = query.eq('category', category);
    final data = await query.order('sort_order');
    return (data as List)
        .map((j) => AmenityItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Submits a guest order for an amenity (spa/restaurant/room service item).
  Future<void> submitAmenityOrder({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required String amenityId,
    int quantity = 1,
    String? notes,
  }) async {
    await supabase.from('amenity_orders').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'amenity_id':  amenityId,
      'quantity':    quantity,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  /// Streams this guest's requests, newest first.
  /// Filtered client-side — stream() only supports one .eq() filter.
  Stream<List<GuestRequest>> streamMyRequests(
      String hotelId, String roomNumber, String guestName) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .where((r) =>
                r.roomNumber == roomNumber && r.guestName == guestName)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Submits a new guest request.
  Future<void> submitRequest({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required String category,
    String? description,
  }) async {
    await supabase.from('guest_requests').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'category':    category,
      if (description != null && description.isNotEmpty)
        'description': description,
      'created_by': 'guest',
    });
  }

  /// Submits end-of-stay feedback.
  Future<void> submitFeedback({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required int rating,
    String? comment,
  }) async {
    await supabase.from('guest_feedback').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'rating':      rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}
