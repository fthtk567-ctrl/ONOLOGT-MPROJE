# 🎵 ÖZEL SES DOSYALARI NASIL EKLENİR?

## ⚡ **HIZLI ÇÖZÜM: ŞİMDİLİK VARSAYILAN SES KULLAN**

Kod şu an **Android varsayılan bildirim sesini** kullanıyor. Bu yeterli! ✅

Titreşim desenleri farklı olduğu için courier yeni sipariş ile acil siparişi ayırt edebilir.

---

## 🎯 **İLERİDE ÖZEL SES EKLEMEK İSTERSEN**

### Adım 1: Ses Dosyalarını İndir

**Ücretsiz Kaynaklar:**
- https://mixkit.co/free-sound-effects/notification/
- https://pixabay.com/sound-effects/search/notification/
- https://freesound.org/

**Önerilen Sesler:**
- **Yeni Sipariş**: "Cash register" veya "Ding" sesi (1-2 saniye)
- **Acil Teslimat**: "Alert" veya "Alarm" sesi (2-3 saniye)
- **Genel**: "Notification pop" sesi (1 saniye)

### Adım 2: Ses Dosyalarını Hazırla

1. **Format**: MP3 veya OGG
2. **Süre**: 1-3 saniye (çok uzun olmasın)
3. **Dosya Boyutu**: Maksimum 500 KB
4. **İsim**: Küçük harf, boşluk yok, özel karakter yok

**Örnekler:**
- ✅ `new_order.mp3`
- ✅ `urgent.mp3`
- ✅ `notification.mp3`
- ❌ `New Order Sound.mp3` (boşluk var)
- ❌ `acil-sipariş.mp3` (Türkçe karakter var)

### Adım 3: Klasöre Kopyala

```bash
# Ses dosyalarını buraya kopyala:
c:\onlog_projects\onlog_courier_app\android\app\src\main\res\raw\

# Klasör içeriği:
raw/
├── new_order.mp3      (Yeni sipariş sesi)
├── urgent.mp3         (Acil teslimat sesi)
└── notification.mp3   (Genel bildirim sesi)
```

**Windows'ta:**
1. Windows Explorer'ı aç
2. `c:\onlog_projects\onlog_courier_app\android\app\src\main\res\raw\` klasörüne git
3. MP3 dosyalarını buraya yapıştır

### Adım 4: Kodda Aktif Et

`lib/services/push_notification_service.dart` dosyasında:

```dart
// Şu satırların başındaki // işaretlerini kaldır:

sound: const RawResourceAndroidNotificationSound('new_order'),  // .mp3 uzantısı YAZMA!
sound: const RawResourceAndroidNotificationSound('urgent'),
sound: const RawResourceAndroidNotificationSound('notification'),
```

### Adım 5: Uygulamayı Yeniden Derle

```bash
cd c:\onlog_projects\onlog_courier_app
flutter run -d R6CY200GZCF
```

**ÖNEMLİ:** Hot reload YETMEZ! Yeniden derleme gerekli çünkü Android native kaynaklarını değiştirdin.

---

## 🧪 **TEST ETME**

### Test Kodu
```dart
// Profile screen'e ekle
ElevatedButton(
  onPressed: () async {
    await PushNotificationService().sendTestNotification();
  },
  child: Text('🔔 Test Bildirimi'),
)
```

### Manuel Test
1. Telefonda uygulamayı aç
2. Profile → Test Bildirimi butonu
3. Ses çalmalı, titremeli

---

## 💡 **KOLAY YÖNTEM: ONLINE SES ÜRETİCİ**

Kendi sesini oluştur:

1. **Text-to-Speech:**
   - https://ttsmp3.com/
   - "Yeni sipariş" yaz
   - MP3 indir

2. **Ses Efekti Jeneratörü:**
   - https://www.zapsplat.com/
   - "notification" ara
   - Ücretsiz olanları indir

3. **Basit Ding Sesi:**
   - https://mixkit.co/free-sound-effects/notification/
   - Mixkit → Notification → Cash Register
   - İndir ve `new_order.mp3` olarak kaydet

---

## 🎨 **ÖNERİLEN SESLER**

### 1. Yeni Sipariş (`new_order.mp3`)
**Karakter:** Pozitif, motivasyon veren, "para kazandın" hissi
```
Öneriler:
- Cash register ding
- Coin drop sound
- Success chime
- "Ding ding ding" (3 kez)
```

### 2. Acil Teslimat (`urgent.mp3`)
**Karakter:** Dikkat çekici, aciliyet hissi, "hemen bak" mesajı
```
Öneriler:
- Alert siren
- Urgent beep (tekrarlı)
- Alarm sound
- "Beep beep beep" (hızlı)
```

### 3. Genel Bildirim (`notification.mp3`)
**Karakter:** Profesyonel, nazik, "bilgi var" mesajı
```
Öneriler:
- Soft notification pop
- Bell chime
- Subtle ding
- WhatsApp benzeri ses
```

---

## 📋 **SES DOSYASI ÖZELLİKLERİ**

| Özellik | Değer | Neden? |
|---------|-------|--------|
| Format | MP3 veya OGG | Android desteği |
| Bit Rate | 128 kbps | Kalite/boyut dengesi |
| Sample Rate | 44100 Hz | CD kalitesi |
| Kanal | Mono | Daha küçük dosya |
| Süre | 1-3 saniye | Kullanıcıyı rahatsız etmez |
| Boyut | Max 500 KB | Hız için |

---

## 🚨 **YAYGIIN HATALAR**

### Ses Çalmıyor?
1. ✅ Dosya adı küçük harf mı?
2. ✅ `.mp3` uzantısı kodda YOK (sadece dosya adı)?
3. ✅ Dosya `raw/` klasöründe mi?
4. ✅ Uygulama yeniden derlendi mi? (hot reload yetmez!)
5. ✅ Telefon sesli modda mı?

### "Resource not found" Hatası?
```bash
# Android clean yap
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run -d R6CY200GZCF
```

### Ses Çok Yavaş/Hızlı?
- MP3 dosyasını bir ses editöründe aç (Audacity ücretsiz)
- Hızlandır/yavaşlat
- Yeniden export et

---

## 🎯 **SONUÇ**

### Şu an:
✅ **Varsayılan Android sesi** kullanıyorsun  
✅ **Titreşim desenleri farklı** (yeni: 2 kez, acil: 4 kez)  
✅ **LED farklı** (acil: kırmızı)  
✅ **Öncelikler farklı** (MAX vs HIGH)  

**Bu yeterli!** Özel ses eklemek BONUS.

### İleride özel ses için:
1. Ses dosyası bul/oluştur
2. `android/app/src/main/res/raw/` klasörüne kopyala
3. Kodda `sound:` satırlarının başındaki `//` kaldır
4. `flutter run` ile yeniden derle

---

## 💡 **HİZMET: BEN HAZIR SES BULAYIM MI?**

Istersen ben sana uygun ücretsiz sesler bulup link verebilirim. Sadece söyle! 🎵
