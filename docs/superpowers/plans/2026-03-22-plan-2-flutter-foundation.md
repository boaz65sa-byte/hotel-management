# Hotel Management App - Plan 2: Flutter Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Flutter app skeleton — project setup, i18n (Hebrew/English/Arabic + RTL), white-label theming engine, Supabase client, SQLite offline cache, sync queue, connectivity detection, auth flow (login + session), and app navigation — so all feature plans (Plans 3 and 4) have a solid foundation to build on.

**Architecture:** Flutter project targeting iOS, Android, and Web from a single codebase. Supabase Flutter SDK for auth + data. `sqflite` for local SQLite cache. `connectivity_plus` for online detection. `flutter_riverpod` for state management. `go_router` for navigation. `flutter_localizations` + `intl` for i18n.

**Tech Stack:** Flutter 3.x, Dart, supabase_flutter, sqflite, flutter_riverpod, go_router, connectivity_plus, intl, flutter_localizations, cached_network_image

---

## Prerequisites

- Plan 1 (Supabase Backend) complete
- Flutter SDK installed: `flutter doctor` passes
- Xcode (for iOS) and Android Studio (for Android) installed
- `.env` file with Supabase URL and anon key

---

## File Structure

```
lib/
├── main.dart                          # App entry point, providers, theme init
├── app.dart                           # MaterialApp + GoRouter + theme consumer
├── core/
│   ├── supabase/
│   │   ├── supabase_client.dart       # Supabase singleton init
│   │   └── supabase_extensions.dart   # JWT claim helpers
│   ├── database/
│   │   ├── local_db.dart              # SQLite init + migrations
│   │   ├── sync_queue.dart            # Offline action queue
│   │   └── sync_service.dart          # Runs queue when online
│   ├── auth/
│   │   ├── auth_repository.dart       # login, logout, session
│   │   ├── auth_state.dart            # Riverpod auth state
│   │   └── session_timeout.dart       # Per-hotel session timer
│   ├── connectivity/
│   │   └── connectivity_service.dart  # Online/offline stream
│   ├── theme/
│   │   ├── app_theme.dart             # Build ThemeData from hotel colors
│   │   └── theme_provider.dart        # Riverpod: fetch + cache theme
│   └── i18n/
│       ├── app_localizations.dart     # Generated (do not edit)
│       ├── arb/
│       │   ├── app_en.arb
│       │   ├── app_he.arb
│       │   └── app_ar.arb
│       └── locale_provider.dart       # Riverpod: current locale
├── features/
│   └── auth/
│       ├── login_screen.dart
│       └── login_controller.dart
├── navigation/
│   └── router.dart                    # GoRouter config + auth guard
└── shared/
    └── widgets/
        └── offline_banner.dart        # "You are offline" banner
```

---

## Task 1: Flutter Project Setup

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `.env` (not committed)

- [ ] **Step 1: Create Flutter project**

```bash
cd "/Users/boazsaada/manegmant resapceon"
flutter create hotel_app --org com.hotelapp --platforms ios,android,web
mv hotel_app/* . && rm -rf hotel_app
```

- [ ] **Step 2: Replace pubspec.yaml dependencies**

```yaml
name: hotel_app
description: Hotel service ticket management
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.5.0

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # Local storage
  sqflite: ^2.3.3
  path: ^1.9.0

  # Connectivity
  connectivity_plus: ^6.0.3

  # i18n
  intl: ^0.19.0

  # Utilities
  cached_network_image: ^3.3.1
  image_picker: ^1.1.2
  excel: ^4.0.3
  flutter_dotenv: ^5.1.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
  mocktail: ^1.0.4
  sqflite_common_ffi: ^2.3.3  # required for SQLite unit tests on desktop/CI

flutter:
  uses-material-design: true
  generate: true  # enables l10n generation
  assets:
    - assets/images/
    - .env
```

- [ ] **Step 3: Run pub get**

```bash
flutter pub get
```
Expected: No errors.

- [ ] **Step 4: Create assets directory**

```bash
mkdir -p lib/core/supabase lib/core/database lib/core/auth \
         lib/core/connectivity lib/core/theme lib/core/i18n/arb \
         lib/features/auth lib/navigation lib/shared/widgets \
         assets/images
touch assets/images/.gitkeep
```

