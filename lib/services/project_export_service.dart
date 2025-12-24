import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

// ✨ TIER 9: DEPLOYMENT & DISTRIBUTION - ULTIMATE EXPORT SYSTEM ✨

enum DeploymentTarget {
  playStore,
  appStore,
  webHosting,
  dockerRegistry,
  githubPages,
  firebaseHosting,
  desktopStore,
  enterpriseDistribution
}

enum BuildConfiguration {
  debug,
  profile,
  release
}

class DeploymentConfig {
  final DeploymentTarget target;
  final BuildConfiguration buildConfig;
  final Map<String, dynamic> platformSettings;
  final String? apiKey;
  final String? certificatePath;
  final bool enableObfuscation;
  final bool enableMinification;
  final List<String> buildFlags;
  final Map<String, String> environmentVariables;
  
  const DeploymentConfig({
    required this.target,
    this.buildConfig = BuildConfiguration.release,
    this.platformSettings = const {},
    this.apiKey,
    this.certificatePath,
    this.enableObfuscation = false,
    this.enableMinification = true,
    this.buildFlags = const [],
    this.environmentVariables = const {},
  });
}

class BuildResult {
  final bool success;
  final String? outputPath;
  final int? fileSizeBytes;
  final Duration buildDuration;
  final String? downloadUrl;
  final String? deploymentUrl;
  final List<String> warnings;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  
  const BuildResult({
    required this.success,
    this.outputPath,
    this.fileSizeBytes,
    required this.buildDuration,
    this.downloadUrl,
    this.deploymentUrl,
    this.warnings = const [],
    this.errorMessage,
    this.metadata = const {},
  });
  
  BuildResult.success({
    required String outputPath,
    required int fileSizeBytes, 
    required Duration buildDuration,
    String? downloadUrl,
    String? deploymentUrl,
    List<String> warnings = const [],
    Map<String, dynamic> metadata = const {},
  }) : success = true,
       outputPath = outputPath,
       fileSizeBytes = fileSizeBytes,
       buildDuration = buildDuration,
       downloadUrl = downloadUrl,
       deploymentUrl = deploymentUrl,
       warnings = warnings,
       errorMessage = null,
       metadata = metadata;
       
  BuildResult.error(String errorMessage, Duration buildDuration)
    : success = false,
      outputPath = null,
      fileSizeBytes = null,
      buildDuration = buildDuration,
      downloadUrl = null,
      deploymentUrl = null,
      warnings = const [],
      errorMessage = errorMessage,
      metadata = const {};
}

class ProjectExportOptions {
  final bool includeLibFiles;
  final bool includeTestFiles;
  final bool includeAndroidFiles;
  final bool includeIosFiles;
  final bool includeWebFiles;
  final bool includeAssets;
  final bool includeDependencies;
  final bool includeHiddenFiles;
  final bool includeBuildFiles;
  final bool includeGitFiles;
  final ExportFormat format;
  final List<String> customExcludePaths;
  final List<String> customIncludePaths;
  
  const ProjectExportOptions({
    this.includeLibFiles = true,
    this.includeTestFiles = true,
    this.includeAndroidFiles = false,
    this.includeIosFiles = false,
    this.includeWebFiles = false,
    this.includeAssets = true,
    this.includeDependencies = true,
    this.includeHiddenFiles = false,
    this.includeBuildFiles = false,
    this.includeGitFiles = false,
    this.format = ExportFormat.zip,
    this.customExcludePaths = const [],
    this.customIncludePaths = const [],
  });
}

enum ExportFormat {
  zip,
  flutterTemplate,
  codeWhisperProject,
  sourceOnly,
  apk,
  aab,
  ipa,
  webBuild,
  windowsExe,
  macosApp,
  linuxBinary,
  dockerImage,
  githubRepo,
}

class ExportProgress {
  final String message;
  final double progress;
  final bool isComplete;
  final bool hasError;
  final String? error;
  
  const ExportProgress({
    required this.message,
    required this.progress,
    this.isComplete = false,
    this.hasError = false,
    this.error,
  });
}

