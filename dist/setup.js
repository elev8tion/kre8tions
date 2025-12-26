"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupPlaywriter = setupPlaywriter;
exports.cleanupPlaywriter = cleanupPlaywriter;
const playwright_core_1 = require("playwright-core");
const playwriter_1 = require("playwriter");
/**
 * Setup Playwriter automation server for KRE8TIONS IDE
 */
async function setupPlaywriter() {
    console.log('🚀 Starting Playwriter CDP Relay Server...');
    const server = await (0, playwriter_1.startPlayWriterCDPRelayServer)();
    console.log('✅ Server started successfully');
    const browser = await playwright_core_1.chromium.connectOverCDP((0, playwriter_1.getCdpUrl)());
    console.log('✅ Connected to browser via CDP');
    return { server, browser };
}
/**
 * Cleanup and close connections
 */
async function cleanupPlaywriter(browser, server) {
    await browser.close();
    await server.close();
    console.log('✅ Cleaned up Playwriter connections');
}
//# sourceMappingURL=setup.js.map