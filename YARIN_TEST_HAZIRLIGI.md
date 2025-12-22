# 🎯 YARIN TESTİ İÇİN HAZIR MI? - HİZLI KONTROL

## ✅ HAZIR OLAN HER ŞEY

### 📦 APK
- ✅ **Dosya:** `c:\onlog_projects\onlog_courier_app\build\app\outputs\flutter-apk\app-release.apk`
- ✅ **Boyut:** 65.6 MB
- ✅ **Tarih:** 31 Ekim 2025
- ✅ **Son Değişiklik:** Login'de otomatik is_available=true kaldırıldı

### 🔐 TEST KULLANICILARI
Supabase'de hazır SGK kurye hesapları:
- Email: sgk1@test.com (varsa)
- Email: sgk2@test.com (varsa)
- **Kontrol Et:** Admin panelden "Kullanıcı Yönetimi" → Kuryeler

### 📱 UYGULAMA ÖZELLİKLERİ

#### 1. Giriş Sistemi ✅
- Email/Şifre ile giriş
- Onay durumu kontrolü (pending/approved/rejected)
- ~~Otomatik is_available=true~~ ❌ KALDIRILDI
- Manuel "Mesaiye Başla" gerekli ✅

#### 2. SGK Kurye Özellikleri ✅
- **3 Sekme:**
  1. 🏠 Teslimatlar
  2. 📊 Performans (❌ para yok, ✅ bonus var)
  3. 👤 Profil
- **Kazançlar sekmesi YOK** ✅

#### 3. Mesai Yönetimi ✅
- "Mesaiye Başla" butonu
- Konum izni talebi
- is_available=true yapma
- 30 saniye konum güncellemesi
- "Mesaiden Çık" butonu
- is_available=false yapma

#### 4. Konum Takibi ✅
- GPS konum alma
- 30 saniye aralık
- current_location JSONB
- Sadece mesaide çalışır

#### 5. Otomatik Offline ✅
- Uygulama kapanınca
- Arka plana alınınca
- Logout yapılınca
- is_available=false olur

#### 6. Performans Ekranı ✅
- Günlük/Haftalık/Aylık teslimatlar
- Başarı oranı (%)
- 5 seviyeli bonus sistemi:
  - 🌱 Başlangıç (0-49)
  - 🥉 Bronz (50-99)
  - 🥈 Gümüş (100-149)
  - 🥇 Altın (150-199)
  - ⭐ Platin (200+)
- ❌ Para miktarı yok

#### 7. Sipariş Yönetimi ✅
- Realtime liste
- Sipariş kabul et
- Ürünü aldım
- Teslimat fotoğrafı
- Teslim edildi

---

## 📝 YARINKI TEST ADIMLAR

### Sabah 9:00 - Hazırlık
1. [ ] APK'yı WhatsApp'tan kuryelere gönder
2. [ ] APK'yı telefonlara yükle
3. [ ] Admin panel aç (chrome)
4. [ ] Merchant panel aç (chrome)
5. [ ] Supabase dashboard aç (realtime takip için)

### 9:30 - İlk Test
1. [ ] SGK kurye 1 giriş yapsın
2. [ ] Ana sayfa açılsın
3. [ ] "Mesaiye Başla" butonunu görsün
4. [ ] Butona bassın → Konum izni istesin
5. [ ] İzin versin → "Mesaiden Çık" olsun
6. [ ] Admin panelde "Müsait" görünsün ✅

### 10:00 - Konum Testi
1. [ ] 30 saniye bekle
2. [ ] Supabase'de current_location güncellendi mi?
3. [ ] Admin panelde konum haritada değişti mi?
4. [ ] Kurye farklı yere gitsin
5. [ ] 30 saniye sonra yeni konum gelsin

### 10:30 - Sipariş Testi
1. [ ] Merchant panelden sipariş oluştur
2. [ ] Kuryeye sipariş ata
3. [ ] Courier app'te bildirim gelsin
4. [ ] Sipariş kartını görsün
5. [ ] "Kabul Et" bassın
6. [ ] "Ürünü Aldım" bassın
7. [ ] Fotoğraf yüklesin
8. [ ] "Teslim Edildi" bassın
9. [ ] Admin panelde ödeme transaction'ı kontrol et

### 11:00 - Performans Ekranı
1. [ ] "Performans" sekmesine gitsin
2. [ ] Teslimat istatistiklerini görsün
3. [ ] Bonus seviyesini görsün
4. [ ] ❌ Hiçbir yerde para gösterilmesin
5. [ ] Aşağı çek yenile → Veriler güncellensin

### 11:30 - Otomatik Offline Test
1. [ ] Mesaide olduğundan emin ol
2. [ ] Admin panelde "Müsait" olduğunu doğrula
3. [ ] Uygulamayı kapat (home tuşu)
4. [ ] Admin panelde "Müsait Değil" olsun ✅
5. [ ] Uygulamayı tekrar aç
6. [ ] "Mesaiye Başla" butonunu görsün