- [ ] **Step 5: Create .env file (not committed)**

```bash
cat > .env << 'EOF'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
EOF
```

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/ assets/ .gitignore
git commit -m "feat: initialize flutter project with dependencies"
```

---

## Task 2: i18n Setup (Hebrew, English, Arabic)

**Files:**
- Create: `lib/l10n.yaml`
- Create: `lib/core/i18n/arb/app_en.arb`
- Create: `lib/core/i18n/arb/app_he.arb`
- Create: `lib/core/i18n/arb/app_ar.arb`
- Create: `lib/core/i18n/locale_provider.dart`

- [ ] **Step 1: Create l10n.yaml at project root (NOT inside lib/)**

```yaml
# l10n.yaml  ← project root, same level as pubspec.yaml
arb-dir: lib/core/i18n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/core/i18n
```

```bash
# Verify it's at the right path:
ls "/Users/boazsaada/manegmant resapceon/hotel_app/l10n.yaml"
```

- [ ] **Step 2: Write English ARB (template)**

```json
{
  "@@locale": "en",
  "appName": "Hotel Management",
  "login": "Login",
  "email": "Email",
  "password": "Password",
  "logout": "Logout",
  "myTickets": "My Tickets",
  "deptQueue": "Department Queue",
  "newTicket": "New Ticket",
  "rooms": "Rooms",
  "profile": "Profile",
  "offline": "You are offline",
  "claimTicket": "Claim Ticket",
  "claimRequiresConnection": "Claiming requires internet connection",
  "ticketFixed": "Fixed",
  "ticketOnHold": "On Hold",
  "ticketRoomClosed": "Room Closed",
  "pendingApproval": "Pending Approval",
  "approve": "Approve",
  "reject": "Reject",
  "addPhoto": "Add Photo",
  "addComment": "Add Comment",
  "analytics": "Analytics",
  "users": "Users",
  "saveChanges": "Save Changes",
  "cancel": "Cancel",
  "loading": "Loading...",
  "errorGeneric": "Something went wrong",
  "available": "Available",
  "onHold": "On Hold",
  "closed": "Closed",
  "priority_low": "Low",
  "priority_normal": "Normal",
  "priority_high": "High",
  "priority_urgent": "Urgent"
}
```

- [ ] **Step 3: Write Hebrew ARB**

```json
{
  "@@locale": "he",
  "appName": "ניהול מלון",
  "login": "כניסה",
  "email": "אימייל",
  "password": "סיסמה",
  "logout": "יציאה",
  "myTickets": "הקריאות שלי",
  "deptQueue": "תור המחלקה",
  "newTicket": "קריאה חדשה",
  "rooms": "חדרים",
  "profile": "פרופיל",
  "offline": "אין חיבור לאינטרנט",
  "claimTicket": "קח אחריות",
  "claimRequiresConnection": "לקיחת אחריות דורשת חיבור לאינטרנט",
  "ticketFixed": "תוקן",
  "ticketOnHold": "בהמתנה",
  "ticketRoomClosed": "חדר סגור",
  "pendingApproval": "ממתין לאישור",
  "approve": "אשר",
  "reject": "דחה",
  "addPhoto": "הוסף תמונה",
  "addComment": "הוסף הערה",
  "analytics": "נתונים",
  "users": "משתמשים",
  "saveChanges": "שמור שינויים",
  "cancel": "ביטול",
  "loading": "טוען...",
  "errorGeneric": "משהו השתבש",
  "available": "פנוי",
  "onHold": "בהמתנה",
  "closed": "סגור",
  "priority_low": "נמוך",
  "priority_normal": "רגיל",
  "priority_high": "גבוה",
  "priority_urgent": "דחוף"
}
```

- [ ] **Step 4: Write Arabic ARB**

```json
{
  "@@locale": "ar",
  "appName": "إدارة الفندق",
  "login": "تسجيل الدخول",
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور",
  "logout": "تسجيل الخروج",
  "myTickets": "طلباتي",
  "deptQueue": "قائمة القسم",
  "newTicket": "طلب جديد",
  "rooms": "الغرف",
  "profile": "الملف الشخصي",
  "offline": "لا يوجد اتصال بالإنترنت",
  "claimTicket": "استلام الطلب",
  "claimRequiresConnection": "استلام الطلب يتطلب اتصالاً بالإنترنت",
  "ticketFixed": "تم الإصلاح",
  "ticketOnHold": "في الانتظار",
  "ticketRoomClosed": "الغرفة مغلقة",
  "pendingApproval": "في انتظار الموافقة",
  "approve": "موافقة",
  "reject": "رفض",
  "addPhoto": "إضافة صورة",
  "addComment": "إضافة تعليق",
  "analytics": "التحليلات",
  "users": "المستخدمون",
  "saveChanges": "حفظ التغييرات",
  "cancel": "إلغاء",
  "loading": "جار التحميل...",
  "errorGeneric": "حدث خطأ ما",
  "available": "متاح",
  "onHold": "في الانتظار",
  "closed": "مغلق",
  "priority_low": "منخفض",
  "priority_normal": "عادي",
  "priority_high": "مرتفع",
  "priority_urgent": "عاجل"
}
```

- [ ] **Step 5: Generate localizations**

```bash
flutter gen-l10n
```
Expected: `lib/core/i18n/app_localizations.dart` generated.

- [ ] **Step 6: Write locale provider**

```dart
// lib/core/i18n/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('he'); // default; overridden after login
});
```

- [ ] **Step 7: Write test for locale**

```dart
// test/core/i18n/locale_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';

