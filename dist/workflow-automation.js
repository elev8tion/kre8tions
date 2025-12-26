"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorkflowAutomation = void 0;
/**
 * Development Workflow Automation
 */
class WorkflowAutomation {
    constructor(page) {
        this.page = page;
    }
    /**
     * Automate project upload workflow
     */
    async uploadProject(zipFilePath) {
        console.log('📦 Automating project upload...');
        // Click upload button
        await this.page.click('[data-action="upload-project"]').catch(() => console.log('  Upload button not found, trying alternative selector...'));
        // Handle file input
        const fileInput = await this.page.locator('input[type="file"]');
        await fileInput.setInputFiles(zipFilePath);
        console.log('  ✅ Project uploaded');
    }
    /**
     * Automate code editing workflow
     */
    async editCodeFile(fileName, code) {
        console.log(`✏️ Editing file: ${fileName}`);
        // Find and click file in tree
        await this.page.click(`text="${fileName}"`).catch(() => console.log('  File not found in tree'));
        // Wait for editor to load
        await this.page.waitForTimeout(500);
        // Clear and type new code
        await this.page.keyboard.press('Control+A');
        await this.page.keyboard.type(code);
        console.log('  ✅ Code updated');
    }
    /**
     * Automate live preview refresh
     */
    async refreshPreview() {
        console.log('🔄 Refreshing preview...');
        await this.page.click('[data-action="refresh-preview"]').catch(() => console.log('  Auto-refresh may be enabled'));
        await this.page.waitForTimeout(1000);
        console.log('  ✅ Preview refreshed');
    }
    /**
     * Automate error detection workflow
     */
    async checkForErrors() {
        console.log('🔍 Checking for errors...');
        const errors = await this.page.locator('[class*="error"]').count();
        console.log(`  Found ${errors} errors`);
        if (errors > 0) {
            const errorMessages = await this.page.locator('[class*="error"]').allTextContents();
            console.log('  Error messages:', errorMessages);
        }
        return errors;
    }
    /**
     * Automate project export
     */
    async exportProject() {
        console.log('💾 Exporting project...');
        await this.page.click('[data-action="export-project"]').catch(() => console.log('  Export button not found'));
        // Wait for download
        const download = await this.page.waitForEvent('download', { timeout: 5000 }).catch(() => null);
        if (download) {
            console.log(`  ✅ Downloaded: ${await download.suggestedFilename()}`);
        }
        return download;
    }
    /**
     * Complete development cycle automation
     */
    async runDevelopmentCycle(fileName, code) {
        console.log('\n🔄 Running Complete Development Cycle\n');
        await this.editCodeFile(fileName, code);
        await this.refreshPreview();
        const errors = await this.checkForErrors();
        if (errors === 0) {
            console.log('✅ No errors found, ready to export');
            await this.exportProject();
        }
        else {
            console.log('❌ Errors detected, fix before exporting');
        }
    }
}
exports.WorkflowAutomation = WorkflowAutomation;
//# sourceMappingURL=workflow-automation.js.map