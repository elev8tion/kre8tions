import 'package:flutter/services.dart' show rootBundle;
import 'source_code_correlator.dart';

/// Service to load and provide the IDE's own source code for widget inspection
/// This enables precise widget code extraction when developing the IDE itself
class IDESourceService {
  static final IDESourceService _instance = IDESourceService._internal();
  static IDESourceService get instance => _instance;
  IDESourceService._internal();

  /// Cached source files: path -> content
  final Map<String, String> _sourceCache = {};

  /// Whether source has been loaded
  bool _isLoaded = false;

  /// Key IDE source files to bundle
  static const List<String> _ideSourceFiles = [
    'lib/main.dart',
    'lib/theme.dart',
    'lib/screens/home_page.dart',
    'lib/widgets/file_tree_view.dart',
    'lib/widgets/enhanced_code_editor.dart',
    'lib/widgets/ai_assistant_panel.dart',
    'lib/widgets/terminal_panel.dart',
    'lib/widgets/ui_preview_panel.dart',
    'lib/widgets/precise_widget_selector.dart',
    'lib/widgets/enhanced_ide_inspector_widgets.dart',
    'lib/panels/properties_panel.dart',
    'lib/services/ide_inspector_service.dart',
    'lib/services/app_state_manager.dart',
    'lib/services/service_orchestrator.dart',
    'lib/models/flutter_project.dart',
    'lib/models/project_file.dart',
    'lib/models/widget_selection.dart',
  ];

  /// Load IDE source files from bundled assets
  Future<void> loadIDESource() async {
    if (_isLoaded) return;

    for (final path in _ideSourceFiles) {
      try {
        // Try loading from assets (requires files to be in assets/ide_source/)
        final assetPath = 'assets/ide_source/$path';
        final content = await rootBundle.loadString(assetPath);
        _sourceCache[path] = content;
        print('📂 Loaded IDE source: $path (${content.length} chars)');
      } catch (e) {
        // File not bundled yet - that's ok
        print('⚠️ IDE source not bundled: $path');
      }
    }

    _isLoaded = true;
    print('✅ IDE source loaded: ${_sourceCache.length}/${_ideSourceFiles.length} files');
  }

  /// Check if IDE source is available
  bool get hasIDESource => _sourceCache.isNotEmpty;

  /// Get source content for a file path
  String? getSourceContent(String filePath) {
    // Normalize path
    final normalized = filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;

    // Try exact match
    if (_sourceCache.containsKey(normalized)) {
      return _sourceCache[normalized];
    }

    // Try with lib/ prefix
    if (!normalized.startsWith('lib/')) {
      final withLib = 'lib/$normalized';
      if (_sourceCache.containsKey(withLib)) {
        return _sourceCache[withLib];
      }
    }

    // Try partial match
    for (final entry in _sourceCache.entries) {
      if (entry.key.endsWith(normalized) || normalized.endsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get all loaded source files
  Map<String, String> get allSources => Map.unmodifiable(_sourceCache);

  /// Find widget in IDE source using SourceCodeCorrelator
  IDEWidgetSourceMatch? findWidgetInIDESource(
    String widgetType, {
    List<String>? parentChain,
  }) {
    final correlator = SourceCodeCorrelator.instance;

    for (final entry in _sourceCache.entries) {
      final path = entry.key;
      final content = entry.value;

      final occurrences = correlator.findWidgetOccurrences(content, widgetType);

      if (occurrences.isEmpty) continue;

      // If only one occurrence, use it
      if (occurrences.length == 1) {
        final occ = occurrences.first;
        return IDEWidgetSourceMatch(
          filePath: path,
          lineNumber: occ.lineNumber,
          columnNumber: occ.columnNumber,
          preciseWidgetCode: occ.boundary.sourceCode,
          confidence: 1.0,
        );
      }

      // Multiple occurrences - use parent chain matching
      if (parentChain != null) {
        final bestMatch = correlator.matchToSourceOccurrence(
          occurrences,
          parentChain,
          content,
        );

        if (bestMatch != null) {
          return IDEWidgetSourceMatch(
            filePath: path,
            lineNumber: bestMatch.lineNumber,
            columnNumber: bestMatch.columnNumber,
            preciseWidgetCode: bestMatch.boundary.sourceCode,
            confidence: 0.8,
          );
        }
      }

      // Return first occurrence as fallback
      final first = occurrences.first;
      return IDEWidgetSourceMatch(
        filePath: path,
        lineNumber: first.lineNumber,
        columnNumber: first.columnNumber,
        preciseWidgetCode: first.boundary.sourceCode,
        confidence: 0.5,
      );
    }

    return null;
  }

  /// Search all IDE source files for a widget type
  List<IDEWidgetSourceMatch> findAllWidgetOccurrences(String widgetType) {
    final results = <IDEWidgetSourceMatch>[];
    final correlator = SourceCodeCorrelator.instance;

    for (final entry in _sourceCache.entries) {
      final path = entry.key;
      final content = entry.value;

      final occurrences = correlator.findWidgetOccurrences(content, widgetType);

      for (final occ in occurrences) {
        results.add(IDEWidgetSourceMatch(
          filePath: path,
          lineNumber: occ.lineNumber,
          columnNumber: occ.columnNumber,
          preciseWidgetCode: occ.boundary.sourceCode,
          confidence: 0.9,
        ));
      }
    }

    return results;
  }
}

/// Represents a widget source match in IDE source
class IDEWidgetSourceMatch {
  final String filePath;
  final int lineNumber;
  final int columnNumber;
  final String preciseWidgetCode;
  final double confidence;

  IDEWidgetSourceMatch({
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.preciseWidgetCode,
    required this.confidence,
  });

  String get locationString => '$filePath:$lineNumber:$columnNumber';

  @override
  String toString() => 'IDEWidgetSourceMatch($filePath:$lineNumber, ${preciseWidgetCode.length} chars)';
}
