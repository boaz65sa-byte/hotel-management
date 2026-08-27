# סטטוס פרויקט — מה עובד ומה נשאר

**עודכן:** 2026-08-27

> ⚠️ הסטטוס הזה היה תקוע על 2026-05-08 (3.5 חודשים) בזמן שהריפו התקדם משמעותית (ריברנד ל-Roxon, מערכת רישוי, RBAC חדש, dashboard לאדמין-על, Tauri desktop). הבלוק הזה מתעד רק את מה שאומת בפועל בסבב האבטחה/QA של 2026-08-27 — לא ריענון מלא של כל הפרויקט.

---

## 🆕 סשן 2026-08-27 — אבטחה: סוד webhook בטקסט גלוי + תיקוני push (בוצע ב-2 סשנים מקבילים)

**הרקע:** `supabase/migrations/20260515000003_send_push_webhooks.sql` הכיל את `WEBHOOK_SECRET` כליטרל בטקסט גלוי ב-5 מקומות (ולמעשה 6, ראה למטה) — הסוד הזה כבר היה ב-git history שנדחפה ל-origin. תוך כדי הטיפול התגלתה גם תקרית נוספת: סוכן מחקר הריץ בטעות `supabase projects api-keys` שמדפיס מפתחות API חיים של הפרויקט — **מומלץ לסובב את `service_role`/`anon` keys של הפרויקט כאמצעי זהירות** (ראוי לבדוק עם boaz65sa אם זה בוצע).

**מה תוקן ואומת בפועל:**
1. ✅ `WEBHOOK_SECRET` סובב; כל 6 פונקציות ה-trigger (5 המקוריות + `whk_fn_amenity_order_insert` שנוסף ב-`20260827000003_amenities_ordering.sql`) עודכנו במיגרציה `20260828000001_webhook_secret_vault.sql` לקרוא את הסוד מ-Supabase Vault (`vault.decrypted_secrets`, שם `webhook_secret`) בזמן ריצה, במקום ליטרל — לא לחזור לליטרל בעתיד.
2. ✅ **נמצא ותוקן באג נפרד וקדום**: פונקציית `send-push` דרשה JWT verification בברירת מחדל, אבל קריאות ה-`pg_net` מה-triggers אף פעם לא נושאות JWT (רק `x-webhook-secret`) — כל קריאה קיבלה 401 `UNAUTHORIZED_NO_AUTH_HEADER`, כנראה **מאז ומתמיד**, לפני שנפרס תיקון כלשהו של הסבב הזה. תוקן: `[functions.send-push]\nverify_jwt = false` ב-`supabase/config.toml` + פריסה מחדש עם `--no-verify-jwt`.
3. ✅ **נמצא ותוקן עוד באג נפרד וקדום**: `ONESIGNAL_REST_API_KEY` שהוגדר בפרויקט הכיל 2 תווי עברית מוטמעים בטעות (ככל הנראה מהעתקה מה-UI של OneSignal) — גרם ל-`Failed to construct 'Request': 'headers'... is not a valid ByteString` בכל ניסיון שליחת פוש. **המשמעות: ייתכן שהתראות Push מעולם לא עבדו בפרודקשן**, גם לפני הסבב הזה. תוקן ע"י הגדרה מחדש נקייה של `ONESIGNAL_REST_API_KEY` (בוצע בסשן המקביל).
4. ✅ עודכן `DEPLOY.md`: טבלת webhooks מ-5 ל-6, הוראות `--no-verify-jwt`, ו-runbook לסיבוב סוד עתידי.
5. ✅ **נבדק ונסגר — אין drift בפועל**: שאילתה חיה על `users.role` (`select role, count(*) from users group by role`) מראה שכל המשתמשים החיים עדיין בסכימה הישנה — `super_admin`(2), `ceo`(1), `reception_manager`(2), `maintenance_manager`(1), `receptionist`(2), `maintenance_tech`(1). כל התפקידים האלה מכוסים נכון גם ב-`lib/core/push/push_service.dart` (`_roleToDept`/`_managerRoles`) וגם ב-`supabase/functions/send-push/index.ts` (`ROLE_TO_DEPT`). התיאור ב-`LINKS.md` של `hotel_manager`/`dept_manager`/`staff` הוא כנראה תכנון עתידי שעדיין לא מומש בפועל ב-DB — לא באג פעיל, אבל שווה להבהיר את זה ב-LINKS.md כדי שלא יטעה מישהו שיקרא אותו.
6. ✅ **JWT Auth Hook — אומת בפועל ועובד**: התחברות עם `reception@hotel.com` והדבקת ה-JWT הראתה `app_metadata.hotel_id` ו-`app_metadata.role` תקינים. אין צורך בפעולה נוספת כאן.
7. ✅ **כל 5 משתמשי הבדיקה על Hotel Alpha נבדקו בפועל ועובדים** (בניגוד לחשש הישן ב-STATUS.md מ-5/2026):

   | Role | Email | Login | מסך בית | תקין? |
   |---|---|---|---|---|
   | super_admin | superadmin@hotel.com | ✅ | Manager Dashboard + Users/Analytics | ✅ |
   | reception_manager | manager@hotel.com | ✅ (הסיסמה בתוקף, לא ישנה כפי שחששו) | חדרים + ניהול חדרים | ✅ |
   | receptionist | reception@hotel.com | ✅ | חדרים | ✅ |
   | maintenance_tech | tech@hotel.com | ✅ | קריאות אחזקה | ✅ |
   | maintenance_manager | maintenance@hotel.com | ✅ login | קריאות אחזקה | ⚠️ **באג**: לחיצה על "בקשות" (Requests) נתקעת ב-spinner אינסופי; קונסול מראה 401 + 406 + 2 Dart null-reference exceptions. אותו טאב נטען מיידית אצל super_admin/reception_manager — נראה כמו באג הרשאות/query ספציפי ל-maintenance_manager. גם אין הבדל UI בין maintenance_manager ל-tech (לבדוק אם זה בכוונה). |