### 12:00 - Çoklu Kurye Test
1. [ ] SGK kurye 2 de giriş yapsın
2. [ ] İkisi de mesaide olsun
3. [ ] Sipariş oluştur
4. [ ] En yakın kuryeye atansın
5. [ ] Diğer kurye bildirim almasın

### 12:30 - Logout Test
1. [ ] Profil sekmesine git
2. [ ] "Çıkış Yap" bas
3. [ ] Onay ver
4. [ ] Login ekranına dön
5. [ ] Admin panelde "Müsait Değil" kontrol et

---

## ⚠️ DİKKAT EDİLECEKLER

### Konum İçin:
- ✅ GPS açık olmalı
- ✅ Konum servisleri aktif
- ✅ Uygulama izinleri "Her Zaman İzin Ver"
- ✅ Batarya tasarrufu kapalı (uygulama için)

### Test İçin:
- ✅ İnternet bağlantısı stabil
- ✅ Admin panel hazır
- ✅ Supabase dashboard açık
- ✅ Ekran görüntüleri al (her adımda)
- ✅ Sorunları hemen not et

### SGK Kurye İçin:
- ❌ Para miktarları gösterilmemeli
- ✅ Bonus seviyesi görünmeli
- ✅ İstatistikler doğru olmalı
- ✅ Performans sekmesi çalışmalı

---

## 🚨 SORUN OLURSA

### Problem 1: Konum Güncellenmiyor
**Kontrol:**
- GPS açık mı?
- Konum izni verilmiş mi?
- Mesaide mi? (is_available=true)
- 30 saniye beklendi mi?

**Çözüm:**
1. Ayarlar → Konum → GPS Aç
2. Uygulama izinleri → Konum → Her Zaman
3. "Mesaiden Çık" + "Mesaiye Başla" tekrar dene

### Problem 2: Sipariş Gelmiyor
**Kontrol:**
- Kurye mesaide mi?
- status=approved mi?
- is_active=true mi?
- Merchant sipariş kuryeye attı mı?

**Çözüm:**
1. Admin panelden kurye durumunu kontrol et
2. Mesaiye başla butonu tekrar
3. Sipariş atamayı tekrar yap

### Problem 3: Performans Ekranı Boş
**Kontrol:**
- Daha önce teslimat yapılmış mı?
- Deliveries tablosunda veri var mı?

**Çözüm:**
1. En az 1 teslimat yap
2. Aşağı çek yenile
3. Supabase'den deliveries tablosunu kontrol et

### Problem 4: Uygulama Çöktü
**Kontrol:**
- Android versiyonu uyumlu mu?
- Yeterli RAM var mı?
- APK yükleme başarılı mı?

**Çözüm:**
1. Uygulamayı kapat
2. Cache temizle
3. Uygulamayı tekrar aç
4. Olmadı → Yeniden yükle

---

## 📊 BAŞARI KRİTERLERİ

Test başarılı sayılması için:

- ✅ Mesai sistemi sorunsuz çalışmalı
- ✅ Konum 30 saniyede güncellemeli
- ✅ SGK kurye para görmemeli
- ✅ Performans ekranı çalışmalı
- ✅ Sipariş akışı tamamlanmalı
- ✅ Otomatik offline çalışmalı
- ✅ Logout is_available=false yapmalı

---

## 📸 DOKÜMANTASYON

Her test adımında:
1. Ekran görüntüsü al
2. Admin panel screenshot
3. Supabase database screenshot
4. Sorunları not et

Test sonunda:
- Başarılı: ✅ İşaretle
- Başarısız: ❌ İşaretle + Neden yaz
- Kısmi: ⚠️ İşaretle + Detay ver

---

## ✅ SON KONTROL LİSTESİ

### Gece Öncesi Hazırlık:
- [ ] APK'yı test et (senin telefonunda)
- [ ] Test kullanıcılarının email/şifrelerini hazırla
- [ ] Admin panel login bilgileri hazır
- [ ] Supabase dashboard erişimi doğrula
- [ ] Internet bağlantısını kontrol et

### Sabah Hazırlık:
- [ ] APK'yı gönder
- [ ] Kuryelere yükle
- [ ] Admin panel aç
- [ ] Merchant panel aç
- [ ] Supabase dashboard aç
- [ ] Test dökümanlarını hazırla

---

## 🎯 HEDEF

**Yarın sonunda:**
- 2 SGK kurye sorunsuz çalışmalı
- Mesai sistemi test edilmiş olmalı
- Konum takibi doğrulanmış olmalı
- SGK performans ekranı test edilmiş olmalı
- En az 5 başarılı teslimat yapılmış olmalı

---

**HER ŞEY HAZIR! BAŞARILAR! 🚀**

APK Yolu: `c:\onlog_projects\onlog_courier_app\build\app\outputs\flutter-apk\app-release.apk`
