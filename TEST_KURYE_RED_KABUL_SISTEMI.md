# 🧪 ONLOG KURYE RED/KABUL SİSTEMİ TEST PLANI

## 📱 ÖN HAZIRLIK

### 1. SQL Migration (Supabase Dashboard)
```sql
-- Supabase Dashboard > SQL Editor > New Query
-- Yukarıdaki SQL'i çalıştır (ADD_DELIVERY_REJECT_SYSTEM.sql)
```

### 2. Uygulamaları Başlat
- ✅ Courier App: `cd onlog_courier_app && flutter run`
- ✅ Merchant Panel: `cd onlog_merchant_panel && flutter run -d chrome`

---

## 🧪 TEST SENARYOLARI

### TEST 1: KABUL AKIŞI ✅
```
1. Merchant Panel:
   └─ Kurye Çağır
   └─ Paket: 1, Tutar: 50 TL
   └─ [Kurye Çağır] tıkla

2. Courier App (TEST KURYE hesabı):
   └─ Bildirim geldi mi? ✅
   └─ Ana ekranda sipariş görünüyor mu? ✅
   └─ Sipariş kartına tıkla

3. Detay Ekranı (Status: assigned):
   └─ [✓ KABUL ET] butonu var mı? ✅
   └─ [✗ REDDET] butonu var mı? ✅
   └─ [✓ KABUL ET] tıkla

4. Sonuç:
   └─ Status: assigned → accepted
   └─ Timeline: "Kabul Edildi" ✅ yeşil
   └─ Toast: "✅ Teslimat kabul edildi! Mağazaya gidebilirsiniz."
   └─ Butonlar: [📦 Toplandı İşaretle] + [⚠️ İptal Et (Ceza Risk!)]
```

---

### TEST 2: RED AKIŞI ❌
```
1. Merchant Panel:
   └─ Yeni teslimat oluştur
   └─ Paket: 2, Tutar: 100 TL

2. Courier App:
   └─ Bildirim gelir
   └─ Sipariş detayına gir
   └─ [✗ REDDET] tıkla

3. Red Dialog:
   └─ Başlık: "Teslimatı Reddet" ⚠️
   └─ İçerik: Red nedenleri listesi
   └─ [Vazgeç] veya [Reddet] butonları
   └─ [Reddet] tıkla

4. Sonuç:
   └─ Sipariş listeden kaybolur
   └─ Toast: "❌ Teslimat reddedildi. Başka kurye aranacak."
   └─ Ana ekrana dönülür

5. Supabase Kontrol:
   ```sql
   SELECT id, status, courier_id, rejected_by, rejected_at
   FROM delivery_requests
   WHERE id = 'SON_SİPARİŞ_ID'
   ORDER BY created_at DESC
   LIMIT 1;
   ```
   └─ status: 'pending'
   └─ courier_id: NULL
   └─ rejected_by: TEST_KURYE_ID ✅
```

---

### TEST 3: KABUL SONRASI İPTAL (CEZALI) ⚠️
```
1. Merchant Panel:
   └─ Yeni teslimat oluştur

2. Courier App:
   └─ Teslimatı KABUL ET
   └─ Status: accepted

3. İptal Dene:
   └─ [⚠️ İptal Et (Ceza Uygulanabilir)] tıkla

4. Ceza Dialog:
   └─ Başlık: "Dikkat!" 🔴
   └─ İçerik: 
      "⚠️ CEZA RİSKİ VAR!"
      "❌ 10 dakika yeni iş alamazsınız"
      "❌ Performans puanınız düşer"
      "❌ Merchant memnuniyetsizliği kaydedilir"
   └─ [Vazgeç] veya [İptal Et (Ceza Kabul)] butonları
   └─ [İptal Et (Ceza Kabul)] tıkla

5. Sonuç:
   └─ Sipariş listeden kaybolur
   └─ Toast: "⛔ Teslimat iptal edildi. 10 dakika yeni iş alamazsınız!" (5 saniye)
   └─ Ana ekrana dönülür

6. Supabase Kontrol:
   ```sql
   -- Teslimat durumu
   SELECT id, status, cancelled_by, cancelled_at, cancellation_reason
   FROM delivery_requests
   WHERE id = 'SİPARİŞ_ID';
   
   -- Kurye ceza durumu
   SELECT 
     id, 
     full_name, 
     penalty_until, 
     is_available,
     cancellation_count
   FROM users
   WHERE id = 'TEST_KURYE_ID';
   ```
   └─ status: 'cancelled'
   └─ cancelled_by: TEST_KURYE_ID
   └─ cancellation_reason: 'courier_cancelled_after_accept'
   └─ penalty_until: NOW() + 10 dakika
   └─ is_available: false ⛔
   └─ cancellation_count: +1

7. Yeni Sipariş Dene:
   └─ Merchant yeni teslimat oluşturur
   └─ Courier App: Bildirim GELMEMELİ! (10 dakika cezalı)
```

