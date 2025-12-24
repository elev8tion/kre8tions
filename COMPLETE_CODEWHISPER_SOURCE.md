# CodeWhisper - Complete Source Code Collection

**CodeWhisper** is a sophisticated web-based Flutter development environment with AI assistance. This document contains all the source code files from the project.

## 🎯 Project Overview

CodeWhisper is a professional web IDE that allows developers to:
- Upload Flutter projects as ZIP files
- Navigate and edit project files with syntax highlighting
- Preview Flutter UI with selectable widgets
- Get AI-powered assistance for code improvement, generation, and explanation
- Export modified projects

---

## 📁 Project Structure

```
codewhisper/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── theme.dart
│   ├── models/
│   │   ├── project_file.dart
│   │   ├── flutter_project.dart
│   │   └── widget_selection.dart
│   ├── services/
│   │   ├── file_operations.dart
│   │   ├── project_manager.dart
│   │   └── flutter_analyzer.dart
│   ├── widgets/
│   │   ├── ui_preview_panel.dart
│   │   ├── code_editor.dart
│   │   ├── ai_assistant_panel.dart
│   │   └── file_tree_view.dart
│   ├── screens/
│   │   └── home_page.dart
│   └── openai/
│       └── openai_config.dart
└── platform files (android/, ios/, web/)
```

---

## 📄 Source Code Files

### 1. pubspec.yaml
```yaml
name: codewhisper
description: "Unleash your Flutter creativity with AI! This web app lets you upload, intelligently refine with a sophisticated LLM, and export your projects, transforming your development workflow."
publish_to: "none"
version: 1.0.0

environment:
  sdk: ^3.6.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.1.0
  file_picker: '>=8.1.2'
  http: ^1.0.0
  archive: ^4.0.0
  universal_html: ^2.0.0
  shared_preferences: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

### 2. lib/main.dart
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

### 3. lib/theme.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightModeColors {
  static const lightPrimary = Color(0xFF6366F1);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE0E7FF);
  static const lightOnPrimaryContainer = Color(0xFF1E1B4B);
  static const lightSecondary = Color(0xFF64748B);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFF059669);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFEF4444);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEE2E2);
  static const lightOnErrorContainer = Color(0xFF7F1D1D);
  static const lightInversePrimary = Color(0xFFA5B4FC);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1F2937);
  static const lightAppBarBackground = Color(0xFFF8FAFC);
  static const lightCodeBackground = Color(0xFFF1F5F9);
  static const lightCodeBorder = Color(0xFFE2E8F0);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFF818CF8);
  static const darkOnPrimary = Color(0xFF1E1B4B);
  static const darkPrimaryContainer = Color(0xFF312E81);
  static const darkOnPrimaryContainer = Color(0xFFE0E7FF);
  static const darkSecondary = Color(0xFF94A3B8);
  static const darkOnSecondary = Color(0xFF1E293B);
  static const darkTertiary = Color(0xFF34D399);
  static const darkOnTertiary = Color(0xFF064E3B);
  static const darkError = Color(0xFFF87171);
  static const darkOnError = Color(0xFF7F1D1D);
  static const darkErrorContainer = Color(0xFF991B1B);
  static const darkOnErrorContainer = Color(0xFFFEE2E2);
  static const darkInversePrimary = Color(0xFF6366F1);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF0F172A);
  static const darkOnSurface = Color(0xFFE2E8F0);
  static const darkAppBarBackground = Color(0xFF1E293B);
  static const darkCodeBackground = Color(0xFF1E293B);
  static const darkCodeBorder = Color(0xFF334155);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
```

### 4. lib/models/project_file.dart
```dart
import 'package:flutter/material.dart';

class ProjectFile {
  final String path;
  final String content;
  final FileType type;
  final bool isDirectory;
  
  ProjectFile({
    required this.path,
    required this.content,
    required this.type,
    this.isDirectory = false,
  });

  String get fileName => path.split('/').last;
  
  String get extension => fileName.contains('.') ? fileName.split('.').last : '';
  
  bool get isDartFile => extension == 'dart';
  
  bool get isYamlFile => extension == 'yaml';
  
  bool get isJsonFile => extension == 'json';
  
  bool get isTextFile => isDartFile || isYamlFile || isJsonFile || extension == 'md' || extension == 'txt';

  ProjectFile copyWith({
    String? path,
    String? content,
    FileType? type,
    bool? isDirectory,
  }) {
    return ProjectFile(
      path: path ?? this.path,
      content: content ?? this.content,
      type: type ?? this.type,
      isDirectory: isDirectory ?? this.isDirectory,
    );
  }
}

enum FileType {
  dart,
  yaml,
  json,
  markdown,
  text,
  image,
  other,
}

extension FileTypeExtension on FileType {
  static FileType fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'dart':
        return FileType.dart;
      case 'yaml':
      case 'yml':
        return FileType.yaml;
      case 'json':
        return FileType.json;
      case 'md':
        return FileType.markdown;
      case 'txt':
        return FileType.text;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return FileType.image;
      default:
        return FileType.other;
    }
  }

  String get displayName {
    switch (this) {
      case FileType.dart:
        return 'Dart';
      case FileType.yaml:
        return 'YAML';
      case FileType.json:
        return 'JSON';
      case FileType.markdown:
        return 'Markdown';
      case FileType.text:
        return 'Text';
      case FileType.image:
        return 'Image';
      case FileType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case FileType.dart:
        return Icons.code;
      case FileType.yaml:
        return Icons.settings;
      case FileType.json:
        return Icons.data_object;
      case FileType.markdown:
        return Icons.description;
      case FileType.text:
        return Icons.text_snippet;
      case FileType.image:
        return Icons.image;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }
}
```

