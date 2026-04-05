# מערכת קריאות מרכזית — Design Spec
**תאריך**: 2026-04-05
**סטטוס**: מאושר ✅
**שלב**: Phase 8

---

## סקירה כללית

מערכת קריאות אחידה המכסה את כל מחלקות המלון. כל עובד מורשה יכול לפתוח קריאה לכל מחלקה. הקריאה נופלת לתור המחלקה הרלוונטית, והאחראי משבץ ידנית.

---

## Design System

### מצב יום — Warm Hospitality
| Token | Value |
|-------|-------|
| Primary | `#ea580c` |
| Primary Dark | `#c2410c` |
| Background | `#fdf6f0` |
| Surface | `#ffffff` |
| Border | `#fed7aa` |
| Text Primary | `#1f2937` |
| Text Muted | `#9ca3af` |
| Success | `#16a34a` |
| Error | `#dc2626` |
| Warning | `#d97706` |

### מצב לילה — Navy Professional
| Token | Value |
|-------|-------|
| Primary (Gold) | `#c9a84c` |
| Accent | `#2563eb` |
| Background | `#0a1628` |
| Surface | `#0f1f3d` |
| Elevated | `#1a3160` |
| Text Primary | `#e2e8f0` |
| Text Muted | `#7c9dc4` |
| Success | `#4ade80` |
| Error | `#f87171` |

---

## מחלקות

| מחלקה | מזהה | צבע chip | אייקון |
|-------|------|----------|--------|
| אחזקה | `maintenance` | `#eff6ff` / `#2563eb` | 🔧 |
| קבלה | `reception` | `#fdf4ff` / `#9333ea` | 🛎️ |
| ביטחון | `security` | `#fff7ed` / `#d97706` | 🔒 |
| משק בית | `housekeeping` | `#f0fdf4` / `#16a34a` | 🧹 |

---

## רמות דחיפות

| רמה | מזהה | צבע | SLA ברירת מחדל | תמונה חובה |
|-----|------|-----|----------------|------------|
| נמוך | `low` | ירוק `#16a34a` | 24 שעות | לא |
| רגיל | `normal` | אפור `#4b5563` | 4 שעות | לא |
| דחוף | `urgent` | כתום `#ea580c` | 2 שעות | מומלץ |
| חירום | `emergency` | אדום `#dc2626` | 30 דקות | **חובה** |

---

## DB Schema

### הרחבת `tickets`
```sql
ALTER TABLE tickets ADD COLUMN department text
  CHECK (department IN ('maintenance','reception','security','housekeeping'))
  DEFAULT 'maintenance';

ALTER TABLE tickets ADD COLUMN priority text
  CHECK (priority IN ('low','normal','urgent','emergency'))
  DEFAULT 'normal';

ALTER TABLE tickets ADD COLUMN assigned_to uuid REFERENCES users(id);
ALTER TABLE tickets ADD COLUMN requires_media boolean DEFAULT false;
ALTER TABLE tickets ADD COLUMN department_notes text;
```

### `ticket_assignments` — היסטוריית שיבוצים
```sql
CREATE TABLE ticket_assignments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  assigned_to uuid NOT NULL REFERENCES users(id),
  assigned_by uuid NOT NULL REFERENCES users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  note        text
);
```

### `ticket_messages` — צ'אט בתוך קריאה
```sql
CREATE TABLE ticket_messages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id  uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  sender_id  uuid NOT NULL REFERENCES users(id),
  body       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

### `ticket_media` — תמונות לפני/אחרי
```sql
CREATE TABLE ticket_media (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  uploaded_by uuid NOT NULL REFERENCES users(id),
  url         text NOT NULL,
  media_type  text CHECK (media_type IN ('before','after','general')),
  created_at  timestamptz NOT NULL DEFAULT now()
);
```

### טריגר — `requires_media` אוטומטי
```sql
CREATE OR REPLACE FUNCTION set_requires_media()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.priority IN ('urgent','emergency') THEN
    NEW.requires_media = true;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_requires_media
  BEFORE INSERT OR UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_requires_media();
