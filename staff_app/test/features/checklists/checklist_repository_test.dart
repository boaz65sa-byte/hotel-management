import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

void main() {
  test('ChecklistInstance.isComplete false when completedAt null', () {
    final inst = ChecklistInstance(
      id: 'i1', templateId: 't1', hotelId: 'h1',
      createdAt: DateTime(2026), templateName: 'Test',
    );
    expect(inst.isComplete, false);
  });

  test('ChecklistInstance.isComplete true when completedAt set', () {
    final inst = ChecklistInstance(
      id: 'i1', templateId: 't1', hotelId: 'h1',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      templateName: 'Test',
    );
    expect(inst.isComplete, true);
  });
}
