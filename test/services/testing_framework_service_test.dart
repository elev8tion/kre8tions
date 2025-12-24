import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/services/testing_framework_service.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

void main() {
  group('TestingFrameworkService Tests', () {
    late TestingFrameworkService service;
    late FlutterProject testProject;

    setUp(() {
      service = TestingFrameworkService();
      
      final testFiles = [
        ProjectFile(
          path: 'test/widget_test.dart',
          content: '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Counter App Tests', () {
    testWidgets('Counter increments smoke test', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp());

      // Verify that our counter starts at 0.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap the '+' icon and trigger a frame.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify that our counter has incremented.
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
''',
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'test/unit_test.dart',
          content: '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Math Operations', () {
    test('addition', () {
      expect(2 + 2, equals(4));
    });
    
    test('subtraction', () {
      expect(5 - 3, equals(2));
    });
  });
}
''',
          type: FileType.dart,
        ),
      ];

      testProject = FlutterProject(
        name: 'Test Project',
        files: testFiles,
        uploadedAt: DateTime.now(),
      );
    });

    test('should create TestingFrameworkService instance', () {
      expect(service, isNotNull);
      expect(service, isA<TestingFrameworkService>());
    });

    test('should discover tests in project', () async {
      final testSuites = await service.discoverTests(testProject);
      
      expect(testSuites.isNotEmpty, isTrue);
      expect(testSuites.length, equals(2)); // widget_test.dart and unit_test.dart
      
      final widgetTestSuite = testSuites.firstWhere((suite) => suite.name == 'widget_test');
      expect(widgetTestSuite.testCases.isNotEmpty, isTrue);
    });

    test('should run all tests', () async {
      final testResult = await service.runAllTests(testProject);
      
      expect(testResult, isNotNull);
      expect(testResult.testSuites.isNotEmpty, isTrue);
      expect(testResult.totalTests, greaterThan(0));
      expect(testResult.overallStatus, isA<TestStatus>());
    });

    test('should generate mock data', () {
      final userData = service.generateMockData('user');
      expect(userData, isA<Map<String, dynamic>>());
      expect(userData.containsKey('id'), isTrue);
      expect(userData.containsKey('name'), isTrue);
      expect(userData.containsKey('email'), isTrue);
      
      final productData = service.generateMockData('product');
      expect(productData, isA<Map<String, dynamic>>());
      expect(productData.containsKey('id'), isTrue);
      expect(productData.containsKey('name'), isTrue);
      expect(productData.containsKey('price'), isTrue);
    });

    test('should generate test files', () async {
      final testContent = await service.generateTestFile('lib/models/user.dart', 'User');
      
      expect(testContent, isNotNull);
      expect(testContent, contains('User Tests'));
      expect(testContent, contains('import'));
      expect(testContent, contains('test('));
    });

    test('should track test history', () async {
      expect(service.testHistory.isEmpty, isTrue);
      
      await service.runAllTests(testProject);
      
      expect(service.testHistory.isNotEmpty, isTrue);
      expect(service.testHistory.length, equals(1));
      
      final latestResult = service.getLatestTestResult();
      expect(latestResult, isNotNull);
    });

    test('should handle test progress stream', () async {
      bool receivedProgress = false;
      
      service.testProgressStream.listen((testCase) {
        receivedProgress = true;
        expect(testCase, isA<TestCase>());
      });
      
      await service.runAllTests(testProject);
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(receivedProgress, isTrue);
    });

    test('should clear test history', () async {
      await service.runAllTests(testProject);
      expect(service.testHistory.isNotEmpty, isTrue);
      
      await service.clearTestHistory();
      expect(service.testHistory.isEmpty, isTrue);
    });

    test('should get failed tests', () async {
      await service.runAllTests(testProject);
      
      final failedTests = service.getFailedTests();
      expect(failedTests, isA<List<TestCase>>());
    });

    test('should get tests by type', () async {
      await service.runAllTests(testProject);
      
      final unitTests = service.getTestsByType(TestType.unit);
      final widgetTests = service.getTestsByType(TestType.widget);
      
      expect(unitTests, isA<List<TestCase>>());
      expect(widgetTests, isA<List<TestCase>>());
    });

    test('should handle testing state', () {
      expect(service.isTestingInProgress, isFalse);
      
      // During test execution, isTestingInProgress should be true
      // This is tested implicitly during runAllTests
    });

    test('should validate test case properties', () {
      final testCase = TestCase(
        id: 'test-1',
        name: 'Sample Test',
        description: 'A sample test case',
        type: TestType.unit,
        category: TestCategory.model,
        filePath: 'test/sample_test.dart',
        lineNumber: 10,
      );
      
      expect(testCase.id, equals('test-1'));
      expect(testCase.name, equals('Sample Test'));
      expect(testCase.type, equals(TestType.unit));
      expect(testCase.status, equals(TestStatus.pending));
      expect(testCase.isPassed, isFalse);
      expect(testCase.isFailed, isFalse);
      expect(testCase.isSkipped, isFalse);
    });

    test('should validate test suite properties', () {
      final testCases = [
        TestCase(
          id: 'test-1',
          name: 'Test 1',
          description: 'First test',
          type: TestType.unit,
          category: TestCategory.model,
          filePath: 'test/sample_test.dart',
          lineNumber: 10,
          status: TestStatus.passed,
        ),
        TestCase(
          id: 'test-2',
          name: 'Test 2',
          description: 'Second test',
          type: TestType.unit,
          category: TestCategory.model,
          filePath: 'test/sample_test.dart',
          lineNumber: 20,
          status: TestStatus.failed,
        ),
      ];
      
      final testSuite = TestSuite(
        id: 'suite-1',
        name: 'Sample Suite',
        filePath: 'test/sample_test.dart',
        testCases: testCases,
      );
      
      expect(testSuite.totalTests, equals(2));
      expect(testSuite.passedTests, equals(1));
      expect(testSuite.failedTests, equals(1));
      expect(testSuite.skippedTests, equals(0));
      expect(testSuite.successRate, equals(50.0));
    });

    tearDown(() {
      service.dispose();
    });
  });
}