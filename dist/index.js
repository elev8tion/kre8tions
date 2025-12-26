"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FeatureTests = exports.AIDebugging = exports.WorkflowAutomation = exports.UITests = exports.cleanupPlaywriter = exports.setupPlaywriter = void 0;
const setup_1 = require("./setup");
Object.defineProperty(exports, "setupPlaywriter", { enumerable: true, get: function () { return setup_1.setupPlaywriter; } });
Object.defineProperty(exports, "cleanupPlaywriter", { enumerable: true, get: function () { return setup_1.cleanupPlaywriter; } });
const ui_tests_1 = require("./ui-tests");
Object.defineProperty(exports, "UITests", { enumerable: true, get: function () { return ui_tests_1.UITests; } });
const workflow_automation_1 = require("./workflow-automation");
Object.defineProperty(exports, "WorkflowAutomation", { enumerable: true, get: function () { return workflow_automation_1.WorkflowAutomation; } });
const ai_debugging_1 = require("./ai-debugging");
Object.defineProperty(exports, "AIDebugging", { enumerable: true, get: function () { return ai_debugging_1.AIDebugging; } });
const feature_tests_1 = require("./feature-tests");
Object.defineProperty(exports, "FeatureTests", { enumerable: true, get: function () { return feature_tests_1.FeatureTests; } });
/**
 * Main Playwriter Automation Runner for KRE8TIONS IDE
 *
 * Usage:
 * 1. Install Chrome extension: https://chromewebstore.google.com/detail/playwriter/...
 * 2. Open KRE8TIONS IDE in Chrome (http://localhost:PORT)
 * 3. Click the Playwriter extension icon to connect the tab
 * 4. Run: npm run automation
 */
async function main() {
    console.log('🚀 KRE8TIONS IDE - Playwriter Automation Suite\n');
    let browser, server;
    try {
        // Setup Playwriter
        const setup = await (0, setup_1.setupPlaywriter)();
        browser = setup.browser;
        server = setup.server;
        // Get the first page/tab
        const contexts = browser.contexts();
        const pages = await contexts[0].pages();
        const page = pages[0];
        if (!page) {
            throw new Error('No page found. Make sure to connect a tab using the Playwriter extension.');
        }
        console.log(`📄 Connected to page: ${page.url()}\n`);
        // Initialize test suites
        const uiTests = new ui_tests_1.UITests(page);
        const workflowAutomation = new workflow_automation_1.WorkflowAutomation(page);
        const aiDebugging = new ai_debugging_1.AIDebugging(page);
        const featureTests = new feature_tests_1.FeatureTests(page);
        // Run automated tests based on command line args
        const testType = process.argv[2] || 'all';
        switch (testType) {
            case 'ui':
                await uiTests.runAllPanelTests();
                break;
            case 'workflow':
                await workflowAutomation.runDevelopmentCycle('main.dart', '// Test code');
                break;
            case 'debug':
                await aiDebugging.generateDiagnosticReport();
                break;
            case 'features':
                await featureTests.runCompleteFeatureTests();
                break;
            case 'all':
            default:
                console.log('🔄 Running ALL Test Suites\n');
                await uiTests.runAllPanelTests();
                await featureTests.runCompleteFeatureTests();
                await aiDebugging.generateDiagnosticReport();
                break;
        }
        console.log('\n✅ Automation Complete!');
    }
    catch (error) {
        console.error('❌ Error:', error);
    }
    finally {
        // Cleanup
        if (browser && server) {
            await (0, setup_1.cleanupPlaywriter)(browser, server);
        }
    }
}
// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}
//# sourceMappingURL=index.js.map