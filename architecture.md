# CodeWhisper - Flutter Project AI Editor Architecture

## Overview
A sophisticated web application for uploading, editing Flutter projects with OpenAI LLM assistance, and exporting the modified projects.

## Core Features (MVP)
1. **Project Upload**: Upload Flutter project as ZIP file
2. **Project Browser**: Navigate and view project files in a tree structure
3. **Code Editor**: Edit individual files with syntax highlighting
4. **AI Assistant**: Integrate with OpenAI for code suggestions and improvements
5. **Project Export**: Download modified project as ZIP file

## Technical Architecture

### Core Components
1. **ProjectManager**: Handles project upload/export and file management
2. **FileTreeView**: Displays project structure with expandable tree
3. **CodeEditor**: Code editing interface with syntax highlighting
4. **AIAssistant**: OpenAI integration for code improvements
5. **HomePage**: Main interface orchestrating all components

### Data Models
- **FlutterProject**: Project metadata and file structure
- **ProjectFile**: Individual file data (path, content, type)
- **AIRequest/Response**: OpenAI API interaction models

### File Structure
```
lib/
├── main.dart              # App entry point
├── theme.dart            # Updated theme with code editor colors
├── models/
│   ├── flutter_project.dart
│   └── project_file.dart
├── services/
│   ├── project_manager.dart
│   └── file_operations.dart
├── openai/
│   └── openai_config.dart
├── screens/
│   └── home_page.dart
└── widgets/
    ├── file_tree_view.dart
    ├── code_editor.dart
    └── ai_assistant_panel.dart
```

## Implementation Steps
1. Update dependencies in pubspec.yaml
2. Create data models for project and file management
3. Implement project upload/download functionality
4. Build file tree navigation component
5. Create code editor with basic syntax highlighting
6. Integrate OpenAI API for code assistance
7. Implement project export functionality
8. Add responsive layout and UI polish
9. Test and debug the complete application

## Technical Constraints
- Web-only application (no mobile deployment)
- Client-side file processing using Archive library
- OpenAI API integration for code improvements
- Local storage for temporary project data
- Modern Material Design 3 interface