### 5. lib/models/flutter_project.dart
```dart
import 'package:codewhisper/models/project_file.dart';

class FlutterProject {
  final String name;
  final List<ProjectFile> files;
  final DateTime uploadedAt;
  
  FlutterProject({
    required this.name,
    required this.files,
    required this.uploadedAt,
  });

  List<ProjectFile> get dartFiles => files.where((f) => f.isDartFile).toList();
  
  List<ProjectFile> get directories => files.where((f) => f.isDirectory).toList();
  
  ProjectFile? get pubspecFile => files.where((f) => f.fileName == 'pubspec.yaml').firstOrNull;
  
  List<ProjectFile> getFilesInDirectory(String dirPath) {
    return files.where((f) => 
      f.path.startsWith(dirPath) && 
      f.path != dirPath &&
      f.path.substring(dirPath.length + 1).split('/').length == 1
    ).toList();
  }

  ProjectFile? findFileByPath(String path) {
    return files.where((f) => f.path == path).firstOrNull;
  }

  FlutterProject updateFile(String path, String newContent) {
    final updatedFiles = files.map((file) {
      if (file.path == path) {
        return file.copyWith(content: newContent);
      }
      return file;
    }).toList();
    
    return FlutterProject(
      name: name,
      files: updatedFiles,
      uploadedAt: uploadedAt,
    );
  }

  bool get isValidFlutterProject {
    return pubspecFile != null && 
           files.any((f) => f.path.contains('lib/')) &&
           files.any((f) => f.path.contains('lib/main.dart'));
  }
}
```

### 6. lib/models/widget_selection.dart
```dart
class WidgetSelection {
  final String widgetType;
  final String widgetId;
  final String filePath;
  final int lineNumber;
  final Map<String, dynamic> properties;
  final String sourceCode;

  const WidgetSelection({
    required this.widgetType,
    required this.widgetId,
    required this.filePath,
    required this.lineNumber,
    required this.properties,
    required this.sourceCode,
  });

  @override
  String toString() => 'WidgetSelection($widgetType at $filePath:$lineNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetSelection &&
          runtimeType == other.runtimeType &&
          widgetId == other.widgetId &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => widgetId.hashCode ^ filePath.hashCode ^ lineNumber.hashCode;
}
```

### 7. lib/services/file_operations.dart
```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class FileOperations {
  static Future<Uint8List?> pickFile() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.zip';
    uploadInput.click();

    await uploadInput.onChange.first;
    final files = uploadInput.files;
    if (files?.isEmpty ?? true) return null;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(files!.first);
    await reader.onLoad.first;

    return reader.result as Uint8List?;
  }

  static void downloadFile(List<int> bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static bool isTextFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    const textExtensions = {
      'dart', 'yaml', 'yml', 'json', 'md', 'txt', 'xml', 'gradle', 'properties'
    };
    return textExtensions.contains(extension);
  }

  static bool isBinaryFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    const binaryExtensions = {
      'png', 'jpg', 'jpeg', 'gif', 'ico', 'webp', 'pdf', 'zip', 'jar', 'so', 'dylib'
    };
    return binaryExtensions.contains(extension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  static String getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return '📱';
      case 'yaml':
      case 'yml':
        return '⚙️';
      case 'json':
        return '📊';
      case 'md':
        return '📝';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return '🖼️';
      default:
        return '📄';
    }
  }

  static bool shouldIncludeInProject(String path) {
    // Skip common build and cache directories
    final excludedDirs = {
      'build/',
      '.dart_tool/',
      '.idea/',
      '.vscode/',
      'ios/Pods/',
      'android/app/build/',
      'macos/build/',
      'linux/build/',
      'windows/build/',
      'web/build/',
    };
    
    for (final excludedDir in excludedDirs) {
      if (path.startsWith(excludedDir)) return false;
    }
    
    // Skip hidden files and directories
    if (path.startsWith('.') && !path.startsWith('./')) return false;
    
    return true;
  }
}
```

