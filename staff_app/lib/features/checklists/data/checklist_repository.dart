// lib/features/checklists/data/checklist_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

final checklistRepositoryProvider = Provider((_) => ChecklistRepository());

class ChecklistRepository {
  Future<List<ChecklistTemplate>> fetchTemplates() async {
    final data = await supabase
        .from('checklist_templates')
        .select()
        .order('name');
    return (data as List).map((j) => ChecklistTemplate.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ChecklistInstance>> fetchActiveInstances(String hotelId) async {
    final data = await supabase
        .from('checklist_instances')
        .select('*, template:checklist_templates(name)')
        .eq('hotel_id', hotelId)
        .filter('completed_at', 'is', null)
        .order('created_at', ascending: false);
    return (data as List).map((j) => ChecklistInstance.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ChecklistInstanceItem>> fetchInstanceItems(String instanceId) async {
    final data = await supabase
        .from('checklist_instance_items')
        .select('*, item:checklist_items(title_he, requires_photo)')
        .eq('instance_id', instanceId)
        .order('updated_at');
    return (data as List).map((j) => ChecklistInstanceItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<String> createInstance({
    required String templateId,
    required String hotelId,
    String? roomId,
    String? assignedTo,
  }) async {
    final instance = await supabase
        .from('checklist_instances')
        .insert({
          'template_id': templateId,
          'hotel_id': hotelId,
          if (roomId != null) 'room_id': roomId,
          if (assignedTo != null) 'assigned_to': assignedTo,
        })
        .select()
        .single();
    final instanceId = instance['id'] as String;

    final items = await supabase
        .from('checklist_items')
        .select()
        .eq('template_id', templateId)
        .order('order_index');

    final instanceItems = (items as List).map((item) => {
      'instance_id': instanceId,
      'item_id': item['id'],
    }).toList();

    await supabase.from('checklist_instance_items').insert(instanceItems);
    return instanceId;
  }

  Future<void> toggleItem(String itemId, bool isDone) async {
    await supabase.from('checklist_instance_items').update({
      'is_done': isDone,
      'done_at': isDone ? DateTime.now().toIso8601String() : null,
    }).eq('id', itemId);
  }

  Future<void> completeInstance(String instanceId) async {
    await supabase.from('checklist_instances').update({
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', instanceId);
  }
}