```

---

## מסכי Flutter — 5 מסכים

### 1. רשימת קריאות (`TicketListScreen`)
- סינון לפי מחלקה (tabs) + דחיפות (chips)
- מיון: חירום → דחוף → רגיל → נמוך
- כל כרטיס: מספר, מיקום, כותרת, מחלקה, דחיפות, SLA countdown
- FAB: פתיחת קריאה חדשה

### 2. פתיחת קריאה (`NewTicketScreen`)
- בחירת מחלקה (4 כפתורים ויזואליים)
- שדה מיקום (חדר / אזור)
- תיאור חופשי
- בחירת דחיפות (4 כפתורים צבעוניים)
- העלאת תמונה — חובה אם `emergency`, מומלץ אם `urgent`
- כפתור שליחה

### 3. פרטי קריאה (`TicketDetailScreen`)
- Header עם gradient + chip סטטוס + דחיפות
- SLA progress bar (אדום כשנותרות פחות מ-20%)
- תיאור + היסטוריית עדכונים
- גלריית תמונות לפני/אחרי
- כפתורי: סגור קריאה / צ'אט / שבץ

### 4. שיבוץ עובד (`AssignStaffScreen`)
- רשימת עובדים זמינים במחלקה
- לכל עובד: שם, תפקיד, עומס (progress bar), סטטוס online/busy
- בחירה ← כפתור אישור שיבוץ
- שדה הערה לשיבוץ (אופציונלי)

### 5. צ'אט בתוך קריאה (`TicketChatScreen`)
- ממשק צ'אט רגיל (bubble messages)
- מציג שם שולח + מחלקה + זמן
- תמיכה בשליחת תמונות
- תזכורת SLA בצ'אט כשמתקרב deadline

---

## היררכיית הרשאות

### שתי רמות ניהול עליונות

| תפקיד | מי הוא | מה הוא יכול |
|-------|--------|-------------|
| `super_admin` | **בעלים של האפליקציה** | מפעיל/מכבה מלונות, מעניק הרשאת `hotel_admin`, גישה לכל |
| `hotel_admin` | **מנהל האפליקציה במלון** | מוסיף/משנה/מכבה משתמשים במלון שלו בלבד |

### כללי גישה לפי תפקיד

```
super_admin
  └── יכול: כל פעולה + הענקת hotel_admin

hotel_admin (per hotel)
  └── יכול: ניהול משתמשים במלון שלו
  └── יכול: צפייה בכל קריאות המלון
  └── לא יכול: לגעת במלונות אחרים

מנהלי מחלקות (reception_manager, maintenance_manager...)
  └── יכולים: לשבץ עובדים במחלקה שלהם
  └── יכולים: לפתוח קריאות לכל מחלקה

עובדים (receptionist, maintenance_tech...)
  └── יכולים: לפתוח קריאות לכל מחלקה
  └── יכולים: לעדכן קריאות שמשובצות אליהם
```

### DB — הוספת `hotel_admin` לאנום
```sql
ALTER TYPE user_role ADD VALUE 'hotel_admin' AFTER 'super_admin';
```

### RLS — hotel_admin מנוהל ע"י super_admin בלבד
```sql
-- רק super_admin יכול ליצור/לשנות hotel_admin
CREATE POLICY hotel_admin_managed_by_super
  ON users FOR ALL
  USING (
    auth.jwt()->>'role' = 'super_admin'
    OR (
      auth.jwt()->>'role' = 'hotel_admin'
      AND hotel_id = (auth.jwt()->>'hotel_id')::uuid
      AND role != 'hotel_admin'  -- hotel_admin לא יכול ליצור hotel_admin נוסף
    )
  );
```

---

## Business Logic

### חוקי גישה
- כל עובד עם גישה לאפליקציה: יכול לפתוח קריאה לכל מחלקה
- אחראי מחלקה: יכול לשבץ עובדים בתוך המחלקה שלו
- `hotel_admin`: ניהול משתמשים + צפייה בכל קריאות המלון
- `super_admin`: גישה מלאה לכל + הענקת `hotel_admin`

### ניתוב אוטומטי
- קריאה חדשה → מחלקה שנבחרה → נראית לכל הצוות של אותה מחלקה
- אחראי מחלקה מקבל notification מיידי על קריאות חירום

### סגירת קריאה
- לפני סגירה: אם `requires_media = true` ואין תמונת "אחרי" → חסימה + הודעה
- אחרי סגירה: מדדי ביצועים מתעדכנים (SLA עמידה, זמן טיפול)

---

## Mockups
`.superpowers/brainstorm/75181-1775418232/content/ticket-screens.html`

---

## לא בסקופ (Phase זה)
- Push notifications (Phase 11)
- Realtime subscriptions (Phase 9)
- PMS integration (Phase 12)
- Analytics מתקדמות
