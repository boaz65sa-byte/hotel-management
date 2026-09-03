-- Cleanup: remove test fixtures created during Phase 6 end-to-end QA
-- (real guest request, real feedback, and a test amenity item, all
-- submitted through the actual live UI to verify the RLS fixes and new
-- features work for a real guest, not just via curl).
DELETE FROM guest_requests WHERE id = 'acbf3a82-11be-47c3-a73c-e75917931f2d';
DELETE FROM guest_feedback WHERE id = 'e4fcd41b-bfed-4b96-b249-9c690b33d101';
DELETE FROM hotel_amenities WHERE id = '33333333-3333-3333-3333-333333333333';
