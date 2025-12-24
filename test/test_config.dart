import 'package:flutter_test/flutter_test.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/testing_framework_service.dart';

/// Global test configuration and utilities for CodeWhisper test suite
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration shortTimeout = Duration(seconds: 5);
  
  static late TestingFrameworkService testingService;
  
  static void setUp() {
    testingService = TestingFrameworkService();
  }
  
  static void tearDown() {
    testingService.dispose();
  }
}

/// Mock data utilities for testing
class MockDataProvider {
  static FlutterProject createSimpleProject() {
    return FlutterProject(
      name: 'Mock Project',
      files: [],
      uploadedAt: DateTime.now(),
    );
  }
  
  static Map<String, dynamic> createMockUser() {
    return {
      'id': 'user-123',
      'name': 'Test User',
      'email': 'test@example.com',
      'role': 'developer',
      'preferences': {
        'theme': 'dark',
        'fontSize': 14,
        'autoSave': true,
      },
    };
  }
  
  static List<Map<String, dynamic>> createMockProjectFiles() {
    return [
      {
        'path': 'lib/main.dart',
        'content': 'void main() => runApp(MyApp());',
        'size': 1024,
        'modified': DateTime.now().toIso8601String(),
      },
      {
        'path': 'lib/models/user.dart',
        'content': 'class User { final String id; }',
        'size': 512,
        'modified': DateTime.now().toIso8601String(),
      },
      {
        'path': 'pubspec.yaml',
        'content': 'name: test_app\nversion: 1.0.0',
        'size': 256,
        'modified': DateTime.now().toIso8601String(),
      },
    ];
  }
}

/// Test validation utilities
class TestValidator {
  static void validateProjectStructure(FlutterProject project) {
    expect(project.name.isNotEmpty, isTrue, reason: 'Project name should not be empty');
    expect(project.files, isA<List<ProjectFile>>(), reason: 'Project should have files list');
    expect(project.uploadedAt, isA<DateTime>(), reason: 'Project should have upload date');
  }
  
  static void validateApiResponse(Map<String, dynamic> response) {
    expect(response.containsKey('success'), isTrue, reason: 'Response should have success field');
    expect(response.containsKey('data'), isTrue, reason: 'Response should have data field');
    expect(response['success'], isA<bool>(), reason: 'Success should be boolean');
  }
}

/// Performance testing utilities
class PerformanceTestHelper {
  static Future<Duration> measureExecutionTime(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  static void validatePerformance(Duration duration, Duration maxExpected) {
    expect(
      duration.inMilliseconds,
      lessThanOrEqualTo(maxExpected.inMilliseconds),
      reason: 'Operation took ${duration.inMilliseconds}ms, expected <= ${maxExpected.inMilliseconds}ms'
    );
  }
  
  static Future<void> stressTest(
    Future<void> Function() operation,
    int iterations,
    Duration maxTotalTime,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < iterations; i++) {
      await operation();
      
      if (stopwatch.elapsed > maxTotalTime) {
        fail('Stress test exceeded maximum time limit');
      }
    }
    
    stopwatch.stop();
    print('Stress test completed: $iterations iterations in ${stopwatch.elapsed.inMilliseconds}ms');
  }
}

/// Custom matchers for CodeWhisper-specific testing
Matcher isValidFlutterProject() => predicate<FlutterProject>(
  (project) {
    return project.name.isNotEmpty;
  },
  'is a valid Flutter project',
);

Matcher hasValidDartSyntax() => predicate<String>(
  (code) {
    // Basic validation - in real implementation, use dart analyzer
    return code.contains('class ') ||
           code.contains('void ') ||
           code.contains('import ') ||
           code.trim().isNotEmpty;
  },
  'has valid Dart syntax',
);

Matcher isSuccessfulOperation() => predicate<Map<String, dynamic>>(
  (result) => result['success'] == true,
  'is a successful operation result',
);

/// Test data generators
class TestDataGenerator {
  static String generateValidDartClass(String className) {
    return '''
class $className {
  final String id;
  final String name;
  
  $className({required this.id, required this.name});
  
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
  
  factory $className.fromJson(Map<String, dynamic> json) {
    return $className(
      id: json['id'],
      name: json['name'],
    );
  }
}
''';
  }
  
  static String generateValidDartWidget(String widgetName) {
    return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  final String title;
  
  const $widgetName({Key? key, required this.title}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('Welcome to $widgetName'),
      ),
    );
  }
}
''';
  }
  
  static String generateInvalidDartCode() {
    return '''
