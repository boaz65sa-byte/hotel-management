import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/user_model.dart';

class UsersRepository {
  Future<List<HotelUser>> fetchAll() async {
    final res = await supabase
      .from('users')
      .select()
      .order('full_name');
    return (res as List).map((j) => HotelUser.fromJson(j)).toList();
  }

  Future<void> toggleActive(String userId, bool isActive) async {
    await supabase.from('users').update({'is_active': isActive}).eq('id', userId);
  }

  Future<void> updateRole(String userId, String role) async {
    await supabase.from('users').update({'role': role}).eq('id', userId);
  }

  /// Invite new user (sends Supabase auth invite email)
  Future<void> inviteUser({
    required String email,
    required String fullName,
    required String role,
    required String hotelId,
  }) async {
    await supabase.functions.invoke('invite-user', body: {
      'email': email, 'full_name': fullName, 'role': role, 'hotel_id': hotelId,
    });
  }
}
