# 🔗 Roxon — רכז קישורים

> **Roxon** · מערכת ניהול מלון · עוד אחד מהפיתוחים מבית היוצר של **BS-Simple.com**

---

## 🚀 כתובות חיות

| מערכת | URL | למי |
|---|---|---|
| **Admin Panel** (סופר אדמין) | <https://hotel-management-rho-two.vercel.app> | בועז + מנהלים |
| **Guest PWA** (אורחים) | <https://exquisite-cocada-7966bd.netlify.app> | האורחים — סורקים QR |
| **Staff App** (עובדים) | _להעלות עכשיו ל-Netlify_ (ראה מטה) | קבלה, אחזקה, משק בית |
| **GitHub** | <https://github.com/boaz65sa-byte/hotel-management> | קוד מקור |
| **Supabase** | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj> | DB + Auth |

---

## 🏨 מלון רוקסון רד סי אילת (לדמו ביום ראשון)

**ID:** `72367ec2-5155-43f7-9788-85975d50058c`

| מטרה | קישור |
|---|---|
| 📱 PWA לאורחים (סרוק QR או לחץ) | <https://exquisite-cocada-7966bd.netlify.app/#/?hotel=72367ec2-5155-43f7-9788-85975d50058c> |
| ⚙️ ערוך פרטי מלון + העלאת לוגו | <https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c> |
| 🛏️ ניהול חדרים (כולל בולק-אד) | <https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c/rooms> |
| 🔲 QR למלון + לחדרים | <https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c/qr-codes> |
| 🖨️ פוסטר A4 להדפסה | <https://hotel-management-rho-two.vercel.app/dashboard/hotels/72367ec2-5155-43f7-9788-85975d50058c/qr-codes/poster> |

---

## 👥 מסכי הצוות — איך מתחברים?

האפליקציה לעובדים (Staff App) רצה כ-Web — אחרי שתעלה אותה ל-Netlify (ראה הוראות מטה), כל אחד יכנס דרך הדפדפן:

### יצירת משתמש דמו דרך הפאנל

לפני יום ראשון: צור משתמשים אמיתיים דרך **Admin → "📋 ניהול משתמשים" → "+ הוספת משתמש"**:

1. **מנהל מלון** — role: `hotel_manager` · רואה את כל המחלקות
2. **מנהל קבלה** — role: `dept_manager` · assigned_dept: `reception`
3. **מנהל אחזקה** — role: `dept_manager` · assigned_dept: `maintenance`
4. **מנהל משק** — role: `dept_manager` · assigned_dept: `housekeeping`
5. **עובד קבלה** — role: `staff` · assigned_dept: `reception`
6. **טכנאי אחזקה** — role: `staff` · assigned_dept: `maintenance`

לכל אחד תשלח לעצמך כתובת מייל ייחודית (שמייל הזמנה מגיע אליה). אחרי שתאשר את ההזמנה → תיכנס ל-Staff App URL → תתחבר → תראה את המסך **ספציפי לתפקיד**.

### היררכיית הרשאות

| Role | רואה | פעולות |
|---|---|---|
| `super_admin` | כל המלונות, כל הנתונים | הכל |
| `hotel_manager` | המלון שלו (כל המחלקות) | יצירת תקלות, הקצאה, סטטיסטיקות |
| `dept_manager` | רק התקלות של המחלקה שלו | אישור / סגירה / הקצאה לטכנאי |
| `staff` | רק תקלות שהוקצו לו | עדכון סטטוס, העלאת תמונות |

---

## 🚀 איך להעלות את Staff App ל-Netlify

1. הבילד מוכן ב-`build/web` (כבר פתחתי לך Finder)
2. עבור ל-<https://app.netlify.com/drop>
3. גרור את התיקייה `web` (לא הקבצים בודדים)
4. תקבל URL חדש (משהו כמו `xxx.netlify.app`)
5. שמור את ה-URL כאן בקובץ במקום "_להעלות עכשיו..._"

---

## 🗺️ עמודי ה-Admin

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

## 🏨 כל המלונות במערכת

| ID | שם | קישור PWA |
|---|---|---|
| `72367ec2-...50058c` | **מלון רוקסון רד סי אילת** ⭐ | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=72367ec2-5155-43f7-9788-85975d50058c) |
| `aaaaaaaa-...000001` | מלון דן תל אביב | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=aaaaaaaa-0000-0000-0000-000000000001) |
| `00000000-...000001` | Hotel Alpha (בדיקות) | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=00000000-0000-0000-0000-000000000001) |
| `00000000-...000002` | Hotel Beta (בדיקות) | [פתח](https://exquisite-cocada-7966bd.netlify.app/#/?hotel=00000000-0000-0000-0000-000000000002) |

---

## 🔌 Supabase — קישורים שימושיים

| מה | קישור |
|---|---|
| SQL Editor | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/sql/new> |
| Auth Users | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/auth/users> |
| Storage (לוגואים) | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/storage/buckets/hotel-logos> |
| Edge Functions | <https://supabase.com/dashboard/project/vetwlonyzyzvhrtdwbzj/functions> |

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
| פרזנטציה ליום ראשון | `presentation.html` (פתח בכרום) |

---

## 🆘 פתרון בעיות מהיר

| בעיה | פתרון |
|---|---|
| אורח רואה "ברוכים הבאים" בלי שם המלון | Cmd+Shift+R בדפדפן (cache PWA) |
| עובד לא יכול להיכנס | בדוק שיש לו `email_confirmed_at` ב-Supabase Auth |
| אין QR-ים בעמוד QR | המלון חסר חדרים — לך ל-`/rooms` ועשה בולק-אד |
| Admin מציג 404 | Vercel באמצע build, חכה 30 שניות ורענן |

---

עדכון אחרון: 2026-05-14 · **Roxon** by BS-Simple.com
