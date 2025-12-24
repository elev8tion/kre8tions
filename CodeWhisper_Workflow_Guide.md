# 🚀 CodeWhisper Workflow Guide
*A Comprehensive Technical Documentation for Understanding and Debugging CodeWhisper's Operational Workflows*

---

## 📋 Table of Contents
1. [Architecture Overview](#-architecture-overview)
2. [Application Initialization Flow](#-application-initialization-flow)
3. [Service Orchestrator - Central Command](#-service-orchestrator---central-command)
4. [Project Management Workflow](#-project-management-workflow)
5. [Live Code Execution & Analysis](#-live-code-execution--analysis)
6. [UI Components & User Interactions](#-ui-components--user-interactions)
7. [AI Integration & Code Generation](#-ai-integration--code-generation)
8. [State Management & Persistence](#-state-management--persistence)
9. [Error Handling & Recovery](#-error-handling--recovery)
10. [Development & Debugging Tips](#-development--debugging-tips)

---

## 🏗️ Architecture Overview

CodeWhisper is built as a **web-based Flutter IDE** with a sophisticated service-oriented architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                        CodeWhisper IDE                          │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer:  HomePage → Panels (File Tree, Editor, Preview, AI)  │
│  ├─ Enhanced Code Editor (Syntax, Intelligence, Navigation)     │
│  ├─ UI Preview Panel (Live Preview, Widget Selection)           │
│  └─ AI Terminal Panel (Assistant + Terminal Combined)           │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer: ServiceOrchestrator (Central Coordination)      │
│  ├─ CodeExecutionService (Live Analysis, Hot Reload)            │
│  ├─ DartIntelligenceService (Language Features)                 │
│  ├─ AppStateManager (State & Persistence)                       │
│  ├─ ProjectManager (File Operations)                            │
│  └─ DependencyManager, AI Services, etc.                        │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer: Models (Project, Files, Widgets, Analysis)         │
│  └─ StatePersistenceService (LocalStorage)                      │
└─────────────────────────────────────────────────────────────────┘
```

### 🔑 Key Design Principles:
- **Service Orchestration**: `ServiceOrchestrator` coordinates all operations
- **Real-time Analysis**: Live code execution with instant feedback
- **State Persistence**: Auto-save with crash recovery
- **Modular Architecture**: Each service handles specific responsibilities
- **Event-Driven**: Reactive streams for real-time updates

---

## 🚀 Application Initialization Flow

### 1. **App Startup** (`main.dart`)
```dart
void main() {
  runApp(const MyApp()); // Flutter app entry point
}
```

### 2. **App State Setup** (`_MyAppState`)
- Creates `AppStateManager` singleton
- Sets up theme management (light/dark modes)
- Initializes `HomePage` with state manager

### 3. **State Manager Initialization** (`AppStateManager._initializeState()`)
```
1. Load UI preferences from local storage
   ├─ Panel visibility states
   ├─ Collapsed/expanded states  
   ├─ Panel sizes
   └─ User preferences

2. Load session data
   ├─ Recent projects
   ├─ Search history
   └─ Editor states

3. Load project state (if exists)
   ├─ Current project files
   ├─ Selected file
   └─ Selected widget

4. Start auto-save timer
   └─ Periodic state persistence
```

### 4. **Service Orchestrator Initialization** (`ServiceOrchestrator._initialize()`)
```
1. Initialize core services
   ├─ CodeExecutionService
   ├─ DependencyManager
   └─ AppStateManager reference

2. Setup service streams
   ├─ Execution result stream
   ├─ Error detection stream
   └─ Widget tree updates

3. Start monitoring
   ├─ Health monitoring (5-minute intervals)
   ├─ Dependency monitoring (1-hour intervals)
   └─ Session restoration

4. Broadcast initialization complete
```

### 5. **HomePage Initialization** (`_HomePageState.initState()`)
```
1. Setup orchestrator listeners
   ├─ Live analysis updates
   ├─ Project events
   └─ Error notifications

2. Load sample project (if no project exists)
   ├─ Create default Flutter app
   ├─ Setup basic file structure
   └─ Initialize UI state
```

---

## 🎯 Service Orchestrator - Central Command

The `ServiceOrchestrator` is the **heart** of CodeWhisper, coordinating all operations:

### 🔄 Core Responsibilities:
1. **Project Loading**: Full project analysis with dependency checking
2. **Live Code Execution**: Real-time compilation and preview generation
3. **File Management**: Coordinate file changes across services
4. **Error Detection**: Aggregate errors from multiple sources
5. **Hot Reload**: Simulate Flutter's hot reload functionality
6. **Health Monitoring**: System status and performance tracking

### 📊 Data Flow:
```
User Action → ServiceOrchestrator → Core Services → Stream Updates → UI Updates
     ↓                ↓                    ↓              ↓           ↓
Load Project → ProjectManager → CodeExecution → Analysis → Live Preview
Edit Code → AppStateManager → LiveAnalysis → ErrorDetection → Editor Hints
Hot Reload → CodeExecution → WidgetTree → PreviewData → UI Update
```

### 🎛️ Event System:
The orchestrator uses three main streams:
- **Event Stream**: Project loading, hot reload, dependency updates
- **Analysis Stream**: Live code analysis results
- **Health Stream**: System health and performance metrics

---

## 📂 Project Management Workflow

### 1. **Project Loading** (`ServiceOrchestrator.loadProject()`)
```
Input: ZIP file bytes + filename
     ↓
1. ProjectManager.loadProjectFromZip()
   ├─ Extract ZIP archive
   ├─ Filter Flutter-relevant files
   ├─ Parse file contents (text/binary)
   └─ Create FlutterProject model

2. Validate Flutter Project
   ├─ Check for pubspec.yaml
   ├─ Check for lib/main.dart
   └─ Verify project structure

3. Service Integration
   ├─ AppStateManager.setCurrentProject()
   ├─ DependencyManager.checkAllSystems()
   └─ CodeExecutionService.executeProject()

4. Analysis & Feedback
   ├─ Generate dependency suggestions
   ├─ Analyze project structure
   ├─ Create live preview
   └─ Broadcast ProjectLoadResult
```

### 2. **File Operations** (`ProjectManager`)
- **Create File**: Validate path, create ProjectFile, update project
- **Delete File**: Remove from project files list
- **Rename File**: Update path and file references
- **Directory Operations**: Handle folder creation/deletion/renaming
- **Content Updates**: Sync changes across all services

### 3. **File Tree Management**
```
FileTreeView receives FlutterProject
     ↓
1. Group files by directory
2. Build hierarchical tree structure
3. Handle expand/collapse states
4. Process file selection events
5. Notify AppStateManager of changes
```

---

## ⚡ Live Code Execution & Analysis

### 🔥 CodeExecutionService Workflow:

### 1. **Project Execution** (`executeProject()`)
```
Input: FlutterProject + optional entry point
     ↓
1. Find main.dart or specified entry file
2. Comprehensive Code Analysis
   ├─ DartIntelligenceService.detectErrors()
   ├─ Flutter-specific analysis
   ├─ Project structure analysis
   └─ Performance analysis

3. Widget Tree Generation
   ├─ Parse Flutter widgets from code
   ├─ Build hierarchical structure
   ├─ Extract widget properties
   └─ Calculate layout metrics

4. UI Preview Generation
   ├─ Generate screenshots for different devices
   ├─ Analyze accessibility
   ├─ Calculate performance metrics
   └─ Create PreviewData

5. Result Broadcasting
   ├─ Stream ExecutionResult
   ├─ Update error list
   └─ Notify UI components
```

### 2. **Live Code Analysis** (`analyzeLiveCode()`)
```
Input: Code string + project context
     ↓
1. Debounced Analysis (500ms delay)
2. Error Detection Pipeline
   ├─ Syntax errors
   ├─ Semantic errors  
   ├─ Flutter-specific issues
   └─ Performance warnings

3. Real-time Widget Tree Update
4. Error Stream Broadcasting
```

### 3. **Hot Reload Simulation** (`hotReload()`)
```
1. Re-execute current project
2. Generate fresh widget tree
3. Update UI preview
4. Stream results to UI components
5. Show user feedback (success/failure)
```

---

## 🖥️ UI Components & User Interactions

### 1. **HomePage Layout Structure**
```
Responsive Web Layout (min-width: 1200px)
├─ Web App Bar
│  ├─ Logo + Project name
│  ├─ Panel toggle buttons  
│  └─ Project actions (export, share, close)
├─ Demo Banner (if sample project)
└─ Main Content Area
   ├─ File Tree Panel (collapsible)
   ├─ Code Editor Panel (flexible)
   ├─ UI Preview Panel (collapsible)
   └─ AI Terminal Panel (collapsible)
```

### 2. **Enhanced Code Editor** (`EnhancedCodeEditor`)
```
Features:
├─ Syntax Highlighting (DartIntelligenceService)
├─ Error Squiggles (from live analysis)
├─ Autocomplete Suggestions (overlay)
├─ Go-to-Definition (F12)
├─ Find References (Ctrl+D)
├─ Hover Information
└─ Live Analysis Integration

Workflow:
1. Text changes trigger _onTextChanged()
2. Update line count and analyze code
3. Rebuild symbol index for navigation
4. Show autocomplete if appropriate
5. Trigger live analysis via orchestrator
6. Update UI with analysis results
```

### 3. **UI Preview Panel** (`UIPreviewPanel`)
```
Components:
├─ Preview Header (device selection, mode toggle)
├─ Mock UI Preview OR Live Preview
├─ Widget Selection (clickable UI elements)
└─ Widget Inspector Panel (properties)

Live Integration:
1. Listen to ServiceOrchestrator analysis stream
2. Receive ExecutionResult with widget tree
3. Update preview with live data
4. Handle widget selection events
5. Update visual properties in real-time
```

### 4. **AI Terminal Combined Panel**
```
Layout:
├─ AI Assistant Panel (60% height)
│  ├─ Context-aware conversations
│  ├─ Code generation
│  └─ File operations
├─ Resizable Divider
└─ Terminal Panel (40% height)
   ├─ Command execution simulation
   ├─ Build output display
   └─ System status information
```

---

## 🤖 AI Integration & Code Generation

### 1. **Context Awareness**
The AI system receives rich context:
```
AI Context Package:
├─ Current File Content
├─ Selected Widget Information
├─ Project Structure Overview
├─ Recent Errors/Warnings
└─ User's Previous Interactions
```

### 2. **Code Generation Flow**
```
User Request → AI Assistant
     ↓
1. Build comprehensive context
2. Send to OpenAI API (if configured)
3. Process AI response
4. Generate code/files
5. Apply to project via orchestrator
6. Trigger hot reload
7. Show user feedback
```

### 3. **File Operations**
- **Single File Updates**: Direct content replacement
- **Multiple File Generation**: Download as ZIP or individual files
- **Code Integration**: Smart merging with existing code
- **Error Recovery**: Rollback on compilation failures

---

## 💾 State Management & Persistence

### 🏪 AppStateManager Architecture:

### 1. **State Categories**
```
Project State:
├─ Current project files
├─ Selected file path
├─ Selected widget
└─ Upload status

UI State:
├─ Panel visibility flags
├─ Collapsed/expanded states
├─ Panel sizes
└─ Theme preferences

Session State:
├─ Recent projects
├─ Search history
├─ Editor cursor positions
└─ Temporary data

User Preferences:
├─ Auto-save interval
├─ Editor settings
├─ Preview preferences
└─ AI configuration
```

### 2. **Persistence Strategy**
```
Auto-save Timer (configurable interval):
1. Serialize all state categories
2. Save to browser LocalStorage
3. Handle storage quota limits
4. Provide error recovery

Manual Operations:
├─ Force save (before navigation/close)
├─ Clear project data only
├─ Clear all data (reset)
└─ Export state (debugging)
```

### 3. **State Restoration**
```
App Startup:
1. Load UI preferences → Apply immediately
2. Load session data → Restore history
3. Load user preferences → Configure services
4. Load project state → Restore project if exists
5. Start auto-save timer
```

---

## 🔧 Error Handling & Recovery

### 1. **Error Detection Pipeline**
```
Multiple Error Sources:
├─ DartIntelligenceService (syntax, semantic)
├─ CodeExecutionService (compilation, runtime)
├─ ProjectManager (file operations)
├─ ServiceOrchestrator (system errors)
└─ AI Services (API failures)

Error Aggregation:
1. Each service reports errors via streams
2. ServiceOrchestrator collects and categorizes
3. UI components receive filtered error lists
4. User sees contextual error information
```

### 2. **Recovery Mechanisms**
```
Automatic Recovery:
├─ State persistence prevents data loss
├─ Service restart on critical failures
├─ Fallback to basic analysis if live analysis fails
└─ Sample project loading if no project exists

User-Initiated Recovery:
├─ Hot reload to fix preview issues
├─ Auto-fix dependencies
├─ Reset to defaults
└─ Clear corrupted data
```

### 3. **Error Display Strategy**
- **Editor**: Inline squiggles with hover details
- **Preview**: Status indicators and error overlays  
- **Terminal**: Detailed error logs and suggestions
- **Notifications**: Toast messages for system events

---

## 🛠️ Development & Debugging Tips

### 1. **Debugging Service Orchestrator**
```dart
// Enable debug prints in ServiceOrchestrator
debugPrint('🎯 ServiceOrchestrator: ${event.type} - ${event.message}');

// Monitor streams:
_orchestrator.eventStream.listen((event) {
  print('Event: ${event.type} - ${event.message}');
});

_orchestrator.analysisStream.listen((update) {
  print('Analysis: ${update.file?.path} - ${update.executionResult.success}');
});
```

### 2. **State Manager Debug Info**
```dart
// Get comprehensive state information
final debugInfo = _stateManager.getDebugInfo();
print('State Debug: ${jsonEncode(debugInfo)}');
```

### 3. **Common Issues & Solutions**

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Live Analysis Not Working** | No error highlighting, preview not updating | Check ServiceOrchestrator initialization, verify stream connections |
| **Project Won't Load** | Stuck loading, error messages | Verify ZIP format, check Flutter project structure (pubspec.yaml, lib/main.dart) |
| **Hot Reload Fails** | Preview doesn't update | Check code compilation errors, verify ExecutionResult.success |
| **State Not Persisting** | Settings reset on refresh | Check LocalStorage quotas, verify auto-save timer |
| **Performance Issues** | Slow typing, UI lag | Increase analysis debounce timer, optimize widget rebuilds |

### 4. **Testing Workflows**
```dart
// Test project loading
final testProject = await ProjectManager.loadProjectFromZip(zipBytes, 'test.zip');
assert(testProject != null);
assert(testProject.isValidFlutterProject);

// Test live analysis
final errors = DartIntelligenceService.detectErrors(codeString);
assert(errors.isNotEmpty); // for code with known errors

// Test state persistence
await _stateManager.forceSave();
final saved = _stateManager.getDebugInfo();
// Verify saved state contains expected data
```

### 5. **Performance Monitoring**
```dart
// Monitor execution times
final stopwatch = Stopwatch()..start();
final result = await _orchestrator.loadProject(bytes, filename);
stopwatch.stop();
print('Project load time: ${stopwatch.elapsedMilliseconds}ms');

// Monitor memory usage (DevTools)
// Monitor stream subscription counts
// Watch for memory leaks in overlays and timers
```

---

## 🎯 Workflow Summary

CodeWhisper operates as a **unified development environment** where:

1. **ServiceOrchestrator** coordinates all operations
2. **AppStateManager** handles persistence and UI state
3. **Live analysis** provides real-time feedback
4. **Modular UI** allows flexible workspace layouts
5. **AI integration** assists with code generation
6. **Error handling** provides graceful failure recovery

Each component is designed to work independently while contributing to a seamless user experience. The event-driven architecture ensures that changes in one component immediately reflect across the entire system, creating a responsive and intelligent development environment.

---

*This guide serves as both documentation and debugging reference. When troubleshooting issues, start with the ServiceOrchestrator event logs and work your way through the specific service workflows.*