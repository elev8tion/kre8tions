import 'dart:async';
import 'dart:math';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';

enum SearchType { text, regex, symbol, reference }
enum SearchScope { currentFile, openFiles, project, selectedFiles }
enum ReplaceMode { single, all, preview, confirm }

class SearchMatch {
  final String id;
  final String filePath;
  final int line;
  final int column;
  final int startOffset;
  final int endOffset;
  final String matchedText;
  final String lineContent;
  final String? context;
  final Map<String, dynamic> metadata;

  const SearchMatch({
    required this.id,
    required this.filePath,
    required this.line,
    required this.column,
    required this.startOffset,
    required this.endOffset,
    required this.matchedText,
    required this.lineContent,
    this.context,
    this.metadata = const {},
  });

  String get fileName => filePath.split('/').last;
  String get displayText => lineContent.trim();
  
  SearchMatch copyWith({
    String? id,
    String? filePath,
    int? line,
    int? column,
    int? startOffset,
    int? endOffset,
    String? matchedText,
    String? lineContent,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    return SearchMatch(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      matchedText: matchedText ?? this.matchedText,
      lineContent: lineContent ?? this.lineContent,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
    );
  }
}

class SearchQuery {
  final String id;
  final String query;
  final SearchType type;
  final SearchScope scope;
  final bool caseSensitive;
  final bool wholeWord;
  final bool includeComments;
  final bool includeStrings;
  final List<String> filePatterns;
  final List<String> excludePatterns;
  final DateTime createdAt;

  const SearchQuery({
    required this.id,
    required this.query,
    required this.type,
    required this.scope,
    this.caseSensitive = false,
    this.wholeWord = false,
    this.includeComments = true,
    this.includeStrings = true,
    this.filePatterns = const [],
    this.excludePatterns = const [],
    required this.createdAt,
  });

  SearchQuery copyWith({
    String? id,
    String? query,
    SearchType? type,
    SearchScope? scope,
    bool? caseSensitive,
    bool? wholeWord,
    bool? includeComments,
    bool? includeStrings,
    List<String>? filePatterns,
    List<String>? excludePatterns,
    DateTime? createdAt,
  }) {
    return SearchQuery(
      id: id ?? this.id,
      query: query ?? this.query,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      includeComments: includeComments ?? this.includeComments,
      includeStrings: includeStrings ?? this.includeStrings,
      filePatterns: filePatterns ?? this.filePatterns,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SearchResult {
  final String id;
  final SearchQuery query;
  final List<SearchMatch> matches;
  final int totalMatches;
  final int filesSearched;
  final int filesWithMatches;
  final Duration searchTime;
  final DateTime completedAt;
  final Map<String, int> matchesByFile;

  const SearchResult({
    required this.id,
    required this.query,
    required this.matches,
    required this.totalMatches,
    required this.filesSearched,
    required this.filesWithMatches,
    required this.searchTime,
    required this.completedAt,
    required this.matchesByFile,
  });
}

class ReplaceOperation {
  final String id;
  final SearchQuery searchQuery;
  final String replacementText;
  final ReplaceMode mode;
  final List<String> selectedMatchIds;
  final bool preserveCase;
  final DateTime createdAt;

  const ReplaceOperation({
    required this.id,
    required this.searchQuery,
    required this.replacementText,
    required this.mode,
    required this.selectedMatchIds,
    this.preserveCase = false,
    required this.createdAt,
  });
}

class ReplaceResult {
  final String id;
  final ReplaceOperation operation;
  final List<ReplaceChange> changes;
  final int totalReplacements;
  final int filesModified;
  final Duration replaceTime;
  final DateTime completedAt;
  final List<String> errors;

  const ReplaceResult({
    required this.id,
    required this.operation,
    required this.changes,
    required this.totalReplacements,
    required this.filesModified,
    required this.replaceTime,
    required this.completedAt,
    this.errors = const [],
  });
}

class ReplaceChange {
  final String filePath;
  final int line;
  final int column;
  final String originalText;
  final String newText;
  final String lineContent;
  final String newLineContent;

  const ReplaceChange({
    required this.filePath,
    required this.line,
    required this.column,
    required this.originalText,
    required this.newText,
    required this.lineContent,
    required this.newLineContent,
  });
}

class SavedSearch {
  final String id;
  final String name;
  final SearchQuery query;
  final DateTime savedAt;
  final int useCount;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.savedAt,
    this.useCount = 0,
  });

  SavedSearch copyWith({
    String? id,
    String? name,
    SearchQuery? query,
    DateTime? savedAt,
    int? useCount,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      savedAt: savedAt ?? this.savedAt,
      useCount: useCount ?? this.useCount,
    );
  }
}

class AdvancedSearchService {
  static final AdvancedSearchService _instance = AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  final StreamController<SearchResult> _searchResultController = 
      StreamController<SearchResult>.broadcast();
  final StreamController<ReplaceResult> _replaceResultController = 
      StreamController<ReplaceResult>.broadcast();
  final StreamController<String> _searchProgressController = 
      StreamController<String>.broadcast();
  final StreamController<List<SearchMatch>> _matchesController = 
      StreamController<List<SearchMatch>>.broadcast();