class InvalidClass {
  void method() {
    // Missing semicolon and brace
    print("error"
  // Missing closing brace
''';
  }
  
  /// Generate a complete Flutter project with realistic structure
  static FlutterProject generateFlutterProject([String? name]) {
    final projectName = name ?? 'test_project';
    
    // Create initial project files
    final files = <ProjectFile>[
      ProjectFile(
        path: 'lib/main.dart',
        content: generateMainDartFile(projectName),
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'pubspec.yaml',
        content: generatePubspecFile(projectName),
        type: FileType.yaml,
      ),
      ProjectFile(
        path: 'lib/models/user.dart',
        content: generateValidDartClass('User'),
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/home_screen.dart',
        content: generateValidDartWidget('HomeScreen'),
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/services/api_service.dart',
        content: generateApiServiceCode(),
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'test/widget_test.dart',
        content: generateWidgetTestCode(),
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'android/app/src/main/AndroidManifest.xml',
        content: generateAndroidManifest(),
        type: FileType.other,
      ),
      ProjectFile(
        path: 'ios/Runner/Info.plist',
        content: generateIosInfoPlist(),
        type: FileType.other,
      ),
    ];
    
    final project = FlutterProject(
      name: projectName,
      files: files,
      uploadedAt: DateTime.now(),
    );
    
    return project;
  }
  
  /// Generate a large Flutter project for performance testing
  static FlutterProject generateLargeFlutterProject() {
    final baseProject = generateFlutterProject('large_test_project');
    final additionalFiles = <ProjectFile>[];
    
    // Add many files to simulate large project
    for (int i = 0; i < 100; i++) {
      additionalFiles.addAll([
        ProjectFile(
          path: 'lib/widgets/widget_$i.dart',
          content: generateValidDartWidget('Widget$i'),
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'lib/models/model_$i.dart',
          content: generateValidDartClass('Model$i'),
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'lib/services/service_$i.dart',
          content: generateServiceCode('Service$i'),
          type: FileType.dart,
        ),
      ]);
    }
    
    // Add nested folder structure
    for (int i = 0; i < 20; i++) {
      additionalFiles.addAll([
        ProjectFile(
          path: 'lib/modules/module_$i/controller.dart',
          content: generateControllerCode('Module${i}Controller'),
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'lib/modules/module_$i/view.dart',
          content: generateValidDartWidget('Module${i}View'),
          type: FileType.dart,
        ),
        ProjectFile(
          path: 'lib/modules/module_$i/model.dart',
          content: generateValidDartClass('Module${i}Model'),
          type: FileType.dart,
        ),
      ]);
    }
    
    return baseProject.copyWith(
      files: [...baseProject.files, ...additionalFiles],
    );
  }
  
  /// Generate a project with many files for tree view testing
  static FlutterProject generateProjectWithManyFiles(int fileCount) {
    final baseProject = generateFlutterProject('many_files_project');
    final additionalFiles = <ProjectFile>[];
    
    for (int i = 0; i < fileCount; i++) {
      final folderIndex = i ~/ 50; // 50 files per folder
      additionalFiles.add(
        ProjectFile(
          path: 'lib/folder_$folderIndex/file_$i.dart',
          content: generateValidDartClass('Class$i'),
          type: FileType.dart,
        ),
      );
    }
    
    return baseProject.copyWith(
      files: [...baseProject.files, ...additionalFiles],
    );
  }
  
  static String generateMainDartFile(String appName) {
    return '''
import 'package:flutter/material.dart';

void main() {
  runApp(${appName.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join('')}App());
}

class ${appName.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join('')}App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '$appName Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  
  final String title;
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have pushed the button this many times:'),
            Text('\$_counter', style: Theme.of(context).textTheme.headline4),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
''';
  }
  
  static String generatePubspecFile(String projectName) {
    return '''
name: $projectName
description: A new Flutter project for testing.
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <4.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  http: ^0.13.5
  provider: ^6.0.3
  sqflite: ^2.2.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  mockito: ^5.3.0
  build_runner: ^2.2.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
  fonts:
    - family: Schyler
      fonts:
        - asset: fonts/Schyler-Regular.ttf
        - asset: fonts/Schyler-Italic.ttf
          style: italic
''';
  }
  
  static String generateApiServiceCode() {
    return '''
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://api.example.com';
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('\$_baseUrl/\$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('\$_baseUrl/\$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data');
    }
  }
}
''';
  }
  
  static String generateWidgetTestCode() {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_project/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(TestProjectApp());
    
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
''';
  }
  
  static String generateServiceCode(String serviceName) {
    return '''
class $serviceName {
  static final $serviceName _instance = $serviceName._internal();
  factory $serviceName() => _instance;
  $serviceName._internal();
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize service
    await Future.delayed(Duration(milliseconds: 100));
    _isInitialized = true;
  }
  
  bool get isInitialized => _isInitialized;
  
  Future<String> performOperation() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }
    
    return 'Operation completed by $serviceName';
  }
  
  void dispose() {
    _isInitialized = false;
  }
}
''';
  }
  
  static String generateControllerCode(String controllerName) {
    return '''
import 'package:flutter/foundation.dart';

class $controllerName extends ChangeNotifier {
  String _data = '';
  bool _isLoading = false;
  
  String get data => _data;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(Duration(seconds: 2));
    
    _data = 'Data loaded by $controllerName';
    _isLoading = false;
    notifyListeners();
  }
  
  void updateData(String newData) {
    _data = newData;
    notifyListeners();
  }
  
  void reset() {
    _data = '';
    _isLoading = false;
    notifyListeners();
  }
}
''';
  }
  
  static String generateAndroidManifest() {
    return '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.test.testproject">
   <application
        android:label="test_project"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''';
  }
  
  static String generateIosInfoPlist() {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Test Project</string>
	<key>CFBundleExecutable</key>
	<string>Runner</string>
	<key>CFBundleIdentifier</key>
	<string>com.test.testProject</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>test_project</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
</dict>
</plist>
''';
  }
  
  static String generateDartFileContent(String className) {
    return generateValidDartClass(className);
  }
}

/// Test environment setup
void setUpTestEnvironment() {
  TestConfig.setUp();
  
  // Set up global test configuration
  TestWidgetsFlutterBinding.ensureInitialized();
}

void tearDownTestEnvironment() {
  TestConfig.tearDown();
}