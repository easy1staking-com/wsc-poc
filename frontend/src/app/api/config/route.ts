import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic'; // Disable caching

/**
 * Runtime configuration endpoint
 * Returns environment-specific config from server-side env vars
 */
export async function GET() {
  const config = {
    // Blockfrost API configuration
    blockfrostApiKey: process.env.BLOCKFROST_API_KEY ??
                      process.env.NEXT_PUBLIC_BLOCKFROST_API_KEY ??
                      '',

    // Network configuration (Preview, Preprod, Mainnet)
    network: process.env.NETWORK ?? 'Preview',

    // API base URL (optional, for client-side direct calls if needed)
    // Usually not needed since we use rewrites
    apiUrl: process.env.API_URL ?? '',
  };

  return NextResponse.json(config);
}
