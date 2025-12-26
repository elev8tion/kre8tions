"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AIDebugging = void 0;
/**
 * AI-Assisted Debugging with Playwriter
 */
class AIDebugging {
    constructor(page) {
        this.page = page;
    }
    /**
     * Capture screenshot of current state for AI analysis
     */
    async captureStateForAI(context) {
        console.log(`📸 Capturing state: ${context}`);
        const screenshot = await this.page.screenshot({
            fullPage: true,
            path: `debug-screenshots/${context}-${Date.now()}.png`
        });
        console.log('  ✅ Screenshot captured for AI analysis');
        return screenshot;
    }
    /**
     * Extract console errors for AI debugging
     */
    async extractConsoleErrors() {
        console.log('🐛 Extracting console errors...');
        const errors = [];
        this.page.on('console', (msg) => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });
        // Wait to collect errors
        await this.page.waitForTimeout(2000);
        console.log(`  Found ${errors.length} console errors`);
        return errors;
    }
    /**
     * Analyze widget tree structure
     */
    async analyzeWidgetTree() {
        console.log('🌳 Analyzing widget tree...');
        // Try to access Flutter DevTools or widget inspector
        const widgetInfo = await this.page.evaluate(() => {
            // This would access Flutter's widget tree if available
            return {
                timestamp: Date.now(),
                url: window.location.href,
                // Add Flutter-specific inspection here
            };
        });
        console.log('  Widget tree info:', widgetInfo);
        return widgetInfo;
    }
    /**
     * Monitor network requests for debugging
     */
    async monitorNetworkActivity() {
        console.log('🌐 Monitoring network activity...');
        const requests = [];
        const responses = [];
        this.page.on('request', (request) => {
            requests.push({
                url: request.url(),
                method: request.method(),
                timestamp: Date.now()
            });
        });
        this.page.on('response', (response) => {
            responses.push({
                url: response.url(),
                status: response.status(),
                timestamp: Date.now()
            });
        });
        // Monitor for 5 seconds
        await this.page.waitForTimeout(5000);
        console.log(`  Requests: ${requests.length}, Responses: ${responses.length}`);
        return { requests, responses };
    }
    /**
     * Performance profiling
     */
    async profilePerformance() {
        console.log('⚡ Profiling performance...');
        const metrics = await this.page.evaluate(() => {
            const navigation = performance.getEntriesByType('navigation')[0];
            return {
                domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
                loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
                domInteractive: navigation.domInteractive - navigation.fetchStart,
                responseTime: navigation.responseEnd - navigation.requestStart
            };
        });
        console.log('  Performance metrics:', metrics);
        return metrics;
    }
    /**
     * Memory usage analysis
     */
    async analyzeMemoryUsage() {
        console.log('💾 Analyzing memory usage...');
        const memory = await this.page.evaluate(() => {
            if ('memory' in performance) {
                const mem = performance.memory;
                return {
                    usedJSHeapSize: mem.usedJSHeapSize,
                    totalJSHeapSize: mem.totalJSHeapSize,
                    jsHeapSizeLimit: mem.jsHeapSizeLimit,
                    usedPercentage: (mem.usedJSHeapSize / mem.jsHeapSizeLimit * 100).toFixed(2)
                };
            }
            return null;
        });
        console.log('  Memory usage:', memory);
        return memory;
    }
    /**
     * Complete diagnostic report for AI analysis
     */
    async generateDiagnosticReport() {
        console.log('\n🔬 Generating Complete Diagnostic Report\n');
        const report = {
            timestamp: new Date().toISOString(),
            screenshot: await this.captureStateForAI('diagnostic'),
            consoleErrors: await this.extractConsoleErrors(),
            widgetTree: await this.analyzeWidgetTree(),
            network: await this.monitorNetworkActivity(),
            performance: await this.profilePerformance(),
            memory: await this.analyzeMemoryUsage()
        };
        console.log('\n📋 Diagnostic Report Generated');
        console.log('  Console Errors:', report.consoleErrors.length);
        console.log('  Network Requests:', report.network.requests.length);
        console.log('  Memory Usage:', report.memory?.usedPercentage + '%');
        return report;
    }
}
exports.AIDebugging = AIDebugging;
//# sourceMappingURL=ai-debugging.js.map