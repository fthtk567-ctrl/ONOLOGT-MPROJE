# 🔗 ONLOG - YEMEK APP ENTEGRASYON GÖREVLERİ

**Tarih:** 17 Kasım 2025  
**Proje:** Onlog Kurye & Merchant Sistemi  
**Amaç:** Yemek App platformundan gelen siparişleri Onlog sistemine entegre etmek

---

## 📋 GENEL BAKIŞ

### Ne Yapılacak?
Yemek App adında yeni bir yemek sipariş platformu, Onlog kurye sistemini kullanacak. Müşteriler Yemek App'ten sipariş verdiğinde, bu siparişler otomatik olarak Onlog sistemine düşecek ve restoran sahipleri Onlog Merchant Panel'den kurye çağırabilecek.

### Mevcut Durum
- ✅ Onlog zaten çalışıyor (Manuel kurye çağırma + Trendyol/Getir entegrasyonu)
- ✅ Supabase kullanılıyor (PostgreSQL + Realtime)
- ✅ 3 uygulama: Merchant Panel, Courier App, Admin Panel

### Hedef Durum
- ✅ Yemek App siparişleri otomatik Onlog'a düşsün
- ✅ Restoran sahibi Merchant Panel'de görsün
- ✅ Manuel kurye çağırma aynı kalsın (değişiklik yok)
- ✅ Durum güncellemeleri Yemek App'e geri gönderilsin

---

## 🎯 GÖREV 1: DATABASE ŞEMASI GÜNCELLEMESİ

### Açıklama
`delivery_requests` tablosuna 2 yeni sütun eklenecek. Bu sayede:
- Hangi platformdan geldiğini biliyoruz (source)
- Dış platformdaki sipariş numarasını takip ediyoruz (external_order_id)

### SQL Kodu
Onlog Supabase Dashboard → SQL Editor → Yeni sorgu oluştur → Aşağıdaki kodu yapıştır → Çalıştır

```sql
-- ======================================================================
-- DELIVERY_REQUESTS TABLOSUNA YENİ SÜTUNLAR EKLEME
-- ======================================================================

-- 1. Sütunları ekle
ALTER TABLE delivery_requests 
  ADD COLUMN IF NOT EXISTS external_order_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS source VARCHAR(50) DEFAULT 'manual';

-- 2. Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_external_order_id 
  ON delivery_requests(external_order_id);

CREATE INDEX IF NOT EXISTS idx_source 
  ON delivery_requests(source);

CREATE INDEX IF NOT EXISTS idx_source_status 
  ON delivery_requests(source, status);

-- 3. Dökümantasyon (yorum)
COMMENT ON COLUMN delivery_requests.external_order_id IS 
  'Dış platform sipariş numarası (örn: YO-4521, TR-1234)';

COMMENT ON COLUMN delivery_requests.source IS 
  'Sipariş kaynağı: manual (elle girilen), yemek_app, trendyol, getir';

-- 4. Varsayılan değerleri ayarla (mevcut kayıtlar için)
UPDATE delivery_requests 
SET source = 'manual' 
WHERE source IS NULL;

-- 5. Doğrulama (kontrol et)
SELECT 
  column_name, 
  data_type, 
  column_default, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'delivery_requests' 
  AND column_name IN ('external_order_id', 'source');

-- Başarılıysa şunu göreceksin:
-- external_order_id | character varying | NULL | YES
-- source            | character varying | 'manual'::character varying | YES
```

**Beklenen Çıktı:**
```
ALTER TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
COMMENT
COMMENT
UPDATE 1234
```

---

## 🎯 GÖREV 2: WEBHOOK TRIGGER OLUŞTURMA

### Açıklama
Delivery durumu değiştiğinde (örn: assigned → picked_up → delivered) otomatik olarak Yemek App'e bildirim gönderecek trigger ekliyoruz.

