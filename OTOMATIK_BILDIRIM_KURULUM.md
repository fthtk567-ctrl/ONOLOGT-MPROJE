# Otomatik Kurye Bildirim Sistemi Kurulum Rehberi

## Sistem Mimarisi
Merchant teslimat isteği oluşturduğunda → Database Webhook → Edge Function → FCM → Kurye Uygulaması

## 1. Firebase Service Account Key Al

### Adım 1: Firebase Console'a Git
1. https://console.firebase.google.com/ adresine git
2. **onlog-push** projesini seç

### Adım 2: Service Account Key Oluştur
1. Sol menüden **Project Settings** (⚙️ ikon) → **Service Accounts** sekmesi
2. **Generate New Private Key** butonuna tıkla
3. **Generate Key** ile onayla
4. İndirilen JSON dosyasını güvenli bir yerde sakla (örn: `firebase-service-account.json`)

### Adım 3: JSON İçeriğini Kopyala
Dosya içeriği şöyle görünecek:
```json
{
  "type": "service_account",
  "project_id": "onlog-push",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@onlog-push.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

## 2. Supabase Edge Function Deploy

### Adım 1: Supabase CLI Kur (Eğer yoksa)
```powershell
# Chocolatey ile
choco install supabase

# Veya Scoop ile
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Adım 2: Supabase Login
```powershell
supabase login
```

### Adım 3: Project ID Al
1. https://supabase.com/dashboard/project/_/settings/general
2. **Reference ID** değerini kopyala (örn: `abcdefghijklmnop`)

### Adım 4: Edge Function Secret Ekle
```powershell
# FIREBASE_SERVICE_ACCOUNT secret'ını ekle
supabase secrets set FIREBASE_SERVICE_ACCOUNT='<JSON_CONTENT>' --project-ref <PROJECT_ID>
```

**Önemli:** `<JSON_CONTENT>` yerine Firebase'den indirdiğin JSON dosyasının **tüm içeriğini** tek satırda yapıştır.

### Adım 5: Edge Function Deploy
```powershell
cd c:\onlog_projects
supabase functions deploy send-courier-notification --project-ref <PROJECT_ID>
```

## 3. Database Webhook Kur

### Basit Alternatif: Supabase Database Webhooks (Önerilen)

1. **Supabase Dashboard** → **Database** → **Webhooks**
2. **Create a new hook** butonuna tıkla
3. Webhook ayarlarını yapılandır:
   - **Name:** `notify-courier-on-assignment`
   - **Table:** `orders`
   - **Events:** `INSERT`, `UPDATE`
   - **Type of hook:** `HTTP Request`
   - **HTTP Method:** `POST`
   - **URL:** `https://<YOUR_PROJECT>.supabase.co/functions/v1/send-courier-notification`
   - **HTTP Headers:**
     ```
     Authorization: Bearer <YOUR_SUPABASE_ANON_KEY>
     Content-Type: application/json
     ```
   - **Conditions (Filters):**
     ```sql
     courier_id IS NOT NULL
     ```

4. **Enable webhook** ve **Create webhook**

### Gelişmiş Alternatif: PostgreSQL Trigger (pg_net ile)

Eğer webhook çalışmazsa `SQL_COURIER_NOTIFICATION_TRIGGER.sql` dosyasını kullan:

```powershell
# Supabase Dashboard > SQL Editor'de çalıştır
```

**Gerekli Extension:**
```sql
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
```

**Gerekli Settings (Database settings):**
- `app.settings.supabase_url` = `https://YOUR_PROJECT.supabase.co`
- `app.settings.supabase_service_role_key` = `YOUR_SERVICE_ROLE_KEY`

## 4. Merchant Panel'e Webhook Çağrısı Ekle (İsteğe Bağlı)

Eğer database trigger çalışmazsa, merchant panel'den manuel olarak Edge Function çağırabilirsin:

```dart
// onlog_merchant_panel/lib/services/order_service.dart içinde
Future<void> notifyCourierAboutNewOrder(String orderId, String courierId) async {
  try {
    final response = await SupabaseService.client.functions.invoke(
      'send-courier-notification',
      body: {
        'orderId': orderId,
        'courierId': courierId,
        'merchantName': 'Merchant Name', // Current user'dan al
        'deliveryAddress': 'Delivery Address',
        'deliveryFee': 25.0,
      },
    );
    print('✅ Kurye bildirimi gönderildi: ${response.data}');
  } catch (e) {
    print('❌ Kurye bildirimi hatası: $e');
  }
}

// Sipariş oluşturulduktan sonra çağır:
// await notifyCourierAboutNewOrder(newOrder.id, assignedCourierId);
```

## 5. Test Senaryosu

### Test 1: Manuel Edge Function Çağrısı
```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/send-courier-notification' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "test-order-123",
    "courierId": "250f4abe-858a-457b-b972-9a76340b07c2",
    "merchantName": "Test Merchant",
    "deliveryAddress": "Test Address",
    "deliveryFee": 25
  }'
```

### Test 2: Merchant Panel'den Teslimat İsteği Oluştur
1. Merchant panel'i aç
2. **Yeni Teslimat** butonuna tıkla
3. Kurye seç (courier@onlog.com - 250f4abe-858a-457b-b972-9a76340b07c2)
4. Teslimat detaylarını doldur
5. **Oluştur** butonuna bas
6. Kurye uygulamasında (arka planda açık) bildirim geldiğini kontrol et

### Test 3: Database'den Manuel Trigger
```sql
-- Supabase SQL Editor'de
UPDATE orders 
SET courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
WHERE id = 'existing-order-id';
```

## 6. Hata Ayıklama

### Edge Function Logları
```powershell
supabase functions logs send-courier-notification --project-ref <PROJECT_ID>
```

### Supabase Dashboard Logları
1. **Supabase Dashboard** → **Logs** → **Edge Functions**
2. `send-courier-notification` fonksiyonunu seç
3. Son çağrıları ve hataları görüntüle

### Common Issues

**1. FCM Token Bulunamadı**
- Çözüm: Kurye uygulamasında login/logout yap, token'ı yeniden kaydet

**2. FIREBASE_SERVICE_ACCOUNT Bulunamadı**
- Çözüm: `supabase secrets list --project-ref <PROJECT_ID>` ile kontrol et
- Eksikse tekrar `supabase secrets set` komutunu çalıştır

**3. Webhook Tetiklenmiyor**
- Çözüm: Webhook'u Supabase Dashboard'da kontrol et (Database → Webhooks)
- Status: **active** olmalı
- Conditions'u doğrula

**4. Access Token Alınamıyor**
- Çözüm: Firebase Service Account JSON'ının `private_key` alanını kontrol et
- Satır sonları `\n` olarak korunmalı

## 7. Production Checklist

✅ Firebase Service Account key güvenli bir yerde saklandı  
✅ Supabase secrets yapılandırıldı  
✅ Edge Function deploy edildi  
✅ Database webhook/trigger kuruldu  
✅ Test bildirimi başarıyla alındı  
✅ Merchant panel entegrasyonu tamamlandı  
✅ Error handling ve logging eklendi  
✅ Rate limiting yapılandırıldı (opsiyonel)

## Sonuç

Sistem şu şekilde çalışacak:
1. Merchant teslimat isteği oluşturur
2. `orders` tablosuna `courier_id` atanır
3. Database webhook/trigger Edge Function'ı tetikler
4. Edge Function kurye FCM token'ını alır
5. Firebase OAuth2 token alır
6. FCM V1 API ile bildirim gönderir
7. Kurye uygulaması bildirim alır (arka planda bile)
8. `notification_history` tablosuna kayıt eklenir
