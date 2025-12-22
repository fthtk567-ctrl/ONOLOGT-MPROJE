# 🔥 FIREBASE CLOUD MESSAGING (FCM) KURULUM REHBERİ

## ⚠️ ÖNEMLİ NOT
**Sadece FCM (Push Notification) kullanıyoruz!**
- ❌ Firebase Firestore KULLANMIYORUZ
- ❌ Firebase Auth KULLANMIYORUZ
- ❌ Firebase Storage KULLANMIYORUZ
- ✅ **Sadece FCM** - Arka plan bildirimleri için

**Database:** Supabase PostgreSQL  
**Auth:** Supabase Auth  
**Push:** Firebase Cloud Messaging (FCM)

---

## 📋 ADIM 1: Firebase Console'da Proje Oluştur

### 1.1 Firebase Console'a Git
https://console.firebase.google.com/

### 1.2 Yeni Proje Oluştur
1. "Add project" butonuna tıkla
2. Proje adı: **onlog-push** (veya istediğiniz ad)
3. Google Analytics: **Disable** (isteğe bağlı)
4. "Create project" tıkla

### 1.3 Android App Ekle
1. Sol menüden **Project Overview** → Ayarlar (⚙️)
2. **"Add app"** → Android simgesine tıkla
3. Form doldur:
   ```
   Android package name: com.example.onlog_courier_app
   App nickname: ONLOG Courier (opsiyonel)
   Debug signing certificate SHA-1: (şimdilik boş bırak)
   ```
4. **"Register app"** tıkla
5. **google-services.json** dosyasını indir
6. Dosyayı şuraya taşı:
   ```
   c:\onlog_projects\onlog_courier_app\android\app\google-services.json
   ```

### 1.4 iOS App Ekle (İsteğe bağlı)
1. **"Add app"** → iOS simgesine tıkla
2. Form doldur:
   ```
   iOS bundle ID: com.example.onlogCourierApp
   App nickname: ONLOG Courier iOS (opsiyonel)
   ```
3. **GoogleService-Info.plist** dosyasını indir
4. Dosyayı şuraya taşı:
   ```
   c:\onlog_projects\onlog_courier_app\ios\Runner\GoogleService-Info.plist
   ```

### 1.5 Web App Ekle (Merchant Panel için)
1. **"Add app"** → Web simgesine tıkla
2. Form doldur:
   ```
   App nickname: ONLOG Merchant Panel
   ```
3. Firebase SDK configuration'u kopyala (sonra kullanacağız)

---

## 📋 ADIM 2: FCM Server Key Al

### 2.1 Cloud Messaging Ayarları
1. Firebase Console → **Project Settings** (⚙️)
2. **Cloud Messaging** sekmesine git
3. **Server key** kopyala (örn: `AAAA...`)
4. Bu key'i şu dosyada güncelle:
   ```
   c:\onlog_projects\onlog_shared\lib\services\supabase_fcm_service.dart
   ```
   Satır 10:
   ```dart
   static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';
   ```

### 2.2 Sender ID
- **Sender ID** de not et (edge functions için gerekebilir)

---

## 📋 ADIM 3: Android Manifest Güncellemeleri

### 3.1 AndroidManifest.xml Düzenle
**Dosya:** `c:\onlog_projects\onlog_courier_app\android\app\src\main\AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.onlog_courier_app">

    <!-- Push Notification İzinleri -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>

    <application
        android:label="ONLOG Courier"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Firebase Cloud Messaging -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="new_order_channel" />
        
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- Arka plan bildirim servisi -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- ... diğer manifest içeriği ... -->
    </application>
</manifest>
```

### 3.2 build.gradle Güncellemeleri

**Dosya 1:** `c:\onlog_projects\onlog_courier_app\android\build.gradle`

```gradle
buildscript {
    dependencies {
        // ... mevcut dependencies ...
        classpath 'com.google.gms:google-services:4.4.0'  // EKLE
    }
}
```

**Dosya 2:** `c:\onlog_projects\onlog_courier_app\android\app\build.gradle`

