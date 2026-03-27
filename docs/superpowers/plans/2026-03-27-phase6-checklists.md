# Phase 6: Checklists Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Global checklist templates (managed by Super Admin) instantiated per hotel room. Housekeeping staff completes checklists with one tap per item. Supports photo evidence per item.

**Architecture:** 4 new DB tables: `checklist_templates` (global), `checklist_items`, `checklist_instances` (per hotel/room), `checklist_instance_items`. Flutter module `features/checklists/` with repository, domain models, and screens. Admin panel page `/dashboard/checklists` for Super Admin to manage templates.

**Tech Stack:** Flutter 3, Riverpod, Supabase (RLS), Next.js 16 App Router (admin panel)

**Prerequisite:** Phase 5 DB migrations must be applied first (for `set_updated_at()` function).

---

## File Structure

```
supabase/migrations/
  20260327000004_checklists.sql             ← NEW: all 4 tables + RLS + triggers + seed

lib/features/checklists/
  domain/checklist_model.dart               ← NEW: ChecklistTemplate, ChecklistInstance, ChecklistInstanceItem
  data/checklist_repository.dart            ← NEW: CRUD operations
  providers/checklist_provider.dart         ← NEW: Riverpod providers
  presentation/
    checklist_screen.dart                   ← NEW: active checklist for a room
    checklist_item_tile.dart                ← NEW: single item with checkbox + camera

admin/src/app/dashboard/checklists/
  page.tsx                                  ← NEW: list templates
  new/page.tsx                              ← NEW: create template + items
  [id]/page.tsx                             ← NEW: edit template
admin/src/app/api/checklists/
  route.ts                                  ← NEW: GET + POST templates
  [id]/route.ts                             ← NEW: PATCH + DELETE template
```

---

## Task 1: DB Migration — all checklist tables

**Files:**
- Create: `supabase/migrations/20260327000004_checklists.sql`

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260327000004_checklists.sql

-- Shared updated_at trigger function (idempotent)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

-- Templates (global — no hotel_id)
CREATE TABLE IF NOT EXISTS checklist_templates (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('housekeeping', 'maintenance')),
  is_vip     BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS checklist_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id    UUID NOT NULL REFERENCES checklist_templates(id) ON DELETE CASCADE,
  order_index    INT NOT NULL,
  title_he       TEXT NOT NULL,
  title_en       TEXT,
  requires_photo BOOLEAN NOT NULL DEFAULT false,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Instances (per hotel + optional room)
CREATE TABLE IF NOT EXISTS checklist_instances (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id  UUID NOT NULL REFERENCES checklist_templates(id),
  room_id      UUID REFERENCES rooms(id),
  assigned_to  UUID REFERENCES auth.users(id),
  hotel_id     UUID NOT NULL REFERENCES hotels(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS checklist_instance_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
  item_id     UUID REFERENCES checklist_items(id) ON DELETE SET NULL,
  is_done     BOOLEAN NOT NULL DEFAULT false,
  photo_url   TEXT,
  done_at     TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Triggers
CREATE TRIGGER trg_updated_at_checklist_templates
  BEFORE UPDATE ON checklist_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_items
  BEFORE UPDATE ON checklist_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_instances
  BEFORE UPDATE ON checklist_instances FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_instance_items
  BEFORE UPDATE ON checklist_instance_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: templates — readable by all auth, writable by superAdmin only
ALTER TABLE checklist_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read templates" ON checklist_templates FOR SELECT TO authenticated USING (true);
CREATE POLICY "write templates" ON checklist_templates FOR ALL
  USING  ((auth.jwt()->'claims'->>'role') = 'superAdmin')
  WITH CHECK ((auth.jwt()->'claims'->>'role') = 'superAdmin');

ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read items" ON checklist_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "write items" ON checklist_items FOR ALL
  USING  ((auth.jwt()->'claims'->>'role') = 'superAdmin')
  WITH CHECK ((auth.jwt()->'claims'->>'role') = 'superAdmin');

-- RLS: instances — scoped to hotel
ALTER TABLE checklist_instances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel instances" ON checklist_instances FOR ALL
  USING ((auth.jwt()->'claims'->>'hotel_id')::uuid = hotel_id);

ALTER TABLE checklist_instance_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel instance items" ON checklist_instance_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM checklist_instances ci
    WHERE ci.id = instance_id
      AND (auth.jwt()->'claims'->>'hotel_id')::uuid = ci.hotel_id
  ));

