/**
 * ONLOG - FCM Notification Sender (Node.js)
 * Web CORS bypass için backend'den FCM gönderen script
 */

const https = require('https');
const fs = require('fs');
const crypto = require('crypto');

// Firebase Service Account
const SERVICE_ACCOUNT_FILE = 'C:\\Users\\PC\\Downloads\\onlog-push-firebase-adminsdk-fbsvc-787041d780.json';

function base64url(source) {
  let encodedSource = Buffer.from(source).toString('base64');
  encodedSource = encodedSource.replace(/=+$/, '');
  encodedSource = encodedSource.replace(/\+/g, '-');
  encodedSource = encodedSource.replace(/\//g, '_');
  return encodedSource;
}

async function getAccessToken() {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_FILE, 'utf8'));
    
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now
    };
    
    const header = {
      alg: 'RS256',
      typ: 'JWT'
    };
    
    const headerBase64 = base64url(JSON.stringify(header));
    const payloadBase64 = base64url(JSON.stringify(payload));
    const signatureInput = `${headerBase64}.${payloadBase64}`;
    
    const sign = crypto.createSign('RSA-SHA256');
    sign.update(signatureInput);
    sign.end();
    
    const signature = sign.sign(serviceAccount.private_key);
    const signatureBase64 = base64url(signature);
    
    const jwt = `${signatureInput}.${signatureBase64}`;
    
    // Exchange JWT for access token
    const tokenData = `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`;
    
    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'oauth2.googleapis.com',
        port: 443,
        path: '/token',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(tokenData)
        }
      };
      
      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          if (res.statusCode === 200) {
            const response = JSON.parse(data);
            console.log('✅ OAuth2 token alındı');
            resolve(response.access_token);
          } else {
            console.error('❌ Token hatası:', res.statusCode, data);
            resolve(null);
          }
        });
      });
      
      req.on('error', (error) => {
        console.error('❌ Request hatası:', error.message);
        resolve(null);
      });
      
      req.write(tokenData);
      req.end();
    });
  } catch (error) {
    console.error('❌ Token hatası:', error.message);
    return null;
  }
}

async function sendFCM(token, title, body, data = {}) {
  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return false;
    }

    const message = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order',
            sound: 'default'
          }
        },
        data: data
      }
    };

    const messageData = JSON.stringify(message);
    
    const options = {
      hostname: 'fcm.googleapis.com',
      port: 443,
      path: '/v1/projects/onlog-push/messages:send',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(messageData)
      }
    };

    return new Promise((resolve, reject) => {
      console.log('📤 FCM\'e gönderiliyor...');
      
      const req = https.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          if (res.statusCode === 200) {
            console.log('✅ Bildirim başarıyla gönderildi!');
            console.log('📥 Response:', responseData);
            resolve(true);
          } else {
            console.error('❌ FCM hatası:', res.statusCode);
            console.error('📄 Response:', responseData);
            resolve(false);
          }
        });
      });
      
      req.on('error', (error) => {
        console.error('❌ Request hatası:', error.message);
        resolve(false);
      });
      
      req.write(messageData);
      req.end();
    });
  } catch (error) {
    console.error('❌ Hata:', error.message);
    return false;
  }
}

// Test
(async () => {
  console.log('🚀 ONLOG - FCM Notification Test');
  console.log('='.repeat(50));
  
  const courierToken = 'cB55RyA1QuOc4bBOfpxFJe:APA91bFgKDbdbUKwEr2aPqdlsaln1U2nNkKvrRvl3rB9ykBmTF8PCPVPzys0ZgNOA5znf9v5EXiCov6t8K1fbXFfW1U9iYLwoznj7-hdMpcyH1en5Oph0-k';
  
  const success = await sendFCM(
    courierToken,
    '🚀 Yeni Teslimat İsteği!',
    'Restoran - test3 - 1 paket - 1.00 TL',
    {
      type: 'new_delivery_request',
      test: 'true',
      source: 'Backend Script',
      delivery_id: '140f57e6-6485-4df9-bc15-d57c4759a22b'
    }
  );
  
  console.log('='.repeat(50));
  if (success) {
    console.log('✅ TEST BAŞARILI - Kurye telefonunu kontrol et!');
  } else {
    console.log('❌ TEST BAŞARISIZ - Loglara bak');
  }
})();