**Önemli:** Bu sadece `source = 'yemek_app'` olan kayıtlar için çalışır. Manuel siparişlere dokunmaz!

### SQL Kodu

```sql
-- ======================================================================
-- WEBHOOK TRİGGER: Durum değiştiğinde Yemek App'e bildir
-- ======================================================================

-- 1. Webhook gönderen fonksiyon oluştur
CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  http_response RECORD;
BEGIN
  -- Sadece harici platformlardan gelen siparişler için çalış
  IF NEW.source IS NOT NULL AND NEW.source != 'manual' THEN
    
    -- Platform'a göre webhook URL'i belirle
    CASE NEW.source
      WHEN 'yemek_app' THEN
        -- ⚠️ DİKKAT: Bu URL'i Yemek App ekibi verecek!
        -- Geçici olarak boş bırakıldı, gerçek URL geldiğinde güncellenecek
        webhook_url := 'https://YEMEK_APP_SUPABASE_PROJECT_ID.supabase.co/functions/v1/onlog-status-update';
      
      WHEN 'trendyol' THEN
        webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
      
      WHEN 'getir' THEN
        webhook_url := 'https://api.getir.com/webhook/delivery-status';
      
      ELSE
        webhook_url := NULL;
    END CASE;
    
    -- Webhook varsa gönder
    IF webhook_url IS NOT NULL AND webhook_url != 'https://YEMEK_APP_SUPABASE_PROJECT_ID.supabase.co/functions/v1/onlog-status-update' THEN
      
      -- Gönderilecek veri paketini hazırla
      payload := jsonb_build_object(
        'delivery_id', NEW.id,
        'external_order_id', NEW.external_order_id,
        'status', NEW.status,
        'courier_id', NEW.courier_id,
        'courier_name', (SELECT owner_name FROM users WHERE id = NEW.courier_id),
        'updated_at', NEW.updated_at,
        'source', NEW.source
      );
      
      -- HTTP POST isteği gönder
      SELECT * INTO http_response FROM net.http_post(
        url := webhook_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Onlog-Source', 'onlog_webhook',
          'X-Onlog-Event', 'delivery_status_changed'
        ),
        body := payload::text
      );
      
      -- Loglama (opsiyonel - debug için)
      RAISE NOTICE 'Webhook sent to % for delivery %: status=%', 
        NEW.source, NEW.id, http_response.status;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Eski trigger varsa sil
DROP TRIGGER IF EXISTS trigger_notify_external_platform ON delivery_requests;

-- 3. Yeni trigger oluştur
CREATE TRIGGER trigger_notify_external_platform
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  WHEN (
    OLD.status IS DISTINCT FROM NEW.status  -- Sadece durum değiştiğinde
  )
  EXECUTE FUNCTION notify_external_platform_on_status_change();

-- 4. Doğrulama (kontrol et)
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table, 
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_external_platform';

-- Başarılıysa trigger bilgilerini göreceksin
```

**⚠️ ÖNEMLİ NOT:** 
Webhook URL'i şu an placeholder. Yemek App ekibi gerçek URL'i verdiğinde, aşağıdaki komutu çalıştırarak güncelleyebilirsin:

```sql
-- Webhook URL'i güncelleme (Yemek App URL'i geldiğinde)
CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
-- ... fonksiyonun tamamını kopyala-yapıştır, sadece URL'i değiştir
```

---

## 🎯 GÖREV 3: MODEL SINIFI GÜNCELLEMESİ

### Açıklama
`DeliveryRequest` model sınıfına yeni alanlar ekliyoruz. Bu sayede Flutter uygulamaları yeni verileri okuyabilir.

### Dosya Yolu
```
onlog_shared/lib/models/delivery_request.dart
```

### Kod Değişikliği

