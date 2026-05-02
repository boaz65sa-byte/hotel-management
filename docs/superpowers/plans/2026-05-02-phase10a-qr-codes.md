# Phase 10a — QR Codes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-hotel QR code display + share to the Flutter app, bulk per-room QR download to the Admin Panel, and pre-fill room number in the PWA landing screen from URL param.

**Architecture:** Flutter uses `qr_flutter` to render and `screenshot` + `share_plus` to capture and share. Admin uses `qrcode` npm package server-side to generate SVG/PNG. PWA reads `room` URL param to pre-fill the landing field.

**Tech Stack:** Flutter + `qr_flutter` + `screenshot` + `share_plus` | Next.js + `qrcode` npm | Flutter Web (PWA minor update)

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` — add `qr_flutter`, `screenshot` |
| Create | `lib/features/guest_requests/presentation/hotel_qr_screen.dart` |
| Modify | `lib/features/guest_requests/presentation/guest_requests_list.dart` — add QR action |
| Modify | `hotel_guest_app/lib/presentation/landing_screen.dart` — read `room` URL param |
| Create | `admin/src/app/dashboard/hotels/[id]/qr-codes/page.tsx` |
| Modify | `admin/src/app/dashboard/hotels/[id]/page.tsx` — add QR link |

---

### Task 1: Add Flutter dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `qr_flutter` and `screenshot` to pubspec.yaml**

Find the dependencies section and add:
```yaml
  qr_flutter: ^4.1.0
  screenshot: ^3.0.0
```

- [ ] **Step 2: Install**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add qr_flutter and screenshot dependencies"
```

---

### Task 2: HotelQrScreen widget

**Files:**
- Create: `lib/features/guest_requests/presentation/hotel_qr_screen.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/features/guest_requests/presentation/hotel_qr_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HotelQrScreen extends StatefulWidget {
  final String hotelId;
  final String hotelName;

  const HotelQrScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
  });

  @override
  State<HotelQrScreen> createState() => _HotelQrScreenState();
}

class _HotelQrScreenState extends State<HotelQrScreen> {
  final _qrKey = GlobalKey();
  bool _saving = false;

  String get _pwaUrl =>
      'https://guest.hotel.com/?hotel=${widget.hotelId}';

  Future<Uint8List?> _captureQr() async {
    final boundary = _qrKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hotel_qr_${widget.hotelId}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR קוד — ${widget.hotelName}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/hotel_qr_${widget.hotelId}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נשמר ב-${file.path}'),
            backgroundColor: const Color(0xFF4ADE80),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE2E8F0),
        title: const Text('QR קוד מלון',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.hotelName,
                style: const TextStyle(
                  color: Color(0xFFC9A84C),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'סרקו את הקוד לכניסה לאפליקציית האורחים',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    data: _pwaUrl,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _pwaUrl,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _share,
                    icon: const Icon(Icons.share),
                    label: const Text('שתף'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.download),
                    label: const Text('שמור'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE2E8F0),
                      side: const BorderSide(color: Color(0xFF1E3A5F)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              if (_saving) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                    color: Color(0xFFC9A84C)),
              ],
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
git add lib/features/guest_requests/presentation/hotel_qr_screen.dart
git commit -m "feat: add HotelQrScreen with QR display, share and save"
```

---

### Task 3: Wire QR button into GuestRequestsListScreen

**Files:**
- Modify: `lib/features/guest_requests/presentation/guest_requests_list.dart`

The screen currently has a `Scaffold` with a `SafeArea` body + FAB. Add a QR button to the AppBar.

- [ ] **Step 1: Read the file to find the exact Scaffold / body structure**

Read `lib/features/guest_requests/presentation/guest_requests_list.dart` lines 1–50 to confirm the current structure.

- [ ] **Step 2: Add import**

At the top of the file, add after the last existing import:
```dart
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/guest_requests/presentation/hotel_qr_screen.dart';
```

- [ ] **Step 3: Replace the Scaffold inside `data:` callback**

Find the `return Scaffold(` inside the `data: (all) {` callback. Replace:
```dart
          return Scaffold(
            backgroundColor: const Color(0xFF0A1628),
            body: SafeArea(
```

With:
```dart
          final user = ref.read(currentUserProvider);
          final hotelId = user?.appMetadata['hotel_id'] as String?;
          final hotelName = user?.appMetadata['hotel_name'] as String? ?? 'המלון';
          return Scaffold(
            backgroundColor: const Color(0xFF0A1628),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A1628),
              automaticallyImplyLeading: false,
              actions: [
                if (hotelId != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code,
                        color: Color(0xFFC9A84C)),
                    tooltip: 'QR קוד מלון',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HotelQrScreen(
                          hotelId: hotelId,
                          hotelName: hotelName,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
```

- [ ] **Step 4: Run all guest_requests tests**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter test test/features/guest_requests/guest_request_test.dart -v 2>&1 | tail -5
```

Expected: All 13 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/guest_requests/presentation/guest_requests_list.dart
git commit -m "feat: add QR code button to GuestRequestsListScreen"
```

---

### Task 4: PWA — pre-fill room from URL param

**Files:**
- Modify: `hotel_guest_app/lib/presentation/landing_screen.dart`

- [ ] **Step 1: Read the file**

Read `hotel_guest_app/lib/presentation/landing_screen.dart` to find the constructor and `initState` (or lack thereof).

