import 'dart:async';
import 'dart:math';

enum CursorType { primary, secondary }
enum SelectionMode { character, word, line, block }
enum EditOperation { insert, delete, replace, cut, copy, paste }

class CursorPosition {
  final int line;
  final int column;
  final CursorType type;
  final String id;
  final DateTime createdAt;

  const CursorPosition({
    required this.line,
    required this.column,
    required this.type,
    required this.id,
    required this.createdAt,
  });

  CursorPosition copyWith({
    int? line,
    int? column,
    CursorType? type,
    String? id,
    DateTime? createdAt,
  }) {
    return CursorPosition(
      line: line ?? this.line,
      column: column ?? this.column,
      type: type ?? this.type,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CursorPosition &&
        other.line == line &&
        other.column == column &&
        other.type == type;
  }

  @override
  int get hashCode => line.hashCode ^ column.hashCode ^ type.hashCode;

  @override
  String toString() => 'CursorPosition(line: $line, column: $column, type: $type)';
}

class TextSelection {
  final CursorPosition start;
  final CursorPosition end;
  final String selectedText;
  final SelectionMode mode;
  final String id;

  const TextSelection({
    required this.start,
    required this.end,
    required this.selectedText,
    required this.mode,
    required this.id,
  });

  bool get isValid => start.line <= end.line && 
      (start.line < end.line || start.column <= end.column);
  
  bool get isEmpty => start.line == end.line && start.column == end.column;
  
  int get length => selectedText.length;
}

class EditAction {
  final String id;
  final EditOperation operation;
  final List<CursorPosition> cursors;
  final List<TextSelection> selections;
  final String? insertText;
  final String? originalText;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const EditAction({
    required this.id,
    required this.operation,
    required this.cursors,
    this.selections = const [],
    this.insertText,
    this.originalText,
    required this.timestamp,
    this.metadata = const {},
  });
}

class MultiEditResult {
  final List<CursorPosition> newCursorPositions;
  final List<String> modifiedLines;
  final Map<int, String> lineChanges;
  final int totalChanges;
  final Duration executionTime;

  const MultiEditResult({
    required this.newCursorPositions,
    required this.modifiedLines,
    required this.lineChanges,
    required this.totalChanges,
    required this.executionTime,
  });
}

class CursorGroup {
  final String id;
  final List<CursorPosition> cursors;
  final String name;
  final DateTime createdAt;

  const CursorGroup({
    required this.id,
    required this.cursors,
    required this.name,
    required this.createdAt,
  });

  int get cursorCount => cursors.length;
}

class MultiCursorService {
  static final MultiCursorService _instance = MultiCursorService._internal();
  factory MultiCursorService() => _instance;
  MultiCursorService._internal();

  final StreamController<List<CursorPosition>> _cursorsController = 
      StreamController<List<CursorPosition>>.broadcast();
  final StreamController<List<TextSelection>> _selectionsController = 
      StreamController<List<TextSelection>>.broadcast();
  final StreamController<EditAction> _editActionController = 
      StreamController<EditAction>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();

  Stream<List<CursorPosition>> get cursorsStream => _cursorsController.stream;
  Stream<List<TextSelection>> get selectionsStream => _selectionsController.stream;
  Stream<EditAction> get editActionStream => _editActionController.stream;
  Stream<String> get statusStream => _statusController.stream;

  final List<CursorPosition> _cursors = [];
  final List<TextSelection> _selections = [];
  final List<EditAction> _actionHistory = [];
  final List<CursorGroup> _savedGroups = [];
  
  String _currentFileContent = '';
  List<String> _lines = [];
  
  bool _isMultiCursorMode = false;
  final SelectionMode _currentSelectionMode = SelectionMode.character;

  List<CursorPosition> get cursors => List.unmodifiable(_cursors);
  List<TextSelection> get selections => List.unmodifiable(_selections);
  List<EditAction> get actionHistory => List.unmodifiable(_actionHistory);
  List<CursorGroup> get savedGroups => List.unmodifiable(_savedGroups);
  
  bool get isMultiCursorMode => _isMultiCursorMode;
  bool get hasPrimaryCursor => _cursors.any((c) => c.type == CursorType.primary);
  bool get hasSecondaryCursors => _cursors.any((c) => c.type == CursorType.secondary);
  int get cursorCount => _cursors.length;
  
  SelectionMode get currentSelectionMode => _currentSelectionMode;

