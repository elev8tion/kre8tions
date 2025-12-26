import { Page } from 'playwright-core';
/**
 * Development Workflow Automation
 */
export declare class WorkflowAutomation {
    private page;
    constructor(page: Page);
    /**
     * Automate project upload workflow
     */
    uploadProject(zipFilePath: string): Promise<void>;
    /**
     * Automate code editing workflow
     */
    editCodeFile(fileName: string, code: string): Promise<void>;
    /**
     * Automate live preview refresh
     */
    refreshPreview(): Promise<void>;
    /**
     * Automate error detection workflow
     */
    checkForErrors(): Promise<number>;
    /**
     * Automate project export
     */
    exportProject(): Promise<import("playwright-core").Download | null>;
    /**
     * Complete development cycle automation
     */
    runDevelopmentCycle(fileName: string, code: string): Promise<void>;
}
//# sourceMappingURL=workflow-automation.d.ts.map