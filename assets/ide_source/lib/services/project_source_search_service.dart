import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart' show ProjectFile, FileType;
import 'source_code_correlator.dart';
import 'ide_source_service.dart';

/// Service for searching actual project source files to find widget locations
/// This provides REAL source linking by searching uploaded project files
/// Enhanced with SourceCodeCorrelator for precise widget code extraction
class ProjectSourceSearchService {
  static final ProjectSourceSearchService _instance = ProjectSourceSearchService._internal();
  static ProjectSourceSearchService get instance => _instance;
  ProjectSourceSearchService._internal();

  /// Current project being searched
  FlutterProject? _currentProject;

  /// Set the current project to search
  void setProject(FlutterProject? project) {
    _currentProject = project;
  }

  /// Search for a widget type in the current project's source files
  /// Returns a list of all locations where this widget is instantiated
  List<SourceLocation> findWidgetInProject(String widgetType) {
    if (_currentProject == null) return [];

    final results = <SourceLocation>[];

    // Search all Dart files in the project
    for (final file in _currentProject!.dartFiles) {
      final locations = _searchFileForWidget(file, widgetType);
      results.addAll(locations);
    }

    // Sort by relevance (lib/ files first, then by specificity)
    results.sort((a, b) {
      // Prioritize lib/ files
      final aInLib = a.filePath.contains('lib/');
      final bInLib = b.filePath.contains('lib/');
      if (aInLib && !bInLib) return -1;
      if (!aInLib && bInLib) return 1;

      // Then prioritize by match confidence
      return b.confidence.compareTo(a.confidence);
    });

    return results;
  }

  /// Search a single file for widget instantiations
  List<SourceLocation> _searchFileForWidget(ProjectFile file, String widgetType) {
    final results = <SourceLocation>[];
    final content = file.content;

    if (content.isEmpty) return results;

    // Pattern 1: Widget constructor call - "WidgetName("
    final constructorPattern = RegExp(
      '\\b$widgetType\\s*\\(',
      multiLine: true,
    );

    // Pattern 2: Widget class definition - "class WidgetName extends"
    final classPattern = RegExp(
      'class\\s+$widgetType\\s+extends',
      multiLine: true,
    );

    // Pattern 3: const constructor - "const WidgetName("
    final constPattern = RegExp(
      'const\\s+$widgetType\\s*\\(',
      multiLine: true,
    );

    // Search for constructor calls
    for (final match in constructorPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      final column = _getColumn(content, match.start);
      final snippet = _extractCodeSnippet(content, match.start);

      results.add(SourceLocation(
        filePath: file.path,
        lineNumber: lineNumber,
        column: column,
        matchType: MatchType.instantiation,
        codeSnippet: snippet,
        confidence: 0.9,
      ));
    }

    // Search for class definitions
    for (final match in classPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      final column = _getColumn(content, match.start);
      final snippet = _extractCodeSnippet(content, match.start);

      results.add(SourceLocation(
        filePath: file.path,
        lineNumber: lineNumber,
        column: column,
        matchType: MatchType.definition,
        codeSnippet: snippet,
        confidence: 1.0, // Class definitions are highest confidence
      ));
    }

    // Search for const constructor calls
    for (final match in constPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      final column = _getColumn(content, match.start);
      final snippet = _extractCodeSnippet(content, match.start);

      // Skip if we already have this location from the regular constructor search
      final alreadyFound = results.any((r) =>
          r.filePath == file.path && r.lineNumber == lineNumber);
      if (!alreadyFound) {
        results.add(SourceLocation(
          filePath: file.path,
          lineNumber: lineNumber,
          column: column,
          matchType: MatchType.constInstantiation,
          codeSnippet: snippet,
          confidence: 0.9,
        ));
      }
    }

    return results;
  }

  /// Find the best matching source location for a widget
  /// Uses widget type and optional context (parent chain, UI position) to find best match
  /// Enhanced with SourceCodeCorrelator for precise widget code extraction
  /// Falls back to IDE source when no project is loaded (for IDE development)
  SourceLocation? findBestMatch(
    String widgetType, {
    List<String>? parentChain,
    String? uiLocation,
  }) {
    // If no project loaded, try IDE source (for IDE development)
    if (_currentProject == null) {
      return _findInIDESource(widgetType, parentChain: parentChain);
    }

    final locations = findWidgetInProject(widgetType);
    if (locations.isEmpty) {
      // Fallback to IDE source if widget not found in project
      return _findInIDESource(widgetType, parentChain: parentChain);
    }
    if (locations.length == 1) {
      // Even for single match, extract precise widget code
      return _enhanceWithPreciseCode(locations.first, widgetType, parentChain);
    }

    // Score each location based on context
    SourceLocation? best;
    double bestScore = -1;

    for (final loc in locations) {
      double score = loc.confidence;

      // Boost score if parent chain hints at file
      if (parentChain != null) {
        final chainStr = parentChain.join(' ').toLowerCase();
        final pathLower = loc.filePath.toLowerCase();

        if (chainStr.contains('filetree') && pathLower.contains('file_tree')) {
          score += 0.5;
        }
        if (chainStr.contains('editor') && pathLower.contains('editor')) {
          score += 0.5;
        }
        if (chainStr.contains('preview') && pathLower.contains('preview')) {
          score += 0.5;
        }
        if (chainStr.contains('terminal') && pathLower.contains('terminal')) {
          score += 0.5;
        }
        if (chainStr.contains('assistant') && pathLower.contains('assistant')) {
          score += 0.5;
        }
        if (chainStr.contains('properties') && pathLower.contains('properties')) {
          score += 0.5;
        }
      }

      // Prefer class definitions over instantiations
      if (loc.matchType == MatchType.definition) {
        score += 0.3;
      }

      // Prefer files in lib/widgets/ or lib/screens/
      if (loc.filePath.contains('lib/widgets/') ||
          loc.filePath.contains('lib/screens/')) {
        score += 0.2;
      }

      if (score > bestScore) {
        bestScore = score;
        best = loc;
      }
    }

    final result = best ?? locations.first;
    return _enhanceWithPreciseCode(result, widgetType, parentChain);
  }

