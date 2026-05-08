-- Update guest_pwa_url to the new Netlify deployment.
-- The previous default 'https://zesty-queijadas-16c29.netlify.app' pointed to an
-- older site that was replaced via Netlify Drop. The canonical guest PWA now
-- lives at 'https://exquisite-cocada-7966bd.netlify.app'.

ALTER TABLE hotels
  ALTER COLUMN guest_pwa_url
  SET DEFAULT 'https://exquisite-cocada-7966bd.netlify.app';

UPDATE hotels
   SET guest_pwa_url = 'https://exquisite-cocada-7966bd.netlify.app'
 WHERE guest_pwa_url IS NULL
    OR guest_pwa_url = 'https://zesty-queijadas-16c29.netlify.app'
    OR trim(guest_pwa_url) = '';