- [ ] **Step 2: Override `initState` to read room param**

`LandingScreen` already receives `hotelId` from the router. The router passes URL params via `state.uri.queryParameters`. We need to also pass `roomNumber` from the URL.

First, modify `hotel_guest_app/lib/router.dart` — add `roomNumber` param to the LandingScreen route:

Current:
```dart
    GoRoute(
      path: '/',
      builder: (context, state) {
        final hotelId = state.uri.queryParameters['hotel'];
        return LandingScreen(hotelId: hotelId);
      },
    ),
```

New:
```dart
    GoRoute(
      path: '/',
      builder: (context, state) {
        final hotelId   = state.uri.queryParameters['hotel'];
        final roomNumber = state.uri.queryParameters['room'];
        return LandingScreen(hotelId: hotelId, roomNumber: roomNumber);
      },
    ),
```

- [ ] **Step 3: Update LandingScreen to accept and use roomNumber**

In `hotel_guest_app/lib/presentation/landing_screen.dart`:

Add `roomNumber` to the constructor:
```dart
  final String? hotelId;
  final String? roomNumber;
  const LandingScreen({super.key, this.hotelId, this.roomNumber});
```

Add `initState` to pre-fill the room field:
```dart
  @override
  void initState() {
    super.initState();
    if (widget.roomNumber != null && widget.roomNumber!.isNotEmpty) {
      _roomCtrl.text = widget.roomNumber!;
    }
  }
```

- [ ] **Step 4: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/presentation/landing_screen.dart hotel_guest_app/lib/router.dart && git commit -m "feat: pre-fill room number in PWA landing from URL param"
```

---

### Task 5: Admin Panel — QR codes page

**Files:**
- Create: `admin/src/app/dashboard/hotels/[id]/qr-codes/page.tsx`
- Modify: `admin/src/app/dashboard/hotels/[id]/page.tsx`

- [ ] **Step 1: Install `qrcode` npm package**

```bash
cd "/Users/boazsaada/manegmant resapceon/admin" && npm install qrcode && npm install --save-dev @types/qrcode
```

- [ ] **Step 2: Create the QR codes page**

Create `admin/src/app/dashboard/hotels/[id]/qr-codes/page.tsx`:

```tsx
import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import QRCode from 'qrcode'

const PWA_BASE_URL = 'https://guest.hotel.com'

async function generateQrDataUrl(url: string): Promise<string> {
  return QRCode.toDataURL(url, {
    width: 200,
    margin: 2,
    color: { dark: '#0a1628', light: '#ffffff' },
  })
}

export default async function HotelQrCodesPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()

  if (!hotel) notFound()

  const { data: rooms } = await supabaseAdmin
    .from('rooms')
    .select('id, room_number')
    .eq('hotel_id', id)
    .order('room_number')

  const roomsWithQr = await Promise.all(
    (rooms ?? []).map(async (room) => {
      const url = `${PWA_BASE_URL}/?hotel=${hotel.id}&room=${room.room_number}`
      const qrDataUrl = await generateQrDataUrl(url)
      return { ...room, url, qrDataUrl }
    })
  )

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">QR Codes — {hotel.name}</h1>
          <p className="text-gray-500 text-sm mt-1">
            QR נפרד לכל חדר — יש להדביק בחדר
          </p>
        </div>
        <a
          href={`/dashboard/hotels/${id}`}
          className="text-sm text-blue-600 hover:underline"
        >
          ← חזרה למלון
        </a>
      </div>

      {roomsWithQr.length === 0 ? (
        <p className="text-gray-500">אין חדרים מוגדרים למלון זה.</p>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {roomsWithQr.map((room) => (
            <div
              key={room.id}
              className="border rounded-xl p-4 flex flex-col items-center gap-3 bg-white shadow-sm"
            >
              <p className="font-bold text-lg">חדר {room.room_number}</p>
              <img
                src={room.qrDataUrl}
                alt={`QR חדר ${room.room_number}`}
                width={160}
                height={160}
              />
              <p className="text-xs text-gray-400 text-center break-all">
                {room.url}
              </p>
              <a
                href={room.qrDataUrl}
                download={`qr-room-${room.room_number}.png`}
                className="text-sm bg-blue-600 text-white px-3 py-1.5 rounded-lg hover:bg-blue-700"
              >
                הורד PNG
              </a>
            </div>
          ))}
        </div>
      )}

      <div className="mt-8 p-4 bg-blue-50 rounded-lg text-sm text-blue-800">
        <strong>כיצד להשתמש:</strong> הורידו את ה-QR של כל חדר והדביקו אותו בולט בחדר (על שלט, על
        הקיר ליד הדלת). האורח סורק → ממלא שם → שולח בקשות.
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Add QR link to hotel edit page**

In `admin/src/app/dashboard/hotels/[id]/page.tsx`, after the `<h1>` tag, add:

```tsx
      <div className="mb-6 flex gap-4">
        <a
          href={`/dashboard/hotels/${hotel.id}/qr-codes`}
          className="inline-flex items-center gap-2 bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
        >
          🔲 QR Codes לחדרים
        </a>
      </div>
```

- [ ] **Step 4: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add admin/src/app/dashboard/hotels/ && git commit -m "feat: add QR codes page for hotel rooms in admin panel"
```
