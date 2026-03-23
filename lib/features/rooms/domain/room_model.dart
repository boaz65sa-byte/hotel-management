class Room {
  final String id;
  final String hotelId;
  final String roomNumber;
  final int? floor;
  final String? roomType;
  final String status; // available | on_hold | closed
  final String? notes;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    this.floor,
    this.roomType,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    hotelId: j['hotel_id'] as String,
    roomNumber: j['room_number'] as String,
    floor: j['floor'] as int?,
    roomType: j['room_type'] as String?,
    status: j['status'] as String,
    notes: j['notes'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  bool get isAvailable => status == 'available';
  bool get isOnHold   => status == 'on_hold';
  bool get isClosed   => status == 'closed';
}
