import 'package:hotel_guest_app/core/supabase_init.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';

class HotelBranding {
  final String name;
  final String? logoUrl;
  const HotelBranding({required this.name, this.logoUrl});
}

class GuestRepository {
  /// Fetches the hotel's public branding (name + logo).
  /// Returns null if hotelId is invalid or the row is missing.
  Future<HotelBranding?> getHotelBranding(String hotelId) async {
    try {
      final row = await supabase
          .from('hotels')
          .select('name, logo_url')
          .eq('id', hotelId)
          .maybeSingle();
      if (row == null) return null;
      return HotelBranding(
        name: row['name'] as String,
        logoUrl: row['logo_url'] as String?,
      );
    } catch (_) {
      return null;
    }
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
