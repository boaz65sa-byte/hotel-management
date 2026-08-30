import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

void main() {
  group('ChecklistTemplate', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'tmpl1', 'name': 'ניקיון רגיל', 'type': 'housekeeping',
        'is_vip': false, 'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final t = ChecklistTemplate.fromJson(json);
      expect(t.name, 'ניקיון רגיל');
      expect(t.type, 'housekeeping');
      expect(t.isVip, false);
    });
  });

  group('ChecklistInstanceItem', () {
    test('fromJson parses isDone', () {
      final json = {
        'id': 'ii1', 'instance_id': 'inst1', 'is_done': true,
        'updated_at': '2026-01-01T00:00:00Z',
        'item': {'title_he': 'ניקוי אמבטיה', 'requires_photo': false},
      };
      final item = ChecklistInstanceItem.fromJson(json);
      expect(item.isDone, true);
      expect(item.titleHe, 'ניקוי אמבטיה');
    });

    test('isComplete false when requiresPhoto and no photoUrl', () {
      final item = ChecklistInstanceItem(
        id: 'i1', instanceId: 'inst1', isDone: true,
        titleHe: 'בדיקה', requiresPhoto: true, photoUrl: null,
        updatedAt: DateTime.now(),
      );
      expect(item.isComplete, false);
    });

    test('isComplete true when isDone and photo present', () {
      final item = ChecklistInstanceItem(
        id: 'i1', instanceId: 'inst1', isDone: true,
        titleHe: 'בדיקה', requiresPhoto: true,
        photoUrl: 'https://example.com/photo.jpg',
        updatedAt: DateTime.now(),
      );
      expect(item.isComplete, true);
    });

    test('isComplete true when isDone and no photo required', () {
      final item = ChecklistInstanceItem(
        id: 'i1', instanceId: 'inst1', isDone: true,
        titleHe: 'בדיקה', requiresPhoto: false,
        updatedAt: DateTime.now(),
      );
      expect(item.isComplete, true);
    });
  });
}
