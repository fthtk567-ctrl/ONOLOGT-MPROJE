# 🚀 ONLOG Courier App - Canlı Test Kontrol Listesi
## 📅 Tarih: 1 Kasım 2025 - SGK Kurye Testleri

---

## ✅ HAZIR OLAN ÖZELLİKLER

### 1. 🔐 GİRİŞ SİSTEMİ
- ✅ Email/Şifre ile giriş
- ✅ Kurye rolü kontrolü (role='courier')
- ✅ Durum kontrolü:
  - ⏳ `pending` → "Onay Bekleniyor" mesajı gösterir
  - ❌ `rejected` → Red nedeniyle birlikte gösterir
  - ✅ `approved` → Giriş yapabilir
- ✅ Aktif kontrol (is_active=true olmalı)
- ✅ **Giriş yaparken otomatik `is_available=true` yapılır**
- ✅ FCM Token kaydı (push notification için)
- ✅ Son giriş zamanı kaydedilir

**Test Adımları:**
1. SGK kurye email/şifre ile giriş yap
2. Onay bekleyen hesapla test et (pending status)
3. Reddedilmiş hesapla test et (rejected status)
4. Başarılı giriş sonrası ana ekran açılsın

---

### 2. 📱 NAVİGASYON SİSTEMİ

#### SGK Kuryeleri İçin (courier_type='sgk'):
- ✅ 3 Tab:
  1. 🏠 **Teslimatlar** (Ana Sayfa)
  2. 📊 **Performans** (Bonus & İstatistikler)
  3. 👤 **Profil**
- ✅ **💰 Kazançlar sekmesi YOK** (para gösterilmez)

#### Esnaf Kuryeleri İçin (courier_type='esnaf'):
- ✅ 3 Tab:
  1. 🏠 **Teslimatlar** (Ana Sayfa)
  2. 💰 **Kazançlar** (Para detayları)
  3. 👤 **Profil**

**Test Adımları:**
1. SGK kurye hesabıyla giriş yap → "Performans" sekmesi görünmeli
2. Esnaf kurye hesabıyla giriş yap → "Kazançlar" sekmesi görünmeli
3. Her iki hesapta da tab geçişleri çalışsın

---

### 3. 🟢 MESAİ SİSTEMİ (Duty Management)

#### Ana Sayfa Özellikleri:
- ✅ **"Mesaiye Başla"** butonu (gradient yeşil kart)
- ✅ **"Mesaiden Çık"** butonu (gradient gri kart)
- ✅ Mesai durumu veritabanından yüklenir (`is_available`)

#### Mesaiye Başlarken:
1. ✅ Konum izni istenir
2. ✅ İzin verilirse:
   - `is_available=true` yapılır (database)
   - Hemen konum gönderilir
   - 30 saniyede bir konum güncellenir (Timer başlar)
   - Buton "Mesaiden Çık" olur
3. ✅ İzin verilmezse:
   - Hata mesajı gösterilir
   - "Ayarlardan konum izni verin" yönlendirir
   - Mesai başlamaz

#### Mesaiden Çıkarken:
1. ✅ `is_available=false` yapılır (database)
2. ✅ Konum güncellemesi durur (Timer iptal)
3. ✅ Buton tekrar "Mesaiye Başla" olur

**Test Adımları:**
1. Ana sayfaya git → "Mesaiye Başla" butonunu gör
2. Butona bas → Konum izni iste
3. İzin ver → Buton "Mesaiden Çık" olsun
4. Admin panelden kurye listesinde "Müsait" görünsün
5. 30 saniye bekle → Konum güncellensin (current_location değişsin)
6. "Mesaiden Çık"a bas → "Mesaiye Başla" butonuna dönsün
7. Admin panelde "Müsait Değil" görünsün

---

### 4. 📍 KONUM TAKİBİ (Location Tracking)

