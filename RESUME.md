# 📌 Resume Here — Hotel Management

**עודכן:** 2026-05-08, סוף יום
**מצב:** Production-ready, פעיל בשטח, נשארו 2 צעדי תפעול קטנים.

---

## 🚦 כשחוזרים — תתחיל מכאן

### צעד 1 — SQL ב-Supabase (30 שניות)

פתח [Supabase SQL Editor](https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/sql/new) והדבק:

```sql
ALTER TABLE hotels
  ALTER COLUMN guest_pwa_url
  SET DEFAULT 'https://exquisite-cocada-7966bd.netlify.app';

UPDATE hotels
   SET guest_pwa_url = 'https://exquisite-cocada-7966bd.netlify.app'
 WHERE guest_pwa_url IS NULL
    OR guest_pwa_url = 'https://zesty-queijadas-16c29.netlify.app'
    OR trim(guest_pwa_url) = '';
```

לחץ **Run**. ↩

### צעד 2 — בדיקה מקצה-לקצה (דקה)

1. פתח בטלפון: <https://exquisite-cocada-7966bd.netlify.app> — אמור לראות מסך ברוכים הבאים, יכול לבחור שפה.
2. ב-Admin → Hotels → Alpha → "החלף קובץ" → העלה לוגו (PNG/JPG, עד 2MB).
3. ב-Admin → Hotels → Alpha → "🖨️ פוסטר קבלה (A4)" — אמור לראות פוסטר עם הלוגו, שם המלון ו-QR גדול.
4. סרוק את ה-QR מהפוסטר עם הטלפון → אמור לנחות במסך הברוכים-הבאים עם הלוגו ושם המלון.

אם הכל עובד — **המוצר חי**. ✅

---

## 🌐 כתובות חיות

| מערכת | URL |
|---|---|
| Admin (Super) | <https://hotel-management-rho-two.vercel.app> |
| Guest PWA | <https://exquisite-cocada-7966bd.netlify.app> |
| GitHub | <https://github.com/boaz65sa-byte/hotel-management> |
| Supabase | project `vetwlonyzyzvhrtdwbzj` |

---

## ✅ מה הספקנו ב-2026-05-08

### בוקר — Polish round
- מילוי שם המלון אמיתי במסך ה-QR ב-Staff App (במקום `'המלון'`).
- `SessionTimeoutManager` חוט ב-`app.dart` — auto sign-out על פי `idle`.
- ניקוי dead code (`acceptTicket`, `quickResolveTicket`).
- RBAC ל-Excel export — `lib/core/auth/role_helpers.dart`, מוגבל למנהלים בלבד.
- ברנדינג ל-PWA (`index.html` + `manifest.json`); מחיקת `widget_test.dart` יתומ.
- כל ה-flutter info lints נפתרו → `flutter analyze` 0/0 בשני הפרויקטים.

### צהריים — Localization & Branding
- 🇷🇺 רוסית ל-Staff App (35 מפתחות + dropdown ב-Profile).
- 🇷🇺🇮🇱🇬🇧🇸🇦 i18n מלא ל-PWA: 4 ARB files, `localeProvider` עם `shared_preferences`, flag-dropdown.
- ברנדינג למלון ב-PWA: לוגו + שם המלון בלאנדינג, נטען מ-Supabase לפי `?hotel=<id>`.

### אחה"צ — Admin Hotel Management
- Logo upload בסטוריג'ז (`hotel-logos` bucket, 2MB, PNG/JPG/WebP/SVG) + רכיב `LogoPicker`.
- אשף הקמת מלון 3-שלבי (Wizard): פרטים → חדרים (auto-numbering + skip-list) → משתמשים (bulk invites).
- שדות יצירת קשר נוספים למלונות (address/city/country/phone/email).

### ערב — QR מלון שלם
- **🆕 QR לקבלה / לובי** ב-`/dashboard/hotels/<id>/qr-codes` — QR אחד למלון השלם, פעולות: PNG / Print / Copy / Email.
- **🆕 פוסטר A4 להדפסה** ב-`/qr-codes/poster` — לוגו + שם המלון + QR ענק 120mm + הוראות סריקה ב-4 שפות.
- כפתור-קיצור 🖨️ "פוסטר קבלה (A4)" בעמוד עריכת מלון.

