# Phase 1: Hotel Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing `HotelTheme.fromJson()` hex-color system with two named themes — `luxury` (dark gold) and `clean_blue` (white + blue) — selectable per hotel in the admin panel and applied globally on login.

**Architecture:** Add `theme TEXT` column to `hotels` DB table. Replace `HotelTheme` class with `AppTheme.forHotel(String theme)` returning a full `ThemeData`. Load theme at login from JWT/hotel record and store in `hotelThemeProvider`. Apply in `HotelApp` via `MaterialApp.router(theme:...)`.

**Tech Stack:** Flutter + Riverpod, Supabase (migration), Next.js admin panel (theme picker UI)

**Spec:** `docs/superpowers/specs/2026-03-25-hotel-pro-features-design.md` — Phase 1

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/core/theme/app_theme.dart` | Replace `HotelTheme` with `AppTheme.forHotel()` returning `ThemeData` |
| Modify | `lib/core/theme/theme_provider.dart` | Change to `StateProvider<ThemeData>` |
| Modify | `lib/app.dart` | Apply `themeProvider` to `MaterialApp.router` |
| Modify | `test/core/theme/app_theme_test.dart` | Update tests for new API |
| Create | `supabase/migrations/20260326000001_add_hotel_theme.sql` | Add `theme` column to `hotels` |
| Modify | `admin/src/app/dashboard/hotels/page.tsx` | Add theme picker, remove old hex color pickers |
| Create | `admin/src/app/api/hotels/[id]/route.ts` | PATCH endpoint for single hotel updates |

---

## Task 1: DB Migration — Add `theme` to hotels

**Files:**
- Create: `supabase/migrations/20260326000001_add_hotel_theme.sql`

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260326000001_add_hotel_theme.sql
ALTER TABLE hotels
  ADD COLUMN theme TEXT NOT NULL DEFAULT 'clean_blue'
    CHECK (theme IN ('luxury', 'clean_blue'));
```

- [ ] **Step 2: Apply via Supabase Dashboard SQL Editor**

Paste and run the SQL above. Verify with:
```sql
SELECT id, name, theme FROM hotels LIMIT 5;
```
Expected: all rows show `clean_blue` in theme column.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260326000001_add_hotel_theme.sql
git commit -m "feat: add theme column to hotels table"
```

---

## Task 2: Flutter — Replace `HotelTheme` with `AppTheme`

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Write failing tests first**

Replace contents of `test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme.forHotel', () {
    test('clean_blue returns light theme with blue primary', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF1E40AF));
    });

    test('luxury returns dark theme with gold primary', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFE4B800));
    });

    test('unknown value falls back to clean_blue', () {
      final theme = AppTheme.forHotel('unknown');
      expect(theme.brightness, Brightness.light);
    });

    test('clean_blue scaffold background is white', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF0F4FF));
    });

    test('luxury scaffold background is dark', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.scaffoldBackgroundColor, const Color(0xFF1A1A2E));
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
cd "/Users/boazsaada/manegmant resapceon"
/Users/boazsaada/flutter/bin/flutter test test/core/theme/app_theme_test.dart -v
```
Expected: FAIL — `AppTheme` not defined.

- [ ] **Step 3: Replace `app_theme.dart` with new implementation**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData forHotel(String theme) {
    switch (theme) {
      case 'luxury':
        return _luxuryTheme;
      default:
        return _cleanBlueTheme;
    }
  }

  static final ThemeData _cleanBlueTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E40AF),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF1E40AF),
      secondary: const Color(0xFF3B82F6),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E40AF),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFDBEAFE),
    ),
  );

  static final ThemeData _luxuryTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE4B800),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE4B800),
      secondary: const Color(0xFFFFD700),
      surface: const Color(0xFF16213E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Color(0xFFE4B800),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF16213E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x40E4B800)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF16213E),
      indicatorColor: Color(0x30E4B800),
    ),
  );
}
```

- [ ] **Step 4: Run tests — verify they PASS**

