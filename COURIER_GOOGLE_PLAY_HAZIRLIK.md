# 🚀 COURIER APP - GOOGLE PLAY HAZIRLIK RAPORU

**Tarih:** 3 Kasım 2025  
**Durum:** ✅ Hazır (Keystore oluşturulması gerekiyor)

---

## ✅ TAMAMLANAN İŞLEMLER

### 1️⃣ **Keystore Konfigürasyonu**
- ✅ `key.properties` oluşturuldu
- ✅ `build.gradle.kts` release signing config eklendi
- ✅ `.gitignore` keystore'u koruyor (zaten vardı)

### 2️⃣ **Build Optimizasyonları**
- ✅ `proguard-rules.pro` oluşturuldu
- ✅ `minifyEnabled = true` (APK boyutunu küçültür)
- ✅ `shrinkResources = true` (Kullanılmayan kaynakları siler)

### 3️⃣ **Uygulama İkonu**
- ✅ Flutter logosu yerine ONLOG ikonu kullanılıyor
- ✅ `flutter_launcher_icons` zaten kurulu
- ✅ `assets/icons/app_icon_512.png` mevcut

---

## ⏳ YAPILMASI GEREKEN

### 🔐 **ADIM 1: Keystore Oluştur**

**Seçenek A:** Batch script çalıştır (KOLAY)
```
c:\onlog_projects\CREATE_COURIER_KEYSTORE.bat
```
Çift tıkla, soruları cevapla.

**Seçenek B:** Manuel komut (ELLE)
```powershell
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -genkey -v -keystore c:\onlog_projects\onlog-courier-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onlog-courier
```

**Sorulara Cevaplar:**
```
Enter keystore password: onlog2024courier!
Re-enter new password: onlog2024courier!

What is your first and last name? ONLOG Courier
What is the name of your organizational unit? ONLOG
What is the name of your organization? ONLOG Ltd
What is the name of your City or Locality? Istanbul
What is the name of your State or Province? Istanbul
What is the two-letter country code for this unit? TR

Is CN=ONLOG Courier, OU=ONLOG, O=ONLOG Ltd, L=Istanbul, ST=Istanbul, C=TR correct? yes
```

---

### 🔨 **ADIM 2: Release APK Oluştur**

Keystore oluştuktan sonra:

```powershell
cd c:\onlog_projects\onlog_courier_app
flutter build apk --release
```

APK şurada oluşacak:
```
c:\onlog_projects\onlog_courier_app\build\app\outputs\flutter-apk\app-release.apk
```

---

### 📦 **ADIM 3: App Bundle Oluştur (Google Play için önerilen)**

```powershell
cd c:\onlog_projects\onlog_courier_app
flutter build appbundle --release
```

App Bundle şurada oluşacak:
```
c:\onlog_projects\onlog_courier_app\build\app\outputs\bundle\release\app-release.aab
```

---

## 📋 KEYSTORE BİLGİLERİ

**⚠️ ÖNEMLİ: Bu bilgileri güvenli bir yerde sakla!**

```
Dosya: c:\onlog_projects\onlog-courier-release.jks
Alias: onlog-courier
Şifre: onlog2024courier!
```

**Neden Önemli?**
- Bu keystore ile imzalanmış uygulamayı sadece bu keystore ile güncelleyebilirsin
- Keystore'u kaybedersen Google Play'e güncelleme yükleyemezsin
- Git'e ekleme (zaten .gitignore'da)
- Google Drive / Dropbox'a yedekle

---

## 🎯 GOOGLE PLAY CONSOLE ADMLARI

### 1️⃣ **Uygulama Oluştur**
- Google Play Console'a git: https://play.google.com/console
- "Uygulama Oluştur" butonuna tıkla
- Uygulama adı: **ONLOG Kurye**
- Varsayılan dil: **Türkçe**
- Uygulama türü: **Uygulama**
- Ücretsiz/Ücretli: **Ücretsiz**