  Stream<SearchResult> get searchResultStream => _searchResultController.stream;
  Stream<ReplaceResult> get replaceResultStream => _replaceResultController.stream;
  Stream<String> get searchProgressStream => _searchProgressController.stream;
  Stream<List<SearchMatch>> get matchesStream => _matchesController.stream;

  final List<SearchResult> _searchHistory = [];
  final List<ReplaceResult> _replaceHistory = [];
  final List<SavedSearch> _savedSearches = [];
  final List<SearchMatch> _currentMatches = [];
  
  bool _isSearching = false;
  bool _isReplacing = false;

  bool get isSearching => _isSearching;
  bool get isReplacing => _isReplacing;
  List<SearchResult> get searchHistory => List.unmodifiable(_searchHistory);
  List<ReplaceResult> get replaceHistory => List.unmodifiable(_replaceHistory);
  List<SavedSearch> get savedSearches => List.unmodifiable(_savedSearches);
  List<SearchMatch> get currentMatches => List.unmodifiable(_currentMatches);

  // Main Search Operations
  Future<SearchResult> search(SearchQuery query, FlutterProject project) async {
    _isSearching = true;
    _progress('Starting search...');

    final startTime = DateTime.now();
    final matches = <SearchMatch>[];
    final matchesByFile = <String, int>{};
    int filesSearched = 0;

    try {
      // Get files to search based on scope
      final filesToSearch = _getFilesToSearch(query, project);
      
      for (final file in filesToSearch) {
        _progress('Searching in ${file.fileName}...');
        
        final fileMatches = await _searchInFile(query, file);
        matches.addAll(fileMatches);
        
        if (fileMatches.isNotEmpty) {
          matchesByFile[file.path] = fileMatches.length;
        }
        
        filesSearched++;
      }

      final endTime = DateTime.now();
      final searchTime = endTime.difference(startTime);

      final result = SearchResult(
        id: _generateId(),
        query: query,
        matches: matches,
        totalMatches: matches.length,
        filesSearched: filesSearched,
        filesWithMatches: matchesByFile.length,
        searchTime: searchTime,
        completedAt: endTime,
        matchesByFile: matchesByFile,
      );

      _searchHistory.add(result);
      if (_searchHistory.length > 50) {
        _searchHistory.removeAt(0);
      }

      _currentMatches.clear();
      _currentMatches.addAll(matches);
      
      _searchResultController.add(result);
      _matchesController.add(_currentMatches);
      
      _progress('Search completed: ${matches.length} matches found in ${matchesByFile.length} files');

      return result;
    } finally {
      _isSearching = false;
    }
  }

  List<ProjectFile> _getFilesToSearch(SearchQuery query, FlutterProject project) {
    List<ProjectFile> files = [];

    switch (query.scope) {
      case SearchScope.currentFile:
        // In a real implementation, this would get the currently open file
        files = project.files.take(1).toList();
        break;
      case SearchScope.openFiles:
        // In a real implementation, this would get open files
        files = project.files.take(5).toList();
        break;
      case SearchScope.project:
        files = project.files;
        break;
      case SearchScope.selectedFiles:
        // In a real implementation, this would get user-selected files
        files = project.files;
        break;
    }

    // Filter by file patterns
    if (query.filePatterns.isNotEmpty) {
      files = files.where((file) {
        return query.filePatterns.any((pattern) => 
          _matchesPattern(file.fileName, pattern));
      }).toList();
    }

    // Exclude patterns
    if (query.excludePatterns.isNotEmpty) {
      files = files.where((file) {
        return !query.excludePatterns.any((pattern) => 
          _matchesPattern(file.fileName, pattern));
      }).toList();
    }

    return files.where((file) => !file.isDirectory).toList();
  }

