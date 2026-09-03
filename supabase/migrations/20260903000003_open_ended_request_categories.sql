-- supabase/migrations/20260903000003_open_ended_request_categories.sql
--
-- Lets a super admin add entirely new guest-request categories per hotel,
-- not just enable/disable the fixed housekeeping/maintenance/reception set
-- (that's what hotel_request_tiles_disabled / hotel_ticket_departments_disabled
-- already do — this is a level above them: the category list itself).
--
-- `hotel_request_categories` is the per-hotel catalog the Guest PWA's "new
-- request" screen renders as its top-level category picker, and the source
-- of truth for display label + icon. The 3 existing categories are seeded
-- as `is_system = true` rows (can be disabled but not deleted, since the
-- guest app ships curated quick-select tiles and staff-side role routing
-- for them) — anything else a super admin adds is `is_system = false`
-- (freely editable/deletable, no quick tiles, no dedicated staff-role
-- routing: visible to reception/management like any request without a
-- narrower home).

CREATE TABLE hotel_request_categories (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  key        text NOT NULL,
  label      text NOT NULL,
  icon       text NOT NULL DEFAULT '📋',
  is_system  boolean NOT NULL DEFAULT false,
  is_active  boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, key)
);

COMMENT ON TABLE hotel_request_categories IS
  'Per-hotel catalog of guest-request categories. System rows (housekeeping/maintenance/reception) are seeded for every hotel and can be disabled but not deleted. Anon-readable when active — guests browse before login, same trust model as hotel_amenities.';

ALTER TABLE hotel_request_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "request_categories_public_read_active" ON hotel_request_categories
  FOR SELECT USING (is_active = true);

CREATE POLICY "request_categories_super_admin_manage" ON hotel_request_categories
  FOR ALL USING (auth_role() = 'super_admin');

-- Seed the 3 existing categories for every hotel that doesn't have them yet
-- (idempotent — safe to re-run, and safe for hotels created after this
-- migration since new-hotel creation should also seed these, see admin
-- hotels/new/actions.ts).
INSERT INTO hotel_request_categories (hotel_id, key, label, icon, is_system, sort_order)
SELECT h.id, c.key, c.label, c.icon, true, c.sort_order
FROM hotels h
CROSS JOIN (VALUES
  ('housekeeping', 'חדרניות',  '🛏️', 1),
  ('maintenance',  'תחזוקה',   '🔧', 2),
  ('reception',    'קבלה',     '🛎️', 3)
) AS c(key, label, icon, sort_order)
ON CONFLICT (hotel_id, key) DO NOTHING;

-- guest_requests.category was constrained to exactly these 3 values —
-- open it up so a guest can submit against any category a super admin adds.
ALTER TABLE guest_requests DROP CONSTRAINT IF EXISTS guest_requests_category_check;