```bash
/Users/boazsaada/flutter/bin/flutter test test/core/theme/app_theme_test.dart -v
```
Expected: 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: replace HotelTheme with AppTheme.forHotel (luxury + clean_blue)"
```

---

## Task 3: Flutter — Update `theme_provider.dart`

**Files:**
- Modify: `lib/core/theme/theme_provider.dart`

- [ ] **Step 1: Replace provider to hold `ThemeData`**

```dart
// lib/core/theme/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Holds the active ThemeData for the current hotel.
/// Set after login using the hotel's theme string from Supabase.
final hotelThemeProvider = StateProvider<ThemeData>((ref) {
  return AppTheme.forHotel('clean_blue'); // default until login
});
```

- [ ] **Step 2: Run analyze — verify no errors**

```bash
/Users/boazsaada/flutter/bin/flutter analyze lib/core/theme/
```
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/theme_provider.dart
git commit -m "refactor: update hotelThemeProvider to hold ThemeData"
```

---

## Task 4: Flutter — Apply theme in `app.dart`

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add `theme` to `MaterialApp.router`**

In `lib/app.dart`, add `ref.watch(hotelThemeProvider)` and pass to `theme:`:

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';
import 'package:hotel_app/core/sync/sync_worker.dart';
import 'package:hotel_app/core/theme/theme_provider.dart';
import 'package:hotel_app/navigation/router.dart';

