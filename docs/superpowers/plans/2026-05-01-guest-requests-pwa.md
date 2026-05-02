# Guest Requests PWA — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter Web PWA that guests open via QR code — enter name + room number, submit service requests, track status, and leave end-of-stay feedback. Shares the same Supabase backend as the hotel app.

**Architecture:** Separate Flutter Web project at `hotel_guest_app/` in the repo root. Uses the same Supabase URL/anon key. Session (guest_name, room_number, hotel_id) stored in SharedPreferences (localStorage on web). `hotel_id` read from URL query param `?hotel=<id>`. PWA manifest enables "Add to Home Screen" prompt.

**Tech Stack:** Flutter Web + Riverpod + go_router + supabase_flutter + shared_preferences

**Prerequisite:** Complete the Hotel App plan first (`2026-05-01-guest-requests-hotel-app.md`) — the DB tables and RLS policies must exist before running the PWA.

---

## File Map

| Action | File |
|--------|------|
| Create | `hotel_guest_app/pubspec.yaml` |
| Create | `hotel_guest_app/web/manifest.json` |
| Modify | `hotel_guest_app/web/index.html` (add manifest link) |
| Create | `hotel_guest_app/lib/core/supabase_init.dart` |
| Create | `hotel_guest_app/lib/core/session.dart` |
| Create | `hotel_guest_app/lib/domain/guest_request.dart` |
| Create | `hotel_guest_app/lib/data/guest_repository.dart` |
| Create | `hotel_guest_app/lib/providers/providers.dart` |
| Create | `hotel_guest_app/lib/presentation/landing_screen.dart` |
| Create | `hotel_guest_app/lib/presentation/home_screen.dart` |
| Create | `hotel_guest_app/lib/presentation/new_request_screen.dart` |
| Create | `hotel_guest_app/lib/presentation/feedback_screen.dart` |
| Create | `hotel_guest_app/lib/router.dart` |
| Create | `hotel_guest_app/lib/main.dart` |

---

### Task 1: Create Flutter Web project

**Files:**
- Create: `hotel_guest_app/pubspec.yaml` and project scaffold

- [ ] **Step 1: Create Flutter Web project**

Run from the repo root (`/Users/boazsaada/manegmant resapceon`):

```bash
flutter create --platforms=web --org com.hotel hotel_guest_app
```

- [ ] **Step 2: Replace `hotel_guest_app/pubspec.yaml`**

