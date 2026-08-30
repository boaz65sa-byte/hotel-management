import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import 'package:hotel_app/shared/widgets/offline_banner.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, bool isOnline) {
  return ProviderScope(
    overrides: [isOnlineProvider.overrideWithValue(isOnline)],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('OfflineBanner is hidden when online', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineBanner(), true));
    await tester.pump();
    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('OfflineBanner is visible when offline', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineBanner(), false));
    await tester.pump();
    expect(find.byType(Container), findsOneWidget);
  });
}
