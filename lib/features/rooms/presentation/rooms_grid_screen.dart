import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import '../providers/rooms_provider.dart';
import 'room_tile.dart';

class RoomsGridScreen extends ConsumerWidget {
  const RoomsGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final byFloor = ref.watch(roomsByFloorProvider);
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
      (user?.appMetadata['role'] as String?) ?? 'receptionist');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rooms),
        actions: [
          if (role.isManager)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {/* navigate to room management */},
            ),
        ],
      ),
      body: byFloor.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: byFloor.entries.map((entry) {
              final floor = entry.key;
              final rooms = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      floor == 0 ? 'No Floor' : 'Floor $floor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, childAspectRatio: 1.1,
                      mainAxisSpacing: 8, crossAxisSpacing: 8,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) => RoomTile(
                      room: rooms[i],
                      onTap: () {/* show room tickets */},
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      // Legend
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _legend(Colors.green, l.available),
          _legend(Colors.orange, l.onHold),
          _legend(Colors.red, l.closed),
        ]),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12)),
  ]);
}
