#  ONLOG - Kurye Teslimat Süreçleri & Webhook Akışı

**Tarih:** 15 Aralık 2025  
**Amaç:** Yemek App entegrasyonu için kurye tarafındaki tüm süreçleri netleştirmek

---

##  TESLİMAT DURUMLARI (Status Flow)

WAITING_COURIER  ASSIGNED  ACCEPTED  PICKED_UP  DELIVERED
                                          
                  REJECTED  CANCELLED  CANCELLED

---

##  SÜREÇ DETAYI: BAŞTAN SONA

### 1 YENİ TESLİMAT TALEBİ GELDİ
**Durum:** WAITING_COURIER

**Ne Oluyor:**
- Yemek App webhook ile teslimat talebi gönderiyor
- delivery_requests tablosuna kayıt ekleniyor
- source: 'yemek_app', external_order_id: 'KURYE-12345'
- Otomatik kurye ataması başlıyor (3 deneme hakkı)

**Webhook Gerekli Mi?**  HAYIR (henüz kurye atanmadı)

---

### 2 KURYEYE ATANDI (Otomatik Atama)
**Durum:** ASSIGNED

**Ne Oluyor:**
- Sistem yakındaki uygun kuryeyi buluyor
- courier_id atanıyor
- Kuryeye PUSH notification gidiyor
- Kurye uygulamasında Yeni Teslimat İsteği gösteriliyor

**Kurye Seçenekleri:**
1.  KABUL ET  Durum ACCEPTED'e geçer
2.  REDDET  Ret nedeni seçmesi gerekir

**Webhook Gerekli Mi?**  HAYIR (kurye henüz karar vermedi)

---

### 3 KURYE REDDETTİ
**Durum:** ASSIGNED  Yeni kurye aranıyor

**Ret Nedenleri:**
-  Adres Hatalı/Bulunamıyor
-  Müşteriye Ulaşılamıyor
-  Çok Uzak/Zamanım Yok
-  Paket Hasarlı
-  Diğer

**Ne Oluyor:**
- rejection_reason kaydediliyor
- rejection_count artırılıyor
- Otomatik yeni kurye atanıyor (max 3 deneme)
- Yeni kurye bulunursa tekrar ASSIGNED oluyor

**Webhook Gerekli Mi?** 
-  İlk 2 ret: HAYIR (yeni kurye deneniyor)
-  3. ret: EVET!  courier_not_found bildirimi göndermek lazım

---

### 4 KURYE KABUL ETTİ
**Durum:** ACCEPTED

**Ne Oluyor:**
- Kurye Kabul Et butonuna basıyor
- Durum ACCEPTED'e geçiyor
- Kurye artık teslimatı yapmaya başlayabilir
- Teslimat detayları ekranına gidiyor

**Kurye Seçenekleri:**
1.  Siparişi Al  Durum PICKED_UP'a geçer
2.  Sorun Bildir  Problem raporu oluşturur (durum değişmez)
3.  İptal Et  Durum CANCELLED'a geçer

**Webhook Gerekli Mi?**  EVET! 
{
  external_order_id: KURYE-12345,
  status: accepted,
  courier_name: Ahmet Kuryeci,
  courier_phone: +905551234567,
  estimated_pickup_time: 10-15 dakika,
  message: Kurye siparişinizi almak üzere yola çıktı
}

---

### 5 SORUN BİLDİRİMİ (İsteğe Bağlı)
**Durum:** Değişmez (arka planda problem kaydedilir)

**Sorun Tipleri:**
-  Adres Yanlış/Eksik
-  Müşteri Telefonu Çalışmıyor
-  Müşteri Evde Yok
-  Paket Bilgisi Uyuşmuyor
-  Ödeme Sorunu
-  Araç Arızası
-  Diğer

**Ne Oluyor:**
- delivery_problems tablosuna kayıt ekleniyor
- Kurye isteğe bağlı not ekleyebiliyor
- Destek ekibi bilgilendiriliyor
- Teslimat devam ediyor (iptal olmuyor)

**Webhook Gerekli Mi?**  OPSIYONEL
- Kritik sorunlarda bildirmek mantıklı (ör: müşteri evde yok, adres hatalı)
- İç sorunlarda gerek yok (ör: araç arızası)

---

### 6 SİPARİŞ ALINDI
**Durum:** PICKED_UP

**Ne Oluyor:**
- Kurye restaurant/işletmeye varıyor
- Siparişi Al butonuna basıyor
- Durum PICKED_UP'a geçiyor
- Kurye artık teslim adresine gidiyor

