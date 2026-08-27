-- supabase/migrations/20260827000003_amenities_ordering.sql
--
-- Amenities/upsell ordering: a per-hotel catalog (spa/restaurant/room
-- service items) guests can browse and order from, separate from
-- guest_requests since those only ever needed one flat description string
-- — orders need a priced catalog reference + quantity. No payment fields:
-- this only records the order for staff to fulfill and bill to the room
-- manually, same trust/flow guest_requests already uses.
-- Gated per-hotel by hotels.enabled_features->>'amenities_ordering'
-- (see 20260827000002_hotel_feature_toggles.sql).

CREATE TABLE hotel_amenities (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  category    text NOT NULL CHECK (category IN ('restaurant', 'spa', 'room_service')),
  name        text NOT NULL,
  description text,
  price       numeric(10, 2),
  currency    text NOT NULL DEFAULT 'ILS',
  image_url   text,
  is_active   boolean NOT NULL DEFAULT true,
  sort_order  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE amenity_orders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  room_number text NOT NULL,
  guest_name  text NOT NULL,
  amenity_id  uuid NOT NULL REFERENCES hotel_amenities(id),
  quantity    integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  status      text NOT NULL DEFAULT 'open'
                CHECK (status IN ('open', 'confirmed', 'delivered', 'cancelled')),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE hotel_amenities IS 'Per-hotel catalog of orderable extras (spa/restaurant/room service). Anon-readable when active — guests browse before any auth, same trust model as get_hotel_branding.';
COMMENT ON TABLE amenity_orders IS 'Guest orders against hotel_amenities. No payment fields by design (v1) — staff fulfills and bills to the room manually, same as guest_requests has always worked.';

-- ─── RLS: hotel_amenities ──────────────────────────────────────────────────
ALTER TABLE hotel_amenities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "amenities_public_read_active" ON hotel_amenities
  FOR SELECT USING (is_active = true);

CREATE POLICY "amenities_staff_manage_own_hotel" ON hotel_amenities
  FOR ALL USING (
    auth_role() = 'super_admin' OR hotel_id = auth_hotel_id()
  );

-- ─── RLS: amenity_orders ───────────────────────────────────────────────────
ALTER TABLE amenity_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "amenity_orders_anyone_can_insert" ON amenity_orders
  FOR INSERT WITH CHECK (true);

CREATE POLICY "amenity_orders_staff_view_own_hotel" ON amenity_orders
  FOR SELECT USING (
    auth_role() = 'super_admin' OR hotel_id = auth_hotel_id()
  );

CREATE POLICY "amenity_orders_staff_update_own_hotel" ON amenity_orders
  FOR UPDATE USING (
    auth_role() = 'super_admin' OR hotel_id = auth_hotel_id()
  );

-- ─── Push webhook: new order → notify reception ────────────────────────────
-- Same pg_net -> send-push pattern as the other 5 triggers in
-- 20260515000003_send_push_webhooks.sql. IMPORTANT: this hardcodes the same
-- webhook secret as those triggers — if that secret is ever rotated, this
-- trigger must be updated in the same pass or it will silently start
-- failing its auth check against send-push.
CREATE OR REPLACE FUNCTION whk_fn_amenity_order_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
      'x-event-type',      'amenity_order_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE TRIGGER whk_amenity_order_insert
  AFTER INSERT ON amenity_orders
  FOR EACH ROW EXECUTE FUNCTION whk_fn_amenity_order_insert();