-- Seed: 3 default templates
INSERT INTO checklist_templates (name, type, is_vip) VALUES
  ('ניקיון רגיל', 'housekeeping', false),
  ('ניקיון VIP',  'housekeeping', true),
  ('ביקורת אחזקה', 'maintenance', false);

-- Seed items for ניקיון רגיל (template 1)
WITH t AS (SELECT id FROM checklist_templates WHERE name = 'ניקיון רגיל')
INSERT INTO checklist_items (template_id, order_index, title_he, requires_photo)
SELECT t.id, idx, title, photo FROM t, (VALUES
  (1, 'ניקוי אמבטיה', false),
  (2, 'ניקוי שירותים', false),
  (3, 'ניקוי רצפה', false),
  (4, 'החלפת מגבות', false),
  (5, 'ניקוי מטבחון', false),
  (6, 'שינוי מצעים', false),
  (7, 'ניקוי חלונות', false),
  (8, 'בדיקת מיזוג', true)
) AS v(idx, title, photo);

-- Seed items for ניקיון VIP (template 2)
WITH t AS (SELECT id FROM checklist_templates WHERE name = 'ניקיון VIP')
INSERT INTO checklist_items (template_id, order_index, title_he, requires_photo)
SELECT t.id, idx, title, photo FROM t, (VALUES
  (1,  'ניקוי אמבטיה עמוק', true),
  (2,  'ניקוי ג׳קוזי', true),
  (3,  'ניקוי שירותים', false),
  (4,  'ניקוי רצפה מלא', false),
  (5,  'החלפת מגבות VIP', false),
  (6,  'סידור פרחים', true),
  (7,  'ניקוי מטבחון', false),
  (8,  'שינוי מצעים VIP', true),
  (9,  'ניקוי חלונות', false),
  (10, 'סידור אמנויות', true),
  (11, 'בדיקת מיזוג', true),
  (12, 'בדיקת מיני בר', true)
) AS v(idx, title, photo);

-- Seed items for ביקורת אחזקה (template 3)
WITH t AS (SELECT id FROM checklist_templates WHERE name = 'ביקורת אחזקה')
INSERT INTO checklist_items (template_id, order_index, title_he, requires_photo)
SELECT t.id, idx, title, photo FROM t, (VALUES
  (1,  'בדיקת חשמל', true),
  (2,  'בדיקת אינסטלציה', false),
  (3,  'בדיקת מיזוג אוויר', true),
  (4,  'בדיקת חלונות', false),
  (5,  'בדיקת דלתות ומנעולים', false),
  (6,  'בדיקת תאורה', false),
  (7,  'בדיקת טלוויזיה', false),
  (8,  'בדיקת כספת', false),
  (9,  'בדיקת אינטרנט', false),
  (10, 'תיעוד כללי', true)
) AS v(idx, title, photo);
```

- [ ] **Step 2: Apply in Supabase Dashboard SQL Editor**

- [ ] **Step 3: Verify seed data**

Run in SQL Editor: `SELECT name, type FROM checklist_templates;`
Expected: 3 rows.

- [ ] **Step 4: Commit migration**

```bash
git add supabase/migrations/20260327000004_checklists.sql
git commit -m "feat: checklist tables, RLS, triggers, seed data"
```

---

## Task 2: Domain models — ChecklistTemplate, ChecklistInstance, ChecklistInstanceItem

**Files:**
- Create: `lib/features/checklists/domain/checklist_model.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/checklists/checklist_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