**Kurye Seçenekleri:**
1.  Teslim Et  Durum DELIVERED'a geçer
2.  Sorun Bildir  Problem raporu (durum değişmez)
3.  İptal Et  Durum CANCELLED'a geçer

**Webhook Gerekli Mi?**  EVET!
{
  external_order_id: KURYE-12345,
  status: picked_up,
  courier_name: Ahmet Kuryeci,
  courier_phone: +905551234567,
  estimated_delivery_time: 20-25 dakika,
  message: Sipariş kurye tarafından alındı, teslimata çıkıyor
}

---

### 7 TESLİM EDİLDİ
**Durum:** DELIVERED

**Ne Oluyor:**
- Kurye müşteriye ulaşıyor
- Teslim fotoğrafı çekiyor (zorunlu)
- Tahsil edilen tutarı giriyor
- Teslim Et butonuna basıyor
- Durum DELIVERED'a geçiyor
- OTOMATİK ÖDEME SİSTEMİ ÇALIŞIYOR:
  - Komisyon hesaplanıyor (%15 + 2 TL + %18 KDV)
  - Merchant cüzdanına ücret ekleniyor
  - Kurye cüzdanına teslimat ücreti ekleniyor
  - payment_transactions kayıtları oluşturuluyor

**Webhook Gerekli Mi?**  EVET! (EN ÖNEMLİ)
{
  external_order_id: KURYE-12345,
  status: delivered,
  courier_name: Ahmet Kuryeci,
  courier_phone: +905551234567,
  delivered_at: 2025-12-15T10:48:23Z,
  collected_amount: 219.00,
  payment_method: cash,
  delivery_photo_url: https://oilldfyywtzybrmpyixx.supabase.co/storage/v1/object/public/delivery-photos/abc123.jpg,
  message: Sipariş başarıyla teslim edildi
}

---

### 8 İPTAL EDİLDİ
**Durum:** CANCELLED

**İptal Sebepleri:**
- Kurye istedi (kabul ettikten sonra)
- Müşteri istedi (merchant panel üzerinden)
- Merchant istedi
- Sistem otomatik iptal etti (timeout vs)

**Ne Oluyor:**
- cancellation_reason kaydediliyor
- cancelled_by kaydediliyor (courier/merchant/customer/system)
- cancelled_at timestamp ekleniyor
- Teslimat tamamlanmış sayılmıyor

**Webhook Gerekli Mi?**  EVET!
{
  external_order_id: KURYE-12345,
  status: cancelled,
  cancelled_by: courier,
  cancellation_reason: Müşteri evde yok, ulaşılamıyor,
  cancelled_at: 2025-12-15T10:30:00Z,
  message: Teslimat iptal edildi
}

---

##  WEBHOOK GÖNDERİM KURALLARI

###  Webhook Gönderilmesi GEREKEN Durumlar:

1. ACCEPTED - Kurye kabul etti
2. PICKED_UP - Sipariş alındı
3. DELIVERED - Teslim edildi (EN ÖNEMLİ!)
4. CANCELLED - İptal edildi
5. COURIER_NOT_FOUND - 3 kurye de reddetti (özel durum)

###  Webhook Gönderilmemesi GEREKEN Durumlar:

1. WAITING_COURIER - Henüz kurye atanmadı
2. ASSIGNED - Kurye atandı ama henüz karar vermedi
3. REJECTED (ilk 2 deneme) - Yeni kurye deneniyor

###  Opsiyonel Webhook Durumları:

1. PROBLEM_REPORTED - Kritik sorunlarda bildirilebilir

---

##  OTOMATİK KURYE ATAMA SİSTEMİ

### Atama Algoritması:
1. Yakındaki kuryeler bulunuyor (2 km içinde)
2. Müsait olanlar filtreleniyor (is_available = true)
3. En yakın kurye seçiliyor
4. Kurye bilgilendir notification gönderiliyor
5. Beklenilen süre: 60 saniye (1 dakika)

### Red Senaryosu:
- 1. Red: Yeni kurye atanıyor (hemen)
- 2. Red: Yeni kurye atanıyor (hemen)
- 3. Red:  Webhook gönderiliyor: courier_not_found

### Webhook Payload (3. Red):
{
  external_order_id: KURYE-12345,
  status: courier_not_found,
  rejection_count: 3,
  message: Yakındaki 3 kurye de teslimatı reddetti,
  last_rejection_reason:  Çok Uzak/Zamanım Yok
}

---

##  SONRAKI ADIMLAR

1. Yemek App'ten webhook URL alın
2. onlog_merchant_mapping tablosuna ekleyin
3. Trigger'ı aktif edin (database function)
4. Test edin: Quick courier talebi  Kabul  Teslim  Webhook geldi mi?

HAZIR! 
