// scripts/update_tunnel_url.js - Registers the active Cloudflare Tunnel URL in Supabase
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const { supabase } = require('../config/supabase');

async function updateTunnelUrl(url) {
  const targetUrl = (url || process.argv[2] || '').trim();
  if (!targetUrl || (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://'))) {
    console.error('[TUNNEL CONFIG ERROR] Please provide a valid HTTP/HTTPS URL.');
    process.exit(1);
  }

  if (!supabase) {
    console.error('[TUNNEL CONFIG ERROR] Supabase client is not available.');
    process.exit(1);
  }

  try {
    const { error } = await supabase.from('users').upsert([{
      id: 'system_config',
      username: '__config__',
      name: 'active_tunnel_url',
      phone: '0000000000',
      role: 'admin',
      password: targetUrl,
      created_at: new Date().toISOString(),
    }], { onConflict: 'id' });

    if (error) {
      console.error('[TUNNEL CONFIG ERROR]', error.message);
      process.exit(1);
    }

    console.log('[TUNNEL CONFIG OK] Active tunnel registered in Supabase:', targetUrl);
  } catch (err) {
    console.error('[TUNNEL CONFIG EXCEPTION]', err.message);
    process.exit(1);
  }
}

updateTunnelUrl();