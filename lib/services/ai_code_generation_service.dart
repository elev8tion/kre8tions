import 'dart:async';
import 'dart:math';

enum CodeGenerationType {
  widget,
  service,
  model,
  screen,
  function,
  test,
  documentation,
  boilerplate,
}

enum RefactoringType {
  extractWidget,
  extractMethod,
  renameSymbol,
  moveClass,
  optimizeImports,
  addNullSafety,
  convertToStateless,
  addDocumentation,
}

enum AiCapability {
  codeGeneration,
  codeRefactoring,
  bugFix,
  codeExplanation,
  codeOptimization,
  testGeneration,
  documentationGeneration,
}

class CodeGenerationRequest {
  final String id;
  final CodeGenerationType type;
  final String description;
  final String? context;
  final Map<String, dynamic> parameters;
  final String? filePath;
  final DateTime requestedAt;

  const CodeGenerationRequest({
    required this.id,
    required this.type,
    required this.description,
    this.context,
    this.parameters = const {},
    this.filePath,
    required this.requestedAt,
  });
}

class CodeGenerationResult {
  final String id;
  final CodeGenerationRequest request;
  final String generatedCode;
  final List<String> suggestions;
  final List<String> imports;
  final Map<String, dynamic> metadata;
  final double confidenceScore;
  final DateTime generatedAt;
  final Duration processingTime;

  const CodeGenerationResult({
    required this.id,
    required this.request,
    required this.generatedCode,
    this.suggestions = const [],
    this.imports = const [],
    this.metadata = const {},
    this.confidenceScore = 0.9,
    required this.generatedAt,
    required this.processingTime,
  });
}

class RefactoringRequest {
  final String id;
  final RefactoringType type;
  final String filePath;
  final String originalCode;
  final int startLine;
  final int endLine;
  final Map<String, dynamic> parameters;
  final DateTime requestedAt;

  const RefactoringRequest({
    required this.id,
    required this.type,
    required this.filePath,
    required this.originalCode,
    required this.startLine,
    required this.endLine,
    this.parameters = const {},
    required this.requestedAt,
  });
}

class RefactoringResult {
  final String id;
  final RefactoringRequest request;
  final String refactoredCode;
  final List<FileChange> fileChanges;
  final List<String> warnings;
  final List<String> suggestions;
  final double riskLevel;
  final DateTime completedAt;

  const RefactoringResult({
    required this.id,
    required this.request,
    required this.refactoredCode,
    this.fileChanges = const [],
    this.warnings = const [],
    this.suggestions = const [],
    this.riskLevel = 0.1,
    required this.completedAt,
  });
}

class FileChange {
  final String filePath;
  final String? originalContent;
  final String newContent;
  final String changeDescription;

  const FileChange({
    required this.filePath,
    this.originalContent,
    required this.newContent,
    required this.changeDescription,
  });
}

class CodeSuggestion {
  final String id;
  final String title;
  final String description;
  final String code;
  final int priority; // 1-5, 5 being highest
  final List<String> tags;
  final DateTime suggestedAt;

  const CodeSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    this.priority = 3,
    this.tags = const [],
    required this.suggestedAt,
  });
}

class AiCodeGenerationService {
  static final AiCodeGenerationService _instance = AiCodeGenerationService._internal();
  factory AiCodeGenerationService() => _instance;
  AiCodeGenerationService._internal();

  final StreamController<CodeGenerationResult> _generationController = 
      StreamController<CodeGenerationResult>.broadcast();
  final StreamController<RefactoringResult> _refactoringController = 
      StreamController<RefactoringResult>.broadcast();
  final StreamController<List<CodeSuggestion>> _suggestionsController = 
      StreamController<List<CodeSuggestion>>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();

  Stream<CodeGenerationResult> get generationStream => _generationController.stream;
  Stream<RefactoringResult> get refactoringStream => _refactoringController.stream;
  Stream<List<CodeSuggestion>> get suggestionsStream => _suggestionsController.stream;
  Stream<String> get statusStream => _statusController.stream;

