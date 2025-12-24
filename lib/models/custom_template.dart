import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';

class CustomTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final DateTime createdAt;
  final FlutterProject sourceProject;
  final List<String> tags;
  
  CustomTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.createdAt,
    required this.sourceProject,
    this.tags = const [],
  });
  
  CustomTemplate copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    DateTime? createdAt,
    FlutterProject? sourceProject,
    List<String>? tags,
  }) {
    return CustomTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      sourceProject: sourceProject ?? this.sourceProject,
      tags: tags ?? this.tags,
    );
  }
  
  // Helper to create a new project from this template
  FlutterProject createProject(String projectName) {
    // Deep copy the source project with new name
    final newFiles = sourceProject.files.map((file) {
      // Replace the old project name with the new one in file content
      final updatedContent = file.content.replaceAll(
        sourceProject.name,
        projectName,
      );
      
      return file.copyWith(content: updatedContent);
    }).toList();
    
    return FlutterProject(
      name: projectName,
      files: newFiles,
      uploadedAt: DateTime.now(),
    );
  }
}