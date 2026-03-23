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
    id: j['id'],
    hotelId: j['hotel_id'],
    roomNumber: j['room_number'],
    floor: j['floor'],
    roomType: j['room_type'],
    status: j['status'],
    notes: j['notes'],
    createdAt: DateTime.parse(j['created_at']),
  );

  bool get isAvailable => status == 'available';
  bool get isOnHold   => status == 'on_hold';
  bool get isClosed   => status == 'closed';
}
