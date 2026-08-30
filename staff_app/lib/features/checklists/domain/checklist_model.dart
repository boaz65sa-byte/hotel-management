// lib/features/checklists/domain/checklist_model.dart

class ChecklistTemplate {
  final String id;
  final String name;
  final String type; // 'housekeeping' | 'maintenance'
  final bool isVip;
  final DateTime createdAt;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.isVip,
    required this.createdAt,
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> j) => ChecklistTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String,
    isVip: j['is_vip'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class ChecklistInstance {
  final String id;
  final String templateId;
  final String hotelId;
  final String? roomId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String templateName;

  const ChecklistInstance({
    required this.id,
    required this.templateId,
    required this.hotelId,
    this.roomId,
    this.assignedTo,
    required this.createdAt,
    this.completedAt,
    required this.templateName,
  });

  bool get isComplete => completedAt != null;

  factory ChecklistInstance.fromJson(Map<String, dynamic> j) => ChecklistInstance(
    id: j['id'] as String,
    templateId: j['template_id'] as String,
    hotelId: j['hotel_id'] as String,
    roomId: j['room_id'] as String?,
    assignedTo: j['assigned_to'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    completedAt: j['completed_at'] != null ? DateTime.parse(j['completed_at'] as String) : null,
    templateName: j['template'] != null
        ? (j['template'] as Map<String, dynamic>)['name'] as String? ?? ''
        : '',
  );
}

class ChecklistInstanceItem {
  final String id;
  final String instanceId;
  final bool isDone;
  final String titleHe;
  final bool requiresPhoto;
  final String? photoUrl;
  final DateTime? doneAt;
  final DateTime updatedAt;

  const ChecklistInstanceItem({
    required this.id,
    required this.instanceId,
    required this.isDone,
    required this.titleHe,
    required this.requiresPhoto,
    this.photoUrl,
    this.doneAt,
    required this.updatedAt,
  });

  /// True only when: isDone AND (no photo required OR photo uploaded)
  bool get isComplete => isDone && (!requiresPhoto || photoUrl != null);

  factory ChecklistInstanceItem.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>?;
    return ChecklistInstanceItem(
      id: j['id'] as String,
      instanceId: j['instance_id'] as String,
      isDone: j['is_done'] as bool? ?? false,
      titleHe: item?['title_he'] as String? ?? '',
      requiresPhoto: item?['requires_photo'] as bool? ?? false,
      photoUrl: j['photo_url'] as String?,
      doneAt: j['done_at'] != null ? DateTime.parse(j['done_at'] as String) : null,
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }
}
