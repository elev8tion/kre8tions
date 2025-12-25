import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/openai/openai_config.dart';

class AIProjectGenesisService {
  static Future<FlutterProject> generateProject({
    required String projectName,
    required String description,
    required FlutterProject baseProject,
    Function(String)? onProgress,
  }) async {
    onProgress?.call('🧠 Analyzing your vision...');
    
    // Analyze the description to determine app type and features
    final analysis = await _analyzeDescription(description);
    onProgress?.call('📋 Planning architecture...');
    
    // Create implementation plan
    final plan = await _createImplementationPlan(projectName, description, analysis);
    onProgress?.call('⚡ Generating models & services...');
    
    // Generate core files
    final coreFiles = await _generateCoreFiles(projectName, description, analysis, plan);
    onProgress?.call('🎨 Creating beautiful screens...');
    
    // Generate UI screens
    final screenFiles = await _generateScreenFiles(projectName, description, analysis, plan);
    onProgress?.call('🔧 Setting up navigation...');
    
    // Generate navigation and routing
    final navigationFiles = await _generateNavigation(projectName, description, analysis, plan);
    onProgress?.call('📱 Finalizing project structure...');
    
    // Combine all files
    final allFiles = [
      ...coreFiles,
      ...screenFiles,
      ...navigationFiles,
      ..._generateConfigFiles(projectName, analysis),
    ];
    
    onProgress?.call('✅ AI Genesis complete!');
    
    return FlutterProject(
      name: projectName,
      files: allFiles,
      uploadedAt: DateTime.now(),
    );
  }

  static Future<ProjectAnalysis> _analyzeDescription(String description) async {
    final prompt = '''
Analyze this app description and extract key information:

"$description"

Return a JSON object with:
{
  "appType": "fitness|social|ecommerce|productivity|entertainment|utility|education|health|finance|travel",
  "primaryFeatures": ["feature1", "feature2", ...],
  "screens": ["screen1", "screen2", ...],
  "dataModels": ["model1", "model2", ...],
  "services": ["service1", "service2", ...],
  "complexity": "simple|moderate|complex",
  "theme": {
    "primaryColor": "color_name",
    "style": "material|modern|minimalist|colorful"
  },
  "hasAuth": true|false,
  "hasDatabase": true|false,
  "hasAPI": true|false,
  "targetAudience": "description"
}
    ''';

    try {
      final response = await AIProjectGenesisService._makeRequestWithJson(prompt);
      return ProjectAnalysis.fromJson(response);
    } catch (e) {
      // Fallback to basic analysis
      return _createFallbackAnalysis(description);
    }
  }

  static Future<String> _createImplementationPlan(
    String projectName, 
    String description, 
    ProjectAnalysis analysis
  ) async {
    final prompt = '''
Create a detailed implementation plan for: "$description"

App Analysis:
- Type: ${analysis.appType}
- Features: ${analysis.primaryFeatures.join(', ')}
- Complexity: ${analysis.complexity}

Create a plan covering:
1. App structure and navigation
2. Data models and their relationships
3. Services and business logic
4. Screen layouts and user flow
5. State management approach
6. Sample data strategy

Focus on practical, implementable Flutter architecture.
    ''';

    try {
      return await AIProjectGenesisService._makeRequest(prompt);
    } catch (e) {
      return _createFallbackPlan(analysis);
    }
  }

  static Future<List<ProjectFile>> _generateCoreFiles(
    String projectName,
    String description,
    ProjectAnalysis analysis,
    String plan,
  ) async {
    final files = <ProjectFile>[];
    
    // Generate data models
    for (final model in analysis.dataModels) {
      files.add(await _generateDataModel(model, analysis));
    }
    
    // Generate services
    for (final service in analysis.services) {
      files.add(await _generateService(service, analysis));
    }
    
    // Generate theme
    files.add(_generateTheme(projectName, analysis));
    
    // Generate app constants
    files.add(_generateConstants(analysis));
    
    return files;
  }

  static Future<List<ProjectFile>> _generateScreenFiles(
    String projectName,
    String description,
    ProjectAnalysis analysis,
    String plan,
  ) async {
    final files = <ProjectFile>[];
    
    for (final screen in analysis.screens) {
      files.add(await _generateScreen(screen, analysis, plan));
    }
    
    return files;
  }

  static Future<List<ProjectFile>> _generateNavigation(
    String projectName,
    String description,
    ProjectAnalysis analysis,
    String plan,
  ) async {
    return [
      _generateAppRoutes(analysis),
      await _generateMainApp(projectName, analysis),
    ];
  }