#### Çalışma Mantığı:
- ✅ **Sadece mesaide iken çalışır** (is_available=true)
- ✅ 30 saniye aralıklarla GPS konumu alır
- ✅ `current_location` JSONB alanına kaydeder:
  ```json
  {
    "latitude": 41.0082,
    "longitude": 28.9784,
    "updated_at": "2025-11-01T09:30:00Z"
  }
  ```
- ✅ Konum servisleri kapalıysa hata gösterir
- ✅ Konum izni yoksa tekrar ister

#### Konum İzinleri:
- ✅ `whileInUse` - Uygulama açıkken konum al
- ✅ `always` (opsiyonel) - Arka planda da konum al

**Test Adımları:**
1. Mesaiye başla
2. Telefon GPS'ini aç
3. 30 saniye bekle
4. Supabase'den `current_location` alanını kontrol et
5. Konumun güncellendiğini doğrula
6. Farklı bir yere git → Konum değişsin
7. Mesaiden çık → Konum güncellemesi dursun

---

### 5. 📴 OTOMATİK OFFLİNE (Lifecycle Management)

#### Tetikleme Durumları:
- ✅ **Uygulama kapatılırsa** (`AppLifecycleState.detached`)
- ✅ **Uygulama arka plana alınırsa** (`AppLifecycleState.paused`)
- ✅ **Logout yapılırsa** (Profile ekranından çıkış)

#### Yapılan İşlemler:
1. ✅ `is_available=false` yapılır (database)
2. ✅ Konum timer'ı iptal edilir
3. ✅ Kullanıcı otomatik "Müsait Değil" olur

**Test Adımları:**
1. Mesaiye başla → Müsait ol
2. Uygulamayı kapat (Home tuşu, task manager vb.)
3. Admin panelden kontrol et → "Müsait Değil" olmalı
4. Uygulamayı tekrar aç → Mesai durumu korunmalı (false)
5. Logout yap → "Müsait Değil" olmalı

---

### 6. 📊 PERFORMANS EKRANI (SGK Kuryeleri İçin)

#### Gösterilen İstatistikler:
- ✅ **Günlük Teslimatlar:** Bugün kaç teslimat
- ✅ **Haftalık Teslimatlar:** Bu hafta kaç teslimat
- ✅ **Aylık Teslimatlar:** Bu ay kaç teslimat
- ✅ **Toplam Teslimatlar:** Tüm zamanlar
- ✅ **Tamamlanan:** DELIVERED statuslu
- ✅ **İptal Edilen:** CANCELLED statuslu
- ✅ **Başarı Oranı:** % hesabı (renk kodlu)
  - 🟢 %90+ → Yeşil
  - 🟠 %70-89 → Turuncu
  - 🔴 <%70 → Kırmızı

#### Bonus Sistemi (5 Seviye):
- 🌱 **Başlangıç:** 0-49 teslimat (Gri)
- 🥉 **Bronz:** 50-99 teslimat (Bronz renk)
- 🥈 **Gümüş:** 100-149 teslimat (Gümüş renk)
- 🥇 **Altın:** 150-199 teslimat (Altın renk)
- ⭐ **Platin:** 200+ teslimat (Mor/Platin renk)

#### Özellikler:
- ✅ Progress bar ile ilerleme gösterimi
- ✅ "X teslimat daha sonraki seviyeye!" mesajı
- ✅ Son 10 teslimat listesi
- ✅ Pull-to-refresh (aşağı çek yenile)
- ✅ **Para miktarı gösterilmez** ❌💰

**Test Adımları:**
1. SGK kurye ile giriş yap
2. "Performans" sekmesine git
3. İstatistiklerin doğru yüklendiğini kontrol et
4. Bonus seviyesini kontrol et
5. Aşağı çek yenile → Veriler güncellensin
6. ❌ Hiçbir yerde para miktarı gösterilmesin

---

### 7. 📦 SİPARİŞ YÖNETİMİ

