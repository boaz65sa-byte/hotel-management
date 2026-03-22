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
    this.roomNumber,
    this.openerName,
    this.claimerName,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
    id: j['id'],
    hotelId: j['hotel_id'],
    roomId: j['room_id'],
    openedBy: j['opened_by'],
    assignedDept: j['assigned_dept'],
    claimedBy: j['claimed_by'],
    title: j['title'],
    description: j['description'],
    priority: j['priority'],
    status: j['status'],
    resolutionType: j['resolution_type'],
    slaDeadline: j['sla_deadline'] != null ? DateTime.parse(j['sla_deadline']) : null,
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
    resolvedAt: j['resolved_at'] != null ? DateTime.parse(j['resolved_at']) : null,
    roomNumber: j['room']?['room_number'],
    openerName: j['opener']?['full_name'],
    claimerName: j['claimer']?['full_name'],
  );

  bool get isOverSla =>
    slaDeadline != null && DateTime.now().isAfter(slaDeadline!) && resolvedAt == null;
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
    id: j['id'],
    ticketId: j['ticket_id'],
    userId: j['user_id'],
    message: j['message'],
    updateType: j['update_type'],
    createdAt: DateTime.parse(j['created_at']),
    userName: j['user']?['full_name'],
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
    id: j['id'],
    ticketId: j['ticket_id'],
    photoUrl: j['photo_url'],
    fileSizeBytes: j['file_size_bytes'],
    createdAt: DateTime.parse(j['created_at']),
    uploaderName: j['uploader']?['full_name'],
  );
}
