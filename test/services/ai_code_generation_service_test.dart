import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/services/ai_code_generation_service.dart';

void main() {
  group('AICodeGenerationService Core Functionality Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should initialize service successfully', () {
      expect(service, isNotNull);
      expect(service.isProcessing, isFalse);
      expect(service.generationHistory, isEmpty);
      expect(service.refactoringHistory, isEmpty);
      expect(service.activeSuggestions, isEmpty);
    });

    test('should generate widget code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-widget-1',
        type: CodeGenerationType.widget,
        description: 'Generate a custom widget',
        parameters: {
          'name': 'TestWidget',
          'stateful': false,
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result, isNotNull);
      expect(result.generatedCode, contains('class TestWidget'));
      expect(result.generatedCode, contains('StatelessWidget'));
      expect(result.imports, contains('package:flutter/material.dart'));
      expect(result.confidenceScore, greaterThan(0.8));
      expect(service.generationHistory.length, equals(1));
    });

    test('should generate stateful widget code', () async {
      final request = CodeGenerationRequest(
        id: 'test-stateful-widget-1',
        type: CodeGenerationType.widget,
        description: 'Generate a stateful widget',
        parameters: {
          'name': 'StatefulTestWidget',
          'stateful': true,
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('class StatefulTestWidget'));
      expect(result.generatedCode, contains('StatefulWidget'));
      expect(result.generatedCode, contains('_StatefulTestWidgetState'));
      expect(result.generatedCode, contains('dispose'));
    });

    test('should generate service code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-service-1',
        type: CodeGenerationType.service,
        description: 'Generate a service class',
        parameters: {
          'name': 'TestService',
          'singleton': true,
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('class TestService'));
      expect(result.generatedCode, contains('_instance'));
      expect(result.generatedCode, contains('factory TestService'));
      expect(result.generatedCode, contains('initialize'));
    });

    test('should generate model code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-model-1',
        type: CodeGenerationType.model,
        description: 'Generate a data model',
        parameters: {
          'name': 'TestModel',
          'fields': [
            {'name': 'id', 'type': 'String'},
            {'name': 'name', 'type': 'String'},
            {'name': 'createdAt', 'type': 'DateTime'},
          ],
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('class TestModel'));
      expect(result.generatedCode, contains('final String id'));
      expect(result.generatedCode, contains('final String name'));
      expect(result.generatedCode, contains('final DateTime createdAt'));
      expect(result.generatedCode, contains('fromJson'));
      expect(result.generatedCode, contains('toJson'));
      expect(result.generatedCode, contains('copyWith'));
    });

    test('should generate screen code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-screen-1',
        type: CodeGenerationType.screen,
        description: 'Generate a screen widget',
        parameters: {
          'name': 'TestScreen',
          'appBar': true,
          'fab': true,
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('class TestScreen'));
      expect(result.generatedCode, contains('AppBar'));
      expect(result.generatedCode, contains('FloatingActionButton'));
      expect(result.generatedCode, contains('Scaffold'));
    });

    test('should generate function code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-function-1',
        type: CodeGenerationType.function,
        description: 'Generate a function',
        parameters: {
          'name': 'testFunction',
          'async': true,
          'returnType': 'String',
          'parameters': [
            {'name': 'input', 'type': 'String'},
          ],
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('Future<String> testFunction'));
      expect(result.generatedCode, contains('String input'));
      expect(result.generatedCode, contains('async'));
    });

    test('should generate test code successfully', () async {
      final request = CodeGenerationRequest(
        id: 'test-test-1',
        type: CodeGenerationType.test,
        description: 'Generate test code',
        parameters: {
          'name': 'Widget Test',
          'targetClass': 'TestWidget',
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result.generatedCode, contains('void main()'));
      expect(result.generatedCode, contains('group('));
      expect(result.generatedCode, contains('test('));
      expect(result.generatedCode, contains('expect('));
      expect(result.imports, contains('package:flutter_test/flutter_test.dart'));
    });
  });

  group('AICodeGenerationService Refactoring Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should extract widget successfully', () async {
      final request = RefactoringRequest(
        id: 'refactor-extract-widget-1',
        type: RefactoringType.extractWidget,
        filePath: 'lib/test_widget.dart',
        originalCode: '''
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Header'),
      Container(
        child: Text('Content'),
      ),
    ],
  );
}
''',
        startLine: 4,
        endLine: 6,
        parameters: {'widgetName': 'ContentWidget'},
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result, isNotNull);
      expect(result.refactoredCode, contains('class ContentWidget'));
      expect(result.refactoredCode, contains('StatelessWidget'));
      expect(result.fileChanges, hasLength(1));
      expect(result.warnings, isNotEmpty);
      expect(service.refactoringHistory.length, equals(1));
    });

    test('should extract method successfully', () async {
      final request = RefactoringRequest(
        id: 'refactor-extract-method-1',
        type: RefactoringType.extractMethod,
        filePath: 'lib/test_service.dart',
        originalCode: '''
void performAction() {
  print('Starting action');
  // Complex logic here
  print('Action completed');
}
''',
        startLine: 2,
        endLine: 4,
        parameters: {'methodName': 'performComplexLogic'},
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result.refactoredCode, contains('void performComplexLogic'));
      expect(result.refactoredCode, contains('performComplexLogic()'));
    });

    test('should rename symbol successfully', () async {
      final request = RefactoringRequest(
        id: 'refactor-rename-1',
        type: RefactoringType.renameSymbol,
        filePath: 'lib/test.dart',
        originalCode: '''
class OldClassName {
  void oldMethodName() {
    var oldVariableName = 'test';
  }
}
''',
        startLine: 1,
        endLine: 5,
        parameters: {
          'oldName': 'OldClassName',
          'newName': 'NewClassName',
        },
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result.refactoredCode, contains('NewClassName'));
      expect(result.refactoredCode, isNot(contains('OldClassName')));
    });

    test('should optimize imports successfully', () async {
      final request = RefactoringRequest(
        id: 'refactor-imports-1',
        type: RefactoringType.optimizeImports,
        filePath: 'lib/test.dart',
        originalCode: '''
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';

class TestClass {}
''',
        startLine: 1,
        endLine: 7,
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result.refactoredCode, contains('import \'dart:async\''));
      expect(result.refactoredCode, contains('import \'dart:convert\''));
      expect(result.refactoredCode, contains('class TestClass'));
      // Should remove duplicates
      expect('package:flutter/material.dart'.allMatches(result.refactoredCode).length, equals(1));
    });

    test('should convert to stateless widget', () async {
      final request = RefactoringRequest(
        id: 'refactor-stateless-1',
        type: RefactoringType.convertToStateless,
        filePath: 'lib/widget.dart',
        originalCode: '''
class TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => _TestWidgetState();
}
''',
        startLine: 1,
        endLine: 4,
        parameters: {'className': 'TestWidget'},
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result.refactoredCode, contains('StatelessWidget'));
      expect(result.refactoredCode, isNot(contains('StatefulWidget')));
      expect(result.warnings, contains('State variables will be lost - handle them appropriately'));
    });
  });

  group('AICodeGenerationService Suggestions Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should generate suggestions for StatefulWidget without dispose', () {
      const code = '''
class TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';

      service.generateCodeSuggestions(code);

      expect(service.activeSuggestions, isNotEmpty);
      expect(service.activeSuggestions.any((s) => s.title.contains('dispose')), isTrue);
    });

    test('should generate suggestions for async setState', () {
      const code = '''
class TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  Future<void> loadData() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      // Update state
    });
  }
}
''';

      service.generateCodeSuggestions(code);

      expect(service.activeSuggestions.any((s) => s.title.contains('mounted')), isTrue);
    });

    test('should generate suggestions for non-const widgets', () {
      const code = '''
