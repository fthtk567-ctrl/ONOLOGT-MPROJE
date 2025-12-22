# Trendyol Go Yemek API Entegrasyonu

ONLOG Merchant Panel, Trendyol Go Yemek API'si ile entegre edilmiştir. Bu döküman API'nin nasıl yapılandırılacağını açıklar.

## 📋 İçindekiler
- [Kurulum](#kurulum)
- [API Credentials Edinme](#api-credentials-edinme)
- [Test Ortamı](#test-ortamı)
- [Production Ortamı](#production-ortamı)
- [Sorun Giderme](#sorun-giderme)

---

## 🚀 Kurulum

### 1. Config Dosyasını Oluştur

```bash
# Template dosyasını kopyala
cp lib/config/trendyol_config.dart.template lib/config/trendyol_config.dart
```

### 2. Credentials'ı Ekle

`lib/config/trendyol_config.dart` dosyasını düzenle:

```dart
class TrendyolConfig {
  static const String supplierId = 'GERÇEK_SUPPLIER_ID';
  static const String apiKey = 'GERÇEK_API_KEY';
  static const String apiSecretKey = 'GERÇEK_SECRET_KEY';
  static const String entegratorName = 'OnlogMerchantPanel';
  static const bool isProduction = false; // Test için false
}
```

### 3. Uygulamayı Çalıştır

```bash
flutter run
```

Başlangıçta şu loglara bakın:
```
🔐 ✅ Trendyol API Configured
Environment: STAGE
Supplier ID: 107385
API Key: test****
Entegrator: OnlogMerchantPanel
```

---

## 🔑 API Credentials Edinme

### Trendyol Satıcı Paneli Üzerinden:

1. **Giriş Yap**
   - https://partner.trendyol.com adresine git
   - Satıcı hesabınla giriş yap

2. **Entegrasyon Bilgilerine Git**
   - Sol menü: **Hesap Bilgilerim**
   - Alt menü: **Entegrasyon Bilgileri**

3. **Bilgileri Kopyala**
   - **Supplier ID** (Satıcı ID)
   - **API Key** (Kullanıcı Adı)
   - **API Secret Key** (Şifre)

4. **Config Dosyasına Yapıştır**
   ```dart
   static const String supplierId = 'BURAYA_SUPPLIER_ID';
   static const String apiKey = 'BURAYA_API_KEY';
   static const String apiSecretKey = 'BURAYA_SECRET_KEY';
   ```

---

## 🧪 Test Ortamı (STAGE)

Test ortamında çalışmak için:

### Ayarlar
```dart
static const bool isProduction = false; // STAGE
```

### Base URL
```
https://stageapi.tgoapis.com/integrator
```

### Özellikler
- ✅ Gerçek API yapısı
- ✅ Test siparişleri oluşturulabilir
- ✅ Canlı sistemden bağımsız
- ⚠️ IP Whitelisting gerekebilir

### Test Siparişi Oluşturma
Kodda mevcut `createTestOrder()` metodunu kullan:

```dart
final orderId = await TrendyolApiService().createTestOrder(
  customerFirstName: 'Ahmet',
  customerLastName: 'Test',
  productName: 'Hamburger Menü',
);
```

---

## 🌐 Production Ortamı (CANLI)

⚠️ **UYARI**: Production'a geçmeden önce mutlaka test ortamında test edin!

### Ayarlar
```dart
static const bool isProduction = true; // PRODUCTION
```

### Base URL
```
https://api.tgoapis.com/integrator
```

### Gereksinimler
1. ✅ Test ortamında başarılı testler
2. ✅ IP Whitelisting onayı
3. ✅ Gerçek restaurant bilgileri
4. ✅ Kurye sistemi hazır

---

## 🛠️ Özellikler

### Sipariş Yönetimi
- ✅ Yeni siparişleri çekme (`fetchPackages`)
- ✅ Sipariş kabul etme (`acceptOrder`)
- ✅ Hazır işaretleme (`markOrderReady`)
- ✅ Yola çıktı işaretleme (`markOrderShipped`)
- ✅ Teslim edildi işaretleme (`markOrderDelivered`)
- ✅ İptal etme (`cancelOrder`)

### Otomatik Polling
30 saniye aralıklarla yeni siparişler çekiliyor:
```dart
TrendyolPollingService().startPolling();
```

### UI Entegrasyonu
- 🟧 Turuncu TRENDYOL badge
- 📊 Platform filtresi (Tümü/Trendyol/Getir/Yemeksepeti)
- 🎯 Durum bazlı action butonları
- 🔔 Yeni sipariş bildirimleri (ses + görsel)

---

## 🔧 Sorun Giderme

### "API credentials not set!" Hatası
**Sebep**: Config dosyası düzenlenmemiş.

**Çözüm**:
1. `lib/config/trendyol_config.dart` dosyasını oluştur
2. Gerçek credentials'ı ekle
3. Uygulamayı yeniden başlat

---

### IP Whitelisting Hatası
**Sebep**: Sunucu IP'si Trendyol tarafında onaylanmamış.

**Çözüm**:
1. Trendyol Destek'i ara: **0850 258 58 00**
2. Sunucu IP adresini bildir
3. Whitelist onayını bekle (genelde 1-2 iş günü)

---

### Siparişler Gelmiyor
**Kontrol Listesi**:
- [ ] Credentials doğru mu?
- [ ] STAGE/PRODUCTION ortamı doğru mu?
- [ ] Internet bağlantısı var mı?
- [ ] IP Whitelisting onaylı mı?
- [ ] Restaurant açık mı? (Production'da)

**Debug Log**:
```
I/flutter: 🔍 [Trendyol] kIsWeb = false
I/flutter: 📡 [Trendyol] Fetching packages: https://stageapi.tgoapis.com/...
I/flutter: ✅ [Trendyol] Fetched 3 packages
```

---

### Test Siparişi Oluşturulamıyor
**Sebep**: Test siparişi sadece STAGE ortamında çalışır.

**Kontrol**:
```dart
static const bool isProduction = false; // STAGE olmalı
```

---

## 📞 Destek

### Trendyol Destek
- **Telefon**: 0850 258 58 00
- **Email**: Satıcı panelinden ticket aç

### Teknik Dokümantasyon
- API Dökümanı: Trendyol Satıcı Paneli > Yardım > API Dökümanları

### Kod Sorunları
- Developer: GitHub Issues veya internal destek

---

## 🔒 Güvenlik

### ⚠️ UYARILAR

1. **Credentials'ı ASLA git'e ekleme!**
   ```bash
   # .gitignore'da olmalı:
   lib/config/trendyol_config.dart
   ```

2. **Production credentials'ı paylaşma!**
   - Slack, email vb. güvensiz kanallardan gönderme
   - Şifreli kanallar kullan (1Password, Bitwarden vb.)

3. **API Secret Key'i loglamaktan kaçın!**
   ```dart
   // YANLIŞ ❌
   debugPrint('Secret: $_apiSecretKey');
   
   // DOĞRU ✅
   debugPrint('Secret: ${_apiSecretKey?.substring(0, 4)}****');
   ```

---

## 📝 Changelog

### v1.0.0 (2025-10-12)
- ✅ Initial Trendyol API entegrasyonu
- ✅ STAGE/PRODUCTION ortam desteği
- ✅ Sipariş yönetimi (CRUD)
- ✅ Otomatik polling (30s)
- ✅ UI entegrasyonu (badge, filter, actions)
- ✅ Bildirim sistemi

---

**Son Güncelleme**: 12 Ekim 2025
**Versiyon**: 1.0.0
**Durum**: ✅ Production Ready
