import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic'; // Disable caching

/**
 * Demo environment endpoint that fetches from backend and supplements with runtime config
 * This intercepts the /api/v1/demo-environment call before it gets rewritten to the backend
 */
export async function GET() {
  try {
    // Get the backend URL from environment
    const backendUrl = process.env.API_URL || 'http://localhost:8080';

    // Fetch demo environment from backend
    const response = await fetch(`${backendUrl}/api/v1/demo-environment`, {
      cache: 'no-store',
    });

    if (!response.ok) {
      throw new Error(`Backend returned ${response.status}`);
    }

    const demoEnv = await response.json();

    // Supplement with runtime configuration from environment variables
    const enrichedDemoEnv = {
      ...demoEnv,
      // Override blockfrost_key from runtime environment if provided
      blockfrost_key: process.env.BLOCKFROST_API_KEY ??
                      process.env.NEXT_PUBLIC_BLOCKFROST_API_KEY ??
                      demoEnv.blockfrost_key ??
                      '',
      // Override network from runtime environment if provided
      network: process.env.NETWORK ?? demoEnv.network ?? 'Preview',
    };

    return NextResponse.json(enrichedDemoEnv);
  } catch (error) {
    console.error('Failed to fetch demo environment:', error);

    // Return a fallback preview environment with runtime config
    const fallbackEnv = {
      mint_authority: "problem alert infant glance toss gospel tonight sheriff match else hover upset chicken desert anxiety cliff moment song large seed purpose chalk loan onion",
      user_a: "during dolphin crop lend pizza guilt hen earn easy direct inhale deputy detect season army inject exhaust apple hard front bubble emotion short portion",
      user_b: "silver legal flame powder fence kiss stable margin refuse hold unknown valid wolf kangaroo zero able waste jewel find salad sadness exhibit hello tape",
      blockfrost_url: "https://cardano-preview.blockfrost.io/api/v0",
      explorer_url: "https://preview.cexplorer.io/tx",
      blockfrost_key: process.env.BLOCKFROST_API_KEY ??
                      process.env.NEXT_PUBLIC_BLOCKFROST_API_KEY ??
                      '',
      minting_policy: "b34a184f1f2871aa4d33544caecefef5242025f45c3fa5213d7662a9",
      token_name: "575354",
      transfer_logic_address: "addr_test1qq986m3uel86pl674mkzneqtycyg7csrdgdxj6uf7v7kd857kquweuh5kmrj28zs8czrwkl692jm67vna2rf7xtafhpqk3hecm",
      prog_logic_base_hash: "fca77bcce1e5e73c97a0bfa8c90f7cd2faff6fd6ed5b6fec1c04eefa",
      network: process.env.NETWORK ?? 'Preview',
    };

    return NextResponse.json(fallbackEnv);
  }
}
