import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/file_operations.dart';

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
            content = '[Binary File - \${FileOperations.formatFileSize(file.size)}]';
          } else {
            // Try to decode as text, fallback to binary description
            try {
              content = utf8.decode(file.content as List<int>);
            } catch (e) {
              content = '[Binary File - \${FileOperations.formatFileSize(file.size)}]';
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
      throw Exception('Failed to load project: \$e');
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
      throw Exception('Failed to export project: \$e');
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
      structure.add('\$indent\$icon \${file.fileName}');
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

  // Advanced File Management Operations
  static FlutterProject createFile(FlutterProject project, String filePath, String content) {
    // Check if file already exists
    final existingFile = project.files.firstWhere(
      (file) => file.path == filePath,
      orElse: () => ProjectFile(path: '', content: '', type: FileType.other),
    );
    
    if (existingFile.path.isNotEmpty) {
      throw Exception('File already exists: $filePath');
    }
    
    // Create new file
    final newFile = ProjectFile(
      path: filePath,
      content: content,
      type: FileTypeExtension.fromExtension(filePath.split('.').last),
    );
    
    final updatedFiles = [...project.files, newFile];
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject createDirectory(FlutterProject project, String dirPath) {
    // Check if directory already exists
    final existingDir = project.files.firstWhere(
      (file) => file.path == dirPath && file.isDirectory,
      orElse: () => ProjectFile(path: '', content: '', type: FileType.other),
    );
    
    if (existingDir.path.isNotEmpty) {
      throw Exception('Directory already exists: $dirPath');
    }
    
    // Create new directory
    final newDir = ProjectFile(
      path: dirPath,
      content: '',
      type: FileType.other,
      isDirectory: true,
    );
    
    final updatedFiles = [...project.files, newDir];
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject deleteFile(FlutterProject project, String filePath) {
    final updatedFiles = project.files.where((file) => file.path != filePath).toList();
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject deleteDirectory(FlutterProject project, String dirPath) {
    // Delete directory and all files within it
    final updatedFiles = project.files.where((file) => 
      !file.path.startsWith('$dirPath/') && file.path != dirPath
    ).toList();
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject renameFile(FlutterProject project, String oldPath, String newPath) {
    final updatedFiles = project.files.map((file) {
      if (file.path == oldPath) {
        return ProjectFile(
          path: newPath,
          content: file.content,
          type: FileTypeExtension.fromExtension(newPath.split('.').last),
          isDirectory: file.isDirectory,
        );
      }
      return file;
    }).toList();
    
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject renameDirectory(FlutterProject project, String oldPath, String newPath) {
    final updatedFiles = project.files.map((file) {
      if (file.path == oldPath) {
        // Rename the directory itself
        return ProjectFile(
          path: newPath,
          content: file.content,
          type: file.type,
          isDirectory: file.isDirectory,
        );
      } else if (file.path.startsWith('$oldPath/')) {
        // Rename files within the directory
        final newFilePath = file.path.replaceFirst('$oldPath/', '$newPath/');
        return ProjectFile(
          path: newFilePath,
          content: file.content,
          type: file.type,
          isDirectory: file.isDirectory,
        );
      }
      return file;
    }).toList();
    
    return project.copyWith(files: updatedFiles);
  }

  static FlutterProject updateFileContent(FlutterProject project, String filePath, String newContent) {
    final updatedFiles = project.files.map((file) {
      if (file.path == filePath) {
        return ProjectFile(
          path: file.path,
          content: newContent,
          type: file.type,
          isDirectory: file.isDirectory,
        );
      }
      return file;
    }).toList();
    
    return project.copyWith(files: updatedFiles);
  }

  static bool fileExists(FlutterProject project, String filePath) {
    return project.files.any((file) => file.path == filePath);
  }

  static bool directoryExists(FlutterProject project, String dirPath) {
    return project.files.any((file) => file.path == dirPath && file.isDirectory);
  }

  static List<String> getExistingFileNames(FlutterProject project, String directory) {
    return project.files
        .where((file) => file.path.startsWith('$directory/') && 
                        !file.path.substring(directory.length + 1).contains('/'))
        .map((file) => file.fileName)
        .toList();
  }

  static List<String> getExistingDirectoryNames(FlutterProject project, String parentDirectory) {
    final prefix = parentDirectory.isEmpty ? '' : '$parentDirectory/';
    return project.files
        .where((file) => file.isDirectory && 
                        file.path.startsWith(prefix) &&
                        file.path.substring(prefix.length).split('/').length == 1)
        .map((file) => file.path.split('/').last)
        .toList();
  }
}