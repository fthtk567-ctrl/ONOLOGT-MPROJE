# 🚀 GOOGLE PLAY YAYINI İÇİN SUPABASE PRODUCTION AYARLARI

## 📧 1. Email Confirmation Aktifleştirme

### Supabase Dashboard > Authentication > Settings:

✅ **Enable email confirmations** - AÇILMALI  
✅ **Enable email change confirmations** - AÇILMALI  
✅ **Enable phone confirmations** - KAPALI (şimdilik)

### Email Templates (Türkçeleştir):

**Kayıt Onayı (Sign Up):**
```
Konu: ONLOG Hesabınızı Onaylayın

Merhaba,

ONLOG Satıcı Paneli'ne kayıt olduğunuz için teşekkürler!

Hesabınızı aktifleştirmek için aşağıdaki bağlantıya tıklayın:
{{ .ConfirmationURL }}

Bu bağlantı 24 saat geçerlidir.

Herhangi bir sorunuz için: destek@onlog.com

ONLOG Ekibi
```

**Şifre Sıfırlama:**
```
Konu: ONLOG Şifre Sıfırlama

Merhaba,

ONLOG hesabınız için şifre sıfırlama talebiniz alındı.

Yeni şifre belirlemek için:
{{ .ConfirmationURL }}

Bu bağlantı 1 saat geçerlidir.

Eğer bu talep sizden değilse, bu e-postayı görmezden gelin.

ONLOG Ekibi
```

## 🔒 2. Güvenlik Ayarları

### Session Management:
- **Session timeout**: 30 gün (mevcut) ✅
- **Refresh token rotation**: Aktif ✅
- **JWT expiry**: 1 saat (varsayılan) ✅

### Rate Limiting:
```sql
-- Supabase Dashboard > SQL Editor
-- Rate limiting için ayarlar
ALTER ROLE anon SET statement_timeout = '30s';
ALTER ROLE authenticated SET statement_timeout = '60s';
```

## 🌐 3. CORS ve Domain Ayarları

### Site URL (Production):
- **Site URL**: `https://onlog.com` (web sürümü için)
- **Redirect URLs**: 
  - `https://onlog.com/auth/callback`
  - `onlog://auth/callback` (mobile deep link)

### Mobile Deep Links:
```xml
<!-- Android Manifest'e eklenecek -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="onlog" android:host="auth" />
</intent-filter>
```

## 📊 4. Database Production Ayarları

### RLS Policies Kontrolü:
```sql
-- Tüm önemli tablolarda RLS aktif mi kontrol et
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'orders', 'payment_transactions', 'merchant_wallets');
```

### Index Optimizasyonu:
```sql
-- Performans için indexler
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role_status ON users(role, status);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id, status);
```

## 🔐 5. API Key Güvenliği

### Environment Variables:
- ✅ `SUPABASE_URL` - production URL
- ✅ `SUPABASE_ANON_KEY` - public key
- ❌ `SUPABASE_SERVICE_KEY` - ASLA mobile app'e koyma!

### Key Rotasyonu:
- **Anon Key**: 6 ayda bir yenile
- **Service Key**: Sadece backend'de kullan

## 📱 6. Mobile App Specific

### Push Notifications:
- FCM project key updated ✅
- iOS APNs certificates ✅

### App Permissions:
```xml
<!-- Minimum required permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 🚨 7. Production Checklist

### Pre-Launch:
- [ ] Email confirmation açık
- [ ] Email templates Türkçe
- [ ] Domain whitelist ayarlandı
- [ ] Deep links yapılandırıldı
- [ ] RLS policies test edildi
- [ ] Database backup kuruldu
- [ ] Monitoring ayarlandı

### Security:
- [ ] Rate limiting aktif
- [ ] Session timeout uygun
- [ ] CORS yapılandırması
- [ ] API key güvenliği
- [ ] SQL injection koruması (RLS)

### Performance:
- [ ] Database indexleri
- [ ] Connection pooling
- [ ] Query optimizasyonu
- [ ] CDN yapılandırması

## 📞 8. Support & Monitoring

### Error Tracking:
- Supabase Dashboard > Logs
- Custom error reporting (Sentry vs.)

### User Support:
- Email: destek@onlog.com
- Support ticket system
- FAQ section

---

## 🎯 HEMEN YAPILACAKLAR:

1. **Supabase Dashboard** > Authentication > Settings > **Email confirmation AÇ**
2. **Email templates** Türkçe yap
3. **Site URL** production domain set et
4. **Mobile deep links** Android Manifest'e ekle
5. **Database indexleri** çalıştır

Bu ayarları yaptıktan sonra Google Play'e güvenle yayınlayabilirsin! 🚀