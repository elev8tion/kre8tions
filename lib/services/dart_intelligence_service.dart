import 'package:flutter/material.dart';

/// Advanced Dart/Flutter Code Intelligence Service
/// Provides syntax highlighting, autocomplete, error detection, and more
class DartIntelligenceService {
  
  // Dart/Flutter Keywords for syntax highlighting
  static const Set<String> _keywords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 
    'class', 'const', 'continue', 'default', 'deferred', 'do', 'dynamic', 
    'else', 'enum', 'export', 'extends', 'external', 'factory', 'false', 
    'final', 'finally', 'for', 'get', 'if', 'implements', 'import', 'in', 
    'is', 'late', 'library', 'mixin', 'new', 'null', 'operator', 'part', 
    'required', 'rethrow', 'return', 'set', 'static', 'super', 'switch', 
    'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with'
  };

  static const Set<String> _flutterWidgets = {
    'Widget', 'StatelessWidget', 'StatefulWidget', 'Container', 'Column', 'Row',
    'Scaffold', 'AppBar', 'Text', 'TextButton', 'ElevatedButton', 'IconButton',
    'Icon', 'Image', 'ListView', 'GridView', 'Stack', 'Positioned', 'Padding',
    'Margin', 'SizedBox', 'Expanded', 'Flexible', 'Center', 'Align', 'Card',
    'Material', 'InkWell', 'GestureDetector', 'AnimatedContainer', 'Hero',
    'Navigator', 'MaterialApp', 'CupertinoApp', 'Theme', 'MediaQuery'
  };

  static const Set<String> _dartTypes = {
    'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Object', 
    'Function', 'Future', 'Stream', 'Iterable', 'Duration', 'DateTime'
  };

  static const Set<String> _flutterImports = {
    'package:flutter/material.dart',
    'package:flutter/cupertino.dart',
    'package:flutter/services.dart',
    'package:flutter/widgets.dart',
    'dart:async',
    'dart:convert',
    'dart:io',
    'dart:math',
    'dart:collection'
  };

  /// Generate syntax highlighted spans for code
  static List<TextSpan> generateSyntaxHighlighting(String code, ThemeData theme) {
    List<TextSpan> spans = [];
    
    // Colors for different syntax elements
    final keywordColor = theme.brightness == Brightness.light 
        ? Colors.purple[700]! : Colors.purple[300]!;
    final stringColor = theme.brightness == Brightness.light 
        ? Colors.green[700]! : Colors.green[300]!;
    final commentColor = theme.brightness == Brightness.light 
        ? Colors.grey[600]! : Colors.grey[400]!;
    final widgetColor = theme.brightness == Brightness.light 
        ? Colors.blue[700]! : Colors.blue[300]!;
    final typeColor = theme.brightness == Brightness.light 
        ? Colors.teal[700]! : Colors.teal[300]!;
    final numberColor = theme.brightness == Brightness.light 
        ? Colors.orange[700]! : Colors.orange[300]!;

    final lines = code.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      int i = 0;
      
      while (i < line.length) {
        // Skip whitespace
        if (line[i].trim().isEmpty) {
          spans.add(TextSpan(text: line[i]));
          i++;
          continue;
        }
        
        // Comments
        if (i < line.length - 1 && line.substring(i, i + 2) == '//') {
          spans.add(TextSpan(
            text: line.substring(i),
            style: TextStyle(color: commentColor, fontStyle: FontStyle.italic),
          ));
          break;
        }
        
        // Multi-line comments
        if (i < line.length - 1 && line.substring(i, i + 2) == '/*') {
          int endIndex = line.indexOf('*/', i + 2);
          if (endIndex == -1) endIndex = line.length;
          spans.add(TextSpan(
            text: line.substring(i, endIndex + 2),
            style: TextStyle(color: commentColor, fontStyle: FontStyle.italic),
          ));
          i = endIndex + 2;
          continue;
        }
        
        // Strings
        if (line[i] == '"' || line[i] == "'") {
          final quote = line[i];
          int endIndex = i + 1;
          while (endIndex < line.length && line[endIndex] != quote) {
            if (line[endIndex] == '\\') endIndex++; // Skip escaped characters
            endIndex++;
          }
          if (endIndex < line.length) endIndex++; // Include closing quote
          
          spans.add(TextSpan(
            text: line.substring(i, endIndex),
            style: TextStyle(color: stringColor),
          ));
          i = endIndex;
          continue;
        }
        
        // Numbers
        if (RegExp(r'^\d').hasMatch(line[i])) {
          int endIndex = i;
          while (endIndex < line.length && 
                 RegExp(r'[\d\.]').hasMatch(line[endIndex])) {
            endIndex++;
          }
          spans.add(TextSpan(
            text: line.substring(i, endIndex),
            style: TextStyle(color: numberColor, fontWeight: FontWeight.w600),
          ));
          i = endIndex;
          continue;
        }
        
        // Words (keywords, widgets, types)
        if (RegExp(r'^[a-zA-Z_]').hasMatch(line[i])) {
          int endIndex = i;
          while (endIndex < line.length && 
                 RegExp(r'[a-zA-Z0-9_]').hasMatch(line[endIndex])) {
            endIndex++;
          }
          
          final word = line.substring(i, endIndex);
          Color? wordColor;
          FontWeight? weight;
          
          if (_keywords.contains(word)) {
            wordColor = keywordColor;
            weight = FontWeight.w700;
          } else if (_flutterWidgets.contains(word)) {
            wordColor = widgetColor;
            weight = FontWeight.w600;
          } else if (_dartTypes.contains(word)) {
            wordColor = typeColor;
            weight = FontWeight.w600;
          }
          
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: wordColor, fontWeight: weight),
          ));
          i = endIndex;
          continue;
        }
        
        // Default character
        spans.add(TextSpan(text: line[i]));
        i++;
      }
      
      // Add newline except for last line
      if (lineIndex < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }

  /// Get autocomplete suggestions based on current context
  static List<AutocompleteSuggestion> getAutocompleteSuggestions(
    String code, 
    int cursorPosition
  ) {
    List<AutocompleteSuggestion> suggestions = [];
    
    // Get word at cursor position
    final wordAtCursor = _getWordAtPosition(code, cursorPosition);
    
    if (wordAtCursor.isEmpty) return suggestions;
    
    // Widget suggestions
    for (final widget in _flutterWidgets) {
      if (widget.toLowerCase().startsWith(wordAtCursor.toLowerCase())) {
        suggestions.add(AutocompleteSuggestion(
          text: widget,
          type: SuggestionType.widget,
          description: 'Flutter Widget',
          insertText: _getWidgetInsertText(widget),
        ));
      }
    }
    
    // Keyword suggestions
    for (final keyword in _keywords) {
      if (keyword.toLowerCase().startsWith(wordAtCursor.toLowerCase())) {
        suggestions.add(AutocompleteSuggestion(
          text: keyword,
          type: SuggestionType.keyword,
          description: 'Dart keyword',
          insertText: keyword,
        ));
      }
    }
    
    // Type suggestions
    for (final type in _dartTypes) {
      if (type.toLowerCase().startsWith(wordAtCursor.toLowerCase())) {
        suggestions.add(AutocompleteSuggestion(
          text: type,
          type: SuggestionType.type,
          description: 'Dart type',
          insertText: type,
        ));
      }
    }
    
    // Import suggestions
    if (_isImportContext(code, cursorPosition)) {
      for (final import in _flutterImports) {
        if (import.toLowerCase().contains(wordAtCursor.toLowerCase())) {
          suggestions.add(AutocompleteSuggestion(
            text: import,
            type: SuggestionType.import,
            description: 'Import statement',
            insertText: import,
          ));
        }
      }
    }
    
    return suggestions..sort((a, b) => a.text.compareTo(b.text));
  }

  /// Detect and return code errors
  static List<CodeError> detectErrors(String code) {
    List<CodeError> errors = [];
    final lines = code.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Missing semicolons
      if (line.isNotEmpty && 
          !line.endsWith(';') && 
          !line.endsWith('{') && 
          !line.endsWith('}') &&
          !line.startsWith('//') &&
          !line.startsWith('/*') &&
          !line.contains('=>') &&
          !_isControlStructure(line)) {
        errors.add(CodeError(
          line: i + 1,
          message: 'Missing semicolon',
          type: ErrorType.syntax,
          severity: ErrorSeverity.error,
        ));
      }
      
      // Unclosed strings
      int quoteCount = 0;
      for (int j = 0; j < line.length; j++) {
        if (line[j] == '"' && (j == 0 || line[j - 1] != '\\')) {
          quoteCount++;
        }
      }
      if (quoteCount % 2 != 0) {
        errors.add(CodeError(
          line: i + 1,
          message: 'Unclosed string literal',
          type: ErrorType.syntax,
          severity: ErrorSeverity.error,
        ));
      }
    }
    
    return errors;
  }

  /// Format Dart code with proper indentation
  static String formatCode(String code) {
    final lines = code.split('\n');
    final formattedLines = <String>[];
    int indentLevel = 0;
    
    for (String line in lines) {
      final trimmed = line.trim();
      
      // Decrease indent for closing braces
      if (trimmed.startsWith('}')) {
        indentLevel = (indentLevel - 1).clamp(0, 20);
      }
      
      // Add formatted line with proper indentation
      if (trimmed.isNotEmpty) {
        formattedLines.add('  ' * indentLevel + trimmed);
      } else {
        formattedLines.add('');
      }
      
      // Increase indent for opening braces
      if (trimmed.endsWith('{')) {
        indentLevel++;
      }
    }
    
    return formattedLines.join('\n');
  }

  /// Get missing imports for the current code
  static List<String> suggestImports(String code) {
    List<String> suggestions = [];
    
    // Check for Flutter widgets usage
    for (final widget in _flutterWidgets) {
      if (code.contains(widget) && 
          !code.contains("import 'package:flutter/material.dart'")) {
        suggestions.add("import 'package:flutter/material.dart';");
        break;
      }
    }
    
    // Check for async/await usage
    if ((code.contains('async') || code.contains('await')) && 
        !code.contains("import 'dart:async'")) {
      suggestions.add("import 'dart:async';");
    }
    
    // Check for JSON usage
    if (code.contains('jsonEncode') || code.contains('jsonDecode')) {
      suggestions.add("import 'dart:convert';");
    }
    
    return suggestions;
  }

  /// 🚀 GO-TO-DEFINITION FUNCTIONALITY
  
  /// Find definition location for symbol at cursor position
  static DefinitionResult? findDefinition(
    String code, 
    int cursorPosition, 
    Map<String, String> projectFiles
  ) {
    final symbol = _getWordAtPosition(code, cursorPosition);
    if (symbol.isEmpty) return null;
    
    // First check in current file for local definitions
    final localDefinition = _findLocalDefinition(code, symbol, cursorPosition);
    if (localDefinition != null) return localDefinition;
    
    // Search across project files
    return _findDefinitionInProject(symbol, projectFiles);
  }

  /// Find all references to a symbol across the project
  static List<ReferenceLocation> findReferences(
    String symbol, 
    Map<String, String> projectFiles
  ) {
    List<ReferenceLocation> references = [];
    
    for (final entry in projectFiles.entries) {
      final filePath = entry.key;
      final content = entry.value;
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        int index = 0;
        
        while ((index = line.indexOf(symbol, index)) != -1) {
          // Ensure it's a whole word, not part of another identifier
          final isValidReference = _isWholeWordMatch(line, index, symbol.length);
          
          if (isValidReference) {
            references.add(ReferenceLocation(
              filePath: filePath,
              line: i + 1,
              column: index + 1,
              context: line.trim(),
            ));
          }
          index += symbol.length;
        }
      }
    }
    
    return references;
  }

  /// Build symbol index for the entire project
  static Map<String, List<SymbolDefinition>> buildSymbolIndex(
    Map<String, String> projectFiles
  ) {
    Map<String, List<SymbolDefinition>> symbolIndex = {};
    
    for (final entry in projectFiles.entries) {
      final filePath = entry.key;
      final content = entry.value;
      final symbols = _extractSymbols(content, filePath);
      
      for (final symbol in symbols) {
        symbolIndex.putIfAbsent(symbol.name, () => []);
        symbolIndex[symbol.name]!.add(symbol);
      }
    }
    
    return symbolIndex;
  }

  /// Get hover information for symbol at position
  static HoverInfo? getHoverInfo(
    String code, 
    int cursorPosition,
    Map<String, List<SymbolDefinition>> symbolIndex
  ) {
    final symbol = _getWordAtPosition(code, cursorPosition);
    if (symbol.isEmpty) return null;
    
    // Check if it's a known Flutter widget
    if (_flutterWidgets.contains(symbol)) {
      return HoverInfo(
        symbol: symbol,
        type: 'Flutter Widget',
        documentation: _getFlutterWidgetDocumentation(symbol),
        signature: '$symbol extends Widget',
      );
    }
    
    // Check if it's a Dart type
    if (_dartTypes.contains(symbol)) {
      return HoverInfo(
        symbol: symbol,
        type: 'Dart Type',
        documentation: _getDartTypeDocumentation(symbol),
        signature: 'class $symbol',
      );
    }
    
    // Check project symbols
    final definitions = symbolIndex[symbol];
    if (definitions != null && definitions.isNotEmpty) {
      final definition = definitions.first;
      return HoverInfo(
        symbol: symbol,
        type: definition.kind.name,
        documentation: definition.documentation ?? 'No documentation available',
        signature: definition.signature ?? symbol,
      );
    }
    
    return null;
  }

  /// Navigate to symbol definition and return navigation action
  static NavigationAction? navigateToDefinition(
    String symbol,
    Map<String, List<SymbolDefinition>> symbolIndex
  ) {
    final definitions = symbolIndex[symbol];
    if (definitions == null || definitions.isEmpty) return null;
    
    final definition = definitions.first;
    return NavigationAction(
      type: NavigationType.goToDefinition,
      targetFile: definition.filePath,
      targetLine: definition.line,
      targetColumn: definition.column,
      symbol: symbol,
    );
  }

  // Helper methods
  static String _getWordAtPosition(String code, int position) {
    if (position >= code.length || position < 0) return '';
    
    int start = position;
    int end = position;
    
    // Find start of word
    while (start > 0 && RegExp(r'[a-zA-Z0-9_]').hasMatch(code[start - 1])) {
      start--;
    }
    
    // Find end of word
    while (end < code.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(code[end])) {
      end++;
    }
    
    return code.substring(start, end);
  }

  static bool _isImportContext(String code, int position) {
    final lineStart = code.lastIndexOf('\n', position - 1) + 1;
    final lineEnd = code.indexOf('\n', position);
    final line = code.substring(lineStart, lineEnd == -1 ? code.length : lineEnd);
    return line.trim().startsWith('import');
  }

  static bool _isControlStructure(String line) {
    final controlWords = ['if', 'else', 'for', 'while', 'switch', 'case', 'default'];
    return controlWords.any((word) => line.contains(word));
  }

  static String _getWidgetInsertText(String widget) {
    // Common Flutter widget templates
    switch (widget) {
      case 'Container':
        return 'Container(\n  child: \n)';
      case 'Column':
        return 'Column(\n  children: [\n    \n  ],\n)';
      case 'Row':
        return 'Row(\n  children: [\n    \n  ],\n)';
      case 'Text':
        return "Text('')";
      case 'Scaffold':
        return 'Scaffold(\n  appBar: AppBar(\n    title: Text(\'\'),\n  ),\n  body: \n)';
      default:
        return '$widget()';
    }
  }

  /// 🔧 NAVIGATION HELPER METHODS
  
  static DefinitionResult? _findLocalDefinition(String code, String symbol, int cursorPosition) {
    final lines = code.split('\n');
    
    // Look for class definitions
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final classPattern = RegExp(r'class\s+' + RegExp.escape(symbol) + r'\b');
      final match = classPattern.firstMatch(line);
      if (match != null) {
        return DefinitionResult(
          symbol: symbol,
          filePath: 'current',
          line: i + 1,
          column: match.start + 1,
          definitionType: 'class',
        );
      }
    }
    
    // Look for function definitions
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final functionPattern = RegExp(r'\b' + RegExp.escape(symbol) + r'\s*\([^)]*\)\s*[{=>]');
      final match = functionPattern.firstMatch(line);
      if (match != null) {
        return DefinitionResult(
          symbol: symbol,
          filePath: 'current',
          line: i + 1,
          column: match.start + 1,
          definitionType: 'function',
        );
      }
    }
    
    // Look for variable declarations
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final varPattern = RegExp(r'\b(?:var|final|const|int|String|double|bool|List|Map)\s+' + RegExp.escape(symbol) + r'\b');
      final match = varPattern.firstMatch(line);
      if (match != null) {
        return DefinitionResult(
          symbol: symbol,
          filePath: 'current',
          line: i + 1,
          column: match.start + 1,
          definitionType: 'variable',
        );
      }
    }
    
    return null;
  }

  static DefinitionResult? _findDefinitionInProject(String symbol, Map<String, String> projectFiles) {
    for (final entry in projectFiles.entries) {
      final filePath = entry.key;
      final content = entry.value;
      
      // Skip non-Dart files
      if (!filePath.endsWith('.dart')) continue;
      
      final result = _findLocalDefinition(content, symbol, 0);
      if (result != null) {
        return DefinitionResult(
          symbol: symbol,
          filePath: filePath,
          line: result.line,
          column: result.column,
          definitionType: result.definitionType,
        );
      }
    }
    
    return null;
  }

  static bool _isWholeWordMatch(String line, int index, int length) {
    // Check character before
    if (index > 0) {
      final charBefore = line[index - 1];
      if (RegExp(r'[a-zA-Z0-9_]').hasMatch(charBefore)) return false;
    }
    
    // Check character after
    if (index + length < line.length) {
      final charAfter = line[index + length];
      if (RegExp(r'[a-zA-Z0-9_]').hasMatch(charAfter)) return false;
    }
    
    return true;
  }

  static List<SymbolDefinition> _extractSymbols(String content, String filePath) {
    List<SymbolDefinition> symbols = [];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Extract class definitions
      final classMatch = RegExp(r'class\s+(\w+)').firstMatch(line);
      if (classMatch != null) {
        symbols.add(SymbolDefinition(
          name: classMatch.group(1)!,
          kind: SymbolKind.classDefinition,
          filePath: filePath,
          line: i + 1,
          column: classMatch.start + 1,
          signature: line.trim(),
        ));
      }
      
      // Extract function definitions
      final functionMatch = RegExp(r'(\w+)\s*\([^)]*\)\s*[{=>]').firstMatch(line);
      if (functionMatch != null && !line.trim().startsWith('//')) {
        symbols.add(SymbolDefinition(
          name: functionMatch.group(1)!,
          kind: SymbolKind.function,
          filePath: filePath,
          line: i + 1,
          column: functionMatch.start + 1,
          signature: line.trim(),
        ));
      }
      
      // Extract variable definitions
      final varMatch = RegExp(r'(?:var|final|const|int|String|double|bool|List|Map)\s+(\w+)').firstMatch(line);
      if (varMatch != null && !line.trim().startsWith('//')) {
        symbols.add(SymbolDefinition(
          name: varMatch.group(1)!,
          kind: SymbolKind.variable,
          filePath: filePath,
          line: i + 1,
          column: varMatch.start + 1,
          signature: line.trim(),
        ));
      }
    }
    
    return symbols;
  }

  static String _getFlutterWidgetDocumentation(String widget) {
    switch (widget) {
      case 'Container':
        return 'A convenience widget that combines common painting, positioning, and sizing widgets.';
      case 'Column':
        return 'A widget that displays its children in a vertical array.';
      case 'Row':
        return 'A widget that displays its children in a horizontal array.';
      case 'Text':
        return 'A run of text with a single style.';
      case 'Scaffold':
        return 'Implements the basic material design visual layout structure.';
      default:
        return 'Flutter widget for building user interfaces.';
    }
  }

  static String _getDartTypeDocumentation(String type) {
    switch (type) {
      case 'String':
        return 'A sequence of UTF-16 code units.';
      case 'int':
        return 'An integer number.';
      case 'double':
        return 'A double-precision floating point number.';
      case 'bool':
        return 'A boolean value, either true or false.';
      case 'List':
        return 'An indexable collection of objects with a length.';
      case 'Map':
        return 'A collection of key/value pairs.';
      default:
        return 'Dart built-in type.';
    }
  }
}

