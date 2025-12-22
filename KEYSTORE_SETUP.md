# Android Keystore Oluşturma

## Option 1: Google Play App Signing (Önerilen)
1. "İmzalama anahtarını değiştir" butonuna tıkla
2. "Google tarafından yönetilen" seç
3. Google otomatik signing yapar

## Option 2: Kendi Keystore
```bash
# Java JDK gerekli
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Gradle config
android/key.properties:
```
storePassword=myStorePassword
keyPassword=myKeyPassword  
keyAlias=upload
storeFile=upload-keystore.jks
```

android/app/build.gradle:
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```