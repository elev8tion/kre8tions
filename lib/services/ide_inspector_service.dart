import 'dart:async';
import 'package:flutter/material.dart';

/// Service for inspecting the KRE8TIONS IDE itself
/// Allows clicking on any part of the IDE to identify widgets and send notes to AI
class IDEInspectorService {
  static final IDEInspectorService _instance = IDEInspectorService._internal();
  factory IDEInspectorService() => _instance;
  IDEInspectorService._internal();

  bool _isActive = false;
  final _activeController = StreamController<bool>.broadcast();
  final _widgetSelectedController = StreamController<IDEWidgetInfo>.broadcast();
  final _noteToAIController = StreamController<IDEWidgetNote>.broadcast();

  Stream<bool> get activeStream => _activeController.stream;
  Stream<IDEWidgetInfo> get widgetSelectedStream => _widgetSelectedController.stream;
  Stream<IDEWidgetNote> get noteToAIStream => _noteToAIController.stream;

  bool get isActive => _isActive;

  final List<IDEWidgetNote> _notes = [];
  List<IDEWidgetNote> get notes => List.unmodifiable(_notes);

  void toggle() {
    _isActive = !_isActive;
    _activeController.add(_isActive);
    debugPrint('🔍 IDE Inspector ${_isActive ? "ENABLED" : "DISABLED"}');
  }

  void enable() {
    _isActive = true;
    _activeController.add(true);
    debugPrint('🔍 IDE Inspector ENABLED');
  }

  void disable() {
    _isActive = false;
    _activeController.add(false);
    debugPrint('🔍 IDE Inspector DISABLED');
  }

  void selectWidget(IDEWidgetInfo info) {
    _widgetSelectedController.add(info);
    debugPrint('📍 Selected: ${info.widgetType} at ${info.location}');
  }

  void sendNoteToAI(IDEWidgetInfo widget, String note, {NoteAction action = NoteAction.discuss}) {
    final widgetNote = IDEWidgetNote(
      widget: widget,
      userNote: note,
      action: action,
      timestamp: DateTime.now(),
    );

    _notes.add(widgetNote);
    _noteToAIController.add(widgetNote);

    debugPrint('💬 Note sent to AI: $note');
    debugPrint('   Widget: ${widget.widgetType}');
    debugPrint('   Action: ${action.name}');
  }

  String formatNoteForAI(IDEWidgetNote note) {
    final buffer = StringBuffer();

    buffer.writeln('=== IDE Widget Inspection Note ===');
    buffer.writeln('User Request: ${note.action.description}');
    buffer.writeln('Timestamp: ${note.timestamp}');
    buffer.writeln();
    buffer.writeln('Widget Information:');
    buffer.writeln('  Type: ${note.widget.widgetType}');
    buffer.writeln('  Location: ${note.widget.location}');
    buffer.writeln('  Source File: ${note.widget.sourceFile}');
    if (note.widget.lineNumber != null) {
      buffer.writeln('  Line Number: ${note.widget.lineNumber}');
    }
    buffer.writeln('  Size: ${note.widget.size.width.toStringAsFixed(0)} × ${note.widget.size.height.toStringAsFixed(0)}');
    buffer.writeln('  Position: (${note.widget.position.dx.toStringAsFixed(0)}, ${note.widget.position.dy.toStringAsFixed(0)})');

    if (note.widget.properties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Properties:');
      note.widget.properties.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (note.widget.parentChain.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Widget Hierarchy:');
      for (int i = 0; i < note.widget.parentChain.length; i++) {
        buffer.writeln('  ${'  ' * i}└─ ${note.widget.parentChain[i]}');
      }
    }

    buffer.writeln();
    buffer.writeln('User Note:');
    buffer.writeln(note.userNote);
    buffer.writeln();
    buffer.writeln('Suggested File to Edit: ${note.widget.sourceFile}');

    return buffer.toString();
  }

  void clearNotes() {
    _notes.clear();
  }

  void dispose() {
    _activeController.close();
    _widgetSelectedController.close();
    _noteToAIController.close();
  }
}

/// Information about an inspected IDE widget
class IDEWidgetInfo {
  final String widgetType;
  final String location; // e.g., "File Tree Panel", "Code Editor", "AI Assistant"
  final String sourceFile; // The Dart file containing this widget
  final int? lineNumber;
  final Size size;
  final Offset position;
  final Map<String, dynamic> properties;
  final List<String> parentChain;

  IDEWidgetInfo({
    required this.widgetType,
    required this.location,
    required this.sourceFile,
    this.lineNumber,
    required this.size,
    required this.position,
    this.properties = const {},
    this.parentChain = const [],
  });

  Map<String, dynamic> toJson() => {
    'widgetType': widgetType,
    'location': location,
    'sourceFile': sourceFile,
    'lineNumber': lineNumber,
    'size': {'width': size.width, 'height': size.height},
    'position': {'x': position.dx, 'y': position.dy},
    'properties': properties,
    'parentChain': parentChain,
  };
}

/// A note about an IDE widget to send to AI
class IDEWidgetNote {
  final IDEWidgetInfo widget;
  final String userNote;
  final NoteAction action;
  final DateTime timestamp;

  IDEWidgetNote({
    required this.widget,
    required this.userNote,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'widget': widget.toJson(),
    'userNote': userNote,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
  };

  String get formattedForClipboard {
    return '''
IDE Widget Note
===============
Location: ${widget.location}
Widget: ${widget.widgetType}
File: ${widget.sourceFile}:${widget.lineNumber ?? '?'}
Action: ${action.description}

Note:
${userNote}

---
Generated at $timestamp
''';
  }
}

/// Action to take on the widget
enum NoteAction {
  discuss('Discuss this widget with AI'),
  modify('Modify this widget'),
  fix('Fix a bug in this widget'),
  enhance('Enhance this widget'),
  remove('Remove this widget'),
  relocate('Move this widget'),
  style('Change styling'),
  question('Ask a question');

  final String description;
  const NoteAction(this.description);
}
