import { startPlayWriterCDPRelayServer, getCdpUrl } from 'playwriter';

/**
 * Simple test to verify Playwriter connection
 */
async function testConnection() {
  console.log('Testing Playwriter connection...\n');

  try {
    console.log('1. Starting CDP Relay Server...');
    const server = await startPlayWriterCDPRelayServer();
    console.log('✅ Server started');
    console.log('   CDP URL:', getCdpUrl());

    console.log('\n📋 Instructions:');
    console.log('   1. Open Chrome browser (your regular one with extensions)');
    console.log('   2. Go to: http://localhost:8000');
    console.log('   3. Click the Playwriter extension icon (puzzle piece)');
    console.log('   4. Click "Connect this tab"');
    console.log('   5. You should see a green indicator\n');

    console.log('⏳ Waiting 30 seconds for you to connect the tab...\n');

    // Wait for user to connect
    await new Promise(resolve => setTimeout(resolve, 30000));

    console.log('Attempting to connect to browser...');

    const { chromium } = await import('playwright-core');
    const browser = await chromium.connectOverCDP(getCdpUrl());

    console.log('✅ Successfully connected to browser!');

    const contexts = browser.contexts();
    console.log(`   Contexts found: ${contexts.length}`);

    if (contexts.length > 0) {
      const pages = await contexts[0].pages();
      console.log(`   Pages found: ${pages.length}`);

      if (pages.length > 0) {
        console.log(`   Connected to: ${pages[0].url()}`);
      }
    }

    await browser.close();
    await server.close();

    console.log('\n✅ Connection test successful!');
    console.log('You can now run: npm run automation\n');

  } catch (error) {
    console.error('\n❌ Connection failed:', (error as Error).message);
    console.log('\nTroubleshooting:');
    console.log('1. Is the Playwriter Chrome extension installed?');
    console.log('   Install from: Chrome Web Store > Search "Playwriter"');
    console.log('2. Did you click "Connect this tab" in the extension popup?');
    console.log('3. Is the page still open at http://localhost:8000?');
    console.log('4. Try refreshing the page and connecting again\n');
  }
}

testConnection();
