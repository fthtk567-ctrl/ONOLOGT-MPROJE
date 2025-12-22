# 🚀 SUPABASE EDGE FUNCTION - FCM PUSH NOTIFICATION KURULUM

## 📋 ÖNCELİKLER

### 1. Firebase Service Account JSON Al (YENİ API - ZORUNLU!)

**Legacy API kapandı! Artık Service Account kullanmalısın:**

1. Firebase Console aç: https://console.firebase.google.com/
2. Projen'i seç: `onlog-dcb77` (veya kullandığın proje)
3. ⚙️ **Project Settings** → **Service accounts** tab
4. **Generate new private key** butonu → **Generate key**
5. JSON dosyası inecek (örn: `onlog-dcb77-firebase-adminsdk-xxxxx.json`)

**JSON içeriği şuna benzer:**
```json
{
  "type": "service_account",
  "project_id": "onlog-dcb77",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIB...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@onlog-dcb77.iam.gserviceaccount.com",
  "client_id": "xxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

**⚠️ ÖNEMLİ:** Bu dosyayı GÜVENLİ SAKLA! Sızarsa proje hacklenebilir!

### 2. Supabase CLI Yükle (PowerShell)
```powershell
# Chocolatey ile (önerilir)
choco install supabase

# Manuel indirme
# https://github.com/supabase/cli/releases
# supabase_windows_amd64.exe → supabase.exe yap ve PATH'e ekle
```

---

## 🔧 KURULUM ADIMLARI

### ADIM 1: Edge Function Deploy Et

```powershell
# Proje dizinine git
cd C:\onlog_projects

# Supabase login
supabase login

# Edge Function deploy
supabase functions deploy send-fcm-notification
```

### ADIM 2: Firebase Service Account JSON'ı Supabase Secret'a Ekle

**YENİ YOL (FCM HTTP v1 API):**

```powershell
# Service Account JSON'ın tamamını tek satır yap (newline'ları \\n yap)
# PowerShell'de:

$json = Get-Content "C:\path\to\onlog-dcb77-firebase-adminsdk-xxxxx.json" -Raw
$jsonMinified = $json -replace "`r`n", "" -replace "`n", ""

# Supabase secret'a ekle (tek satır JSON)
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$jsonMinified"
```

**Alternatif (Manuel):**

JSON dosyasını aç, tüm içeriği kopyala ve tek satıra çevir:

```powershell
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"onlog-dcb77",...}'
```

**⚠️ DIKKAT:** JSON'daki `\n` karakterleri `\\n` olarak escape edilmeli!

### ADIM 3: Secrets Kontrol

```powershell
# Tüm secrets'ı listele
supabase secrets list
```

Çıktı şöyle olmalı:
```
NAME                      | VALUE (truncated)
--------------------------|---------------------------
FIREBASE_SERVICE_ACCOUNT  | {"type":"service_account"...
```

---

## 📡 TRİGGER KURULUMU (Otomatik Bildirim Gönderimi)

### OPSİYON 1: Her Yeni Notification'da Tetikle (ÖNERİLİR) ✅

```sql
-- SETUP_FCM_EDGE_FUNCTION_CRON.sql dosyasını aç
-- Supabase Dashboard → SQL Editor'a yapıştır

-- ÖNEMLİ: Aşağıdaki satırı düzenle:
url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-fcm-notification',

-- YOUR_PROJECT_REF yerine kendi project ref'ini yaz
-- Supabase Dashboard URL'inden bul:
-- https://app.supabase.com/project/YOUR_PROJECT_REF/...

-- Örnek:
url := 'https://abcdefgh12345678.supabase.co/functions/v1/send-fcm-notification',
```

**SQL'i çalıştır!**

### OPSİYON 2: Manuel Test (Hemen Dene)

Supabase Dashboard → SQL Editor'da:

```sql
SELECT
  net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-fcm-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'::jsonb
  ) as request_id;
```

**ÖNEMLİ:**
- `YOUR_PROJECT_REF` → Kendi project ref'in
- `YOUR_SERVICE_ROLE_KEY` → Supabase Dashboard → Settings → API → `service_role` key

---

## ✅ TEST

### Test 1: Yeni Teslimat Ata

```sql
-- Kuryeye teslimat ata
UPDATE delivery_requests
SET courier_id = '4ff777e8-8e2f-4486-a49a-ffcae7ba1b40' -- TROLLOJI KURYE
WHERE id = 'TEST_DELIVERY_ID';
```

### Test 2: Notifications Kontrol

```sql
-- Pending olanlar
SELECT * FROM notifications WHERE notification_status = 'pending';

