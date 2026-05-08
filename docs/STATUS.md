# סטטוס פרויקט — מה עובד ומה נשאר

**עודכן:** 2026-05-08

---

## 🆕 סשן 2026-05-08 — סבב ליטוש סופי

הופעלו 3 סוכנים במקביל וסגרו את שאר משימות הליטוש בקוד:

### Flutter Staff App
- ✅ **שם מלון אמיתי במסך QR** — `hotel_qr_screen.dart` שולף `name` מטבלת `hotels` ומציג אותו במקום הטקסט הקבוע "המלון" (עם fallback).
- ✅ **`SessionTimeoutService` חוט** — `SessionTimeoutManager` + `sessionTimeoutManagerProvider` נוספו ב-`session_timeout.dart`; `app.dart` עוטף את האפליקציה ב-`Listener` שמאתחל timer בכל pointer event; auto sign-out כשהזמן עובר.
- ✅ **Dead code** — הוסרו `acceptTicket` ו-`quickResolveTicket` מ-`ticket_repository.dart` (אומת אפס שימושים בכל הקוד).
- ✅ **0 lints** — כל 16 ה-info של `flutter analyze lib` נסגרו (const constructors, curly braces, captured ScaffoldMessenger לפני await).

### Flutter Guest PWA
- ✅ **Branding ב-`web/index.html`**: title `Hotel Guest Service`, description, `apple-mobile-web-app-title=Hotel Guest`.
- ✅ **`web/manifest.json`**: name / short_name / description בהתאמה.
- ✅ **`test/widget_test.dart` נמחק** (היה ברירת המחדל של Flutter Counter; smoke test היה נופל בגלל אתחול Supabase).

### RBAC ל-Excel Export
- ✅ קובץ עזר חדש `lib/core/auth/role_helpers.dart` עם `kExportRoles` + `canExportData(role)`.
- ✅ הכפתור ב-`guest_requests_list.dart` ו-`guest_feedback_screen.dart` מסתתר אם המשתמש לא בקבוצה: `manager / *_manager / ceo / hotel_admin / super_admin`.

### בדיקות שעברו (סוף הסבב)
| בדיקה | תוצאה |
|------|------|
| `npx eslint .` (admin) | 0 errors / 0 warnings |
| `npx tsc --noEmit` (admin) | 0 errors |
| `flutter analyze lib` (staff) | **No issues found!** |
| `flutter analyze lib` (PWA) | **No issues found!** |
| TODO/FIXME/HACK בקוד | 0 |

---

## 🗓️ סשן 2026-05-04 — Admin: משוב אורחים

- **דף** `admin/src/app/dashboard/guest-feedback/page.tsx`:
  - טקסט אורח ארוך מתקפל ב-`<details>`
  - עמודת **הערות צוות** (`staff_notes`) + כפתור שמירה
  - **מחיקה** של שורת משוב (אחרי אישור)
- **מיגרציה:** `supabase/migrations/20260504000001_guest_feedback_staff_notes.sql` — מוסיפה `guest_feedback.staff_notes` (TEXT).

> **חשוב:** לפני שהעמוד לא יפול ב-REST, הרץ את המיגרציה ב-Supabase (`db push` או SQL Editor).

- **תיעוד Push:** עודכן `docs/superpowers/specs/2026-05-03-push-notifications-design.md` — אירוע `room_assigned` על `rooms` UPDATE + שורת webhook `push_room_assigned`.

---

## ✅ מה עובד

### אפליקציית הצוות (Flutter)
- [x] Login — **superadmin@hotel.com / Admin1234!** ✅
- [x] Dashboard מנהל — KPIs, Analytics, טאבים
- [x] Rooms — רשימת חדרים, עדכון סטטוס
- [x] Tickets — יצירה, assign, chat, SLA, פילטרים
- [x] Housekeeping — checklist, assignments
- [x] Guest Requests — רשימה, סטטוס, FAQ, ייצוא Excel
- [x] Guest Feedback — רשימה, ייצוא Excel
- [x] QR code button (הצגה + שיתוף)
- [x] Analytics — גרף בקשות (תוקן: `assigned_dept`)
- [x] OneSignal SDK — מותקן ומחובר ל-login

### Admin Panel (Next.js)
- [x] פורטל ב-localhost
- [x] ניהול מלונות, משתמשים, analytics, logs
- [x] עמודי Guest Requests + Guest Feedback
- [x] QR codes per room
- [x] stay_threshold שדה

### Guest PWA
- [x] פרוס ב-Netlify: **https://exquisite-cocada-7966bd.netlify.app**
- [x] Landing screen — שם + חדר (עם pre-fill מURL)
- [x] Home screen — רשימת בקשות + feedback banner
- [x] New request + Feedback
- [x] OneSignal Web SDK — מותקן

---

## 🔴 מה לא עובד / נשאר לעשות

### 1. JWT Hook — צריך לאמת שה-SQL האחרון רץ

הרץ ב-**Supabase → SQL Editor** (אם עדיין לא):