---

### TEST 4: PAKET ALINDIKTAN SONRA İPTAL İMKANSIZ ⛔
```
1. Courier App:
   └─ Teslimatı kabul et
   └─ [📦 Toplandı İşaretle] tıkla
   └─ Status: picked_up

2. Buton Kontrol:
   └─ [📷 Fotoğraf Çek (Zorunlu)] var ✅
   └─ [✓ Teslim Edildi İşaretle] var ✅ (gri - fotoğraf gerekli)
   └─ [İptal Et] butonu YOK! ⛔

3. Sonuç:
   └─ Kurye paketi aldıktan sonra iptal edemez
   └─ Teslim etmek ZORUNDA!
```

---

## 🔍 SUPABASE DASHBOARD KONTROL SORULARI

### Teslimat Durumları
```sql
-- Son 10 teslimat
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  cancelled_by,
  created_at,
  accepted_at,
  rejected_at,
  cancelled_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 10;
```

### Kurye İstatistikleri
```sql
-- Kurye red/iptal sayıları
SELECT 
  id,
  full_name,
  role,
  is_available,
  penalty_until,
  rejection_count,
  cancellation_count,
  CASE 
    WHEN penalty_until > NOW() THEN 'Cezalı ⛔'
    WHEN is_available THEN 'Müsait ✅'
    ELSE 'Mesai Dışı 💤'
  END as durum
FROM users
WHERE role = 'courier'
ORDER BY rejection_count DESC, cancellation_count DESC;
```

### Bildirimler
```sql
-- Son 10 bildirim
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;
```

---

## ✅ BAŞARI KRİTERLERİ

### Test 1: KABUL ✅
- [x] Bildirim gelir
- [x] Status: assigned → accepted
- [x] Timeline güncellenir
- [x] Butonlar değişir (TOPLANDI + İPTAL)

### Test 2: RED ❌
- [x] Red dialog açılır
- [x] Status: assigned → pending
- [x] courier_id NULL olur
- [x] rejected_by dolu
- [x] rejection_count +1

### Test 3: KABUL SONRASI İPTAL ⚠️
- [x] Ceza dialog açılır
- [x] Status: accepted → cancelled
- [x] penalty_until +10 dakika
- [x] is_available = false
- [x] cancellation_count +1
- [x] 10 dakika yeni iş alamaz

### Test 4: PAKET ALINDIKTAN SONRA ⛔
- [x] İptal butonu görünmez
- [x] Sadece fotoğraf + teslim et

---

## 🐛 OLASI HATALAR & ÇÖZÜMLER

### Hata 1: "The method '_acceptDelivery' isn't defined"
```bash
# Çözüm: Flutter hot reload
r (terminal'de)
# veya
R (full restart)
```

### Hata 2: SQL kolonu yok
```sql
-- Çözüm: Migration tekrar çalıştır
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;
```

### Hata 3: Bildirim gelmiyor
```sql
-- Realtime kontrolü
SELECT * FROM pg_stat_subscription;

-- Realtime aktif mi?
ALTER TABLE delivery_requests REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_requests;
```

### Hata 4: Ceza kalkmiyor
```sql
-- Manuel ceza kaldır
UPDATE users 
SET 
  penalty_until = NULL,
  is_available = true
WHERE id = 'TEST_KURYE_ID';
```

---

## 🎯 TEST TAMAMLANDI!

Tüm testler başarılıysa:
✅ Kabul/Red sistemi çalışıyor
✅ Ceza mekanizması aktif
✅ Otomatik re-assign çalışıyor
✅ Bildirimler geliy