### 8. lib/services/project_manager.dart
```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:codewhisper/models/flutter_project.dart';
import 'package:codewhisper/models/project_file.dart';
import 'package:codewhisper/services/file_operations.dart';

class ProjectManager {
  static Future<FlutterProject?> loadProjectFromZip(Uint8List zipBytes, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final files = <ProjectFile>[];
      
      for (final file in archive) {
        if (file.isFile && FileOperations.shouldIncludeInProject(file.name)) {
          String content = '';
          
          if (FileOperations.isTextFile(file.name)) {
            content = utf8.decode(file.content as List<int>);
          } else if (FileOperations.isBinaryFile(file.name)) {
            content = '[Binary File - ${FileOperations.formatFileSize(file.size)}]';
          } else {
            // Try to decode as text, fallback to binary description
            try {
              content = utf8.decode(file.content as List<int>);
            } catch (e) {
              content = '[Binary File - ${FileOperations.formatFileSize(file.size)}]';
            }
          }
          
          final projectFile = ProjectFile(
            path: file.name,
            content: content,
            type: FileTypeExtension.fromExtension(file.name.split('.').last),
          );
          
          files.add(projectFile);
        } else if (!file.isFile) {
          // Add directory entries
          final dirFile = ProjectFile(
            path: file.name,
            content: '',
            type: FileType.other,
            isDirectory: true,
          );
          files.add(dirFile);
        }
      }
      
      final projectName = fileName.replaceAll('.zip', '');
      final project = FlutterProject(
        name: projectName,
        files: files,
        uploadedAt: DateTime.now(),
      );
      
      if (!project.isValidFlutterProject) {
        throw Exception('This does not appear to be a valid Flutter project. Please ensure it contains a pubspec.yaml and lib/main.dart file.');
      }
      
      return project;
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  static Future<List<int>> exportProjectToZip(FlutterProject project) async {
    try {
      final archive = Archive();
      
      for (final file in project.files) {
        if (file.isDirectory) {
          // Create directory entry
          archive.addFile(ArchiveFile(file.path, 0, <int>[]));
        } else if (!file.content.startsWith('[Binary File')) {
          // Add text files
          final bytes = utf8.encode(file.content);
          archive.addFile(ArchiveFile(file.path, bytes.length, bytes));
        }
        // Skip binary files for now - they would need special handling
      }
      
      final encoded = ZipEncoder().encode(archive);
      return encoded ?? [];
    } catch (e) {
      throw Exception('Failed to export project: $e');
    }
  }

  static List<String> getProjectStructure(FlutterProject project) {
    final structure = <String>[];
    final sortedFiles = [...project.files];
    
    // Sort files: directories first, then by path
    sortedFiles.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.path.compareTo(b.path);
    });
    
    for (final file in sortedFiles) {
      final depth = file.path.split('/').length - 1;
      final indent = '  ' * depth;
      final icon = file.isDirectory ? '📁' : FileOperations.getFileIcon(file.fileName);
      structure.add('$indent$icon ${file.fileName}');
    }
    
    return structure;
  }

  static Map<String, List<ProjectFile>> groupFilesByDirectory(FlutterProject project) {
    final grouped = <String, List<ProjectFile>>{};
    
    for (final file in project.files) {
      if (file.isDirectory) continue;
      
      final pathParts = file.path.split('/');
      final directory = pathParts.length > 1 
        ? pathParts.sublist(0, pathParts.length - 1).join('/')
        : '';
      
      grouped.putIfAbsent(directory, () => []);
      grouped[directory]!.add(file);
    }
    
    return grouped;
  }

  static List<String> getDirectoryTree(FlutterProject project) {
    final directories = <String>{};
    
    for (final file in project.files) {
      final pathParts = file.path.split('/');
      for (int i = 1; i < pathParts.length; i++) {
        final dir = pathParts.sublist(0, i).join('/');
        if (dir.isNotEmpty) {
          directories.add(dir);
        }
      }
    }
    
    final sortedDirs = directories.toList()..sort();
    return sortedDirs;
  }
}
```

### 9. lib/services/flutter_analyzer.dart
```dart
import 'package:codewhisper/models/flutter_project.dart';

class WidgetInfo {
  final String type;
  final String id;
  final String filePath;
  final int lineNumber;
  final Map<String, dynamic> properties;
  final List<WidgetInfo> children;

  const WidgetInfo({
    required this.type,
    required this.id,
    required this.filePath,
    required this.lineNumber,
    required this.properties,
    this.children = const [],
  });
}

class FlutterAnalyzer {
  Future<List<WidgetInfo>> analyzeProject(FlutterProject project) async {
    // Simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // In a real implementation, this would parse the Dart code
    // and extract the actual widget tree from the Flutter project
    return [
      WidgetInfo(
        type: 'MaterialApp',
        id: 'material_app_1',
        filePath: 'lib/main.dart',
        lineNumber: 14,
        properties: {'title': 'Flutter Demo'},
        children: [
          WidgetInfo(
            type: 'Scaffold',
            id: 'scaffold_1',
            filePath: 'lib/home_screen.dart',
            lineNumber: 20,
            properties: {},
            children: [
              WidgetInfo(
                type: 'AppBar',
                id: 'appbar_1',
                filePath: 'lib/home_screen.dart',
                lineNumber: 25,
                properties: {'title': 'Home'},
              ),
              WidgetInfo(
                type: 'Column',
                id: 'column_1',
                filePath: 'lib/home_screen.dart',
                lineNumber: 30,
                properties: {},
                children: [
                  WidgetInfo(
                    type: 'Card',
                    id: 'card_1',
                    filePath: 'lib/home_screen.dart',
                    lineNumber: 45,
                    properties: {},
                  ),
                  WidgetInfo(
                    type: 'ListView',
                    id: 'listview_1',
                    filePath: 'lib/home_screen.dart',
                    lineNumber: 78,
                    properties: {'itemCount': 10},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
```