  // File Content Management
  void setFileContent(String content) {
    _currentFileContent = content;
    _lines = content.split('\n');
    _status('File content updated (${_lines.length} lines)');
  }

  // Cursor Management
  void addCursor(int line, int column, {CursorType type = CursorType.secondary}) {
    // Validate position
    if (!_isValidPosition(line, column)) {
      _status('Invalid cursor position: line $line, column $column');
      return;
    }

    // Check for duplicate cursor at same position
    final existingCursor = _cursors.firstWhere(
      (cursor) => cursor.line == line && cursor.column == column,
      orElse: () => CursorPosition(line: -1, column: -1, type: CursorType.primary, id: '', createdAt: DateTime.now()),
    );

    if (existingCursor.line != -1) {
      _status('Cursor already exists at line $line, column $column');
      return;
    }

    final cursor = CursorPosition(
      line: line,
      column: column,
      type: type,
      id: _generateId(),
      createdAt: DateTime.now(),
    );

    _cursors.add(cursor);
    _isMultiCursorMode = _cursors.length > 1;
    
    _cursorsController.add(_cursors);
    _status('Added ${type.name} cursor at line $line, column $column');
  }

  void setPrimaryCursor(int line, int column) {
    // Remove existing primary cursor
    _cursors.removeWhere((cursor) => cursor.type == CursorType.primary);
    
    addCursor(line, column, type: CursorType.primary);
  }

  void removeCursor(String cursorId) {
    final cursor = _cursors.firstWhere(
      (c) => c.id == cursorId,
      orElse: () => CursorPosition(line: -1, column: -1, type: CursorType.primary, id: '', createdAt: DateTime.now()),
    );

    if (cursor.line != -1) {
      _cursors.removeWhere((c) => c.id == cursorId);
      _isMultiCursorMode = _cursors.length > 1;
      
      _cursorsController.add(_cursors);
      _status('Removed cursor from line ${cursor.line}, column ${cursor.column}');
    }
  }

  void removeAllCursors({bool keepPrimary = true}) {
    if (keepPrimary) {
      _cursors.removeWhere((cursor) => cursor.type == CursorType.secondary);
    } else {
      _cursors.clear();
    }
    
    _isMultiCursorMode = _cursors.length > 1;
    _cursorsController.add(_cursors);
    _status('Removed ${keepPrimary ? 'secondary' : 'all'} cursors');
  }

  void moveCursor(String cursorId, int newLine, int newColumn) {
    if (!_isValidPosition(newLine, newColumn)) return;

    final index = _cursors.indexWhere((c) => c.id == cursorId);
    if (index != -1) {
      _cursors[index] = _cursors[index].copyWith(
        line: newLine,
        column: newColumn,
      );
      
      _cursorsController.add(_cursors);
    }
  }

  void moveAllCursors(int deltaLine, int deltaColumn) {
    final movedCursors = <CursorPosition>[];
    
    for (final cursor in _cursors) {
      final newLine = cursor.line + deltaLine;
      final newColumn = cursor.column + deltaColumn;
      
      if (_isValidPosition(newLine, newColumn)) {
        movedCursors.add(cursor.copyWith(line: newLine, column: newColumn));
      } else {
        movedCursors.add(cursor);
      }
    }
    
    _cursors.clear();
    _cursors.addAll(movedCursors);
    _cursorsController.add(_cursors);
  }

  // Advanced Cursor Placement
  void addCursorAtNextOccurrence(String searchText, {bool caseSensitive = false}) {
    if (searchText.isEmpty || _lines.isEmpty) return;

    final searchPattern = caseSensitive ? searchText : searchText.toLowerCase();
    
    // Start search from the last cursor position
    int startLine = 0;
    int startColumn = 0;
    
    if (_cursors.isNotEmpty) {
      final lastCursor = _cursors.last;
      startLine = lastCursor.line;
      startColumn = lastCursor.column + 1;
    }

    for (int lineIndex = startLine; lineIndex < _lines.length; lineIndex++) {
      final line = _lines[lineIndex];
      final searchLine = caseSensitive ? line : line.toLowerCase();
      
      final startPos = lineIndex == startLine ? startColumn : 0;
      final foundIndex = searchLine.indexOf(searchPattern, startPos);
      
      if (foundIndex != -1) {
        addCursor(lineIndex, foundIndex);
        return;
      }
    }

    _status('No more occurrences of "$searchText" found');
  }

