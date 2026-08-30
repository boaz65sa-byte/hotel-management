// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'core/supabase/supabase_client.dart';
import 'core/database/local_db.dart';
import 'app.dart';
import 'package:hotel_app/core/push/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  // Web hosts (e.g. Netlify) refuse to serve dotfiles such as ".env",
  // so we ship a duplicate at "assets/env" and prefer it on web.
  await dotenv.load(fileName: kIsWeb ? 'assets/env' : '.env');
  final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  if (oneSignalAppId.isNotEmpty) {
    PushService.initOneSignal(oneSignalAppId);
  }
  await initSupabase();
  try {
    await LocalDb.instance; // pre-warm SQLite
  } catch (e) {
    // Local cache is an optimization (offline queue + cached lists), not a
    // hard requirement — a network-connected user shouldn't get a blank
    // white screen because sqflite_common_ffi_web's wasm worker failed to
    // load (e.g. missing COOP/COEP headers on some hosts).
    debugPrint('LocalDb pre-warm failed, continuing without offline cache: $e');
  }
  runApp(const ProviderScope(child: HotelApp()));
}
