# ONLOG Shared Package

ONLOG sistemi için ortak modeller ve servisler içeren shared package.

## 📦 İçindekiler

### Models
- **Order** - Sipariş modeli (tüm platformlar için)
- **Courier** - Kurye modeli  
- **Merchant** - Satıcı/İşletme modeli
- **Address** - Adres modeli
- **Customer** - Müşteri modeli

### Enums
- OrderStatus, OrderPlatform, OrderType, OrderPriority
- CourierStatus, VehicleType

## 🎯 Kullanım

### pubspec.yaml'a ekleyin:

```yaml
dependencies:
  onlog_shared:
    path: ../onlog_shared
```

### Import edin:

```dart
import 'package:onlog_shared/onlog_shared.dart';

// Artık tüm modelleri kullanabilirsiniz
Order order = Order(...);
Courier courier = Courier(...);
Merchant merchant = Merchant(...);
```

## 🏗️ Proje Yapısı

```
onlog_shared/
├── lib/
│   ├── models/
│   │   ├── order.dart
│   │   ├── courier.dart
│   │   └── merchant.dart
│   └── onlog_shared.dart
└── pubspec.yaml
```

## 📱 Kullanıldığı Projeler

1. **onlog_merchant_panel** - Satıcı paneli
2. **onlog_courier_app** - Kurye uygulaması  
3. **onlog_admin_panel** - Yönetici paneli