  bool _matchesPattern(String fileName, String pattern) {
    // Simple pattern matching - in reality, this would support glob patterns
    if (pattern.contains('*')) {
      final regex = RegExp(pattern.replaceAll('*', '.*'));
      return regex.hasMatch(fileName);
    }
    return fileName.contains(pattern);
  }

  Future<List<SearchMatch>> _searchInFile(SearchQuery query, ProjectFile file) async {
    final matches = <SearchMatch>[];
    final lines = file.content.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lineMatches = _findMatchesInLine(query, line, lineIndex + 1, file.path);
      matches.addAll(lineMatches);
    }

    return matches;
  }

  List<SearchMatch> _findMatchesInLine(SearchQuery query, String line, int lineNumber, String filePath) {
    final matches = <SearchMatch>[];
    
    switch (query.type) {
      case SearchType.text:
        matches.addAll(_findTextMatches(query, line, lineNumber, filePath));
        break;
      case SearchType.regex:
        matches.addAll(_findRegexMatches(query, line, lineNumber, filePath));
        break;
      case SearchType.symbol:
        matches.addAll(_findSymbolMatches(query, line, lineNumber, filePath));
        break;
      case SearchType.reference:
        matches.addAll(_findReferenceMatches(query, line, lineNumber, filePath));
        break;
    }

    return matches;
  }

  List<SearchMatch> _findTextMatches(SearchQuery query, String line, int lineNumber, String filePath) {
    final matches = <SearchMatch>[];
    String searchText = query.caseSensitive ? line : line.toLowerCase();
    String queryText = query.caseSensitive ? query.query : query.query.toLowerCase();

    if (query.wholeWord) {
      final wordRegex = RegExp(r'\b' + RegExp.escape(queryText) + r'\b', 
          caseSensitive: query.caseSensitive);
      final regexMatches = wordRegex.allMatches(searchText);
      
      for (final match in regexMatches) {
        matches.add(_createSearchMatch(
          line, lineNumber, filePath, match.start, match.end, query.query));
      }
    } else {
      int startIndex = 0;
      while (true) {
        final index = searchText.indexOf(queryText, startIndex);
        if (index == -1) break;

        matches.add(_createSearchMatch(
          line, lineNumber, filePath, index, index + queryText.length, query.query));
        
        startIndex = index + 1;
      }
    }

    return _filterMatchesByContext(matches, query);
  }

  List<SearchMatch> _findRegexMatches(SearchQuery query, String line, int lineNumber, String filePath) {
    final matches = <SearchMatch>[];
    
    try {
      final regex = RegExp(query.query, caseSensitive: query.caseSensitive);
      final regexMatches = regex.allMatches(line);
      
      for (final match in regexMatches) {
        matches.add(_createSearchMatch(
          line, lineNumber, filePath, match.start, match.end, match.group(0) ?? ''));
      }
    } catch (e) {
      // Invalid regex - return empty list
      return [];
    }

    return _filterMatchesByContext(matches, query);
  }

  List<SearchMatch> _findSymbolMatches(SearchQuery query, String line, int lineNumber, String filePath) {
    final matches = <SearchMatch>[];
    
    // Look for class declarations, method names, variable names, etc.
    final symbolPatterns = [
      r'class\s+' + query.query + r'\b',
      r'enum\s+' + query.query + r'\b',
      r'typedef\s+.*\s+' + query.query + r'\b',
      r'(?:final|const|var)\s+.*\s+' + query.query + r'\b',
      r'(?:void|Future|String|int|double|bool)\s+' + query.query + r'\s*\(',
      query.query + r'\s*\(',  // Method calls
    ];

    for (final pattern in symbolPatterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: query.caseSensitive);
        final regexMatches = regex.allMatches(line);
        
        for (final match in regexMatches) {
          final fullMatch = match.group(0) ?? '';
          final symbolIndex = fullMatch.indexOf(query.query);
          if (symbolIndex != -1) {
            matches.add(_createSearchMatch(
              line, lineNumber, filePath, 
              match.start + symbolIndex, 
              match.start + symbolIndex + query.query.length,
              query.query));
          }
        }
      } catch (e) {
        // Invalid pattern - skip
      }
    }