**MEVCUT KOD (Bulunacak satır ~15-30):**
```dart
class DeliveryRequest {
  final String id;
  final String merchantId;
  final String? courierId;
  final int packageCount;
  final double declaredAmount;
  final double merchantPaymentDue;
  final double courierPaymentDue;
  final String status;
  final Map<String, dynamic>? pickupLocation;
  final Map<String, dynamic>? deliveryLocation;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeliveryRequest({
    required this.id,
    required this.merchantId,
    this.courierId,
    required this.packageCount,
    required this.declaredAmount,
    required this.merchantPaymentDue,
    required this.courierPaymentDue,
    required this.status,
    this.pickupLocation,
    this.deliveryLocation,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });
```

**YENİ KOD (Değiştirilecek):**
```dart
class DeliveryRequest {
  final String id;
  final String merchantId;
  final String? courierId;
  final int packageCount;
  final double declaredAmount;
  final double merchantPaymentDue;
  final double courierPaymentDue;
  final String status;
  final Map<String, dynamic>? pickupLocation;
  final Map<String, dynamic>? deliveryLocation;
  final String? notes;
  
  // ⭐ YENİ ALANLAR
  final String? externalOrderId;  // Yemek App sipariş no (YO-4521)
  final String source;            // 'manual', 'yemek_app', 'trendyol'
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeliveryRequest({
    required this.id,
    required this.merchantId,
    this.courierId,
    required this.packageCount,
    required this.declaredAmount,
    required this.merchantPaymentDue,
    required this.courierPaymentDue,
    required this.status,
    this.pickupLocation,
    this.deliveryLocation,
    this.notes,
    
    // ⭐ YENİ PARAMETRELER
    this.externalOrderId,
    this.source = 'manual',  // Varsayılan değer
    
    required this.createdAt,
    this.updatedAt,
  });
```

**fromJson metodunu da güncelle (Bulunacak satır ~60-80):**

**MEVCUT KOD:**
```dart
factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
  return DeliveryRequest(
    id: json['id'],
    merchantId: json['merchant_id'],
    courierId: json['courier_id'],
    packageCount: json['package_count'],
    declaredAmount: (json['declared_amount'] as num).toDouble(),
    merchantPaymentDue: (json['merchant_payment_due'] as num).toDouble(),
    courierPaymentDue: (json['courier_payment_due'] as num).toDouble(),
    status: json['status'],
    pickupLocation: json['pickup_location'],
    deliveryLocation: json['delivery_location'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: json['updated_at'] != null 
      ? DateTime.parse(json['updated_at']) 
      : null,
  );
}
```

**YENİ KOD:**
```dart
factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
  return DeliveryRequest(
    id: json['id'],
    merchantId: json['merchant_id'],
    courierId: json['courier_id'],
    packageCount: json['package_count'],
    declaredAmount: (json['declared_amount'] as num).toDouble(),
    merchantPaymentDue: (json['merchant_payment_due'] as num).toDouble(),
    courierPaymentDue: (json['courier_payment_due'] as num).toDouble(),
    status: json['status'],
    pickupLocation: json['pickup_location'],
    deliveryLocation: json['delivery_location'],
    notes: json['notes'],
    
    // ⭐ YENİ ALANLAR
    externalOrderId: json['external_order_id'],
    source: json['source'] ?? 'manual',
    
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: json['updated_at'] != null 
      ? DateTime.parse(json['updated_at']) 
      : null,
  );
}
```

**toJson metodunu da güncelle (Bulunacak satır ~85-105):**

**MEVCUT KOD:**
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'merchant_id': merchantId,
    'courier_id': courierId,
    'package_count': packageCount,
    'declared_amount': declaredAmount,
    'merchant_payment_due': merchantPaymentDue,
    'courier_payment_due': courierPaymentDue,
    'status': status,
    'pickup_location': pickupLocation,
    'delivery_location': deliveryLocation,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
