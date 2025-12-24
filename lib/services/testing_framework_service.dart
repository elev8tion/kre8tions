import 'dart:async';
import 'dart:math';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

enum TestType { unit, widget, integration, golden, performance }
enum TestStatus { pending, running, passed, failed, skipped }
enum TestCategory { model, service, widget, screen, api, util }

class TestCase {
  final String id;
  final String name;
  final String description;
  final TestType type;
  final TestCategory category;
  final String filePath;
  final int lineNumber;
  final TestStatus status;
  final Duration? duration;
  final String? errorMessage;
  final String? stackTrace;
  final DateTime? executedAt;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const TestCase({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.filePath,
    required this.lineNumber,
    this.status = TestStatus.pending,
    this.duration,
    this.errorMessage,
    this.stackTrace,
    this.executedAt,
    this.tags = const [],
    this.metadata = const {},
  });

  TestCase copyWith({
    String? id,
    String? name,
    String? description,
    TestType? type,
    TestCategory? category,
    String? filePath,
    int? lineNumber,
    TestStatus? status,
    Duration? duration,
    String? errorMessage,
    String? stackTrace,
    DateTime? executedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return TestCase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      executedAt: executedAt ?? this.executedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  String get typeIcon {
    switch (type) {
      case TestType.unit:
        return '🧪';
      case TestType.widget:
        return '🎯';
      case TestType.integration:
        return '🔗';
      case TestType.golden:
        return '🏆';
      case TestType.performance:
        return '⚡';
    }
  }

  String get statusIcon {
    switch (status) {
      case TestStatus.pending:
        return '⏳';
      case TestStatus.running:
        return '🏃';
      case TestStatus.passed:
        return '✅';
      case TestStatus.failed:
        return '❌';
      case TestStatus.skipped:
        return '⏭️';
    }
  }

  bool get isPassed => status == TestStatus.passed;
  bool get isFailed => status == TestStatus.failed;
  bool get isSkipped => status == TestStatus.skipped;
}

class TestSuite {
  final String id;
  final String name;
  final String filePath;
  final List<TestCase> testCases;
  final TestStatus status;
  final Duration? totalDuration;
  final DateTime? executedAt;

  const TestSuite({
    required this.id,
    required this.name,
    required this.filePath,
    required this.testCases,
    this.status = TestStatus.pending,
    this.totalDuration,
    this.executedAt,
  });

  int get totalTests => testCases.length;
  int get passedTests => testCases.where((test) => test.isPassed).length;
  int get failedTests => testCases.where((test) => test.isFailed).length;
  int get skippedTests => testCases.where((test) => test.isSkipped).length;

  double get successRate => totalTests > 0 ? (passedTests / totalTests) * 100 : 0;
}

class TestCoverageReport {
  final String filePath;
  final int totalLines;
  final int coveredLines;
  final int uncoveredLines;
  final double coveragePercentage;
  final List<int> coveredLineNumbers;
  final List<int> uncoveredLineNumbers;

  const TestCoverageReport({
    required this.filePath,
    required this.totalLines,
    required this.coveredLines,
    required this.uncoveredLines,
    required this.coveragePercentage,
    required this.coveredLineNumbers,
    required this.uncoveredLineNumbers,
  });
}

class TestResult {
  final String id;
  final List<TestSuite> testSuites;
  final TestStatus overallStatus;
  final Duration totalDuration;
  final DateTime executedAt;
  final Map<TestType, int> testCountByType;
  final List<TestCoverageReport> coverageReports;

  const TestResult({
    required this.id,
    required this.testSuites,
    required this.overallStatus,
    required this.totalDuration,
    required this.executedAt,
    required this.testCountByType,
    required this.coverageReports,
  });

  int get totalTests => testSuites.fold(0, (sum, suite) => sum + suite.totalTests);
  int get passedTests => testSuites.fold(0, (sum, suite) => sum + suite.passedTests);
  int get failedTests => testSuites.fold(0, (sum, suite) => sum + suite.failedTests);
  int get skippedTests => testSuites.fold(0, (sum, suite) => sum + suite.skippedTests);

  double get overallSuccessRate => totalTests > 0 ? (passedTests / totalTests) * 100 : 0;
  double get overallCoverage => coverageReports.isNotEmpty
      ? coverageReports.fold(0.0, (sum, report) => sum + report.coveragePercentage) / coverageReports.length
      : 0.0;
}

class TestingFrameworkService {
  static final TestingFrameworkService _instance = TestingFrameworkService._internal();
  factory TestingFrameworkService() => _instance;
  TestingFrameworkService._internal();

  final StreamController<TestResult> _testResultController = StreamController<TestResult>.broadcast();
  final StreamController<TestCase> _testProgressController = StreamController<TestCase>.broadcast();
  final StreamController<String> _testLogController = StreamController<String>.broadcast();

  Stream<TestResult> get testResultStream => _testResultController.stream;
  Stream<TestCase> get testProgressStream => _testProgressController.stream;
  Stream<String> get testLogStream => _testLogController.stream;

  final List<TestResult> _testHistory = [];
  bool _isTestingInProgress = false;

  bool get isTestingInProgress => _isTestingInProgress;
  List<TestResult> get testHistory => List.unmodifiable(_testHistory);

  // Test Discovery
  Future<List<TestSuite>> discoverTests(FlutterProject project) async {
    _log('Discovering tests in project: ${project.name}');
    
    final testSuites = <TestSuite>[];
    final testFiles = project.files.where((file) => 
      file.path.contains('test/') && file.path.endsWith('_test.dart')).toList();

    for (final testFile in testFiles) {
      final testCases = await _parseTestFile(testFile);
      if (testCases.isNotEmpty) {
        testSuites.add(TestSuite(
          id: testFile.path,
          name: testFile.fileName.replaceAll('_test.dart', ''),
          filePath: testFile.path,
          testCases: testCases,
        ));
      }
    }

    _log('Discovered ${testSuites.length} test suites with ${testSuites.fold(0, (sum, suite) => sum + suite.totalTests)} tests');
    return testSuites;
  }

  Future<List<TestCase>> _parseTestFile(ProjectFile testFile) async {
    final testCases = <TestCase>[];
    final lines = testFile.content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('test(') || line.startsWith('testWidgets(') || 
          line.startsWith('group(')) {
        
        final testName = _extractTestName(line);
        if (testName != null) {
          final testType = _determineTestType(testFile.path, line);
          final category = _determineTestCategory(testFile.path, testName);
          
          testCases.add(TestCase(
            id: '${testFile.path}:${i + 1}',
            name: testName,
            description: testName,
            type: testType,
            category: category,
            filePath: testFile.path,
            lineNumber: i + 1,
          ));
        }
      }
    }

    return testCases;
  }