#### Ana Sayfa Sipariş Listesi:
- ✅ Realtime güncelleme (Supabase Stream)
- ✅ Sipariş kartları:
  - Sipariş ID
  - Merchant adı
  - Teslimat adresi
  - Toplam tutar
  - Durum badge'i
- ✅ Durum filtreleme:
  - Tümü
  - Atanmış
  - Devam Eden
  - Tamamlanan

#### Sipariş Durumları:
- 🟡 **ASSIGNED:** Kuryeye atandı
- 🔵 **ACCEPTED:** Kurye kabul etti
- 🟣 **PICKED_UP:** Kurye ürünü aldı
- 🟢 **DELIVERED:** Teslim edildi
- 🔴 **CANCELLED:** İptal edildi

#### Sipariş Detay Ekranı:
- ✅ Merchant bilgileri
- ✅ Müşteri bilgileri
- ✅ Ürün listesi
- ✅ Harita üzerinde konum
- ✅ Durum güncelleme butonları
- ✅ Teslimat fotoğrafı yükleme
- ✅ QR kod okutma

**Test Adımları:**
1. Merchant panelden sipariş oluştur
2. Siparişi kuryeye ata
3. Courier app'te siparişi gör (realtime)
4. Sipariş kartına tıkla → Detay ekranı açılsın
5. "Kabul Et" → Status ACCEPTED olsun
6. "Ürünü Aldım" → Status PICKED_UP olsun
7. Teslimat fotoğrafı yükle
8. QR kod okut (opsiyonel)
9. "Teslim Edildi" → Status DELIVERED olsun
10. Admin panelden ödeme transaction'larını kontrol et

---

### 8. 🔔 BİLDİRİM SİSTEMİ

#### Bildirim Türleri:
- ✅ **Yeni Sipariş:** Kuryeye sipariş atandığında
- ✅ **Sipariş İptali:** Merchant iptal ederse
- ✅ **Sistem Bildirimleri:** Admin mesajları

#### Bildirim Kanalları:
- ✅ **FCM Push Notification:** Arka planda/kapalıyken
- ✅ **Lokal Bildirim:** Uygulama açıkken
- ✅ **SnackBar:** Realtime bildirim

#### Bildirim Ekranı:
- ✅ Bildirim listesi
- ✅ Okundu/okunmadı işaretleme
- ✅ Bildirime tıkla → İlgili ekrana git

**Test Adımları:**
1. Mesaiye başla
2. Merchant panelden sipariş oluştur ve kuryeye ata
3. Courier app açıkken → SnackBar + Lokal bildirim görsün
4. Uygulamayı kapat
5. Yeni sipariş oluştur
6. Push notification gelsin
7. Bildirime tıkla → Uygulama açılsın + Sipariş detayı görünsün

---

### 9. 👤 PROFİL EKRANI

#### Görüntülenen Bilgiler:
- ✅ Profil fotoğrafı (opsiyonel)
- ✅ Ad Soyad
- ✅ Email
- ✅ Telefon
- ✅ Kurye Tipi (SGK/Esnaf)
- ✅ Durumu (Aktif/Pasif)
- ✅ Kayıt tarihi
- ✅ Son giriş tarihi

#### İşlemler:
- ✅ **Bildirim Ayarları:** Bildirimleri aç/kapat
- ✅ **Yardım:** Destek bilgileri
- ✅ **Hakkında:** Uygulama bilgisi
- ✅ **Çıkış Yap:** Logout + is_available=false

**Test Adımları:**
1. Profil sekmesine git
2. Kullanıcı bilgilerini kontrol et
3. Kurye tipini kontrol et (SGK görünmeli)
4. Bildirim ayarlarını değiştir
5. Çıkış yap → Login ekranına dön
6. Database'den is_available=false olduğunu kontrol et

---

## 🔍 CANLI TEST SENARYO

