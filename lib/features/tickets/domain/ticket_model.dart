// lib/features/tickets/domain/ticket_model.dart
class Ticket {
  final String id;
  final String hotelId;
  final String roomId;
  final String openedBy;
  final String assignedDept;
  final String? claimedBy;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? resolutionType;
  final DateTime? slaDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? acceptedAt;
  final String? photoBeforeUrl;
  final String? photoAfterUrl;

  // Joined fields
  final String? roomNumber;
  final String? openerName;
  final String? claimerName;

  const Ticket({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.openedBy,
    required this.assignedDept,
    this.claimedBy,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.resolutionType,
    this.slaDeadline,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.acceptedAt,
    this.photoBeforeUrl,
    this.photoAfterUrl,
    this.roomNumber,
    this.openerName,
    this.claimerName,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
    id: j['id'] as String,
    hotelId: j['hotel_id'] as String,
    roomId: j['room_id'] as String,
    openedBy: j['opened_by'] as String,
    assignedDept: j['assigned_dept'] as String,
    claimedBy: j['claimed_by'] as String?,
    title: j['title'] as String,
    description: j['description'] as String?,
    priority: j['priority'] as String,
    status: j['status'] as String,
    resolutionType: j['resolution_type'] as String?,
    slaDeadline: j['sla_deadline'] != null ? DateTime.parse(j['sla_deadline'] as String) : null,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    resolvedAt: j['resolved_at'] != null ? DateTime.parse(j['resolved_at'] as String) : null,
    acceptedAt: j['accepted_at'] != null ? DateTime.parse(j['accepted_at'] as String) : null,
    photoBeforeUrl: j['photo_before_url'] as String?,
    photoAfterUrl: j['photo_after_url'] as String?,
    roomNumber: j['room'] != null ? (j['room'] as Map<String, dynamic>)['room_number'] as String? : null,
    openerName: j['opener'] != null ? (j['opener'] as Map<String, dynamic>)['full_name'] as String? : null,
    claimerName: j['claimer'] != null ? (j['claimer'] as Map<String, dynamic>)['full_name'] as String? : null,
  );

  bool get isOverSla =>
    slaDeadline != null && DateTime.now().isAfter(slaDeadline!) && resolvedAt == null;

  bool get canResolve => photoAfterUrl != null;
}

class TicketUpdate {
  final String id;
  final String ticketId;
  final String userId;
  final String? message;
  final String updateType;
  final DateTime createdAt;
  final String? userName;

  const TicketUpdate({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.message,
    required this.updateType,
    required this.createdAt,
    this.userName,
  });

  factory TicketUpdate.fromJson(Map<String, dynamic> j) => TicketUpdate(
    id: j['id'] as String,
    ticketId: j['ticket_id'] as String,
    userId: j['user_id'] as String,
    message: j['message'] as String?,
    updateType: j['update_type'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    userName: j['user'] != null ? (j['user'] as Map<String, dynamic>)['full_name'] as String? : null,
  );
}

class TicketPhoto {
  final String id;
  final String ticketId;
  final String photoUrl;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final String? uploaderName;

  const TicketPhoto({
    required this.id,
    required this.ticketId,
    required this.photoUrl,
    this.fileSizeBytes,
    required this.createdAt,
    this.uploaderName,
  });

  factory TicketPhoto.fromJson(Map<String, dynamic> j) => TicketPhoto(
    id: j['id'] as String,
    ticketId: j['ticket_id'] as String,
    photoUrl: j['photo_url'] as String,
    fileSizeBytes: j['file_size_bytes'] as int?,
    createdAt: DateTime.parse(j['created_at'] as String),
    uploaderName: j['uploader'] != null ? (j['uploader'] as Map<String, dynamic>)['full_name'] as String? : null,
  );
}
