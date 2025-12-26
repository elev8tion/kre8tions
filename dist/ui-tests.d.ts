import { Page } from 'playwright-core';
/**
 * Automated UI Panel Tests for KRE8TIONS IDE
 */
export declare class UITests {
    private page;
    constructor(page: Page);
    /**
     * Test File Tree Panel (Ctrl+1)
     */
    testFileTreePanel(): Promise<boolean>;
    /**
     * Test Code Editor Panel (Ctrl+2)
     */
    testCodeEditor(): Promise<boolean>;
    /**
     * Test UI Preview Panel (Ctrl+3)
     */
    testUIPreview(): Promise<boolean>;
    /**
     * Test AI Assistant Panel (Ctrl+4)
     */
    testAIAssistant(): Promise<boolean>;
    /**
     * Test Terminal Panel (Ctrl+5)
     */
    testTerminal(): Promise<boolean>;
    /**
     * Run all panel tests
     */
    runAllPanelTests(): Promise<{
        fileTree: boolean;
        codeEditor: boolean;
        uiPreview: boolean;
        aiAssistant: boolean;
        terminal: boolean;
    }>;
}
//# sourceMappingURL=ui-tests.d.ts.map