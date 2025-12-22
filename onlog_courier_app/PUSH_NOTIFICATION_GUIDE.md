# 🔔 COURIER APP - PRO BİLDİRİM SİSTEMİ

## ✅ EKLENENStops

### 1. **Firebase Cloud Messaging (FCM)**
- ✅ Firebase Messaging entegrasyonu
- ✅ Arka plan mesaj handler
- ✅ FCM token yönetimi
- ✅ Token Firestore'a otomatik kayıt

### 2. **Flutter Local Notifications**
- ✅ 4 farklı bildirim kanalı:
  * **new_order_channel**: Yeni sipariş (MAX öncelik)
  * **urgent_order_channel**: Acil teslimat (MAX öncelik + LED)
  * **general_channel**: Genel bildirimler (YÜKSEK öncelik)
  * **info_channel**: Bilgilendirmeler (NORMAL öncelik)

### 3. **Özel Ses ve Titreşim**
- ✅ Her kanal için farklı ses
- ✅ Özel titreşim desenleri:
  * Yeni sipariş: 2 kez titreşim
  * Acil: 4 kez hızlı titreşim
  * Genel: 2 kez orta titreşim
- ✅ LED desteği (acil teslimatlar için kırmızı)

### 4. **Android Manifest İzinleri**
- ✅ POST_NOTIFICATIONS (Android 13+)
- ✅ VIBRATE
- ✅ RECEIVE_BOOT_COMPLETED
- ✅ USE_FULL_SCREEN_INTENT (acil teslimatlar için)

### 5. **Tam Ekran Bildirim**
- ✅ Acil siparişler tam ekran açılır
- ✅ Ekran kapalı iken açılır
- ✅ Kilit ekranında gösterilir

---

## 📱 KULLANIM

### Otomatik FCM Token Kaydı
Kullanıcı login olduğunda otomatik olarak:
```dart
// CourierHomeScreen - initState()
await PushNotificationService().saveFCMTokenToFirestore(courierId);
```

### Firebase'den Bildirim Gönderme

#### Yeni Sipariş Bildirimi
```json
{
  "to": "<courier_fcm_token>",
  "notification": {
    "title": "🆕 Yeni Sipariş!",
    "body": "TEKELER KEPAB'dan teslimat - 15₺ kazanç"
  },
  "data": {
    "type": "new_order",
    "priority": "high",
    "orderId": "ORDER123",
    "restaurantName": "TEKELER KEPAB",
    "earning": "15"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "new_order_channel",
      "sound": "new_order_sound",
      "tag": "new_order"
    }
  }
}
```

#### Acil Teslimat Bildirimi
```json
{
  "to": "<courier_fcm_token>",
  "notification": {
    "title": "🚨 ACİL TESLİMAT!",
    "body": "10 dakikada teslim edilmeli - 50₺ bonus!"
  },
  "data": {
    "type": "urgent",
    "priority": "urgent",
    "orderId": "URGENT456",
    "deadline": "10",
    "bonus": "50"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "urgent_order_channel",
      "sound": "urgent_sound",
      "tag": "urgent_delivery",
      "visibility": "public",
      "priority": 2
    }
  }
}
```

---

## 🎵 SES DOSYALARpendencies>
  firebase_messaging: ^16.0.2  ✅
  flutter_local_notifications: ^18.0.1  ✅
```

### Android Bildirim İzinleri
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

### iOS Yapılandırması (İsteğe Bağlı)
```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

---

## 🧪 TEST ETME

### 1. Telefondan Test
```dart
// main.dart veya profile screen'e ekle
ElevatedButton(
  onPressed: () async {
    await PushNotificationService().sendTestNotification();
  },
  child: Text('Test Bildirimi Gönder'),
)
```