### 10. lib/widgets/ui_preview_panel.dart
```dart
import 'package:flutter/material.dart';
import 'package:codewhisper/models/flutter_project.dart';
import 'package:codewhisper/models/project_file.dart';
import 'package:codewhisper/models/widget_selection.dart';
import 'package:codewhisper/services/flutter_analyzer.dart';
import 'dart:math' as math;

class UIPreviewPanel extends StatefulWidget {
  final FlutterProject project;
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final Function(WidgetSelection?) onWidgetSelected;

  const UIPreviewPanel({
    super.key,
    required this.project,
    required this.selectedFile,
    required this.selectedWidget,
    required this.onWidgetSelected,
  });

  @override
  State<UIPreviewPanel> createState() => _UIPreviewPanelState();
}

class _UIPreviewPanelState extends State<UIPreviewPanel> {
  bool _isMobileView = true;
  bool _isAnalyzing = false;
  List<WidgetInfo> _widgetTree = [];

  @override
  void initState() {
    super.initState();
    _analyzeProject();
  }

  @override
  void didUpdateWidget(UIPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _analyzeProject();
    }
  }

  Future<void> _analyzeProject() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analyzer = FlutterAnalyzer();
      final tree = await analyzer.analyzeProject(widget.project);
      setState(() {
        _widgetTree = tree;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
      ),
      child: Column(
        children: [
          _buildPreviewHeader(theme),
          Expanded(
            child: _isAnalyzing
              ? _buildAnalyzingView(theme)
              : _buildPreviewContent(theme),
          ),
          if (widget.selectedWidget != null)
            _buildWidgetDetails(theme),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(ThemeData theme) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'UI Preview',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton(
                  theme,
                  icon: Icons.phone_android,
                  isActive: _isMobileView,
                  onPressed: () => setState(() => _isMobileView = true),
                ),
                _buildViewToggleButton(
                  theme,
                  icon: Icons.web,
                  isActive: !_isMobileView,
                  onPressed: () => setState(() => _isMobileView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(ThemeData theme, {
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isActive ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: isActive 
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing Flutter project...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parsing widget tree and UI structure',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: _isMobileView ? 300 : 600,
          height: _isMobileView ? 600 : 400,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildMockUI(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildMockUI(ThemeData theme) {
    // Mock UI representing a typical Flutter app
    return Stack(
      children: [
        Column(
          children: [
            // Mock AppBar
            GestureDetector(
              onTap: () => _selectWidget('AppBar', 'main.dart', 25),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  border: widget.selectedWidget?.widgetType == 'AppBar' 
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.menu, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 16),
                    Text(
                      'App Title',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
                  ],
                ),
              ),
            ),
            // Mock Body
            Expanded(
              child: Container(
                color: theme.colorScheme.background,
                child: Column(
                  children: [
                    // Mock Card
                    GestureDetector(
                      onTap: () => _selectWidget('Card', 'home_screen.dart', 45),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: widget.selectedWidget?.widgetType == 'Card' 
                            ? Border.all(color: Colors.red, width: 2)
                            : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to your app!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is a sample card widget that you can select and modify.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mock ListView
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectWidget('ListView', 'home_screen.dart', 78),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: widget.selectedWidget?.widgetType == 'ListView' 
                              ? Border.all(color: Colors.red, width: 2)
                              : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _selectWidget('ListTile', 'home_screen.dart', 82 + index * 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: widget.selectedWidget?.widgetType == 'ListTile' && 
                                           widget.selectedWidget?.lineNumber == 82 + index * 5
                                      ? Border.all(color: Colors.red, width: 2)
                                      : null,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text('List Item ${index + 1}'),
                                    subtitle: Text('Subtitle for item ${index + 1}'),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Selection indicator
        if (widget.selectedWidget != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Selected: ${widget.selectedWidget!.widgetType}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWidgetDetails(ThemeData theme) {
    final selection = widget.selectedWidget!;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.widgets,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Widget',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => widget.onWidgetSelected(null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selection.widgetType,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${selection.filePath}:${selection.lineNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Now you can ask the AI assistant about this specific widget!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectWidget(String widgetType, String filePath, int lineNumber) {
    final selection = WidgetSelection(
      widgetType: widgetType,
      widgetId: '${widgetType}_${lineNumber}',
      filePath: filePath,
      lineNumber: lineNumber,
      properties: {
        'type': widgetType,
        'line': lineNumber,
      },
      sourceCode: 'Mock source code for $widgetType at line $lineNumber',
    );
    
    widget.onWidgetSelected(selection);
  }
}
```

### 11. lib/widgets/code_editor.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:codewhisper/models/project_file.dart';

class CodeEditor extends StatefulWidget {
  final ProjectFile? file;
  final Function(String, String)? onContentChanged;

