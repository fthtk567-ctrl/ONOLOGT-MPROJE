# 🚀 ONLOG - Sipariş ve Kurye Yönetim Sistemi# onlog_projects



ONLOG, yerel esnaflar için geliştirilmiş kapsamlı sipariş ve kurye yönetim platformudur.A new Flutter project.



## 📦 PROJE YAPISI## Getting Started



```This project is a starting point for a Flutter application.

onlog_projects/

│A few resources to get you started if this is your first Flutter project:

├── 📱 onlog_merchant_panel/      # Satıcı Paneli (Android, iOS, Web, Desktop)

│   └── Yerel esnaflar için sipariş yönetimi- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

│- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

├── 📱 onlog_courier_app/          # Kurye Uygulaması (Android, iOS)

│   └── Kuryeler için teslimat uygulamasıFor help getting started with Flutter development, view the

│[online documentation](https://docs.flutter.dev/), which offers tutorials,

├── 💻 onlog_admin_panel/          # Yönetici Paneli (Web)samples, guidance on mobile development, and a full API reference.

│   └── Sistem yöneticileri için kontrol paneli
│
├── 📦 onlog_shared/               # Ortak Paket
│   └── Tüm projelerde kullanılan modeller
│
└── 🗂️ onlog_application_2/        # ESKİ PROJE (Yedek - arşiv amaçlı)
```

---

## 🎯 SİSTEM MİMARİSİ

```
[Trendyol/Getir/Yemeksepeti API]
            ↓
    ┌───────────────┐
    │   BACKEND     │  ← Firebase/Supabase
    │  (Firestore)  │
    └───────────────┘
            ↓
    ┌───────┴───────┬────────────┐
    ↓               ↓            ↓
[Satıcı Panel]  [Kurye App]  [Admin Panel]
```

---

## 📱 1. SATICI PANELİ

### 🎯 Hedef: Yerel esnaflar, marketler, restoranlar

### ✨ Özellikler:
- ✅ Platform entegrasyonu (Trendyol, Getir, Yemek Sepeti)
- ✅ Tek tuşla kurye çağırma
- ✅ Sipariş yönetimi ve takibi
- ✅ Ödeme takibi (15 günlük/aylık dönemler)
- ✅ Excel export & raporlama
- ✅ Yazıcı entegrasyonu (isteğe bağlı)

---

## 🚴 2. KURYE UYGULAMASI

### 🎯 Hedef: ONLOG kuryeleri

### ✨ Özellikler:
- ✅ Sipariş kabul/red
- ✅ Gerçek zamanlı konum paylaşımı
- ✅ Harita ve navigasyon (OpenStreetMap)
- ✅ Kazanç takibi
- ✅ Performans metrikleri

---

## 💻 3. YÖNETİCİ PANELİ

### 🎯 Hedef: ONLOG sistem yöneticileri

### ✨ Özellikler:
- ✅ Tüm satıcıları görüntüleme ve yönetme
- ✅ Tüm kuryeleri görüntüleme ve takip
- ✅ Canlı sipariş izleme
- ✅ Sistem istatistikleri
- ✅ Hata logları ve müdahale
- ✅ Platform API ayarları

---

## 🚀 HIZLI BAŞLANGIÇ

### Satıcı Paneli:
```bash
cd onlog_merchant_panel
flutter run
```

### Kurye App:
```bash
cd onlog_courier_app
flutter run
```

### Admin Panel (Web):
```bash
cd onlog_admin_panel
flutter run -d chrome
```

---

## 📊 BACKEND (Firebase Collections)

```
merchants/          # Satıcılar
couriers/           # Kuryeler
orders/             # Siparişler
deliveries/         # Teslimatlar
```

---

## 💰 MALİYET (150 Esnaf)

- Backend: ~50$/ay (Firebase)
- Domain: ~100₺/yıl
- **Toplam: ~500-1000₺/ay**

---

## 🛠️ STACK

- Flutter 3.7+
- Firebase / Supabase
- OpenStreetMap
- Firestore / PostgreSQL

---

**Son Güncelleme:** 10 Ekim 2025  
**Geliştirici:** ONLOG Development Team