void main() {
  group('ChecklistTemplate', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'tmpl1', 'name': 'ניקיון רגיל', 'type': 'housekeeping',
        'is_vip': false, 'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final t = ChecklistTemplate.fromJson(json);
      expect(t.name, 'ניקיון רגיל');
      expect(t.type, 'housekeeping');
      expect(t.isVip, false);
    });
  });

  group('ChecklistInstanceItem', () {
    test('fromJson parses isDone', () {
      final json = {
        'id': 'ii1', 'instance_id': 'inst1', 'is_done': true,
        'updated_at': '2026-01-01T00:00:00Z',
        'item': {'title_he': 'ניקוי אמבטיה', 'requires_photo': false},
      };
      final item = ChecklistInstanceItem.fromJson(json);
      expect(item.isDone, true);
      expect(item.titleHe, 'ניקוי אמבטיה');
    });

    test('isComplete false when requiresPhoto and no photoUrl', () {
      final item = ChecklistInstanceItem(
        id: 'i1', instanceId: 'inst1', isDone: true,
        titleHe: 'בדיקה', requiresPhoto: true, photoUrl: null,
        updatedAt: DateTime.now(),
      );
      expect(item.isComplete, false);
    });

    test('isComplete true when isDone and photo present', () {
      final item = ChecklistInstanceItem(
        id: 'i1', instanceId: 'inst1', isDone: true,
        titleHe: 'בדיקה', requiresPhoto: true,
        photoUrl: 'https://example.com/photo.jpg',
        updatedAt: DateTime.now(),
      );
      expect(item.isComplete, true);
    });
  });
}
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/checklists/checklist_model_test.dart -v
```

- [ ] **Step 3: Create domain models**

```dart
// lib/features/checklists/domain/checklist_model.dart