  final List<CodeGenerationResult> _generationHistory = [];
  final List<RefactoringResult> _refactoringHistory = [];
  final List<CodeSuggestion> _activeSuggestions = [];

  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;
  List<CodeGenerationResult> get generationHistory => List.unmodifiable(_generationHistory);
  List<RefactoringResult> get refactoringHistory => List.unmodifiable(_refactoringHistory);
  List<CodeSuggestion> get activeSuggestions => List.unmodifiable(_activeSuggestions);

  // Code Generation
  Future<CodeGenerationResult> generateCode(CodeGenerationRequest request) async {
    _isProcessing = true;
    _status('Generating ${request.type.name} code...');

    final startTime = DateTime.now();

    try {
      // Simulate AI processing time
      await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(2000)));

      final generatedCode = _generateCodeByType(request);
      final imports = _extractImports(request.type);
      final suggestions = _generateSuggestions(request);

      final result = CodeGenerationResult(
        id: _generateId(),
        request: request,
        generatedCode: generatedCode,
        imports: imports,
        suggestions: suggestions,
        confidenceScore: 0.85 + Random().nextDouble() * 0.1,
        generatedAt: DateTime.now(),
        processingTime: DateTime.now().difference(startTime),
      );

      _generationHistory.add(result);
      _generationController.add(result);
      _status('Code generation completed successfully');

