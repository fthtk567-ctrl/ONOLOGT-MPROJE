-- TÜM KURYELERİN AKTİF/PASİF DURUMU

SELECT 
    email as "Email",
    full_name as "Ad Soyad",
    owner_name as "İsim",
    is_active as "Hesap Aktif mi?",
    is_available as "Mesaide mi?",
    status as "Onay Durumu",
    current_location as "Konum",
    created_at as "Kayıt Tarihi",
    last_login as "Son Giriş"
FROM users
WHERE role = 'courier'
ORDER BY is_active DESC, is_available DESC, email;

-- Özet istatistik
SELECT 
    COUNT(*) as "Toplam Kurye",
    COUNT(CASE WHEN is_active = true THEN 1 END) as "Aktif Hesap",
    COUNT(CASE WHEN is_active = false THEN 1 END) as "Pasif Hesap",
    COUNT(CASE WHEN is_available = true THEN 1 END) as "Mesaide",
    COUNT(CASE WHEN is_available = false THEN 1 END) as "Mesai Dışı"
FROM users
WHERE role = 'courier';
