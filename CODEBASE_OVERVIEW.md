# CodeWhisper - Complete Codebase Overview

## Project Description
CodeWhisper is an AI-powered, web-based Flutter IDE that allows developers to upload Flutter projects, edit code with intelligent assistance, preview UI components, and export modified projects. The application features collapsible panels, live UI preview with widget selection, and context-aware AI assistance.

## Architecture Overview

### Core Features
- 🚀 **Web-based IDE** - Full Flutter development environment in the browser
- 📁 **Project Management** - Upload/download Flutter projects as ZIP files
- 🎨 **Live UI Preview** - Visual representation of Flutter widgets with selection
- 🤖 **AI Assistant** - Context-aware code improvement, generation, and explanation
- 📱 **Responsive Layout** - Collapsible panels with keyboard shortcuts
- 🎯 **Widget-level Intelligence** - Select specific widgets for targeted AI assistance

---

## File Structure & Components

### 🏠 Entry Point
- `lib/main.dart` - Application entry point with theme configuration
- `lib/screens/home_page.dart` - Main IDE interface with collapsible panel system

### 🎨 UI Components
- `lib/widgets/file_tree_view.dart` - Project file explorer with tree structure
- `lib/widgets/code_editor.dart` - Syntax-highlighted code editor with line numbers
- `lib/widgets/ai_assistant_panel.dart` - AI-powered code assistant interface
- `lib/widgets/ui_preview_panel.dart` - Live UI preview with widget selection

### 📊 Data Models
- `lib/models/flutter_project.dart` - Project structure representation
- `lib/models/project_file.dart` - Individual file metadata and content
- `lib/models/widget_selection.dart` - Widget selection state management

### 🔧 Services
- `lib/services/project_manager.dart` - ZIP project import/export logic
- `lib/services/file_operations.dart` - Web file operations (upload/download)
- `lib/services/flutter_analyzer.dart` - Widget tree analysis (mock implementation)

### 🤖 AI Integration
- `lib/openai/openai_config.dart` - OpenAI API configuration and service

### 🎭 Theming
- `lib/theme.dart` - Material 3 light/dark theme definitions

---

## Detailed Code Documentation

### 📱 main.dart
```dart
import 'package:flutter/material.dart';
import 'package:codewhisper/theme.dart';
import 'package:codewhisper/screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeWhisper - AI Flutter Editor',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

### 🏠 home_page.dart (Main Interface)
**Key Features:**
- Responsive design with minimum 1200px width requirement
- Three collapsible panels: Explorer, UI Preview, AI Assistant
- Keyboard shortcuts: Ctrl+1/2/3 for panel toggles, Ctrl+B for collapse all
- Project upload/download functionality
- Sample project for immediate functionality

**Panel Management:**
```dart
// Panel state management
bool _showAIPanel = true;
bool _showUIPreview = true; 
bool _showFileTree = true;
bool _isFileTreeCollapsed = false;
bool _isUIPreviewCollapsed = false;
bool _isAIPanelCollapsed = false;

// Keyboard shortcuts handler
void _handleKeyEvent(KeyEvent event) {
  if (event is KeyDownEvent) {
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    
    if (isCtrlPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.digit1:
          setState(() => _showFileTree = !_showFileTree);
          break;
        case LogicalKeyboardKey.digit2:
          setState(() => _showUIPreview = !_showUIPreview);
          break;
        case LogicalKeyboardKey.digit3:
          setState(() => _showAIPanel = !_showAIPanel);
          break;
        case LogicalKeyboardKey.keyB:
          // Toggle all panels collapsed/expanded
          final shouldCollapse = !(_isFileTreeCollapsed && _isUIPreviewCollapsed && _isAIPanelCollapsed);
          setState(() {
            _isFileTreeCollapsed = shouldCollapse;
            _isUIPreviewCollapsed = shouldCollapse;
            _isAIPanelCollapsed = shouldCollapse;
          });
          break;
      }
    }
  }
}
```

### 📁 file_tree_view.dart
**Features:**
- Hierarchical file tree display
- Expandable directories
- File type icons
- Selection highlighting
- Auto-expansion of `lib` directory

### ✏️ code_editor.dart
**Features:**
- Line-numbered code display
- Syntax highlighting container
- Copy to clipboard functionality
- Real-time content change tracking
- Support for text/binary file differentiation

### 🤖 ai_assistant_panel.dart
**AI Actions:**
- **✨ Improve** - Code quality enhancement
- **🔧 Generate** - New code creation
- **💡 Explain** - Code explanation

**Features:**
- Context-aware prompts based on selected widgets
- OpenAI API integration
- Response copying and code application
- Visual widget context display

### 🎨 ui_preview_panel.dart
**Features:**
- Mock Flutter app preview
- Widget selection system
- Mobile/web view toggle
- Interactive widget highlighting
- Widget detail display

### 📊 Data Models

**FlutterProject:**
```dart
class FlutterProject {
  final String name;
  final List<ProjectFile> files;
  final DateTime uploadedAt;
  
