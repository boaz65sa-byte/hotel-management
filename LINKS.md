# 🔗 רכז קישורים — מערכת ניהול מלון

> מסמך אחד עם כל הכתובות החיות, ה-IDs, ועמודי ה-Admin. שמור — תפתח כשצריך.

---

## 🚀 כתובות חיות

| מערכת | URL | למי |
|---|---|---|
| **Super Admin / Admin Panel** | <https://hotel-management-rho-two.vercel.app> | אתה (Boaz) |
| **Guest PWA (אורחים)** | <https://exquisite-cocada-7966bd.netlify.app> | האורחים — סורקים QR |
| **GitHub Repo** | <https://github.com/boaz65sa-byte/hotel-management> | קוד מקור |
| **Supabase Dashboard** | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj> | ניהול DB + Auth |
| **Vercel Dashboard** | <https://vercel.com/dashboard> | Admin deploys |
| **Netlify Dashboard** | <https://app.netlify.com/projects/exquisite-cocada-7966bd> | PWA deploys |

---

## 🏨 4 המלונות במערכת

| ID | שם | ק"י לאורחים | QR + פוסטר |
|---|---|---|---|
| `aaaaaaaa-0000-0000-0000-000000000001` | מלון דן תל אביב | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=aaaaaaaa-0000-0000-0000-000000000001) | [QR](https://hotel-management-rho-two.vercel.app/dashboard/hotels/aaaaaaaa-0000-0000-0000-000000000001/qr-codes) · [פוסטר](https://hotel-management-rho-two.vercel.app/dashboard/hotels/aaaaaaaa-0000-0000-0000-000000000001/qr-codes/poster) |
| `72367ec2-5155-43f7-9788-85975d50058c` | מלון רוקסון רד סי אילת | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=72367ec2-5155-43f7-9788-85975d50058c) | [QR](https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c/qr-codes) · [פוסטר](https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c/qr-codes/poster) |
| `00000000-0000-0000-0000-000000000001` | Hotel Alpha (בדיקות) | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=00000000-0000-0000-0000-000000000001) | [QR](https://hotel-management-rho-two.vercel.app/dashboard/hotels/00000000-0000-0000-0000-000000000001/qr-codes) |
| `00000000-0000-0000-0000-000000000002` | Hotel Beta (בדיקות) | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=00000000-0000-0000-0000-000000000002) | [QR](https://hotel-management-rho-two.vercel.app/dashboard/hotels/00000000-0000-0000-0000-000000000002/qr-codes) |

> 💡 כל לינק "QR" פותח גם את ה-QR למלון השלם וגם את ה-QR לכל חדר (יחד עם כפתור "פוסטר A4" להדפסה).

---

## 🗺️ עמודי ה-Admin — תפריט מהיר

| מטרה | קישור |
|---|---|
| 📋 רשימת מלונות | <https://hotel-management-rho-two.vercel.app/dashboard/hotels> |
| ➕ הקמת מלון חדש (אשף 3 שלבים) | <https://hotel-management-rho-two.vercel.app/dashboard/hotels/new> |
| 👤 ניהול משתמשים | <https://hotel-management-rho-two.vercel.app/dashboard/users> |
| 📊 Analytics | <https://hotel-management-rho-two.vercel.app/dashboard/analytics> |
| 🛎️ Guest Requests | <https://hotel-management-rho-two.vercel.app/dashboard/guest-requests> |
| ⭐ Guest Feedback | <https://hotel-management-rho-two.vercel.app/dashboard/guest-feedback> |
| ✅ Checklists | <https://hotel-management-rho-two.vercel.app/dashboard/checklists> |
| 🤖 Automations | <https://hotel-management-rho-two.vercel.app/dashboard/automations> |
| 📝 Logs | <https://hotel-management-rho-two.vercel.app/dashboard/logs> |

---

## 🛠️ ניהול מלון בודד (החלף `<ID>` ב-ID של המלון)

```
/dashboard/hotels/<ID>              ← עריכת פרטים + לוגו + שפה + תוכנית
/dashboard/hotels/<ID>/rooms        ← חדרים + בולק-אד 🆕
/dashboard/hotels/<ID>/qr-codes     ← QR למלון + QR לכל חדר
/dashboard/hotels/<ID>/qr-codes/poster ← פוסטר A4 להדפסה
```

---

## 🔌 Supabase — קישורים שימושיים

| מה | קישור |
|---|---|
| SQL Editor | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/sql/new> |
| Auth Users | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/auth/users> |
| Storage (לוגואים) | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/storage/buckets/hotel-logos> |
| Edge Functions | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/functions> |
| Database Tables | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/database/tables> |

**Project ref:** `vetwlonyzyzvhrtdwbzj`

---

## 📂 קבצים חשובים בפרויקט

| מטרה | נתיב |
|---|---|
| תיעוד התקדמות | `PROGRESS.md` |
| מסמך זה | `LINKS.md` |
| מצב סטטוס מלא | `docs/STATUS.md` |
| מדריך פריסה | `DEPLOY.md` |
| Resume מהיר | `RESUME.md` |
| פרזנטציה | `presentation.html` (פתח בכרום) |

---

## 🆘 פתרון בעיות מהיר

| בעיה | פתרון |
|---|---|
| אורח רואה "ברוכים הבאים" בלי שם המלון | בדוק שה-URL מכיל `?hotel=<id>`. אם כן — refresh חזק (Cmd+Shift+R). |
| חדש לא נשמר | בדוק שיש לך הרשאת super_admin ב-Supabase (`users.role`). |
| אין QR-ים בעמוד QR | המלון חסר חדרים — לך ל-`/rooms` ועשה בולק-אד. |
| Admin מציג 404 | Vercel באמצע build, חכה 30 שניות ורענן. |

---

עדכון אחרון: 2026-05-14