class ProjectExportResult {
  final Uint8List? data;
  final String filename;
  final ExportFormat format;
  final Map<String, dynamic> metadata;
  final bool success;
  final String? error;
  
  const ProjectExportResult({
    this.data,
    required this.filename,
    required this.format,
    this.metadata = const {},
    this.success = true,
    this.error,
  });
}

class ProjectExportService {
  // Export progress callback
  static void Function(ExportProgress)? onProgress;

  /// Export project with specified options
  static Future<ProjectExportResult> exportProject(
    FlutterProject project, 
    ProjectExportOptions options,
  ) async {
    try {
      _updateProgress('Preparing export...', 0.0);

      switch (options.format) {
        case ExportFormat.zip:
          return await _exportAsZip(project, options);
        case ExportFormat.flutterTemplate:
          return await _exportAsFlutterTemplate(project, options);
        case ExportFormat.codeWhisperProject:
          return await _exportAsCodeWhisperProject(project, options);
        case ExportFormat.sourceOnly:
          return await _exportSourceOnly(project, options);
        case ExportFormat.apk:
        case ExportFormat.aab:
        case ExportFormat.ipa:
        case ExportFormat.webBuild:
        case ExportFormat.windowsExe:
        case ExportFormat.macosApp:
        case ExportFormat.linuxBinary:
        case ExportFormat.dockerImage:
        case ExportFormat.githubRepo:
          throw UnimplementedError('${options.format.name} export not yet implemented');
      }
    } catch (e) {
      return ProjectExportResult(
        filename: '${project.name}_export_error.txt',
        format: options.format,
        success: false,
        error: 'Export failed: $e',
      );
    }
  }

  /// Export as standard ZIP file
  static Future<ProjectExportResult> _exportAsZip(
    FlutterProject project, 
    ProjectExportOptions options,
  ) async {
    _updateProgress('Building file archive...', 0.2);

    final archive = Archive();
    final filteredFiles = _filterFiles(project.files, options);
    
    _updateProgress('Processing files...', 0.4);

    for (int i = 0; i < filteredFiles.length; i++) {
      final file = filteredFiles[i];
      final progress = 0.4 + (i / filteredFiles.length) * 0.5;
      _updateProgress('Processing ${file.path}...', progress);

      if (file.isDirectory) {
        archive.addFile(ArchiveFile(file.path, 0, <int>[]));
      } else if (!file.content.startsWith('[Binary File')) {
        final bytes = utf8.encode(file.content);
        archive.addFile(ArchiveFile(file.path, bytes.length, bytes));
      }
    }

    _updateProgress('Compressing archive...', 0.9);
    final encoded = ZipEncoder().encode(archive);

    _updateProgress('Export complete!', 1.0);

    return ProjectExportResult(
      data: Uint8List.fromList(encoded),
      filename: '${project.name}_${DateTime.now().millisecondsSinceEpoch}.zip',
      format: ExportFormat.zip,
      metadata: {
        'fileCount': filteredFiles.length,
        'exportDate': DateTime.now().toIso8601String(),
        'options': _serializeOptions(options),
      },
    );
  }

