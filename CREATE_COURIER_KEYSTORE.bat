@echo off
echo ========================================
echo ONLOG COURIER APP - KEYSTORE OLUSTURMA
echo ========================================
echo.
echo Keystore otomatik olusturuluyor...
echo.

"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore c:\onlog_projects\onlog-courier-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onlog-courier -storepass onlog2024courier! -keypass onlog2024courier! -dname "CN=ONLOG Courier, OU=ONLOG, O=ONLOG Ltd, L=Istanbul, ST=Istanbul, C=TR"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo KEYSTORE BASARIYLA OLUSTURULDU!
    echo ========================================
    echo.
    echo Dosya Yeri: c:\onlog_projects\onlog-courier-release.jks
    echo Alias: onlog-courier
    echo Sifre: onlog2024courier!
    echo.
    echo ONEMLI: Sifreyi guvenli bir yerde saklayin!
    echo.
) else (
    echo.
    echo ========================================
    echo HATA! KEYSTORE OLUSTURULAMADI!
    echo ========================================
    echo.
)

pause
