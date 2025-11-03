export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname + url.search;
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
    
    // Extract API key from header
    const apiKey = request.headers.get('X-API-Key');
    
    // API key validation for all requests (optional - allow requests without keys)
    if (apiKey) {
      const validKey = await env.API_KEYS.get(apiKey);
      if (!validKey || validKey !== 'valid') {
        return new Response(JSON.stringify({ error: 'Invalid or expired API key' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }
    
    // Rate limiting (100 requests per minute per key/IP)
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
    const rateLimitKey = `ratelimit:${apiKey || clientIP}`;
    const requests = await env.CACHE.get(rateLimitKey);
    
    if (requests && parseInt(requests) > 100) {
      return new Response(JSON.stringify({ error: 'Rate limit exceeded. Maximum 100 requests per minute.' }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Increment rate limit counter
    ctx.waitUntil(
      env.CACHE.put(rateLimitKey, (parseInt(requests || 0) + 1).toString(), { expirationTtl: 60 })
    );
    
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

