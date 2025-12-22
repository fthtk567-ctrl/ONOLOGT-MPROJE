# ✅ ONLOG ÖDEME SİSTEMİ - KURULUM KONTROL LİSTESİ

## 📋 Genel Bakış

Bu döküman, **Onlog Ödeme Sistemi**'nin tamamen otomatik çalışması için gereken tüm adımları içerir.

---

## 🎯 AŞAMA 1: SUPABASE SETUP (10 dakika)

### 1.1 SQL Script Kurulumu ✅
- [ ] Supabase Dashboard'a giriş yap: https://supabase.com/dashboard
- [ ] Projeyi seç
- [ ] Sol menüden **SQL Editor** sekmesine tıkla
- [ ] **New query** butonuna bas
- [ ] `SUPABASE_PAYMENT_SETUP.sql` dosyasını aç
- [ ] Tüm içeriği kopyala (Ctrl+A, Ctrl+C)
- [ ] SQL Editor'e yapıştır (Ctrl+V)
- [ ] **RUN** butonuna tıkla (veya F5)
- [ ] ✅ "Success. No rows returned" mesajını gör

**Beklenen Sonuç:**
```
Success. No rows returned
Rows: 0
Duration: ~2-5 seconds
```

### 1.2 Realtime Subscriptions Aktifleştirme ✅
- [ ] Dashboard > **Database** > **Replication**
- [ ] `payment_transactions` tablosunu bul
- [ ] **Enable Realtime** checkbox'ını işaretle ☑️
- [ ] `merchant_wallets` tablosunu bul
- [ ] **Enable Realtime** checkbox'ını işaretle ☑️
- [ ] `courier_wallets` tablosunu bul
- [ ] **Enable Realtime** checkbox'ını işaretle ☑️
- [ ] **Save** butonuna tıkla

**Doğrulama:**
```sql
-- SQL Editor'de çalıştır:
SELECT tablename FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```
Beklenen: `payment_transactions`, `merchant_wallets`, `courier_wallets` görünmeli

### 1.3 Trigger Kontrolü ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_process_payment_on_delivery';
```

**Beklenen Sonuç:**
| trigger_name | event_manipulation | event_object_table | action_statement |
|--------------|-------------------|-------------------|------------------|
| trigger_process_payment_on_delivery | UPDATE | orders | EXECUTE FUNCTION process_order_payment_on_delivery() |

### 1.4 RPC Fonksiyonları Kontrolü ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_name IN (
  'update_merchant_wallet',
  'update_courier_wallet',
  'update_merchant_wallet_after_payment',
  'get_merchant_available_balance',
  'get_courier_available_balance',
  'merchant_withdraw_money',
  'process_order_payment_on_delivery'
);
```

**Beklenen Sonuç:** 7 fonksiyon görünmeli

### 1.5 Default Komisyon Config Kontrolü ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT * FROM commission_configs 
WHERE merchant_id IS NULL AND is_active = TRUE;
```

**Beklenen Sonuç:**
| commission_rate | fixed_fee | minimum_commission | maximum_commission |
|-----------------|-----------|-------------------|-------------------|
| 15.0            | 2.0       | 2.0               | 50.0              |

---

## 🎯 AŞAMA 2: FLUTTER BACKEND ENTEGRASYONU (5 dakika)

### 2.1 onlog_shared Paketi ✅
- [ ] Terminal aç
- [ ] `cd c:\onlog_projects\onlog_shared` çalıştır
- [ ] `flutter pub get` çalıştır
- [ ] ✅ Hatasız tamamlandığını gör

### 2.2 payment_service.dart Kontrolü ✅
- [ ] VSCode'da `payment_service.dart` dosyasını aç
- [ ] Problems panelinde **0 hata** olduğunu doğrula
- [ ] Dosyada `_firestore` referansı **olmamalı**
- [ ] `_supabase = SupabaseService.client` **olmalı**

**Doğrulama:**
```bash
cd c:\onlog_projects\onlog_shared
dart analyze lib/services/payment_service.dart
```
Beklenen: `No issues found!`

---

## 🎯 AŞAMA 3: MERCHANT PANEL ENTEGRASYONU (10 dakika)

### 3.1 Paket Güncelleme ✅
- [ ] Terminal aç
- [ ] `cd c:\onlog_projects\onlog_merchant_panel` çalıştır
- [ ] `flutter pub get` çalıştır
- [ ] ✅ `onlog_shared` paketinin güncellendiğini gör

### 3.2 Payment Dashboard Güncelleme ✅
- [ ] `merchant_payment_dashboard.dart` dosyasını aç
- [ ] PaymentService'i kullanacak şekilde güncelle:

```dart
import 'package:onlog_shared/services/payment_service.dart';

