# ONLOG Courier App - Google Play Store Hazırlık Rehberi

## 📋 KONTROL LİSTESİ

### ✅ Tamamlanan:
- [x] Uygulama ismi: "Onlog Kurye"
- [x] Package name: com.onlog.onlog_courier_app
- [x] App icon
- [x] Firebase entegrasyonu
- [x] AndroidManifest izinleri

### ❌ Yapılması Gerekenler:

## 🔑 1. KEYSTORE OLUŞTURMA (5 dakika)

### Windows PowerShell'de:
```powershell
cd c:\onlog_projects\onlog_courier_app\android

keytool -genkey -v -keystore onlog-courier-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onlog-courier
```

### Sorulacak Bilgiler:
```
Enter keystore password: [ŞİFRENİZ - EN AZ 6 KARAKTER]
Re-enter new password: [AYNI ŞİFRE]
What is your first and last name? Onlog Teknoloji
What is the name of your organizational unit? Development
What is the name of your organization? Onlog
What is the name of your City or Locality? Konya
What is the name of your State or Province? Konya
What is the two-letter country code for this unit? TR
Is CN=Onlog Teknoloji, OU=Development, O=Onlog, L=Konya, ST=Konya, C=TR correct? yes

Enter key password for <onlog-courier>: [ENTER - aynı şifreyi kullan]
```

### ⚠️ ÇOK ÖNEMLİ:
- **Şifreyi MUTLAKA kaydedin!**
- **onlog-courier-release.jks dosyasını YEDEKLEYIN!**
- **Kaybederseniz uygulama güncelleyemezsiniz!**

---

## 📝 2. KEY.PROPERTIES DOSYASI OLUŞTURMA (1 dakika)

`android/key.properties` dosyası oluşturun:

```properties
storePassword=[YUKARIDA GİRDİĞİNİZ ŞİFRE]
keyPassword=[YUKARIDA GİRDİĞİNİZ ŞİFRE]
keyAlias=onlog-courier
storeFile=onlog-courier-release.jks
```

**Örnek:**
```properties
storePassword=Onlog2025!
keyPassword=Onlog2025!
keyAlias=onlog-courier
storeFile=onlog-courier-release.jks
```

---

## 🔨 3. BUILD.GRADLE.KTS GÜNCELLEME (2 dakika)

`android/app/build.gradle.kts` dosyasında değişiklik yapılacak.

---

## 📦 4. RELEASE BUILD (5 dakika)

```powershell
cd c:\onlog_projects\onlog_courier_app

# App Bundle oluştur (Google Play için)
flutter build appbundle --release

# Veya APK oluştur (direkt yükleme için)
flutter build apk --release
```

### Çıktılar:
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (Google Play için)
- **APK**: `build/app/outputs/flutter-apk/app-release.apk` (Direkt yükleme için)

---

## 📱 5. GOOGLE PLAY CONSOLE KAYIT ($25 - Tek Seferlik)

1. https://play.google.com/console adresine gidin
2. "Create Application" tıklayın
3. Kredi kartı ile $25 ödeme yapın (tek seferlik)
4. Uygulama bilgilerini doldurun:
   - App name: Onlog Kurye
   - Category: Business
   - Contact email: [email@onlog.com]
   - Privacy policy URL: [yapılacak]

---

## 🚀 6. UYGULAMA YÜKLEME

### İlk Yükleme İçin Gerekli:
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (en az 2 adet)
- [ ] Kısa açıklama (80 karakter max)
- [ ] Uzun açıklama (4000 karakter max)
- [ ] Privacy Policy URL

### Test Versiyonu (Hızlı):
1. Internal Testing oluşturun
2. AAB dosyasını yükleyin
3. Test kullanıcıları ekleyin (courier email'leri)
4. Link ile dağıtın

### Production (Resmi Yayın):
1. Tüm bilgileri doldurun
2. AAB dosyasını yükleyin
3. Content rating alın
4. Review'a gönderin (1-3 gün)

---

## ⚡ HIZLI TEST İÇİN: APK Dağıtımı (Ücretsiz)

Google Play beklemeden hemen test etmek için:

```powershell
# APK oluştur
flutter build apk --release

# Dosya burada olacak:
# build/app/outputs/flutter-apk/app-release.apk
```

Bu APK'yı:
- ✅ Google Drive'a yükleyin
- ✅ WhatsApp ile gönderin
- ✅ WeTransfer ile paylaşın
- ✅ Courier'lar direkt yüklesin

**Dezavantaj:** Google Play Store'da görünmez, manuel yükleme gerekir.

---

## 🔐 GÜVENLİK

### .gitignore'a ekleyin:
```
# Keystore dosyaları
*.jks
*.keystore
key.properties
google-services.json
```

### Yedekleme:
1. `onlog-courier-release.jks` dosyasını şifreli USB'ye kopyalayın
2. `key.properties` dosyasını güvenli yere kaydedin
3. Şifreyi password manager'a ekleyin

---

## 📊 SONUÇ

### Hemen Başlamak İçin (Ücretsiz):
1. ✅ Keystore oluştur
2. ✅ APK build al
3. ✅ WhatsApp ile dağıt
4. ✅ Courier'lar test etsin

### Resmi Yayın İçin (Sonra):
1. ⏳ Google Play Console kaydı ($25)
2. ⏳ AAB build al
3. ⏳ Store sayfası hazırla
4. ⏳ Review'a gönder

---

## 🆘 SORUN ÇÖZME

### "keytool command not found"
Java JDK kurulu değil. Flutter zaten JDK ile geliyor:
```powershell
$env:JAVA_HOME = "C:\flutter\jre"
$env:PATH += ";$env:JAVA_HOME\bin"
```

### Build hatası
```powershell
flutter clean
flutter pub get
flutter build apk --release
```

### "Signing key not found"
key.properties dosyasını kontrol edin, yol doğru mu?
