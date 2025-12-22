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
      '/sitemap.xml',   // SEO sitemap
      '/llms.txt',      // AI crawler file
      '/robots.txt',    // Search engine robots
      '/up'             // Health check
    ];
    
    // Check if this is a public web page or account action
    const isPublicPage = publicPaths.includes(pathname) || 
                         pathname.startsWith('/account/') ||
                         pathname.startsWith('/assets/');
    
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
    
    // Validate API key exists
    const validKey = await env.API_KEYS.get(apiKey);
    if (!validKey || validKey !== 'valid') {
      return new Response(JSON.stringify({ 
        error: 'Unauthorized',
        message: 'Invalid or expired API key'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Rate limiting: 1,000 requests per day per API key
    // Use daily key format: ratelimit:{apiKey}:{YYYY-MM-DD}
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const rateLimitKey = `ratelimit:${apiKey}:${today}`;
    const RATE_LIMIT_MAX = 1000;
    const RATE_LIMIT_TTL = 86400; // 24 hours
    
    // Get current count
    const currentCountStr = await env.CACHE.get(rateLimitKey);
    const currentCount = currentCountStr ? parseInt(currentCountStr) : 0;
    
    // Calculate reset time (next midnight UTC)
    const resetTime = new Date();
    resetTime.setUTCDate(resetTime.getUTCDate() + 1);
    resetTime.setUTCHours(0, 0, 0, 0);
    
    // Check if limit exceeded
    if (currentCount >= RATE_LIMIT_MAX) {
      return new Response(JSON.stringify({ 
        error: 'Rate limit exceeded',
        message: `Maximum 1,000 requests per day. Limit resets at ${resetTime.toISOString()}`,
        limit: RATE_LIMIT_MAX,
        reset_at: resetTime.toISOString()
      }), {
        status: 429,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'X-RateLimit-Limit': RATE_LIMIT_MAX.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': Math.floor(resetTime.getTime() / 1000).toString()
        }
      });
    }
    
    // Increment rate limit counter (async, won't block response)
    const newCount = currentCount + 1;
    const remaining = RATE_LIMIT_MAX - newCount;
    
    ctx.waitUntil(
      env.CACHE.put(rateLimitKey, newCount.toString(), { expirationTtl: RATE_LIMIT_TTL })
    );
    
    // Store rate limit headers for response
    corsHeaders['X-RateLimit-Limit'] = RATE_LIMIT_MAX.toString();
    corsHeaders['X-RateLimit-Remaining'] = remaining.toString();
    corsHeaders['X-RateLimit-Reset'] = Math.floor(resetTime.getTime() / 1000).toString();
    
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

