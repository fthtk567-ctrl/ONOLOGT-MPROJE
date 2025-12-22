const https = require('https');

const SUPABASE_URL = 'oilldfyywtzybrmpyixx.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzI4MjksImV4cCI6MjA3NjI0ODgyOX0.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM';

async function checkQueue() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: '/rest/v1/notification_queue?select=*&order=created_at.desc&limit=5',
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
          const result = JSON.parse(data);
          console.log('📊 Notification Queue Status:');
          console.log('='.repeat(50));
          console.log(`Total records: ${result.length}`);
          result.forEach(n => {
            console.log(`\nID: ${n.id}`);
            console.log(`Status: ${n.status}`);
            console.log(`Title: ${n.title}`);
            console.log(`Created: ${n.created_at}`);
            console.log(`Processed: ${n.processed_at || 'N/A'}`);
          });
          resolve(result);
        } catch (e) {
          reject(e);
        }
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

checkQueue()
  .then(() => console.log('\n✅ Done'))
  .catch(err => console.error('❌ Error:', err));