class ChecklistTemplate {
  final String id;
  final String name;
  final String type; // 'housekeeping' | 'maintenance'
  final bool isVip;
  final DateTime createdAt;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.isVip,
    required this.createdAt,
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> j) => ChecklistTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String,
    isVip: j['is_vip'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class ChecklistInstance {
  final String id;
  final String templateId;
  final String hotelId;
  final String? roomId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String templateName;

  const ChecklistInstance({
    required this.id,
    required this.templateId,
    required this.hotelId,
    this.roomId,
    this.assignedTo,
    required this.createdAt,
    this.completedAt,
    required this.templateName,
  });

  bool get isComplete => completedAt != null;

  factory ChecklistInstance.fromJson(Map<String, dynamic> j) => ChecklistInstance(
    id: j['id'] as String,
    templateId: j['template_id'] as String,
    hotelId: j['hotel_id'] as String,
    roomId: j['room_id'] as String?,
    assignedTo: j['assigned_to'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    completedAt: j['completed_at'] != null ? DateTime.parse(j['completed_at'] as String) : null,
    templateName: j['template'] != null
        ? (j['template'] as Map<String, dynamic>)['name'] as String? ?? ''
        : '',
  );
}

class ChecklistInstanceItem {
  final String id;
  final String instanceId;
  final bool isDone;
  final String titleHe;
  final bool requiresPhoto;
  final String? photoUrl;
  final DateTime? doneAt;
  final DateTime updatedAt;

  const ChecklistInstanceItem({
    required this.id,
    required this.instanceId,
    required this.isDone,
    required this.titleHe,
    required this.requiresPhoto,
    this.photoUrl,
    this.doneAt,
    required this.updatedAt,
  });

  /// True only when: isDone AND (no photo required OR photo uploaded)
  bool get isComplete => isDone && (!requiresPhoto || photoUrl != null);

  factory ChecklistInstanceItem.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>?;
    return ChecklistInstanceItem(
      id: j['id'] as String,
      instanceId: j['instance_id'] as String,
      isDone: j['is_done'] as bool? ?? false,
      titleHe: item?['title_he'] as String? ?? '',
      requiresPhoto: item?['requires_photo'] as bool? ?? false,
      photoUrl: j['photo_url'] as String?,
      doneAt: j['done_at'] != null ? DateTime.parse(j['done_at'] as String) : null,
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }
}
```

- [ ] **Step 4: Run test to verify pass**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/checklists/checklist_model_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/checklists/domain/checklist_model.dart test/features/checklists/checklist_model_test.dart
git commit -m "feat: checklist domain models with isComplete guard"
```

---

## Task 3: ChecklistRepository

**Files:**
- Create: `lib/features/checklists/data/checklist_repository.dart`

- [ ] **Step 1: Create repository**

```dart
// lib/features/checklists/data/checklist_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

final checklistRepositoryProvider = Provider((_) => ChecklistRepository());

class ChecklistRepository {
  Future<List<ChecklistTemplate>> fetchTemplates() async {
    final data = await supabase
        .from('checklist_templates')
        .select()
        .order('name');
    return (data as List).map((j) => ChecklistTemplate.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ChecklistInstance>> fetchActiveInstances(String hotelId) async {
    final data = await supabase
        .from('checklist_instances')
        .select('*, template:checklist_templates(name)')
        .eq('hotel_id', hotelId)
        .filter('completed_at', 'is', null)
        .order('created_at', ascending: false);
    return (data as List).map((j) => ChecklistInstance.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ChecklistInstanceItem>> fetchInstanceItems(String instanceId) async {
    final data = await supabase
        .from('checklist_instance_items')
        .select('*, item:checklist_items(title_he, requires_photo)')
        .eq('instance_id', instanceId)
        .order('updated_at');
    return (data as List).map((j) => ChecklistInstanceItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<String> createInstance({
    required String templateId,
    required String hotelId,
    String? roomId,
    String? assignedTo,
  }) async {
    // Create instance
    final instance = await supabase
        .from('checklist_instances')
        .insert({
          'template_id': templateId,
          'hotel_id': hotelId,
          if (roomId != null) 'room_id': roomId,
          if (assignedTo != null) 'assigned_to': assignedTo,
        })
        .select()
        .single();
    final instanceId = instance['id'] as String;

    // Copy items from template
    final items = await supabase
        .from('checklist_items')
        .select()
        .eq('template_id', templateId)
        .order('order_index');

    final instanceItems = (items as List).map((item) => {
      'instance_id': instanceId,
      'item_id': item['id'],
    }).toList();

    await supabase.from('checklist_instance_items').insert(instanceItems);
    return instanceId;
  }

  Future<void> toggleItem(String itemId, bool isDone) async {
    await supabase.from('checklist_instance_items').update({
      'is_done': isDone,
      'done_at': isDone ? DateTime.now().toIso8601String() : null,
    }).eq('id', itemId);
  }

  Future<void> completeInstance(String instanceId) async {
    await supabase.from('checklist_instances').update({
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', instanceId);
  }
}
```

- [ ] **Step 2: Write smoke test**

In `test/features/checklists/checklist_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

void main() {
  test('ChecklistInstance.isComplete false when completedAt null', () {
    final inst = ChecklistInstance(
      id: 'i1', templateId: 't1', hotelId: 'h1',
      createdAt: DateTime.now(), templateName: 'Test',
    );
    expect(inst.isComplete, false);
  });
}
```

- [ ] **Step 3: Run test**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/checklists/checklist_repository_test.dart -v
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/checklists/data/checklist_repository.dart test/features/checklists/checklist_repository_test.dart
git commit -m "feat: ChecklistRepository with create, toggle, complete"
```

---

## Task 4: Riverpod providers for checklists

**Files:**
- Create: `lib/features/checklists/providers/checklist_provider.dart`

- [ ] **Step 1: Create providers**

```dart
// lib/features/checklists/providers/checklist_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/checklists/data/checklist_repository.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

final checklistTemplatesProvider = FutureProvider<List<ChecklistTemplate>>((ref) {
  return ref.read(checklistRepositoryProvider).fetchTemplates();
});

final activeChecklistsProvider = FutureProvider<List<ChecklistInstance>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref.read(checklistRepositoryProvider).fetchActiveInstances(hotelId);
});

