import 'dart:async';
import 'dart:convert';
import 'dart:math';

enum SnippetType { dart, flutter, custom, project }
enum SnippetCategory { 
  widgets, 
  services, 
  models, 
  screens, 
  utils, 
  tests, 
  animations,
  layouts,
  forms,
  networking
}

class SnippetVariable {
  final String name;
  final String defaultValue;
  final String? description;
  final List<String>? choices;
  final bool required;

  const SnippetVariable({
    required this.name,
    required this.defaultValue,
    this.description,
    this.choices,
    this.required = false,
  });

  factory SnippetVariable.fromJson(Map<String, dynamic> json) {
    return SnippetVariable(
      name: json['name'] as String,
      defaultValue: json['defaultValue'] as String,
      description: json['description'] as String?,
      choices: (json['choices'] as List<dynamic>?)?.cast<String>(),
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultValue': defaultValue,
      'description': description,
      'choices': choices,
      'required': required,
    };
  }
}

class CodeSnippet {
  final String id;
  final String name;
  final String prefix;
  final String description;
  final SnippetType type;
  final SnippetCategory category;
  final String body;
  final List<SnippetVariable> variables;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final int useCount;
  final double rating;
  final String? author;
  final bool isBuiltIn;

  const CodeSnippet({
    required this.id,
    required this.name,
    required this.prefix,
    required this.description,
    required this.type,
    required this.category,
    required this.body,
    this.variables = const [],
    this.tags = const [],
    required this.createdAt,
    this.modifiedAt,
    this.useCount = 0,
    this.rating = 0.0,
    this.author,
    this.isBuiltIn = false,
  });

  CodeSnippet copyWith({
    String? id,
    String? name,
    String? prefix,
    String? description,
    SnippetType? type,
    SnippetCategory? category,
    String? body,
    List<SnippetVariable>? variables,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? useCount,
    double? rating,
    String? author,
    bool? isBuiltIn,
  }) {
    return CodeSnippet(
      id: id ?? this.id,
      name: name ?? this.name,
      prefix: prefix ?? this.prefix,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      body: body ?? this.body,
      variables: variables ?? this.variables,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      useCount: useCount ?? this.useCount,
      rating: rating ?? this.rating,
      author: author ?? this.author,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  factory CodeSnippet.fromJson(Map<String, dynamic> json) {
    return CodeSnippet(
      id: json['id'] as String,
      name: json['name'] as String,
      prefix: json['prefix'] as String,
      description: json['description'] as String,
      type: SnippetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SnippetType.custom,
      ),
      category: SnippetCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SnippetCategory.utils,
      ),
      body: json['body'] as String,
      variables: (json['variables'] as List<dynamic>?)
          ?.map((v) => SnippetVariable.fromJson(v))
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null 
          ? DateTime.parse(json['modifiedAt'] as String) 
          : null,
      useCount: json['useCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      author: json['author'] as String?,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prefix': prefix,
      'description': description,
      'type': type.name,
      'category': category.name,
      'body': body,
      'variables': variables.map((v) => v.toJson()).toList(),
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'useCount': useCount,
      'rating': rating,
      'author': author,
      'isBuiltIn': isBuiltIn,
    };
  }
}

class SnippetExpansion {
  final String id;
  final CodeSnippet snippet;
  final String expandedCode;
  final Map<String, String> variableValues;
  final DateTime expandedAt;
  final String filePath;
  final int lineNumber;

  const SnippetExpansion({
    required this.id,
    required this.snippet,
    required this.expandedCode,
    required this.variableValues,
    required this.expandedAt,
    required this.filePath,
    required this.lineNumber,
  });
}

class SnippetTemplate {
  final String id;
  final String name;
  final String description;
  final SnippetCategory category;
  final List<CodeSnippet> snippets;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SnippetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.snippets,
    this.metadata = const {},
    required this.createdAt,
  });
}