  String? _extractTestName(String line) {
    if (line.contains('test(') || line.contains('testWidgets(') || line.contains('group(')) {
      final start = line.contains('\'') ? line.indexOf('\'') : line.indexOf('"');
      if (start != -1) {
        final quote = line[start];
        final end = line.indexOf(quote, start + 1);
        if (end != -1) {
          return line.substring(start + 1, end);
        }
      }
    }
    return null;
  }

  TestType _determineTestType(String filePath, String line) {
    if (line.contains('testWidgets')) return TestType.widget;
    if (filePath.contains('integration_test')) return TestType.integration;
    if (filePath.contains('golden')) return TestType.golden;
    if (filePath.contains('performance')) return TestType.performance;
    return TestType.unit;
  }

  TestCategory _determineTestCategory(String filePath, String testName) {
    if (filePath.contains('model') || testName.toLowerCase().contains('model')) {
      return TestCategory.model;
    }
    if (filePath.contains('service') || testName.toLowerCase().contains('service')) {
      return TestCategory.service;
    }
    if (filePath.contains('widget') || testName.toLowerCase().contains('widget')) {
      return TestCategory.widget;
    }
    if (filePath.contains('screen') || testName.toLowerCase().contains('screen')) {
      return TestCategory.screen;
    }
    if (filePath.contains('api') || testName.toLowerCase().contains('api')) {
      return TestCategory.api;
    }
    return TestCategory.util;
  }

  // Test Execution
  Future<TestResult> runAllTests(FlutterProject project) async {
    final testSuites = await discoverTests(project);
    return runTestSuites(testSuites);
  }

  Future<TestResult> runTestSuites(List<TestSuite> testSuites) async {
    _isTestingInProgress = true;
    _log('Starting test execution for ${testSuites.length} test suites');

    final startTime = DateTime.now();
    final executedSuites = <TestSuite>[];
    final testCountByType = <TestType, int>{};

    for (final suite in testSuites) {
      final executedSuite = await _runTestSuite(suite);
      executedSuites.add(executedSuite);

      // Count tests by type
      for (final testCase in executedSuite.testCases) {
        testCountByType[testCase.type] = (testCountByType[testCase.type] ?? 0) + 1;
      }
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);

    // Generate coverage reports
    final coverageReports = await _generateCoverageReports(executedSuites);

    // Determine overall status
    final hasFailures = executedSuites.any((suite) => suite.failedTests > 0);
    final overallStatus = hasFailures ? TestStatus.failed : TestStatus.passed;

    final testResult = TestResult(
      id: startTime.millisecondsSinceEpoch.toString(),
      testSuites: executedSuites,
      overallStatus: overallStatus,
      totalDuration: totalDuration,
      executedAt: startTime,
      testCountByType: testCountByType,
      coverageReports: coverageReports,
    );

    _testHistory.add(testResult);
    if (_testHistory.length > 10) {
      _testHistory.removeAt(0);
    }

    _testResultController.add(testResult);
    _isTestingInProgress = false;

    _log('Test execution completed in ${totalDuration.inMilliseconds}ms');
    _log('Results: ${testResult.passedTests} passed, ${testResult.failedTests} failed, ${testResult.skippedTests} skipped');

    return testResult;
  }

