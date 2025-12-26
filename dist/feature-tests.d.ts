import { Page } from 'playwright-core';
/**
 * Feature Testing Automation for Code Editor
 */
export declare class FeatureTests {
    private page;
    constructor(page: Page);
    /**
     * Test syntax highlighting
     */
    testSyntaxHighlighting(): Promise<boolean>;
    /**
     * Test code autocompletion
     */
    testAutocompletion(): Promise<boolean>;
    /**
     * Test file tree navigation
     */
    testFileTreeNavigation(): Promise<boolean>;
    /**
     * Test live preview updates
     */
    testLivePreview(): Promise<boolean>;
    /**
     * Test error detection
     */
    testErrorDetection(): Promise<boolean>;
    /**
     * Test keyboard shortcuts
     */
    testKeyboardShortcuts(): Promise<{
        fileTree: boolean;
        codeEditor: boolean;
        preview: boolean;
        aiAssistant: boolean;
        terminal: boolean;
    }>;
    /**
     * Test project upload/export
     */
    testProjectManagement(): Promise<boolean>;
    /**
     * Test AI assistant integration
     */
    testAIIntegration(): Promise<boolean>;
    /**
     * Run complete feature test suite
     */
    runCompleteFeatureTests(): Promise<{
        syntaxHighlighting: boolean;
        autocompletion: boolean;
        fileTreeNavigation: boolean;
        livePreview: boolean;
        errorDetection: boolean;
        keyboardShortcuts: {
            fileTree: boolean;
            codeEditor: boolean;
            preview: boolean;
            aiAssistant: boolean;
            terminal: boolean;
        };
        projectManagement: boolean;
        aiIntegration: boolean;
    }>;
}
//# sourceMappingURL=feature-tests.d.ts.map