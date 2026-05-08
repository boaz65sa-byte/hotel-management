// hotel_guest_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/i18n/locale_provider.dart';
import 'package:hotel_guest_app/core/supabase_init.dart';
import 'package:hotel_guest_app/l10n/app_localizations.dart';
import 'package:hotel_guest_app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: GuestApp()));
}

class GuestApp extends ConsumerStatefulWidget {
  const GuestApp({super.key});

  @override
  ConsumerState<GuestApp> createState() => _GuestAppState();
}

class _GuestAppState extends ConsumerState<GuestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Hotel Guest',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
        Locale('ar'),
        Locale('ru'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC9A84C),
          surface: const Color(0xFF0F1F3D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
      ),
      routerConfig: _router,
    );
  }
}