  void addCursorAtAllOccurrences(String searchText, {bool caseSensitive = false}) {
    if (searchText.isEmpty || _lines.isEmpty) return;

    final searchPattern = caseSensitive ? searchText : searchText.toLowerCase();
    int addedCursors = 0;

    for (int lineIndex = 0; lineIndex < _lines.length; lineIndex++) {
      final line = _lines[lineIndex];
      final searchLine = caseSensitive ? line : line.toLowerCase();
      
      int searchStart = 0;
      while (true) {
        final foundIndex = searchLine.indexOf(searchPattern, searchStart);
        if (foundIndex == -1) break;
        
        // Check if cursor already exists at this position
        final exists = _cursors.any((c) => c.line == lineIndex && c.column == foundIndex);
        if (!exists) {
          addCursor(lineIndex, foundIndex);
          addedCursors++;
        }
        
        searchStart = foundIndex + 1;
      }
    }

    _status('Added $addedCursors cursors for "$searchText"');
  }

  void addCursorAtLineStarts(int fromLine, int toLine) {
    for (int line = fromLine; line <= toLine && line < _lines.length; line++) {
      addCursor(line, 0);
    }
    _status('Added cursors at start of lines $fromLine-$toLine');
  }

  void addCursorAtLineEnds(int fromLine, int toLine) {
    for (int line = fromLine; line <= toLine && line < _lines.length; line++) {
      final lineLength = _lines[line].length;
      addCursor(line, lineLength);
    }
    _status('Added cursors at end of lines $fromLine-$toLine');
  }

  void addCursorAtColumn(int column, int fromLine, int toLine) {
    for (int line = fromLine; line <= toLine && line < _lines.length; line++) {
      if (_lines[line].length >= column) {
        addCursor(line, column);
      }
    }
    _status('Added cursors at column $column for lines $fromLine-$toLine');
  }

  // Selection Management
  void createSelection(int startLine, int startColumn, int endLine, int endColumn, 
      {SelectionMode mode = SelectionMode.character}) {
    if (!_isValidPosition(startLine, startColumn) || !_isValidPosition(endLine, endColumn)) {
      return;
    }

    final start = CursorPosition(
      line: startLine, 
      column: startColumn, 
      type: CursorType.primary, 
      id: _generateId(),
      createdAt: DateTime.now(),
    );
    
    final end = CursorPosition(
      line: endLine, 
      column: endColumn, 
      type: CursorType.primary, 
      id: _generateId(),
      createdAt: DateTime.now(),
    );

    final selectedText = _getTextBetweenPositions(start, end);
    
    final selection = TextSelection(
      start: start,
      end: end,
      selectedText: selectedText,
      mode: mode,
      id: _generateId(),
    );

    _selections.add(selection);
    _selectionsController.add(_selections);
    _status('Created selection: ${selection.selectedText.length} characters');
  }

  void clearSelections() {
    _selections.clear();
    _selectionsController.add(_selections);
    _status('Cleared all selections');
  }

  void selectWordAtCursors() {
    _selections.clear();
    
    for (final cursor in _cursors) {
      final wordBounds = _getWordBoundsAt(cursor.line, cursor.column);
      if (wordBounds != null) {
        final selection = TextSelection(
          start: CursorPosition(line: cursor.line, column: wordBounds['start']!, type: cursor.type, id: _generateId(), createdAt: DateTime.now()),
          end: CursorPosition(line: cursor.line, column: wordBounds['end']!, type: cursor.type, id: _generateId(), createdAt: DateTime.now()),
          selectedText: _lines[cursor.line].substring(wordBounds['start']!, wordBounds['end']!),
          mode: SelectionMode.word,
          id: _generateId(),
        );
        _selections.add(selection);
      }
    }
    
    _selectionsController.add(_selections);
    _status('Selected words at ${_selections.length} cursors');
  }

  void selectLineAtCursors() {
    _selections.clear();
    
    for (final cursor in _cursors) {
      if (cursor.line < _lines.length) {
        final selection = TextSelection(
          start: CursorPosition(line: cursor.line, column: 0, type: cursor.type, id: _generateId(), createdAt: DateTime.now()),
          end: CursorPosition(line: cursor.line, column: _lines[cursor.line].length, type: cursor.type, id: _generateId(), createdAt: DateTime.now()),
          selectedText: _lines[cursor.line],
          mode: SelectionMode.line,
          id: _generateId(),
        );
        _selections.add(selection);
      }
    }
    
    _selectionsController.add(_selections);
    _status('Selected lines at ${_selections.length} cursors');
  }

