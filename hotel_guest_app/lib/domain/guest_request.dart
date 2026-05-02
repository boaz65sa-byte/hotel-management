class GuestRequest {
  final String id;
  final String roomNumber;
  final String guestName;
  final String category;
  final String? description;
  final String status;
  final DateTime createdAt;

  const GuestRequest({
    required this.id,
    required this.roomNumber,
    required this.guestName,
    required this.category,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory GuestRequest.fromJson(Map<String, dynamic> j) => GuestRequest(
    id:          j['id'] as String,
    roomNumber:  j['room_number'] as String,
    guestName:   j['guest_name'] as String,
    category:    j['category'] as String,
    description: j['description'] as String?,
    status:      j['status'] as String,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );
}
