import { Page } from 'playwright-core';
/**
 * AI-Assisted Debugging with Playwriter
 */
export declare class AIDebugging {
    private page;
    constructor(page: Page);
    /**
     * Capture screenshot of current state for AI analysis
     */
    captureStateForAI(context: string): Promise<Buffer<ArrayBufferLike>>;
    /**
     * Extract console errors for AI debugging
     */
    extractConsoleErrors(): Promise<string[]>;
    /**
     * Analyze widget tree structure
     */
    analyzeWidgetTree(): Promise<{
        timestamp: number;
        url: string;
    }>;
    /**
     * Monitor network requests for debugging
     */
    monitorNetworkActivity(): Promise<{
        requests: any[];
        responses: any[];
    }>;
    /**
     * Performance profiling
     */
    profilePerformance(): Promise<{
        domContentLoaded: number;
        loadComplete: number;
        domInteractive: number;
        responseTime: number;
    }>;
    /**
     * Memory usage analysis
     */
    analyzeMemoryUsage(): Promise<{
        usedJSHeapSize: any;
        totalJSHeapSize: any;
        jsHeapSizeLimit: any;
        usedPercentage: string;
    } | null>;
    /**
     * Complete diagnostic report for AI analysis
     */
    generateDiagnosticReport(): Promise<{
        timestamp: string;
        screenshot: Buffer<ArrayBufferLike>;
        consoleErrors: string[];
        widgetTree: {
            timestamp: number;
            url: string;
        };
        network: {
            requests: any[];
            responses: any[];
        };
        performance: {
            domContentLoaded: number;
            loadComplete: number;
            domInteractive: number;
            responseTime: number;
        };
        memory: {
            usedJSHeapSize: any;
            totalJSHeapSize: any;
            jsHeapSizeLimit: any;
            usedPercentage: string;
        } | null;
    }>;
}
//# sourceMappingURL=ai-debugging.d.ts.map