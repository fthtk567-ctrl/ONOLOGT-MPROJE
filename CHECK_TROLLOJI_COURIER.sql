-- trolloji.ai@gmail.com kurye hesabını kontrol et
-- Hesap devre dışı mı, status ne durumda?

SELECT 
    id as "Kullanıcı ID",
    email as "Email",
    role as "Rol",
    full_name as "Ad Soyad",
    owner_name as "İsim",
    phone as "Telefon",
    is_active as "Aktif mi?",
    status as "Durum",
    is_available as "Mesaide mi?",
    rejection_reason as "Red Sebebi",
    created_at as "Kayıt Tarihi",
    last_login as "Son Giriş"
FROM users
WHERE email = 'trolloji.ai@gmail.com';

-- Tüm kuryelerin durumunu göster (karşılaştırma için)
SELECT 
    email as "Email",
    full_name as "Ad",
    is_active as "Aktif?",
    status as "Durum",
    is_available as "Mesaide?"
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;
