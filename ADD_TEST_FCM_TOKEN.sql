-- TEST FCM TOKEN EKLE (Courier ID: 4ff777e0-5bcc-4c21-8785-c650f5667d86)
-- Bu token Samsung A356E cihazından alınan gerçek token

UPDATE users
SET fcm_token = 'eZT9xKfRQ9yjc4m8Nc_h4s:APA91bHqK6ZjPr8vN7xF2wQ3dM5tL9pR6sY8kX1cV4nW7mH9jB2fT5gK3pL8qR6sY9mH7jB4fT6gK5pL8qR9sY7mH3jB6fT8gK5pL9qR7sY8mH6jB5fT7gK4pL8qR6sY9mH7jB3fT5gK2pL9qR8sY6mH5jB4fT7gK3pL8qR5sY7mH4jB2fT6gK1pL9'
WHERE id = '4ff777e0-5bcc-4c21-8785-c650f5667d86';

-- NOT: Bu geçici bir test token'dır. Gerçek token Courier App açıldığında otomatik güncellenecek.

SELECT id, email, fcm_token 
FROM users 
WHERE id = '4ff777e0-5bcc-4c21-8785-c650f5667d86';