  /// Export as Flutter project template
  static Future<ProjectExportResult> _exportAsFlutterTemplate(
    FlutterProject project, 
    ProjectExportOptions options,
  ) async {
    _updateProgress('Creating Flutter template...', 0.2);

    final archive = Archive();
    final filteredFiles = _filterFiles(project.files, options);
    
    // Add template metadata
    final templateMetadata = {
      'name': project.name,
      'description': 'Flutter project template exported from CodeWhisper',
      'version': '1.0.0',
      'type': 'flutter-template',
      'exportedAt': DateTime.now().toIso8601String(),
      'originalProject': {
        'name': project.name,
        'fileCount': project.files.length,
        'hasTests': project.files.any((f) => f.path.startsWith('test/')),
        'dependencies': _extractDependencies(project),
      },
    };

    final metadataBytes = utf8.encode(json.encode(templateMetadata));
    archive.addFile(ArchiveFile('template_metadata.json', metadataBytes.length, metadataBytes));

    _updateProgress('Processing template files...', 0.4);

    // Add README for template usage
    final readmeContent = _generateTemplateReadme(project, templateMetadata);
    final readmeBytes = utf8.encode(readmeContent);
    archive.addFile(ArchiveFile('TEMPLATE_README.md', readmeBytes.length, readmeBytes));

    // Process files
    for (int i = 0; i < filteredFiles.length; i++) {
      final file = filteredFiles[i];
      final progress = 0.4 + (i / filteredFiles.length) * 0.5;
      _updateProgress('Processing ${file.path}...', progress);

      if (file.isDirectory) {
        archive.addFile(ArchiveFile(file.path, 0, <int>[]));
      } else if (!file.content.startsWith('[Binary File')) {
        final bytes = utf8.encode(file.content);
        archive.addFile(ArchiveFile(file.path, bytes.length, bytes));
      }
    }

    _updateProgress('Creating template archive...', 0.9);
    final encoded = ZipEncoder().encode(archive);

    _updateProgress('Template export complete!', 1.0);

    return ProjectExportResult(
      data: Uint8List.fromList(encoded),
      filename: '${project.name}_flutter_template.zip',
      format: ExportFormat.flutterTemplate,
      metadata: templateMetadata,
    );
  }

  /// Export as CodeWhisper project format
  static Future<ProjectExportResult> _exportAsCodeWhisperProject(
    FlutterProject project, 
    ProjectExportOptions options,
  ) async {
    _updateProgress('Creating CodeWhisper project...', 0.2);

    final projectData = {
      'format': 'codewhisper-project',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'project': project.toJson(),
      'exportOptions': _serializeOptions(options),
      'metadata': {
        'totalFiles': project.files.length,
        'dartFiles': project.files.where((f) => f.isDartFile).length,
        'directories': project.files.where((f) => f.isDirectory).length,
        'hasTests': project.files.any((f) => f.path.startsWith('test/')),
        'dependencies': _extractDependencies(project),
        'structure': _generateProjectStructure(project),
      },
    };

    _updateProgress('Serializing project data...', 0.7);
    final jsonData = json.encode(projectData);
    final bytes = utf8.encode(jsonData);

    _updateProgress('CodeWhisper project export complete!', 1.0);

    return ProjectExportResult(
      data: Uint8List.fromList(bytes),
      filename: '${project.name}_codewhisper.json',
      format: ExportFormat.codeWhisperProject,
      metadata: projectData['metadata'] as Map<String, dynamic>,
    );
  }

