import 'dart:typed_data';
import 'dart:convert';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/project_export_service.dart';

class ShareableProject {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String createdBy;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final List<String> tags;
  final ProjectShareType shareType;
  
  const ShareableProject({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.expiresAt,
    required this.createdBy,
    this.metadata = const {},
    this.isPublic = false,
    this.tags = const [],
    this.shareType = ProjectShareType.full,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'createdBy': createdBy,
      'metadata': metadata,
      'isPublic': isPublic,
      'tags': tags,
      'shareType': shareType.name,
    };
  }

  factory ShareableProject.fromJson(Map<String, dynamic> json) {
    return ShareableProject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      createdBy: json['createdBy'] ?? 'Anonymous',
      metadata: json['metadata'] ?? {},
      isPublic: json['isPublic'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      shareType: ProjectShareType.values.firstWhere(
        (e) => e.name == json['shareType'],
        orElse: () => ProjectShareType.full,
      ),
    );
  }
}

enum ProjectShareType {
  full,          // Complete project with all files
  template,      // Project as template (no specific data)
  configuration, // Only configuration files
  structure,     // Only folder structure and metadata
}

class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic> templateData;
  final int downloadCount;
  final double rating;
  final String? previewImage;
  
  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.createdAt,
    required this.createdBy,
    this.templateData = const {},
    this.downloadCount = 0,
    this.rating = 0.0,
    this.previewImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'templateData': templateData,
      'downloadCount': downloadCount,
      'rating': rating,
      'previewImage': previewImage,
    };
  }

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? 'Anonymous',
      templateData: json['templateData'] ?? {},
      downloadCount: json['downloadCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      previewImage: json['previewImage'],
    );
  }
}

class ShareProgress {
  final String message;
  final double progress;
  final bool isComplete;
  final bool hasError;
  final String? error;
  
  const ShareProgress({
    required this.message,
    required this.progress,
    this.isComplete = false,
    this.hasError = false,
    this.error,
  });
}

class ImportConflict {
  final String filePath;
  final String existingContent;
  final String newContent;
  final ConflictType type;
  
  const ImportConflict({
    required this.filePath,
    required this.existingContent,
    required this.newContent,
    required this.type,
  });
}

enum ConflictType {
  fileExists,
  differentContent,
  dependencyConflict,
  configurationConflict,
}

class ImportResult {
  final FlutterProject? project;
  final List<ImportConflict> conflicts;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;
  
  const ImportResult({
    this.project,
    this.conflicts = const [],
    this.success = true,
    this.error,
    this.metadata = const {},
  });
}

class ProjectSharingService {
  // Callbacks for progress updates
  static void Function(ShareProgress)? onShareProgress;
  static void Function(ShareProgress)? onImportProgress;

  // Mock storage - in production this would use a backend service
  static final Map<String, ShareableProject> _sharedProjects = {};
  static final Map<String, ProjectTemplate> _templates = {};
  static final Map<String, Uint8List> _projectData = {};

  /// Generate a shareable link for a project
  static Future<String> shareProject(
    FlutterProject project, {
    required String description,
    String createdBy = 'Anonymous',
    Duration? expirationDuration,
    bool isPublic = false,
    List<String> tags = const [],
    ProjectShareType shareType = ProjectShareType.full,
  }) async {
    try {
      _updateShareProgress('Preparing project for sharing...', 0.1);

      final projectId = _generateProjectId();
      final expiresAt = DateTime.now().add(expirationDuration ?? const Duration(days: 30));

      // Export project data based on share type
      _updateShareProgress('Processing project data...', 0.3);
      final projectData = await _prepareProjectForSharing(project, shareType);

      // Create shareable project record
      final shareableProject = ShareableProject(
        id: projectId,
        name: project.name,
        description: description,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        createdBy: createdBy,
        isPublic: isPublic,
        tags: tags,
        shareType: shareType,
        metadata: {
          'originalFileCount': project.files.length,
          'dartFileCount': project.files.where((f) => f.isDartFile).length,
          'hasTests': project.files.any((f) => f.path.startsWith('test/')),
          'dependencies': _extractDependencies(project),
        },
      );

      _updateShareProgress('Saving shared project...', 0.7);

      // Store the project
      _sharedProjects[projectId] = shareableProject;
      _projectData[projectId] = projectData;

      _updateShareProgress('Share link generated successfully!', 1.0);

      return 'codewhisper://share/$projectId';
    } catch (e) {
      _updateShareProgress('Failed to share project: $e', 1.0, hasError: true);
      throw Exception('Failed to share project: $e');
    }
  }

