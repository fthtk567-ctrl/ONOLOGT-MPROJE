# ⚡ YARIN SABAH QUICK START GUIDE
**Süre: 10 Dakika**

---

## 🚀 HIZLI BAŞLANGIÇ

### 1️⃣ Courier App'i Başlat (2 dk)
```powershell
cd c:\onlog_projects\onlog_courier_app
flutter run -d R6CY200GZCF
```
✅ Terminal açık kalsın - logları izleyeceğiz!

### 2️⃣ Teslimatı Tamamla (3 dk)
**Telefonda:**
1. Courier App aç
2. TEKELER KEPAB teslimatına tıkla (1300₺)
3. "Teslimata Git" → Tahsil tutarı gir: **1300**
4. **"TESLİM ET" BUTONUNA BAS** ⚡

**Terminalde göreceksin:**
```
I/flutter: 💰 Kazanç kaydediliyor...
I/flutter: merchantName: TEKELER KEPAB
I/flutter: earnings koleksiyonuna yazıldı
```

### 3️⃣ Admin Panel Kontrolü (2 dk)
```powershell
cd c:\onlog_projects\onlog_admin_panel
flutter run -d chrome
```

**Tarayıcıda:**
1. F5 ile yenile
2. 💰 Finansal Yönetim'e git
3. **Kurye Ödemeleri** sekmesi
4. Görmelisin:
   - Kurye: Veli Şahin
   - **Merchant: TEKELER KEPAB** ✅
   - Ödeme Bekliyor

### 4️⃣ Ödeme Test Et (3 dk)
1. "Ödeme Yap" butonuna bas
2. Onayı tıkla
3. Durum: "Ödendi" olmalı ✅
4. Courier App'te Kazançlar sekmesinde "Ödendi" görmeli

---

## ❌ Sorun Çıkarsa

### merchantName gözükmüyor?
```bash
# Firebase Console aç:
https://console.firebase.google.com

# Kontrol et:
Firestore → earnings → [son doküman] → merchantName field'ı var mı?
```

### Terminal'de log yok?
```dart
// delivery_details_screen.dart satır 235'e ekle:
print('🔥 BAŞLIYOR: Kazanç kaydediliyor...');
print('🔥 merchantName: $merchantName');
```

### Admin Panel'de veri yok?
1. Chrome DevTools aç (F12)
2. Console'da Firestore query'leri gör
3. Network sekmesinde firebase çağrılarını kontrol et

---

## 📱 Cihazlar

- **Courier App:** Android telefon (R6CY200GZCF)
- **Merchant Panel:** Chrome (localhost)
- **Admin Panel:** Chrome (localhost)

---

## 🎯 Başarı = 4 Adım Tamamlandı ✅

İyi şanslar! 🚀
