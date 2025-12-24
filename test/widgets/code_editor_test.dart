import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/widgets/code_editor.dart';
import 'package:kre8tions/models/project_file.dart';

void main() {
  group('CodeEditor Widget Tests', () {
    testWidgets('should render CodeEditor widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'lib/main.dart',
                content: 'void main() {}',
                type: FileType.dart,
              ),
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.byType(CodeEditor), findsOneWidget);
    });

    testWidgets('should display file content', (WidgetTester tester) async {
      const testContent = 'void main() {\n  print("Hello World");\n}';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'lib/main.dart',
                content: testContent,
                type: FileType.dart,
              ),
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.text(testContent), findsOneWidget);
    });

    testWidgets('should handle empty file', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: null,
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      // Should show empty state
      expect(find.text('No file selected'), findsOneWidget);
    });

    testWidgets('should handle non-text files', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'assets/image.png',
                content: 'binary content',
                type: FileType.image,
              ),
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      // Should show non-text file message
      expect(find.text('This file type cannot be edited'), findsOneWidget);
    });

    testWidgets('should show file path in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'lib/models/user.dart',
                content: 'class User {}',
                type: FileType.dart,
              ),
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.text('lib/models/user.dart'), findsOneWidget);
    });

    testWidgets('should handle content changes', (WidgetTester tester) async {
      String changedPath = '';
      String changedContent = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'lib/main.dart',
                content: 'initial content',
                type: FileType.dart,
              ),
              onContentChanged: (path, content) {
                changedPath = path;
                changedContent = content;
              },
            ),
          ),
        ),
      );

      // Simulate text input
      await tester.enterText(find.byType(TextField), 'new content');
      await tester.pump();

      expect(changedPath, equals('lib/main.dart'));
      expect(changedContent, equals('new content'));
    });

    testWidgets('should display line numbers', (WidgetTester tester) async {
      const multiLineContent = '''void main() {
  print("Line 2");
  print("Line 3");
}''';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: ProjectFile(
                path: 'lib/main.dart',
                content: multiLineContent,
                type: FileType.dart,
              ),
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      // Check for line numbers
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should update when file changes', (WidgetTester tester) async {
      final file1 = ProjectFile(
        path: 'lib/file1.dart',
        content: 'file 1 content',
        type: FileType.dart,
      );
      
      final file2 = ProjectFile(
        path: 'lib/file2.dart',
        content: 'file 2 content',
        type: FileType.dart,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: file1,
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.text('file 1 content'), findsOneWidget);

      // Update to file2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: file2,
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.text('file 2 content'), findsOneWidget);
      expect(find.text('file 1 content'), findsNothing);
    });

    testWidgets('should handle different file types', (WidgetTester tester) async {
      final yamlFile = ProjectFile(
        path: 'pubspec.yaml',
        content: 'name: test_project\nversion: 1.0.0',
        type: FileType.yaml,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeEditor(
              file: yamlFile,
              onContentChanged: (path, content) {},
            ),
          ),
        ),
      );

      expect(find.text('pubspec.yaml'), findsOneWidget);
      expect(find.text('name: test_project\nversion: 1.0.0'), findsOneWidget);
    });
  });
}