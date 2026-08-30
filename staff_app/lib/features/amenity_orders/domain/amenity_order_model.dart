// lib/features/amenity_orders/domain/amenity_order_model.dart

class AmenityOrder {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final String amenityId;
  final int quantity;
  final String status; // open | confirmed | delivered | cancelled
  final String? notes;
  final DateTime createdAt;

  const AmenityOrder({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.guestName,
    required this.amenityId,
    required this.quantity,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory AmenityOrder.fromJson(Map<String, dynamic> j) => AmenityOrder(
    id:         j['id'] as String,
    hotelId:    j['hotel_id'] as String,
    roomNumber: j['room_number'] as String,
    guestName:  j['guest_name'] as String,
    amenityId:  j['amenity_id'] as String,
    quantity:   j['quantity'] as int,
    status:     j['status'] as String,
    notes:      j['notes'] as String?,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );
}

/// Per-hotel catalog entry (spa/restaurant/room_service) — used to resolve
/// [AmenityOrder.amenityId] to a display name. Realtime `.stream()` can't
/// embed a join, so the catalog is fetched separately and looked up by id.
class HotelAmenity {
  final String id;
  final String category;
  final String name;
  final double? price;
  final String currency;

  const HotelAmenity({
    required this.id,
    required this.category,
    required this.name,
    this.price,
    required this.currency,
  });

  factory HotelAmenity.fromJson(Map<String, dynamic> j) => HotelAmenity(
    id:       j['id'] as String,
    category: j['category'] as String,
    name:     j['name'] as String,
    price:    (j['price'] as num?)?.toDouble(),
    currency: j['currency'] as String? ?? 'ILS',
  );
}