final checklistItemsProvider = FutureProvider.family<List<ChecklistInstanceItem>, String>(
  (ref, instanceId) {
    return ref.read(checklistRepositoryProvider).fetchInstanceItems(instanceId);
  },
);
```

- [ ] **Step 2: Run all tests**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/checklists/providers/checklist_provider.dart
git commit -m "feat: checklist Riverpod providers"
```

---

## Task 5: ChecklistItemTile widget

**Files:**
- Create: `lib/features/checklists/presentation/checklist_item_tile.dart`

Single checklist item: checkbox + title + optional camera icon (if requiresPhoto).

- [ ] **Step 1: Write the failing test**

In `test/features/checklists/checklist_item_tile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';
import 'package:hotel_app/features/checklists/presentation/checklist_item_tile.dart';

void main() {
  testWidgets('ChecklistItemTile shows checkbox and title', (tester) async {
    final item = ChecklistInstanceItem(
      id: 'i1', instanceId: 'inst1', isDone: false,
      titleHe: 'ניקוי אמבטיה', requiresPhoto: false, updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ChecklistItemTile(item: item, onToggle: (_) async {})),
        ),
      ),
    );
    expect(find.text('ניקוי אמבטיה'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify fails**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/checklists/checklist_item_tile_test.dart -v
```

- [ ] **Step 3: Create ChecklistItemTile**

```dart
// lib/features/checklists/presentation/checklist_item_tile.dart
import 'package:flutter/material.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistInstanceItem item;
  final Future<void> Function(bool isDone) onToggle;
  final VoidCallback? onCamera;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.isDone,
        onChanged: (v) => onToggle(v ?? false),
      ),
      title: Text(
        item.titleHe,
        style: TextStyle(
          decoration: item.isDone ? TextDecoration.lineThrough : null,
          color: item.isDone ? Colors.grey : null,
        ),
      ),
      trailing: item.requiresPhoto
          ? IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: item.photoUrl != null ? Colors.green : Colors.red,
              ),
              onPressed: onCamera,
              tooltip: item.photoUrl != null ? 'תמונה הועלתה' : 'נדרשת תמונה',
            )
          : null,
    );
  }
}
```

- [ ] **Step 4: Run test to verify pass**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/checklists/checklist_item_tile_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/checklists/presentation/checklist_item_tile.dart test/features/checklists/checklist_item_tile_test.dart
git commit -m "feat: ChecklistItemTile widget with checkbox + camera icon"
```

---

## Task 6: ChecklistScreen

**Files:**
- Create: `lib/features/checklists/presentation/checklist_screen.dart`
- Modify: `lib/navigation/router.dart` — add `/checklists/:instanceId` route

- [ ] **Step 1: Create ChecklistScreen**

```dart
// lib/features/checklists/presentation/checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/checklists/domain/checklist_model.dart';
import 'package:hotel_app/features/checklists/data/checklist_repository.dart';
import 'package:hotel_app/features/checklists/providers/checklist_provider.dart';
import 'package:hotel_app/features/checklists/presentation/checklist_item_tile.dart';