  // Multi-Cursor Editing Operations
  Future<MultiEditResult> insertTextAtAllCursors(String text) async {
    final startTime = DateTime.now();
    final modifiedLines = <String>[];
    final lineChanges = <int, String>{};
    final newCursors = <CursorPosition>[];

    // Sort cursors by line and column (reverse order to maintain positions)
    final sortedCursors = [..._cursors];
    sortedCursors.sort((a, b) {
      if (a.line != b.line) return b.line.compareTo(a.line);
      return b.column.compareTo(a.column);
    });

    for (final cursor in sortedCursors) {
      if (cursor.line < _lines.length) {
        final originalLine = _lines[cursor.line];
        final beforeCursor = originalLine.substring(0, cursor.column);
        final afterCursor = originalLine.substring(cursor.column);
        final newLine = beforeCursor + text + afterCursor;
        
        _lines[cursor.line] = newLine;
        lineChanges[cursor.line] = newLine;
        
        // Update cursor position
        newCursors.add(cursor.copyWith(
          column: cursor.column + text.length,
        ));
      } else {
        newCursors.add(cursor);
      }
    }

    // Update cursors
    _cursors.clear();
    _cursors.addAll(newCursors.reversed); // Reverse to maintain original order
    _cursorsController.add(_cursors);

    // Update file content
    _currentFileContent = _lines.join('\n');

    // Record action
    final action = EditAction(
      id: _generateId(),
      operation: EditOperation.insert,
      cursors: sortedCursors,
      insertText: text,
      timestamp: DateTime.now(),
      metadata: {'cursorCount': sortedCursors.length},
    );
    
    _actionHistory.add(action);
    _editActionController.add(action);

    final result = MultiEditResult(
      newCursorPositions: _cursors,
      modifiedLines: modifiedLines,
      lineChanges: lineChanges,
      totalChanges: lineChanges.length,
      executionTime: DateTime.now().difference(startTime),
    );

    _status('Inserted "$text" at ${sortedCursors.length} cursors');
    return result;
  }

  Future<MultiEditResult> deleteAtAllCursors({int characters = 1, bool backwards = true}) async {
    final startTime = DateTime.now();
    final lineChanges = <int, String>{};
    final newCursors = <CursorPosition>[];
    final deletedTexts = <String>[];

    // Sort cursors by line and column (reverse order to maintain positions)
    final sortedCursors = [..._cursors];
    sortedCursors.sort((a, b) {
      if (a.line != b.line) return b.line.compareTo(a.line);
      return b.column.compareTo(a.column);
    });

    for (final cursor in sortedCursors) {
      if (cursor.line < _lines.length) {
        final originalLine = _lines[cursor.line];
        String newLine;
        int newColumn;
        String deletedText = '';

        if (backwards) {
          // Delete backwards (backspace)
          final deleteStart = (cursor.column - characters).clamp(0, cursor.column);
          deletedText = originalLine.substring(deleteStart, cursor.column);
          newLine = originalLine.substring(0, deleteStart) + originalLine.substring(cursor.column);
          newColumn = deleteStart;
        } else {
          // Delete forwards (delete key)
          final deleteEnd = (cursor.column + characters).clamp(cursor.column, originalLine.length);
          deletedText = originalLine.substring(cursor.column, deleteEnd);
          newLine = originalLine.substring(0, cursor.column) + originalLine.substring(deleteEnd);
          newColumn = cursor.column;
        }

        _lines[cursor.line] = newLine;
        lineChanges[cursor.line] = newLine;
        deletedTexts.add(deletedText);
        
        newCursors.add(cursor.copyWith(column: newColumn));
      } else {
        newCursors.add(cursor);
      }
    }

    // Update cursors
    _cursors.clear();
    _cursors.addAll(newCursors.reversed);
    _cursorsController.add(_cursors);

    // Update file content
    _currentFileContent = _lines.join('\n');

    // Record action
    final action = EditAction(
      id: _generateId(),
      operation: EditOperation.delete,
      cursors: sortedCursors,
      originalText: deletedTexts.join('|'), // Simple way to store multiple deleted texts
      timestamp: DateTime.now(),
      metadata: {
        'characters': characters,
        'backwards': backwards,
        'cursorCount': sortedCursors.length,
      },
    );
    
    _actionHistory.add(action);
    _editActionController.add(action);

    final result = MultiEditResult(
      newCursorPositions: _cursors,
      modifiedLines: [],
      lineChanges: lineChanges,
      totalChanges: lineChanges.length,
      executionTime: DateTime.now().difference(startTime),
    );

    _status('Deleted $characters character(s) at ${sortedCursors.length} cursors');
    return result;
  }

