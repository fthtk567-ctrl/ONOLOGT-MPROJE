# 🔔 ONLOG Bildirim Icon Rehberi

## 📱 Gerekli Dosyalar

Bu klasörlere **ic_notification.png** dosyası eklemeniz gerekiyor:

```
drawable-mdpi/ic_notification.png    → 24x24 piksel
drawable-hdpi/ic_notification.png    → 36x36 piksel
drawable-xhdpi/ic_notification.png   → 48x48 piksel
drawable-xxhdpi/ic_notification.png  → 72x72 piksel
drawable-xxxhdpi/ic_notification.png → 96x96 piksel
```

## 🎨 Tasarım Kuralları

### ✅ YAPILMASI GEREKENLER:
- Tamamen BEYAZ renk kullanın (RGB: 255, 255, 255)
- Arka plan ŞEFFAF olmalı (transparent)
- Basit, tek renkli silüet tasarım
- Tanınabilir şekiller (O harfi, ok, paket, kamyon vb.)
- PNG formatında kaydedin

### ❌ YAPILMAMASI GEREKENLER:
- Renkli tasarım (Android 5.0+ sadece beyaz gösterir)
- Gradyan, gölge efektleri
- Karmaşık detaylar (küçük ekranda görünmez)
- Yazı (sadece semboller kullanın)

## 🚀 EN KOLAY YOL: Android Asset Studio

### Adım 1: Web sitesine gidin
https://romannurik.github.io/AndroidAssetStudio/icons-notification.html

### Adım 2: Logo yükleyin
- "Image" seçeneğini işaretleyin
- ONLOG logonuzu yükleyin (şeffaf PNG olmalı)
- Eğer logo renkli ise, önce beyaz versiyonunu oluşturun

### Adım 3: Ayarları yapın
- **Padding:** %25-30 arası (logo çok kenarlarda olmasın)
- **Trim:** Evet (gereksiz boşlukları kırpar)
- **Name:** ic_notification (varsayılan)

### Adım 4: İndirin
- "Download ZIP" butonuna tıklayın
- ZIP dosyasını açın

### Adım 5: Dosyaları kopyalayın
- ZIP içindeki `res/` klasörünü açın
- İçindeki TÜM `drawable-*` klasörlerini BURAYA kopyalayın
  (Yani: C:\onlog_projects\onlog_courier_app\android\app\src\main\res\ içine)

## 🎯 Tasarım Önerileri

### Öneri 1: "O" Harfi + Ok
```
⭕ → 
```
Büyük O harfi, içinde sağa doğru ok (teslimat/hareket anlamında)

### Öneri 2: Paket Kutusu
```
📦
```
Basit bir kargo kutusu silueti

### Öneri 3: Kamyon Silueti
```
🚚
```
Küçük teslimat aracı

### Öneri 4: ONL Harfleri
```
ONL
```
ONLOG'un ilk 3 harfi (büyük, kalın)

## ✅ Dosyaları Ekledikten Sonra

1. Uygulamayı YENİDEN DERLEYIN:
   ```powershell
   cd C:\onlog_projects\onlog_courier_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test bildirimi gönderin (Merchant Panel → Test Bildirimi)

3. Telefonun üst status bar'ına bakın:
   - Artık Flutter logosu YOK ✅
   - ONLOG logosu görünüyor ✅

## 🆘 Yardım

Eğer logolar görünmüyorsa:
1. Dosya isimlerinin TAM OLARAK `ic_notification.png` olduğundan emin olun
2. Tüm 5 klasöre de dosya koyduğunuzdan emin olun
3. `flutter clean` komutuyla önbelleği temizleyin
4. Uygulamayı tamamen kaldırıp yeniden yükleyin

## 📞 İletişim

Sorun yaşarsanız screenshot gönderin!
