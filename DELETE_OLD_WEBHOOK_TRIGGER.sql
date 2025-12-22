-- ======================================================================
-- ESKİ WEBHOOK TRİGGER'INI SİL
-- ======================================================================
-- SORUN: İki tane aynı trigger var, ikisi de webhook gönderiyor!
-- ÇÖZÜM: Eski trigger'ı (trigger_notify_external_platform) sil
-- ======================================================================
-- Tarih: 27 Kasım 2025
-- ======================================================================

-- Eski trigger'ı sil (yanlış isimli olan)
DROP TRIGGER IF EXISTS trigger_notify_external_platform ON delivery_requests;

-- Doğrulama - Sadece yeni trigger kalmalı
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_name LIKE '%notify%platform%'
ORDER BY trigger_name;

-- Beklenen sonuç: Sadece 'trigger_notify_platform_on_status_change' görünmeli

COMMIT;

-- ======================================================================
-- AÇIKLAMA
-- ======================================================================
/*
SORUN:
- trigger_notify_external_platform (ESKİ - SİLİNDİ ❌)
- trigger_notify_platform_on_status_change (YENİ - KALACAK ✅)

İkisi de aynı fonksiyonu çağırıyordu, bu yüzden webhook 2 kere gidiyordu!

ŞİMDİ:
1. Yemek App → Sipariş gelir (status: 'pending')
   ❌ Webhook gitmez

2. Otomatik kurye ataması (status: 'assigned')
   ❌ Webhook gitmez (yeni trigger 'assigned' durumunu skip ediyor)

3. Kurye kabul eder (status: 'accepted')
   ✅ Webhook gider: "Kurye yolda"
*/
