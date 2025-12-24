import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/services/flutter_analyzer.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import '../test_config.dart';

void main() {
  group('FlutterAnalyzer Core Functionality Tests', () {
    late FlutterAnalyzer analyzer;
    
    setUp(() {
      analyzer = FlutterAnalyzer();
    });

    test('should analyze simple Flutter project successfully', () async {
      final testProject = TestDataGenerator.generateFlutterProject('simple_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      
      expect(widgetInfos, isNotNull);
      expect(widgetInfos, isNotEmpty);
      expect(widgetInfos.first.type, equals('MaterialApp'));
    });

    test('should return proper widget structure', () async {
      final testProject = TestDataGenerator.generateFlutterProject('widget_structure_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      final materialApp = widgetInfos.first;
      
      expect(materialApp.type, equals('MaterialApp'));
      expect(materialApp.id, equals('material_app_1'));
      expect(materialApp.filePath, equals('lib/main.dart'));
      expect(materialApp.lineNumber, equals(14));
      expect(materialApp.properties, containsPair('title', 'Flutter Demo'));
      expect(materialApp.children, isNotEmpty);
    });

    test('should handle nested widget hierarchy', () async {
      final testProject = TestDataGenerator.generateFlutterProject('nested_widgets_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      final materialApp = widgetInfos.first;
      final scaffold = materialApp.children.first;
      
      expect(scaffold.type, equals('Scaffold'));
      expect(scaffold.children.length, equals(2)); // AppBar and Column
      
      final appBar = scaffold.children[0];
      final column = scaffold.children[1];
      
      expect(appBar.type, equals('AppBar'));
      expect(column.type, equals('Column'));
      expect(column.children.length, equals(2)); // Card and ListView
    });

    test('should provide correct widget properties', () async {
      final testProject = TestDataGenerator.generateFlutterProject('widget_properties_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      final materialApp = widgetInfos.first;
      final scaffold = materialApp.children.first;
      final column = scaffold.children[1];
      final listView = column.children[1];
      
      expect(listView.type, equals('ListView'));
      expect(listView.properties, containsPair('itemCount', 10));
    });

    test('should handle empty project gracefully', () async {
      final emptyProject = FlutterProject(
        name: 'empty_project',
        files: [],
        uploadedAt: DateTime.now(),
      );
      
      final widgetInfos = await analyzer.analyzeProject(emptyProject);
      
      expect(widgetInfos, isNotNull);
      expect(widgetInfos, isNotEmpty); // Analyzer returns default structure even for empty project
    });

    test('should handle project with only non-Dart files', () async {
      final nonDartProject = FlutterProject(
        name: 'non_dart_project',
        files: [
          ProjectFile(
            path: 'README.md',
            content: '# Test Project',
            type: FileType.other,
          ),
          ProjectFile(
            path: 'pubspec.yaml',
            content: 'name: test_project\nversion: 1.0.0',
            type: FileType.yaml,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      
      final widgetInfos = await analyzer.analyzeProject(nonDartProject);
      
      expect(widgetInfos, isNotNull);
      // Analyzer should still return some default structure
    });
  });

  group('FlutterAnalyzer Performance Tests', () {
    late FlutterAnalyzer analyzer;
    
    setUp(() {
      analyzer = FlutterAnalyzer();
    });

    test('should complete analysis within reasonable time', () async {
      final testProject = TestDataGenerator.generateFlutterProject('performance_test');
      final stopwatch = Stopwatch()..start();
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      
      stopwatch.stop();
      
      expect(widgetInfos, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Should complete within 3 seconds
    });

    test('should handle large project analysis', () async {
      final largeProject = TestDataGenerator.generateLargeFlutterProject();
      final stopwatch = Stopwatch()..start();
      
      final widgetInfos = await analyzer.analyzeProject(largeProject);
      
      stopwatch.stop();
      
      expect(widgetInfos, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds even for large project
    });

    test('should maintain consistent results across multiple analyses', () async {
      final testProject = TestDataGenerator.generateFlutterProject('consistency_test');
      
      final results1 = await analyzer.analyzeProject(testProject);
      final results2 = await analyzer.analyzeProject(testProject);
      final results3 = await analyzer.analyzeProject(testProject);
      
      // Results should be consistent
      expect(results1.length, equals(results2.length));
      expect(results2.length, equals(results3.length));
      
      expect(results1.first.type, equals(results2.first.type));
      expect(results2.first.type, equals(results3.first.type));
    });

    test('should handle concurrent analysis requests', () async {
      final testProject = TestDataGenerator.generateFlutterProject('concurrent_test');
      
      // Run multiple analyses concurrently
      final futures = <Future<List<WidgetInfo>>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(analyzer.analyzeProject(testProject));
      }
      
      final results = await Future.wait(futures);
      
      // All results should be valid
      for (final result in results) {
        expect(result, isNotNull);
        expect(result, isNotEmpty);
        expect(result.first.type, equals('MaterialApp'));
      }
    });
  });

  group('FlutterAnalyzer Widget Information Tests', () {
    late FlutterAnalyzer analyzer;
    
    setUp(() {
      analyzer = FlutterAnalyzer();
    });

    test('should provide accurate file path information', () async {
      final testProject = TestDataGenerator.generateFlutterProject('file_path_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      
      for (final widget in widgetInfos) {
        expect(widget.filePath, isNotEmpty);
        expect(widget.filePath, contains('.dart'));
        expect(widget.lineNumber, greaterThan(0));
      }
    });

    test('should generate unique widget IDs', () async {
      final testProject = TestDataGenerator.generateFlutterProject('unique_id_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      final allIds = <String>{};
      
      void collectIds(List<WidgetInfo> widgets) {
        for (final widget in widgets) {
          allIds.add(widget.id);
          collectIds(widget.children);
        }
      }
      
      collectIds(widgetInfos);
      
      // All IDs should be unique
      final allIdsList = widgetInfos.expand((w) => [w.id, ...w.children.map((c) => c.id)]).toList();
      expect(allIds.length, equals(allIdsList.length)); // No duplicates
    });

    test('should correctly identify widget types', () async {
      final testProject = TestDataGenerator.generateFlutterProject('widget_types_test');
      
      final widgetInfos = await analyzer.analyzeProject(testProject);
      final materialApp = widgetInfos.first;
      
      final expectedTypes = ['MaterialApp', 'Scaffold', 'AppBar', 'Column', 'Card', 'ListView'];
      final foundTypes = <String>{};
      
      void collectTypes(List<WidgetInfo> widgets) {
        for (final widget in widgets) {
          foundTypes.add(widget.type);
          collectTypes(widget.children);
        }
      }
      
      collectTypes([materialApp]);
      
      for (final expectedType in expectedTypes) {
        expect(foundTypes, contains(expectedType));
      }
    });
  });

  group('FlutterAnalyzer Error Handling Tests', () {
    late FlutterAnalyzer analyzer;
    
    setUp(() {
      analyzer = FlutterAnalyzer();
    });

    test('should handle malformed Dart files gracefully', () async {
      final projectWithErrors = FlutterProject(
        name: 'error_project',
        files: [
          ProjectFile(
            path: 'lib/main.dart',
            content: 'class BrokenClass { // Missing closing brace',
            type: FileType.dart,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      
      final widgetInfos = await analyzer.analyzeProject(projectWithErrors);
      
      expect(widgetInfos, isNotNull);
      // Analyzer should return default structure even with malformed Dart
    });

    test('should handle projects with missing main.dart', () async {
      final projectWithoutMain = FlutterProject(
        name: 'no_main_project',
        files: [
          ProjectFile(
            path: 'lib/helper.dart',
            content: 'class Helper {}',
            type: FileType.dart,
          ),
        ],
        uploadedAt: DateTime.now(),
      );
      
      final widgetInfos = await analyzer.analyzeProject(projectWithoutMain);
      
      expect(widgetInfos, isNotNull);
      // Should handle gracefully even without main.dart
    });
  });
}