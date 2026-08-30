// lib/features/checklists/providers/checklist_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/checklists/data/checklist_repository.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

final checklistTemplatesProvider = FutureProvider<List<ChecklistTemplate>>((ref) {
  return ref.read(checklistRepositoryProvider).fetchTemplates();
});

final activeChecklistsProvider = FutureProvider<List<ChecklistInstance>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref.read(checklistRepositoryProvider).fetchActiveInstances(hotelId);
});

final checklistItemsProvider = FutureProvider.family<List<ChecklistInstanceItem>, String>(
  (ref, instanceId) {
    return ref.read(checklistRepositoryProvider).fetchInstanceItems(instanceId);
  },
);
