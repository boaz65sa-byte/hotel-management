// lib/features/home/providers/housekeeping_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

final dirtyRoomsProvider = FutureProvider<List<RoomModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];

  final data = await supabase
      .from('rooms')
      .select()
      .eq('hotel_id', hotelId)
      .inFilter('housekeeping_status', ['dirty', 'cleaning'])
      .order('room_number');

  return (data as List).map((j) => RoomModel.fromJson(j as Map<String, dynamic>)).toList();
});
