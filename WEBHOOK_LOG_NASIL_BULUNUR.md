# Webhook Logları Nasıl Bulunur?

## 🎯 Problem
Supabase Dashboard'da Edge Functions loglarına bakıyorsun ama webhook mesajlarını bulamıyorsun.

## ✅ Çözüm

### Adım 1: Database Logs'a Git
1. Supabase Dashboard'da **sol menüden** şu sırayla git:
   - **Logs & Analytics** (soldaki menüde)
   - **Database** sekmesine tıkla (**NOT: Edge Functions değil!**)

### Adım 2: Filtreleri Ayarla
1. **Sağ üstteki zaman filtresi**: "Last hour" (Son 1 saat)
2. **SQL sorgu kutusuna** şunu yaz:
   ```sql
   select * from postgres_logs
   where event_message ilike '%webhook%'
      or event_message ilike '%YO-794063%'
   order by timestamp desc
   limit 50
   ```

### Adım 3: Beklenen Sonuçlar

#### Senaryo 1: Sipariş Hala "pending" veya "assigned" Status'unda
```
[Webhook] Skipping webhook for status: pending
```
veya
```
[Webhook] Skipping webhook for status: assigned
```
**Açıklama**: Webhook henüz gönderilmedi çünkü kurye henüz kabul etmedi.

#### Senaryo 2: Kurye Kabul Etti ("accepted" status)
```
[Webhook] Sending webhook for delivery: <UUID>
[Webhook] External order: YO-794063
[Webhook] Payload: {"delivery_id": "...", "status": "accepted", ...}
[Webhook] Webhook sent successfully
```
veya
```
[Webhook] Webhook failed: <hata mesajı>
```

## 🔍 Alternatif: PostgreSQL Logs Panelinde Ara

Eğer yukarıdaki SQL çalışmazsa:

1. **Database** sekmesinde
2. **Sol üstteki arama kutusuna** sadece şunu yaz:
   ```
   webhook
   ```
3. Enter'a bas
4. Zaman filtresini **Last 1 hour** yap

## 📋 Hızlı Durum Kontrolü

Eğer log bulamazsan, siparişin mevcut durumunu kontrol et:

### SQL Editor'de Çalıştır:
```sql
SELECT 
  external_order_id,
  order_number,
  status,
  courier_id,
  rejection_count,
  updated_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063';
```

**Sonuç yorumlama:**
- `status = 'pending'` → Webhook GİTMEDİ (normal)
- `status = 'assigned'` → Webhook GİTMEDİ (normal, kurye henüz kabul etmedi)
- `status = 'accepted'` → Webhook GİTMELİ (log'da olmalı)
- `status = 'delivered'` → Webhook GİTMELİ (log'da olmalı)

## 🧪 Manuel Test İçin

Eğer webhook'u zorla test etmek istersen:

```sql
-- Kurye ID'si al
SELECT id, full_name 
FROM users 
WHERE role = 'courier' 
LIMIT 1;

-- Status'u 'accepted' yap
UPDATE delivery_requests
SET 
  status = 'accepted',
  courier_id = 'YUKARDAKI_COURIER_ID_BURAYA'
WHERE external_order_id = 'YO-794063';
```

Sonra **5-10 saniye bekle** ve Database loglarına tekrar bak.

## ❓ Hala Bulamıyorsan

1. **Ekran görüntüsü at**: Database logs sekmesinde ne görüyorsun?
2. **SQL sonucunu at**: Yukarıdaki SELECT sorgusunun sonucu ne?
3. **Trigger kontrolü yap**:
   ```sql
   SELECT trigger_name, event_object_table, action_statement
   FROM information_schema.triggers
   WHERE trigger_name = 'trigger_notify_platform_on_status_change';
   ```

Trigger varsa ve status 'accepted'/'delivered' ise log olmalı!
