/**
 * Setup Playwriter automation server for KRE8TIONS IDE
 */
export declare function setupPlaywriter(): Promise<{
    server: import("playwriter").RelayServer;
    browser: import("playwright-core").Browser;
}>;
/**
 * Cleanup and close connections
 */
export declare function cleanupPlaywriter(browser: any, server: any): Promise<void>;
//# sourceMappingURL=setup.d.ts.map