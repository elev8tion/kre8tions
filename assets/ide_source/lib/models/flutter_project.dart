import 'package:kre8tions/models/project_file.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'files': files.map((f) => f.toJson()).toList(),
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory FlutterProject.fromJson(Map<String, dynamic> json) {
    return FlutterProject(
      name: json['name'] ?? 'Unnamed Project',
      files: (json['files'] as List? ?? [])
        .map((f) => ProjectFile.fromJson(f))
        .toList(),
      uploadedAt: json['uploadedAt'] != null
        ? DateTime.parse(json['uploadedAt'])
        : DateTime.now(),
    );
  }

  FlutterProject copyWith({
    String? name,
    List<ProjectFile>? files,
    DateTime? uploadedAt,
  }) {
    return FlutterProject(
      name: name ?? this.name,
      files: files ?? this.files,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}