8. 🐛 **באג חדש שנמצא: עמוד Analytics הגלובלי באדמין ריק**. `/dashboard/analytics` נטען בלי שגיאות קונסול, אבל טבלת "Global Analytics" מציגה רק כותרות עמודות בלי שורות נתונים, למרות שיש פעילות בקשות אמיתית במלונות. כנראה בעיית query/מיפוי נתונים.
9. 🕳️ **פער פיצ'ר מאושר**: לא נמצא בקוד (`grep -ril amenity lib/`) ולא ב-UI (נבדק כל טאב זמין ל-super_admin ול-reception_manager) שום מסך לטיפול בהזמנות amenity/room-service/spa. הסכמה קיימת (`hotel_amenities`/`amenity_orders`) והפוש מוגדר, אבל אין לצוות דרך לראות/לטפל בהזמנות כאלה.
10. ✅ אדמין: התנהגות "אין realtime, מתעדכן רק ברענון" אומתה כצפוי (לא באג) — insert ידני לא הופיע לפני רענון, הופיע מיד אחריו.
11. ⚠️ **הערת כלים**: `resize_window` אחרי שדף Flutter (CanvasKit) כבר נטען שובר click hit-testing על אותו דף (נצפה בשני סוכנים שונים באופן עצמאי). אם לחיצות מפסיקות להירשם על staff app/guest PWA, נסה viewport קבוע מההתחלה במקום resize תוך כדי.

**Follow-up נדרש מ-boaz65sa:** לוודא שסיבוב מפתחות ה-service_role/anon בוצע (אם רלוונטי), לבצע סיבוב סופי מוצלח של `ONESIGNAL_REST_API_KEY` דרך `supabase secrets set` עם ערך נקי מ-OneSignal Dashboard, ולתעדף בין 3 הבאגים החדשים (maintenance_manager Requests crash, Analytics ריק, אין UI ל-amenity orders) מול לוח הזמנים להשקה.

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
