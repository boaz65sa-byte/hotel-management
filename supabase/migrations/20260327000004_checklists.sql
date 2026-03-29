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

-- Seed items for ניקיון רגיל
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

-- Seed items for ניקיון VIP
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

-- Seed items for ביקורת אחזקה
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