En alta ekle:
```gradle
apply plugin: 'com.google.gms.google-services'  // EN ALTA EKLE
```

---

## 📋 ADIM 4: iOS Konfigürasyonu (Opsiyonel)

### 4.1 Xcode'da Capabilities Ekle
1. Xcode'da projeyi aç: `ios/Runner.xcworkspace`
2. **Runner** → **Signing & Capabilities** sekmesi
3. **"+ Capability"** tıkla
4. **"Push Notifications"** ekle
5. **"Background Modes"** ekle ve şunları işaretle:
   - ☑️ Background fetch
   - ☑️ Remote notifications

### 4.2 APNs Certificate (Production için)
1. Apple Developer Console → **Certificates, Identifiers & Profiles**
2. APNs certificate oluştur
3. Firebase Console'da **Cloud Messaging** → APNs certificate'i upload et

---

## 📋 ADIM 5: Supabase'de SQL Çalıştır

### 5.1 Supabase Dashboard'a Git
https://supabase.com/dashboard

### 5.2 SQL Çalıştır
1. Sol menüden **SQL Editor** sekmesine tıkla
2. **New query** butonu
3. Şu dosyayı aç ve tamamını kopyala:
   ```
   c:\onlog_projects\SQL_CREATE_FCM_TOKENS_TABLE.sql
   ```
4. SQL Editor'e yapıştır
5. **RUN** (F5) tıkla

### 5.3 Doğrula
SQL Editor'de çalıştır:
```sql
-- Tabloları kontrol et
SELECT tablename FROM pg_tables 
WHERE tablename IN ('user_fcm_tokens', 'notification_history');

-- Fonksiyonları kontrol et
SELECT routine_name FROM information_schema.routines
WHERE routine_name IN ('upsert_fcm_token', 'get_user_fcm_tokens', 'get_tokens_by_role');
```

---

## 📋 ADIM 6: FCM Server Key'i Güncelle

### 6.1 supabase_fcm_service.dart Düzenle
**Dosya:** `c:\onlog_projects\onlog_shared\lib\services\supabase_fcm_service.dart`

```dart
// Satır 10:
static const String _fcmServerKey = 'AAAA...'; // Firebase Console'dan aldığınız key
```

**GÜVENLİK:** Production'da bu key'i **environment variable** olarak kullanın!

---

## 📋 ADIM 7: Test

### 7.1 Courier App Test
```powershell
cd c:\onlog_projects\onlog_courier_app
flutter run
```

Login olduğunda:
- ✅ FCM token otomatik alınır
- ✅ Supabase'e kaydedilir
- ✅ Console'da "✅ FCM Token kaydedildi" görmelisiniz

### 7.2 Manuel Bildirim Test
Firebase Console → **Cloud Messaging** → **Send your first message**

1. Notification title: Test
2. Notification text: Test mesajı
3. Target: Single device
4. FCM registration token: (Supabase'den kopyala)
5. Send test message

---

## 🎯 SONRAKI ADIMLAR

1. ✅ Courier App'te FCM entegrasyonu tamamla
2. ✅ Merchant Panel'de web FCM ekle
3. ✅ Admin Panel'de bildirim gönderme UI
4. ✅ Supabase triggers ile otomatik bildirim

---

## 🚨 SORUN GİDERME

### Token Alınmıyor
- ✅ `google-services.json` doğru yerde mi?
- ✅ Gradle build başarılı mı?
- ✅ İnternet izni var mı?

### Bildirim Gelmiyor
- ✅ FCM Server Key doğru mu?
- ✅ Token Supabase'de kayıtlı mı?
- ✅ Cihaz online mı?

### iOS Bildirimi Yok
- ✅ APNs certificate eklenmiş mi?
- ✅ Capabilities açık mı?
- ✅ Physical device'da test edin (simulator çalışmaz)

---

## 📚 Referanslar

- Firebase Console: https://console.firebase.google.com/
- FCM Documentation: https://firebase.google.com/docs/cloud-messaging
- FlutterFire: https://firebase.flutter.dev/docs/messaging/overview
