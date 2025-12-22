@echo off
echo ONLOG Courier App - Keystore Olusturma
echo =========================================
echo.
echo Bu script Android keystore dosyasi olusturacak.
echo Google Play Store'a yuklemek icin gereklidir.
echo.
echo Asagidaki bilgileri gireceksiniz:
echo 1. Sifre (en az 6 karakter)
echo 2. Ad Soyad
echo 3. Organizasyon: ONLOG
echo 4. Sehir: Konya
echo 5. Ulke Kodu: TR
echo.
pause

cd android

keytool -genkey -v -keystore onlog-courier-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onlog-courier

echo.
echo =========================================
echo Keystore basariyla olusturuldu!
echo Dosya: android\onlog-courier-release.jks
echo.
echo ONEMLI: Bu dosyayi ve sifreyi SAKLAYIN!
echo Kaybederseniz uygulama guncelleyemezsiniz!
echo =========================================
pause