  // Helper methods
  List<ProjectFile> get dartFiles => files.where((f) => f.isDartFile).toList();
  ProjectFile? get pubspecFile => files.where((f) => f.fileName == 'pubspec.yaml').firstOrNull;
  bool get isValidFlutterProject => pubspecFile != null && files.any((f) => f.path.contains('lib/main.dart'));
}
```

**ProjectFile:**
```dart
class ProjectFile {
  final String path;
  final String content;
  final FileType type;
  final bool isDirectory;
  
  String get fileName => path.split('/').last;
  bool get isDartFile => extension == 'dart';
  bool get isTextFile => isDartFile || isYamlFile || isJsonFile || extension == 'md' || extension == 'txt';
}
```

**WidgetSelection:**
```dart
class WidgetSelection {
  final String widgetType;
  final String widgetId;
  final String filePath;
  final int lineNumber;
  final Map<String, dynamic> properties;
  final String sourceCode;
}
```

### 🔧 Services

**ProjectManager:**
- ZIP file parsing and creation
- Project validation
- File filtering (excludes build directories)
- Binary/text file handling

**FileOperations:**
- Web file upload/download
- File type detection
- Size formatting
- Path sanitization

**FlutterAnalyzer:**
- Widget tree analysis (mock implementation)
- Project structure parsing
- Widget hierarchy building

### 🤖 OpenAI Integration
```dart
class OpenAIConfig {
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');
  static const String model = 'gpt-4o';
}

class OpenAIService {
  static Future<String> improveCode({required String code, required String fileName, String? context});
  static Future<String> generateCode({required String description, required String fileName});
  static Future<String> explainCode({required String code, required String fileName});
}
```

### 🎭 Theme System
**Material 3 Design:**
- Light and dark mode support
- Custom color schemes
- Google Fonts (Inter) integration
- Consistent design tokens

**Color Palette:**
```dart
// Light Mode
static const lightPrimary = Color(0xFF6366F1);        // Indigo
static const lightSecondary = Color(0xFF64748B);      // Slate
static const lightTertiary = Color(0xFF059669);       // Emerald

// Dark Mode  
static const darkPrimary = Color(0xFF818CF8);         // Light Indigo
static const darkSecondary = Color(0xFF94A3B8);       // Light Slate
static const darkTertiary = Color(0xFF34D399);        // Light Emerald
```

### 📦 Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.1.0          # Typography
  file_picker: '>=8.1.2'        # File uploads
  http: ^1.0.0                  # API requests
  archive: ^4.0.0               # ZIP handling
  universal_html: ^2.0.0        # Web compatibility
  shared_preferences: ^2.0.0     # Local storage

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 🚀 Key Features Implementation

### 1. Collapsible Panel System
- Smooth 300ms animations with `AnimatedContainer`
- Contextual borders and visual feedback
- Keyboard shortcuts for power users
- Responsive width calculations

### 2. File Management
- ZIP project upload/download
- Intelligent file filtering
- Binary file detection
- Project structure validation

### 3. AI Integration
- Context-aware prompting
- Widget-specific assistance
- Multiple AI actions (improve, generate, explain)
- Error handling and API management

### 4. Live UI Preview
- Interactive widget selection
- Mobile/web responsive preview
- Visual selection indicators
- Mock Flutter app representation

### 5. Code Editor
- Line numbering system
- Syntax highlighting container
- Real-time change detection
- Copy functionality

---

## 🎯 Usage Patterns

### Developer Workflow
1. **Upload Project** - Drag & drop or select Flutter ZIP
2. **Navigate Files** - Use file tree to explore project structure  
3. **Edit Code** - Select files and modify in the editor
4. **Preview UI** - See visual representation and select widgets
5. **AI Assistance** - Get contextual help for selected components
6. **Export** - Download modified project as ZIP

### Panel Management
- **Ctrl+1** - Toggle File Explorer
- **Ctrl+2** - Toggle UI Preview  
- **Ctrl+3** - Toggle AI Assistant
- **Ctrl+B** - Collapse/Expand All Panels

---

## 🔧 Technical Specifications

### Browser Support
- Modern web browsers with ES6+ support
- Minimum screen width: 1200px for optimal experience
- Mobile displays show "Desktop Only" message

### Performance
- Lazy loading of file contents
- Efficient widget tree management
- Optimized ZIP processing
- Responsive UI with smooth animations

### Security
- Client-side only file processing
- No server-side storage
- API keys through environment variables
- Input sanitization for file operations

---

## 🚧 Future Enhancements

### Potential Features
- **Real Terminal Integration** - Execute Flutter commands
- **Hot Reload Support** - Live code updates
- **Git Integration** - Version control features
- **Plugin System** - Extensible architecture
- **Collaboration** - Multi-user editing
- **Advanced Debugging** - Breakpoints and inspection

### Architecture Improvements
- **Real Widget Analysis** - Parse actual Dart AST
- **Performance Monitoring** - Build time tracking
- **Error Boundaries** - Better error handling
- **Offline Support** - Service worker implementation

---

## 📝 Development Notes

### Code Style
- Consistent Material 3 theming
- Responsive design patterns
- Clean separation of concerns
- Comprehensive error handling

### Best Practices
- Widget composition over inheritance
- Immutable data models
- Proper disposal of controllers
- Accessibility considerations

---

*Generated: ${DateTime.now().toString()}*
*Total Files: 13 Dart files + 1 pubspec.yaml*
*Lines of Code: ~3,500+*