class MerchantPaymentDashboard extends StatefulWidget {
  // ... existing code ...
}

class _MerchantPaymentDashboardState extends State<MerchantPaymentDashboard> {
  final _paymentService = PaymentService();
  
  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }
  
  Future<void> _loadWalletData() async {
    final wallet = await _paymentService.getMerchantWallet(currentUserId);
    setState(() {
      // Wallet bilgilerini göster
    });
  }
  
  // Realtime subscription
  Stream<List<PaymentTransaction>> _getTransactionsStream() {
    return _paymentService.getMerchantTransactions(currentUserId);
  }
}
```

### 3.3 UI Componentleri Ekleme ✅
- [ ] Wallet Balance kartı ekle
- [ ] Transaction listesi ekle
- [ ] Para çekme formu ekle
- [ ] Günlük kazanç grafiği ekle

**Örnek Widget:**
```dart
StreamBuilder<List<PaymentTransaction>>(
  stream: _paymentService.getMerchantTransactions(merchantId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final transactions = snapshot.data!;
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return ListTile(
          title: Text('${tx.amount} TL'),
          subtitle: Text(tx.description ?? ''),
          trailing: Text(tx.status.toString()),
        );
      },
    );
  },
)
```

---

## 🎯 AŞAMA 4: COURIER APP ENTEGRASYONU (10 dakika)

### 4.1 Paket Güncelleme ✅
- [ ] Terminal aç
- [ ] `cd c:\onlog_projects\onlog_courier_app` çalıştır
- [ ] `flutter pub get` çalıştır

### 4.2 Courier Wallet Ekranı Oluşturma ✅
- [ ] `lib/screens/courier_wallet_page.dart` dosyası oluştur
- [ ] PaymentService ile entegre et:

```dart
class CourierWalletPage extends StatelessWidget {
  final _paymentService = PaymentService();
  final String courierId;
  
