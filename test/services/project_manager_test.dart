import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/services/project_manager.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import '../test_config.dart';

void main() {
  group('ProjectManager ZIP Operations Tests', () {
    
    test('should load project from ZIP bytes successfully', () async {
      // Create a test project to simulate ZIP loading
      final testProject = TestDataGenerator.generateFlutterProject('test_zip_project');
      
      // Export to ZIP first to create proper ZIP data
      final zipBytes = await ProjectManager.exportProjectToZip(testProject);
      final zipBytesTyped = Uint8List.fromList(zipBytes);
      
      // Load project from ZIP bytes
      final loadedProject = await ProjectManager.loadProjectFromZip(
        zipBytesTyped,
        'test_project.zip'
      );
      
      expect(loadedProject, isNotNull);
      expect(loadedProject!.name, equals('test_project'));
      expect(loadedProject.isValidFlutterProject, isTrue);
    });

    test('should handle invalid ZIP gracefully', () async {
      final invalidZipBytes = Uint8List.fromList([1, 2, 3, 4, 5]); // Invalid ZIP data
      
      expect(
        () => ProjectManager.loadProjectFromZip(invalidZipBytes, 'invalid.zip'),
        throwsException,
      );
    });

    test('should export project to ZIP successfully', () async {
      final testProject = TestDataGenerator.generateFlutterProject('export_test');
      
      final zipBytes = await ProjectManager.exportProjectToZip(testProject);
      
      expect(zipBytes, isNotNull);
      expect(zipBytes, isNotEmpty);
    });

    test('should validate Flutter project structure', () async {
      final validProject = TestDataGenerator.generateFlutterProject();
      expect(validProject.isValidFlutterProject, isTrue);
      
      // Test project without pubspec.yaml
      final invalidProject = FlutterProject(
        name: 'invalid',
        files: [
          ProjectFile(
            path: 'lib/main.dart',
            content: 'void main() {}',
            type: FileType.dart,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      expect(invalidProject.isValidFlutterProject, isFalse);
    });
  });

  group('ProjectManager File Management Tests', () {
    late FlutterProject testProject;
    
    setUp(() {
      testProject = TestDataGenerator.generateFlutterProject();
    });

    test('should create new file in project', () {
      final updatedProject = ProjectManager.createFile(
        testProject, 
        'lib/new_widget.dart', 
        'class NewWidget {}'
      );
      
      expect(updatedProject.files.length, equals(testProject.files.length + 1));
      final newFile = updatedProject.findFileByPath('lib/new_widget.dart');
      expect(newFile, isNotNull);
      expect(newFile!.content, equals('class NewWidget {}'));
    });

    test('should create new directory in project', () {
      final updatedProject = ProjectManager.createDirectory(testProject, 'lib/screens');
      
      expect(updatedProject.files.length, equals(testProject.files.length + 1));
      final newDir = updatedProject.files.where(
        (f) => f.path == 'lib/screens' && f.isDirectory
      ).firstOrNull;
      expect(newDir, isNotNull);
    });

    test('should delete file from project', () {
      final filePath = testProject.files.first.path;
      final updatedProject = ProjectManager.deleteFile(testProject, filePath);
      
      expect(updatedProject.files.length, equals(testProject.files.length - 1));
      expect(updatedProject.findFileByPath(filePath), isNull);
    });

    test('should update file content', () {
      final filePath = testProject.files.first.path;
      const newContent = 'Updated content';
      
      final updatedProject = ProjectManager.updateFileContent(
        testProject, 
        filePath, 
        newContent
      );
      
      final updatedFile = updatedProject.findFileByPath(filePath);
      expect(updatedFile, isNotNull);
      expect(updatedFile!.content, equals(newContent));
    });

    test('should rename file', () {
      final oldPath = testProject.files.first.path;
      const newPath = 'lib/renamed_file.dart';
      
      final updatedProject = ProjectManager.renameFile(testProject, oldPath, newPath);
      
      expect(updatedProject.findFileByPath(oldPath), isNull);
      expect(updatedProject.findFileByPath(newPath), isNotNull);
    });

    test('should check if file exists', () {
      final existingPath = testProject.files.first.path;
      const nonExistingPath = 'lib/non_existing.dart';
      
      expect(ProjectManager.fileExists(testProject, existingPath), isTrue);
      expect(ProjectManager.fileExists(testProject, nonExistingPath), isFalse);
    });
  });

  group('ProjectManager Structure Analysis Tests', () {
    late FlutterProject testProject;
    
    setUp(() {
      testProject = TestDataGenerator.generateFlutterProject();
    });

    test('should generate project structure', () {
      final structure = ProjectManager.getProjectStructure(testProject);
      
      expect(structure, isNotNull);
      expect(structure, isNotEmpty);
      expect(structure.any((line) => line.contains('main.dart')), isTrue);
    });

    test('should group files by directory', () {
      final grouped = ProjectManager.groupFilesByDirectory(testProject);
      
      expect(grouped, isNotNull);
      expect(grouped.containsKey('lib'), isTrue);
    });

    test('should get directory tree', () {
      final directories = ProjectManager.getDirectoryTree(testProject);
      
      expect(directories, isNotNull);
      expect(directories, isNotEmpty);
    });

    test('should get existing file names in directory', () {
      final libFiles = ProjectManager.getExistingFileNames(testProject, 'lib');
      
      expect(libFiles, isNotNull);
      expect(libFiles, isNotEmpty);
    });
  });

  group('ProjectManager Performance Tests', () {
    test('should handle large project operations efficiently', () async {
      final stopwatch = Stopwatch()..start();
      
      final largeProject = TestDataGenerator.generateLargeFlutterProject();
      final zipBytes = await ProjectManager.exportProjectToZip(largeProject);
      
      stopwatch.stop();
      
      expect(zipBytes, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
    });

    test('should maintain performance with file operations', () {
      final project = TestDataGenerator.generateFlutterProject();
      final stopwatch = Stopwatch()..start();
      
      FlutterProject currentProject = project;
      
      // Perform multiple file operations
      for (int i = 0; i < 50; i++) {
        currentProject = ProjectManager.createFile(
          currentProject,
          'lib/generated_$i.dart',
          'class Generated$i {}'
        );
      }
      
      stopwatch.stop();
      
      expect(currentProject.files.length, equals(project.files.length + 50));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
    });
  });

  group('ProjectManager Error Handling Tests', () {
    late FlutterProject testProject;
    
    setUp(() {
      testProject = TestDataGenerator.generateFlutterProject();
    });

    test('should handle duplicate file creation', () {
      final existingPath = testProject.files.first.path;
      
      expect(
        () => ProjectManager.createFile(testProject, existingPath, 'content'),
        throwsException,
      );
    });

    test('should handle duplicate directory creation', () {
      final updatedProject = ProjectManager.createDirectory(testProject, 'lib/test');
      
      expect(
        () => ProjectManager.createDirectory(updatedProject, 'lib/test'),
        throwsException,
      );
    });

    test('should handle export project errors gracefully', () async {
      // Create a project with problematic content
      final problematicProject = FlutterProject(
        name: 'problem_project',
        files: [], // Empty files list
        uploadedAt: DateTime.now(),
      );
      
      final zipBytes = await ProjectManager.exportProjectToZip(problematicProject);
      expect(zipBytes, isNotNull); // Should not throw, but return empty or minimal ZIP
    });
  });
}