# GOOGLE PLAY KEYSTORE OLUŞTURMA KOMUTU

## 🔐 Courier App için Release Keystore Oluştur

Aşağıdaki komutu **Command Prompt** (CMD) veya **PowerShell**'de çalıştırın:

```powershell
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -genkey -v -keystore c:\onlog_projects\onlog-courier-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onlog-courier
```

## 📝 Sorulacak Bilgiler (Örnek Cevaplar):

1. **Enter keystore password:** `onlog2024courier!`
2. **Re-enter new password:** `onlog2024courier!`
3. **What is your first and last name?** `ONLOG Courier`
4. **What is the name of your organizational unit?** `ONLOG`
5. **What is the name of your organization?** `ONLOG Ltd`
6. **What is the name of your City or Locality?** `Istanbul`
7. **What is the name of your State or Province?** `Istanbul`
8. **What is the two-letter country code for this unit?** `TR`
9. **Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct?** `yes`

## ✅ Sonuç:

Keystore dosyası şu konumda oluşacak:
```
c:\onlog_projects\onlog-courier-release.jks
```

## 🔒 ÖNEMLİ NOTLAR:

- **Şifreyi unutmayın!** Şifreyi kaybederseniz Google Play'e güncelleme yükleyemezsiniz!
- **Keystore dosyasını yedekleyin!** Git'e eklemeyin (güvenlik riski!)
- **key.properties** dosyasını da Git'e eklemeyin!

## 📋 Şifre Bilgileri (Güvenli Yerde Saklayın):

```
Keystore Dosyası: c:\onlog_projects\onlog-courier-release.jks
Keystore Şifresi: onlog2024courier!
Alias: onlog-courier
Alias Şifresi: onlog2024courier! (aynı şifre)
```

---

Bu komutu çalıştırdıktan sonra bana haber ver, devam edelim! 🚀
