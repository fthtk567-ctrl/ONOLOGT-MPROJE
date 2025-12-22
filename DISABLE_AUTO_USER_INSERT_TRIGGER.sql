-- ═══════════════════════════════════════════════════
-- ÇÖZÜM: handle_new_user TRIGGER'INI DEVRE DIŞI BIRAK
-- Problem: Auth'a kayıt olunca otomatik 'courier' rolü veriyor
-- Çözüm: Trigger'ı kapat, manuel INSERT yapalım (zaten yapıyoruz)
-- ═══════════════════════════════════════════════════

-- 1️⃣ Trigger'ı geçici olarak devre dışı bırak
ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_created;

-- 2️⃣ Kontrol et (disabled olmalı)
SELECT 
    t.tgname AS trigger_name,
    t.tgenabled AS status,
    CASE t.tgenabled
        WHEN 'D' THEN 'Disabled ✅'
        WHEN 'O' THEN 'Enabled ❌'
        ELSE 'Unknown'
    END as readable_status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname = 'users'
  AND t.tgname = 'on_auth_user_created';

-- ═══════════════════════════════════════════════════
-- NOT: Trigger'ı kapattık çünkü:
-- - Merchant panelinde manuel INSERT yapıyoruz (role='merchant')
-- - Courier app'te de manuel INSERT yapıyoruz (role='courier')
-- - Admin panelinde de manuel INSERT yapıyoruz (role='superAdmin')
-- Yani otomatik INSERT'e gerek yok!
-- ═══════════════════════════════════════════════════

-- 🔄 Tekrar açmak isterseniz:
-- ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created;