### 2️⃣ **Uygulama Bilgilerini Doldur**
- **Kısa Açıklama:** ONLOG kurye teslimat uygulaması
- **Tam Açıklama:** (Detaylı açıklama yaz)
- **Ekran Görüntüleri:** En az 2 adet telefon ekran görüntüsü
- **Simge:** 512x512 px PNG (zaten var: `app_icon_512.png`)
- **Özellik Görseli:** 1024x500 px (Canva'da hazırla)

### 3️⃣ **İçerik Derecelendirmesi**
- Hedef kitle: **18+** (İş uygulaması)
- İçerik kategorisi: **Hizmetler**

### 4️⃣ **Fiyatlandırma ve Dağıtım**
- Ülkeler: **Türkiye** (sadece)
- Hedef kitle: **18+**
- Reklam: **Hayır**

### 5️⃣ **App Bundle Yükle**
- **Üretim** → **Yeni Sürüm Oluştur**
- `app-release.aab` dosyasını yükle
- Sürüm notları yaz
- **İncelemeleri Başlat**

---

## 📱 TEST ETME

Release APK'yı test etmek için:

```powershell
# APK oluştur
flutter build apk --release

# Telefona yükle
adb install c:\onlog_projects\onlog_courier_app\build\app\outputs\flutter-apk\app-release.apk
```

**Test Edilecekler:**
- ✅ Uygulama başlıyor mu?
- ✅ GPS çalışıyor mu?
- ✅ Bildirimler geliyor mu?
- ✅ Sipariş kabul ediliyor mu?
- ✅ Fotoğraf çekiliyor mu?
- ✅ Crash olmuyor mu?

---

## 🔍 SORUN GİDERME

### Build Hatası Alırsanız:

**Hata: "Keystore file not found"**
```
Çözüm: Keystore'u oluşturmadınız. ADIM 1'i yapın.
```

**Hata: "Signing config not found"**
```
Çözüm: key.properties dosyasını kontrol edin:
c:\onlog_projects\onlog_courier_app\android\key.properties
```

**Hata: "minSdkVersion is too low"**
```
Çözüm: android/app/build.gradle.kts'de minSdk = 21 olmalı
```

---

## 📊 DOSYA YAPISI

```
onlog_projects/
├── onlog-courier-release.jks          ← Keystore (OLUŞTURULMASI GEREK!)
├── CREATE_COURIER_KEYSTORE.bat        ← Keystore oluşturma script
└── onlog_courier_app/
    └── android/
        ├── key.properties              ← ✅ Keystore bilgileri
        └── app/
            ├── build.gradle.kts        ← ✅ Signing config
            └── proguard-rules.pro      ← ✅ ProGuard kuralları
```

---

## ✅ SON KONTROL LİSTESİ

- [ ] Keystore oluşturuldu (`onlog-courier-release.jks`)
- [ ] Keystore şifresi güvenli yerde saklandı
- [ ] `flutter build apk --release` başarılı
- [ ] `flutter build appbundle --release` başarılı
- [ ] APK telefonda test edildi
- [ ] Uygulama simgesi Flutter logosu değil
- [ ] GPS çalışıyor
- [ ] Bildirimler çalışıyor
- [ ] Google Play Console hesabı açıldı
- [ ] App Bundle yüklendi
- [ ] İnceleme başlatıldı

---

## 🎉 SONRAKI ADIMLAR

1. **Keystore oluştur** → `CREATE_COURIER_KEYSTORE.bat` çalıştır
2. **Build al** → `flutter build appbundle --release`
3. **Google Play'e yükle** → App Bundle yükle
4. **İnceleme bekle** → 1-7 gün sürer
5. **Yayınla** → Onaylandıktan sonra yayınla!

---

**Hazırlayan:** GitHub Copilot  
**Tarih:** 3 Kasım 2025  
**Versiyon:** 1.0.0
