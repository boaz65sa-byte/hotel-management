# Housekeeping Full Flow — Design Spec

## Goal

Enable managers to assign dirty rooms to housekeeping staff, and staff to complete room cleaning via existing checklist, with real-time status tracking.

## Architecture

Two role-based screens: `HousekeepingManagerScreen` for managers (assign rooms, monitor progress) and `HousekeepingStaffScreen` for staff (see assigned rooms, complete checklists). Router directs to the correct screen based on role. Push notification wiring deferred to Module 4.

## Tech Stack

Flutter + Riverpod (StreamProvider for real-time), Supabase (RLS), existing checklist feature, existing `dirtyRoomsProvider` pattern.

---

## Database Changes

Add two columns to `rooms` table:

```sql
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS assigned_to_name text;
```

RLS: staff can only update rooms assigned to them (`assigned_to = auth.uid()`). Managers can update any room in their hotel.

### Room Status Flow

```
dirty (unassigned)
  → dirty (assigned_to = staff_id)        ← manager assigns
  → cleaning                               ← staff opens checklist
  → clean, assigned_to = null             ← checklist completed
```

---

## Manager Screen — `housekeeping_manager_screen.dart`

### Summary Bar

Three chips at top, color-coded:
- Red: count of dirty rooms
- Amber: count of rooms in cleaning
- Green: count of clean rooms

Updated via `StreamProvider` watching `rooms` table.

### Filter Row

Chip row beneath summary: `הכול | מלוכלך | בניקיון | נקי`

### Room List

Each card shows:
- Room number + floor
- Status badge
- Assigned staff name or "לא מוקצה" (grey)

### Assignment Bottom Sheet

Tapping a room card opens a `BottomSheet`:
- Header: "הקצה לחדר [number]"
- List of housekeeping staff (name + current room count)
- "הסר הקצאה" button (if currently assigned)
- On select: `UPDATE rooms SET assigned_to = staff_id, assigned_to_name = name WHERE id = room_id`

### Providers

```dart
// all dirty/cleaning rooms for this hotel
final housekeepingRoomsProvider = StreamProvider<List<Room>>(...);

// list of housekeeping staff users
final housekeepingStaffProvider = FutureProvider<List<StaffMember>>(...);
```

---

## Staff Screen — `housekeeping_staff_screen.dart`

### Header

```
שלום [name] — יש לך X חדרים
```

### Room List

Shows only rooms where `assigned_to = currentUser.id` and status in `[dirty, cleaning]`.

Each card:
- Room number + floor
- Status badge
- "התחל ניקיון" button (if dirty) or "המשך checklist" (if cleaning)

### On Card Tap

1. If status is `dirty`: `UPDATE rooms SET housekeeping_status = 'cleaning'`
2. Navigate to existing `ChecklistScreen` with room context
3. On checklist completion: `UPDATE rooms SET housekeeping_status = 'clean', assigned_to = null, assigned_to_name = null`

### Provider

```dart
// rooms assigned to current user
final myAssignedRoomsProvider = StreamProvider<List<Room>>(...);
```

---

## Navigation

In `router.dart`, route `/housekeeping` checks user role:

| Role | Screen |
|------|--------|
| `housekeeping_manager`, `hotel_admin`, `super_admin` | `HousekeepingManagerScreen` |
| `housekeeping` | `HousekeepingStaffScreen` |

---

## Notifications

- **In-app**: Staff sees assigned rooms on next app open (via StreamProvider).
- **Push**: Deferred to Module 4. Placeholder comment in assignment logic: `// TODO(Module 4): send push to assigned_to`.

---

## Files

| Action | File |
|--------|------|
| Modify | `lib/features/housekeeping/presentation/housekeeping_home.dart` → keep as redirect or remove |
| Create | `lib/features/housekeeping/presentation/housekeeping_manager_screen.dart` |
| Create | `lib/features/housekeeping/presentation/housekeeping_staff_screen.dart` |
| Modify | `lib/features/housekeeping/data/housekeeping_repository.dart` (or create) |
| Modify | `lib/features/housekeeping/providers/housekeeping_providers.dart` (or create) |
| Modify | `lib/navigation/router.dart` — role-based routing for `/housekeeping` |
| SQL | Supabase migration: add `assigned_to`, `assigned_to_name` to `rooms` |

---

## Out of Scope

- Photo before/after (Module 3+ feature)
- Manager approval before marking clean
- Push notifications (Module 4)
