import { chromium } from 'playwright-core';
import { startPlayWriterCDPRelayServer, getCdpUrl } from 'playwriter';

/**
 * Setup Playwriter automation server for KRE8TIONS IDE
 */
export async function setupPlaywriter() {
  console.log('🚀 Starting Playwriter CDP Relay Server...');

  const server = await startPlayWriterCDPRelayServer();
  console.log('✅ Server started successfully');

  const browser = await chromium.connectOverCDP(getCdpUrl());
  console.log('✅ Connected to browser via CDP');

  return { server, browser };
}

/**
 * Cleanup and close connections
 */
export async function cleanupPlaywriter(browser: any, server: any) {
  await browser.close();
  await server.close();
  console.log('✅ Cleaned up Playwriter connections');
}