-- Gönderilmiş olanlar
SELECT * FROM notifications WHERE notification_status = 'sent' ORDER BY sent_at DESC;

-- Hata alanlar
SELECT * FROM notifications WHERE notification_status = 'failed';
```

### Test 3: Edge Function Logları

Supabase Dashboard → **Edge Functions** → **send-fcm-notification** → **Logs**

Burada:
- ✅ **Success (200)** - Bildirim gönderildi
- ❌ **Error** - Hata detaylarını göster

---

## 🔍 SORUN GİDERME

### Hata: "FIREBASE_SERVICE_ACCOUNT bulunamadı"
**Çözüm:**
```powershell
# Service Account JSON'ı secret olarak ekle
$json = Get-Content "path\to\firebase-adminsdk.json" -Raw
$jsonMinified = $json -replace "`r`n", "" -replace "`n", ""
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$jsonMinified"
```

### Hata: "Invalid FCM token"
**Çözüm:**
- Courier App'te FCM token yeniden kaydet
- `users` tablosunda `fcm_token` NULL olabilir
- Courier App'i aç, login ol, token otomatik kaydedilir

### Hata: "Unauthorized" veya "Invalid JWT"
**Çözüm:**
- `YOUR_SERVICE_ROLE_KEY` yanlış → Supabase Dashboard → Settings → API → `service_role` key kopyala
- Firebase Service Account JSON hatalı → JSON dosyasını yeniden indir
- `private_key` içindeki `\n` karakterleri bozuk olabilir

### Bildirim Gelmiyor
**Kontrol:**
1. Courier App arka planda mı? (Background handler çalışıyor mu)
2. FCM token güncel mi?
```sql
SELECT fcm_token FROM users WHERE id = '4ff777e8-8e2f-4486-a49a-ffcae7ba1b40';
```
3. Notification `sent` olmuş mu?
```sql
SELECT * FROM notifications WHERE user_id = '4ff777e8-8e2f-4486-a49a-ffcae7ba1b40' ORDER BY created_at DESC;
```

---

## 📊 SİSTEM AKIŞI

```
1. Merchant yeni teslimat oluşturur
   ↓
2. Courier atanır (courier_id set edilir)
   ↓
3. PostgreSQL Trigger tetiklenir: notify_courier_new_delivery()
   ↓
4. send_courier_notification() çalışır
   ↓
5. notifications tablosuna INSERT (status = 'pending')
   ↓
6. trigger_call_fcm_edge_function() tetiklenir
   ↓
7. Supabase Edge Function çağrılır: send-fcm-notification
   ↓
8. Edge Function pending bildirimleri okur
   ↓
9. FCM API'ye POST request: https://fcm.googleapis.com/fcm/send
   ↓
10. FCM cihaza push notification gönderir
   ↓
11. notifications.notification_status = 'sent' güncellenir
   ↓
12. Courier telefonuna bildirim gelir! 🎉
```

---

## 🎯 HIZLI BAŞLANGIÇ

1. **Firebase Service Account JSON Al** (Legacy API artık çalışmıyor!)
   - Firebase Console → Project Settings → Service accounts → Generate new private key
   - JSON dosyasını indir

2. **Edge Function Deploy:**
   ```powershell
   cd C:\onlog_projects
   supabase login
   supabase functions deploy send-fcm-notification
   
   # Service Account JSON'ı secret'a ekle
   $json = Get-Content "C:\path\to\firebase-adminsdk.json" -Raw
   $jsonMinified = $json -replace "`r`n", "" -replace "`n", ""
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$jsonMinified"
   ```

3. **SQL Trigger Kur:**
   - `SETUP_FCM_EDGE_FUNCTION_CRON.sql` aç
   - `YOUR_PROJECT_REF` düzenle
   - Supabase SQL Editor'da çalıştır

4. **Test Et:**
   - Yeni teslimat ata
   - Courier telefonuna bildirim geldi mi kontrol et

---

## 📞 DESTEK

Hata alırsan:
1. Edge Function loglarına bak (Supabase Dashboard)
2. `notifications` tablosunda `error_message` kolonuna bak
3. `notification_status = 'failed'` olanları kontrol et

**Başarılı kurulum sonrası:**
- ✅ Yeni teslimat atandığında courier'a anında bildirim gelir
- ✅ Arka planda bile bildirim gelir
- ✅ Otomatik retry yoktur (şimdilik tek seferlik)

**İletişim:** Discord/Telegram'dan bana ulaş!
