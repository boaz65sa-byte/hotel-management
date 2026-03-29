// lib/features/checklists/presentation/checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/checklists/data/checklist_repository.dart';
import 'package:hotel_app/features/checklists/providers/checklist_provider.dart';
import 'package:hotel_app/features/checklists/presentation/checklist_item_tile.dart';

class ChecklistScreen extends ConsumerWidget {
  final String instanceId;
  const ChecklistScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsProvider(instanceId));
    final repo = ref.read(checklistRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('צ׳קליסט')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (items) {
          final done = items.where((i) => i.isComplete).length;
          final allDone = items.isNotEmpty && done == items.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('$done / ${items.length} הושלמו',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ChecklistItemTile(
                      item: item,
                      onToggle: (isDone) async {
                        await repo.toggleItem(item.id, isDone);
                        ref.invalidate(checklistItemsProvider(instanceId));
                      },
                      onCamera: item.requiresPhoto
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('העלאת תמונה — בקרוב')),
                              )
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('סיים צ׳קליסט'),
                  style: allDone
                      ? null
                      : FilledButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: allDone
                      ? () async {
                          await repo.completeInstance(instanceId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
