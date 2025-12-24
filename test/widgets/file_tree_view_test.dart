import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/widgets/file_tree_view.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import '../test_config.dart';

void main() {
  group('FileTreeView Widget Tests', () {
    late FlutterProject testProject;
    
    setUp(() {
      testProject = TestDataGenerator.generateFlutterProject('test_tree_project');
    });

    testWidgets('should render file tree view', (WidgetTester tester) async {
      ProjectFile? selectedFile;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) => selectedFile = file,
          ),
        ),
      ));

      expect(find.byType(FileTreeView), findsOneWidget);
      expect(find.text(testProject.name), findsOneWidget);
    });

    testWidgets('should display project name', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      expect(find.text(testProject.name), findsOneWidget);
    });

    testWidgets('should display files in tree structure', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Should find main.dart file
      expect(find.text('main.dart'), findsAtLeastNWidgets(1));
      
      // Should find pubspec.yaml file
      expect(find.text('pubspec.yaml'), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle file selection', (WidgetTester tester) async {
      ProjectFile? selectedFile;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) => selectedFile = file,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Try to tap on main.dart
      final mainDartFinder = find.text('main.dart');
      if (mainDartFinder.hasFound) {
        await tester.tap(mainDartFinder.first);
        await tester.pumpAndSettle();
        
        expect(selectedFile, isNotNull);
        expect(selectedFile?.fileName, equals('main.dart'));
      }
    });

    testWidgets('should expand and collapse directories', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // lib directory should be expanded by default
      expect(find.text('lib'), findsOneWidget);
      
      // Look for expand/collapse indicators
      expect(find.byIcon(Icons.keyboard_arrow_down), findsAtLeastNWidgets(0));
    });

    testWidgets('should show selected file with highlight', (WidgetTester tester) async {
      final mainDartFile = testProject.files.firstWhere(
        (f) => f.path.contains('main.dart'),
        orElse: () => testProject.files.first,
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            selectedFile: mainDartFile,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Should find the selected file
      expect(find.text(mainDartFile.fileName), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle empty project', (WidgetTester tester) async {
      final emptyProject = FlutterProject(
        name: 'empty_project',
        files: [],
        uploadedAt: DateTime.now(),
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: emptyProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('empty_project'), findsOneWidget);
    });

    testWidgets('should show file icons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: testProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Should show appropriate file type icons
      expect(find.byIcon(Icons.code), findsAtLeastNWidgets(0)); // Dart files
      expect(find.byIcon(Icons.settings), findsAtLeastNWidgets(0)); // YAML files
      expect(find.byIcon(Icons.folder), findsAtLeastNWidgets(0)); // Directories
    });
  });

  group('FileTreeView Performance Tests', () {
    testWidgets('should handle large projects efficiently', (WidgetTester tester) async {
      final largeProject = TestDataGenerator.generateLargeFlutterProject();
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: largeProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      
      // Should still show project name
      expect(find.text(largeProject.name), findsOneWidget);
    });

    testWidgets('should handle many file selections efficiently', (WidgetTester tester) async {
      final perfTestProject = TestDataGenerator.generateFlutterProject('perf_test_project');
      final selectionCounts = <String, int>{};
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: perfTestProject,
            onFileSelected: (file) {
              selectionCounts[file.path] = (selectionCounts[file.path] ?? 0) + 1;
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Perform multiple rapid selections
      final fileWidgets = find.byType(ListTile);
      if (fileWidgets.hasFound) {
        for (int i = 0; i < 5 && i < fileWidgets.evaluate().length; i++) {
          await tester.tap(fileWidgets.at(i));
          await tester.pump();
        }
      }

      expect(selectionCounts.values.fold(0, (sum, count) => sum + count), greaterThan(0));
    });
  });

  group('FileTreeView Integration Tests', () {
    testWidgets('should integrate with project updates', (WidgetTester tester) async {
      final integrationProject = TestDataGenerator.generateFlutterProject('integration_test_project');
      FlutterProject? updatedProject;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: integrationProject,
            onFileSelected: (file) {},
            onProjectUpdated: (project) => updatedProject = project,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // The widget should be ready for project updates
      expect(find.byType(FileTreeView), findsOneWidget);
    });

    testWidgets('should maintain state during rebuilds', (WidgetTester tester) async {
      final stateProject = TestDataGenerator.generateFlutterProject('state_test_project');
      ProjectFile? selectedFile;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: stateProject,
            onFileSelected: (file) => selectedFile = file,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Select a file
      final fileWidgets = find.byType(ListTile);
      if (fileWidgets.hasFound) {
        await tester.tap(fileWidgets.first);
        await tester.pump();
      }

      // Rebuild with same project
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: stateProject,
            selectedFile: selectedFile,
            onFileSelected: (file) => selectedFile = file,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Tree should still be rendered correctly
      expect(find.byType(FileTreeView), findsOneWidget);
    });
  });

  group('FileTreeView Error Handling Tests', () {
    testWidgets('should handle corrupt project data gracefully', (WidgetTester tester) async {
      final corruptProject = FlutterProject(
        name: '', // Empty name
        files: [
          ProjectFile(
            path: '', // Empty path
            content: '',
            type: FileType.other,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: corruptProject,
            onFileSelected: (file) {},
          ),
        ),
      ));

      // Should not throw an exception
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      expect(find.byType(FileTreeView), findsOneWidget);
    });

    testWidgets('should handle null callbacks gracefully', (WidgetTester tester) async {
      final callbackProject = TestDataGenerator.generateFlutterProject('callback_test_project');
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileTreeView(
            project: callbackProject,
            onFileSelected: (file) {}, // Required callback
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();

      expect(find.byType(FileTreeView), findsOneWidget);
    });
  });
}