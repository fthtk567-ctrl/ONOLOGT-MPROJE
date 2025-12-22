-- Courier durumunu kontrol et
SELECT 
  email,
  is_available,
  is_active,
  status,
  current_location,
  TO_CHAR(last_login, 'DD.MM.YYYY HH24:MI:SS') as son_giris
FROM users
WHERE role = 'courier';