### 2. Firebase Console'dan Test
1. Firebase Console → Cloud Messaging
2. "Send your first message" tıkla
3. Bildirim başlığı ve içeriği yaz
4. Test mode seç
5. FCM token gir (Firestore'da user dokümanında)
6. Gönder

### 3. Postman/CURL ile Test
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=YOUR_SERVER_KEY" \
-H "Content-Type: application/json" \
-d '{
  "to": "COURIER_FCM_TOKEN",
  "notification": {
    "title": "Test Bildirimi",
    "body": "Bildirim sistemi çalışıyor!"
  },
  "data": {
    "type": "test"
  }
}'
```

---

## 🎯 ÖZELLİKLER

### ✅ Şu An Çalışıyor
- [x] FCM entegrasyonu
- [x] Local notifications
- [x] 4 bildirim kanalı
- [x] Özel titreşim desenleri
- [x] Arka plan bildirimleri
- [x] Ön plan bildirimleri
- [x] FCM token Firestore kaydı
- [x] Android izinleri
- [x] Tam ekran acil bildirimler

### ⏳ Gelecek Özellikler
- [ ] Bildirim geçmişi sayfası
- [ ] Bildirim ayarları (ses/titreşim açma/kapama)
- [ ] Bildirim istatistikleri
- [ ] Grup bildirimleri
- [ ] Bildirim yanıtlama (kabul/red)
- [ ] iOS desteği
- [ ] Web push notifications

---

## 🚨 ÖNEMLİ NOTLAR

### Android 13+ İçin
```kotlin
// MainActivity.kt
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
        != PackageManager.PERMISSION_GRANTED) {
        ActivityCompat.requestPermissions(this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE_POST_NOTIFICATIONS)
    }
}
```

### Ses Dosyaları Eksik
Şu an ses dosyaları yok. Eklemek için:
1. `android/app/src/main/res/raw/` klasörüne `.mp3` dosyalarını koy:
   - new_order_sound.mp3
   - urgent_sound.mp3
   - notification_sound.mp3
2. Dosya isimleri küçük harf, boşluksuz
3. Uygulamayı yeniden derle

### Firestore Kuralları
```javascript
// Courier'ler kendi token'larını güncelleyebilir
match /users/{userId} {
  allow update: if request.auth.uid == userId 
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['fcmToken', 'fcmTokenUpdatedAt', 'platform']);
}
```

---

## 💡 KULLANIM ÖRNEKLERİ

### Admin Panel'den Bildirim Gönderme
```dart
// Yeni sipariş atandığında
Future<void> assignOrderToCourier(String orderId, String courierId) async {
  // 1. Sipariş ata
  await FirebaseFirestore.instance
      .collection('deliveryRequests')
      .doc(orderId)
      .update({'assignedCourierId': courierId});
  
  // 2. Courier FCM token'ını al
  final courierDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(courierId)
      .get();
  
  String? fcmToken = courierDoc.data()?['fcmToken'];
  
  // 3. Bildirim gönder (Cloud Function kullan)
  await FirebaseFunctions.instance
      .httpsCallable('sendOrderNotification')
      .call({
        'fcmToken': fcmToken,
        'orderId': orderId,
        'type': 'new_order',
      });
}
```

### Cloud Function Örneği
```javascript
// functions/index.js
exports.sendOrderNotification = functions.https.onCall(async (data, context) => {
  const { fcmToken, orderId, type } = data;
  
  const message = {
    token: fcmToken,
    notification: {
      title: '🆕 Yeni Sipariş!',
      body: 'Size yeni bir sipariş atandı',
    },
    data: {
      type: 'new_order',
      orderId: orderId,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'new_order_channel',
        sound: 'new_order_sound',
      },
    },
  };
  
  await admin.messaging().send(message);
});
```

---

## 📊 BİLDİRİM KANALI DETAYLARIsound_channel**
| Özellik | Değer |
|---------|-------|
| Öncelik | MAX |
| Ses | new_order_sound.mp3 |
| Titreşim | [0, 1000, 500, 1000] |
| LED | Yok |
| Tam Ekran | Hayır |
| Kaydırarak Kapat | Hayır (ongoing) |

#### **urgent_order_channel**
| Özellik | Değer |
|---------|-------|
| Öncelik | MAX |
| Ses | urgent_sound.mp3 |
| Titreşim | [0, 500, 200, 500, 200, 500, 200, 500] |
| LED | Kırmızı |
| Tam Ekran | Evet |
| Kaydırarak Kapat | Hayır |

#### **general_channel**
| Özellik | Değer |
|---------|-------|
| Öncelik | HIGH |
| Ses | notification_sound.mp3 |
| Titreşim | [0, 500, 250, 500] |
| LED | Yok |
| Tam Ekran | Hayır |
| Kaydırarak Kapat | Evet |

#### **info_channel**
| Özellik | Değer |
|---------|-------|
| Öncelik | DEFAULT |
| Ses | Varsayılan |
| Titreşim | Yok |
| LED | Yok |
| Tam Ekran | Hayır |
| Kaydırarak Kapat | Evet |

---

## 🎉 SONUÇ

Courier App artık **PRO bildirim sistemine sahip!** 

✅ Kuryeler arka planda bile bildirim alacak  
✅ Özel sesler ve titreşim desenleri  
✅ Acil siparişler tam ekran açılacak  
✅ FCM token otomatik kaydediliyor  

**Eksik:** Sadece ses dosyaları eklenmeli!

---

## 📞 DESTEK

Sorular için:
- `/lib/services/push_notification_service.dart` dosyasına bak
- Firebase Console → Cloud Messaging
- Flutter Local Notifications dokümantasyonu
