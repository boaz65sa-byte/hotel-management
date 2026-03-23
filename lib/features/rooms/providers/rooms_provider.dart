import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';

final roomRepoProvider = Provider<RoomRepository>((_) => RoomRepository());

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  return ref.watch(roomRepoProvider).fetchAll();
});

// Group rooms by floor
final roomsByFloorProvider = Provider<Map<int, List<Room>>>((ref) {
  final rooms = ref.watch(roomsProvider).maybeWhen(
    data: (r) => r, orElse: () => <Room>[]);
  final map = <int, List<Room>>{};
  for (final room in rooms) {
    map.putIfAbsent(room.floor ?? 0, () => []).add(room);
  }
  return map;
});