class ChecklistScreen extends ConsumerWidget {
  final String instanceId;
  const ChecklistScreen({super.key, required this.instanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsProvider(instanceId));
    final repo = ref.read(checklistRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('צ׳קליסט')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (items) {
          final done = items.where((i) => i.isComplete).length;
          final allDone = done == items.length;

          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('$done / ${items.length} הושלמו',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              // Item list
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ChecklistItemTile(
                      item: item,
                      onToggle: (isDone) async {
                        await repo.toggleItem(item.id, isDone);
                        ref.invalidate(checklistItemsProvider(instanceId));
                      },
                      onCamera: item.requiresPhoto
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('העלאת תמונה — בקרוב')),
                              )
                          : null,
                    );
                  },
                ),
              ),
              // Complete button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('סיים צ׳קליסט'),
                  style: allDone
                      ? null
                      : FilledButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: allDone
                      ? () async {
                          await repo.completeInstance(instanceId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Add route to router.dart**

In `lib/navigation/router.dart`, add inside the routes list:

```dart
GoRoute(
  path: '/checklists/:instanceId',
  builder: (context, state) => ChecklistScreen(
    instanceId: state.pathParameters['instanceId']!,
  ),
),
```

- [ ] **Step 3: Run all tests + analyze**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/checklists/presentation/checklist_screen.dart lib/navigation/router.dart
git commit -m "feat: ChecklistScreen with progress bar and complete button"
```

---

## Task 7: Admin Panel — /dashboard/checklists page

**Files:**
- Create: `admin/src/app/dashboard/checklists/page.tsx`
- Create: `admin/src/app/api/checklists/route.ts`

Super Admin can view and create checklist templates.

- [ ] **Step 1: Create API route**

```typescript
// admin/src/app/api/checklists/route.ts
import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET() {
  await requireSuperAdmin()
  const { data, error } = await supabaseAdmin
    .from('checklist_templates')
    .select('*, checklist_items(count)')
    .order('name')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: Request) {
  await requireSuperAdmin()
  const { name, type, is_vip } = await req.json()
  if (!name || !type) return NextResponse.json({ error: 'name and type required' }, { status: 400 })
  const { data, error } = await supabaseAdmin
    .from('checklist_templates')
    .insert({ name, type, is_vip: is_vip ?? false })
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
```

- [ ] **Step 2: Create checklists page**

```tsx
// admin/src/app/dashboard/checklists/page.tsx
'use client'
import { useEffect, useState } from 'react'

interface Template { id: string; name: string; type: string; is_vip: boolean }

export default function ChecklistsPage() {
  const [templates, setTemplates] = useState<Template[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/checklists')
      .then(r => r.json())
      .then(data => { setTemplates(data); setLoading(false) })
  }, [])

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">תבניות צ׳קליסט</h1>
      {loading ? (
        <p>טוען...</p>
      ) : (
        <div className="grid gap-4">
          {templates.map(t => (
            <div key={t.id} className="bg-white rounded-lg p-4 shadow flex items-center justify-between">
              <div>
                <p className="font-semibold">{t.name}</p>
                <p className="text-sm text-gray-500">
                  {t.type === 'housekeeping' ? 'ניקיון' : 'אחזקה'}
                  {t.is_vip && ' · VIP'}
                </p>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                t.type === 'housekeeping' ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'
              }`}>
                {t.type}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 3: Add checklists link to admin sidebar**

In `admin/src/components/sidebar.tsx`, add a link:
```tsx
{ href: '/dashboard/checklists', label: 'צ׳קליסטים', icon: CheckSquare }
```

- [ ] **Step 4: Build admin panel to verify**

```bash
cd "/Users/boazsaada/manegmant resapceon/admin" && npm run build 2>&1 | tail -10
```

Expected: compiled successfully.

- [ ] **Step 5: Commit**

```bash
git add admin/src/app/dashboard/checklists/ admin/src/app/api/checklists/ admin/src/components/sidebar.tsx
git commit -m "feat: admin checklists page + API route"
```

---

## Task 8: Final integration + verification

- [ ] **Step 1: Full Flutter test suite**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

Expected: all pass, analyze clean.

- [ ] **Step 2: Web build**

```bash
cd "/Users/boazsaada/manegmant resapceon" && /Users/boazsaada/flutter/bin/flutter build web --web-renderer html
```

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: Phase 6 complete — Checklists (templates, instances, housekeeping UI, admin panel)"
```

---

## Verification (Success Criteria)

- [ ] 3 default templates visible in admin `/dashboard/checklists`
- [ ] Housekeeping staff can open a checklist instance and tap items to complete them
- [ ] Items requiring photo show red camera icon until photo uploaded
- [ ] `[סיים צ׳קליסט]` button disabled until all `isComplete` items done
- [ ] Completed instance disappears from active list
- [ ] All Flutter tests pass