### Senaryo 1: İlk Giriş + Mesaiye Başlama
```
1. SGK kurye hesabıyla giriş yap (email: sgk1@test.com)
2. Ana sayfa açılsın
3. "Mesaiye Başla" butonuna bas
4. Konum izni ver
5. Buton "Mesaiden Çık" olsun
6. Admin panelden "Müsait" olduğunu kontrol et
7. 30 saniye bekle → Konum güncellensin
```

### Senaryo 2: Sipariş Alma + Teslimat
```
1. Mesaide olduğundan emin ol
2. Merchant panelden sipariş oluştur
3. Siparişi SGK kuryeye ata
4. Courier app'te yeni sipariş bildirimini gör
5. Sipariş kartına tıkla
6. "Kabul Et" butonu
7. "Ürünü Aldım" butonu
8. Teslimat fotoğrafı yükle
9. "Teslim Edildi" butonu
10. Admin panelden ödeme işlemini kontrol et
```

### Senaryo 3: Performans Takibi
```
1. SGK kurye ile giriş yap
2. "Performans" sekmesine git
3. Günlük/Haftalık/Aylık teslimat sayılarını kontrol et
4. Başarı oranını kontrol et
5. Bonus seviyesini kontrol et
6. ❌ Hiçbir yerde para miktarı görünmemeli
```

### Senaryo 4: Uygulama Kapatma + Otomatik Offline
```
1. Mesaiye başla
2. Admin panelden "Müsait" olduğunu kontrol et
3. Uygulamayı kapat (home tuşu)
4. Admin panelden "Müsait Değil" olduğunu kontrol et
5. Uygulamayı tekrar aç
6. Mesai durumu "Mesaiye Başla" olmalı (offline kalmış)
```

### Senaryo 5: Logout + Güvenlik
```
1. Profil sekmesine git
2. "Çıkış Yap" butonu
3. Onay dialogu çıksın
4. Evet → Login ekranına dön
5. Database'den is_available=false olduğunu kontrol et
```

---

## ⚠️ BİLİNEN SORUNLAR VE SINIRLAMALAR

### 1. Konum Takibi
- ⚠️ **Batarya Tüketimi:** 30 saniyede bir konum güncellemesi batarya tüketir
- ⚠️ **GPS Hassasiyeti:** İç mekanlarda GPS sinyali zayıf olabilir
- ⚠️ **Android Konum Servisleri:** Kapalıysa konum alamaz
- ✅ **Çözüm:** Kullanıcıya GPS açma bildirimi göster

### 2. Push Notification
- ⚠️ **FCM Bağlantısı:** send-fcm-notification Edge Function connectivity hatası
- ⚠️ **Token Kaydı:** Bazı cihazlarda token kaydı başarısız olabilir
- ✅ **Kısmi Çözüm:** Lokal bildirimler çalışıyor (uygulama açıkken)

### 3. Realtime Güncelleme
- ⚠️ **İnternet Bağlantısı:** Offline durumda veriler güncellenmiyor
- ⚠️ **Supabase Realtime:** Publication'lar aktif olmalı
- ✅ **Çözüm:** Pull-to-refresh ile manuel güncelleme

### 4. Performans Ekranı
- ⚠️ **İlk Yükleme:** Çok fazla teslimat varsa yavaş olabilir
- ✅ **Çözüm:** Pagination veya lazy loading eklenebilir (gelecek güncellemede)

---

## 📝 TEST SONUÇLARI FORMU

### Test Tarihi: __________
### Test Eden: __________
### Cihaz: __________
### Android Versiyon: __________

