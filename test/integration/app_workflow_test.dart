import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/project_manager.dart';
import 'package:kre8tions/services/testing_framework_service.dart';

void main() {
  group('CodeWhisper App Workflow Integration Tests', () {
    
    test('complete project workflow simulation', () async {
      // Step 1: Create a sample Flutter project
      final sampleProject = FlutterProject(
        name: 'Sample App',
        files: [
          ProjectFile(
            path: 'lib/main.dart',
            content: '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome!')),
    );
  }
}
''',
            type: FileType.dart,
          ),
          ProjectFile(
            path: 'pubspec.yaml',
            content: '''
name: sample_app
description: A sample Flutter application
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
''',
            type: FileType.yaml,
          ),
          ProjectFile(
            path: 'test/widget_test.dart',
            content: '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app/main.dart';

void main() {
  testWidgets('HomePage displays welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Welcome!'), findsOneWidget);
  });
}
''',
            type: FileType.dart,
          ),
        ],
        uploadedAt: DateTime.now(),
      );

      // Step 2: Validate project structure
      expect(sampleProject.isValidFlutterProject, isTrue);
      expect(sampleProject.dartFiles.length, greaterThan(0));
      expect(sampleProject.pubspecFile, isNotNull);

      // Step 3: Test file operations
      final updatedProject = sampleProject.updateFile(
        'lib/main.dart', 
        '${sampleProject.findFileByPath('lib/main.dart')!.content}\n// Updated'
      );
      
      expect(
        updatedProject.findFileByPath('lib/main.dart')!.content,
        contains('// Updated')
      );

      // Step 4: Test serialization
      final jsonData = sampleProject.toJson();
      final restoredProject = FlutterProject.fromJson(jsonData);
      
      expect(restoredProject.name, equals(sampleProject.name));
      expect(restoredProject.files.length, equals(sampleProject.files.length));

      // Step 5: Test service integration
      final testingService = TestingFrameworkService();
      final testSuites = await testingService.discoverTests(sampleProject);
      
      expect(testSuites.isNotEmpty, isTrue);
      
      final testResults = await testingService.runTestSuites(testSuites);
      expect(testResults.totalTests, greaterThan(0));
      
      testingService.dispose();
    });

    test('project manager workflow', () async {
      final projectManager = ProjectManager();
      
      // Test project creation
      final newProject = FlutterProject(
        name: 'New Project',
        files: [
          ProjectFile(
            path: 'lib/main.dart',
            content: 'void main() {}',
            type: FileType.dart,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      
      expect(newProject.name, equals('New Project'));
      expect(newProject.files.length, equals(1));

      // Test project operations
      final foundFile = newProject.findFileByPath('lib/main.dart');
      expect(foundFile, isNotNull);
      expect(foundFile!.content, equals('void main() {}'));
      
      // Test file filtering
      final dartFiles = newProject.dartFiles;
      expect(dartFiles.length, equals(1));
      expect(dartFiles.first.isDartFile, isTrue);
    });

    test('code editor workflow simulation', () async {
      final testFile = ProjectFile(
        path: 'lib/test.dart',
        content: 'class TestClass {}',
        type: FileType.dart,
      );

      // Simulate editor operations
      expect(testFile.fileName, equals('test.dart'));
      expect(testFile.extension, equals('dart'));
      expect(testFile.isDartFile, isTrue);
      expect(testFile.isTextFile, isTrue);

      // Test file updates
      final updatedFile = testFile.copyWith(
        content: 'class TestClass {\n  void method() {}\n}',
      );
      
      expect(updatedFile.content, contains('void method()'));
    });

    test('testing framework comprehensive workflow', () async {
      final testingService = TestingFrameworkService();
      
      // Test mock data generation
      final userData = testingService.generateMockData('user');
      expect(userData['id'], isNotNull);
      expect(userData['name'], isNotNull);
      expect(userData['email'], isNotNull);

      final productData = testingService.generateMockData('product');
      expect(productData['id'], isNotNull);
      expect(productData['name'], isNotNull);
      expect(productData['price'], isNotNull);

      // Test file generation
      final testContent = await testingService.generateTestFile('lib/models/user.dart', 'User');
      expect(testContent, contains('User Tests'));
      expect(testContent, contains('import'));
      expect(testContent, contains('test('));

      // Test different test types
      final unitTestContent = await testingService.generateTestFile('lib/services/api.dart', 'ApiService');
      expect(unitTestContent, contains('ApiService Tests'));

      testingService.dispose();
    });

    test('error handling workflow', () async {
      // Test invalid project structure
      final invalidProject = FlutterProject(
        name: 'Invalid Project',
        files: [], // No files
        uploadedAt: DateTime.now(),
      );
      
      expect(invalidProject.isValidFlutterProject, isFalse);
      expect(invalidProject.pubspecFile, isNull);

      // Test file not found
      final foundFile = invalidProject.findFileByPath('non-existent.dart');
      expect(foundFile, isNull);

      // Test empty content handling
      final emptyFile = ProjectFile(
        path: 'empty.dart',
        content: '',
        type: FileType.dart,
      );
      
      expect(emptyFile.content.isEmpty, isTrue);
      expect(emptyFile.isDartFile, isTrue);
    });

    test('performance and memory workflow', () async {
      final startTime = DateTime.now();
      
      // Create a larger project to test performance
      final largeProject = FlutterProject(
        name: 'Large Project',
        files: List.generate(50, (index) => ProjectFile(
          path: 'lib/file_$index.dart',
          content: 'class File$index { void method$index() {} }',
          type: FileType.dart,
        )),
        uploadedAt: DateTime.now(),
      );
      
      // Test operations on large project
      expect(largeProject.dartFiles.length, equals(50));
      
      // Find specific file
      final specificFile = largeProject.findFileByPath('lib/file_25.dart');
      expect(specificFile, isNotNull);
      expect(specificFile!.content, contains('File25'));
      
      // Test serialization performance
      final jsonData = largeProject.toJson();
      expect(jsonData['files'], hasLength(50));
      
      final restoredProject = FlutterProject.fromJson(jsonData);
      expect(restoredProject.files.length, equals(50));
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Should complete within reasonable time (less than 1 second)
      expect(duration.inMilliseconds, lessThan(1000));
    });

    test('cross-platform compatibility workflow', () async {
      // Test different file types
      final multiTypeProject = FlutterProject(
        name: 'Multi-Type Project',
        files: [
          ProjectFile(path: 'lib/main.dart', content: 'void main() {}', type: FileType.dart),
          ProjectFile(path: 'pubspec.yaml', content: 'name: test', type: FileType.yaml),
          ProjectFile(path: 'README.md', content: '# Test', type: FileType.markdown),
          ProjectFile(path: 'config.json', content: '{}', type: FileType.json),
          ProjectFile(path: 'assets/image.png', content: 'binary', type: FileType.image),
        ],
        uploadedAt: DateTime.now(),
      );

      expect(multiTypeProject.files.length, equals(5));
      expect(multiTypeProject.dartFiles.length, equals(1));
      
      // Test file type detection
      final dartFile = multiTypeProject.files.firstWhere((f) => f.path.endsWith('.dart'));
      expect(dartFile.isDartFile, isTrue);
      expect(dartFile.isTextFile, isTrue);
      
      final yamlFile = multiTypeProject.files.firstWhere((f) => f.path.endsWith('.yaml'));
      expect(yamlFile.isYamlFile, isTrue);
      expect(yamlFile.isTextFile, isTrue);
      
      final imageFile = multiTypeProject.files.firstWhere((f) => f.path.endsWith('.png'));
      expect(imageFile.isTextFile, isFalse);
      expect(imageFile.type, equals(FileType.image));
    });
  });
}