export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname + url.search;
    const pathname = url.pathname;
    const method = request.method;
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
    };
    
    // Handle preflight requests
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    // PUBLIC WEB PAGES - No authentication required
    // These are SEO-optimized documentation and account pages
    const publicPaths = [
      '/',              // Landing page
      '/docs',          // API documentation
      '/account',       // Account management
      '/usage',         // Usage dashboard
      '/forgot-password', // Password reset request
      '/reset-password',  // Password reset form
      '/sitemap.xml',   // SEO sitemap
      '/llms.txt',      // AI crawler file
      '/robots.txt',    // Search engine robots
      '/up'             // Health check
    ];
    
    // Check if this is a public web page or account action
    const isPublicPage = publicPaths.includes(pathname) || 
                         pathname.startsWith('/account/') ||
                         pathname.startsWith('/assets/') ||
                         pathname.startsWith('/forgot-password') ||
                         pathname.startsWith('/reset-password');
    
    // Public pages: proxy directly to origin without auth
    if (isPublicPage) {
      return proxyToOrigin(request, env, corsHeaders);
    }
    
    // Extract API key from header
    const apiKey = request.headers.get('X-API-Key');
    
    // API key validation - required for API requests
    if (!apiKey) {
      return new Response(JSON.stringify({ 
        error: 'Unauthorized',
        message: 'API key is required. Please provide X-API-Key header.'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Validate API key and get associated email
    const keyDataStr = await env.API_KEYS.get(apiKey);
    if (!keyDataStr) {
      return new Response(JSON.stringify({ 
        error: 'Unauthorized',
        message: 'Invalid or expired API key'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Parse key data (supports both old 'valid' format and new JSON format)
    let keyStatus = 'valid';
    let userEmail = 'unknown';
    
    try {
      if (keyDataStr === 'valid') {
        // Legacy format - still valid but no email tracking
        keyStatus = 'valid';
        userEmail = 'legacy';
      } else {
        const keyData = JSON.parse(keyDataStr);
        keyStatus = keyData.status;
        userEmail = keyData.email || 'unknown';
      }
    } catch (e) {
      // If parsing fails, treat as legacy format
      keyStatus = keyDataStr === 'valid' ? 'valid' : 'invalid';
    }
    
    if (keyStatus !== 'valid') {
      return new Response(JSON.stringify({ 
        error: 'Unauthorized',
        message: 'Invalid or expired API key'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // ==========================================
    // RATE LIMITING: 1 request per 58 seconds
    // ==========================================
    const now = Date.now();
    const lastCallKey = `lastcall:${apiKey}`;
    const lastCallStr = await env.CACHE.get(lastCallKey);
    
    if (lastCallStr) {
      const lastCall = parseInt(lastCallStr);
      const elapsed = now - lastCall;
      const cooldownMs = 58000; // 58 seconds
      
      if (elapsed < cooldownMs) {
        const waitSeconds = Math.ceil((cooldownMs - elapsed) / 1000);
        
        // Track abuse: increment rejected counter (async)
        const hour = new Date().toISOString().slice(0, 13); // "2025-12-22T15"
        const abuseKey = `abuse:${apiKey}:${hour}`;
        ctx.waitUntil(
          (async () => {
            const currentAbuse = await env.CACHE.get(abuseKey);
            const newAbuse = (parseInt(currentAbuse) || 0) + 1;
            await env.CACHE.put(abuseKey, newAbuse.toString(), { expirationTtl: 604800 }); // 7 days
          })()
        );
        
        return new Response(JSON.stringify({ 
          error: 'Rate limited',
          message: `Please wait ${waitSeconds} seconds between requests. Data refreshes every 60 seconds.`,
          retry_after: waitSeconds
        }), {
          status: 429,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'Retry-After': waitSeconds.toString()
          }
        });
      }
    }
    
    // Update last call timestamp (async, non-blocking)
    ctx.waitUntil(
      env.CACHE.put(lastCallKey, now.toString(), { expirationTtl: 120 })
    );
    
    // ==========================================
    // USAGE TRACKING: Hourly counters per API key
    // ==========================================
    const hour = new Date().toISOString().slice(0, 13); // "2025-12-22T15"
    const usageKey = `usage:${apiKey}:${hour}`;
    
    // Increment usage counter (async, non-blocking)
    ctx.waitUntil(
      (async () => {
        const currentUsage = await env.CACHE.get(usageKey);
        const newUsage = (parseInt(currentUsage) || 0) + 1;
        await env.CACHE.put(usageKey, newUsage.toString(), { expirationTtl: 604800 }); // 7 days TTL
      })()
    );
    
    // Add rate limit info to headers
    corsHeaders['X-RateLimit-Limit'] = '1';
    corsHeaders['X-RateLimit-Window'] = '58';
    corsHeaders['X-RateLimit-Reset'] = Math.floor((now + 58000) / 1000).toString();
    
    // User endpoints always proxy to origin (no caching for security)
    if (path.startsWith('/api/v1/users')) {
      return proxyToOrigin(request, env, corsHeaders);
    }
    
    // Read-only endpoints: try KV cache first
    if (method === 'GET') {
      const cacheKey = `cache:${path}`;
      const cached = await env.CACHE.get(cacheKey);
      
      if (cached) {
        return new Response(cached, {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-Cache': 'HIT',
            'X-Cache-Status': 'Cloudflare Edge',
            'Cache-Control': 'public, max-age=60'
          }
        });
      }
      
      // Cache miss: proxy to origin and cache response
      const response = await proxyToOrigin(request, env, corsHeaders);
      if (response.ok) {
        const text = await response.text();
        // Cache for 2 minutes (will be refreshed by Heroku job every minute)
        ctx.waitUntil(env.CACHE.put(cacheKey, text, { expirationTtl: 120 }));
        
        return new Response(text, {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-Cache': 'MISS',
            'X-Cache-Status': 'Populated from origin'
          }
        });
      }
      return response;
    }
    
    // All other requests (POST, PUT, PATCH) proxy to origin
    return proxyToOrigin(request, env, corsHeaders);
  }
};

async function proxyToOrigin(request, env, corsHeaders) {
  const originUrl = new URL(request.url);
  originUrl.hostname = 'betstack-45ae7ff725cd.herokuapp.com';
  originUrl.protocol = 'https:';
  
  const originRequest = new Request(originUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body,
  });
  
  try {
    const response = await fetch(originRequest);
    
    // Clone response and add CORS headers
    const modifiedResponse = new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: new Headers(response.headers)
    });
    
    // Add CORS headers
    Object.entries(corsHeaders).forEach(([key, value]) => {
      modifiedResponse.headers.set(key, value);
    });
    
    // Add cache status header
    modifiedResponse.headers.set('X-Cache', 'BYPASS');
    modifiedResponse.headers.set('X-Cache-Status', 'Proxied to origin');
    
    return modifiedResponse;
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Origin server error',
      message: error.message 
    }), {
      status: 502,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}