  Future<MultiEditResult> replaceSelections(String replacementText) async {
    if (_selections.isEmpty) {
      _status('No selections to replace');
      return MultiEditResult(
        newCursorPositions: _cursors,
        modifiedLines: [],
        lineChanges: {},
        totalChanges: 0,
        executionTime: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    final lineChanges = <int, String>{};
    final newCursors = <CursorPosition>[];

    // Sort selections by position (reverse order)
    final sortedSelections = [..._selections];
    sortedSelections.sort((a, b) {
      if (a.start.line != b.start.line) return b.start.line.compareTo(a.start.line);
      return b.start.column.compareTo(a.start.column);
    });

    for (final selection in sortedSelections) {
      // Replace selected text
      if (selection.start.line == selection.end.line) {
        // Single line selection
        final line = _lines[selection.start.line];
        final before = line.substring(0, selection.start.column);
        final after = line.substring(selection.end.column);
        final newLine = before + replacementText + after;
        
        _lines[selection.start.line] = newLine;
        lineChanges[selection.start.line] = newLine;
        
        // Add cursor at end of replacement
        newCursors.add(CursorPosition(
          line: selection.start.line,
          column: selection.start.column + replacementText.length,
          type: CursorType.secondary,
          id: _generateId(),
          createdAt: DateTime.now(),
        ));
      } else {
        // Multi-line selection - simplified implementation
        final firstLine = _lines[selection.start.line];
        final before = firstLine.substring(0, selection.start.column);
        final lastLine = _lines[selection.end.line];
        final after = lastLine.substring(selection.end.column);
        
        final newLine = before + replacementText + after;
        
        // Replace first line
        _lines[selection.start.line] = newLine;
        lineChanges[selection.start.line] = newLine;
        
        // Remove lines in between
        for (int i = selection.end.line; i > selection.start.line; i--) {
          _lines.removeAt(i);
        }
        
        newCursors.add(CursorPosition(
          line: selection.start.line,
          column: selection.start.column + replacementText.length,
          type: CursorType.secondary,
          id: _generateId(),
          createdAt: DateTime.now(),
        ));
      }
    }

    // Update cursors and clear selections
    _cursors.clear();
    _cursors.addAll(newCursors.reversed);
    _selections.clear();
    
    _cursorsController.add(_cursors);
    _selectionsController.add(_selections);

    // Update file content
    _currentFileContent = _lines.join('\n');

    // Record action
    final action = EditAction(
      id: _generateId(),
      operation: EditOperation.replace,
      cursors: _cursors,
      selections: sortedSelections,
      insertText: replacementText,
      timestamp: DateTime.now(),
      metadata: {'selectionCount': sortedSelections.length},
    );
    
    _actionHistory.add(action);
    _editActionController.add(action);

    final result = MultiEditResult(
      newCursorPositions: _cursors,
      modifiedLines: [],
      lineChanges: lineChanges,
      totalChanges: lineChanges.length,
      executionTime: DateTime.now().difference(startTime),
    );

    _status('Replaced ${sortedSelections.length} selections with "$replacementText"');
    return result;
  }

  // Cursor Groups (Save/Restore cursor positions)
  String saveCursorGroup(String name) {
    final group = CursorGroup(
      id: _generateId(),
      cursors: [..._cursors],
      name: name,
      createdAt: DateTime.now(),
    );

    _savedGroups.add(group);
    _status('Saved cursor group "$name" with ${group.cursorCount} cursors');
    
    return group.id;
  }

  void restoreCursorGroup(String groupId) {
    final group = _savedGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => CursorGroup(id: '', cursors: [], name: '', createdAt: DateTime.now()),
    );

    if (group.id.isNotEmpty) {
      _cursors.clear();
      _cursors.addAll(group.cursors.map((cursor) => CursorPosition(
        line: cursor.line,
        column: cursor.column,
        type: cursor.type,
        id: _generateId(), // Generate new IDs
        createdAt: DateTime.now(),
      )));

      _isMultiCursorMode = _cursors.length > 1;
      _cursorsController.add(_cursors);
      _status('Restored cursor group "${group.name}" with ${group.cursorCount} cursors');
    }
  }

  void deleteCursorGroup(String groupId) {
    final group = _savedGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => CursorGroup(id: '', cursors: [], name: '', createdAt: DateTime.now()),
    );

    if (group.id.isNotEmpty) {
      _savedGroups.removeWhere((g) => g.id == groupId);
      _status('Deleted cursor group "${group.name}"');
    }
  }

