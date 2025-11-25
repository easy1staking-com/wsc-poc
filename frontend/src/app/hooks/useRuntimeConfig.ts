'use client';

import { useEffect } from 'react';
import useStore from '../store/store';

/**
 * Hook to load runtime configuration from the server
 * Call this in your root layout or app component
 */
export function useRuntimeConfig() {
  const { config, setConfig } = useStore();

  useEffect(() => {
    // Skip if already loaded
    if (config.isLoaded) {
      return;
    }

    // Fetch config from server
    fetch('/api/config')
      .then((res) => res.json())
      .then((data) => {
        setConfig({
          blockfrostApiKey: data.blockfrostApiKey || '',
          network: data.network || 'Preview',
          apiUrl: data.apiUrl || '',
          isLoaded: true,
        });
        console.log('Runtime config loaded:', {
          network: data.network,
          hasBlockfrostKey: !!data.blockfrostApiKey,
        });
      })
      .catch((error) => {
        console.error('Failed to load runtime config:', error);
        // Set isLoaded to true anyway to prevent infinite retries
        setConfig({
          blockfrostApiKey: '',
          network: 'Preview',
          apiUrl: '',
          isLoaded: true,
        });
      });
  }, [config.isLoaded, setConfig]);

  return config;
}