  static List<ProjectFile> _generateConfigFiles(
    String projectName,
    ProjectAnalysis analysis,
  ) {
    return [
      _generatePubspecYaml(projectName, analysis),
      _generateReadme(projectName, analysis),
    ];
  }

  static Future<ProjectFile> _generateDataModel(String modelName, ProjectAnalysis analysis) async {
    final className = _toPascalCase(modelName);
    final fileName = _toSnakeCase(modelName);
    
    final content = '''
class $className {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const $className({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory $className.fromJson(Map<String, dynamic> json) {
    return $className(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  $className copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return $className(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is $className && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '$className{id: \$id, name: \$name}';
  }
}
''';

    return ProjectFile(
      path: 'lib/models/$fileName.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static Future<ProjectFile> _generateService(String serviceName, ProjectAnalysis analysis) async {
    final className = '${_toPascalCase(serviceName)}Service';
    final fileName = '${_toSnakeCase(serviceName)}_service';
    
    final content = '''
import 'dart:async';
import 'dart:math';

class $className {
  static final $className _instance = $className._internal();
  factory $className() => _instance;
  $className._internal();

  final _random = Random();
  
  /// Get sample data for demonstration
  Future<List<Map<String, dynamic>>> getSampleData() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));
    
    return List.generate(10, (index) => {
      'id': 'item_\${index + 1}',
      'name': 'Sample Item \${index + 1}',
      'createdAt': DateTime.now().subtract(Duration(days: _random.nextInt(30))).toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Create new item
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));
    
    return {
      ...data,
      'id': 'item_\${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Update existing item
  Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> data) async {
    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(600)));
    
    return {
      ...data,
      'id': id,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Delete item
  Future<void> deleteItem(String id) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(400)));
  }
}
''';

    return ProjectFile(
      path: 'lib/services/$fileName.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static ProjectFile _generateTheme(String projectName, ProjectAnalysis analysis) {
    final primaryColor = _getColorFromName(analysis.theme['primaryColor'] ?? 'blue');

    final content = '''
// AppTheme has been moved to lib/models/app_theme.dart
// Import it in your project files as needed:
// import 'package:$projectName/models/app_theme.dart';

// To use a custom primary color, call:
// AppTheme.getLightTheme(seedColor: $primaryColor)
// AppTheme.getDarkTheme(seedColor: $primaryColor)
''';

    return ProjectFile(
      path: 'lib/theme.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static ProjectFile _generateConstants(ProjectAnalysis analysis) {
    const content = '''
class AppConstants {
  // App Information
  static const String appName = 'Generated App';
  static const String appVersion = '1.0.0';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Sample Data Limits
  static const int maxItemsPerPage = 20;
  static const int defaultItemCount = 10;
}
''';

    return ProjectFile(
      path: 'lib/constants.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static Future<ProjectFile> _generateScreen(String screenName, ProjectAnalysis analysis, String plan) async {
    final className = '${_toPascalCase(screenName)}Screen';
    final fileName = '${_toSnakeCase(screenName)}_screen';
    
    final content = '''
import 'package:flutter/material.dart';

class $className extends StatefulWidget {
  const $className({super.key});

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Simulate data loading
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final sampleData = List.generate(10, (index) => {
        'id': 'item_\$index',
        'title': '${_toPascalCase(screenName)} Item \${index + 1}',
        'description': 'This is a sample ${screenName.toLowerCase()} item for demonstration.',
        'createdAt': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      });
      
      if (mounted) {
        setState(() {
          _items = sampleData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_toPascalCase(screenName)}'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState(context)
              : _buildItemList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first item',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(item['title'] ?? ''),
            subtitle: Text(item['description'] ?? ''),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteItem(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                _addItem(titleController.text.trim(), descController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addItem(String title, String description) {
    setState(() {
      _items.insert(0, {
        'id': 'item_\${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added successfully!')),
    );
  }

  void _deleteItem(int index) {
    final item = _items[index];
    setState(() {
      _items.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item "\${item['title']}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _items.insert(index, item);
            });
          },
        ),
      ),
    );
  }
}
''';

    return ProjectFile(
      path: 'lib/screens/$fileName.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static ProjectFile _generateAppRoutes(ProjectAnalysis analysis) {
    final routes = analysis.screens
        .map((screen) => '  static const String ${_toCamelCase(screen)} = \'/${_toSnakeCase(screen)}\';')
        .join('\n');
    
    final content = '''
class AppRoutes {
  static const String home = '/';
$routes

  static Map<String, String> get routeTitles => {
        home: 'Home',
${analysis.screens.map((screen) => '        ${_toCamelCase(screen)}: \'${_toPascalCase(screen)}\',').join('\n')}
      };
}
''';

    return ProjectFile(
      path: 'lib/routes.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static Future<ProjectFile> _generateMainApp(String projectName, ProjectAnalysis analysis) async {
    final imports = analysis.screens
        .map((screen) => 'import \'package:${_toSnakeCase(projectName)}/screens/${_toSnakeCase(screen)}_screen.dart\';')
        .join('\n');
    
    final routeEntries = analysis.screens
        .map((screen) => '        AppRoutes.${_toCamelCase(screen)}: (context) => const ${_toPascalCase(screen)}Screen(),')
        .join('\n');
    
    final content = '''
import 'package:flutter/material.dart';
import 'package:${_toSnakeCase(projectName)}/theme.dart';
import 'package:${_toSnakeCase(projectName)}/routes.dart';
import 'package:${_toSnakeCase(projectName)}/screens/home_screen.dart';
$imports

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$projectName',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
$routeEntries
      },
    );
  }
}
''';

    return ProjectFile(
      path: 'lib/main.dart',
      content: content,
      type: FileType.dart,
    );
  }

  static ProjectFile _generatePubspecYaml(String projectName, ProjectAnalysis analysis) {
    final dependencies = [
      '  flutter:',
      '    sdk: flutter',
      '  cupertino_icons: ^1.0.6',
    ];

    if (analysis.hasDatabase) {
      dependencies.add('  sqflite: ^2.3.0');
    }
    
    if (analysis.hasAPI) {
      dependencies.add('  http: ^1.1.0');
    }

    final content = '''
name: ${_toSnakeCase(projectName)}
description: "A new Flutter project generated by AI Project Genesis."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
${dependencies.join('\n')}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';

    return ProjectFile(
      path: 'pubspec.yaml',
      content: content,
      type: FileType.yaml,
    );
  }

  static ProjectFile _generateReadme(String projectName, ProjectAnalysis analysis) {
    final content = '''
# ${_toPascalCase(projectName)}

A Flutter app generated by AI Project Genesis.

## Features

${analysis.primaryFeatures.map((feature) => '- ${_toPascalCase(feature)}').join('\n')}

## App Type

${_toPascalCase(analysis.appType)} application

## Getting Started

1. Make sure you have Flutter installed
2. Run `flutter pub get` to install dependencies  
3. Run `flutter run` to start the app

## Generated Structure

- **Models**: Data structures in `lib/models/`
- **Services**: Business logic in `lib/services/`
- **Screens**: UI screens in `lib/screens/`
- **Theme**: App styling in `lib/theme.dart`

This app was generated with realistic sample data and is ready to run!
''';

    return ProjectFile(
      path: 'README.md',
      content: content,
      type: FileType.markdown,
    );
  }

  // Helper methods
  static String _toPascalCase(String text) {
    return text.split(RegExp(r'[_\s-]+'))
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  static String _toCamelCase(String text) {
    final pascal = _toPascalCase(text);
    return pascal.isEmpty ? '' : pascal[0].toLowerCase() + pascal.substring(1);
  }

  static String _toSnakeCase(String text) {
    return text
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'[_\s-]+'), '_')
        .toLowerCase();
  }

  static String _getColorFromName(String colorName) {
    final colors = {
      'red': 'Colors.red',
      'blue': 'Colors.blue',
      'green': 'Colors.green',
      'purple': 'Colors.purple',
      'orange': 'Colors.orange',
      'pink': 'Colors.pink',
      'teal': 'Colors.teal',
      'indigo': 'Colors.indigo',
      'cyan': 'Colors.cyan',
      'amber': 'Colors.amber',
    };
    return colors[colorName.toLowerCase()] ?? 'Colors.blue';
  }

  static ProjectAnalysis _createFallbackAnalysis(String description) {
    // Simple keyword-based analysis
    final lowerDesc = description.toLowerCase();
    
    String appType = 'utility';
    if (lowerDesc.contains(RegExp(r'fitness|gym|workout|exercise'))) {
      appType = 'health';
    } else if (lowerDesc.contains(RegExp(r'social|chat|friend|share'))) appType = 'social';
    else if (lowerDesc.contains(RegExp(r'shop|store|buy|sell|ecommerce'))) appType = 'ecommerce';
    else if (lowerDesc.contains(RegExp(r'task|todo|productivity|manage'))) appType = 'productivity';
    else if (lowerDesc.contains(RegExp(r'game|entertainment|fun'))) appType = 'entertainment';
    
    return ProjectAnalysis(
      appType: appType,
      primaryFeatures: ['Dashboard', 'List View', 'Detail View'],
      screens: ['home', 'list', 'detail', 'profile'],
      dataModels: ['item', 'user'],
      services: ['data', 'auth'],
      complexity: 'moderate',
      theme: {'primaryColor': 'blue', 'style': 'material'},
      hasAuth: lowerDesc.contains(RegExp(r'user|account|profile|login')),
      hasDatabase: true,
      hasAPI: lowerDesc.contains(RegExp(r'api|server|sync|cloud')),
      targetAudience: 'General users',
    );
  }

  static String _createFallbackPlan(ProjectAnalysis analysis) {
    return '''
Implementation Plan for ${analysis.appType} app:

1. **App Structure**: Bottom navigation with ${analysis.screens.length} main sections
2. **Data Models**: ${analysis.dataModels.join(', ')} with JSON serialization
3. **Services**: ${analysis.services.join(', ')} with async operations and error handling
4. **Screens**: Home dashboard, list views with search/filter, detail pages
5. **State Management**: StatefulWidget with setState for simplicity
6. **Sample Data**: Realistic mock data for immediate functionality
    ''';
  }

  // Private API methods
  static Future<String> _makeRequest(String prompt) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final response = await http.post(
      Uri.parse(OpenAIConfig.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': OpenAIConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert Flutter developer who creates complete, production-ready mobile apps with proper architecture, realistic sample data, and beautiful UI.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': OpenAIConfig.maxTokens,
        'temperature': OpenAIConfig.temperature,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    
    if (data['choices'] == null || data['choices'].isEmpty) {
      throw Exception('No response from OpenAI API');
    }

    return data['choices'][0]['message']['content'] ?? '';
  }

  static Future<String> _makeRequestWithJson(String prompt) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final response = await http.post(
      Uri.parse(OpenAIConfig.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': OpenAIConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert Flutter developer who analyzes app requirements and provides structured JSON responses for project generation.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': OpenAIConfig.maxTokens,
        'temperature': OpenAIConfig.temperature,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] ?? '';
  }
}

class ProjectAnalysis {
  final String appType;
  final List<String> primaryFeatures;
  final List<String> screens;
  final List<String> dataModels;
  final List<String> services;
  final String complexity;
  final Map<String, String> theme;
  final bool hasAuth;
  final bool hasDatabase;
  final bool hasAPI;
  final String targetAudience;

  ProjectAnalysis({
    required this.appType,
    required this.primaryFeatures,
    required this.screens,
    required this.dataModels,
    required this.services,
    required this.complexity,
    required this.theme,
    required this.hasAuth,
    required this.hasDatabase,
    required this.hasAPI,
    required this.targetAudience,
  });

  factory ProjectAnalysis.fromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      return ProjectAnalysis(
        appType: data['appType'] ?? 'utility',
        primaryFeatures: List<String>.from(data['primaryFeatures'] ?? ['Dashboard', 'List View']),
        screens: List<String>.from(data['screens'] ?? ['home', 'list']),
        dataModels: List<String>.from(data['dataModels'] ?? ['item']),
        services: List<String>.from(data['services'] ?? ['data']),
        complexity: data['complexity'] ?? 'moderate',
        theme: Map<String, String>.from(data['theme'] ?? {'primaryColor': 'blue', 'style': 'material'}),
        hasAuth: data['hasAuth'] ?? false,
        hasDatabase: data['hasDatabase'] ?? true,
        hasAPI: data['hasAPI'] ?? false,
        targetAudience: data['targetAudience'] ?? 'General users',
      );
    } catch (e) {
      // Fallback to basic analysis if JSON parsing fails
      return ProjectAnalysis(
        appType: 'utility',
        primaryFeatures: ['Dashboard', 'List View'],
        screens: ['home', 'list', 'detail'],
        dataModels: ['item', 'user'],
        services: ['data'],
        complexity: 'moderate',
        theme: {'primaryColor': 'blue', 'style': 'material'},
        hasAuth: false,
        hasDatabase: true,
        hasAPI: false,
        targetAudience: 'General users',
      );
    }
  }
}