      return result;
    } finally {
      _isProcessing = false;
    }
  }

  String _generateCodeByType(CodeGenerationRequest request) {
    switch (request.type) {
      case CodeGenerationType.widget:
        return _generateWidget(request);
      case CodeGenerationType.service:
        return _generateService(request);
      case CodeGenerationType.model:
        return _generateModel(request);
      case CodeGenerationType.screen:
        return _generateScreen(request);
      case CodeGenerationType.function:
        return _generateFunction(request);
      case CodeGenerationType.test:
        return _generateTest(request);
      case CodeGenerationType.documentation:
        return _generateDocumentation(request);
      case CodeGenerationType.boilerplate:
        return _generateBoilerplate(request);
    }
  }

  String _generateWidget(CodeGenerationRequest request) {
    final widgetName = request.parameters['name'] ?? 'CustomWidget';
    final isStateful = request.parameters['stateful'] ?? false;
    
    if (isStateful) {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatefulWidget {
  const $widgetName({super.key});

  @override
  State<$widgetName> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<$widgetName> {
  @override
  void initState() {
    super.initState();
    // TODO: Initialize state
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$widgetName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement button action
            },
            child: const Text('Action'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: Clean up resources
    super.dispose();
  }
}
''';
    } else {
      return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '$widgetName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'A custom widget generated by AI',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
''';
    }
  }

  String _generateService(CodeGenerationRequest request) {
    final serviceName = request.parameters['name'] ?? 'CustomService';
    final isSingleton = request.parameters['singleton'] ?? true;

    if (isSingleton) {
      return '''
class $serviceName {
  static final $serviceName _instance = $serviceName._internal();
  factory $serviceName() => _instance;
  $serviceName._internal();

  // Service state
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // TODO: Add initialization logic here
      await Future.delayed(const Duration(milliseconds: 100));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize $serviceName: \$e');
    }
  }

  /// Main service method
  Future<Map<String, dynamic>> performOperation(String input) async {
    if (!_isInitialized) {
      throw StateError('$serviceName not initialized. Call initialize() first.');
    }

    try {
      // TODO: Implement your service logic here
      await Future.delayed(const Duration(milliseconds: 200));
      
      return {
        'success': true,
        'data': input,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Dispose of resources
  void dispose() {
    _isInitialized = false;
    // TODO: Clean up resources here
  }
}
''';
    } else {
      return '''
class $serviceName {
  // Service configuration
  final Map<String, dynamic> _config;

  $serviceName({Map<String, dynamic>? config}) 
      : _config = config ?? {};

  /// Main service method
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    try {
      // TODO: Implement service logic here
      await Future.delayed(const Duration(milliseconds: 100));
      
      return {
        'success': true,
        'result': params,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Helper method
  bool validateParams(Map<String, dynamic> params) {
    // TODO: Add validation logic
    return params.isNotEmpty;
  }
}
''';
    }
  }

  String _generateModel(CodeGenerationRequest request) {
    final modelName = request.parameters['name'] ?? 'CustomModel';
    final fields = request.parameters['fields'] as List<Map<String, String>>? ?? [
      {'name': 'id', 'type': 'String'},
      {'name': 'name', 'type': 'String'},
      {'name': 'createdAt', 'type': 'DateTime'},
    ];

    final fieldDeclarations = fields.map((field) => 
        '  final ${field['type']} ${field['name']};').join('\n');
    
    final constructorParams = fields.map((field) => 
        '    required this.${field['name']},').join('\n');
    
    final fromJsonFields = fields.map((field) {
      final name = field['name']!;
      final type = field['type']!;
      
      if (type == 'DateTime') {
        return "      $name: DateTime.parse(json['$name'] as String),";
      } else if (type == 'int' || type == 'double') {
        return "      $name: json['$name'] as $type,";
      } else {
        return "      $name: json['$name'] as $type,";
      }
    }).join('\n');
    
    final toJsonFields = fields.map((field) {
      final name = field['name']!;
      if (field['type'] == 'DateTime') {
        return "      '$name': $name.toIso8601String(),";
      } else {
        return "      '$name': $name,";
      }
    }).join('\n');

    return '''
class $modelName {
$fieldDeclarations

  const $modelName({
$constructorParams
  });

  factory $modelName.fromJson(Map<String, dynamic> json) {
    return $modelName(
$fromJsonFields
    );
  }

  Map<String, dynamic> toJson() {
    return {
$toJsonFields
    };
  }

  $modelName copyWith({
${fields.map((field) => '    ${field['type']}? ${field['name']},').join('\n')}
  }) {
    return $modelName(
${fields.map((field) => '      ${field['name']}: ${field['name']} ?? this.${field['name']},').join('\n')}
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is $modelName &&
${fields.map((field) => '        other.${field['name']} == ${field['name']}').join(' &&\n')};
  }

  @override
  int get hashCode {
    return ${fields.map((field) => '${field['name']}.hashCode').join(' ^\n        ')};
  }

  @override
  String toString() {
    return '$modelName(${fields.map((field) => '${field['name']}: \$${field['name']}').join(', ')})';
  }
}
''';
  }

  String _generateScreen(CodeGenerationRequest request) {
    final screenName = request.parameters['name'] ?? 'CustomScreen';
    final hasAppBar = request.parameters['appBar'] ?? true;
    final hasFloatingActionButton = request.parameters['fab'] ?? false;

    return '''
import 'package:flutter/material.dart';

class $screenName extends StatefulWidget {
  const $screenName({super.key});

  @override
  State<$screenName> createState() => _${screenName}State();
}

class _${screenName}State extends State<$screenName> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Load your data here
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      _showErrorSnackBar('Failed to load data: \$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(${hasAppBar ? '''
      appBar: AppBar(
        title: const Text('$screenName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),''' : ''}
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),${hasFloatingActionButton ? '''
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add),
      ),''' : ''}
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.widgets,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to $screenName',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This screen was generated by AI. Customize it to fit your needs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onActionPressed,
            child: const Text('Perform Action'),
          ),
        ],
      ),
    );
  }

  void _onActionPressed() {
    // TODO: Implement your action here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action performed!')),
    );
  }${hasFloatingActionButton ? '''

  void _onFabPressed() {
    // TODO: Implement FAB action here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAB pressed!')),
    );
  }''' : ''}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
