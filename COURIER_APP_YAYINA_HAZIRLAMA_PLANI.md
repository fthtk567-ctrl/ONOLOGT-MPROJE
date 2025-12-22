# 🚀 COURIER APP YAYINA HAZIRLAMA PLANI

## 📅 Tarih: 2 Kasım 2025

---

## ✅ 1. MEVCUT ÖZELLIKLER ANALİZİ

### 🎯 Temel Özellikler
- ✅ **Kullanıcı Girişi**: Supabase Auth ile email/password
- ✅ **Profil Yönetimi**: Tam özellikli (fotoğraf, kişisel bilgi, banka, araç)
- ✅ **Teslimat Sistemi**: delivery_requests tablosu ile çalışıyor
- ✅ **Konum Takibi**: Google Maps + GPS (30 saniyede bir güncelleme)
- ✅ **Push Bildirimleri**: Firebase Cloud Messaging entegre
- ✅ **QR Kod Doğrulama**: Teslimat onay sistemi
- ✅ **Kazanç Takibi**: Supabase'den gerçek zamanlı
- ✅ **Performans**: İstatistikler ve grafikler
- ✅ **Yardım & Destek**: Telefon/Email/WhatsApp entegrasyonu
- ✅ **Offline Destek**: Hive ile local cache

### 🔧 Teknik Altyapı
- **Flutter SDK**: ^3.9.2
- **Supabase**: Backend + Auth + Realtime
- **Firebase**: Sadece FCM (Cloud Messaging)
- **Hive**: Local storage
- **Google Maps**: Harita görüntüleme
- **Geolocator**: GPS konumu

### 📱 Desteklenen Platformlar
- ✅ Android (minSdk 21, targetSdk 34)
- ✅ iOS (deployment target: 12.0)

---

## 🔴 2. SORUNLAR VE EKSİKLER

### 🚨 KRİTİK SORUNLAR

#### A. Build Yapılandırması
- ❌ **Release build signing config YOK!**
  - `build.gradle.kts`: Debug key ile sign ediliyor
  - Keystore dosyası yok
  - Production için signing config gerekli

#### B. App Kimlik Bilgileri
- ⚠️ **Paket Adı**: `com.onlog.onlog_courier_app` (OK)
- ⚠️ **Uygulama Adı**: "Onlog Kurye" (AndroidManifest.xml)
- ❌ **Uygulama İkonu**: Sadece Android (iOS eksik)
- ❌ **Splash Screen**: Yok

#### C. API Anahtarları
- ⚠️ **Google Maps API Key**: Manifest'te hardcoded (güvenlik riski)
- ⚠️ **Firebase Config**: google-services.json var ama iOS'ta GoogleService-Info.plist?
- ⚠️ **Supabase Keys**: Kodda hardcoded (onlog_shared/config)

#### D. İzinler ve Güvenlik
- ✅ Android manifest izinleri tamam
- ❌ iOS Info.plist eksik (konum izinleri, bildirim açıklamaları)
- ❌ Privacy Policy linki eksik (zorunlu)
- ❌ Terms of Service linki eksik (zorunlu)

#### E. Veritabanı Senkronizasyonu
- ⚠️ **Teslimat Sayısı**: Manuel SQL ile güncellendi (otomatik trigger eksik)
- ⚠️ **Status uyumsuzluğu**: Küçük/büyük harf karışıklığı ('delivered' vs 'DELIVERED')

---

## 🎯 3. YAYINA HAZIRLIK ADIMLARI

### 📦 ADIM 1: Android Release Build Hazırlığı

#### 1.1 Keystore Oluştur
```powershell
# Android Studio > Build > Generate Signed Bundle/APK
# Veya komut satırı:
keytool -genkey -v -keystore C:\onlog_projects\onlog_courier_app\android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Bilgileri güvenli yere kaydet:
# - Keystore şifresi
# - Alias adı: upload
# - Key şifresi
```