    return matches;
  }

  List<SearchMatch> _findReferenceMatches(SearchQuery query, String line, int lineNumber, String filePath) {
    final matches = <SearchMatch>[];
    
    // Find references to the symbol (usage, not declaration)
    final referencePatterns = [
      r'\b' + query.query + r'\(',  // Method calls
      r'\b' + query.query + r'\.',  // Property access
      r'\b' + query.query + r'\b',  // General usage
    ];

    for (final pattern in referencePatterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: query.caseSensitive);
        final regexMatches = regex.allMatches(line);
        
        for (final match in regexMatches) {
          // Skip if this looks like a declaration
          if (!_isDeclaration(line, match.start, query.query)) {
            matches.add(_createSearchMatch(
              line, lineNumber, filePath, match.start, match.start + query.query.length, query.query));
          }
        }
      } catch (e) {
        // Invalid pattern - skip
      }
    }

    return matches;
  }

  bool _isDeclaration(String line, int position, String symbol) {
    // Simple heuristic to detect if this is a declaration vs usage
    final beforeSymbol = line.substring(0, position).trim();
    
    return beforeSymbol.endsWith('class') ||
           beforeSymbol.endsWith('enum') ||
           beforeSymbol.endsWith('typedef') ||
           beforeSymbol.endsWith('const') ||
           beforeSymbol.endsWith('final') ||
           beforeSymbol.endsWith('var') ||
           beforeSymbol.contains('void ') ||
           beforeSymbol.contains('Future ') ||
           beforeSymbol.contains('String ') ||
           beforeSymbol.contains('int ') ||
           beforeSymbol.contains('double ') ||
           beforeSymbol.contains('bool ');
  }

  SearchMatch _createSearchMatch(String line, int lineNumber, String filePath, 
      int startPos, int endPos, String matchedText) {
    return SearchMatch(
      id: _generateId(),
      filePath: filePath,
      line: lineNumber,
      column: startPos + 1,
      startOffset: startPos,
      endOffset: endPos,
      matchedText: matchedText,
      lineContent: line,
    );
  }

  List<SearchMatch> _filterMatchesByContext(List<SearchMatch> matches, SearchQuery query) {
    if (!query.includeComments || !query.includeStrings) {
      return matches.where((match) {
        final line = match.lineContent;
        final position = match.startOffset;
        
        if (!query.includeComments && _isInComment(line, position)) {
          return false;
        }
        
        if (!query.includeStrings && _isInString(line, position)) {
          return false;
        }
        
        return true;
      }).toList();
    }
    
    return matches;
  }

  bool _isInComment(String line, int position) {
    // Check for single-line comments
    final commentIndex = line.indexOf('//');
    return commentIndex != -1 && position >= commentIndex;
  }

  bool _isInString(String line, int position) {
    // Simple string detection - count quotes before position
    int singleQuotes = 0;
    int doubleQuotes = 0;
    
    for (int i = 0; i < position && i < line.length; i++) {
      if (line[i] == '\'' && (i == 0 || line[i - 1] != '\\')) {
        singleQuotes++;
      } else if (line[i] == '"' && (i == 0 || line[i - 1] != '\\')) {
        doubleQuotes++;
      }
    }
    
    return (singleQuotes % 2 == 1) || (doubleQuotes % 2 == 1);
  }

  // Replace Operations
  Future<ReplaceResult> replaceMatches(ReplaceOperation operation, FlutterProject project) async {
    _isReplacing = true;
    _progress('Starting replace operation...');

    final startTime = DateTime.now();
    final changes = <ReplaceChange>[];
    final errors = <String>[];
    final modifiedFiles = <String>{};

    try {
      // Get matches to replace
      final matchesToReplace = _getMatchesToReplace(operation);
      
      // Group by file for efficient processing
      final matchesByFile = <String, List<SearchMatch>>{};
      for (final match in matchesToReplace) {
        matchesByFile.putIfAbsent(match.filePath, () => []).add(match);
      }

      for (final entry in matchesByFile.entries) {
        final filePath = entry.key;
        final fileMatches = entry.value;
        
        _progress('Replacing in ${filePath.split('/').last}...');
        
        try {
          final fileChanges = await _replaceInFile(operation, fileMatches, project);
          changes.addAll(fileChanges);
          
          if (fileChanges.isNotEmpty) {
            modifiedFiles.add(filePath);
          }
        } catch (e) {
          errors.add('Error in $filePath: $e');
        }
      }

      final endTime = DateTime.now();
      final replaceTime = endTime.difference(startTime);

      final result = ReplaceResult(
        id: _generateId(),
        operation: operation,
        changes: changes,
        totalReplacements: changes.length,
        filesModified: modifiedFiles.length,
        replaceTime: replaceTime,
        completedAt: endTime,
        errors: errors,
      );

      _replaceHistory.add(result);
      if (_replaceHistory.length > 50) {
        _replaceHistory.removeAt(0);
      }

      _replaceResultController.add(result);
      
      _progress('Replace completed: ${changes.length} replacements in ${modifiedFiles.length} files');

      return result;
    } finally {
      _isReplacing = false;
    }
  }

  List<SearchMatch> _getMatchesToReplace(ReplaceOperation operation) {
    switch (operation.mode) {
      case ReplaceMode.single:
        return _currentMatches.where((match) => 
          operation.selectedMatchIds.contains(match.id)).take(1).toList();
      case ReplaceMode.all:
        return _currentMatches;
      case ReplaceMode.preview:
      case ReplaceMode.confirm:
        return _currentMatches.where((match) => 
          operation.selectedMatchIds.contains(match.id)).toList();
    }
  }

  Future<List<ReplaceChange>> _replaceInFile(ReplaceOperation operation, 
      List<SearchMatch> matches, FlutterProject project) async {
    final changes = <ReplaceChange>[];
    
    // Find the file
    final file = project.files.firstWhere((f) => f.path == matches.first.filePath,
        orElse: () => ProjectFile(path: '', content: '', type: FileType.dart));
    
    if (file.path.isEmpty) {
      throw Exception('File not found: ${matches.first.filePath}');
    }

    final lines = file.content.split('\n');
    
    // Sort matches by line and column (reverse order to maintain positions)
    matches.sort((a, b) {
      if (a.line != b.line) return b.line.compareTo(a.line);
      return b.column.compareTo(a.column);
    });

    for (final match in matches) {
      if (match.line - 1 < lines.length) {
        final originalLine = lines[match.line - 1];
        final replacementText = _getReplacementText(operation, match);
        
        final beforeMatch = originalLine.substring(0, match.startOffset);
        final afterMatch = originalLine.substring(match.endOffset);
        final newLine = beforeMatch + replacementText + afterMatch;
        
        lines[match.line - 1] = newLine;
        
        changes.add(ReplaceChange(
          filePath: match.filePath,
          line: match.line,
          column: match.column,
          originalText: match.matchedText,
          newText: replacementText,
          lineContent: originalLine,
          newLineContent: newLine,
        ));
      }
    }

    // Update file content in project (in a real implementation)
    // project.updateFile(file.path, lines.join('\n'));

    return changes;
  }

  String _getReplacementText(ReplaceOperation operation, SearchMatch match) {
    String replacement = operation.replacementText;
    
    if (operation.preserveCase && operation.searchQuery.type != SearchType.regex) {
      replacement = _preserveCase(match.matchedText, replacement);
    }
    
    // Handle regex capture groups
    if (operation.searchQuery.type == SearchType.regex) {
      try {
        final regex = RegExp(operation.searchQuery.query, 
            caseSensitive: operation.searchQuery.caseSensitive);
        final regexMatch = regex.firstMatch(match.lineContent);
        
        if (regexMatch != null) {
          replacement = replacement.replaceAllMapped(
            RegExp(r'\$(\d+)'),
            (match) {
              final groupNum = int.tryParse(match.group(1) ?? '0') ?? 0;
              return regexMatch.group(groupNum) ?? '';
            },
          );
        }
      } catch (e) {
        // Invalid regex - use replacement as-is
      }
    }
    
    return replacement;
  }

  String _preserveCase(String original, String replacement) {
    if (original.isEmpty || replacement.isEmpty) return replacement;
    
    if (original == original.toUpperCase()) {
      return replacement.toUpperCase();
    } else if (original == original.toLowerCase()) {
      return replacement.toLowerCase();
    } else if (original[0] == original[0].toUpperCase()) {
      return replacement[0].toUpperCase() + replacement.substring(1).toLowerCase();
    }
    
    return replacement;
  }

  // Saved Searches
  void saveSearch(String name, SearchQuery query) {
    final saved = SavedSearch(
      id: _generateId(),
      name: name,
      query: query,
      savedAt: DateTime.now(),
    );
    
    _savedSearches.add(saved);
    _progress('Search saved as: $name');
  }

  void deleteSavedSearch(String id) {
    _savedSearches.removeWhere((saved) => saved.id == id);
  }

  SavedSearch? getSavedSearch(String id) {
    return _savedSearches.where((saved) => saved.id == id).firstOrNull;
  }

  void incrementSearchUseCount(String id) {
    final index = _savedSearches.indexWhere((saved) => saved.id == id);
    if (index != -1) {
      _savedSearches[index] = _savedSearches[index].copyWith(
        useCount: _savedSearches[index].useCount + 1,
      );
    }
  }

  // Search History and Navigation
  SearchMatch? getNextMatch(String currentMatchId) {
    final currentIndex = _currentMatches.indexWhere((m) => m.id == currentMatchId);
    if (currentIndex != -1 && currentIndex < _currentMatches.length - 1) {
      return _currentMatches[currentIndex + 1];
    }
    return null;
  }

  SearchMatch? getPreviousMatch(String currentMatchId) {
    final currentIndex = _currentMatches.indexWhere((m) => m.id == currentMatchId);
    if (currentIndex > 0) {
      return _currentMatches[currentIndex - 1];
    }
    return null;
  }

  List<SearchMatch> getMatchesInFile(String filePath) {
    return _currentMatches.where((match) => match.filePath == filePath).toList();
  }

  Map<String, List<SearchMatch>> getMatchesGroupedByFile() {
    final grouped = <String, List<SearchMatch>>{};
    for (final match in _currentMatches) {
      grouped.putIfAbsent(match.filePath, () => []).add(match);
    }
    return grouped;
  }

  // Quick Search and Find in Files
  Future<List<SearchMatch>> quickSearch(String query, FlutterProject project, {
    int maxResults = 100,
  }) async {
    final searchQuery = SearchQuery(
      id: _generateId(),
      query: query,
      type: SearchType.text,
      scope: SearchScope.project,
      createdAt: DateTime.now(),
    );

    final result = await search(searchQuery, project);
    return result.matches.take(maxResults).toList();
  }

  Future<List<SearchMatch>> findInFiles(String query, List<String> filePaths, 
      FlutterProject project) async {
    final searchQuery = SearchQuery(
      id: _generateId(),
      query: query,
      type: SearchType.text,
      scope: SearchScope.selectedFiles,
      createdAt: DateTime.now(),
    );

    // Filter project files to only include specified paths
    final filteredProject = FlutterProject(
      name: project.name,
      files: project.files.where((file) => filePaths.contains(file.path)).toList(),
      uploadedAt: project.uploadedAt,
    );

    final result = await search(searchQuery, filteredProject);
    return result.matches;
  }

  // Statistics and Analytics
  Map<String, dynamic> getSearchStatistics() {
    final now = DateTime.now();
    final recentSearches = _searchHistory.where((result) => 
        now.difference(result.completedAt).inDays < 7).toList();

    return {
      'totalSearches': _searchHistory.length,
      'recentSearches': recentSearches.length,
      'totalReplacements': _replaceHistory.fold(0, (sum, r) => sum + r.totalReplacements),
      'savedSearches': _savedSearches.length,
      'averageSearchTime': _searchHistory.isNotEmpty 
          ? _searchHistory.fold(0, (sum, r) => sum + r.searchTime.inMilliseconds) / _searchHistory.length
          : 0,
      'mostUsedPatterns': _getMostUsedPatterns(),
    };
  }

  List<Map<String, dynamic>> _getMostUsedPatterns() {
    final patterns = <String, int>{};
    
    for (final search in _searchHistory) {
      patterns[search.query.query] = (patterns[search.query.query] ?? 0) + 1;
    }

    final sortedPatterns = patterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPatterns.take(10).map((entry) => {
      'pattern': entry.key,
      'count': entry.value,
    }).toList();
  }

  // Utility methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _progress(String message) {
    _searchProgressController.add('[${DateTime.now().toIso8601String()}] $message');
  }

  void clearHistory() {
    _searchHistory.clear();
    _replaceHistory.clear();
    _currentMatches.clear();
    _matchesController.add(_currentMatches);
  }

  void clearCurrentSearch() {
    _currentMatches.clear();
    _matchesController.add(_currentMatches);
  }

  void dispose() {
    _searchResultController.close();
    _replaceResultController.close();
    _searchProgressController.close();
    _matchesController.close();
  }
}