  Future<TestSuite> _runTestSuite(TestSuite suite) async {
    _log('Running test suite: ${suite.name}');
    
    final startTime = DateTime.now();
    final executedTests = <TestCase>[];

    for (final testCase in suite.testCases) {
      final executedTest = await _runTestCase(testCase);
      executedTests.add(executedTest);
      _testProgressController.add(executedTest);
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);

    final failedTests = executedTests.where((test) => test.isFailed).length;
    final suiteStatus = failedTests > 0 ? TestStatus.failed : TestStatus.passed;

    return TestSuite(
      id: suite.id,
      name: suite.name,
      filePath: suite.filePath,
      testCases: executedTests,
      status: suiteStatus,
      totalDuration: totalDuration,
      executedAt: startTime,
    );
  }

  Future<TestCase> _runTestCase(TestCase testCase) async {
    _log('  Running test: ${testCase.name}');
    
    final startTime = DateTime.now();
    
    // Update status to running
    var runningTest = testCase.copyWith(
      status: TestStatus.running,
      executedAt: startTime,
    );
    _testProgressController.add(runningTest);

    // Simulate test execution
    final random = Random();
    final executionTime = Duration(milliseconds: 50 + random.nextInt(200)); // 50-250ms
    await Future.delayed(executionTime);

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // Simulate test results (90% success rate)
    final isSuccess = random.nextDouble() > 0.1;
    final shouldSkip = random.nextDouble() > 0.95; // 5% skip rate

    TestStatus finalStatus;
    String? errorMessage;
    String? stackTrace;

    if (shouldSkip) {
      finalStatus = TestStatus.skipped;
      _log('  ⏭️  Test skipped: ${testCase.name}');
    } else if (isSuccess) {
      finalStatus = TestStatus.passed;
      _log('  ✅ Test passed: ${testCase.name} (${duration.inMilliseconds}ms)');
    } else {
      finalStatus = TestStatus.failed;
      errorMessage = _generateMockErrorMessage(testCase);
      stackTrace = _generateMockStackTrace(testCase);
      _log('  ❌ Test failed: ${testCase.name} - $errorMessage');
    }

    return testCase.copyWith(
      status: finalStatus,
      duration: duration,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      executedAt: startTime,
    );
  }

  String _generateMockErrorMessage(TestCase testCase) {
    final errors = [
      'Expected: true, Actual: false',
      'AssertionError: Widget not found',
      'TimeoutException: Test timed out after 30s',
      'StateError: Object has been disposed',
      'ArgumentError: Invalid argument provided',
    ];
    return errors[Random().nextInt(errors.length)];
  }

  String _generateMockStackTrace(TestCase testCase) {
    return '''
#0      TestCase._runTestCase (${testCase.filePath}:${testCase.lineNumber}:12)
#1      TestSuite._runTestSuite (test_framework_service.dart:245:21)
#2      TestingFrameworkService.runTestSuites (test_framework_service.dart:198:18)
<asynchronous suspension>
#3      main.<anonymous closure> (test/main_test.dart:15:5)
<asynchronous suspension>
''';
  }

  // Test Generation
  Future<String> generateTestFile(String filePath, String className) async {
    _log('Generating test file for: $className');
    
    final testType = _determineTestTypeFromPath(filePath);
    final template = _getTestTemplate(testType, className, filePath);
    
    return template;
  }

  TestType _determineTestTypeFromPath(String filePath) {
    if (filePath.contains('widgets') || filePath.contains('screens')) {
      return TestType.widget;
    }
    if (filePath.contains('services')) {
      return TestType.unit;
    }
    if (filePath.contains('integration')) {
      return TestType.integration;
    }
    return TestType.unit;
  }

