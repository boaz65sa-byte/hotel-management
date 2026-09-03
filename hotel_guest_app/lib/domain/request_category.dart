/// A guest-request category, as configured per hotel by the super admin.
/// System categories (housekeeping/maintenance/reception) ship curated
/// quick-select tiles in the client; custom ones fall back to free text.
class RequestCategory {
  final String key;
  final String label;
  final String icon;
  final bool isSystem;

  const RequestCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.isSystem,
  });

  factory RequestCategory.fromJson(Map<String, dynamic> j) => RequestCategory(
    key:      j['key'] as String,
    label:    j['label'] as String,
    icon:     j['icon'] as String? ?? '📋',
    isSystem: j['is_system'] as bool? ?? false,
  );
}