  /// Create a project template from an existing project
  static Future<ProjectTemplate> createTemplate(
    FlutterProject project, {
    required String templateName,
    required String description,
    required String category,
    String createdBy = 'Anonymous',
    List<String> tags = const [],
  }) async {
    try {
      _updateShareProgress('Creating project template...', 0.2);

      final templateId = _generateTemplateId();
      
      // Prepare template data by cleaning up project-specific content
      _updateShareProgress('Processing template data...', 0.5);
      final templateData = await _createTemplateData(project);

      final template = ProjectTemplate(
        id: templateId,
        name: templateName,
        description: description,
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        templateData: templateData,
      );

      _updateShareProgress('Saving template...', 0.8);
      _templates[templateId] = template;

      _updateShareProgress('Template created successfully!', 1.0);
      return template;
    } catch (e) {
      _updateShareProgress('Failed to create template: $e', 1.0, hasError: true);
      throw Exception('Failed to create template: $e');
    }
  }

  /// Import a shared project
  static Future<ImportResult> importSharedProject(String shareLink) async {
    try {
      _updateImportProgress('Parsing share link...', 0.1);

      final projectId = _extractProjectIdFromLink(shareLink);
      if (projectId == null) {
        throw Exception('Invalid share link format');
      }

      _updateImportProgress('Retrieving shared project...', 0.3);

      final shareableProject = _sharedProjects[projectId];
      if (shareableProject == null) {
        throw Exception('Shared project not found or expired');
      }

      // Check if project has expired
      if (DateTime.now().isAfter(shareableProject.expiresAt)) {
        throw Exception('Shared project link has expired');
      }

      _updateImportProgress('Loading project data...', 0.5);

      final projectData = _projectData[projectId];
      if (projectData == null) {
        throw Exception('Project data not available');
      }

      _updateImportProgress('Reconstructing project...', 0.7);

      final project = await _reconstructProject(projectData, shareableProject);

      _updateImportProgress('Import completed successfully!', 1.0);

      return ImportResult(
        project: project,
        metadata: {
          'shareInfo': shareableProject.toJson(),
          'importedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _updateImportProgress('Import failed: $e', 1.0, hasError: true);
      return ImportResult(
        success: false,
        error: 'Failed to import project: $e',
      );
    }
  }

  /// Import project from template
  static Future<ImportResult> importFromTemplate(
    String templateId, {
    required String projectName,
    Map<String, String>? customizations,
  }) async {
    try {
      _updateImportProgress('Loading template...', 0.2);

      final template = _templates[templateId];
      if (template == null) {
        throw Exception('Template not found');
      }

      _updateImportProgress('Applying template...', 0.5);

      final project = await _applyTemplate(template, projectName, customizations ?? {});

      _updateImportProgress('Template applied successfully!', 1.0);

      return ImportResult(
        project: project,
        metadata: {
          'templateInfo': template.toJson(),
          'appliedAt': DateTime.now().toIso8601String(),
          'customizations': customizations ?? {},
        },
      );
    } catch (e) {
      _updateImportProgress('Template import failed: $e', 1.0, hasError: true);
      return ImportResult(
        success: false,
        error: 'Failed to import template: $e',
      );
    }
  }

  /// Import project with conflict detection
  static Future<ImportResult> importWithConflictResolution(
    FlutterProject existingProject,
    FlutterProject newProject,
  ) async {
    try {
      _updateImportProgress('Detecting conflicts...', 0.3);

      final conflicts = _detectConflicts(existingProject, newProject);

      if (conflicts.isEmpty) {
        // No conflicts, safe to merge
        _updateImportProgress('No conflicts detected, merging projects...', 0.7);
        final mergedProject = _mergeProjects(existingProject, newProject);
        
        _updateImportProgress('Projects merged successfully!', 1.0);
        return ImportResult(project: mergedProject);
      } else {
        // Return conflicts for user resolution
        _updateImportProgress('Conflicts detected, requiring user input', 1.0);
        return ImportResult(
          project: existingProject, // Return existing project unchanged
          conflicts: conflicts,
        );
      }
    } catch (e) {
      _updateImportProgress('Conflict resolution failed: $e', 1.0, hasError: true);
      return ImportResult(
        success: false,
        error: 'Failed to resolve conflicts: $e',
      );
    }
  }

  /// Resolve conflicts and merge projects
  static FlutterProject resolveConflictsAndMerge(
    FlutterProject existingProject,
    FlutterProject newProject,
    Map<String, String> resolutions, // filePath -> 'keep', 'replace', 'merge'
  ) {
    final mergedFiles = <ProjectFile>[];
    final processedPaths = <String>{};

    // Process existing files
    for (final existingFile in existingProject.files) {
      final resolution = resolutions[existingFile.path];
      
      if (resolution == 'replace') {
        // Find replacement from new project
        final newFile = newProject.files.firstWhere(
          (f) => f.path == existingFile.path,
          orElse: () => existingFile,
        );
        mergedFiles.add(newFile);
      } else if (resolution == 'merge') {
        // Simple merge - in production would be more sophisticated
        final newFile = newProject.files.firstWhere(
          (f) => f.path == existingFile.path,
          orElse: () => existingFile,
        );
        final mergedContent = '${existingFile.content}\n\n// Merged from imported project:\n${newFile.content}';
        mergedFiles.add(existingFile.copyWith(content: mergedContent));
      } else {
        // Default: keep existing
        mergedFiles.add(existingFile);
      }
      
      processedPaths.add(existingFile.path);
    }

    // Add new files that don't exist in the existing project
    for (final newFile in newProject.files) {
      if (!processedPaths.contains(newFile.path)) {
        mergedFiles.add(newFile);
      }
    }

    return existingProject.copyWith(files: mergedFiles);
  }

  /// Get list of available templates
  static List<ProjectTemplate> getAvailableTemplates({
    String? category,
    List<String>? tags,
    String? searchQuery,
  }) {
    var templates = _templates.values.toList();

    if (category != null) {
      templates = templates.where((t) => t.category == category).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      templates = templates.where((t) => 
        tags.any((tag) => t.tags.contains(tag))
      ).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      templates = templates.where((t) => 
        t.name.toLowerCase().contains(query) ||
        t.description.toLowerCase().contains(query) ||
        t.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    // Sort by rating and download count
    templates.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;
      return b.downloadCount.compareTo(a.downloadCount);
    });

    return templates;
  }

  /// Get template categories
  static List<String> getTemplateCategories() {
    return _templates.values
        .map((t) => t.category)
        .toSet()
        .toList()
        ..sort();
  }

  /// Get popular tags
  static List<String> getPopularTags() {
    final tagCounts = <String, int>{};
    
    for (final template in _templates.values) {
      for (final tag in template.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.map((e) => e.key).take(20).toList();
  }

  // Private helper methods

  static String _generateProjectId() {
    return 'proj_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond / 1000000)).round())}';
  }

  static String _generateTemplateId() {
    return 'tmpl_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond / 1000000)).round())}';
  }

  static String? _extractProjectIdFromLink(String link) {
    if (link.startsWith('codewhisper://share/')) {
      return link.substring('codewhisper://share/'.length);
    }
    return null;
  }

  static Future<Uint8List> _prepareProjectForSharing(FlutterProject project, ProjectShareType shareType) async {
    switch (shareType) {
      case ProjectShareType.full:
        final exportOptions = ProjectExportService.getDefaultOptions(ExportFormat.codeWhisperProject);
        final result = await ProjectExportService.exportProject(project, exportOptions);
        return result.data ?? Uint8List(0);

      case ProjectShareType.template:
        final templateData = await _createTemplateData(project);
        final jsonData = json.encode(templateData);
        return Uint8List.fromList(utf8.encode(jsonData));

      case ProjectShareType.configuration:
        final configFiles = project.files.where((f) => 
          f.path.endsWith('.yaml') || 
          f.path.endsWith('.yml') ||
          f.path.endsWith('.json') ||
          f.path.endsWith('.properties')
        ).toList();
        final configData = {'files': configFiles.map((f) => f.toJson()).toList()};
        final jsonData = json.encode(configData);
        return Uint8List.fromList(utf8.encode(jsonData));

      case ProjectShareType.structure:
        final structure = {
          'name': project.name,
          'directories': project.directories.map((d) => d.path).toList(),
          'fileStructure': project.files.map((f) => {
            'path': f.path,
            'type': f.type.name,
            'isDirectory': f.isDirectory,
          }).toList(),
        };
        final jsonData = json.encode(structure);
        return Uint8List.fromList(utf8.encode(jsonData));
    }
  }

  static Future<Map<String, dynamic>> _createTemplateData(FlutterProject project) async {
    // Clean up project-specific content for template use
    final templateFiles = project.files.map((file) {
      if (file.isDirectory) return file;
      
      var content = file.content;
      
      // Replace project name with placeholder
      content = content.replaceAll(project.name, '{{PROJECT_NAME}}');
      content = content.replaceAll(project.name.toLowerCase(), '{{PROJECT_NAME_LOWER}}');
      
      // Remove timestamps and generated IDs
      content = content.replaceAll(RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'), '{{TIMESTAMP}}');
      
      return file.copyWith(content: content);
    }).toList();

    return {
      'name': '{{PROJECT_NAME}}',
      'files': templateFiles.map((f) => f.toJson()).toList(),
      'templateMetadata': {
        'originalName': project.name,
        'createdAt': DateTime.now().toIso8601String(),
        'fileCount': templateFiles.length,
        'placeholders': ['{{PROJECT_NAME}}', '{{PROJECT_NAME_LOWER}}', '{{TIMESTAMP}}'],
      },
    };
  }

  static Future<FlutterProject> _reconstructProject(Uint8List data, ShareableProject shareableProject) async {
    final jsonData = utf8.decode(data);
    final projectData = json.decode(jsonData);

    if (projectData['format'] == 'codewhisper-project') {
      return FlutterProject.fromJson(projectData['project']);
    } else {
      // Handle other formats
      throw Exception('Unsupported project format');
    }
  }

  static Future<FlutterProject> _applyTemplate(
    ProjectTemplate template, 
    String projectName, 
    Map<String, String> customizations,
  ) async {
    final templateData = template.templateData;
    final files = (templateData['files'] as List? ?? [])
        .map((f) => ProjectFile.fromJson(f))
        .toList();

    // Apply template transformations
    final transformedFiles = files.map((file) {
      if (file.isDirectory) return file;

      var content = file.content;
      
      // Apply basic placeholders
      content = content.replaceAll('{{PROJECT_NAME}}', projectName);
      content = content.replaceAll('{{PROJECT_NAME_LOWER}}', projectName.toLowerCase());
      content = content.replaceAll('{{TIMESTAMP}}', DateTime.now().toIso8601String());
      
      // Apply custom transformations
      customizations.forEach((placeholder, value) {
        content = content.replaceAll('{{$placeholder}}', value);
      });

      return file.copyWith(content: content);
    }).toList();

    return FlutterProject(
      name: projectName,
      files: transformedFiles,
      uploadedAt: DateTime.now(),
    );
  }

  static List<ImportConflict> _detectConflicts(FlutterProject existing, FlutterProject newProject) {
    final conflicts = <ImportConflict>[];

    for (final newFile in newProject.files) {
      final existingFile = existing.files.firstWhere(
        (f) => f.path == newFile.path,
        orElse: () => ProjectFile(path: '', content: '', type: FileType.other),
      );

      if (existingFile.path.isNotEmpty) {
        if (!newFile.isDirectory && !existingFile.isDirectory) {
          if (existingFile.content != newFile.content) {
            conflicts.add(ImportConflict(
              filePath: newFile.path,
              existingContent: existingFile.content,
              newContent: newFile.content,
              type: ConflictType.differentContent,
            ));
          }
        } else {
          conflicts.add(ImportConflict(
            filePath: newFile.path,
            existingContent: existingFile.content,
            newContent: newFile.content,
            type: ConflictType.fileExists,
          ));
        }
      }
    }

    return conflicts;
  }

  static FlutterProject _mergeProjects(FlutterProject existing, FlutterProject newProject) {
    final mergedFiles = <String, ProjectFile>{};

    // Add existing files
    for (final file in existing.files) {
      mergedFiles[file.path] = file;
    }

    // Add/update with new files
    for (final file in newProject.files) {
      mergedFiles[file.path] = file;
    }

    return existing.copyWith(files: mergedFiles.values.toList());
  }

  static Map<String, dynamic> _extractDependencies(FlutterProject project) {
    final pubspecFile = project.pubspecFile;
    if (pubspecFile == null) return {};

    // Simple dependency extraction
    final lines = pubspecFile.content.split('\n');
    final dependencies = <String, dynamic>{};
    bool inDependencies = false;

    for (final line in lines) {
      if (line.trim() == 'dependencies:') {
        inDependencies = true;
        continue;
      }
      if (inDependencies && line.startsWith('  ') && line.contains(':')) {
        final parts = line.trim().split(':');
        if (parts.length >= 2) {
          dependencies[parts[0].trim()] = parts[1].trim();
        }
      } else if (inDependencies && !line.startsWith('  ')) {
        break;
      }
    }

    return dependencies;
  }

  static void _updateShareProgress(String message, double progress, {bool hasError = false}) {
    onShareProgress?.call(ShareProgress(
      message: message,
      progress: progress,
      isComplete: progress >= 1.0,
      hasError: hasError,
      error: hasError ? message : null,
    ));
  }

  static void _updateImportProgress(String message, double progress, {bool hasError = false}) {
    onImportProgress?.call(ShareProgress(
      message: message,
      progress: progress,
      isComplete: progress >= 1.0,
      hasError: hasError,
      error: hasError ? message : null,
    ));
  }
}