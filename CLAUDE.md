# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KRE8TIONS** - A web-based Flutter IDE with AI-powered development capabilities. The project enables developers to upload, edit, and preview Flutter projects directly in the browser with intelligent code assistance.

## Development Commands

### Build and Run
```bash
# Install dependencies
flutter pub get

# Run web development server
flutter run -d chrome --web-renderer html

# Build for production
flutter build web --release --web-renderer html

# Clean build artifacts
flutter clean
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/project_manager_test.dart

# Run integration tests
flutter test test/integration/
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated
```

## Architecture Overview

### Core Services Architecture

The application uses a **Service Orchestrator** pattern (`lib/services/service_orchestrator.dart`) that coordinates all major services:

1. **ServiceOrchestrator** - Central command center managing:
   - Live code execution and preview
   - Real-time error detection
   - Dependency management
   - State persistence
   - Health monitoring and auto-healing

2. **AppStateManager** (`lib/services/app_state_manager.dart`) - Manages application state with:
   - Automatic state persistence to SharedPreferences
   - Panel visibility states
   - Project and file selection
   - Recent projects tracking

3. **CodeExecutionService** - Handles:
   - Live code analysis
   - Project execution simulation
   - Hot reload functionality
   - Error detection and reporting

4. **DartIntelligenceService** - Provides:
   - Code completion
   - Go-to-definition
   - Symbol navigation
   - Context-aware suggestions

### UI Architecture

The main UI (`lib/screens/home_page.dart`) implements a sophisticated multi-panel IDE layout:

- **File Tree Panel** (left) - Project file explorer
- **Code Editor** (center) - Enhanced code editing with syntax highlighting
- **UI Preview Panel** (right) - Visual preview of Flutter widgets
- **AI Assistant Panel** (far right) - Context-aware AI help
- **Terminal Panel** (bottom) - Command execution and output

All panels are:
- Collapsible/expandable
- Keyboard shortcut enabled (Ctrl+1 through Ctrl+5)
- Responsive to screen size
- State-persisted across sessions

### Key Design Patterns

1. **Singleton Services** - Most services use singleton pattern for global access
2. **Stream-based Communication** - Services communicate via broadcast streams
3. **State Persistence** - Automatic saving/loading of workspace state
4. **Error Boundaries** - Safe UI preview with error handling
5. **Debounced Analysis** - Live code analysis with intelligent debouncing

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── theme.dart                   # Custom theme definitions
├── screens/
│   └── home_page.dart          # Main IDE interface
├── services/                   # Core business logic
│   ├── service_orchestrator.dart    # Central service coordinator
│   ├── app_state_manager.dart       # State management
│   ├── code_execution_service.dart  # Code execution
│   ├── dart_intelligence_service.dart # Code intelligence
│   └── ...                          # Other services
├── widgets/                    # Reusable UI components
│   ├── enhanced_code_editor.dart
│   ├── file_tree_view.dart
│   └── ...
└── models/                     # Data models
    ├── flutter_project.dart
    ├── project_file.dart
    └── ...
```

## Key Features Implementation

### Live Code Analysis
The system performs real-time code analysis through the orchestrator pattern. When code changes, it flows through:
1. `EnhancedCodeEditor` → 2. `HomePage._updateFileContent()` → 3. `ServiceOrchestrator.updateCode()` → 4. Analysis results broadcast to UI

### State Persistence
AppStateManager automatically saves state on every change with a 500ms debounce. State includes panel visibility, selected files, and project data.

### Health Monitoring
ServiceOrchestrator performs periodic health checks including:
- Memory usage monitoring
- Service connectivity verification
- Performance metrics tracking
- State consistency validation
- Automatic issue remediation

## Development Notes

- The app requires Flutter 3.6.0+ (SDK constraint: ^3.6.0)
- Web renderer is set to HTML for better compatibility
- All file operations use in-memory storage (no server backend)
- Project upload/export via ZIP files only
- AI features require OpenAI API key configuration