/// Autocomplete suggestion model
class AutocompleteSuggestion {
  final String text;
  final SuggestionType type;
  final String description;
  final String insertText;

  AutocompleteSuggestion({
    required this.text,
    required this.type,
    required this.description,
    required this.insertText,
  });
}

enum SuggestionType {
  keyword,
  widget,
  type,
  import,
  method,
  property,
}

/// Code error model
class CodeError {
  final int line;
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;

  CodeError({
    required this.line,
    required this.message,
    required this.type,
    required this.severity,
  });
}

enum ErrorType {
  syntax,
  semantic,
  warning,
}

enum ErrorSeverity {
  error,
  warning,
  info,
}

/// 🚀 NAVIGATION & SYMBOL MODELS

/// Definition result for go-to-definition functionality
class DefinitionResult {
  final String symbol;
  final String filePath;
  final int line;
  final int column;
  final String definitionType;

  DefinitionResult({
    required this.symbol,
    required this.filePath,
    required this.line,
    required this.column,
    required this.definitionType,
  });
}

/// Reference location model
class ReferenceLocation {
  final String filePath;
  final int line;
  final int column;
  final String context;

  ReferenceLocation({
    required this.filePath,
    required this.line,
    required this.column,
    required this.context,
  });
}

/// Symbol definition model for project indexing
class SymbolDefinition {
  final String name;
  final SymbolKind kind;
  final String filePath;
  final int line;
  final int column;
  final String? signature;
  final String? documentation;

  SymbolDefinition({
    required this.name,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    this.signature,
    this.documentation,
  });
}

/// Types of symbols that can be defined
enum SymbolKind {
  classDefinition,
  function,
  variable,
  property,
  method,
  constructor,
  enum_,
  typedef,
}

/// Hover information model
class HoverInfo {
  final String symbol;
  final String type;
  final String documentation;
  final String signature;

  HoverInfo({
    required this.symbol,
    required this.type,
    required this.documentation,
    required this.signature,
  });
}

/// Navigation action model
class NavigationAction {
  final NavigationType type;
  final String targetFile;
  final int targetLine;
  final int targetColumn;
  final String symbol;

  NavigationAction({
    required this.type,
    required this.targetFile,
    required this.targetLine,
    required this.targetColumn,
    required this.symbol,
  });
}

/// Types of navigation actions
enum NavigationType {
  goToDefinition,
  findReferences,
  goToSymbol,
}