### לילה — Netlify redeploy + URL switch
- `flutter build web --release` ✅
- Deploy לאתר חדש `exquisite-cocada-7966bd.netlify.app` (Netlify Drop יצר אתר טרי).
- Migration `20260508000004` + עדכון 8 קבצי קוד שכל ההפניות מצביעות לאתר החדש.

---

## 🟢 מצב כל המערכת

| רכיב | מצב | הערה |
|---|---|---|
| Staff App (Flutter) | ✅ Code complete | 4 שפות. Build ל-Web/Android/iOS — מוכן ל-deploy לחנויות (אופציונלי). |
| Admin Panel (Next.js) | ✅ Live | Vercel auto-deploy on push. |
| Guest PWA (Flutter Web) | ✅ Live | Netlify, 4 שפות, ברנדינג, QR scanning. |
| Supabase Backend | ✅ Live | 6 migrations רצו היום. נשארה אחת (`20260508000004`) לרוץ מחר. |
| QR System | ✅ | Hotel-wide + per-room + A4 poster. |
| Lints / TS / Analyze | ✅ 0/0/0 | בכל 3 הפרויקטים. |
| Push Notifications | 🟡 Code ready | OneSignal — צריך secrets + 5 webhooks (אופציונלי, V1.1). |

---

## 🟡 רשימת רשות לעתיד (לא חוסם השקה)

- [ ] OneSignal: secrets + `supabase functions deploy send-push` + 5 DB webhooks + APNs `.p8`.
- [ ] Verify JWT Hook `public.custom_jwt_claims` רשום כ-Custom Access Token ב-Auth → Hooks.
- [ ] TOTP factor למשתמש Super Admin.
- [ ] Build Staff App ל-Play Store / App Store (Google + Apple Developer accounts).
- [ ] להוסיף משתמשים אמיתיים למלון Alpha דרך האשף החדש.

---

## 📂 קבצים חשובים שנגעתי בהם היום

```
admin/src/app/dashboard/hotels/[id]/qr-codes/page.tsx          (hero QR + per-room)
admin/src/app/dashboard/hotels/[id]/qr-codes/hotel-qr-actions.tsx (חדש)
admin/src/app/dashboard/hotels/[id]/qr-codes/poster/page.tsx   (חדש - A4 poster)
admin/src/app/dashboard/hotels/[id]/qr-codes/poster/print-button.tsx (חדש)
admin/src/app/dashboard/hotels/[id]/page.tsx                   (כפתורי קיצור)
admin/src/app/dashboard/hotels/new/wizard.tsx                  (3-step wizard)
admin/src/app/dashboard/hotels/new/actions.ts                  (setupHotelAction)
admin/src/components/logo-picker.tsx                           (file upload)
admin/src/app/actions/upload-logo.ts                           (server action)
admin/src/components/hotel-form.tsx                            (logo + ru)
hotel_guest_app/lib/presentation/landing_screen.dart           (branding hero)
hotel_guest_app/lib/data/guest_repository.dart                 (HotelBranding)
hotel_guest_app/lib/core/i18n/locale_provider.dart             (חדש)
hotel_guest_app/lib/l10n/app_*.arb                             (4 שפות)
lib/core/i18n/arb/app_ru.arb                                   (חדש - Russian)
supabase/migrations/20260508000001_hotels_default_language_ru.sql
supabase/migrations/20260508000002_hotels_contact_info.sql
supabase/migrations/20260508000003_hotel_logos_bucket.sql
supabase/migrations/20260508000004_hotels_pwa_url_new_default.sql ← לרוץ מחר
```

---

## 🌙 לילה טוב!

המוצר עובד. נשאר SQL קצר אחד + בדיקה. תפתח את הקובץ הזה מחר ותתחיל מ"צעד 1" למעלה. 🚀
