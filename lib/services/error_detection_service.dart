import 'dart:async';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

enum ErrorSeverity { error, warning, info, hint }
enum ErrorCategory { syntax, import, type, logic, performance, style }

class CodeError {
  final String message;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final int line;
  final int column;
  final String filePath;
  final String? suggestion;
  final String? autoFix;
  final bool canAutoFix;

  const CodeError({
    required this.message,
    required this.severity,
    required this.category,
    required this.line,
    required this.column,
    required this.filePath,
    this.suggestion,
    this.autoFix,
    this.canAutoFix = false,
  });

  String get severityIcon {
    switch (severity) {
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.hint:
        return '💡';
    }
  }

  String get categoryIcon {
    switch (category) {
      case ErrorCategory.syntax:
        return '🔴';
      case ErrorCategory.import:
        return '📦';
      case ErrorCategory.type:
        return '🏷️';
      case ErrorCategory.logic:
        return '🧠';
      case ErrorCategory.performance:
        return '⚡';
      case ErrorCategory.style:
        return '🎨';
    }
  }
}

class LiveErrorDetectionService {
  static final LiveErrorDetectionService _instance = LiveErrorDetectionService._internal();
  factory LiveErrorDetectionService() => _instance;
  LiveErrorDetectionService._internal();

  final StreamController<List<CodeError>> _errorsController = StreamController<List<CodeError>>.broadcast();
  final StreamController<Map<String, List<CodeError>>> _fileErrorsController = StreamController<Map<String, List<CodeError>>>.broadcast();
  
  Stream<List<CodeError>> get errorsStream => _errorsController.stream;
  Stream<Map<String, List<CodeError>>> get fileErrorsStream => _fileErrorsController.stream;

  List<CodeError> _currentErrors = [];
  final Map<String, List<CodeError>> _fileErrors = {};
  Timer? _analysisTimer;

  void analyzeProject(FlutterProject project) {
    _analysisTimer?.cancel();
    _analysisTimer = Timer(const Duration(milliseconds: 500), () {
      _performAnalysis(project);
    });
  }

  void analyzeFile(ProjectFile file) {
    final errors = _analyzeFileContent(file);
    _fileErrors[file.path] = errors;
    _updateGlobalErrors();
    _fileErrorsController.add(_fileErrors);
  }

  void _performAnalysis(FlutterProject project) {
    final allErrors = <CodeError>[];
    _fileErrors.clear();

    for (final file in project.files) {
      if (!file.isDirectory && file.isDartFile) {
        final fileErrors = _analyzeFileContent(file);
        _fileErrors[file.path] = fileErrors;
        allErrors.addAll(fileErrors);
      }
    }

    _currentErrors = allErrors;
    _errorsController.add(_currentErrors);
    _fileErrorsController.add(_fileErrors);
  }

  List<CodeError> _analyzeFileContent(ProjectFile file) {
    final errors = <CodeError>[];
    final lines = file.content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Syntax analysis
      errors.addAll(_analyzeSyntax(line, lineNumber, file.path));
      
      // Import analysis
      errors.addAll(_analyzeImports(line, lineNumber, file.path));
      
      // Type analysis
      errors.addAll(_analyzeTypes(line, lineNumber, file.path));
      
      // Logic analysis
      errors.addAll(_analyzeLogic(line, lineNumber, file.path));
      
      // Performance analysis
      errors.addAll(_analyzePerformance(line, lineNumber, file.path));
      
      // Style analysis
      errors.addAll(_analyzeStyle(line, lineNumber, file.path));
    }

