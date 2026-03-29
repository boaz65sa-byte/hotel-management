import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';
import 'package:hotel_app/features/checklists/presentation/checklist_item_tile.dart';

void main() {
  testWidgets('ChecklistItemTile shows checkbox and title', (tester) async {
    final item = ChecklistInstanceItem(
      id: 'i1', instanceId: 'inst1', isDone: false,
      titleHe: 'ניקוי אמבטיה', requiresPhoto: false, updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ChecklistItemTile(item: item, onToggle: (_) async {})),
        ),
      ),
    );
    expect(find.text('ניקוי אמבטיה'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('ChecklistItemTile shows red camera icon when photo required but missing', (tester) async {
    final item = ChecklistInstanceItem(
      id: 'i1', instanceId: 'inst1', isDone: false,
      titleHe: 'בדיקת מיזוג', requiresPhoto: true, photoUrl: null,
      updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ChecklistItemTile(item: item, onToggle: (_) async {})),
        ),
      ),
    );
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