class HotelApp extends ConsumerWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale   = ref.watch(localeProvider);
    final router   = ref.watch(routerProvider);
    final theme    = ref.watch(hotelThemeProvider);
    ref.watch(syncWorkerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: theme,
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

- [ ] **Step 2: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test
```
Expected: All existing tests pass.

- [ ] **Step 3: Run web to visually verify Clean Blue theme is applied**

```bash
/Users/boazsaada/flutter/bin/flutter run -d chrome --web-port 8080
```
Expected: App loads with white/blue theme.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: apply hotelThemeProvider to MaterialApp"
```

---

## Task 5: Flutter — Load theme from Supabase after login

**Files:**
- Modify: `lib/features/auth/login_screen.dart`

- [ ] **Step 1: After successful login, fetch hotel theme from `public.users` table**

JWT custom claims (`appMetadata`) may not be populated on the first login response.
Instead, read `hotel_id` directly from `public.users` then fetch the hotel theme.

In `_LoginScreenState._login()`, after `signIn` succeeds:

```dart
// Inside _login() in lib/features/auth/login_screen.dart
// After: await ref.read(authRepositoryProvider).signIn(...)

// Read hotel_id from public.users (not JWT — claims may lag on first login)
final userId = supabase.auth.currentUser?.id;
if (userId != null) {
  final userRow = await supabase
      .from('users')
      .select('hotel_id')
      .eq('id', userId)
      .maybeSingle();
  final hotelId = userRow?['hotel_id'] as String?;
  if (hotelId != null) {
    final hotel = await supabase
        .from('hotels')
        .select('theme')
        .eq('id', hotelId)
        .single();
    final themeStr = hotel['theme'] as String? ?? 'clean_blue';
    ref.read(hotelThemeProvider.notifier).state = AppTheme.forHotel(themeStr);
  }
  // If no hotel_id (e.g. superAdmin) — default clean_blue remains, no action needed
}
```

Add imports at top of login_screen.dart:
```dart
import 'package:hotel_app/core/theme/app_theme.dart';
import 'package:hotel_app/core/theme/theme_provider.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
```

- [ ] **Step 2: Run analyze**

```bash
/Users/boazsaada/flutter/bin/flutter analyze lib/features/auth/login_screen.dart
```
Expected: No issues.

- [ ] **Step 3: Manually test in browser**
- Login as `superadmin@hotel.com` — no hotel_id → default Clean Blue (correct, no error)
- In Supabase Dashboard: `UPDATE hotels SET theme = 'luxury' WHERE name = 'Grand Hotel'`
- Login as `admin@grandhotel.com` → app should load in Luxury Dark gold theme
- Set back to `clean_blue` → login again → light blue theme

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/login_screen.dart
git commit -m "feat: load hotel theme from Supabase on login"
```

---

## Task 6: Admin Panel — Theme Picker

**Files:**
- Modify: `admin/src/app/dashboard/hotels/page.tsx`

- [ ] **Step 1: Add theme picker to the hotel edit form**

Find the hotel edit section in `page.tsx` and add a theme selector. Add this component inline in the hotel row or edit modal:

```tsx
// Theme picker — add where hotel settings are edited
<div className="flex items-center gap-3">
  <span className="text-sm font-medium text-gray-700">ערכת עיצוב:</span>
  <button
    onClick={() => updateHotelTheme(hotel.id, 'clean_blue')}
    className={`px-4 py-2 rounded-lg text-sm font-medium border-2 transition-all ${
      hotel.theme === 'clean_blue' || !hotel.theme
        ? 'border-blue-600 bg-blue-50 text-blue-700'
        : 'border-gray-200 text-gray-600 hover:border-blue-300'
    }`}
  >
    ☀️ Clean Blue
  </button>
  <button
    onClick={() => updateHotelTheme(hotel.id, 'luxury')}
    className={`px-4 py-2 rounded-lg text-sm font-medium border-2 transition-all ${
      hotel.theme === 'luxury'
        ? 'border-yellow-500 bg-yellow-50 text-yellow-700'
        : 'border-gray-200 text-gray-600 hover:border-yellow-300'
    }`}
  >
    🌙 Luxury Dark
  </button>
</div>
```

Add `updateHotelTheme` server action (or inline fetch) to `PATCH /api/hotels`:

```tsx
async function updateHotelTheme(hotelId: string, theme: string) {
  await fetch(`/api/hotels/${hotelId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ theme }),
  })
}
```

- [ ] **Step 2: Create `admin/src/app/api/hotels/[id]/route.ts`**

```bash
mkdir -p "admin/src/app/api/hotels/[id]"
```

```ts
// admin/src/app/api/hotels/[id]/route.ts
import { supabaseAdmin } from '@/lib/supabase-admin'
import { requireSuperAdmin } from '@/lib/auth-guard'

const ALLOWED_FIELDS = ['theme', 'name', 'is_active'] as const
type AllowedField = typeof ALLOWED_FIELDS[number]

export async function PATCH(
  req: Request,
  { params }: { params: { id: string } }
) {
  await requireSuperAdmin()
  const body = await req.json()

  // Whitelist fields — never allow arbitrary DB writes
  const safe: Partial<Record<AllowedField, unknown>> = {}
  for (const key of ALLOWED_FIELDS) {
    if (key in body) safe[key] = body[key]
  }

  const { data, error } = await supabaseAdmin
    .from('hotels')
    .update(safe)
    .eq('id', params.id)
    .select()
    .single()

  if (error) return Response.json({ error: error.message }, { status: 400 })
  return Response.json(data)
}
```

- [ ] **Step 3: Verify in browser**
- Open http://localhost:3000/dashboard/hotels
- Switch Grand Hotel to Luxury Dark → confirm DB: `SELECT theme FROM hotels WHERE name = 'Grand Hotel'`
- Old hex color pickers should be gone (removed in Step 1)
- Login to Flutter as `admin@grandhotel.com` → should see dark gold theme

- [ ] **Step 4: Commit**

```bash
git add admin/src/app/dashboard/hotels/page.tsx "admin/src/app/api/hotels/[id]/route.ts"
git commit -m "feat: add hotel theme picker + PATCH API route"
```

---

## Task 7: Final validation

- [ ] **Run all Flutter tests**

```bash
/Users/boazsaada/flutter/bin/flutter test
```
Expected: All tests pass (29+ tests).

- [ ] **Run Flutter analyze**

```bash
/Users/boazsaada/flutter/bin/flutter analyze
```
Expected: No issues.

- [ ] **Manual E2E check**
1. Set Grand Hotel to `luxury` in admin panel
2. Login as `admin@grandhotel.com` in Flutter web → see dark gold theme
3. Set back to `clean_blue` → login → see light blue theme
4. Login as `superadmin@hotel.com` (no hotel) → default clean blue

- [ ] **Final commit**

```bash
git add -A
git commit -m "feat: Phase 1 complete — hotel themes (luxury + clean_blue)"
```
