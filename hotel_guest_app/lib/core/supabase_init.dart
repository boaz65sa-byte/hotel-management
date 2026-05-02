// hotel_guest_app/lib/core/supabase_init.dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Same Supabase project as the hotel app.
// Anon key is safe to embed — public-role permissions only.
const _supabaseUrl  = 'https://vetwlonyzyzvhrtdwbzj.supabase.co';
const _supabaseAnon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZldHdsb255enl6dmhydGR3YnpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxODM2NDgsImV4cCI6MjA4OTc1OTY0OH0.ycDWffdTHXnGJrIV0z63K652giS2OA2vEShJ3MEQ5fo';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnon);
}

SupabaseClient get supabase => Supabase.instance.client;
