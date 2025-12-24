import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kre8tions/models/flutter_project.dart';

class OpenAIConfig {
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');
  
  static const String model = 'gpt-4o';
  static const int maxTokens = 4096;
  static const double temperature = 0.7;

  static bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;
}

class OpenAIService {
  static Future<String> improveCode({
    required String code,
    required String fileName,
    String? context,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeImprovementPrompt(code, fileName, context);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to improve code: \$e');
    }
  }

  static Future<String> generateCode({
    required String description,
    required String fileName,
    String? projectContext,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeGenerationPrompt(description, fileName, projectContext);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate code: \$e');
    }
  }

  static Future<String> explainCode({
    required String code,
    required String fileName,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final prompt = _buildCodeExplanationPrompt(code, fileName);
    
    try {
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to explain code: \$e');
    }
  }

  static Future<String> _makeRequest(String prompt) async {
    final response = await http.post(
      Uri.parse(OpenAIConfig.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': OpenAIConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert Flutter developer. Provide clean, efficient, and well-documented code solutions.'
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
      throw Exception('OpenAI API error: \${response.statusCode} - \${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    
    if (data['choices'] == null || data['choices'].isEmpty) {
      throw Exception('No response from OpenAI API');
    }

    return data['choices'][0]['message']['content'] ?? '';
  }

  static String _buildCodeImprovementPrompt(String code, String fileName, String? context) {
    return '''
Please analyze and improve the following Flutter/Dart code from file "$fileName":

\${context != null ? "Project Context: \$context\n\n" : ""}Code to improve:
```dart
\$code
```

Please provide improvements focusing on:
1. Code quality and best practices
2. Performance optimizations
3. Better error handling
4. Code documentation
5. Flutter/Dart specific improvements

Return only the improved code without explanations.
    ''';
  }

  static String _buildCodeGenerationPrompt(String description, String fileName, String? projectContext) {
    return '''
Generate Flutter/Dart code for file "$fileName" based on this description:

\$description

\${projectContext != null ? "Project Context: \$projectContext\n\n" : ""}

Please ensure the code:
1. Follows Flutter best practices
2. Uses Material Design 3 components
3. Includes proper error handling
4. Is well-documented
5. Is production-ready

Return only the code without explanations.
    ''';
  }

  static String _buildCodeExplanationPrompt(String code, String fileName) {
    return '''
Please explain the following Flutter/Dart code from file "$fileName":

```dart
\$code
```

Provide a clear explanation covering:
1. What this code does
2. How it works
3. Key Flutter concepts used
4. Any potential issues or improvements
5. How it fits in a typical Flutter app structure

Keep the explanation concise but comprehensive.
    ''';
  }

  // SYSTEMATIC GENERATION - Mirror Hologram's approach
  static Future<SystematicGenerationResult> generateSystematically({
    required String task,
    required FlutterProject project,
    Function(SystematicStep)? onStepUpdate,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing. Please set environment variables.');
    }

    final result = SystematicGenerationResult();
    
    try {
      // Step 1: Analyze & Plan
      onStepUpdate?.call(SystematicStep.analyzing);
      final analysisPrompt = _buildAnalysisPrompt(task, project);
      final analysis = await _makeRequest(analysisPrompt);
      result.analysis = analysis;
      
      // Step 2: Generate Implementation Plan
      onStepUpdate?.call(SystematicStep.planning);
      final planPrompt = _buildPlanningPrompt(task, project, analysis);
      final plan = await _makeRequest(planPrompt);
      result.plan = plan;
      
      // Step 3: Generate Code
      onStepUpdate?.call(SystematicStep.generating);
      final codePrompt = _buildSystematicCodePrompt(task, project, analysis, plan);
      final code = await _makeRequest(codePrompt);
      result.generatedCode = code;
      
      // Step 4: Create File Operations
      onStepUpdate?.call(SystematicStep.organizing);
      final fileOpsPrompt = _buildFileOperationsPrompt(code, project);
      final fileOpsResponse = await _makeRequestWithJson(fileOpsPrompt);
      result.fileOperations = _parseFileOperations(fileOpsResponse);
      
      result.success = true;
      onStepUpdate?.call(SystematicStep.complete);
      
    } catch (e) {
      result.success = false;
      result.error = e.toString();
      onStepUpdate?.call(SystematicStep.error);
    }
    
    return result;
  }

  static Future<String> fixCompilationErrors({
    required String code,
    required String fileName,
    required String errors,
    required FlutterProject project,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw Exception('OpenAI configuration is missing.');
    }

    final prompt = _buildErrorFixingPrompt(code, fileName, errors, project);
    return await _makeRequest(prompt);
  }

  static Future<String> _makeRequestWithJson(String prompt) async {
    final response = await http.post(
      Uri.parse(OpenAIConfig.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': OpenAIConfig.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert Flutter developer who provides systematic, step-by-step code generation. Always output valid JSON when requested.'
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
      throw Exception('OpenAI API error: \${response.statusCode} - \${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] ?? '';
  }

  // SYSTEMATIC PROMPTS - Mirror Hologram's methodology
  static String _buildAnalysisPrompt(String task, FlutterProject project) {
    final projectStructure = _getProjectStructure(project);
    
    return '''
ANALYSIS PHASE: Analyze the following Flutter development task systematically.

TASK: \$task

PROJECT CONTEXT:
\$projectStructure

Provide a comprehensive analysis covering:
1. Understanding of the requirements
2. Existing project structure assessment
3. Dependencies that may be needed
4. Potential challenges and considerations
5. Files that will need modification/creation
6. Integration points with existing code

Be thorough and systematic in your analysis.
    ''';
  }

  static String _buildPlanningPrompt(String task, FlutterProject project, String analysis) {
    return '''
PLANNING PHASE: Create a detailed implementation plan based on the analysis.

TASK: \$task

ANALYSIS:
\$analysis

Create a step-by-step implementation plan including:
1. Order of operations (which files to create/modify first)
2. Code structure and architecture decisions
3. Key classes/widgets to implement
4. Error handling strategy
5. Testing considerations
6. Integration steps

Provide a clear, actionable plan that ensures systematic implementation.
    ''';
  }

  static String _buildSystematicCodePrompt(String task, FlutterProject project, String analysis, String plan) {
    final projectStructure = _getProjectStructure(project);
    
    return '''
CODE GENERATION PHASE: Generate production-ready Flutter code based on analysis and plan.

TASK: \$task

ANALYSIS:
\$analysis

PLAN:
\$plan

PROJECT STRUCTURE:
\$projectStructure

Generate complete, production-ready code that:
1. Follows Flutter best practices and conventions
2. Uses Material Design 3 components
3. Includes proper error handling
4. Has comprehensive documentation
5. Integrates seamlessly with existing project structure
6. Uses absolute imports (package:codewhisper/...)
7. Follows the established project patterns
8. Is compilation-ready without errors

Return ONLY the code files needed, properly formatted.
    ''';
  }

  static String _buildFileOperationsPrompt(String generatedCode, FlutterProject project) {
    return '''
FILE OPERATIONS PHASE: Analyze the generated code and determine file operations needed.

GENERATED CODE:
\$generatedCode

Analyze the code and return a JSON object with the following structure:
{
  "operations": [
    {
      "type": "create" | "modify" | "update",
      "filePath": "relative/path/to/file.dart",
      "content": "complete file content",
      "description": "What this operation does"
    }
  ]
}

Ensure:
1. All file paths are correct relative to project root
2. Content is complete and ready to write
3. Operations are in correct execution order
4. All necessary imports are included
    ''';
  }

  static String _buildErrorFixingPrompt(String code, String fileName, String errors, FlutterProject project) {
    final projectStructure = _getProjectStructure(project);
    
    return '''
ERROR FIXING PHASE: Fix compilation errors systematically.

FILE: \$fileName

CODE WITH ERRORS:
```dart
\$code
```

COMPILATION ERRORS:
\$errors

PROJECT CONTEXT:
\$projectStructure

Analyze the errors and provide the corrected code that:
1. Fixes all compilation errors
2. Maintains the original functionality
3. Follows Flutter best practices
4. Uses proper imports and dependencies
5. Is production-ready

Return ONLY the corrected code without explanations.
    ''';
  }

  static String _getProjectStructure(FlutterProject project) {
    final buffer = StringBuffer();
    buffer.writeln('PROJECT: \${project.name}');
    buffer.writeln('FILES:');
    
    for (final file in project.files) {
      if (file.fileName.endsWith('.dart')) {
        buffer.writeln('- \${file.filePath}');
      }
    }
    
    return buffer.toString();
  }

  static List<FileOperation> _parseFileOperations(String jsonResponse) {
    try {
      final data = jsonDecode(jsonResponse);
      final operations = data['operations'] as List;
      
      return operations.map((op) => FileOperation(
        type: op['type'],
        filePath: op['filePath'],
        content: op['content'],
        description: op['description'] ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Failed to parse file operations: \$e');
    }
  }
}

// SYSTEMATIC GENERATION MODELS
class SystematicGenerationResult {
  String? analysis;
  String? plan;
  String? generatedCode;
  List<FileOperation> fileOperations = [];
  bool success = false;
  String? error;
}

class FileOperation {
  final String type; // create, modify, update
  final String filePath;
  final String content;
  final String description;
  
  FileOperation({
    required this.type,
    required this.filePath,
    required this.content,
    required this.description,
  });
}

enum SystematicStep {
  analyzing('🔍 Analyzing requirements...'),
  planning('📋 Creating implementation plan...'),
  generating('⚡ Generating code...'),
  organizing('📁 Organizing file operations...'),
  complete('✅ Generation complete!'),
  error('❌ Error occurred');
  
  const SystematicStep(this.message);
  final String message;
}