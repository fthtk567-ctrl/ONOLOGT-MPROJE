// Supabase'den FCM token al
const https = require('https');

const options = {
  hostname: 'oilldfyywtzybrmpyixx.supabase.co',
  port: 443,
  path: '/rest/v1/user_fcm_tokens?select=fcm_token&user_id=eq.250f4abe-858a-457b-b972-9a76340b07c2&order=created_at.desc&limit=1',
  method: 'GET',
  headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzI4MjksImV4cCI6MjA3NjI0ODgyOX0.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzI4MjksImV4cCI6MjA3NjI0ODgyOX0.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      if (parsed && parsed.length > 0) {
        console.log('✅ Token bulundu:');
        console.log(parsed[0].fcm_token);
      } else {
        console.log('❌ Token bulunamadı');
      }
    } catch (e) {
      console.error('❌ Parse hatası:', e.message);
      console.log('Raw data:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request hatası:', error.message);
});

req.end();