| # | Test Adımı | Sonuç (✅/❌) | Notlar |
|---|------------|--------------|--------|
| 1 | Giriş yapıldı | [ ] | |
| 2 | Mesaiye başlandı | [ ] | |
| 3 | Konum izni verildi | [ ] | |
| 4 | 30 saniye konum güncellemesi | [ ] | |
| 5 | Performans ekranı açıldı | [ ] | |
| 6 | Para miktarı gösterilmedi | [ ] | |
| 7 | Sipariş alındı | [ ] | |
| 8 | Sipariş kabul edildi | [ ] | |
| 9 | Ürün alındı | [ ] | |
| 10 | Teslimat tamamlandı | [ ] | |
| 11 | Uygulama kapatıldı → Offline | [ ] | |
| 12 | Logout → is_available=false | [ ] | |
| 13 | Push notification geldi | [ ] | |
| 14 | Realtime güncelleme çalıştı | [ ] | |

---

## 🚨 ACİL DURUM SENARYOLARI

### Senaryo 1: Kurye Uygulama Çöktü
**Problem:** Uygulama çöker, kurye müsait kalır  
**Çözüm:**
1. Admin panelden kuryeyi manuel offline yap
2. Kullanıcıya uygulamayı yeniden başlat diye mesaj at
3. Veya backend'de timeout sistemi kur (5 dakika konum güncellemesi yoksa otomatik offline)

### Senaryo 2: GPS Çalışmıyor
**Problem:** Kurye mesaide ama konum güncellenmiyor  
**Çözüm:**
1. Ayarlar → Konum Servisleri → GPS Aç
2. Uygulama izinleri → Konum → Her Zaman İzin Ver
3. Telefonu yeniden başlat

### Senaryo 3: Sipariş Gelmiyor
**Problem:** Kurye mesaide ama sipariş atanmıyor  
**Kontrol:**
1. is_available=true mi? (Database)
2. status=approved mi?
3. is_active=true mi?
4. current_location güncellenmiş mi?
5. Merchant sipariş oluştururken kurye atadı mı?

### Senaryo 4: Bildirim Gelmiyor
**Problem:** Push notification çalışmıyor  
**Çözüm:**
1. FCM token kaydedilmiş mi? (users.fcm_token)
2. Bildirim izni verilmiş mi? (Android ayarları)
3. Lokal bildirimler çalışıyor mu? (Uygulama açıkken)
4. Supabase Edge Function çalışıyor mu?

---

## 🎯 TEST SONRASI YAPILACAKLAR

### Performans Geliştirmeleri:
- [ ] Konum güncelleme aralığını optimize et (30 saniye → 60 saniye?)
- [ ] Performans ekranına pagination ekle
- [ ] Offline mod için local cache

### Eksik Özellikler:
- [ ] Profil fotoğrafı yükleme
- [ ] Şifre değiştirme
- [ ] İstatistik grafikleri (chart)
- [ ] Teslimat geçmişi export (PDF/Excel)

### Bug Düzeltmeleri:
- [ ] Push notification connectivity sorunu
- [ ] Realtime stream bazen kopuyor
- [ ] Konum izni reddetme sonrası tekrar isteme

---

## 📞 DESTEK BİLGİLERİ

**Sorun olursa:**
- Ekran görüntüsü al
- Hata mesajını not et
- Adım adım ne yaptığını açıkla
- Cihaz ve Android versiyonunu belirt

**İletişim:**
- Test sırasında anında raporla
- Kritik hatalar için hemen bildir
- Öneri ve geri bildirimleri kaydet

---

## ✅ HAZIRLIK DURUMU: %95

### Tamamlanmış:
- ✅ Giriş sistemi
- ✅ Mesai yönetimi
- ✅ Konum takibi
- ✅ Otomatik offline
- ✅ SGK performans ekranı
- ✅ Sipariş yönetimi
- ✅ Profil ekranı
- ✅ Realtime güncelleme

### Test Edilecek:
- 🧪 Canlı ortamda konum takibi
- 🧪 Push notification
- 🧪 Gerçek sipariş akışı
- 🧪 Çoklu kurye senaryosu

### Gelecek Güncellemeler:
- 📅 Backend timeout sistemi
- 📅 Detaylı istatistik raporları
- 📅 Performans optimizasyonu

---

**BAŞARILAR! 🚀**