```yaml
name: hotel_guest_app
description: Hotel guest PWA for submitting service requests
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  supabase_flutter: ^2.5.0
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  shared_preferences: ^2.3.2

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Install dependencies**

```bash
cd hotel_guest_app && flutter pub get
```

Expected: Dependencies resolved, no errors.

- [ ] **Step 4: Commit**

```bash
cd ..
git add hotel_guest_app/
git commit -m "feat: scaffold hotel_guest_app Flutter Web project"
```

---

### Task 2: PWA manifest + theme

**Files:**
- Create: `hotel_guest_app/web/manifest.json`
- Modify: `hotel_guest_app/web/index.html`

- [ ] **Step 1: Create `hotel_guest_app/web/manifest.json`**

```json
{
  "name": "Hotel Guest",
  "short_name": "Guest",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0a1628",
  "theme_color": "#c9a84c",
  "description": "Submit hotel service requests",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

- [ ] **Step 2: Add manifest link to `hotel_guest_app/web/index.html`**

Inside `<head>`, add after the existing `<meta>` tags:

```html
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#c9a84c">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
```

- [ ] **Step 3: Commit**

```bash
git add hotel_guest_app/web/
git commit -m "feat: add PWA manifest and meta tags to guest app"
```

---

### Task 3: Supabase init + session storage

**Files:**
- Create: `hotel_guest_app/lib/core/supabase_init.dart`
- Create: `hotel_guest_app/lib/core/session.dart`

- [ ] **Step 1: Create `hotel_guest_app/lib/core/supabase_init.dart`**

Get the Supabase URL and anon key from the hotel app's `.env` file at the repo root (or Supabase dashboard → Project Settings → API).

```dart
// hotel_guest_app/lib/core/supabase_init.dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Same Supabase project as the hotel app.
// These are safe to embed — anon key has only public-role permissions.
const _supabaseUrl  = 'YOUR_SUPABASE_URL';   // e.g. https://xyz.supabase.co
const _supabaseAnon = 'YOUR_ANON_KEY';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnon);
}

SupabaseClient get supabase => Supabase.instance.client;
```

Replace `YOUR_SUPABASE_URL` and `YOUR_ANON_KEY` with values from the hotel app's `.env` file:
- Look for `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `/Users/boazsaada/manegmant resapceon/.env`

- [ ] **Step 2: Create `hotel_guest_app/lib/core/session.dart`**

```dart
// hotel_guest_app/lib/core/session.dart
import 'package:shared_preferences/shared_preferences.dart';

class GuestSession {
  static const _keyName       = 'guest_name';
  static const _keyRoom       = 'room_number';
  static const _keyHotel      = 'hotel_id';
  static const _keyLoginTime  = 'login_time';
  static const _keyFeedbackDone = 'feedback_done';

  final String guestName;
  final String roomNumber;
  final String hotelId;
  final DateTime loginTime;
  final bool feedbackDone;

  const GuestSession({
    required this.guestName,
    required this.roomNumber,
    required this.hotelId,
    required this.loginTime,
    this.feedbackDone = false,
  });

  bool get shouldShowFeedback {
    const threshold = Duration(days: 3);
    return !feedbackDone &&
        DateTime.now().difference(loginTime) >= threshold;
  }

  static Future<GuestSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString(_keyName);
    final room  = prefs.getString(_keyRoom);
    final hotel = prefs.getString(_keyHotel);
    final time  = prefs.getString(_keyLoginTime);
    if (name == null || room == null || hotel == null || time == null) {
      return null;
    }
    return GuestSession(
      guestName:    name,
      roomNumber:   room,
      hotelId:      hotel,
      loginTime:    DateTime.parse(time),
      feedbackDone: prefs.getBool(_keyFeedbackDone) ?? false,
    );
  }

  static Future<void> save({
    required String guestName,
    required String roomNumber,
    required String hotelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName,      guestName);
    await prefs.setString(_keyRoom,      roomNumber);
    await prefs.setString(_keyHotel,     hotelId);
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
    await prefs.setBool(_keyFeedbackDone, false);
  }

  static Future<void> markFeedbackDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFeedbackDone, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add hotel_guest_app/lib/core/
git commit -m "feat: add Supabase init and session storage for guest PWA"
```

---

### Task 4: Domain models + repository

**Files:**
- Create: `hotel_guest_app/lib/domain/guest_request.dart`
- Create: `hotel_guest_app/lib/data/guest_repository.dart`

- [ ] **Step 1: Create domain model**

```dart
// hotel_guest_app/lib/domain/guest_request.dart

class GuestRequest {
  final String id;
  final String roomNumber;
  final String guestName;
  final String category;
  final String? description;
  final String status;
  final DateTime createdAt;

  const GuestRequest({
    required this.id,
    required this.roomNumber,
    required this.guestName,
    required this.category,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory GuestRequest.fromJson(Map<String, dynamic> j) => GuestRequest(
    id:          j['id'] as String,
    roomNumber:  j['room_number'] as String,
    guestName:   j['guest_name'] as String,
    category:    j['category'] as String,
    description: j['description'] as String?,
    status:      j['status'] as String,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );
}
```

- [ ] **Step 2: Create repository**

```dart
// hotel_guest_app/lib/data/guest_repository.dart
import 'package:hotel_guest_app/core/supabase_init.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';

class GuestRepository {
  /// Streams this guest's requests, newest first.
  /// Filtered client-side — stream() only supports one .eq() filter.
  Stream<List<GuestRequest>> streamMyRequests(
      String hotelId, String roomNumber, String guestName) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .where((r) =>
                r.roomNumber == roomNumber && r.guestName == guestName)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Submits a new guest request.
  Future<void> submitRequest({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required String category,
    String? description,
  }) async {
    await supabase.from('guest_requests').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'category':    category,
      if (description != null && description.isNotEmpty)
        'description': description,
      'created_by': 'guest',
    });
  }

  /// Submits end-of-stay feedback.
  Future<void> submitFeedback({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required int rating,
    String? comment,
  }) async {
    await supabase.from('guest_feedback').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'rating':      rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add hotel_guest_app/lib/domain/ hotel_guest_app/lib/data/
git commit -m "feat: add guest PWA domain model and repository"
```

---

### Task 5: Providers

**Files:**
- Create: `hotel_guest_app/lib/providers/providers.dart`

- [ ] **Step 1: Create providers file**

```dart
// hotel_guest_app/lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/data/guest_repository.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';

final guestRepositoryProvider =
    Provider<GuestRepository>((_) => GuestRepository());

/// Current session — loaded once at startup.
final sessionProvider = FutureProvider<GuestSession?>((ref) async {
  return GuestSession.load();
});

/// Stream of this guest's requests.
/// Returns empty stream if no session loaded yet.
final myRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final sessionAsync = ref.watch(sessionProvider);
  return sessionAsync.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (session) {
      if (session == null) return const Stream.empty();
      return ref.read(guestRepositoryProvider).streamMyRequests(
            session.hotelId,
            session.roomNumber,
            session.guestName,
          );
    },
  );
});
```

- [ ] **Step 2: Commit**

```bash
git add hotel_guest_app/lib/providers/
git commit -m "feat: add guest PWA providers"
```

---

### Task 6: Landing screen

**Files:**
- Create: `hotel_guest_app/lib/presentation/landing_screen.dart`

- [ ] **Step 1: Create landing screen**

```dart
// hotel_guest_app/lib/presentation/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class LandingScreen extends ConsumerStatefulWidget {
  /// hotel_id from URL query param ?hotel=<id>
  final String? hotelId;
  const LandingScreen({super.key, this.hotelId});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final name = _nameCtrl.text.trim();
    final room = _roomCtrl.text.trim();
    final hotel = widget.hotelId;

    if (name.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא למלא שם ומספר חדר')),
      );
      return;
    }
    if (hotel == null || hotel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('קוד מלון חסר — סרקו שוב את ה-QR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await GuestSession.save(
          guestName: name, roomNumber: room, hotelId: hotel);
      ref.invalidate(sessionProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hotel,
                      color: Color(0xFFC9A84C), size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'ברוכים הבאים',
                    style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'מלאו את הפרטים כדי להתחיל',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildField(_nameCtrl, 'שמך המלא', Icons.person),
                  const SizedBox(height: 16),
                  _buildField(
                      _roomCtrl, 'מספר חדר', Icons.door_front_door,
                      type: TextInputType.number),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _enter,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text('כניסה →'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '+ ניתן להוסיף לדף הבית לגישה מהירה',
                    style:
                        TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Color(0xFFE2E8F0)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFF0F1F3D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
          ),
        ),
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add hotel_guest_app/lib/presentation/landing_screen.dart
git commit -m "feat: add guest PWA landing screen"
```

---

### Task 7: Home screen

**Files:**
- Create: `hotel_guest_app/lib/presentation/home_screen.dart`

- [ ] **Step 1: Create home screen**

```dart
// hotel_guest_app/lib/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _statusColor = {
    'open':        Color(0xFFF87171),
    'assigned':    Color(0xFFFB923C),
    'in_progress': Color(0xFFFB923C),
    'resolved':    Color(0xFF4ADE80),
    'cancelled':   Color(0xFF64748B),
  };

  static const _statusLabel = {
    'open':        'פתוחה',
    'assigned':    'בטיפול',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה ✓',
    'cancelled':   'בוטלה',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final requestsAsync = ref.watch(myRequestsProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white))),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(backgroundColor: Color(0xFF0A1628));
        }
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'שלום ${session.guestName} 👋',
                        style: const TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'חדר ${session.roomNumber}',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Feedback banner
                if (session.shouldShowFeedback)
                  GestureDetector(
                    onTap: () => context.push('/feedback'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2F1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF4ADE80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Color(0xFFC9A84C)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('איך הייתה השהייה?',
                                    style: TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w700)),
                                Text('השאירו לנו משוב קצר',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('בקשה חדשה',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('הבקשות שלי',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: requestsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('$e',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8)))),
                    data: (requests) => requests.isEmpty
                        ? const Center(
                            child: Text('אין בקשות עדיין',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: requests.length,
                            itemBuilder: (_, i) =>
                                _RequestTile(request: requests[i]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final GuestRequest request;
  const _RequestTile({required this.request});

  static const _categoryLabel = {
    'housekeeping': '🛏️ חדרניות',
    'maintenance':  '🔧 תחזוקה',
    'reception':    '🛎️ קבלה',
  };

  static const _statusColor = {
    'open':        Color(0xFFF87171),
    'assigned':    Color(0xFFFB923C),
    'in_progress': Color(0xFFFB923C),
    'resolved':    Color(0xFF4ADE80),
    'cancelled':   Color(0xFF64748B),
  };

  static const _statusLabel = {
    'open':        'פתוחה',
    'assigned':    'בטיפול',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה ✓',
    'cancelled':   'בוטלה',
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor[request.status] ?? const Color(0xFF64748B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel[request.category] ?? request.category,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                if (request.description != null &&
                    request.description!.isNotEmpty)
                  Text(
                    request.description!,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel[request.status] ?? request.status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add hotel_guest_app/lib/presentation/home_screen.dart
git commit -m "feat: add guest PWA home screen"
```

---

### Task 8: New request screen

**Files:**
- Create: `hotel_guest_app/lib/presentation/new_request_screen.dart`

- [ ] **Step 1: Create screen**

```dart
// hotel_guest_app/lib/presentation/new_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});
  @override
  ConsumerState<NewRequestScreen> createState() =>
      _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'housekeeping';
  bool _loading = false;

  static const _categories = [
    ('housekeeping', '🛏️ חדרניות'),
    ('maintenance',  '🔧 תחזוקה'),
    ('reception',    '🛎️ קבלה'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception('אין סשן');
      await ref.read(guestRepositoryProvider).submitRequest(
            hotelId:     session.hotelId,
            roomNumber:  session.roomNumber,
            guestName:   session.guestName,
            category:    _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה: $e'),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('בקשה חדשה',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('קטגוריה',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories
                    .map((c) => GestureDetector(
                          onTap: () =>
                              setState(() => _category = c.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _category == c.$1
                                  ? const Color(0xFFC9A84C)
                                  : const Color(0xFF0F1F3D),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _category == c.$1
                                    ? const Color(0xFFC9A84C)
                                    : const Color(0xFF1E3A5F),
                              ),
                            ),
                            child: Text(
                              c.$2,
                              style: TextStyle(
                                color: _category == c.$1
                                    ? Colors.black
                                    : const Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('פרטים (אופציונלי)',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFFE2E8F0)),
                decoration: InputDecoration(
                  hintText: 'ספרו לנו במה תרצו עזרה...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F1F3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('שלח בקשה'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add hotel_guest_app/lib/presentation/new_request_screen.dart
git commit -m "feat: add guest PWA new request screen"
```

---

### Task 9: Feedback screen

**Files:**
- Create: `hotel_guest_app/lib/presentation/feedback_screen.dart`

- [ ] **Step 1: Create screen**

```dart
// hotel_guest_app/lib/presentation/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});
  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור דירוג')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await ref.read(sessionProvider.future);
      if (session == null) throw Exception('אין סשן');
      await ref.read(guestRepositoryProvider).submitFeedback(
            hotelId:    session.hotelId,
            roomNumber: session.roomNumber,
            guestName:  session.guestName,
            rating:     _rating,
            comment:    _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      await GuestSession.markFeedbackDone();
      ref.invalidate(sessionProvider);
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה: $e'),
              backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF4ADE80), size: 64),
              const SizedBox(height: 16),
              const Text('תודה על המשוב!',
                  style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('תודה שבחרתם בנו 🙏',
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                ),
                child: const Text('חזרה לדף הבית',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('משוב שהייה',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              const Text('איך הייתה השהייה?',
                  style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFC9A84C),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFFE2E8F0)),
                decoration: InputDecoration(
                  hintText: 'ספרו לנו על החוויה שלכם (אופציונלי)...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F1F3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('שלח משוב'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add hotel_guest_app/lib/presentation/feedback_screen.dart
git commit -m "feat: add guest PWA feedback screen"
```

---

### Task 10: Router + main.dart

**Files:**
- Create: `hotel_guest_app/lib/router.dart`
- Create: `hotel_guest_app/lib/main.dart`

- [ ] **Step 1: Create router**

```dart
// hotel_guest_app/lib/router.dart
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/presentation/landing_screen.dart';
import 'package:hotel_guest_app/presentation/home_screen.dart';
import 'package:hotel_guest_app/presentation/new_request_screen.dart';
import 'package:hotel_guest_app/presentation/feedback_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // If navigating to home but no session exists, redirect to landing
    if (state.matchedLocation == '/home') {
      final session = await GuestSession.load();
      if (session == null) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        // hotel_id comes from URL query param: /?hotel=<id>
        final hotelId = state.uri.queryParameters['hotel'];
        return LandingScreen(hotelId: hotelId);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new',
      builder: (context, state) => const NewRequestScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
  ],
);
```

- [ ] **Step 2: Create main.dart**

```dart
// hotel_guest_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/supabase_init.dart';
import 'package:hotel_guest_app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: GuestApp()));
}

class GuestApp extends StatefulWidget {
  const GuestApp({super.key});

  @override
  State<GuestApp> createState() => _GuestAppState();
}

class _GuestAppState extends State<GuestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hotel Guest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC9A84C),
          surface: const Color(0xFF0F1F3D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        fontFamily: 'Rubik',
      ),
      routerConfig: _router,
    );
  }
}
```

- [ ] **Step 3: Remove generated `hotel_guest_app/lib/main.dart` stub**

The `flutter create` command generates a counter app in `main.dart`. The file above replaces it entirely.

- [ ] **Step 4: Run the PWA locally**

```bash
cd hotel_guest_app
flutter run -d chrome --web-port=3000
```

Open `http://localhost:3000/?hotel=<your-hotel-id>` in Chrome.

Expected: Landing screen appears with hotel gold theme. Enter name + room number → navigates to home screen.

- [ ] **Step 5: Commit**

```bash
cd ..
git add hotel_guest_app/lib/router.dart hotel_guest_app/lib/main.dart
git commit -m "feat: add guest PWA router and main entry point"
```

---

### Task 11: Build and verify PWA installability

- [ ] **Step 1: Build for production**

```bash
cd hotel_guest_app
flutter build web --release
```

Expected: Build succeeds, output in `hotel_guest_app/build/web/`.

- [ ] **Step 2: Verify PWA in Chrome DevTools**

Open the built app (serve locally with `python3 -m http.server 8080 --directory build/web`).

In Chrome DevTools → Application → Manifest:
- Name: "Hotel Guest"
- Theme color: #c9a84c
- Display: standalone
- No errors shown

- [ ] **Step 3: Commit**

```bash
cd ..
git add hotel_guest_app/
git commit -m "feat: guest PWA complete — landing, home, new request, feedback, PWA manifest"
```
