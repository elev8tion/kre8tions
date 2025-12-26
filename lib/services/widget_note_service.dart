import 'dart:async';
import 'dart:convert';
import 'widget_inspector_service.dart' as inspector;

/// Service for managing widget inspection notes and AI communication
class WidgetNoteService {
  static final WidgetNoteService _instance = WidgetNoteService._internal();
  factory WidgetNoteService() => _instance;
  WidgetNoteService._internal();

  final _noteController = StreamController<WidgetNote>.broadcast();
  final List<WidgetNote> _notes = [];

  Stream<WidgetNote> get noteStream => _noteController.stream;
  List<WidgetNote> get notes => List.unmodifiable(_notes);

  /// Send a note about a widget to the AI assistant
  void sendNoteToAI(
    inspector.WidgetInspectionData widget, {
    String? userNote,
    String? question,
    NoteType type = NoteType.inspection,
  }) {
    final note = WidgetNote(
      widget: widget,
      userNote: userNote,
      question: question,
      type: type,
      timestamp: DateTime.now(),
    );

    _notes.add(note);
    _noteController.add(note);
  }

  /// Get formatted note for AI context
  String formatNoteForAI(WidgetNote note) {
    final buffer = StringBuffer();

    buffer.writeln('=== Widget Inspection Note ===');
    buffer.writeln('Timestamp: ${note.timestamp}');
    buffer.writeln('Type: ${note.type.name}');
    buffer.writeln();
    buffer.writeln('Widget Information:');
    buffer.writeln('  Type: ${note.widget.widgetType}');
    buffer.writeln('  Depth: ${note.widget.depth}');
    buffer.writeln('  Size: ${note.widget.bounds.width.toStringAsFixed(1)} × ${note.widget.bounds.height.toStringAsFixed(1)}');
    buffer.writeln('  Children: ${note.widget.children.length}');

    if (note.widget.properties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Properties:');
      note.widget.properties.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (note.widget.children.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Widget Tree:');
      _formatWidgetTree(buffer, note.widget, 0);
    }

    if (note.userNote != null) {
      buffer.writeln();
      buffer.writeln('User Note:');
      buffer.writeln(note.userNote);
    }

    if (note.question != null) {
      buffer.writeln();
      buffer.writeln('Question:');
      buffer.writeln(note.question);
    }

    buffer.writeln();
    buffer.writeln('JSON Data:');
    buffer.writeln(const JsonEncoder.withIndent('  ').convert(note.widget.toJson()));

    return buffer.toString();
  }

  void _formatWidgetTree(StringBuffer buffer, inspector.WidgetInspectionData widget, int level) {
    final indent = '  ' * level;
    buffer.writeln('$indent- ${widget.widgetType} (${widget.children.length} children)');

    for (var child in widget.children) {
      _formatWidgetTree(buffer, child, level + 1);
    }
  }

  /// Clear all notes
  void clearNotes() {
    _notes.clear();
  }

  void dispose() {
    _noteController.close();
  }
}

/// Type of widget note
enum NoteType {
  inspection,     // General widget inspection
  bugReport,      // Reporting a bug
  question,       // Asking a question
  suggestion,     // Making a suggestion
  modification,   // Requesting a modification
}

/// A note about a widget sent to the AI
class WidgetNote {
  final inspector.WidgetInspectionData widget;
  final String? userNote;
  final String? question;
  final NoteType type;
  final DateTime timestamp;

  WidgetNote({
    required this.widget,
    this.userNote,
    this.question,
    this.type = NoteType.inspection,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'widget': widget.toJson(),
    'userNote': userNote,
    'question': question,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };
}
