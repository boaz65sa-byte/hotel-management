// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/supabase/supabase_client.dart';
import 'core/database/local_db.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initSupabase();
  await LocalDb.instance; // pre-warm SQLite
  runApp(const ProviderScope(child: HotelApp()));
}