  Future<CourierWallet?> _getWallet() async {
    // Custom method - payment_service.dart'a eklenecek
    final response = await SupabaseService.client
        .from('courier_wallets')
        .select()
        .eq('courier_id', courierId)
        .maybeSingle();
    
    if (response == null) return null;
    return CourierWallet.fromMap(response);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourierWallet?>(
      future: _getWallet(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final wallet = snapshot.data!;
        return Column(
          children: [
            Text('Bakiye: ${wallet.balance} TL'),
            Text('Toplam Teslimat: ${wallet.totalDeliveries}'),
            ElevatedButton(
              onPressed: () => _withdrawMoney(),
              child: Text('Para Çek'),
            ),
          ],
        );
      },
    );
  }
}
```

### 4.3 Sipariş Teslim Butonu Güncelleme ✅
- [ ] `order_details_page.dart` (veya benzeri) dosyasını aç
- [ ] "Teslim Ettim" butonunu bul
- [ ] Status güncellemesini doğrula:

```dart
Future<void> _deliverOrder() async {
  await SupabaseService.client
      .from('orders')
      .update({'status': 'DELIVERED'})  // ← TRIGGER TEKLİYOR!
      .eq('id', orderId);
  
  // Otomatik ödeme trigger'ı çalışacak!
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Sipariş teslim edildi! Ödemeniz işleniyor...')),
  );
}
```

---

## 🎯 AŞAMA 5: TEST SENARYOLARI (15 dakika)

### 5.1 Test Merchant Wallet Oluşturma ✅
- [ ] Supabase SQL Editor'de çalıştır:
```sql
INSERT INTO merchant_wallets (merchant_id, balance, currency)
VALUES (
  'YOUR-MERCHANT-UUID',  -- merchantt@test.com kullanıcısının UUID'si
  0,  -- Başlangıç bakiyesi 0
  'TRY'
) ON CONFLICT (merchant_id) DO NOTHING;
```

### 5.2 Test Courier Wallet Oluşturma ✅
- [ ] SQL Editor'de çalıştır:
```sql
INSERT INTO courier_wallets (courier_id, balance, currency)
VALUES (
  'YOUR-COURIER-UUID',  -- Test kurye UUID'si
  0,
  'TRY'
) ON CONFLICT (courier_id) DO NOTHING;
```

### 5.3 Test Sipariş Oluşturma ✅
- [ ] SQL Editor'de çalıştır:
```sql
INSERT INTO orders (
  id,
  merchant_id,
  courier_id,
  customer_id,
  total_amount,
  status,
  payment_method,
  metadata
) VALUES (
  gen_random_uuid(),
  'YOUR-MERCHANT-UUID',
  'YOUR-COURIER-UUID',
  'YOUR-CUSTOMER-UUID',
  100.0,  -- 100 TL sipariş
  'ASSIGNED',  -- Henüz teslim edilmedi
  'cash',
  '{"delivery_fee": 20.0}'::jsonb
) RETURNING id;
```

**Not:** Dönen `id` değerini kopyala!

### 5.4 Otomatik Ödeme Testi ✅
- [ ] SQL Editor'de çalıştır (yukarıdaki id'yi kullan):
```sql
UPDATE orders
SET status = 'DELIVERED'
WHERE id = 'YOUR-ORDER-UUID';
```

**Kontrol Et:**
- [ ] Console'da `NOTICE` log'u göründü mü?
```
NOTICE: Otomatik ödeme işlendi: Sipariş ..., Merchant: 79.94 TL, Kurye: 20.00 TL
```

- [ ] Payment transactions oluştu mu?
```sql
SELECT * FROM payment_transactions 
WHERE order_id = 'YOUR-ORDER-UUID';
```
Beklenen: 2 satır (merchant + courier)

- [ ] Merchant wallet güncellendi mi?
```sql
SELECT balance, total_earnings, total_commissions 
FROM merchant_wallets 
WHERE merchant_id = 'YOUR-MERCHANT-UUID';
```
Beklenen: `balance = 79.94`, `total_commissions = 17.0`

- [ ] Courier wallet güncellendi mi?
```sql
SELECT balance, total_earnings, total_deliveries 
FROM courier_wallets 
WHERE courier_id = 'YOUR-COURIER-UUID';
```
Beklenen: `balance = 20.0`, `total_deliveries = 1`

### 5.5 Realtime Test ✅
- [ ] Merchant Panel'i aç: `http://localhost:3001`
- [ ] Ödeme Dashboard'a git
- [ ] Başka bir sekmede SQL Editor'de sipariş teslim et
- [ ] ✅ Bakiyenin **otomatik** güncellendiğini gör (yenileme gerekmez!)

### 5.6 Para Çekme Testi ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT merchant_withdraw_money(
  'YOUR-MERCHANT-UUID',
  50.0,  -- 50 TL çek
  'TR12 3456 7890 1234 5678 90',
  'Test para çekme'
);
```

**Kontrol Et:**
- [ ] Transaction oluştu mu?
```sql
SELECT * FROM payment_transactions 
WHERE merchant_id = 'YOUR-MERCHANT-UUID' 
AND type = 'withdrawal'
ORDER BY created_at DESC LIMIT 1;
```

- [ ] Bakiye düştü mü?
```sql
SELECT balance, total_withdrawals 
FROM merchant_wallets 
WHERE merchant_id = 'YOUR-MERCHANT-UUID';
```
Beklenen: `balance = 29.94` (79.94 - 50.0), `total_withdrawals = 50.0`

---

## 🎯 AŞAMA 6: RAPORLAMA TESTİ (5 dakika)

### 6.1 Günlük Merchant Raporu ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT * FROM daily_merchant_earnings
WHERE merchant_id = 'YOUR-MERCHANT-UUID'
ORDER BY earning_date DESC
LIMIT 7;  -- Son 7 gün
```