  // Utility Methods
  bool _isValidPosition(int line, int column) {
    return line >= 0 && 
           line < _lines.length && 
           column >= 0 && 
           column <= _lines[line].length;
  }

  String _getTextBetweenPositions(CursorPosition start, CursorPosition end) {
    if (start.line == end.line) {
      // Single line
      return _lines[start.line].substring(start.column, end.column);
    } else {
      // Multi-line
      final buffer = StringBuffer();
      
      // First line
      buffer.write(_lines[start.line].substring(start.column));
      buffer.write('\n');
      
      // Middle lines
      for (int i = start.line + 1; i < end.line; i++) {
        buffer.write(_lines[i]);
        buffer.write('\n');
      }
      
      // Last line
      buffer.write(_lines[end.line].substring(0, end.column));
      
      return buffer.toString();
    }
  }

  Map<String, int>? _getWordBoundsAt(int line, int column) {
    if (line >= _lines.length) return null;
    
    final lineText = _lines[line];
    if (column >= lineText.length) return null;

    // Find word boundaries
    int start = column;
    int end = column;

    // Find start of word
    while (start > 0 && _isWordCharacter(lineText[start - 1])) {
      start--;
    }

    // Find end of word
    while (end < lineText.length && _isWordCharacter(lineText[end])) {
      end++;
    }

    return {'start': start, 'end': end};
  }

  bool _isWordCharacter(String char) {
    return char.contains(RegExp(r'[a-zA-Z0-9_]'));
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _status(String message) {
    _statusController.add('[${DateTime.now().toIso8601String()}] $message');
  }

  // Statistics and Analytics
  Map<String, dynamic> getMultiCursorStatistics() {
    final totalActions = _actionHistory.length;
    final insertActions = _actionHistory.where((a) => a.operation == EditOperation.insert).length;
    final deleteActions = _actionHistory.where((a) => a.operation == EditOperation.delete).length;
    final replaceActions = _actionHistory.where((a) => a.operation == EditOperation.replace).length;

    return {
      'totalCursors': _cursors.length,
      'isMultiCursorMode': _isMultiCursorMode,
      'totalSelections': _selections.length,
      'totalActions': totalActions,
      'insertActions': insertActions,
      'deleteActions': deleteActions,
      'replaceActions': replaceActions,
      'savedGroups': _savedGroups.length,
      'currentSelectionMode': _currentSelectionMode.name,
    };
  }

  // Keyboard Shortcuts Support
  void handleKeyboardShortcut(String shortcut) {
    switch (shortcut) {
      case 'ctrl+alt+down':
        // Add cursor below
        if (_cursors.isNotEmpty) {
          final lastCursor = _cursors.last;
          addCursor(lastCursor.line + 1, lastCursor.column);
        }
        break;
      
      case 'ctrl+alt+up':
        // Add cursor above
        if (_cursors.isNotEmpty) {
          final lastCursor = _cursors.last;
          if (lastCursor.line > 0) {
            addCursor(lastCursor.line - 1, lastCursor.column);
          }
        }
        break;
      
      case 'ctrl+d':
        // Add cursor at next occurrence of selected word
        if (_selections.isNotEmpty) {
          final selectedText = _selections.first.selectedText;
          addCursorAtNextOccurrence(selectedText);
        }
        break;
      
      case 'ctrl+shift+l':
        // Add cursor at all occurrences of selected word
        if (_selections.isNotEmpty) {
          final selectedText = _selections.first.selectedText;
          addCursorAtAllOccurrences(selectedText);
        }
        break;
      
      case 'escape':
        // Exit multi-cursor mode
        removeAllCursors();
        clearSelections();
        break;
      
      case 'ctrl+u':
        // Undo last cursor addition
        if (_cursors.length > 1) {
          _cursors.removeLast();
          _cursorsController.add(_cursors);
          _isMultiCursorMode = _cursors.length > 1;
        }
        break;
    }
  }

  // Clean up
  void clearAll() {
    _cursors.clear();
    _selections.clear();
    _actionHistory.clear();
    _isMultiCursorMode = false;
    
    _cursorsController.add(_cursors);
    _selectionsController.add(_selections);
    _status('Cleared all cursors and selections');
  }

  void dispose() {
    _cursorsController.close();
    _selectionsController.close();
    _editActionController.close();
    _statusController.close();
  }
}