    return errors;
  }

  List<CodeError> _analyzeSyntax(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    // Missing semicolon
    if (line.trim().isNotEmpty && 
        !line.trim().endsWith(';') && 
        !line.trim().endsWith('{') && 
        !line.trim().endsWith('}') &&
        !line.contains('//') &&
        !line.contains('import') &&
        !line.contains('class') &&
        !line.contains('void') &&
        !line.contains('if') &&
        !line.contains('for') &&
        !line.contains('while')) {
      
      if (line.contains('return') || 
          line.contains('print') || 
          line.contains('=') && !line.contains('==')) {
        errors.add(CodeError(
          message: 'Missing semicolon',
          severity: ErrorSeverity.error,
          category: ErrorCategory.syntax,
          line: lineNumber,
          column: line.length,
          filePath: filePath,
          suggestion: 'Add semicolon at end of statement',
          autoFix: '${line.trim()};',
          canAutoFix: true,
        ));
      }
    }

    // Unmatched brackets
    final openBrackets = line.split('').where((c) => c == '(' || c == '[' || c == '{').length;
    final closeBrackets = line.split('').where((c) => c == ')' || c == ']' || c == '}').length;
    if (openBrackets != closeBrackets) {
      errors.add(CodeError(
        message: 'Unmatched brackets',
        severity: ErrorSeverity.error,
        category: ErrorCategory.syntax,
        line: lineNumber,
        column: line.contains('(') ? line.indexOf('(') : line.indexOf('['),
        filePath: filePath,
        suggestion: 'Ensure all brackets are properly matched',
      ));
    }

    return errors;
  }

  List<CodeError> _analyzeImports(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    if (line.trim().startsWith('import ')) {
      // Unused import detection (simplified)
      if (line.contains("'dart:io'") && !filePath.endsWith('_test.dart')) {
        errors.add(CodeError(
          message: 'dart:io import not allowed in Flutter apps',
          severity: ErrorSeverity.warning,
          category: ErrorCategory.import,
          line: lineNumber,
          column: 0,
          filePath: filePath,
          suggestion: 'Use platform-specific implementations or remove import',
        ));
      }

      // Relative import suggestion
      if (line.contains('../')) {
        errors.add(CodeError(
          message: 'Consider using absolute imports instead of relative imports',
          severity: ErrorSeverity.hint,
          category: ErrorCategory.import,
          line: lineNumber,
          column: 0,
          filePath: filePath,
          suggestion: 'Use package: imports for better maintainability',
        ));
      }
    }

    return errors;
  }

  List<CodeError> _analyzeTypes(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    // Missing type annotations
    if (line.contains('var ') && !line.contains('=')) {
      errors.add(CodeError(
        message: 'Consider adding explicit type annotation',
        severity: ErrorSeverity.hint,
        category: ErrorCategory.type,
        line: lineNumber,
        column: line.indexOf('var'),
        filePath: filePath,
        suggestion: 'Add explicit type for better code documentation',
      ));
    }

    // Dynamic usage warning
    if (line.contains('dynamic')) {
      errors.add(CodeError(
        message: 'Avoid using dynamic when possible',
        severity: ErrorSeverity.warning,
        category: ErrorCategory.type,
        line: lineNumber,
        column: line.indexOf('dynamic'),
        filePath: filePath,
        suggestion: 'Use specific types for better type safety',
      ));
    }

    return errors;
  }

  List<CodeError> _analyzeLogic(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    // Potential null pointer
    if (line.contains('.') && !line.contains('?.') && !line.contains('!')) {
      final beforeDot = line.substring(0, line.indexOf('.')).trim();
      if (beforeDot.isNotEmpty && !beforeDot.contains('this') && !beforeDot.contains('super')) {
        errors.add(CodeError(
          message: 'Consider null safety',
          severity: ErrorSeverity.hint,
          category: ErrorCategory.logic,
          line: lineNumber,
          column: line.indexOf('.'),
          filePath: filePath,
          suggestion: 'Use null-aware operators (?.) or null assertion (!)',
        ));
      }
    }

    // Empty catch blocks
    if (line.trim() == 'catch (e) {' && lineNumber > 1) {
      errors.add(CodeError(
        message: 'Empty catch block',
        severity: ErrorSeverity.warning,
        category: ErrorCategory.logic,
        line: lineNumber,
        column: 0,
        filePath: filePath,
        suggestion: 'Handle the exception or at least log it',
      ));
    }

    return errors;
  }

  List<CodeError> _analyzePerformance(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    // Inefficient string concatenation
    if (line.contains('+') && line.contains('"')) {
      final parts = line.split('+');
      if (parts.length > 2) {
        errors.add(CodeError(
          message: 'Consider using string interpolation',
          severity: ErrorSeverity.hint,
          category: ErrorCategory.performance,
          line: lineNumber,
          column: line.indexOf('+'),
          filePath: filePath,
          suggestion: 'Use \${} for better performance',
        ));
      }
    }

    // Unnecessary rebuilds in build method
    if (line.contains('setState') && filePath.contains('widget')) {
      errors.add(CodeError(
        message: 'setState in build method may cause infinite rebuilds',
        severity: ErrorSeverity.warning,
        category: ErrorCategory.performance,
        line: lineNumber,
        column: line.indexOf('setState'),
        filePath: filePath,
        suggestion: 'Move setState calls to event handlers',
      ));
    }

    return errors;
  }

  List<CodeError> _analyzeStyle(String line, int lineNumber, String filePath) {
    final errors = <CodeError>[];

    // Naming conventions
    if (RegExp(r'class\s+[a-z]').hasMatch(line)) {
      errors.add(CodeError(
        message: 'Class names should start with uppercase',
        severity: ErrorSeverity.hint,
        category: ErrorCategory.style,
        line: lineNumber,
        column: line.indexOf('class'),
        filePath: filePath,
        suggestion: 'Use PascalCase for class names',
      ));
    }

    // Long lines
    if (line.length > 120) {
      errors.add(CodeError(
        message: 'Line too long (\${line.length} characters)',
        severity: ErrorSeverity.hint,
        category: ErrorCategory.style,
        line: lineNumber,
        column: 120,
        filePath: filePath,
        suggestion: 'Break long lines for better readability',
      ));
    }

    // Missing const keywords
    if (line.contains('new ') && !line.contains('const ')) {
      errors.add(CodeError(
        message: 'Unnecessary new keyword',
        severity: ErrorSeverity.hint,
        category: ErrorCategory.style,
        line: lineNumber,
        column: line.indexOf('new'),
        filePath: filePath,
        suggestion: 'Remove new keyword (Dart 2+ style)',
        autoFix: line.replaceAll('new ', ''),
        canAutoFix: true,
      ));
    }

    return errors;
  }

  void _updateGlobalErrors() {
    final allErrors = <CodeError>[];
    for (final fileErrors in _fileErrors.values) {
      allErrors.addAll(fileErrors);
    }
    _currentErrors = allErrors;
    _errorsController.add(_currentErrors);
  }

  // Auto-fix functionality
  String applyAutoFix(ProjectFile file, CodeError error) {
    if (!error.canAutoFix || error.autoFix == null) {
      throw Exception('This error cannot be auto-fixed');
    }

    final lines = file.content.split('\n');
    if (error.line <= lines.length) {
      lines[error.line - 1] = error.autoFix!;
      return lines.join('\n');
    }

    throw Exception('Invalid line number for auto-fix');
  }

  List<CodeError> getErrorsForFile(String filePath) {
    return _fileErrors[filePath] ?? [];
  }

  List<CodeError> get currentErrors => List.unmodifiable(_currentErrors);

  void dispose() {
    _analysisTimer?.cancel();
    _errorsController.close();
    _fileErrorsController.close();
  }
}