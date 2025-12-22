-- Merchant ve Courier tokenlarını kontrol et
SELECT 
  id,
  email,
  role,
  LEFT(fcm_token, 50) as token_preview,
  LENGTH(fcm_token) as token_length,
  updated_at
FROM users
WHERE email IN ('merchantt@test.com', 'courier@onlog.com')
ORDER BY email;
