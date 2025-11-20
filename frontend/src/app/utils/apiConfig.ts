/**
 * Get the API base URL
 * - Returns empty string to use relative URLs
 * - All API requests go through nginx proxy (dev: Next.js rewrites, prod: nginx reverse proxy)
 */
export const getApiBaseUrl = (): string => {
  return '';
};

/**
 * Build a full API endpoint URL
 * @param path - The API path (e.g., '/api/v1/query/address/...')
 * @returns Relative URL for the API endpoint (proxied by nginx/Next.js)
 */
export const getApiUrl = (path: string): string => {
  const baseUrl = getApiBaseUrl();
  return `${baseUrl}${path}`;
};