void main() {
  test('default locale is Hebrew', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(localeProvider).languageCode, 'he');
  });

  test('locale can be changed to Arabic', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).state = const Locale('ar');
    expect(container.read(localeProvider).languageCode, 'ar');
  });
}
```

- [ ] **Step 8: Run test**

```bash
flutter test test/core/i18n/locale_provider_test.dart
```
Expected: 2 tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/core/i18n/ lib/l10n.yaml test/
git commit -m "feat: add i18n support (Hebrew, English, Arabic)"
```

---

## Task 3: Supabase Client + Theme Engine

**Files:**
- Create: `lib/core/supabase/supabase_client.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/theme_provider.dart`

- [ ] **Step 1: Write Supabase client**

```dart
// lib/core/supabase/supabase_client.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
```

- [ ] **Step 2: Write theme engine**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class HotelTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String? logoUrl;

  const HotelTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    this.logoUrl,
  });

  static const HotelTheme defaultTheme = HotelTheme(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF424242),
    accent: Color(0xFFFF6F00),
  );

  factory HotelTheme.fromJson(Map<String, dynamic> json, {String? logoUrl}) {
    return HotelTheme(
      primary: Color(int.parse((json['primary'] as String).replaceFirst('#', '0xFF'))),
      secondary: Color(int.parse((json['secondary'] as String).replaceFirst('#', '0xFF'))),
      accent: Color(int.parse((json['accent'] as String).replaceFirst('#', '0xFF'))),
      logoUrl: logoUrl,
    );
  }

  ThemeData toThemeData({bool isRtl = false}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        tertiary: accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
```

- [ ] **Step 3: Write theme tests**

```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hotel_app/core/theme/app_theme.dart';

void main() {
  test('HotelTheme parses hex colors from JSON', () {
    final theme = HotelTheme.fromJson({
      'primary': '#1976D2',
      'secondary': '#424242',
      'accent': '#FF6F00',
    });
    expect(theme.primary, const Color(0xFF1976D2));
    expect(theme.secondary, const Color(0xFF424242));
    expect(theme.accent, const Color(0xFFFF6F00));
  });

  test('defaultTheme is valid', () {
    final td = HotelTheme.defaultTheme.toThemeData();
    expect(td, isA<ThemeData>());
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/theme/
```
Expected: Pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/supabase/ lib/core/theme/ test/core/
git commit -m "feat: add supabase client and theme engine"
```

---

## Task 4: Connectivity + Offline Banner

**Files:**
- Create: `lib/core/connectivity/connectivity_service.dart`
- Create: `lib/shared/widgets/offline_banner.dart`

- [ ] **Step 1: Write connectivity service**

```dart
// lib/core/connectivity/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (online) => online,
    orElse: () => true, // assume online until proven otherwise
  );
});
```

- [ ] **Step 2: Write offline banner widget**

```dart
// lib/shared/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.red.shade800,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        AppLocalizations.of(context)!.offline,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
```

- [ ] **Step 3: Write widget test**

```dart
// test/shared/widgets/offline_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import 'package:hotel_app/shared/widgets/offline_banner.dart';

void main() {
  testWidgets('OfflineBanner is hidden when online', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('OfflineBanner is visible when offline', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );
    expect(find.byType(Container), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run test**

```bash
flutter test test/shared/
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/connectivity/ lib/shared/ test/shared/
git commit -m "feat: add connectivity service and offline banner"
```

---

## Task 5: SQLite Local Cache

**Files:**
- Create: `lib/core/database/local_db.dart`
- Create: `lib/core/database/sync_queue.dart`

- [ ] **Step 1: Write local DB setup**

```dart
// lib/core/database/local_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'hotel_app.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Sync queue: offline actions waiting to be sent
    await db.execute('''
      CREATE TABLE sync_queue (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        action      TEXT NOT NULL,
        payload     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        attempts    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Cached tickets for offline reading
    await db.execute('''
      CREATE TABLE cached_tickets (
        id            TEXT PRIMARY KEY,
        hotel_id      TEXT NOT NULL,
        data          TEXT NOT NULL,
        synced_at     TEXT NOT NULL
      )
    ''');

    // Cached rooms
    await db.execute('''
      CREATE TABLE cached_rooms (
        id        TEXT PRIMARY KEY,
        hotel_id  TEXT NOT NULL,
        data      TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    // Theme config cache
    await db.execute('''
      CREATE TABLE hotel_config (
        hotel_id        TEXT PRIMARY KEY,
        theme_colors    TEXT,
        logo_url        TEXT,
        default_language TEXT,
        cached_at       TEXT NOT NULL
      )
    ''');
  }
}
```

- [ ] **Step 2: Write sync queue**

```dart
// lib/core/database/sync_queue.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_db.dart';

class SyncQueue {
  static Future<void> enqueue(String action, Map<String, dynamic> payload) async {
    final db = await LocalDb.instance;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> pending() async {
    final db = await LocalDb.instance;
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  static Future<void> remove(int id) async {
    final db = await LocalDb.instance;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> incrementAttempts(int id) async {
    final db = await LocalDb.instance;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?', [id]);
  }
}
```

- [ ] **Step 3: Write sync queue test**

```dart
// test/core/database/sync_queue_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hotel_app/core/database/sync_queue.dart';
import 'package:hotel_app/core/database/local_db.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Reset DB for each test
    final db = await LocalDb.instance;
    await db.delete('sync_queue');
  });

  test('enqueue adds item, pending returns it, remove clears it', () async {
    await SyncQueue.enqueue('create_ticket', {'title': 'Test'});
    final items = await SyncQueue.pending();
    expect(items.length, 1);
    expect(items.first['action'], 'create_ticket');

    await SyncQueue.remove(items.first['id'] as int);
    expect((await SyncQueue.pending()).length, 0);
  });
}
```

- [ ] **Step 4: Run test**

```bash
flutter test test/core/database/
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/ test/core/database/
git commit -m "feat: add sqlite local cache and sync queue"
```

---

## Task 6: Auth Repository + Login Screen

**Files:**
- Create: `lib/core/auth/auth_repository.dart`
- Create: `lib/core/auth/auth_state.dart`
- Create: `lib/features/auth/login_screen.dart`

- [ ] **Step 1: Write auth repository**

```dart
// lib/core/auth/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

class AuthRepository {
  Future<AuthResponse> signIn(String email, String password) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Extract hotel_id from JWT custom claims
  String? get hotelId {
    final claims = currentSession?.user.appMetadata;
    return claims?['hotel_id'] as String?;
  }

  /// Extract role from JWT custom claims
  String? get role {
    final claims = currentSession?.user.appMetadata;
    return claims?['role'] as String?;
  }
}
```

- [ ] **Step 2: Write auth state provider**

```dart
// lib/core/auth/auth_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});
```

- [ ] **Step 3: Write login screen**

```dart
// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_repository.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signIn(_emailCtrl.text.trim(), _passCtrl.text);
      // Router will redirect automatically via auth guard
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language selector
                DropdownButton<String>(
                  value: locale.languageCode,
                  items: const [
                    DropdownMenuItem(value: 'he', child: Text('עברית')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  ],
                  onChanged: (lang) {
                    if (lang != null) {
                      ref.read(localeProvider.notifier).state = Locale(lang);
                    }
                  },
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(labelText: l.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  decoration: InputDecoration(labelText: l.password),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                _loading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: _login,
                      child: Text(l.login),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write login test**

```dart
// test/features/auth/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hotel_app/core/auth/auth_repository.dart';
import 'package:hotel_app/features/auth/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('LoginScreen shows email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/features/auth/
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/auth/ lib/features/auth/ test/features/
git commit -m "feat: add auth repository and login screen"
```

---

## Task 7: Navigation (GoRouter + Auth Guard)

**Files:**
- Create: `lib/navigation/router.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write router**

```dart
// lib/navigation/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/auth/login_screen.dart';

// Placeholder screens — replaced in Plans 3 and 4
import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home')));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    redirect: (context, state) {
      final loggedIn = authState.maybeWhen(
        data: (s) => s.session != null,
        orElse: () => false,
      );
      final isLoginRoute = state.matchedLocation == '/login';
      if (!loggedIn && !isLoginRoute) return '/login';
      if (loggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/',      builder: (_, __) => const HomeScreen()),
    ],
  );
});
```

- [ ] **Step 2: Write app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';
import 'package:hotel_app/navigation/router.dart';

class HotelApp extends ConsumerWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
```

- [ ] **Step 3: Write main.dart**

```dart
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
```

- [ ] **Step 4: Run app**

```bash
flutter run -d chrome  # test web first
```
Expected: Login screen appears in Hebrew (RTL).

- [ ] **Step 5: Test login with seed user**

Enter `admin@hotelalpha.test` + password → should redirect to Home screen.

- [ ] **Step 6: Commit**

```bash
git add lib/navigation/ lib/app.dart lib/main.dart
git commit -m "feat: add go_router navigation with auth guard"
```

---

## Task 8: Session Timeout

**Files:**
- Create: `lib/core/auth/session_timeout.dart`

- [ ] **Step 1: Write session timeout service**

```dart
// lib/core/auth/session_timeout.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'auth_repository.dart';

/// Monitors inactivity and signs out the user after hotel.session_timeout_min
class SessionTimeoutService {
  Timer? _timer;
  final int timeoutMinutes;
  final VoidCallback onTimeout;

  SessionTimeoutService({required this.timeoutMinutes, required this.onTimeout});

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: timeoutMinutes), onTimeout);
  }

  void dispose() => _timer?.cancel();
}

/// Fetch the session timeout for current user's hotel
Future<int> fetchSessionTimeoutMinutes() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 480;
  final res = await supabase
    .from('users')
    .select('hotel:hotels(session_timeout_min)')
    .eq('id', userId)
    .single();
  return (res['hotel']?['session_timeout_min'] as int?) ?? 480;
}
```

- [ ] **Step 2: Write test**

```dart
// test/core/auth/session_timeout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/auth/session_timeout.dart';

void main() {
  test('SessionTimeoutService calls onTimeout after duration', () async {
    bool triggered = false;
    final service = SessionTimeoutService(
      timeoutMinutes: 0, // instant for test
      onTimeout: () => triggered = true,
    );
    service.resetTimer();
    await Future.delayed(const Duration(milliseconds: 10));
    expect(triggered, true);
    service.dispose();
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/core/auth/session_timeout_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/auth/session_timeout.dart test/core/auth/
git commit -m "feat: add per-hotel session timeout service"
```

---

## Verification Checklist

Before moving to Plan 3, confirm:

- [ ] `flutter test` passes all tests
- [ ] App runs on web (`flutter run -d chrome`)
- [ ] Login works with seed Supabase user
- [ ] Language switcher changes text on login screen (RTL for Hebrew/Arabic)
- [ ] Offline banner appears when network is disabled (test with DevTools → Network → Offline)
- [ ] Sync queue enqueue/dequeue works in unit tests