  String _getTestTemplate(TestType type, String className, String filePath) {
    final importPath = filePath.replaceAll('lib/', 'package:${_extractPackageName(filePath)}/');
    
    switch (type) {
      case TestType.unit:
        return '''
import 'package:flutter_test/flutter_test.dart';
import '$importPath';

void main() {
  group('$className Tests', () {
    late $className ${className.toLowerCase()};

    setUp(() {
      ${className.toLowerCase()} = $className();
    });

    test('should create instance', () {
      expect(${className.toLowerCase()}, isNotNull);
      expect(${className.toLowerCase()}, isA<$className>());
    });

    test('should perform basic operations', () {
      // TODO: Add your test logic here
      expect(true, isTrue);
    });

    tearDown(() {
      // TODO: Add cleanup logic here
    });
  });
}
''';

      case TestType.widget:
        return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '$importPath';

void main() {
  group('$className Widget Tests', () {
    testWidgets('should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: $className(),
        ),
      );

      expect(find.byType($className), findsOneWidget);
    });

    testWidgets('should handle user interactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: $className(),
        ),
      );

      // TODO: Add interaction tests here
      // await tester.tap(find.byType(ElevatedButton));
      // await tester.pump();
      
      // expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
''';

      case TestType.integration:
        return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '$importPath' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('$className Integration Tests', () {
    testWidgets('end-to-end flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Add your integration test logic here
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
''';

      default:
        return _getTestTemplate(TestType.unit, className, filePath);
    }
  }

  String _extractPackageName(String filePath) {
    // Simple extraction - in a real implementation, you'd parse pubspec.yaml
    return 'my_app';
  }

  // Coverage Analysis
  Future<List<TestCoverageReport>> _generateCoverageReports(List<TestSuite> testSuites) async {
    _log('Generating coverage reports...');
    
    final reports = <TestCoverageReport>[];
    final random = Random();

    // Mock coverage data for demonstration
    final coverageFiles = [
      'lib/models/user.dart',
      'lib/services/auth_service.dart',
      'lib/widgets/custom_button.dart',
      'lib/screens/home_screen.dart',
      'lib/main.dart',
    ];

    for (final filePath in coverageFiles) {
      final totalLines = 50 + random.nextInt(100); // 50-150 lines
      final coveragePercent = 60 + random.nextDouble() * 35; // 60-95%
      final coveredLines = (totalLines * (coveragePercent / 100)).round();
      final uncoveredLines = totalLines - coveredLines;

      final coveredLineNumbers = List.generate(coveredLines, (index) => index + 1);
      final uncoveredLineNumbers = List.generate(
        uncoveredLines, 
        (index) => coveredLines + index + 1,
      );

      reports.add(TestCoverageReport(
        filePath: filePath,
        totalLines: totalLines,
        coveredLines: coveredLines,
        uncoveredLines: uncoveredLines,
        coveragePercentage: coveragePercent,
        coveredLineNumbers: coveredLineNumbers,
        uncoveredLineNumbers: uncoveredLineNumbers,
      ));
    }

    return reports;
  }

  // Test Data Generation
  Map<String, dynamic> generateMockData(String dataType) {
    final random = Random();
    
    switch (dataType.toLowerCase()) {
      case 'user':
        return {
          'id': random.nextInt(10000).toString(),
          'name': 'Test User ${random.nextInt(100)}',
          'email': 'test${random.nextInt(1000)}@example.com',
          'age': 18 + random.nextInt(50),
        };
      
      case 'product':
        return {
          'id': random.nextInt(10000).toString(),
          'name': 'Test Product ${random.nextInt(100)}',
          'price': (random.nextDouble() * 100).toStringAsFixed(2),
          'category': ['Electronics', 'Clothing', 'Books'][random.nextInt(3)],
        };
      
      case 'order':
        return {
          'id': random.nextInt(10000).toString(),
          'userId': random.nextInt(1000).toString(),
          'total': (random.nextDouble() * 500).toStringAsFixed(2),
          'status': ['pending', 'completed', 'cancelled'][random.nextInt(3)],
        };
      
      default:
        return {
          'id': random.nextInt(10000).toString(),
          'value': 'Test Value ${random.nextInt(100)}',
        };
    }
  }

  // Utilities
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _testLogController.add(logMessage);
  }

  Future<void> clearTestHistory() async {
    _testHistory.clear();
  }

  List<TestCase> getFailedTests() {
    if (_testHistory.isEmpty) return [];
    
    final latestResult = _testHistory.last;
    return latestResult.testSuites
        .expand((suite) => suite.testCases)
        .where((test) => test.isFailed)
        .toList();
  }

  List<TestCase> getTestsByType(TestType type) {
    if (_testHistory.isEmpty) return [];
    
    final latestResult = _testHistory.last;
    return latestResult.testSuites
        .expand((suite) => suite.testCases)
        .where((test) => test.type == type)
        .toList();
  }

  TestResult? getLatestTestResult() {
    return _testHistory.isNotEmpty ? _testHistory.last : null;
  }

  void dispose() {
    _testResultController.close();
    _testProgressController.close();
    _testLogController.close();
  }
}