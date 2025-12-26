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

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
      'type': type.name,
      'isDirectory': isDirectory,
    };
  }

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      path: json['path'] ?? '',
      content: json['content'] ?? '',
      type: FileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FileType.other,
      ),
      isDirectory: json['isDirectory'] ?? false,
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