const https = require('https');

// Firebase Service Account
const serviceAccount = {
  "type": "service_account",
  "project_id": "onlog-push",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC5z+Z8/cqoKT8Z\nVrjRGf1n7xLiwd3Tyzzd8K9SLXEtSiHcmijCBr/hm0KnjxAxvI+jx3jsXY8wq8Kr\nYFEvj0qVch91tLo/qc3IgEVJ/3s3s8nTuyWW3NX5alWRoo154ILQTNrHXAGWz4SW\nJnbt39eceUnhHASSH8U+yiTV0d1w8+ZySX2eC72DcRCO5JEljqFHBvP0lx40ip2x\naDdujhm8cd/TCIbCoJCtr5iH3VQ6rt18e5R9PfW+IxsK3M1ANc8Jt1iA7Yl1Mmu0\n3maBM/XsOOtskEEEVefreswBGsuGkYHSf9Bs38ghYznpTicxQ1ayIflofHLg62Co\nyI/AjHJJAgMBAAECggEAHmlMvcXS8qFnkqfbMVwJ2cYrBuJ4gjbIFEIVi8Nku+cf\ncinoBFOS+aON7fswCRflwYY/AB6S9kISZzapKvnOmPWX+Q2Wkx9hTxDRZlpSaiw6\nmvUNIqsruTniXebnNVydxGZjw0/Hcc2uk12hxu6FLTa7tQR/KgRZpdxzWWyTC+6T\nV7HPb7KB/G0vIlKuspey8LteqhUMoEHZl557c7Xd3scC3UpqbbiSzUuB26AdoUTu\nK/t9fn4lL2hN4AgmYd6LbLdVnssRpVDJ0tdDbKTuAo/rKibSWIM+CbEfA++aIUc4\nv+cUqKRvJnnRtmoyuR2fa/CWN2BhpEXp2ziDiZRp1QKBgQD4dtIVRbQAfdK4ufDf\nrYMCqh72cRZ+3jaDskBn0oqdJw8LbM4sCMlcn9g7NSnOp15IpdK6oZO3o/5esFMf\nZfXTIAfyS5u5PQZIA8lhyDCtS/4PeLmFdSbu5GzzYB6dmvSd6VpGuYMoiEE6Kcxy\n6vNeIAx4D8StkaSpLub63/ftJQKBgQC/cp+Hw/DnhiwfJfc+L7Cmo8W89Jh3WmwX\nVhgWTEX9PtGGo/PSt+hKlNX1byamB+n8ZGTa+u7ZXZXEgIhwqfOUa7FWG26AqBjH\nvH0BVfm9QzeaGL+7L/cbCgWNtcCTpJzubtcD2dg41JRYg72bNQfWyS4XFkVLNDvl\nYuyt6spRVQKBgQDE/LdsxBmE9jy11j2hqRggaa4opto19Yl0+kLTzXm2RLxJy5be\nFI1I0TYHIwwlWk6G/GlJLEdIJk3K1rLgRt8R5uhF8inhP/+V4uKrkqL9Ei24KHe1\n1n7qkdHLVt6PB8Z+1/6J6hSRcw17xp3gUmRmsLQSEDZXggvxUk0wg5c1vQKBgEEO\nNEOwQ6aJI2kaP5/0GLUnpcQF4eF86ooriVfaZ1YdCJoWEH6kW90sImCaeqmkutA3\nVUZMSum2MXRqsPKH7eubhNFb1PsHJBSLancPviOgOb61dkGnlPKtPyHehygkoecr\n5wi5+A2nvxks+ztIk/daubzCpp1djJTwPrkCtelZAoGBANxzeFc9VBG+BPe4CZJj\nykIeGd+Mav/r0Uesdq0H9LsqTArJKfYT42g3sKlcT+0o5VmQCV7l0f624WxfHUIg\nc1CVJhqBGuvIzLPvoVTwSe8AfKt9jzhPijqX2XtokEhoUfeTwwSeXRZUoOOWzdlY\ngS4HYGTrvZXm4tjvtRH5BwiN\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@onlog-push.iam.gserviceaccount.com"
};

// Legacy FCM API (daha basit)
const FCM_SERVER_KEY = "AAAAxxxxxxx"; // Firebase Console > Project Settings > Cloud Messaging

const FCM_TOKEN = "cB5SRyA1QuOc4bBOfpxfJe:APA91bFg3hRXvTHLEzDiC0xJ8Mq7EZOPrN2XQjGk9sVwYtUmIbAcDeFhJkLmNoPqRsTuVwXyZ0AbCdEfGhIjKlMnOpQrStUvWxYz1A2bC3dE4fG5hI6jK7lM8nO9pQ0rS1tU2vW3xY4z";

const payload = JSON.stringify({
  "to": FCM_TOKEN,
  "priority": "high",
  "notification": {
    "title": "🚀 Yeni Teslimat İsteği!",
    "body": "Test Restaurant - Konya, Ergenekon 119/A - 35 TL",
    "sound": "default",
    "channel_id": "new_order"
  },
  "data": {
    "type": "new_order",
    "order_id": "TEST-" + Date.now(),
    "merchant_name": "Test Restaurant",
    "delivery_address": "Konya, Ergenekon 119/A",
    "delivery_fee": "35"
  }
});

const options = {
  hostname: 'fcm.googleapis.com',
  port: 443,
  path: '/fcm/send',
  method: 'POST',
  headers: {
    'Authorization': `key=${FCM_SERVER_KEY}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

console.log('📱 Kurye uygulamasına test bildirimi gönderiliyor...\n');

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('✅ Bildirim gönderildi!');
      console.log('   Response:', data);
      console.log('\n🎉 Başarılı! Kurye uygulamasını kontrol et!');
      console.log('   (Arka planda ise bildirim panel\'de görünmeli)');
    } else {
      console.log(`❌ Hata: ${res.statusCode}`);
      console.log('   Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ İstek hatası:', error);
});

req.write(payload);
req.end();
