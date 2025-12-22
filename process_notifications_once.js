/**
 * ONLOG - Tek Seferlik Notification Gönder
 * notification_queue'daki pending bildirimleri bir kez işle
 */

const https = require('https');
const fs = require('fs');
const crypto = require('crypto');

const SUPABASE_URL = 'oilldfyywtzybrmpyixx.supabase.co';
// SERVICE ROLE KEY - RLS bypass için
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0';
const SERVICE_ACCOUNT_FILE = 'C:\\Users\\PC\\Downloads\\onlog-push-firebase-adminsdk-fbsvc-787041d780.json';

function base64url(source) {
  let encodedSource = Buffer.from(source).toString('base64');
  encodedSource = encodedSource.replace(/=+$/, '');
  encodedSource = encodedSource.replace(/\+/g, '-');
  encodedSource = encodedSource.replace(/\//g, '_');
  return encodedSource;
}

async function getAccessToken() {
  const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_FILE, 'utf8'));
  
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };
  
  const header = { alg: 'RS256', typ: 'JWT' };
  const headerBase64 = base64url(JSON.stringify(header));
  const payloadBase64 = base64url(JSON.stringify(payload));
  const signatureInput = `${headerBase64}.${payloadBase64}`;
  
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(signatureInput);
  sign.end();
  
  const signature = sign.sign(serviceAccount.private_key);
  const signatureBase64 = base64url(signature);
  const jwt = `${signatureInput}.${signatureBase64}`;
  
  const tokenData = `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`;
  
  return new Promise((resolve) => {
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
          resolve(response.access_token);
        } else {
          resolve(null);
        }
      });
    });
    
    req.on('error', () => resolve(null));
    req.write(tokenData);
    req.end();
  });
}

async function sendFCM(token, title, body, data = {}) {
  const accessToken = await getAccessToken();
  if (!accessToken) return false;

  const message = {
    message: {
      token: token,
      notification: { title, body },
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
  
  return new Promise((resolve) => {
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

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => { responseData += chunk; });
      res.on('end', () => {
        resolve(res.statusCode === 200);
      });
    });
    
    req.on('error', () => resolve(false));
    req.write(messageData);
    req.end();
  });
}

async function getPendingNotifications() {
  return new Promise((resolve) => {
    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: '/rest/v1/notification_queue?status=eq.pending&order=created_at.asc&limit=10',
      method: 'GET',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve([]);
        }
      });
    });
    
    req.on('error', () => resolve([]));
    req.end();
  });
}

async function updateNotificationStatus(id, status, errorMessage = null) {
  return new Promise((resolve) => {
    const updateData = JSON.stringify({
      status: status,
      processed_at: new Date().toISOString(),
      error_message: errorMessage
    });

    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: `/rest/v1/notification_queue?id=eq.${id}`,
      method: 'PATCH',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      }
    };

    const req = https.request(options, (res) => {
      resolve(res.statusCode === 204);
    });
    
    req.on('error', () => resolve(false));
    req.write(updateData);
    req.end();
  });
}

(async () => {
  console.log('🚀 Tek Seferlik Notification İşleme');
  console.log('='.repeat(50));
  
  const notifications = await getPendingNotifications();
  
  if (notifications.length === 0) {
    console.log('❌ Pending bildirim yok!');
    return;
  }

  console.log(`📬 ${notifications.length} bildirim bulundu`);

  for (const notif of notifications) {
    console.log(`\n📤 İşleniyor: ${notif.title}`);
    
    try {
      const dataObj = {};
      if (notif.data) {
        for (const [key, value] of Object.entries(notif.data)) {
          dataObj[key] = String(value);
        }
      }

      const success = await sendFCM(
        notif.fcm_token,
        notif.title,
        notif.body,
        dataObj
      );

      if (success) {
        await updateNotificationStatus(notif.id, 'sent');
        console.log(`✅ Gönderildi: ${notif.title}`);
      } else {
        await updateNotificationStatus(notif.id, 'failed', 'FCM send failed');
        console.log(`❌ Gönderilemedi`);
      }
    } catch (error) {
      await updateNotificationStatus(notif.id, 'failed', error.message);
      console.error(`❌ Hata:`, error.message);
    }
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('✅ Tamamlandı!');
})();
