# 🔐 Teslimat Doğrulama Sistemi

## Sorun
Kurye + Merchant anlaşıp sistem dışı para kazanabilir:
- Merchant 150 TL'lik siparişi 100 TL olarak kaydeder
- 50 TL'yi kurye ile bölüşürler
- Sistem sadece 100 TL'den komisyon alır

## Çözümler

### 1. QR Kod Doğrulama Sistemi ✅
**Nasıl Çalışır:**
- Merchant sipariş oluşturduğunda **QR kod** üretilir
- QR kodda: Sipariş ID + Tutar + Hash (şifreli)
- Kurye teslim ederken QR'ı taratır
- Sistem tutar eşleşmesini kontrol eder

**Avantaj:** Tutar değiştirilemez
**Dezavantaj:** Merchant QR'ı paylaşmayabilir

### 2. Fotoğraf + İmza Zorunluluğu ✅
**Nasıl Çalışır:**
- Kurye teslimat sırasında:
  1. Ürün fotoğrafı çeker (timestamp + GPS etiketli)
  2. Müşteri imzası alır
  3. Tahsil edilen tutarı girer
- Admin panelde tüm fotoğraflar görülür

**Avantaj:** Delil oluşur
**Dezavantaj:** Zaman alır

### 3. GPS Lokasyon Kontrolü ✅
**Nasıl Çalışır:**
- Kurye "Teslim Edildi" dediğinde GPS konumu kaydedilir
- Merchant adresine 100m içinde olmalı
- Uzakta teslim ederse şüpheli işaretlenir

**Avantaj:** Sahte teslimatı engeller
**Dezavantaj:** GPS yanılabilir (bina içi)

### 4. Admin Manuel Onay (Riskli Teslimatlar) ✅
**Nasıl Çalışır:**
- Şüpheli durumlar:
  - GPS 100m dışında
  - Aynı merchant + kurye çok sık teslimat
  - Tutar ortalamanın altında
- Bu teslimatlar "pending_review" durumuna geçer
- Admin onaylayana kadar ödeme yapılmaz

**Avantaj:** İnsan kontrolü
**Dezavantaj:** Gecikme yaratır

### 5. Müşteri SMS Doğrulaması (En Güçlü) ✅
**Nasıl Çalışır:**
- Müşteriye teslimat öncesi SMS: "150 TL ödenecek, doğrula: EVET/HAYIR"
- Müşteri EVET derse kurye teslim edebilir
- Müşteri farklı tutar belirtirse alarm

**Avantaj:** Müşteri de doğrular
**Dezavantaj:** SMS maliyeti, bazı müşteriler cevap vermez

## Önerilen Sistem (Hepsi Birlikte)

### Teslimat Akışı:
1. **Merchant sipariş oluşturur** → QR kod + tutar kaydedilir
2. **Kurye siparişi alır** → GPS takip başlar
3. **Teslim noktasına varır** → GPS kontrol (100m içinde mi?)
4. **QR kodu taratır** → Tutar eşleşmesi kontrol
5. **Fotoğraf çeker** → Ürün + müşteri fotoğrafı
6. **Müşteri imzalar** → Dijital imza
7. **Tahsil edilen tutarı girer** → QR'daki tutarla eşleşmeli
8. **Sistem kontrol eder:**
   - GPS uygun mu? ✓
   - QR tutar eşleşiyor mu? ✓
   - Fotoğraf var mı? ✓
   - İmza var mı? ✓
9. **Eğer hepsi OK:** Otomatik onay, ödeme yapılır
10. **Eğer şüpheli:** Admin onayı bekler

## Teknik Uygulama

### 1. QR Kod Oluşturma (Merchant Panel)
```dart
// Sipariş oluştururken
final qrData = {
  'order_id': orderId,
  'amount': declaredAmount,
  'merchant_id': merchantId,
  'hash': sha256('$orderId-$declaredAmount-SECRET_KEY'),
};
final qrCode = QrCode.generate(jsonEncode(qrData));
```

### 2. QR Kod Okuma (Courier App)
```dart
// Teslim ekranında
final scannedData = await BarcodeScanner.scan();
final orderData = jsonDecode(scannedData);
if (orderData['hash'] != sha256('${orderData['order_id']}-${orderData['amount']}-SECRET_KEY')) {
  throw 'Geçersiz QR kod!';
}
```

### 3. GPS Kontrol (Backend Trigger)
```sql
CREATE OR REPLACE FUNCTION validate_delivery_location()
RETURNS TRIGGER AS $$
DECLARE
  merchant_location GEOGRAPHY;
  delivery_location GEOGRAPHY;
  distance_meters NUMERIC;
BEGIN
  -- Merchant lokasyonunu al
  SELECT location INTO merchant_location
  FROM users
  WHERE id = NEW.merchant_id;
  
  -- Teslimat lokasyonunu oluştur
  delivery_location := ST_SetSRID(ST_MakePoint(NEW.delivery_longitude, NEW.delivery_latitude), 4326)::geography;
  
  -- Mesafeyi hesapla
  distance_meters := ST_Distance(merchant_location, delivery_location);
  
  -- 100m'den uzaksa şüpheli işaretle
  IF distance_meters > 100 THEN
    NEW.status := 'pending_review';
    NEW.review_reason := 'GPS lokasyon uyuşmazlığı: ' || distance_meters || 'm';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 4. Şüpheli Teslimat Algılama (SQL)
```sql
-- Aynı merchant + kurye çok sık teslimat
SELECT merchant_id, courier_id, COUNT(*) as delivery_count
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '7 days'
  AND status = 'delivered'
GROUP BY merchant_id, courier_id
HAVING COUNT(*) > 20; -- Haftada 20'den fazla şüpheli

-- Ortalamanın altında tutar
SELECT AVG(declared_amount) as avg_amount FROM delivery_requests;
-- Eğer yeni teslimat average'ın %50'sinden azsa şüpheli
```

## Sonuç
**Hepsini birlikte kullan:**
- QR Kod → Tutar değiştirilemez
- GPS → Sahte teslimat engellenir
- Fotoğraf + İmza → Delil oluşur
- Admin Onay → İnsan kontrolü
- Müşteri SMS (opsiyonel) → Müşteri de doğrular

**Maliyet:** Orta (SMS hariç ücretsiz)
**Güvenlik:** Çok yüksek
**Kullanıcı Deneyimi:** Kabul edilebilir (30 sn ekstra süre)
