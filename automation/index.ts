import { setupPlaywriter, cleanupPlaywriter } from './setup';
import { UITests } from './ui-tests';
import { WorkflowAutomation } from './workflow-automation';
import { AIDebugging } from './ai-debugging';
import { FeatureTests } from './feature-tests';

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
    const setup = await setupPlaywriter();
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
    const uiTests = new UITests(page);
    const workflowAutomation = new WorkflowAutomation(page);
    const aiDebugging = new AIDebugging(page);
    const featureTests = new FeatureTests(page);

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

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    // Cleanup
    if (browser && server) {
      await cleanupPlaywriter(browser, server);
    }
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

// Export for programmatic usage
export {
  setupPlaywriter,
  cleanupPlaywriter,
  UITests,
  WorkflowAutomation,
  AIDebugging,
  FeatureTests
};