class CodeSnippetsService {
  static final CodeSnippetsService _instance = CodeSnippetsService._internal();
  factory CodeSnippetsService() => _instance;
  CodeSnippetsService._internal();

  final StreamController<List<CodeSnippet>> _snippetsController = 
      StreamController<List<CodeSnippet>>.broadcast();
  final StreamController<SnippetExpansion> _expansionController = 
      StreamController<SnippetExpansion>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();

  Stream<List<CodeSnippet>> get snippetsStream => _snippetsController.stream;
  Stream<SnippetExpansion> get expansionStream => _expansionController.stream;
  Stream<String> get statusStream => _statusController.stream;

  final List<CodeSnippet> _snippets = [];
  final List<SnippetTemplate> _templates = [];
  final List<SnippetExpansion> _expansionHistory = [];

  List<CodeSnippet> get snippets => List.unmodifiable(_snippets);
  List<SnippetTemplate> get templates => List.unmodifiable(_templates);
  List<SnippetExpansion> get expansionHistory => List.unmodifiable(_expansionHistory);

  // Initialize with built-in snippets
  void initialize() {
    _loadBuiltInSnippets();
    _loadBuiltInTemplates();
    _snippetsController.add(_snippets);
    _status('Code snippets service initialized with ${_snippets.length} snippets');
  }