#### 1.2 key.properties Oluştur
```properties
# Dosya: android/key.properties
storePassword=<keystore_sifresi>
keyPassword=<key_sifresi>
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 1.3 build.gradle.kts Güncelle
```kotlin
// Signing config ekle
signingConfigs {
    create("release") {
        val keystorePropertiesFile = rootProject.file("key.properties")
        val keystoreProperties = Properties()
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        minifyEnabled = true
        shrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

---

### 📱 ADIM 2: iOS Hazırlığı

#### 2.1 GoogleService-Info.plist Ekle
```bash
# Firebase Console'dan indir ve ekle:
# ios/Runner/GoogleService-Info.plist
```

#### 2.2 Info.plist Güncelle
```xml
<!-- ios/Runner/Info.plist -->

<!-- Konum İzinleri -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Teslimat yaparken konumunuzu görmek için gereklidir.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Arka planda konumunuzu takip edebilmemiz için izin verin.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Müşterilere gerçek zamanlı konum bilgisi sağlamak için gereklidir.</string>

<!-- Bildirim İzni -->
<key>NSUserTrackingUsageDescription</key>
<string>Size özel sipariş bildirimleri göndermek için gereklidir.</string>

<!-- Kamera İzni (Fotoğraf çekmek için) -->
<key>NSCameraUsageDescription</key>
<string>Teslimat fotoğrafı çekmek için kamera erişimi gereklidir.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Teslimat fotoğrafı yüklemek için galeri erişimi gereklidir.</string>
```

#### 2.3 App Icon ve Launch Screen
```bash
# flutter_launcher_icons ile otomatik oluştur
flutter pub run flutter_launcher_icons
```

---

### 🔒 ADIM 3: Güvenlik ve Gizlilik

#### 3.1 API Keys Güvenliği
```dart
// .env dosyası oluştur (pubspec.yaml'a flutter_dotenv ekle)
GOOGLE_MAPS_API_KEY=AIzaSyBCU7J0J3KjMCZ5Ne0XJmZ0hpG16PknCq8
SUPABASE_URL=https://piqhfygnbfaxvxbzqjkm.supabase.co
SUPABASE_ANON_KEY=eyJhbG...

// .gitignore'a ekle:
.env
android/key.properties
android/app/upload-keystore.jks
ios/Runner/GoogleService-Info.plist
```

#### 3.2 Privacy Policy ve Terms
```dart
// lib/screens/legal_screens.dart oluştur
// https://app-privacy-policy-generator.firebaseapp.com/ kullan

// Linkler:
// - Gizlilik Politikası: https://onlog.com.tr/privacy-policy
// - Kullanım Şartları: https://onlog.com.tr/terms-of-service
```

---

### 🎨 ADIM 4: UI/UX İyileştirmeleri

#### 4.1 Splash Screen (Önerilen)
```yaml
# pubspec.yaml
dependencies:
  flutter_native_splash: ^2.3.5

flutter_native_splash:
  color: "#4CAF50"
  image: assets/images/splash_logo.png
  android: true
  ios: true
```

#### 4.2 App Icon Güncellemesi
```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#4CAF50"
  adaptive_icon_foreground: "assets/images/app_icon_adaptive.png"
```

---

### 🗄️ ADIM 5: Database Düzeltmeleri

#### 5.1 Otomatik Teslimat Sayısı Trigger
```sql
-- Supabase Dashboard > SQL Editor

CREATE OR REPLACE FUNCTION update_courier_delivery_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Status 'delivered' olduğunda sayacı artır
  IF LOWER(NEW.status) = 'delivered' AND LOWER(COALESCE(OLD.status, '')) != 'delivered' THEN
    UPDATE users 
    SET total_deliveries = total_deliveries + 1
    WHERE id = NEW.courier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_update_delivery_count ON delivery_requests;
CREATE TRIGGER trigger_update_delivery_count
AFTER UPDATE ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION update_courier_delivery_count();
```

#### 5.2 Status Standartizasyonu
```sql
-- Tüm status değerlerini küçük harfe çevir
UPDATE delivery_requests 
SET status = LOWER(status);

-- users tablosundaki status'ları da kontrol et
UPDATE users 
SET availability_status = LOWER(availability_status)
WHERE role = 'courier';
```

---

### 📋 ADIM 6: Google Play Console Hazırlığı

#### 6.1 Gerekli Materyaller
- [ ] **App Icon** (512x512 PNG)
- [ ] **Feature Graphic** (1024x500 PNG)
- [ ] **Screenshots** (En az 2 adet, önerilen 4-8 adet)
  - Ana ekran
  - Teslimat listesi
  - Harita görünümü
  - Profil ekranı
  - Kazanç ekranı
- [ ] **Short Description** (80 karakter)
  ```
  ONLOG Kurye - Teslimat yapın, kazancınızı takip edin!
  ```
- [ ] **Full Description** (4000 karakter - aşağıda hazır)
- [ ] **Privacy Policy URL**
- [ ] **Developer Contact** (Email, telefon, adres)

#### 6.2 Uygulama Açıklaması (TR)
```
📦 ONLOG Kurye Uygulaması

ONLOG Kurye uygulaması ile teslimat işlerinizi kolayca yönetin ve kazancınızı artırın!

✨ ÖZELLİKLER:

🚀 Hızlı Teslimat Yönetimi
• Yeni teslimat isteklerini anında görün
• Tek dokunuşla teslimatları kabul edin
• GPS ile optimum rota desteği

📍 Gerçek Zamanlı Takip
• Müşterilere anlık konum bilgisi
• Harita üzerinde teslimat noktaları
• Mesafe ve süre hesaplama

💰 Gelir Takibi
• Günlük/haftalık/aylık kazanç raporları
• Tüm ödemelerin detaylı geçmişi
• Banka hesabınıza otomatik ödeme

📊 Performans İstatistikleri
• Tamamlanan teslimat sayısı
• Ortalama teslimat süresi
• Müşteri memnuniyet puanı

🔔 Akıllı Bildirimler
• Yeni teslimat bildirimleri
• Ödeme bildirimleri
• Sistem güncellemeleri

🛡️ Güvenli ve Kolay
• QR kod ile teslimat doğrulama
• Fotoğraflı teslimat kanıtı
• 7/24 müşteri desteği

📱 Kullanıcı Dostu Arayüz
• Modern ve temiz tasarım
• Kolay navigasyon
• Türkçe dil desteği

NEDEN ONLOG?
• Şeffaf kazanç sistemi
• Esnek çalışma saatleri
• Hızlı ödeme
• Profesyonel destek ekibi

Hemen indirin, kurye olun ve kazanmaya başlayın!

📞 Destek: +90 537 429 1076
📧 E-posta: destek@onlog.com.tr
🌐 Web: www.onlog.com.tr

#kurye #teslimat #kazanç #onlog
```

#### 6.3 Content Rating (İçerik Derecelendirmesi)
- **Kategori**: Business / Productivity
- **Yaş**: 3+ (herkes için uygun)
- **İçerik**: Reklam yok, uygulama içi satın alma yok

#### 6.4 Store Listing
```
App Name: ONLOG Kurye
Developer Name: ONLOG Teknoloji
Email: destek@onlog.com.tr
Website: https://onlog.com.tr
Privacy Policy: https://onlog.com.tr/privacy-policy
Category: Business > Productivity
```

---

### 🍎 ADIM 7: App Store Connect Hazırlığı

#### 7.1 Gerekli Materyaller
- [ ] **App Icon** (1024x1024 PNG)
- [ ] **Screenshots** 
  - iPhone 6.5" (1284x2778) - 3 adet minimum
  - iPhone 5.5" (1242x2208) - 3 adet minimum
- [ ] **App Preview Video** (Opsiyonel ama önerilen)
- [ ] **Keywords** (100 karakter)
  ```
  kurye,teslimat,kazanç,sipariş,para,iş,çalış,delivery,courier
  ```
- [ ] **Promotional Text** (170 karakter)
  ```
  🎉 Yeni özellik! Profil fotoğrafı yükleme ve gelişmiş kazanç raporları. Hemen güncelleyin!
  ```

#### 7.2 App Store Açıklama (TR)
```
ONLOG Kurye - Teslimat Yap, Kazan!

ONLOG Kurye uygulaması ile teslimat işlerinizi profesyonel şekilde yönetin.

ÖZELLİKLER:
• Gerçek zamanlı teslimat takibi
• Otomatik ödeme sistemi
• QR kod doğrulama
• Detaylı kazanç raporları
• 7/24 destek

Kurye olmak hiç bu kadar kolay olmamıştı!

İletişim: destek@onlog.com.tr
```

---

### 🧪 ADIM 8: Test Checklist

#### 8.1 Fonksiyonel Testler
- [ ] Giriş/Çıkış işlemleri
- [ ] Teslimat kabul/red sistemi
- [ ] GPS konumu güncelleme
- [ ] QR kod tarama
- [ ] Fotoğraf yükleme
- [ ] Profil düzenleme
- [ ] Kazanç görüntüleme
- [ ] Push bildirimleri
- [ ] Offline çalışma
- [ ] Harita görünümü

#### 8.2 Performans Testleri
- [ ] Uygulama başlatma süresi (< 3 saniye)
- [ ] Harita yükleme süresi
- [ ] Veri senkronizasyonu
- [ ] Bellek kullanımı
- [ ] Batarya tüketimi

#### 8.3 Cihaz Testleri
- [ ] Android 7.0 (minSdk 21)
- [ ] Android 14 (targetSdk 34)
- [ ] Farklı ekran boyutları
- [ ] Tablet desteği
- [ ] iOS 12.0+
- [ ] iPhone SE, iPhone 14 Pro Max

---

### 📦 ADIM 9: Build Oluşturma

#### 9.1 Android (AAB)
```powershell
# Workspace'e git
cd C:\onlog_projects\onlog_courier_app

# Dependencies güncelle
flutter pub get

# Clean build
flutter clean

# Release AAB oluştur
flutter build appbundle --release

# Çıktı:
# build/app/outputs/bundle/release/app-release.aab
```

#### 9.2 Android (APK - Test için)
```powershell
flutter build apk --release --split-per-abi

# Çıktılar:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

#### 9.3 iOS (IPA)
```bash
# Xcode ile aç
open ios/Runner.xcworkspace

# Archive ve Export (Xcode'da manuel)
# Veya komut satırı:
flutter build ios --release
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release archive \
  -archivePath build/Runner.xcarchive
  
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/Release
```

---

### 🚀 ADIM 10: Yükleme ve Yayınlama

#### 10.1 Google Play Console
1. https://play.google.com/console/ giriş yap
2. "Create app" tıkla
3. App details doldur (ad, açıklama, kategori)
4. Materyalleri yükle (icon, screenshots, graphic)
5. AAB dosyasını yükle
6. Content rating yap
7. Target audience seç (18+)
8. Privacy policy URL ekle
9. "Submit for review" tıkla
10. **İnceleme süresi**: 1-7 gün

#### 10.2 App Store Connect
1. https://appstoreconnect.apple.com/ giriş yap
2. "My Apps" > "+" > "New App"
3. Bundle ID seç (com.onlog.onlog_courier_app)
4. App information doldur
5. Screenshots ve materyalleri yükle
6. Xcode'dan IPA yükle (Archive > Distribute App)
7. "Submit for Review" tıkla
8. **İnceleme süresi**: 1-3 gün

---

## 📊 ÖNCELIK SIRASI

### 🔴 KRİTİK (Önce Yapılmalı)
1. ✅ Android Keystore oluştur
2. ✅ build.gradle.kts signing config ekle
3. ✅ Privacy Policy ve Terms sayfaları hazırla
4. ✅ iOS Info.plist izinleri ekle
5. ✅ Database trigger'ları ekle (otomatik teslimat sayısı)

### 🟡 ÖNEMLİ (Kısa Sürede)
6. ✅ App icon ve splash screen optimize et
7. ✅ Screenshots çek (8 adet - Android + iOS)
8. ✅ Store açıklamaları yaz (TR + EN)
9. ✅ API keys güvenliği (.env dosyası)
10. ✅ Test cihazlarda deneme

### 🟢 İSTEĞE BAĞLI (İyileştirmeler)
11. ⚠️ App preview video çek
12. ⚠️ Tablet layout optimize et
13. ⚠️ Çoklu dil desteği (EN)
14. ⚠️ Analytics entegre et (Firebase Analytics)
15. ⚠️ Crash reporting (Firebase Crashlytics)

---

## 🎯 ZAMAN ÇİZELGESİ

### Gün 1-2: Hazırlık
- [ ] Keystore oluştur
- [ ] Privacy policy hazırla
- [ ] Build config güncelle
- [ ] iOS izinleri ekle

### Gün 3-4: Test
- [ ] Test cihazlarda deneme
- [ ] Bug fix
- [ ] Screenshots çek
- [ ] Açıklamaları yaz

### Gün 5: Build ve Yükleme
- [ ] Release AAB oluştur
- [ ] Release IPA oluştur
- [ ] Google Play'e yükle
- [ ] App Store'a yükle

### Gün 6-14: İnceleme Süreci
- [ ] Store review bekle
- [ ] Gerekirse düzeltmeler yap
- [ ] Yayına alındıktan sonra test et

---

## 📝 NOTLAR

### ⚠️ Dikkat Edilmesi Gerekenler
1. **Keystore dosyasını KAYBETMEYİN!** Yedekleyin!
2. **API Keys'i GitHub'a PUSHLEMAYIN!** (.gitignore kontrol)
3. **Privacy Policy zorunlu** (Supabase veri işleme bildirimi)
4. **iOS için Apple Developer hesabı gerekli** ($99/yıl)
5. **Google Play hesabı gerekli** ($25 tek seferlik)

### 📚 Yararlı Linkler
- Google Play Console: https://play.google.com/console/
- App Store Connect: https://appstoreconnect.apple.com/
- Privacy Policy Generator: https://app-privacy-policy-generator.firebaseapp.com/
- Screenshot Maker: https://appscreenshots.online/
- Icon Generator: https://icon.kitchen/

---

## ✅ TAMAMLANMA DURUMU

| Özellik | Android | iOS | Durum |
|---------|---------|-----|-------|
| Build Config | ❌ | ❌ | Signing config eksik |
| App Icon | ✅ | ❌ | iOS için lazım |
| Splash Screen | ❌ | ❌ | Opsiyonel |
| Privacy Policy | ❌ | ❌ | Hazırlanmalı |
| Store Assets | ❌ | ❌ | Screenshots lazım |
| Release Build | ❌ | ❌ | Keystore ile olacak |

---

## 🎉 SONRAKİ ADIM

**ŞİMDİ NE YAPALIM?**

1. **Önce Android Keystore oluşturalım mı?**
2. **Privacy Policy sayfasını hazırlayalım mı?**
3. **Screenshots çekip store materyallerini hazırlayalım mı?**

Hangi adımdan başlamak istersin? 🚀