''';
  }

  String _generateFunction(CodeGenerationRequest request) {
    final functionName = request.parameters['name'] ?? 'customFunction';
    final isAsync = request.parameters['async'] ?? false;
    final returnType = request.parameters['returnType'] ?? 'void';
    final params = request.parameters['parameters'] as List<Map<String, String>>? ?? [];

    final paramString = params.isEmpty 
        ? '' 
        : params.map((p) => '${p['type']} ${p['name']}').join(', ');

    final asyncModifier = isAsync ? 'async ' : '';
    final asyncReturnType = isAsync && returnType != 'void' ? 'Future<$returnType>' : returnType;

    return '''
/// Generated function: $functionName
/// TODO: Add detailed documentation here
$asyncReturnType $functionName($paramString) $asyncModifier{
  try {
    ${isAsync ? 'await Future.delayed(const Duration(milliseconds: 100));' : ''}
    
    // TODO: Implement your logic here
    ${returnType != 'void' ? '''
    // Example return value
    ${_generateReturnValue(returnType)}''' : ''}
  } catch (e) {
    // TODO: Handle errors appropriately
    ${returnType != 'void' ? '''throw Exception('Error in $functionName: \$e');''' : 'print(\'Error in $functionName: \$e\');'}
  }
}
''';
  }

  String _generateReturnValue(String returnType) {
    switch (returnType) {
      case 'String':
        return 'return \'Generated result\';';
      case 'int':
        return 'return 42;';
      case 'double':
        return 'return 3.14;';
      case 'bool':
        return 'return true;';
      case 'List':
        return 'return [];';
      case 'Map':
        return 'return {};';
      default:
        return 'return null; // TODO: Return appropriate value';
    }
  }

  String _generateTest(CodeGenerationRequest request) {
    final testName = request.parameters['name'] ?? 'Custom Test';
    final targetClass = request.parameters['targetClass'] ?? 'CustomClass';

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// TODO: Import your target class here

void main() {
  group('$testName', () {
    late $targetClass target;

    setUp(() {
      target = $targetClass();
    });

    test('should create instance successfully', () {
      expect(target, isNotNull);
      expect(target, isA<$targetClass>());
    });

    test('should perform basic operations correctly', () async {
      // Arrange
      // TODO: Set up test data

      // Act
      // TODO: Call the method under test

      // Assert
      // TODO: Verify the results
      expect(true, isTrue); // Replace with actual assertions
    });

    test('should handle edge cases', () {
      // TODO: Test edge cases and error conditions
      expect(() {
        // Test error conditions
      }, throwsException);
    });

    test('should handle async operations', () async {
      // TODO: Test async operations
      await expectLater(
        Future.value(true),
        completion(isTrue),
      );
    });

    tearDown(() {
      // TODO: Clean up after each test
    });
  });
}
''';
  }

  String _generateDocumentation(CodeGenerationRequest request) {
    final className = request.parameters['className'] ?? 'CustomClass';
    final description = request.parameters['description'] ?? 'A custom class generated by AI';

    return '''
/// $className
///
/// $description
///
/// This class provides functionality for:
/// - TODO: List main features
/// - TODO: Describe key capabilities
/// - TODO: Mention important usage patterns
///
/// Example usage:
/// ```dart
/// final instance = $className();
/// await instance.initialize();
/// final result = await instance.performOperation('input');
/// ```
///
/// See also:
/// - [RelatedClass] for similar functionality
/// - [Documentation] for detailed guides
class $className {
  /// Creates a new instance of [$className].
  ///
  /// The [parameter] is used to configure the instance behavior.
  /// 
  /// Throws [ArgumentError] if [parameter] is null or empty.
  $className({required String parameter}) {
    // TODO: Add parameter validation
  }

  /// Initializes the class and prepares it for use.
  ///
  /// This method must be called before using other methods.
  /// Returns `true` if initialization was successful.
  ///
  /// Throws [StateError] if the class is already initialized.
  Future<bool> initialize() async {
    // TODO: Implement initialization logic
    return true;
  }

  /// Performs the main operation of this class.
  ///
  /// The [input] parameter specifies what operation to perform.
  /// Returns the result of the operation.
  ///
  /// Example:
  /// ```dart
  /// final result = await instance.performOperation('test');
  /// print(result.isSuccess); // true or false
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if [input] is invalid
  /// - [StateError] if the class is not initialized
  Future<OperationResult> performOperation(String input) async {
    // TODO: Implement operation logic
    throw UnimplementedError('performOperation not implemented');
  }

  /// Disposes of resources used by this class.
  ///
  /// After calling this method, the instance should not be used.
  void dispose() {
    // TODO: Implement disposal logic
  }
}

/// Result of an operation performed by [$className].
class OperationResult {
  /// Whether the operation was successful.
  final bool isSuccess;

  /// The data returned by the operation, if successful.
  final Map<String, dynamic>? data;

  /// The error message, if the operation failed.
  final String? error;

  const OperationResult({
    required this.isSuccess,
    this.data,
    this.error,
  });
}
''';
  }

  String _generateBoilerplate(CodeGenerationRequest request) {
    final type = request.parameters['type'] ?? 'basic';

    switch (type) {
      case 'repository':
        return '''
abstract class Repository<T> {
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<void> delete(String id);
  Future<List<T>> findWhere(bool Function(T) predicate);
}

class InMemoryRepository<T> implements Repository<T> {
  final Map<String, T> _storage = {};
  final String Function(T) _getIdFunction;

  InMemoryRepository(this._getIdFunction);

  @override
  Future<T?> findById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<T>> findAll() async {
    return _storage.values.toList();
  }

  @override
  Future<T> save(T entity) async {
    final id = _getIdFunction(entity);
    _storage[id] = entity;
    return entity;
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<List<T>> findWhere(bool Function(T) predicate) async {
    return _storage.values.where(predicate).toList();
  }
}
''';
      
      case 'bloc':
        return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class CustomEvent extends Equatable {
  const CustomEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadData extends CustomEvent {}

class UpdateData extends CustomEvent {
  final String data;
  
  const UpdateData(this.data);
  
  @override
  List<Object?> get props => [data];
}

// States
abstract class CustomState extends Equatable {
  const CustomState();
  
  @override
  List<Object?> get props => [];
}

class CustomInitial extends CustomState {}

class CustomLoading extends CustomState {}

class CustomLoaded extends CustomState {
  final String data;
  
  const CustomLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class CustomError extends CustomState {
  final String message;
  
  const CustomError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class CustomBloc extends Bloc<CustomEvent, CustomState> {
  CustomBloc() : super(CustomInitial()) {
    on<LoadData>(_onLoadData);
    on<UpdateData>(_onUpdateData);
  }

  Future<void> _onLoadData(LoadData event, Emitter<CustomState> emit) async {
    emit(CustomLoading());
    
    try {
      // TODO: Implement data loading logic
      await Future.delayed(const Duration(seconds: 1));
      emit(const CustomLoaded('Loaded data'));
    } catch (e) {
      emit(CustomError(e.toString()));
    }
  }

  Future<void> _onUpdateData(UpdateData event, Emitter<CustomState> emit) async {
    try {
      // TODO: Implement data update logic
      emit(CustomLoaded(event.data));
    } catch (e) {
      emit(CustomError(e.toString()));
    }
  }
}
''';

      default:
        return '''
/// Basic boilerplate code structure
class BasicClass {
  // Private fields
  String _data = '';
  bool _isInitialized = false;

  // Public properties
  String get data => _data;
  bool get isInitialized => _isInitialized;

  /// Initialize the class
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // TODO: Add initialization logic
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize: \$e');
    }
  }

  /// Main method
  Future<String> performAction(String input) async {
    if (!_isInitialized) {
      throw StateError('Class not initialized');
    }

    try {
      // TODO: Implement your logic here
      _data = input;
      return 'Processed: \$input';
    } catch (e) {
      throw Exception('Action failed: \$e');
    }
  }

  /// Dispose resources
  void dispose() {
    _data = '';
    _isInitialized = false;
  }
}
''';
    }
  }

  List<String> _extractImports(CodeGenerationType type) {
    switch (type) {
      case CodeGenerationType.widget:
      case CodeGenerationType.screen:
        return ['package:flutter/material.dart'];
      case CodeGenerationType.test:
        return [
          'package:flutter_test/flutter_test.dart',
          'package:mockito/mockito.dart',
        ];
      case CodeGenerationType.service:
      case CodeGenerationType.model:
      case CodeGenerationType.function:
      case CodeGenerationType.documentation:
      case CodeGenerationType.boilerplate:
        return [];
    }
  }

  List<String> _generateSuggestions(CodeGenerationRequest request) {
    final suggestions = <String>[];
    
    switch (request.type) {
      case CodeGenerationType.widget:
        suggestions.addAll([
          'Consider adding proper error handling',
          'Add accessibility features (semantics)',
          'Implement proper theme usage',
          'Add loading states for async operations',
        ]);
        break;
      case CodeGenerationType.service:
        suggestions.addAll([
          'Add proper error handling and logging',
          'Consider implementing a cache layer',
          'Add method documentation',
          'Implement proper disposal of resources',
        ]);
        break;
      case CodeGenerationType.model:
        suggestions.addAll([
          'Add validation for required fields',
          'Consider implementing custom equality',
          'Add serialization for complex types',
          'Consider using immutable patterns',
        ]);
        break;
      default:
        suggestions.addAll([
          'Review the generated code for your specific needs',
          'Add proper error handling',
          'Consider adding unit tests',
          'Update documentation as needed',
        ]);
    }

    return suggestions;
  }

  // Refactoring Operations
  Future<RefactoringResult> refactorCode(RefactoringRequest request) async {
    _isProcessing = true;
    _status('Performing ${request.type.name} refactoring...');

    try {
      // Simulate AI processing time
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)));

      final refactoredCode = _performRefactoring(request);
      final fileChanges = _generateFileChanges(request, refactoredCode);
      final warnings = _generateRefactoringWarnings(request);
      final suggestions = _generateRefactoringSuggestions(request);

      final result = RefactoringResult(
        id: _generateId(),
        request: request,
        refactoredCode: refactoredCode,
        fileChanges: fileChanges,
        warnings: warnings,
        suggestions: suggestions,
        riskLevel: _calculateRiskLevel(request.type),
        completedAt: DateTime.now(),
      );

      _refactoringHistory.add(result);
      _refactoringController.add(result);
      _status('Refactoring completed successfully');

      return result;
    } finally {
      _isProcessing = false;
    }
  }

  String _performRefactoring(RefactoringRequest request) {
    switch (request.type) {
      case RefactoringType.extractWidget:
        return _extractWidget(request);
      case RefactoringType.extractMethod:
        return _extractMethod(request);
      case RefactoringType.renameSymbol:
        return _renameSymbol(request);
      case RefactoringType.moveClass:
        return _moveClass(request);
      case RefactoringType.optimizeImports:
        return _optimizeImports(request);
      case RefactoringType.addNullSafety:
        return _addNullSafety(request);
      case RefactoringType.convertToStateless:
        return _convertToStateless(request);
      case RefactoringType.addDocumentation:
        return _addDocumentation(request);
    }
  }

  String _extractWidget(RefactoringRequest request) {
    final widgetName = request.parameters['widgetName'] ?? 'ExtractedWidget';
    
    return '''
// Extracted widget
class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    // Extracted code from lines ${request.startLine}-${request.endLine}
    return Container(
      child: Text('Extracted Widget'),
    );
  }
}

// Original code with widget extracted
Widget _buildOriginalMethod() {
  return Column(
    children: [
      Text('Before extraction'),
      $widgetName(),
      Text('After extraction'),
    ],
  );
}
''';
  }

  String _extractMethod(RefactoringRequest request) {
    final methodName = request.parameters['methodName'] ?? 'extractedMethod';
    
    return '''
// Extracted method
void $methodName() {
  // Extracted code from lines ${request.startLine}-${request.endLine}
  print('Extracted method logic here');
}

// Original method with extracted code replaced
void originalMethod() {
  print('Before extraction');
  $methodName();
  print('After extraction');
}
''';
  }

  String _renameSymbol(RefactoringRequest request) {
    final oldName = request.parameters['oldName'] ?? 'oldSymbol';
    final newName = request.parameters['newName'] ?? 'newSymbol';
    
    return request.originalCode.replaceAll(oldName, newName);
  }

  String _moveClass(RefactoringRequest request) {
    final className = request.parameters['className'] ?? 'MovedClass';
    final newPackage = request.parameters['newPackage'] ?? 'new_package';
    
    return '''
// Class moved to $newPackage
// Update import: import 'package:your_app/$newPackage/${className.toLowerCase()}.dart';

${request.originalCode}
''';
  }

  String _optimizeImports(RefactoringRequest request) {
    final lines = request.originalCode.split('\n');
    final imports = <String>[];
    final otherCode = <String>[];
    
    // Separate imports from other code
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        imports.add(line);
      } else {
        otherCode.add(line);
      }
    }
    
    // Sort and deduplicate imports
    imports.sort();
    final uniqueImports = imports.toSet().toList();
    
    return '${uniqueImports.join('\n')}\n\n${otherCode.join('\n')}';
  }

  String _addNullSafety(RefactoringRequest request) {
    String code = request.originalCode;
    
    // Simple null safety additions (this would be more sophisticated in reality)
    code = code.replaceAll('String ', 'String? ');
    code = code.replaceAll('int ', 'int? ');
    code = code.replaceAll('double ', 'double? ');
    code = code.replaceAll('.length', '?.length ?? 0');
    
    return code;
  }

  String _convertToStateless(RefactoringRequest request) {
    final className = request.parameters['className'] ?? 'ConvertedWidget';
    
    return '''
class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    // Converted from StatefulWidget
    // Note: State variables may need to be passed as parameters
    return Container(
      child: Text('Converted to StatelessWidget'),
    );
  }
}
''';
  }

  String _addDocumentation(RefactoringRequest request) {
    final lines = request.originalCode.split('\n');
    final documentedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Add documentation before class declarations
      if (line.trim().startsWith('class ')) {
        documentedLines.add('/// TODO: Add class documentation');
        documentedLines.add('/// ');
        documentedLines.add('/// Describe what this class does and how to use it.');
      }
      
      // Add documentation before method declarations
      if (line.trim().startsWith('Widget ') || 
          line.trim().startsWith('void ') ||
          line.trim().startsWith('Future ')) {
        documentedLines.add('  /// TODO: Add method documentation');
        documentedLines.add('  /// ');
        documentedLines.add('  /// Describe what this method does.');
      }
      
      documentedLines.add(line);
    }
    
    return documentedLines.join('\n');
  }

  List<FileChange> _generateFileChanges(RefactoringRequest request, String refactoredCode) {
    return [
      FileChange(
        filePath: request.filePath,
        originalContent: request.originalCode,
        newContent: refactoredCode,
        changeDescription: 'Applied ${request.type.name} refactoring',
      ),
    ];
  }

  List<String> _generateRefactoringWarnings(RefactoringRequest request) {
    final warnings = <String>[];
    
    switch (request.type) {
      case RefactoringType.extractWidget:
      case RefactoringType.extractMethod:
        warnings.add('Review extracted code for proper parameter passing');
        warnings.add('Ensure all dependencies are properly handled');
        break;
      case RefactoringType.renameSymbol:
        warnings.add('This will rename all occurrences - review carefully');
        break;
      case RefactoringType.moveClass:
        warnings.add('Update all import statements in dependent files');
        warnings.add('Check for circular dependencies');
        break;
      case RefactoringType.addNullSafety:
        warnings.add('Review all null checks for correctness');
        warnings.add('Some conversions may need manual adjustment');
        break;
      case RefactoringType.convertToStateless:
        warnings.add('State variables will be lost - handle them appropriately');
        warnings.add('Check for lifecycle method dependencies');
        break;
      default:
        warnings.add('Review the refactored code carefully before applying');
    }
    
    return warnings;
  }

  List<String> _generateRefactoringSuggestions(RefactoringRequest request) {
    return [
      'Test the refactored code thoroughly',
      'Update related documentation',
      'Consider adding unit tests for the changes',
      'Review performance implications',
    ];
  }

  double _calculateRiskLevel(RefactoringType type) {
    switch (type) {
      case RefactoringType.addDocumentation:
        return 0.1; // Very low risk
      case RefactoringType.optimizeImports:
        return 0.2; // Low risk
      case RefactoringType.extractWidget:
      case RefactoringType.extractMethod:
        return 0.3; // Moderate risk
      case RefactoringType.renameSymbol:
        return 0.4; // Moderate risk
      case RefactoringType.convertToStateless:
        return 0.6; // Higher risk
      case RefactoringType.moveClass:
        return 0.7; // High risk
      case RefactoringType.addNullSafety:
        return 0.8; // High risk
    }
  }

  // Code Suggestions
  void generateCodeSuggestions(String currentCode, {String? context}) {
    _status('Generating code suggestions...');
    
    final suggestions = <CodeSuggestion>[];
    
    // Analyze current code and generate suggestions
    if (currentCode.contains('StatefulWidget') && !currentCode.contains('dispose')) {
      suggestions.add(CodeSuggestion(
        id: _generateId(),
        title: 'Add dispose method',
        description: 'Add a dispose method to clean up resources',
        code: '''
