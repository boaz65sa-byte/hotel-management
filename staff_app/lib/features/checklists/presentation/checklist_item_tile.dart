// lib/features/checklists/presentation/checklist_item_tile.dart
import 'package:flutter/material.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistInstanceItem item;
  final Future<void> Function(bool isDone) onToggle;
  final VoidCallback? onCamera;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.isDone,
        onChanged: (v) => onToggle(v ?? false),
      ),
      title: Text(
        item.titleHe,
        style: TextStyle(
          decoration: item.isDone ? TextDecoration.lineThrough : null,
          color: item.isDone ? Colors.grey : null,
        ),
      ),
      trailing: item.requiresPhoto
          ? IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: item.photoUrl != null ? Colors.green : Colors.red,
              ),
              onPressed: onCamera,
              tooltip: item.photoUrl != null ? 'תמונה הועלתה' : 'נדרשת תמונה',
            )
          : null,
    );
  }
}