```

**YENİ KOD:**
```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'merchant_id': merchantId,
    'courier_id': courierId,
    'package_count': packageCount,
    'declared_amount': declaredAmount,
    'merchant_payment_due': merchantPaymentDue,
    'courier_payment_due': courierPaymentDue,
    'status': status,
    'pickup_location': pickupLocation,
    'delivery_location': deliveryLocation,
    'notes': notes,
    
    // ⭐ YENİ ALANLAR
    'external_order_id': externalOrderId,
    'source': source,
    
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
```

---

## 🎯 GÖREV 4: MERCHANT PANEL UI - KAYNAK BADGE'İ

### Açıklama
Restoran sahibi "Bu sipariş nereden geldi?" görebilsin diye UI'a renkli badge ekliyoruz.

**Görsel:**
```
┌─────────────────────────────────────┐
│ 🍕 YEMEK APP  YO-4521               │ ← Turuncu badge
├─────────────────────────────────────┤
│ Teslimat #12345                     │
│ 2 paket - 350₺                      │
│ [Kurye Çağır]                       │
└─────────────────────────────────────┘
```

### Dosya 1: Delivery Card Widget

**Dosya Yolu:**
```
onlog_merchant_panel/lib/widgets/delivery_card.dart
```

**Tam dosyayı şöyle değiştir:**

```dart
import 'package:flutter/material.dart';
import 'package:onlog_shared/models/delivery_request.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryRequest delivery;
  final VoidCallback onCallCourier;
  final VoidCallback? onViewDetails;

  const DeliveryCard({
    Key? key,
    required this.delivery,
    required this.onCallCourier,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ KAYNAK BADGE'İ (Yeni eklendi)
          if (delivery.source != 'manual')
            _buildSourceBadge(),
          
          // Mevcut içerik
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teslimat bilgileri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Teslimat #${delivery.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  '${delivery.packageCount} paket - ${delivery.declaredAmount.toStringAsFixed(2)}₺',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                
                if (delivery.notes != null && delivery.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Not: ${delivery.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onViewDetails != null)
                      TextButton(
                        onPressed: onViewDetails,
                        child: const Text('Detay'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: delivery.status == 'pending' ? onCallCourier : null,
                      child: const Text('Kurye Çağır'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ YENİ METOD: Kaynak badge'i
  Widget _buildSourceBadge() {
    final sourceInfo = _getSourceInfo(delivery.source);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: sourceInfo['color'],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sourceInfo['icon'],
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            sourceInfo['label'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (delivery.externalOrderId != null) ...[
            const SizedBox(width: 8),
            Text(
              delivery.externalOrderId!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ⭐ YENİ METOD: Kaynak bilgileri
  Map<String, dynamic> _getSourceInfo(String source) {
    switch (source) {
      case 'yemek_app':
        return {
          'label': 'YEMEK APP',
          'color': const Color(0xFFFF6B35), // Turuncu
          'icon': Icons.restaurant_menu,
        };
      case 'trendyol':
        return {
          'label': 'TRENDYOL',
          'color': const Color(0xFFF27A1A),
          'icon': Icons.shopping_bag,
        };
      case 'getir':
        return {
          'label': 'GETİR',
          'color': const Color(0xFF5D3EBC),
          'icon': Icons.delivery_dining,
        };
      default:
        return {
          'label': source.toUpperCase(),
          'color': Colors.grey,
          'icon': Icons.help_outline,
        };
    }
  }

  // Mevcut metod (değişiklik yok)
  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (delivery.status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Bekliyor';
        break;
      case 'assigned':
        chipColor = Colors.blue;
        statusText = 'Atandı';
        break;
      case 'picked_up':
        chipColor = Colors.purple;
        statusText = 'Alındı';
        break;
      case 'delivered':
        chipColor = Colors.green;
        statusText = 'Teslim Edildi';
        break;
      default:
        chipColor = Colors.grey;
        statusText = delivery.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## 🎯 GÖREV 5: FCM BİLDİRİMİ GÜNCELLEMESİ

### Açıklama
Kurye'ye gelen bildirimde "Bu Yemek App siparişi" gösterilsin.

### Dosya Yolu
```
supabase/functions/send-notification-v2/index.ts
```

### Kod Değişikliği

**MEVCUT KOD (Bulunacak satır ~80-100):**
```typescript
const notificationPayload = {
  notification: {
    title: 'Yeni Teslimat!',
    body: `${merchantName} - ${packageCount} paket, ${declaredAmount} TL`,
  },
  data: {
    type: 'NEW_DELIVERY',
    deliveryId: deliveryRequest.id,
  },
  token: fcmToken,
}
```

**YENİ KOD:**
```typescript
// ⭐ Kaynak bilgisini al
const source = deliveryRequest.source || 'manual';
const externalOrderId = deliveryRequest.external_order_id;

// Başlık kaynağa göre değişsin
let title = 'Yeni Teslimat!';
if (source === 'yemek_app') {
  title = '🍕 Yemek App Teslimatı!';
} else if (source === 'trendyol') {
  title = '🛍️ Trendyol Teslimatı!';
} else if (source === 'getir') {
  title = '🛵 Getir Teslimatı!';
}

const notificationPayload = {
  notification: {
    title: title,  // ⭐ Dinamik başlık
    body: `${merchantName} - ${packageCount} paket, ${declaredAmount} TL`,
  },
  data: {
    type: 'NEW_DELIVERY',
    deliveryId: deliveryRequest.id,
    source: source,  // ⭐ Kaynak bilgisi
    externalOrderId: externalOrderId || '',  // ⭐ Dış sipariş no
  },
  token: fcmToken,
}
```

---

## 🎯 GÖREV 6: KURYE ATAMA SERVİSİ (OPSİYONEL)

### Açıklama
**Bu opsiyoneldir!** Yemek App siparişleri için sadece "yemek teslimatı yapabilen" kuryeler atansın isterseniz yapın.

### Dosya Yolu
```
onlog_shared/lib/services/courier_assignment_service.dart
```

### Kod Değişikliği

**MEVCUT KOD (findBestCourier metodu, satır ~25):**
```dart
static Future<String?> findBestCourier({
  required Map<String, dynamic> merchantLocation,
  required String merchantId,
}) async {
  // ... mevcut kod
}
```

**YENİ KOD:**
```dart
static Future<String?> findBestCourier({
  required Map<String, dynamic> merchantLocation,
  required String merchantId,
  String? source,  // ⭐ YENİ PARAMETRE
}) async {
  
  // ⭐ Yemek App için özel filtre (Opsiyonel)
  var query = SupabaseService.client
    .from('users')
    .select()
    .eq('role', 'courier')
    .eq('is_active', true)
    .eq('is_available', true)
    .eq('is_busy', false)
    .eq('status', 'approved');
  
  // Eğer yemek siparişiyse, sadece yemek teslimatı yapanlar
  if (source == 'yemek_app') {
    // ⚠️ DİKKAT: Eğer users tablosunda 'delivery_type' sütunu yoksa bu satırı ekleme!
    // query = query.eq('delivery_type', 'food');  // 'all', 'food', 'package'
  }
  
  final response = await query;
  
  // ... geri kalan mevcut kod
}
```

**⚠️ NOT:** Bu sadece users tablosunda `delivery_type` sütunu varsa çalışır. Yoksa atlayabilirsin.

---

## ✅ TEST SENARYOSU

### Nasıl Test Edeceğim?
Tüm değişiklikler yapıldıktan sonra:

**1. Manuel Test Kaydı Oluştur:**
```sql
-- Test delivery request ekle
INSERT INTO delivery_requests (
  merchant_id,
  package_count,
  declared_amount,
  merchant_payment_due,
  courier_payment_due,
  status,
  pickup_location,
  delivery_location,
  notes,
  external_order_id,  -- ⭐ YENİ
  source              -- ⭐ YENİ
) VALUES (
  'MERCHANT_ID_BURAYA',  -- Gerçek bir merchant ID
  2,
  350.00,
  70.00,
  63.00,
  'pending',
  '{"latitude": 41.0082, "longitude": 28.9784, "address": "Test Restoran"}',
  '{"latitude": 41.0156, "longitude": 29.1234, "address": "Test Müşteri Adresi"}',
  'Test sipariş - Yemek App entegrasyonu',
  'YO-TEST-001',  -- ⭐ Yemek App sipariş no
  'yemek_app'     -- ⭐ Kaynak
);
```

**2. Merchant Panel'de Kontrol Et:**
- ✅ Turuncu "YEMEK APP" badge'i görünüyor mu?
- ✅ "YO-TEST-001" sipariş numarası görünüyor mu?
- ✅ "Kurye Çağır" butonu çalışıyor mu?

**3. Durum Değiştir ve Webhook Test Et:**
```sql
-- Durumu güncelle (trigger tetiklenir)
UPDATE delivery_requests
SET status = 'assigned',
    courier_id = 'KURYE_ID_BURAYA'
WHERE external_order_id = 'YO-TEST-001';

-- Supabase Logs'ta kontrol et:
-- Dashboard → Database → Logs → "Webhook sent to yemek_app" mesajını ara
```

**4. Temizlik:**
```sql
-- Test kaydını sil
DELETE FROM delivery_requests 
WHERE external_order_id = 'YO-TEST-001';
```

---

## 📊 KONTROL LİSTESİ

Tamamlandıkça işaretle:

- [ ] **GÖREV 1:** Database sütunları eklendi (`external_order_id`, `source`)
- [ ] **GÖREV 2:** Webhook trigger oluşturuldu
- [ ] **GÖREV 3:** DeliveryRequest model sınıfı güncellendi
- [ ] **GÖREV 4:** Merchant Panel'de kaynak badge'i eklendi
- [ ] **GÖREV 5:** FCM bildirimi güncellendi
- [ ] **GÖREV 6:** (Opsiyonel) Kurye atama servisi güncellendi
- [ ] **TEST:** Manuel test kaydı oluşturuldu ve doğrulandı

---

## ⚠️ ÖNEMLİ NOTLAR

1. **Webhook URL:** 
   - Görev 2'deki webhook URL şu an placeholder.
   - Yemek App ekibi gerçek URL'i verdiğinde güncellemen gerekecek.

2. **Mevcut Siparişler:**
   - Tüm mevcut kayıtlar `source = 'manual'` olarak işaretlenecek.
   - Bu hiçbir şeyi bozmaz, sadece yeni alanlar ekler.

3. **Geri Uyumluluk:**
   - Tüm değişiklikler geri uyumlu (backward compatible).
   - Eski kod çalışmaya devam eder.
   - Manuel kurye çağırma sistemi HİÇBİR ŞEKİLDE değişmez!

4. **Hata Durumları:**
   - Webhook gönderilemezse trigger hata vermez, sadece log'a yazar.
   - Bu sayede Onlog sistemi çalışmaya devam eder.

---

## 🆘 YARDIM

Sorun yaşarsan:

1. **SQL Hataları:** Supabase Dashboard → Database → Logs
2. **Trigger Logları:** `RAISE NOTICE` mesajlarını loglar'da ara
3. **Model Hataları:** Flutter uygulamada debug console'a bak
4. **Webhook Hataları:** Supabase Edge Functions → Logs

---

## 📞 İLETİŞİM

Yemek App ekibiyle paylaşman gereken bilgiler:

1. **Webhook URL'i neresi olacak?** (Görev 2 için gerekli)
2. **Hangi merchant ID'ler Yemek App'te olacak?** (Restaurant mapping için)
3. **Test için Yemek App Supabase'e erişim verebilirler mi?**

---

**Hazırlayan:** GitHub Copilot  
**Tarih:** 17 Kasım 2025  
**Versiyon:** 1.0
