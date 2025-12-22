# 🔥 FCM HTTP v1 API'ye Geçiş - Özet

## ❌ ESKİ YOL (ARTIK ÇALIŞMIYOR - DEPRECATED)

```typescript
// Legacy API (Kapandı!)
fetch('https://fcm.googleapis.com/fcm/send', {
  headers: {
    'Authorization': `key=${SERVER_KEY}`, // ❌ Artık çalışmıyor
  },
  body: JSON.stringify({
    to: fcm_token,
    notification: {...}
  })
})
```

**Neden çalışmıyor?**
- Google, Legacy Cloud Messaging API'yi **20 Haziran 2024**'te kapattı
- Artık **Server Key** yerine **Service Account JSON** kullanmalısın
- HTTP v1 API zorunlu!

---

## ✅ YENİ YOL (FCM HTTP v1 API)

### 1. Firebase Service Account JSON Al

**Adımlar:**
1. https://console.firebase.google.com/ aç
2. Proje: `onlog-dcb77` seç
3. ⚙️ **Project Settings** → **Service accounts**
4. **Generate new private key** → JSON dosyası indir

**JSON örneği:**
```json
{
  "type": "service_account",
  "project_id": "onlog-dcb77",
  "private_key_id": "abcd1234...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BA...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@onlog-dcb77.iam.gserviceaccount.com",
  "client_id": "1234567890",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

### 2. Edge Function Kodu (Yeni)

```typescript
// 1. OAuth2 Access Token al
const accessToken = await getAccessToken(serviceAccount)

// 2. FCM v1 API kullan
const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

fetch(fcmUrl, {
  headers: {
    'Authorization': `Bearer ${accessToken}`, // ✅ Bearer token
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: {
      token: fcm_token, // ✅ "to" değil "token"
      notification: {
        title: "...",
        body: "..."
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
        }
      }
    }
  })
})
```

### 3. Supabase Secrets Yapılandırması

**ESKİ:**
```powershell
supabase secrets set FCM_SERVER_KEY=AAAAxxxxxxx:APA91bF...
```

**YENİ:**
```powershell
# JSON dosyasını tek satıra çevir
$json = Get-Content "firebase-adminsdk.json" -Raw
$jsonMinified = $json -replace "`r`n", "" -replace "`n", ""

# Secret olarak ekle
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$jsonMinified"
```

---

## 🔑 API Farkları

| Özellik | Legacy API (❌ Eski) | HTTP v1 API (✅ Yeni) |
|---------|---------------------|----------------------|
| **Auth** | `key=SERVER_KEY` | `Bearer ACCESS_TOKEN` |
| **URL** | `fcm.googleapis.com/fcm/send` | `fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send` |
| **Token Field** | `to: "device_token"` | `message.token: "device_token"` |
| **Response** | `{ success: 1 }` | `{ name: "projects/..." }` |
| **Credential** | Server Key (string) | Service Account (JSON) |
| **OAuth** | Yok | OAuth2 JWT + Access Token |

---

## 🚀 Migration Checklist

- [x] ✅ Firebase Service Account JSON indir
- [x] ✅ Edge Function kodunu güncelle (OAuth2 + v1 API)
- [x] ✅ Supabase Secret'ı değiştir (`FIREBASE_SERVICE_ACCOUNT`)
- [ ] ⏳ Edge Function deploy et
- [ ] ⏳ Secret'ı ekle
- [ ] ⏳ Test et (yeni teslimat ata)

---

## 📝 Dosyalar

1. **`supabase/functions/send-fcm-notification/index.ts`** → Güncellendi (v1 API)
2. **`FCM_EDGE_FUNCTION_KURULUM.md`** → Güncellendi (Service Account talimatları)
3. **`SETUP_FCM_EDGE_FUNCTION_CRON.sql`** → Değişmedi (trigger aynı)

---

## ⚡ Hızlı Komutlar

```powershell
# 1. Login
cd C:\onlog_projects
supabase login

# 2. Deploy
supabase functions deploy send-fcm-notification

# 3. Secret Ekle (JSON dosyasını düzenle)
$json = Get-Content "C:\path\to\onlog-dcb77-firebase-adminsdk-xxxxx.json" -Raw
$jsonMinified = $json -replace "`r`n", "" -replace "`n", ""
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$jsonMinified"

# 4. Kontrol
supabase secrets list
```

---

## 🔍 Troubleshooting

### Hata: "FIREBASE_SERVICE_ACCOUNT bulunamadı"
```powershell
# Secret eksik, tekrar ekle
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content firebase.json -Raw)"
```

### Hata: "Invalid JWT signature"
- `private_key` içindeki `\n` karakterleri bozuk olabilir
- JSON dosyasını yeniden indir
- Tek satır JSON'a çevirirken `\n` karakterlerini koru

### Hata: "Permission denied"
- Service Account'un **Firebase Cloud Messaging API** yetkisi var mı?
- Firebase Console → IAM & Admin → Permissions kontrol et

---

## 🎉 Test

```sql
-- 1. Test teslimat oluştur
INSERT INTO delivery_requests (merchant_id, courier_id, declared_amount, status)
VALUES (
  'MERCHANT_ID',
  '4ff777e8-8e2f-4486-a49a-ffcae7ba1b40', -- TROLLOJI KURYE
  100.00,
  'assigned'
);

-- 2. Notification oluştu mu?
SELECT * FROM notifications WHERE notification_status = 'pending' ORDER BY created_at DESC;

-- 3. Bildirim gönderildi mi?
SELECT * FROM notifications WHERE notification_status = 'sent' ORDER BY sent_at DESC LIMIT 5;
```

**Beklenen sonuç:** Courier telefonuna push notification gelecek! 🚀

---

## 📚 Kaynaklar

- Firebase HTTP v1 API Docs: https://firebase.google.com/docs/cloud-messaging/migrate-v1
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- OAuth2 JWT: https://developers.google.com/identity/protocols/oauth2/service-account

---

**Hazır mısın? Firebase Service Account JSON'ını al ve deploy et!** 🔥