### 6.2 Günlük Courier Raporu ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT * FROM daily_courier_earnings
WHERE courier_id = 'YOUR-COURIER-UUID'
ORDER BY earning_date DESC
LIMIT 7;
```

### 6.3 Sistem Komisyon Raporu ✅
- [ ] SQL Editor'de çalıştır:
```sql
SELECT * FROM system_commission_report
ORDER BY report_date DESC
LIMIT 30;  -- Son 30 gün
```

---

## 🎯 AŞAMA 7: PRODUCTION HAZIRLIK (10 dakika)

### 7.1 Environment Variables ✅
- [ ] `.env` dosyasında Supabase bilgileri güncel mi?
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 7.2 Error Handling ✅
- [ ] PaymentService'te try-catch blokları var mı?
- [ ] Kullanıcıya anlamlı hata mesajları gösteriliyor mu?
- [ ] Sentry/Firebase Crashlytics entegre mi?

### 7.3 Monitoring ✅
- [ ] Supabase Dashboard > **Logs** aktif mi?
- [ ] Database log retention ayarlandı mı?
- [ ] Alertler kuruldu mu? (Realtime sorunları için)

### 7.4 Backup ✅
- [ ] Supabase otomatik backup aktif mi?
- [ ] Database > **Backups** sekmesini kontrol et
- [ ] Daily backup schedule ayarlandı mı?

### 7.5 Security Audit ✅
- [ ] RLS politikaları doğru mu?
```sql
-- Her tablo için test et
SET ROLE authenticated;
SET request.jwt.claims.sub = 'test-user-uuid';
SELECT * FROM payment_transactions;  -- Sadece kendi kayıtlarını görmeli
```

- [ ] API Key'ler güvende mi? (`.env` gitignore'da)
- [ ] CORS ayarları production için uygun mu?

---

## ✅ SON KONTROL LİSTESİ

### Backend (Supabase)
- [ ] 4 Tablo oluşturuldu
- [ ] 7 RPC fonksiyonu kuruldu
- [ ] 1 Trigger aktif
- [ ] 3 View oluşturuldu
- [ ] RLS politikaları aktif
- [ ] Realtime subscriptions aktif
- [ ] Default commission config mevcut

### Frontend (Flutter)
- [ ] onlog_shared paketi güncellendi
- [ ] payment_service.dart hatasız
- [ ] Merchant Panel entegrasyonu tamam
- [ ] Courier App entegrasyonu tamam
- [ ] UI componentleri eklendi
- [ ] Realtime updates çalışıyor

### Test
- [ ] Sipariş oluşturma testi geçti
- [ ] Otomatik ödeme testi geçti
- [ ] Wallet güncelleme testi geçti
- [ ] Para çekme testi geçti
- [ ] Raporlama testi geçti
- [ ] Realtime test geçti

### Production
- [ ] Environment variables set edildi
- [ ] Error handling eklendi
- [ ] Monitoring aktif
- [ ] Backup ayarlandı
- [ ] Security audit yapıldı

---

## 🎉 BAŞARI!

Tüm adımlar tamamlandıysa, **Onlog Ödeme Sistemi** artık tam otomatik çalışıyor!

### Önemli Hatırlatma:
> Sipariş durumu `DELIVERED` olduğu **anda**, trigger otomatik çalışır ve tüm finansal işlemler tamamlanır. Manuel müdahale gerekmez!

### Destek:
Sorun yaşarsanız:
1. Supabase Dashboard > **Logs** > **Database Logs** kontrol edin
2. `NOTICE` ve `ERROR` mesajlarına bakın
3. `OTOMATIK_ODEME_SISTEMI.md` dosyasına başvurun

---

**Kurulum Tarihi:** 24 Ekim 2025  
**Versiyon:** 1.0.0  
**Durum:** ✅ PRODUCTION READY