  /// Find widget in IDE source (for IDE development when no project is loaded)
  SourceLocation? _findInIDESource(
    String widgetType, {
    List<String>? parentChain,
  }) {
    final ideSource = IDESourceService.instance;

    if (!ideSource.hasIDESource) {
      // IDE source not loaded yet - return null to use fallback heuristics
      return null;
    }

    final match = ideSource.findWidgetInIDESource(
      widgetType,
      parentChain: parentChain,
    );

    if (match == null) return null;

    return SourceLocation(
      filePath: match.filePath,
      lineNumber: match.lineNumber,
      column: match.columnNumber,
      matchType: MatchType.instantiation,
      codeSnippet: match.preciseWidgetCode.length > 100
          ? '${match.preciseWidgetCode.substring(0, 100)}...'
          : match.preciseWidgetCode,
      confidence: match.confidence,
      preciseWidgetCode: match.preciseWidgetCode,
    );
  }

  /// Use SourceCodeCorrelator to extract precise widget code boundaries
  SourceLocation _enhanceWithPreciseCode(
    SourceLocation location,
    String widgetType,
    List<String>? parentChain,
  ) {
    if (_currentProject == null) return location;

    // Find the file content
    final file = _currentProject!.dartFiles.firstWhere(
      (f) => f.path == location.filePath,
      orElse: () => ProjectFile(path: '', content: '', type: FileType.dart),
    );

    if (file.content.isEmpty) return location;

    // Use SourceCodeCorrelator for precise extraction
    final correlator = SourceCodeCorrelator.instance;
    final occurrences = correlator.findWidgetOccurrences(file.content, widgetType);

    if (occurrences.isEmpty) return location;

    // Find the occurrence matching our line number
    WidgetOccurrence? bestOccurrence;
    for (final occ in occurrences) {
      if (occ.lineNumber == location.lineNumber) {
        bestOccurrence = occ;
        break;
      }
    }

    // If no exact line match, use parent chain matching
    if (bestOccurrence == null && parentChain != null) {
      bestOccurrence = correlator.matchToSourceOccurrence(
        occurrences,
        parentChain,
        file.content,
      );
    }

    bestOccurrence ??= occurrences.first;

    // Extract precise widget code using bracket matching
    final boundary = bestOccurrence.boundary;

    return SourceLocation(
      filePath: location.filePath,
      lineNumber: bestOccurrence.lineNumber,
      column: bestOccurrence.columnNumber,
      matchType: location.matchType,
      codeSnippet: location.codeSnippet,
      confidence: location.confidence,
      // NEW: Include precise widget code extracted via bracket matching
      preciseWidgetCode: boundary.sourceCode,
      widgetBoundary: boundary,
    );
  }

  /// Get line number from character offset
  int _getLineNumber(String content, int offset) {
    int line = 1;
    for (int i = 0; i < offset && i < content.length; i++) {
      if (content[i] == '\n') line++;
    }
    return line;
  }

  /// Get column number from character offset
  int _getColumn(String content, int offset) {
    int lastNewline = content.lastIndexOf('\n', offset);
    if (lastNewline == -1) return offset + 1;
    return offset - lastNewline;
  }

  /// Extract a code snippet around the match for context
  String _extractCodeSnippet(String content, int offset) {
    // Find start of line
    int start = offset;
    while (start > 0 && content[start - 1] != '\n') {
      start--;
    }

    // Find end of line (or next 120 chars)
    int end = offset;
    int count = 0;
    while (end < content.length && content[end] != '\n' && count < 120) {
      end++;
      count++;
    }

    return content.substring(start, end).trim();
  }
}

/// Represents a source location where a widget was found
class SourceLocation {
  final String filePath;
  final int lineNumber;
  final int? column;
  final MatchType matchType;
  final String? codeSnippet;
  final double confidence;

  /// Precise widget code extracted using bracket matching (from SourceCodeCorrelator)
  final String? preciseWidgetCode;

  /// Widget boundary information for advanced operations
  final WidgetBoundary? widgetBoundary;

  SourceLocation({
    required this.filePath,
    required this.lineNumber,
    this.column,
    required this.matchType,
    this.codeSnippet,
    this.confidence = 1.0,
    this.preciseWidgetCode,
    this.widgetBoundary,
  });

  /// Whether this location has precise widget code extracted
  bool get hasPreciseCode => preciseWidgetCode != null && preciseWidgetCode!.isNotEmpty;

  /// Get just the filename without the full path
  String get shortPath {
    final parts = filePath.split('/');
    if (parts.length > 2) {
      return parts.sublist(parts.length - 2).join('/');
    }
    return filePath;
  }

  /// Format as file:line:column string
  String get locationString {
    if (column != null) {
      return '$filePath:$lineNumber:$column';
    }
    return '$filePath:$lineNumber';
  }

  @override
  String toString() => '$filePath:$lineNumber (${matchType.name})';
}

/// Type of match found in source code
enum MatchType {
  /// Widget class definition (class Foo extends StatelessWidget)
  definition,

  /// Widget instantiation (Foo(...))
  instantiation,

  /// Const widget instantiation (const Foo(...))
  constInstantiation,
}
