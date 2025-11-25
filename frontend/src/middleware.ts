import { NextRequest, NextResponse } from 'next/server';

/**
 * Middleware to proxy /api/v1/* requests to the backend
 * This runs at runtime and can read runtime environment variables!
 */
export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Only intercept /api/v1/* requests
  if (pathname.startsWith('/api/v1/')) {
    // Get backend URL from runtime environment variables
    const backendUrl = process.env.API_URL ||
                       process.env.NEXT_PUBLIC_API_URL ||
                       'http://localhost:8080';

    // Log the proxy target (helps with debugging)
    console.log(`[middleware] Proxying ${pathname} to ${backendUrl}${pathname}`);

    // Build the backend URL
    const backendFullUrl = `${backendUrl}${pathname}${request.nextUrl.search}`;

    try {
      // Forward the request to the backend
      const response = await fetch(backendFullUrl, {
        method: request.method,
        headers: {
          'Content-Type': request.headers.get('Content-Type') || 'application/json',
          // Forward other important headers
          ...(request.headers.get('Authorization') && {
            'Authorization': request.headers.get('Authorization')!
          }),
        },
        body: request.method !== 'GET' && request.method !== 'HEAD'
          ? await request.text()
          : undefined,
        // Don't cache the response
        cache: 'no-store',
      });

      // Get the response body
      const data = await response.text();

      // Return the response from the backend
      return new NextResponse(data, {
        status: response.status,
        statusText: response.statusText,
        headers: {
          'Content-Type': response.headers.get('Content-Type') || 'application/json',
        },
      });
    } catch (error) {
      console.error(`[middleware] Failed to proxy ${pathname} to ${backendUrl}:`, error);
      return new NextResponse(
        JSON.stringify({ error: 'Failed to connect to backend' }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }
  }

  // Let other requests pass through
  return NextResponse.next();
}

// Configure which routes this middleware should run on
export const config = {
  matcher: '/api/v1/:path*',
};