  /// Export source code only
  static Future<ProjectExportResult> _exportSourceOnly(
    FlutterProject project, 
    ProjectExportOptions options,
  ) async {
    _updateProgress('Creating source archive...', 0.2);

    final archive = Archive();
    final sourceFiles = project.files.where((file) => 
      file.isDartFile || 
      file.path.endsWith('.yaml') || 
      file.path.endsWith('.yml') ||
      file.path.endsWith('.json') ||
      file.path.endsWith('.md')
    ).toList();

    _updateProgress('Processing source files...', 0.4);

    for (int i = 0; i < sourceFiles.length; i++) {
      final file = sourceFiles[i];
      final progress = 0.4 + (i / sourceFiles.length) * 0.5;
      _updateProgress('Processing ${file.path}...', progress);

      if (!file.isDirectory && !file.content.startsWith('[Binary File')) {
        final bytes = utf8.encode(file.content);
        archive.addFile(ArchiveFile(file.path, bytes.length, bytes));
      }
    }

    _updateProgress('Compressing source files...', 0.9);
    final encoded = ZipEncoder().encode(archive);

    _updateProgress('Source export complete!', 1.0);

    return ProjectExportResult(
      data: Uint8List.fromList(encoded),
      filename: '${project.name}_source_only.zip',
      format: ExportFormat.sourceOnly,
      metadata: {
        'sourceFileCount': sourceFiles.length,
        'exportDate': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Filter files based on export options
  static List<ProjectFile> _filterFiles(List<ProjectFile> files, ProjectExportOptions options) {
    return files.where((file) {
      // Custom include paths override everything
      if (options.customIncludePaths.isNotEmpty) {
        final included = options.customIncludePaths.any((pattern) => 
          file.path.contains(pattern) || _matchesGlob(file.path, pattern));
        if (!included) return false;
      }

      // Custom exclude paths
      if (options.customExcludePaths.any((pattern) => 
          file.path.contains(pattern) || _matchesGlob(file.path, pattern))) {
        return false;
      }

      // Built-in filters
      if (!options.includeLibFiles && file.path.startsWith('lib/')) return false;
      if (!options.includeTestFiles && file.path.startsWith('test/')) return false;
      if (!options.includeAndroidFiles && file.path.startsWith('android/')) return false;
      if (!options.includeIosFiles && file.path.startsWith('ios/')) return false;
      if (!options.includeWebFiles && file.path.startsWith('web/')) return false;
      if (!options.includeAssets && file.path.startsWith('assets/')) return false;
      if (!options.includeHiddenFiles && file.path.contains('/.')) return false;
      if (!options.includeBuildFiles && file.path.startsWith('build/')) return false;
      if (!options.includeGitFiles && (file.path.startsWith('.git/') || file.path == '.gitignore')) return false;

      return true;
    }).toList();
  }

  /// Simple glob pattern matching
  static bool _matchesGlob(String path, String pattern) {
    if (pattern.contains('*')) {
      final regexPattern = pattern.replaceAll('*', '.*');
      return RegExp(regexPattern).hasMatch(path);
    }
    return path.contains(pattern);
  }

  /// Extract dependencies from pubspec.yaml
  static Map<String, dynamic> _extractDependencies(FlutterProject project) {
    final pubspecFile = project.pubspecFile;
    if (pubspecFile == null) return {};

    try {
      // Simple extraction - in real implementation would use yaml parser
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
    } catch (e) {
      return {};
    }
  }

  /// Generate project structure summary
  static Map<String, dynamic> _generateProjectStructure(FlutterProject project) {
    final structure = <String, dynamic>{};
    final directories = <String>{};
    
    for (final file in project.files) {
      if (file.isDirectory) {
        directories.add(file.path);
      } else {
        final dir = file.path.contains('/') 
          ? file.path.substring(0, file.path.lastIndexOf('/'))
          : '';
        directories.add(dir);
      }
    }

    structure['directories'] = directories.toList()..sort();
    structure['filesByType'] = {
      'dart': project.files.where((f) => f.isDartFile).length,
      'yaml': project.files.where((f) => f.isYamlFile).length,
      'json': project.files.where((f) => f.isJsonFile).length,
      'other': project.files.where((f) => !f.isDartFile && !f.isYamlFile && !f.isJsonFile).length,
    };

    return structure;
  }

  /// Generate template README content
  static String _generateTemplateReadme(FlutterProject project, Map<String, dynamic> metadata) {
    return '''
# ${project.name} - Flutter Template

This is a Flutter project template exported from CodeWhisper.

## Project Information
- **Original Name**: ${project.name}
- **Exported**: ${metadata['exportedAt']}
- **Files**: ${metadata['originalProject']['fileCount']} files
- **Has Tests**: ${metadata['originalProject']['hasTests']}

## Usage

1. Extract this template to your desired location
2. Run `flutter pub get` to install dependencies
3. Customize the project as needed
4. Run `flutter run` to start the application

## Dependencies

${_formatDependencies(metadata['originalProject']['dependencies'] as Map<String, dynamic>)}

## Template Structure

This template includes:
- Core application code in `lib/`
- Project configuration files
- Asset definitions (if any)
- Basic project documentation

## Getting Started

After extracting the template:

```bash
flutter pub get
flutter run
```

---

*Template generated by CodeWhisper - The Advanced Flutter IDE*
''';
  }

  /// Format dependencies for README
  static String _formatDependencies(Map<String, dynamic> dependencies) {
    if (dependencies.isEmpty) return 'No dependencies found.';

    final buffer = StringBuffer();
    dependencies.forEach((key, value) {
      buffer.writeln('- `$key`: $value');
    });
    return buffer.toString();
  }

  /// Serialize export options to JSON
  static Map<String, dynamic> _serializeOptions(ProjectExportOptions options) {
    return {
      'includeLibFiles': options.includeLibFiles,
      'includeTestFiles': options.includeTestFiles,
      'includeAndroidFiles': options.includeAndroidFiles,
      'includeIosFiles': options.includeIosFiles,
      'includeWebFiles': options.includeWebFiles,
      'includeAssets': options.includeAssets,
      'includeDependencies': options.includeDependencies,
      'includeHiddenFiles': options.includeHiddenFiles,
      'includeBuildFiles': options.includeBuildFiles,
      'includeGitFiles': options.includeGitFiles,
      'format': options.format.name,
      'customExcludePaths': options.customExcludePaths,
      'customIncludePaths': options.customIncludePaths,
    };
  }

  /// Update progress callback
  static void _updateProgress(String message, double progress) {
    onProgress?.call(ExportProgress(
      message: message,
      progress: progress,
      isComplete: progress >= 1.0,
    ));
  }

  /// Get default export options for common scenarios
  static ProjectExportOptions getDefaultOptions(ExportFormat format) {
    switch (format) {
      case ExportFormat.zip:
        return const ProjectExportOptions();
      
      case ExportFormat.flutterTemplate:
        return const ProjectExportOptions(
          includeAndroidFiles: true,
          includeIosFiles: true,
          includeWebFiles: true,
        );
      
      case ExportFormat.codeWhisperProject:
        return const ProjectExportOptions(
          includeHiddenFiles: true,
          includeBuildFiles: false,
        );
      
      case ExportFormat.sourceOnly:
        return const ProjectExportOptions(
          includeAndroidFiles: false,
          includeIosFiles: false,
          includeWebFiles: false,
          includeBuildFiles: false,
          includeHiddenFiles: false,
        );
      
      case ExportFormat.apk:
      case ExportFormat.aab:
      case ExportFormat.ipa:
      case ExportFormat.webBuild:
      case ExportFormat.windowsExe:
      case ExportFormat.macosApp:
      case ExportFormat.linuxBinary:
      case ExportFormat.dockerImage:
      case ExportFormat.githubRepo:
        return const ProjectExportOptions();
    }
  }

  /// Create a project snapshot with current state
  static Future<ProjectExportResult> createProjectSnapshot(FlutterProject project) async {
    final snapshot = {
      'format': 'codewhisper-snapshot',
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'project': project.toJson(),
      'snapshot': {
        'fileHashes': _generateFileHashes(project.files),
        'structure': _generateProjectStructure(project),
        'statistics': {
          'totalFiles': project.files.length,
          'totalLines': _countTotalLines(project.files),
          'totalSize': _calculateTotalSize(project.files),
        },
      },
    };

    final jsonData = json.encode(snapshot);
    final bytes = utf8.encode(jsonData);

    return ProjectExportResult(
      data: Uint8List.fromList(bytes),
      filename: '${project.name}_snapshot_${DateTime.now().millisecondsSinceEpoch}.json',
      format: ExportFormat.codeWhisperProject,
      metadata: snapshot['snapshot'] as Map<String, dynamic>,
    );
  }

  /// Generate file hashes for change detection
  static Map<String, String> _generateFileHashes(List<ProjectFile> files) {
    final hashes = <String, String>{};
    for (final file in files) {
      if (!file.isDirectory) {
        // Simple hash - in production use crypto hash
        hashes[file.path] = file.content.length.toString();
      }
    }
    return hashes;
  }

  /// Count total lines in project
  static int _countTotalLines(List<ProjectFile> files) {
    int totalLines = 0;
    for (final file in files) {
      if (!file.isDirectory && file.isTextFile) {
        totalLines += file.content.split('\n').length;
      }
    }
    return totalLines;
  }

  /// Calculate total project size
  static int _calculateTotalSize(List<ProjectFile> files) {
    int totalSize = 0;
    for (final file in files) {
      if (!file.isDirectory) {
        totalSize += file.content.length;
      }
    }
    return totalSize;
  }
}