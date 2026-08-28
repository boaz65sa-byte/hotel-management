// hotel_guest_app/lib/core/supabase_init.dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Same Supabase project as the hotel app.
// Anon key is safe to embed — public-role permissions only.
const _supabaseUrl  = 'https://vetwlonyzyzvhrtdwbzj.supabase.co';
const _supabaseAnon = 'sb_publishable_I3AU7CkzMDJQ9tlVPS9wUA_Hx8BRGAB';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnon);
}

SupabaseClient get supabase => Supabase.instance.client;
