-- Adds the "software_manager" role to user_role.
--
-- Role hierarchy clarified:
--   super_admin       -> Boaz, the platform owner / developer.
--                       Sees every hotel, manages everything.
--   ceo               -> "מנכ"ל מלון" — hotel-level admin scoped to ONE hotel.
--                       Sees and manages only that hotel's data + users.
--   software_manager  -> "מנהל תוכנה" — hotel-level admin scoped to ONE hotel.
--                       Same powers as the CEO but typically the IT contact.
--   hotel_admin       -> Legacy synonym. Kept for backwards compatibility.
--   <dept>_manager    -> Department head: reception / maintenance /
--                       housekeeping / security.
--   <staff>           -> Operational staff (receptionist, security_guard,
--                       maintenance_tech, repairman, deputy_reception).
--
-- Idempotent — re-running the migration is safe.

ALTER TYPE user_role
  ADD VALUE IF NOT EXISTS 'software_manager' AFTER 'ceo';
