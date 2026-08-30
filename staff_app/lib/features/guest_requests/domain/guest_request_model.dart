// lib/features/guest_requests/domain/guest_request_model.dart

class GuestRequest {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final String category;
  final String? description;
  final String status;
  final String? assignedDept;
  final String? assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestRequest({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.guestName,
    required this.category,
    this.description,
    required this.status,
    this.assignedDept,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuestRequest.fromJson(Map<String, dynamic> j) => GuestRequest(
    id:           j['id'] as String,
    hotelId:      j['hotel_id'] as String,
    roomNumber:   j['room_number'] as String,
    guestName:    j['guest_name'] as String,
    category:     j['category'] as String,
    description:  j['description'] as String?,
    status:       j['status'] as String,
    assignedDept: j['assigned_dept'] as String?,
    assignedTo:   j['assigned_to'] as String?,
    createdBy:    j['created_by'] as String,
    createdAt:    DateTime.parse(j['created_at'] as String),
    updatedAt:    DateTime.parse(j['updated_at'] as String),
  );
}

class GuestFeedback {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const GuestFeedback({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.guestName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory GuestFeedback.fromJson(Map<String, dynamic> j) => GuestFeedback(
    id:         j['id'] as String,
    hotelId:    j['hotel_id'] as String,
    roomNumber: j['room_number'] as String,
    guestName:  j['guest_name'] as String,
    rating:     j['rating'] as int,
    comment:    j['comment'] as String?,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );
}
