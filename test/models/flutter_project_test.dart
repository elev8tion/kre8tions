import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

void main() {
  group('FlutterProject Tests', () {
    late FlutterProject project;

    setUp(() {
      project = FlutterProject(
        name: 'Test Project',
        files: [],
        uploadedAt: DateTime.now(),
      );
    });

    test('should create FlutterProject instance', () {
      expect(project, isNotNull);
      expect(project, isA<FlutterProject>());
      expect(project.name, equals('Test Project'));
    });

    test('should handle file operations', () {
      final testFile = ProjectFile(
        path: 'lib/main.dart',
        content: 'void main() {}',
        type: FileType.dart,
      );

      project = project.copyWith(files: [testFile]);
      
      expect(project.files.length, equals(1));
      expect(project.files.first.path, equals('lib/main.dart'));
    });

    test('should identify dart files', () {
      final dartFile = ProjectFile(
        path: 'lib/main.dart',
        content: 'void main() {}',
        type: FileType.dart,
      );
      
      final yamlFile = ProjectFile(
        path: 'pubspec.yaml',
        content: 'name: test',
        type: FileType.yaml,
      );

      project = project.copyWith(files: [dartFile, yamlFile]);
      
      expect(project.dartFiles.length, equals(1));
      expect(project.dartFiles.first.path, equals('lib/main.dart'));
    });

    test('should find pubspec file', () {
      final pubspecFile = ProjectFile(
        path: 'pubspec.yaml',
        content: 'name: test_project\nversion: 1.0.0',
        type: FileType.yaml,
      );

      project = project.copyWith(files: [pubspecFile]);
      
      expect(project.pubspecFile, isNotNull);
      expect(project.pubspecFile!.path, equals('pubspec.yaml'));
    });

    test('should validate Flutter project structure', () {
      final files = [
        ProjectFile(
          path: 'lib/main.dart',
          content: 'void main() {}',
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'pubspec.yaml',
          content: 'name: test',
          type: FileType.yaml,
        ),
      ];

      project = project.copyWith(files: files);
      
      expect(project.isValidFlutterProject, isTrue);
    });

    test('should update file content', () {
      final originalFile = ProjectFile(
        path: 'lib/main.dart',
        content: 'void main() {}',
        type: FileType.dart,
      );

      project = project.copyWith(files: [originalFile]);
      
      final updatedProject = project.updateFile('lib/main.dart', 'void main() { print("Hello"); }');
      
      expect(updatedProject.findFileByPath('lib/main.dart')?.content, 
             contains('Hello'));
    });

    test('should find files by path', () {
      final testFile = ProjectFile(
        path: 'lib/models/user.dart',
        content: 'class User {}',
        type: FileType.dart,
      );

      project = project.copyWith(files: [testFile]);
      
      final foundFile = project.findFileByPath('lib/models/user.dart');
      expect(foundFile, isNotNull);
      expect(foundFile!.content, equals('class User {}'));
    });

    test('should serialize to/from JSON', () {
      final files = [
        ProjectFile(
          path: 'lib/main.dart',
          content: 'void main() {}',
          type: FileType.dart,
        ),
      ];

      project = project.copyWith(files: files);
      
      final json = project.toJson();
      expect(json['name'], equals('Test Project'));
      expect(json['files'], isA<List>());
      
      final restoredProject = FlutterProject.fromJson(json);
      expect(restoredProject.name, equals(project.name));
      expect(restoredProject.files.length, equals(project.files.length));
    });

    tearDown(() {
      // Cleanup if needed
    });
  });
}