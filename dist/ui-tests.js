"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UITests = void 0;
/**
 * Automated UI Panel Tests for KRE8TIONS IDE
 */
class UITests {
    constructor(page) {
        this.page = page;
    }
    /**
     * Test File Tree Panel (Ctrl+1)
     */
    async testFileTreePanel() {
        console.log('🧪 Testing File Tree Panel...');
        // Toggle panel with keyboard shortcut
        await this.page.keyboard.press('Control+1');
        await this.page.waitForTimeout(500);
        // Verify panel visibility
        const fileTreeVisible = await this.page.locator('[class*="file-tree"]').isVisible();
        console.log(`  File Tree visible: ${fileTreeVisible}`);
        // Click on a file
        await this.page.click('[class*="file-item"]').catch(() => console.log('  No files available to click'));
        return fileTreeVisible;
    }
    /**
     * Test Code Editor Panel (Ctrl+2)
     */
    async testCodeEditor() {
        console.log('🧪 Testing Code Editor Panel...');
        await this.page.keyboard.press('Control+2');
        await this.page.waitForTimeout(500);
        const editorVisible = await this.page.locator('[class*="code-editor"]').isVisible();
        console.log(`  Code Editor visible: ${editorVisible}`);
        // Test typing in editor
        await this.page.click('[class*="code-editor"]').catch(() => console.log('  Could not focus editor'));
        return editorVisible;
    }
    /**
     * Test UI Preview Panel (Ctrl+3)
     */
    async testUIPreview() {
        console.log('🧪 Testing UI Preview Panel...');
        await this.page.keyboard.press('Control+3');
        await this.page.waitForTimeout(500);
        const previewVisible = await this.page.locator('[class*="preview"]').isVisible();
        console.log(`  UI Preview visible: ${previewVisible}`);
        return previewVisible;
    }
    /**
     * Test AI Assistant Panel (Ctrl+4)
     */
    async testAIAssistant() {
        console.log('🧪 Testing AI Assistant Panel...');
        await this.page.keyboard.press('Control+4');
        await this.page.waitForTimeout(500);
        const aiVisible = await this.page.locator('[class*="ai-assistant"]').isVisible();
        console.log(`  AI Assistant visible: ${aiVisible}`);
        return aiVisible;
    }
    /**
     * Test Terminal Panel (Ctrl+5)
     */
    async testTerminal() {
        console.log('🧪 Testing Terminal Panel...');
        await this.page.keyboard.press('Control+5');
        await this.page.waitForTimeout(500);
        const terminalVisible = await this.page.locator('[class*="terminal"]').isVisible();
        console.log(`  Terminal visible: ${terminalVisible}`);
        return terminalVisible;
    }
    /**
     * Run all panel tests
     */
    async runAllPanelTests() {
        console.log('\n🎯 Running All Panel Tests\n');
        const results = {
            fileTree: await this.testFileTreePanel(),
            codeEditor: await this.testCodeEditor(),
            uiPreview: await this.testUIPreview(),
            aiAssistant: await this.testAIAssistant(),
            terminal: await this.testTerminal()
        };
        console.log('\n📊 Test Results:', results);
        return results;
    }
}
exports.UITests = UITests;
//# sourceMappingURL=ui-tests.js.map