  void _loadBuiltInSnippets() {
    _snippets.addAll([
      // Flutter Widget Snippets
      CodeSnippet(
        id: 'stless',
        name: 'StatelessWidget',
        prefix: 'stless',
        description: 'Creates a StatelessWidget class',
        type: SnippetType.flutter,
        category: SnippetCategory.widgets,
        body: '''import 'package:flutter/material.dart';

class \${1:WidgetName} extends StatelessWidget {
  const \${1:WidgetName}({super.key});

  @override
  Widget build(BuildContext context) {
    return \${2:Container}(
      \${3:child: Text('Hello World'),}
    );
  }
}''',
        variables: [
          const SnippetVariable(name: 'WidgetName', defaultValue: 'MyWidget', required: true),
          const SnippetVariable(name: 'Container', defaultValue: 'Container'),
          const SnippetVariable(name: 'child: Text(\'Hello World\'),', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['widget', 'stateless', 'flutter'],
      ),

      CodeSnippet(
        id: 'stful',
        name: 'StatefulWidget',
        prefix: 'stful',
        description: 'Creates a StatefulWidget class',
        type: SnippetType.flutter,
        category: SnippetCategory.widgets,
        body: '''import 'package:flutter/material.dart';

class \${1:WidgetName} extends StatefulWidget {
  const \${1:WidgetName}({super.key});

  @override
  State<\${1:WidgetName}> createState() => _\${1:WidgetName}State();
}

class _\${1:WidgetName}State extends State<\${1:WidgetName}> {
  @override
  void initState() {
    super.initState();
    \${2:// TODO: Initialize state}
  }

  @override
  Widget build(BuildContext context) {
    return \${3:Scaffold}(
      \${4:body: Container(),}
    );
  }

  @override
  void dispose() {
    \${5:// TODO: Dispose resources}
    super.dispose();
  }
}''',
        variables: [
          const SnippetVariable(name: 'WidgetName', defaultValue: 'MyWidget', required: true),
          const SnippetVariable(name: '// TODO: Initialize state', defaultValue: ''),
          const SnippetVariable(name: 'Scaffold', defaultValue: 'Scaffold'),
          const SnippetVariable(name: 'body: Container(),', defaultValue: ''),
          const SnippetVariable(name: '// TODO: Dispose resources', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['widget', 'stateful', 'flutter'],
      ),

      // Service Snippets
      CodeSnippet(
        id: 'service',
        name: 'Singleton Service',
        prefix: 'service',
        description: 'Creates a singleton service class',
        type: SnippetType.dart,
        category: SnippetCategory.services,
        body: '''class \${1:ServiceName} {
  static final \${1:ServiceName} _instance = \${1:ServiceName}._internal();
  factory \${1:ServiceName}() => _instance;
  \${1:ServiceName}._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      \${2:// TODO: Initialize service}
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize \${1:ServiceName}: \$e');
    }
  }

  \${3:Future<void> performAction() async {
    if (!_isInitialized) {
      throw StateError('\${1:ServiceName} not initialized');
    }
    
    // TODO: Implement action
  }}

  void dispose() {
    \${4:// TODO: Clean up resources}
    _isInitialized = false;
  }
}''',
        variables: [
          const SnippetVariable(name: 'ServiceName', defaultValue: 'MyService', required: true),
          const SnippetVariable(name: '// TODO: Initialize service', defaultValue: ''),
          const SnippetVariable(name: 'Future<void> performAction() async {\n    if (!_isInitialized) {\n      throw StateError(\'\${1:ServiceName} not initialized\');\n    }\n    \n    // TODO: Implement action\n  }', defaultValue: ''),
          const SnippetVariable(name: '// TODO: Clean up resources', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['service', 'singleton', 'dart'],
      ),

      // Model Snippets
      CodeSnippet(
        id: 'model',
        name: 'Data Model',
        prefix: 'model',
        description: 'Creates a data model class with JSON serialization',
        type: SnippetType.dart,
        category: SnippetCategory.models,
        body: '''class \${1:ModelName} {
  final String id;
  final String \${2:name};
  final DateTime createdAt;

  const \${1:ModelName}({
    required this.id,
    required this.\${2:name},
    required this.createdAt,
  });

  factory \${1:ModelName}.fromJson(Map<String, dynamic> json) {
    return \${1:ModelName}(
      id: json['id'] as String,
      \${2:name}: json['\${2:name}'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '\${2:name}': \${2:name},
      'createdAt': createdAt.toIso8601String(),
    };
  }

  \${1:ModelName} copyWith({
    String? id,
    String? \${2:name},
    DateTime? createdAt,
  }) {
    return \${1:ModelName}(
      id: id ?? this.id,
      \${2:name}: \${2:name} ?? this.\${2:name},
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is \${1:ModelName} &&
        other.id == id &&
        other.\${2:name} == \${2:name} &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ \${2:name}.hashCode ^ createdAt.hashCode;
  }
}''',
        variables: [
          const SnippetVariable(name: 'ModelName', defaultValue: 'MyModel', required: true),
          const SnippetVariable(name: 'name', defaultValue: 'name', required: true),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['model', 'json', 'dart'],
      ),

      // Screen Snippets
      CodeSnippet(
        id: 'screen',
        name: 'Screen with AppBar',
        prefix: 'screen',
        description: 'Creates a screen with AppBar and body',
        type: SnippetType.flutter,
        category: SnippetCategory.screens,
        body: '''import 'package:flutter/material.dart';

class \${1:ScreenName} extends StatefulWidget {
  const \${1:ScreenName}({super.key});

  @override
  State<\${1:ScreenName}> createState() => _\${1:ScreenName}State();
}

class _\${1:ScreenName}State extends State<\${1:ScreenName}> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      \${3:// TODO: Load data}
    } catch (e) {
      _showError('Failed to load data: \$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\${2:Screen Title}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return const Center(
      child: Text('\${2:Screen Title}'),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}''',
        variables: [
          const SnippetVariable(name: 'ScreenName', defaultValue: 'MyScreen', required: true),
          const SnippetVariable(name: 'Screen Title', defaultValue: 'My Screen', required: true),
          const SnippetVariable(name: '// TODO: Load data', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['screen', 'scaffold', 'appbar', 'flutter'],
      ),

      // Form Snippets
      CodeSnippet(
        id: 'form',
        name: 'Form with Validation',
        prefix: 'form',
        description: 'Creates a form with validation',
        type: SnippetType.flutter,
        category: SnippetCategory.forms,
        body: '''class \${1:FormName} extends StatefulWidget {
  const \${1:FormName}({super.key});

  @override
  State<\${1:FormName}> createState() => _\${1:FormName}State();
}

class _\${1:FormName}State extends State<\${1:FormName}> {
  final _formKey = GlobalKey<FormState>();
  final _\${2:field}Controller = TextEditingController();

  @override
  void dispose() {
    _\${2:field}Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _\${2:field}Controller,
            decoration: const InputDecoration(
              labelText: '\${3:Field Label}',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter \${2:field}';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      \${4:// TODO: Process form data}
      final \${2:field} = _\${2:field}Controller.text;
      print('\${3:Field Label}: \$\${2:field}');
    }
  }
}''',
        variables: [
          const SnippetVariable(name: 'FormName', defaultValue: 'MyForm', required: true),
          const SnippetVariable(name: 'field', defaultValue: 'name', required: true),
          const SnippetVariable(name: 'Field Label', defaultValue: 'Name', required: true),
          const SnippetVariable(name: '// TODO: Process form data', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['form', 'validation', 'textfield', 'flutter'],
      ),

      // Animation Snippets
      CodeSnippet(
        id: 'animation',
        name: 'Animation Controller',
        prefix: 'animation',
        description: 'Creates an AnimationController with Tween',
        type: SnippetType.flutter,
        category: SnippetCategory.animations,
        body: '''class \${1:AnimatedWidget} extends StatefulWidget {
  const \${1:AnimatedWidget}({super.key});

  @override
  State<\${1:AnimatedWidget}> createState() => _\${1:AnimatedWidget}State();
}

class _\${1:AnimatedWidget}State extends State<\${1:AnimatedWidget}>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: \${2:500}),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: \${3:0.0},
      end: \${4:1.0},
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.\${5:easeInOut},
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return \${6:Opacity}(
          opacity: _animation.value,
          child: \${7:Container(
            child: Text('Animated Widget'),
          )},
        );
      },
    );
  }

  void \${8:startAnimation}() {
    _animationController.forward();
  }

  void \${9:resetAnimation}() {
    _animationController.reset();
  }
}''',
        variables: [
          const SnippetVariable(name: 'AnimatedWidget', defaultValue: 'MyAnimatedWidget', required: true),
          const SnippetVariable(name: '500', defaultValue: '500'),
          const SnippetVariable(name: '0.0', defaultValue: '0.0'),
          const SnippetVariable(name: '1.0', defaultValue: '1.0'),
          const SnippetVariable(name: 'easeInOut', defaultValue: 'easeInOut', choices: ['easeInOut', 'easeIn', 'easeOut', 'bounceIn', 'bounceOut']),
          const SnippetVariable(name: 'Opacity', defaultValue: 'Opacity'),
          const SnippetVariable(name: 'Container(\n            child: Text(\'Animated Widget\'),\n          )', defaultValue: 'Container()'),
          const SnippetVariable(name: 'startAnimation', defaultValue: 'startAnimation'),
          const SnippetVariable(name: 'resetAnimation', defaultValue: 'resetAnimation'),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['animation', 'controller', 'tween', 'flutter'],
      ),

      // Test Snippets
      CodeSnippet(
        id: 'test',
        name: 'Unit Test',
        prefix: 'test',
        description: 'Creates a unit test with setup and teardown',
        type: SnippetType.dart,
        category: SnippetCategory.tests,
        body: '''import 'package:flutter_test/flutter_test.dart';
\${1:import 'package:your_app/your_file.dart';}

void main() {
  group('\${2:TestGroupName}', () {
    late \${3:ClassUnderTest} \${4:instance};

    setUp(() {
      \${4:instance} = \${3:ClassUnderTest}();
    });

    test('\${5:should perform expected behavior}', () {
      // Arrange
      \${6:const input = 'test';}

      // Act
      \${7:final result = \${4:instance}.method(input);}

      // Assert
      \${8:expect(result, equals('expected'));}
    });

    test('\${9:should handle edge cases}', () {
      // TODO: Test edge cases
      expect(true, isTrue);
    });

    tearDown(() {
      \${10:// Clean up resources}
    });
  });
}''',
        variables: [
          const SnippetVariable(name: 'import \'package:your_app/your_file.dart\';', defaultValue: ''),
          const SnippetVariable(name: 'TestGroupName', defaultValue: 'Test Group', required: true),
          const SnippetVariable(name: 'ClassUnderTest', defaultValue: 'MyClass', required: true),
          const SnippetVariable(name: 'instance', defaultValue: 'instance'),
          const SnippetVariable(name: 'should perform expected behavior', defaultValue: 'should perform expected behavior'),
          const SnippetVariable(name: 'const input = \'test\';', defaultValue: ''),
          const SnippetVariable(name: 'final result = \${4:instance}.method(input);', defaultValue: ''),
          const SnippetVariable(name: 'expect(result, equals(\'expected\'));', defaultValue: 'expect(true, isTrue);'),
          const SnippetVariable(name: 'should handle edge cases', defaultValue: 'should handle edge cases'),
          const SnippetVariable(name: '// Clean up resources', defaultValue: ''),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['test', 'unit', 'dart'],
      ),

      // Utility Snippets
      CodeSnippet(
        id: 'logger',
        name: 'Logger Setup',
        prefix: 'logger',
        description: 'Creates a logger utility class',
        type: SnippetType.dart,
        category: SnippetCategory.utils,
        body: '''import 'dart:developer' as developer;

class Logger {
  static const String _prefix = '\${1:AppLogger}';

  static void debug(String message, [Object? error]) {
    developer.log(
      message,
      name: _prefix,
      level: 500,
      error: error,
    );
  }

  static void info(String message, [Object? error]) {
    developer.log(
      message,
      name: _prefix,
      level: 800,
      error: error,
    );
  }

  static void warning(String message, [Object? error]) {
    developer.log(
      message,
      name: _prefix,
      level: 900,
      error: error,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _prefix,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}''',
        variables: [
          const SnippetVariable(name: 'AppLogger', defaultValue: 'AppLogger'),
        ],
        createdAt: DateTime.now(),
        isBuiltIn: true,
        tags: ['logger', 'debug', 'utility', 'dart'],
      ),
    ]);
  }

  void _loadBuiltInTemplates() {
    _templates.addAll([
      SnippetTemplate(
        id: 'mvvm_template',
        name: 'MVVM Architecture Template',
        description: 'Complete MVVM pattern setup with ViewModel, View, and Model',
        category: SnippetCategory.services,
        snippets: [
          // This would include multiple related snippets
        ],
        createdAt: DateTime.now(),
      ),
    ]);
  }

  // Snippet Management
  CodeSnippet createSnippet({
    required String name,
    required String prefix,
    required String description,
    required SnippetType type,
    required SnippetCategory category,
    required String body,
    List<SnippetVariable>? variables,
    List<String>? tags,
    String? author,
  }) {
    final snippet = CodeSnippet(
      id: _generateId(),
      name: name,
      prefix: prefix,
      description: description,
      type: type,
      category: category,
      body: body,
      variables: variables ?? [],
      tags: tags ?? [],
      createdAt: DateTime.now(),
      author: author,
    );

    _snippets.add(snippet);
    _snippetsController.add(_snippets);
    _status('Created snippet: $name');

    return snippet;
  }

  void updateSnippet(String id, {
    String? name,
    String? prefix,
    String? description,
    SnippetType? type,
    SnippetCategory? category,
    String? body,
    List<SnippetVariable>? variables,
    List<String>? tags,
  }) {
    final index = _snippets.indexWhere((s) => s.id == id);
    if (index != -1) {
      _snippets[index] = _snippets[index].copyWith(
        name: name,
        prefix: prefix,
        description: description,
        type: type,
        category: category,
        body: body,
        variables: variables,
        tags: tags,
        modifiedAt: DateTime.now(),
      );

      _snippetsController.add(_snippets);
      _status('Updated snippet: ${_snippets[index].name}');
    }
  }

  void deleteSnippet(String id) {
    final snippet = _snippets.firstWhere((s) => s.id == id, orElse: () => 
        CodeSnippet(id: '', name: '', prefix: '', description: '', type: SnippetType.custom, category: SnippetCategory.utils, body: '', createdAt: DateTime.now()));
    
    if (snippet.id.isNotEmpty && !snippet.isBuiltIn) {
      _snippets.removeWhere((s) => s.id == id);
      _snippetsController.add(_snippets);
      _status('Deleted snippet: ${snippet.name}');
    }
  }

  // Snippet Search and Filtering
  List<CodeSnippet> searchSnippets(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _snippets.where((snippet) {
      return snippet.name.toLowerCase().contains(lowercaseQuery) ||
             snippet.prefix.toLowerCase().contains(lowercaseQuery) ||
             snippet.description.toLowerCase().contains(lowercaseQuery) ||
             snippet.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  List<CodeSnippet> getSnippetsByCategory(SnippetCategory category) {
    return _snippets.where((snippet) => snippet.category == category).toList();
  }

  List<CodeSnippet> getSnippetsByType(SnippetType type) {
    return _snippets.where((snippet) => snippet.type == type).toList();
  }

  List<CodeSnippet> getSnippetsByPrefix(String prefix) {
    return _snippets.where((snippet) => 
        snippet.prefix.toLowerCase().startsWith(prefix.toLowerCase())).toList();
  }

  List<CodeSnippet> getMostUsedSnippets({int limit = 10}) {
    final sorted = [..._snippets];
    sorted.sort((a, b) => b.useCount.compareTo(a.useCount));
    return sorted.take(limit).toList();
  }

  List<CodeSnippet> getRecentSnippets({int limit = 10}) {
    final sorted = [..._snippets];
    sorted.sort((a, b) => (b.modifiedAt ?? b.createdAt)
        .compareTo(a.modifiedAt ?? a.createdAt));
    return sorted.take(limit).toList();
  }

  // Snippet Expansion
  String expandSnippet(CodeSnippet snippet, Map<String, String> variableValues, {
    String? filePath,
    int? lineNumber,
  }) {
    String expandedCode = snippet.body;
    final actualValues = <String, String>{};

    // Replace variables
    for (final variable in snippet.variables) {
      final value = variableValues[variable.name] ?? variable.defaultValue;
      actualValues[variable.name] = value;
      
      // Replace both ${n:name} and ${name} patterns
      expandedCode = expandedCode.replaceAll('\${${snippet.variables.indexOf(variable) + 1}:${variable.name}}', value);
      expandedCode = expandedCode.replaceAll('\${${variable.name}}', value);
    }

    // Handle numbered placeholders without variable names
    final placeholderRegex = RegExp(r'\$\{(\d+):([^}]+)\}');
    expandedCode = expandedCode.replaceAllMapped(placeholderRegex, (match) {
      final placeholder = match.group(2) ?? '';
      return variableValues[placeholder] ?? placeholder;
    });

    // Record expansion
    final expansion = SnippetExpansion(
      id: _generateId(),
      snippet: snippet,
      expandedCode: expandedCode,
      variableValues: actualValues,
      expandedAt: DateTime.now(),
      filePath: filePath ?? '',
      lineNumber: lineNumber ?? 0,
    );

    _expansionHistory.add(expansion);
    if (_expansionHistory.length > 100) {
      _expansionHistory.removeAt(0);
    }

    // Increment use count
    _incrementUseCount(snippet.id);

    _expansionController.add(expansion);
    
    return expandedCode;
  }

  void _incrementUseCount(String snippetId) {
    final index = _snippets.indexWhere((s) => s.id == snippetId);
    if (index != -1) {
      _snippets[index] = _snippets[index].copyWith(
        useCount: _snippets[index].useCount + 1,
      );
      _snippetsController.add(_snippets);
    }
  }

  // Import/Export
  String exportSnippets(List<String> snippetIds) {
    final snippetsToExport = _snippets.where((s) => snippetIds.contains(s.id)).toList();
    final jsonData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'snippets': snippetsToExport.map((s) => s.toJson()).toList(),
    };
    return jsonEncode(jsonData);
  }

  void importSnippets(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final snippetsData = data['snippets'] as List<dynamic>;
      
      int importedCount = 0;
      for (final snippetData in snippetsData) {
        try {
          final snippet = CodeSnippet.fromJson(snippetData as Map<String, dynamic>);
          
          // Check for duplicates by prefix
          final existingIndex = _snippets.indexWhere((s) => s.prefix == snippet.prefix);
          if (existingIndex == -1) {
            _snippets.add(snippet.copyWith(
              id: _generateId(), // Generate new ID
              createdAt: DateTime.now(),
            ));
            importedCount++;
          }
        } catch (e) {
          _status('Failed to import snippet: $e');
        }
      }
      
      _snippetsController.add(_snippets);
      _status('Imported $importedCount snippets');
    } catch (e) {
      _status('Failed to import snippets: $e');
    }
  }

  // Template Management
  SnippetTemplate createTemplate({
    required String name,
    required String description,
    required SnippetCategory category,
    required List<CodeSnippet> snippets,
    Map<String, dynamic>? metadata,
  }) {
    final template = SnippetTemplate(
      id: _generateId(),
      name: name,
      description: description,
      category: category,
      snippets: snippets,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
    );

    _templates.add(template);
    _status('Created template: $name');

    return template;
  }

  void applyTemplate(String templateId, Map<String, String> globalVariables) {
    final template = _templates.firstWhere((t) => t.id == templateId,
        orElse: () => SnippetTemplate(id: '', name: '', description: '', category: SnippetCategory.utils, snippets: [], createdAt: DateTime.now()));
    
    if (template.id.isNotEmpty) {
      for (final snippet in template.snippets) {
        expandSnippet(snippet, globalVariables);
      }
      _status('Applied template: ${template.name}');
    }
  }

  // Statistics
  Map<String, dynamic> getSnippetStatistics() {
    final categoryCount = <SnippetCategory, int>{};
    final typeCount = <SnippetType, int>{};
    
    for (final snippet in _snippets) {
      categoryCount[snippet.category] = (categoryCount[snippet.category] ?? 0) + 1;
      typeCount[snippet.type] = (typeCount[snippet.type] ?? 0) + 1;
    }

    return {
      'totalSnippets': _snippets.length,
      'customSnippets': _snippets.where((s) => !s.isBuiltIn).length,
      'builtInSnippets': _snippets.where((s) => s.isBuiltIn).length,
      'totalExpansions': _expansionHistory.length,
      'categoryBreakdown': categoryCount.map((k, v) => MapEntry(k.name, v)),
      'typeBreakdown': typeCount.map((k, v) => MapEntry(k.name, v)),
      'mostUsedSnippet': _snippets.isNotEmpty 
          ? _snippets.reduce((a, b) => a.useCount > b.useCount ? a : b).name
          : 'None',
      'totalTemplates': _templates.length,
    };
  }

  // Utility methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _status(String message) {
    _statusController.add('[${DateTime.now().toIso8601String()}] $message');
  }

  void dispose() {
    _snippetsController.close();
    _expansionController.close();
    _statusController.close();
  }
}