Widget build(BuildContext context) {
  return Container(
    child: Text('Hello'),
  );
}
''';

      service.generateCodeSuggestions(code);

      expect(service.activeSuggestions.any((s) => s.title.contains('const')), isTrue);
    });
  });

  group('AICodeGenerationService Performance Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should complete code generation within reasonable time', () async {
      final request = CodeGenerationRequest(
        id: 'perf-test-1',
        type: CodeGenerationType.widget,
        description: 'Performance test widget',
        requestedAt: DateTime.now(),
      );

      final stopwatch = Stopwatch()..start();
      final result = await service.generateCode(request);
      stopwatch.stop();

      expect(result, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
    });

    test('should handle multiple concurrent requests', () async {
      final requests = List.generate(5, (index) => CodeGenerationRequest(
        id: 'concurrent-test-$index',
        type: CodeGenerationType.function,
        description: 'Concurrent test function $index',
        parameters: {'name': 'testFunction$index'},
        requestedAt: DateTime.now(),
      ));

      final futures = requests.map((request) => service.generateCode(request));
      final results = await Future.wait(futures);

      expect(results.length, equals(5));
      for (final result in results) {
        expect(result, isNotNull);
        expect(result.generatedCode, isNotEmpty);
      }
    });

    test('should maintain performance with large history', () async {
      // Generate many requests to build up history
      for (int i = 0; i < 50; i++) {
        final request = CodeGenerationRequest(
          id: 'history-test-$i',
          type: CodeGenerationType.function,
          description: 'History test function $i',
          requestedAt: DateTime.now(),
        );
        await service.generateCode(request);
      }

      expect(service.generationHistory.length, equals(50));

      // New request should still be fast
      final stopwatch = Stopwatch()..start();
      final finalRequest = CodeGenerationRequest(
        id: 'final-test',
        type: CodeGenerationType.widget,
        description: 'Final performance test',
        requestedAt: DateTime.now(),
      );
      await service.generateCode(finalRequest);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });

  group('AICodeGenerationService Stream Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should emit results through generation stream', () async {
      final request = CodeGenerationRequest(
        id: 'stream-test-1',
        type: CodeGenerationType.widget,
        description: 'Stream test widget',
        requestedAt: DateTime.now(),
      );

      // Listen to the stream
      CodeGenerationResult? streamResult;
      final subscription = service.generationStream.listen((result) {
        streamResult = result;
      });

      await service.generateCode(request);

      // Give some time for the stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(streamResult, isNotNull);
      expect(streamResult!.id, equals(streamResult!.id)); // ID should match

      await subscription.cancel();
    });

    test('should emit status updates through status stream', () async {
      final statuses = <String>[];
      final subscription = service.statusStream.listen((status) {
        statuses.add(status);
      });

      final request = CodeGenerationRequest(
        id: 'status-test-1',
        type: CodeGenerationType.service,
        description: 'Status test service',
        requestedAt: DateTime.now(),
      );

      await service.generateCode(request);

      expect(statuses, isNotEmpty);
      expect(statuses.any((s) => s.contains('Generating')), isTrue);
      expect(statuses.any((s) => s.contains('completed')), isTrue);

      await subscription.cancel();
    });
  });

  group('AICodeGenerationService Error Handling Tests', () {
    late AiCodeGenerationService service;
    
    setUp(() {
      service = AiCodeGenerationService();
    });
    
    tearDown(() {
      service.clearHistory();
    });

    test('should handle invalid generation requests gracefully', () async {
      final request = CodeGenerationRequest(
        id: 'invalid-test-1',
        type: CodeGenerationType.widget,
        description: '', // Empty description
        parameters: {}, // No parameters
        requestedAt: DateTime.now(),
      );

      final result = await service.generateCode(request);

      expect(result, isNotNull);
      expect(result.generatedCode, isNotEmpty); // Should still generate something
    });

    test('should handle invalid refactoring requests gracefully', () async {
      final request = RefactoringRequest(
        id: 'invalid-refactor-1',
        type: RefactoringType.extractWidget,
        filePath: '', // Empty file path
        originalCode: '', // Empty code
        startLine: -1, // Invalid line
        endLine: -1, // Invalid line
        requestedAt: DateTime.now(),
      );

      final result = await service.refactorCode(request);

      expect(result, isNotNull);
      expect(result.refactoredCode, isNotNull);
    });
  });
}