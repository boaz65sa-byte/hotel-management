-- Temporary test fixture: one amenity item with an image, to verify the
-- image-rendering feature end to end in the guest PWA. Cleaned up after.
INSERT INTO hotel_amenities (id, hotel_id, category, name, description, price, image_url)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '00000000-0000-0000-0000-000000000001',
  'restaurant',
  'QA Test Pasta',
  'End-to-end image rendering check',
  45,
  'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=200'
)
ON CONFLICT (id) DO NOTHING;