@override
void dispose() {
  // TODO: Dispose of controllers, streams, etc.
  super.dispose();
}''',
        priority: 4,
        tags: ['cleanup', 'best-practice'],
        suggestedAt: DateTime.now(),
      ));
    }
    
    if (currentCode.contains('setState') && currentCode.contains('async')) {
      suggestions.add(CodeSuggestion(
        id: _generateId(),
        title: 'Add null check for mounted',
        description: 'Check if widget is still mounted before calling setState',
        code: '''
if (mounted) {
  setState(() {
    // Your state updates here
  });
}''',
        priority: 5,
        tags: ['bug-fix', 'async'],
        suggestedAt: DateTime.now(),
      ));
    }
    
    if (currentCode.contains('Container') && !currentCode.contains('const')) {
      suggestions.add(CodeSuggestion(
        id: _generateId(),
        title: 'Use const constructors',
        description: 'Add const to improve performance',
        code: 'const Container(...)',
        priority: 3,
        tags: ['performance', 'optimization'],
        suggestedAt: DateTime.now(),
      ));
    }
    
    _activeSuggestions.clear();
    _activeSuggestions.addAll(suggestions);
    _suggestionsController.add(_activeSuggestions);
  }

  // Utility methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _status(String message) {
    _statusController.add('[${DateTime.now().toIso8601String()}] $message');
  }

  // Clean up
  void clearHistory() {
    _generationHistory.clear();
    _refactoringHistory.clear();
    _activeSuggestions.clear();
  }

  void dispose() {
    _generationController.close();
    _refactoringController.close();
    _suggestionsController.close();
    _statusController.close();
  }
}