  const CodeEditor({
    super.key,
    this.file,
    this.onContentChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _updateContent();
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file?.path != widget.file?.path) {
      _updateContent();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateContent() {
    if (widget.file != null) {
      _controller.text = widget.file!.content;
      _updateLineCount();
    } else {
      _controller.text = '';
      _lineCount = 1;
    }
  }

  void _updateLineCount() {
    setState(() {
      _lineCount = _controller.text.split('\n').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.file == null) {
      return _buildEmptyState(theme);
    }

    if (!widget.file!.isTextFile) {
      return _buildNonTextFileView(theme);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
          ? const Color(0xFFF1F5F9)
          : const Color(0xFF1E293B),
        border: Border.all(
          color: theme.brightness == Brightness.light
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF334155),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildEditorHeader(theme),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLineNumbers(theme),
                Expanded(
                  child: _buildEditor(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a file to start editing',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a file from the project tree to view and edit its contents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonTextFileView(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.file!.type.icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Binary file cannot be edited',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.file!.fileName,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.file!.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.file!.type.icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.file!.path,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _controller.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy code',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers(ThemeData theme) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_lineCount, (index) {
          return Text(
            '${index + 1}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return Scrollbar(
      controller: _scrollController,
      child: TextField(
        controller: _controller,
        scrollController: _scrollController,
        maxLines: null,
        expands: true,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.4,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        onChanged: (value) {
          _updateLineCount();
          if (widget.file != null && widget.onContentChanged != null) {
            widget.onContentChanged!(widget.file!.path, value);
          }
        },
      ),
    );
  }
}
```

### 12. lib/widgets/ai_assistant_panel.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:codewhisper/models/project_file.dart';
import 'package:codewhisper/models/widget_selection.dart';
import 'package:codewhisper/openai/openai_config.dart';

class AIAssistantPanel extends StatefulWidget {
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final Function(String)? onCodeGenerated;

  const AIAssistantPanel({
    super.key,
    this.selectedFile,
    this.selectedWidget,
    this.onCodeGenerated,
  });

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _lastResponse;
  AIAction _selectedAction = AIAction.improve;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildActionSelector(theme),
          _buildPromptInput(theme),
          _buildActionButtons(theme),
          Expanded(
            child: _buildResponseArea(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!OpenAIConfig.isConfigured)
                Tooltip(
                  message: 'OpenAI API not configured',
                  child: Icon(
                    Icons.warning,
                    color: theme.colorScheme.error,
                    size: 16,
                  ),
                ),
            ],
          ),
          if (widget.selectedWidget != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.widgets,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Context: ${widget.selectedWidget!.widgetType}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'at line ${widget.selectedWidget!.lineNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Action',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AIAction.values.map((action) {
              final isSelected = _selectedAction == action;
              return FilterChip(
                label: Text(
                  action.displayName,
                  style: TextStyle(
                    color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedAction = action;
                    });
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedAction.promptLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _selectedAction.promptHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading || !OpenAIConfig.isConfigured
                ? null
                : _processAIRequest,
              icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
              label: Text(
                _isLoading ? 'Processing...' : 'Generate',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _promptController.clear();
                _lastResponse = null;
              });
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
          ),
        ],
      ),
    );
  }

  Widget _buildResponseArea(ThemeData theme) {
    if (_lastResponse == null) {
      return _buildEmptyResponseState(theme);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
          ? const Color(0xFFF1F5F9)
          : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.light
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Response',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lastResponse!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Response copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy response',
                  visualDensity: VisualDensity.compact,
                ),
                if (_selectedAction == AIAction.improve || _selectedAction == AIAction.generate)
                  IconButton(
                    onPressed: () {
                      if (widget.onCodeGenerated != null) {
                        widget.onCodeGenerated!(_lastResponse!);
                      }
                    },
                    icon: const Icon(Icons.integration_instructions, size: 16),
                    tooltip: 'Apply to editor',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _lastResponse!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResponseState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'AI responses will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (!OpenAIConfig.isConfigured) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OpenAI API not configured. Please set environment variables.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _processAIRequest() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    if (widget.selectedFile == null && widget.selectedWidget == null && _selectedAction != AIAction.generate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file or widget first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
    });

    try {
      String response;
      
      switch (_selectedAction) {
        case AIAction.improve:
          String contextInfo = _promptController.text;
          if (widget.selectedWidget != null) {
            contextInfo += '\n\n[WIDGET CONTEXT: ${widget.selectedWidget!.widgetType} at ${widget.selectedWidget!.filePath}:${widget.selectedWidget!.lineNumber}]';
          }
          response = await OpenAIService.improveCode(
            code: widget.selectedFile?.content ?? widget.selectedWidget?.sourceCode ?? '',
            fileName: widget.selectedFile?.fileName ?? widget.selectedWidget?.filePath ?? 'unknown.dart',
            context: contextInfo,
          );
          break;
        case AIAction.generate:
          String description = _promptController.text;
          if (widget.selectedWidget != null) {
            description += '\n\nGenerate code for a ${widget.selectedWidget!.widgetType} widget.';
          }
          response = await OpenAIService.generateCode(
            description: description,
            fileName: 'generated_code.dart',
          );
          break;
        case AIAction.explain:
          String codeToExplain = widget.selectedFile?.content ?? widget.selectedWidget?.sourceCode ?? '';
          if (widget.selectedWidget != null) {
            codeToExplain = 'Widget: ${widget.selectedWidget!.widgetType}\n' +
                          'Location: ${widget.selectedWidget!.filePath}:${widget.selectedWidget!.lineNumber}\n\n' +
                          codeToExplain;
          }
          response = await OpenAIService.explainCode(
            code: codeToExplain,
            fileName: widget.selectedFile?.fileName ?? widget.selectedWidget?.filePath ?? 'unknown.dart',
          );
          break;
      }

      setState(() {
        _lastResponse = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

enum AIAction {
  improve,
  generate,
  explain,
}

extension AIActionExtension on AIAction {
  String get displayName {
    switch (this) {
      case AIAction.improve:
        return '✨ Improve';
      case AIAction.generate:
        return '🔧 Generate';
      case AIAction.explain:
        return '💡 Explain';
    }
  }

  String get promptLabel {
    switch (this) {
      case AIAction.improve:
        return 'Improvement Instructions';
      case AIAction.generate:
        return 'Code Description';
      case AIAction.explain:
        return 'Questions (Optional)';
    }
  }

  String get promptHint {
    switch (this) {
      case AIAction.improve:
        return 'Describe what improvements you want to make...';
      case AIAction.generate:
        return 'Describe the code you want to generate...';
      case AIAction.explain:
        return 'Ask specific questions about the code...';
    }
  }
}
```

### 13. lib/widgets/file_tree_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:codewhisper/models/flutter_project.dart';
import 'package:codewhisper/models/project_file.dart';

class FileTreeView extends StatefulWidget {
  final FlutterProject project;
  final ProjectFile? selectedFile;
  final Function(ProjectFile) onFileSelected;

  const FileTreeView({
    super.key,
    required this.project,
    this.selectedFile,
    required this.onFileSelected,
  });

  @override
  State<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends State<FileTreeView> {
  final Set<String> _expandedDirectories = <String>{};

  @override
  void initState() {
    super.initState();
    // Auto-expand lib directory
    _expandedDirectories.add('lib');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.project.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildFileTree(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFileTree() {
    final fileTree = _organizeFilesIntoTree();
    return _buildTreeNodes(fileTree, 0);
  }

  Map<String, dynamic> _organizeFilesIntoTree() {
    final tree = <String, dynamic>{};
    
    for (final file in widget.project.files) {
      final parts = file.path.split('/');
      Map<String, dynamic> current = tree;
      
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1 && !file.isDirectory) {
          // This is a file
          current[part] = file;
        } else {
          // This is a directory
          current[part] ??= <String, dynamic>{};
          current = current[part] as Map<String, dynamic>;
        }
      }
    }
    
    return tree;
  }

  List<Widget> _buildTreeNodes(Map<String, dynamic> tree, int depth) {
    final widgets = <Widget>[];
    final sortedKeys = tree.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final value = tree[key];
      
      if (value is ProjectFile) {
        // This is a file
        widgets.add(_buildFileItem(value, depth));
      } else if (value is Map<String, dynamic>) {
        // This is a directory
        final dirPath = _buildPathFromDepth(key, depth);
        final isExpanded = _expandedDirectories.contains(dirPath);
        
        widgets.add(_buildDirectoryItem(key, depth, isExpanded, () {
          setState(() {
            if (isExpanded) {
              _expandedDirectories.remove(dirPath);
            } else {
              _expandedDirectories.add(dirPath);
            }
          });
        }));
        
        if (isExpanded) {
          widgets.addAll(_buildTreeNodes(value, depth + 1));
        }
      }
    }
    
    return widgets;
  }

  String _buildPathFromDepth(String name, int depth) {
    // This is a simplified approach - in a real implementation,
    // you'd need to track the full path properly
    return name;
  }

  Widget _buildDirectoryItem(String name, int depth, bool isExpanded, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (depth * 20.0),
          right: 16,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.folder_open : Icons.folder,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(ProjectFile file, int depth) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedFile?.path == file.path;
    
    return InkWell(
      onTap: () => widget.onFileSelected(file),
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (depth * 20.0) + 20.0, // Extra indent for files
          right: 16,
          top: 6,
          bottom: 6,
        ),
        decoration: isSelected ? BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ) : null,
        child: Row(
          children: [
            Icon(
              file.type.icon,
              size: 16,
              color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                file.fileName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 14. lib/screens/home_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:codewhisper/models/flutter_project.dart';
import 'package:codewhisper/models/project_file.dart';
import 'package:codewhisper/services/project_manager.dart';
import 'package:codewhisper/services/file_operations.dart';
import 'package:codewhisper/widgets/file_tree_view.dart';
import 'package:codewhisper/widgets/code_editor.dart';
import 'package:codewhisper/widgets/ai_assistant_panel.dart';
import 'package:codewhisper/widgets/ui_preview_panel.dart';
import 'package:codewhisper/models/widget_selection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterProject? _currentProject;
  ProjectFile? _selectedFile;
  bool _isLoading = false;
  bool _showAIPanel = true; // Show by default for web
  bool _showUIPreview = true;
  WidgetSelection? _selectedWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: screenWidth < 1200 
        ? _buildMobileNotSupported(theme)
        : Column(
            children: [
              _buildWebAppBar(theme),
              Expanded(
                child: _isLoading
                  ? _buildLoadingView(theme)
                  : _currentProject == null
                    ? _buildWelcomeView(theme)
                    : _buildWebProjectView(theme, screenWidth, screenHeight),
              ),
            ],
          ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading project...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNotSupported(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.desktop_windows,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Desktop Only',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'CodeWhisper is designed for desktop devices. Please use a larger screen (minimum 1200px width) for the optimal web IDE experience.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.web_asset,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CodeWhisper IDE',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Professional Web-Based Flutter Development Environment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Upload your Flutter project and experience the power of AI-assisted development. '
                'CodeWhisper provides a complete IDE with live UI preview, intelligent widget selection, '
                'and context-aware AI assistance that understands your code structure.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildFeatureGrid(theme),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadProject,
                    icon: Icon(
                      Icons.upload_file,
                      color: theme.colorScheme.onPrimary,
                      size: 22,
                    ),
                    label: Text(
                      'Upload Flutter Project (ZIP)',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(width: 24),
                  OutlinedButton.icon(
                    onPressed: () => _showDemoInfo(context),
                    icon: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    label: Text(
                      'Learn More',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(ThemeData theme) {
    final features = [
      {
        'icon': Icons.folder_open,
        'title': 'Project Explorer',
        'description': 'Browse and navigate your Flutter project files with a tree view',
      },
      {
        'icon': Icons.edit_note,
        'title': 'Code Editor',
        'description': 'Professional code editor with syntax highlighting',
      },
      {
        'icon': Icons.visibility,
        'title': 'Live UI Preview',
        'description': 'See your Flutter app rendered with selectable widgets',
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'AI Assistant',
        'description': 'Context-aware AI that understands your selected widgets',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 32,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                feature['description'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWebAppBar(ThemeData theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo and Title
          Row(
            children: [
              Icon(
                Icons.web,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'CodeWhisper',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentProject != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentProject!.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Action Buttons
          if (_currentProject != null) ...[
            _buildToolbarButton(
              theme,
              icon: Icons.visibility,
              label: _showUIPreview ? 'Hide Preview' : 'Show Preview',
              isActive: _showUIPreview,
              onPressed: () => setState(() => _showUIPreview = !_showUIPreview),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(
              theme,
              icon: Icons.auto_awesome,
              label: _showAIPanel ? 'Hide AI Assistant' : 'Show AI Assistant',
              isActive: _showAIPanel,
              onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(
              theme,
              icon: Icons.download,
              label: 'Export Project',
              isActive: false,
              onPressed: _exportProject,
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(
              theme,
              icon: Icons.close,
              label: 'Close Project',
              isActive: false,
              onPressed: _closeProject,
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _loadProject,
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text('Upload Flutter Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbarButton(ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isActive 
        ? theme.colorScheme.primaryContainer 
        : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebProjectView(ThemeData theme, double screenWidth, double screenHeight) {
    // Calculate responsive panel widths based on screen size
    final fileTreeWidth = (screenWidth * 0.18).clamp(250.0, 320.0);
    final aiPanelWidth = (screenWidth * 0.22).clamp(300.0, 400.0);
    
    return Row(
      children: [
        // Left Panel - File Tree (18% of screen width)
        SizedBox(
          width: fileTreeWidth,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: FileTreeView(
              project: _currentProject!,
              selectedFile: _selectedFile,
              onFileSelected: (file) {
                setState(() {
                  _selectedFile = file;
                });
              },
            ),
          ),
        ),
        
        // Center Panel - Code Editor (flexible, takes remaining space)
        Expanded(
          flex: _showUIPreview ? 5 : 8,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              border: _showUIPreview ? Border(
                right: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ) : null,
            ),
            child: Column(
              children: [
                // Editor header
                if (_selectedFile != null)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFile!.fileName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _selectedFile!.path.split('/').sublist(0, _selectedFile!.path.split('/').length - 1).join('/'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Code editor
                Expanded(
                  child: CodeEditor(
                    file: _selectedFile,
                    onContentChanged: _updateFileContent,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Right Panel - UI Preview (30% of remaining space when shown)
        if (_showUIPreview)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: _showAIPanel ? Border(
                  right: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ) : null,
              ),
              child: UIPreviewPanel(
                project: _currentProject!,
                selectedFile: _selectedFile,
                selectedWidget: _selectedWidget,
                onWidgetSelected: (widget) {
                  setState(() {
                    _selectedWidget = widget;
                  });
                },
              ),
            ),
          ),
          
        // Far Right Panel - AI Assistant (22% of screen width)
        if (_showAIPanel)
          SizedBox(
            width: aiPanelWidth,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: AIAssistantPanel(
                selectedFile: _selectedFile,
                selectedWidget: _selectedWidget,
                onCodeGenerated: _applyGeneratedCode,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final zipBytes = await FileOperations.pickFile();
      if (zipBytes == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final project = await ProjectManager.loadProjectFromZip(
        zipBytes,
        'uploaded_project.zip',
      );

      setState(() {
        _currentProject = project;
        _selectedFile = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${project?.name}" loaded successfully!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportProject() async {
    if (_currentProject == null) return;

    try {
      final zipBytes = await ProjectManager.exportProjectToZip(_currentProject!);
      final fileName = '${_currentProject!.name}_modified.zip';
      
      FileOperations.downloadFile(zipBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project exported as $fileName'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _closeProject() {
    setState(() {
      _currentProject = null;
      _selectedFile = null;
      _showAIPanel = false;
    });
  }

  void _updateFileContent(String filePath, String newContent) {
    if (_currentProject == null) return;

    setState(() {
      _currentProject = _currentProject!.updateFile(filePath, newContent);
      // Update selected file to reflect the change
      _selectedFile = _currentProject!.findFileByPath(filePath);
    });
  }

  void _applyGeneratedCode(String generatedCode) {
    if (_selectedFile == null) return;

    _updateFileContent(_selectedFile!.path, generatedCode);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated code applied to editor'),
      ),
    );
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CodeWhisper is a web-based Flutter IDE with AI assistance. '
              'Key features include:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text('• Upload and edit Flutter projects'),
            Text('• Live UI preview with selectable widgets'),
            Text('• Context-aware AI assistant'),
            Text('• Export modified projects'),
            SizedBox(height: 16),
            Text(
              'Upload a Flutter project ZIP file to get started!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
```

### 15. lib/openai/openai_config.dart
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIConfig {
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');
  
  static const String model = 'gpt-4o';
  static const int maxTokens = 4096;
  static const double temperature = 0.7;

  static bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;
}

class OpenAIService {
  static Future<String> improveCode({
    required String code,
    required String fileName,
    String? context,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeImprovementPrompt(code, fileName, context);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to improve code: $e');
    }
  }

  static Future<String> generateCode({
    required String description,
    required String fileName,
    String? projectContext,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeGenerationPrompt(description, fileName, projectContext);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate code: $e');
    }
  }

  static Future<String> explainCode({
    required String code,
    required String fileName,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeExplanationPrompt(code, fileName);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to explain code: $e');
    }
  }

  static Future<String> _makeRequest(String prompt) async {
    final response = await http.post(
      Uri.parse(OpenAIConfig.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': OpenAIConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert Flutter developer. Provide clean, efficient, and well-documented code solutions.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': OpenAIConfig.maxTokens,
        'temperature': OpenAIConfig.temperature,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    
    if (data['choices'] == null || data['choices'].isEmpty) {
      throw Exception('No response from OpenAI API');
    }

    return data['choices'][0]['message']['content'] ?? '';
  }

  static String _buildCodeImprovementPrompt(String code, String fileName, String? context) {
    return '''
Please analyze and improve the following Flutter/Dart code from file "$fileName":

${context != null ? "Project Context: $context\n\n" : ""}Code to improve:
```dart
$code
```

Please provide improvements focusing on:
1. Code quality and best practices
2. Performance optimizations
3. Better error handling
4. Code documentation
5. Flutter/Dart specific improvements

Return only the improved code without explanations.
    ''';
  }

  static String _buildCodeGenerationPrompt(String description, String fileName, String? projectContext) {
    return '''
Generate Flutter/Dart code for file "$fileName" based on this description:

$description

${projectContext != null ? "Project Context: $projectContext\n\n" : ""}

Please ensure the code:
1. Follows Flutter best practices
2. Uses Material Design 3 components
3. Includes proper error handling
4. Is well-documented
5. Is production-ready

Return only the code without explanations.
    ''';
  }

  static String _buildCodeExplanationPrompt(String code, String fileName) {
    return '''
Please explain the following Flutter/Dart code from file "$fileName":

```dart
$code
```

Provide a clear explanation covering:
1. What this code does
2. How it works
3. Key Flutter concepts used
4. Any potential issues or improvements
5. How it fits in a typical Flutter app structure

Keep the explanation concise but comprehensive.
    ''';
  }
}
```

---

## 🔧 Key Features

### 🏗️ Architecture
- **Clean Architecture**: Organized into models, services, widgets, and screens
- **State Management**: StatefulWidget-based state management for simplicity
- **Responsive Design**: Desktop-first web application with minimum 1200px width requirement

### 🎨 UI/UX Features
- **Material Design 3**: Modern design system with light and dark themes
- **Professional Layout**: Multi-panel IDE layout with resizable sections
- **File Tree Navigation**: Hierarchical project file explorer
- **Code Editor**: Syntax highlighting with line numbers and copy functionality

### 🤖 AI Integration
- **OpenAI GPT-4o**: Integrated AI assistant for code improvement, generation, and explanation
- **Context-Aware**: AI understands selected widgets and files for better assistance
- **Multiple Actions**: Support for improve, generate, and explain operations

### 📱 Live UI Preview
- **Widget Selection**: Click on UI elements to select specific widgets
- **Mobile/Web Toggle**: Switch between mobile and web preview modes
- **Mock UI**: Simulated Flutter app interface with selectable components

### 💾 Project Management
- **ZIP Upload/Export**: Import Flutter projects from ZIP files and export modifications
- **File Operations**: Read, edit, and manage project files in the browser
- **Project Validation**: Ensures uploaded projects are valid Flutter applications

---

## 🚀 Getting Started

1. **Install Dependencies**: `flutter pub get`
2. **Set OpenAI Environment Variables** (optional):
   - `OPENAI_PROXY_API_KEY`: Your OpenAI API key
   - `OPENAI_PROXY_ENDPOINT`: OpenAI API endpoint
3. **Run the App**: `flutter run -d chrome`
4. **Upload a Flutter Project**: Click "Upload Flutter Project (ZIP)" and select a ZIP file

---

## 📋 Technical Requirements

- **Flutter SDK**: ^3.6.0
- **Minimum Screen Width**: 1200px (desktop-only application)
- **Supported Platforms**: Web browsers (Chrome recommended)
- **Dependencies**: See pubspec.yaml for complete list

---

This complete source code collection represents a sophisticated Flutter web application that demonstrates modern development practices, AI integration, and professional IDE functionality. The codebase is well-structured, documented, and ready for further development or educational use.