```sql
CREATE OR REPLACE FUNCTION public.custom_jwt_claims(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_record users%ROWTYPE;
  user_id     uuid;
  base_claims jsonb;
  custom_meta jsonb;
BEGIN
  user_id     := (event->>'user_id')::uuid;
  base_claims := event->'claims';

  SELECT * INTO user_record FROM users WHERE id = user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('claims', base_claims);
  END IF;

  -- jsonb_strip_nulls מסיר hotel_id כשהוא NULL (לsuperadmin)
  custom_meta := jsonb_strip_nulls(jsonb_build_object(
    'hotel_id',  user_record.hotel_id,
    'role',      user_record.role,
    'is_active', user_record.is_active
  ));

  RETURN jsonb_build_object(
    'claims',
    base_claims || jsonb_build_object(
      'app_metadata',
      COALESCE(base_claims->'app_metadata', '{}'::jsonb) || custom_meta
    )
  );
END;
$$;
```

אחרי שמריץ — בדוק ב-**Authentication → Auth Hooks** שה-hook רשום:
- Hook type: **Custom Access Token**
- Function: **public.custom_jwt_claims**

---

### 2. סיסמאות משתמשי טסט — לתקן

הרץ **כל שאילתה בנפרד** ב-Supabase SQL Editor:

```sql
UPDATE auth.users
SET encrypted_password = crypt('Reception1234!', gen_salt('bf'))
WHERE email = 'reception@hotel.com';
```

```sql
UPDATE auth.users
SET encrypted_password = crypt('Manager1234!', gen_salt('bf'))
WHERE email = 'manager@hotel.com';
```

```sql
UPDATE auth.users
SET encrypted_password = crypt('Tech1234!', gen_salt('bf'))
WHERE email = 'tech@hotel.com';
```

```sql
UPDATE auth.users
SET encrypted_password = crypt('Maintenance1234!', gen_salt('bf'))
WHERE email = 'maintenance@hotel.com';
```

אחרי זה — נסה login מחדש עם כל משתמש.

---

### 3. DB Migration — stay_threshold

```sql
ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS stay_threshold INT NOT NULL DEFAULT 3;
```

---

### 4. Push Notifications (OneSignal) — להגדיר

**שלב א — OneSignal:**
1. צור חשבון ב-[onesignal.com](https://onesignal.com)
2. צור App → הוסף פלטפורמות (Android / iOS / Web Push)
3. העתק **App ID** ו-**REST API Key**

**שלב ב — Supabase Secrets:**
```
ONESIGNAL_APP_ID       = ...
ONESIGNAL_REST_API_KEY = ...
WEBHOOK_SECRET         = (הרץ: openssl rand -hex 32)
```

**שלב ג — Deploy Edge Function:**
```bash
cd "/Users/boazsaada/manegmant resapceon"
supabase functions deploy send-push
```

**שלב ד — 4 Database Webhooks** (Supabase → Database → Webhooks):

| שם | טבלה | Event | Header x-event-type |
|----|------|-------|---------------------|
| push_guest_request_insert | guest_requests | INSERT | guest_request_insert |
| push_guest_request_update | guest_requests | UPDATE | guest_request_status |
| push_ticket_insert | tickets | INSERT | ticket_insert |
| push_ticket_assigned | ticket_assignments | INSERT | ticket_assigned |
| **push_room_assigned** (מומלץ) | **rooms** | **UPDATE** | **room_assigned** |

כל ה-webhooks שולחים ל-`{supabase-url}/functions/v1/send-push` עם header `x-webhook-secret`.

**שלב ה — PWA App ID:**
החלף `YOUR_ONESIGNAL_APP_ID` ב-`hotel_guest_app/web/index.html` עם ה-App ID האמיתי, ואז:
```bash
cd hotel_guest_app && flutter build web --release
```

---

### 5. iOS — OneSignal APNs

לפני שOnESignal עובד על iOS:
1. Apple Developer → Certificates → Keys → צור APNs .p8 key
2. OneSignal Dashboard → Platforms → Apple iOS → העלה את ה-.p8

---

## 📋 טבלת משתמשי טסט

| Email | סיסמה | Role | מצב |
|-------|-------|------|-----|
| superadmin@hotel.com | Admin1234! | super_admin | ✅ עובד |
| manager@hotel.com | Manager1234! | reception_manager | ❓ לאמת |
| reception@hotel.com | Reception1234! | receptionist | ❌ לא עובד |
| tech@hotel.com | Tech1234! | maintenance_tech | ❓ לאמת |
| maintenance@hotel.com | Maintenance1234! | maintenance_manager | ❓ לאמת |

**Hotel Alpha ID:** `00000000-0000-0000-0000-000000000001`

---

## 📦 איפה הכל יושב

| שכבה | מיקום |
|------|-------|
| Flutter Staff App | `/Users/boazsaada/manegmant resapceon/` (localhost בפיתוח) |
| Guest PWA | https://exquisite-cocada-7966bd.netlify.app |
| Admin Panel | `/Users/boazsaada/manegmant resapceon/admin/` (localhost) |
| Backend | Supabase: vetwlonyzyzvhrtdwbzj.supabase.co |
| Edge Functions | `supabase/functions/` (send-push, invite-user, manage-user, run-scheduled-tasks, export-excel) |

---

## 🔢 סדר עדיפויות לתיקון

1. **הרץ את SQL של JWT hook** (שלב 1 למעלה)
2. **תקן סיסמאות** (שלב 2)
3. **בדוק login** — reception@hotel.com → אם עובד, ממשיכים
4. **stay_threshold migration** (שלב 3)
5. **OneSignal** — אפשר לדחות לסוף
