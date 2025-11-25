import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

/**
 * Debug endpoint to check environment variables
 * Only use in development/debugging!
 */
export async function GET() {
  return NextResponse.json({
    API_URL: process.env.API_URL || '(not set)',
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '(not set)',
    BLOCKFROST_API_KEY: process.env.BLOCKFROST_API_KEY ? '***set***' : '(not set)',
    NEXT_PUBLIC_BLOCKFROST_API_KEY: process.env.NEXT_PUBLIC_BLOCKFROST_API_KEY ? '***set***' : '(not set)',
    NETWORK: process.env.NETWORK || '(not set)',
    NODE_ENV: process.env.NODE_ENV || '(not set)',
  });
}
