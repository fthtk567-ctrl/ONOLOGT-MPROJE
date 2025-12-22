# Firebase FCM Kurulumu - ONLOG Courier App

## Adım 1: FlutterFire CLI Kurulumu

```powershell
# Flutter CLI'yi global olarak yükle (bir kez)
dart pub global activate flutterfire_cli
```

## Adım 2: Firebase Projesi Yapılandırması

```powershell
# Courier App klasörüne git
cd C:\onlog_projects\onlog_courier_app

# Firebase'i yapılandır (Google hesabınla giriş yapar)
flutterfire configure
```

### Bu komut şunları yapacak:
1. Google hesabınla giriş yapar
2. Firebase projelerini listeler (ONLOG projesini seç)
3. Android + iOS için otomatik yapılandırır
4. `firebase_options.dart` dosyasını oluşturur
5. `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indirir

## Adım 3: Paketi Yükle

```powershell
flutter pub get
```

## Adım 4: Uygulamayı Tekrar Başlat

```powershell
flutter run -d R6CY200GZCF
```

---

## VEYA Manuel Yöntem (Yedek)

Eğer `flutterfire configure` çalışmazsa:

1. Firebase Console'a git: https://console.firebase.google.com
2. ONLOG projesini seç
3. Project Settings > General
4. Android uygulaması ekle (package name: `com.onlog.courier`)
5. `google-services.json` dosyasını indir → `android/app/` klasörüne koy
6. iOS için `GoogleService-Info.plist` indir → `ios/Runner/` klasörüne koy
7. `lib/firebase_options.dart` dosyasını manuel oluştur

---

## Test

Uygulama başlatıldıktan sonra logları kontrol et:

```
✅ Firebase initialized successfully!
📱 FCM Token alındı: xxxxx...
✅ FCM Token users tablosuna kaydedildi
```

Bu mesajları görüyorsan FCM hazır! 🎉
