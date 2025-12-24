import 'dart:typed_data';
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
    if (bytes < 1024) return '\${bytes}B';
    if (bytes < 1024 * 1024) return '\${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '\${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '\${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
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

  // Advanced File Management Operations
  static bool isValidFileName(String name) {
    if (name.isEmpty || name.trim().isEmpty) return false;
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(name);
  }

  static bool isValidDirectoryName(String name) {
    if (name.isEmpty || name.trim().isEmpty) return false;
    if (name.startsWith('.') || name.endsWith('.')) return false;
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(name);
  }

  static String generateUniqueFileName(String baseName, List<String> existingNames) {
    if (!existingNames.contains(baseName)) return baseName;
    
    final parts = baseName.split('.');
    final name = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : baseName;
    final extension = parts.length > 1 ? '.${parts.last}' : '';
    
    int counter = 1;
    String newName;
    do {
      newName = '${name}_$counter$extension';
      counter++;
    } while (existingNames.contains(newName));
    
    return newName;
  }

  static String generateUniqueDirectoryName(String baseName, List<String> existingNames) {
    if (!existingNames.contains(baseName)) return baseName;
    
    int counter = 1;
    String newName;
    do {
      newName = '${baseName}_$counter';
      counter++;
    } while (existingNames.contains(newName));
    
    return newName;
  }

  static List<String> getFileTemplates() {
    return [
      'Dart Class',
      'Dart Widget', 
      'Dart Service',
      'Dart Model',
      'JSON File',
      'YAML File',
      'Markdown File',
      'Text File'
    ];
  }

  static String getFileTemplate(String templateType, String fileName) {
    final className = fileName.split('.').first.split('_').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join('');
    
    switch (templateType) {
      case 'Dart Class':
        return '''class $className {
  // TODO: Implement class
}
''';
      
      case 'Dart Widget':
        return '''import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$className'),
      ),
      body: const Center(
        child: Text('$className'),
      ),
    );
  }
}
''';
      
      case 'Dart Service':
        return '''class $className {
  static final $className _instance = $className._internal();
  factory $className() => _instance;
  $className._internal();

  // TODO: Implement service methods
}
''';
      
      case 'Dart Model':
        return '''class $className {
  final String id;
  final String name;

  const $className({
    required this.id,
    required this.name,
  });

  factory $className.fromJson(Map<String, dynamic> json) {
    return $className(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
''';
      
      case 'JSON File':
        return '''{
  "name": "example",
  "value": ""
}
''';
      
      case 'YAML File':
        return '''# Configuration file
name: example
version: 1.0.0
''';
      
      case 'Markdown File':
        return '''# ${fileName.split('.').first.toUpperCase()}

## Overview

Description here.

## Usage

Instructions here.
''';
      
      default:
        return '// New file\n';
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