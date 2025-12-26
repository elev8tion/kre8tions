import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../services/ide_inspector_service.dart';

/// Global overlay that wraps the entire KRE8TIONS IDE
/// Allows clicking on any widget to inspect and send notes to AI
class IDEInspectorOverlay extends StatefulWidget {
  final Widget child;

  const IDEInspectorOverlay({
    super.key,
    required this.child,
  });

  @override
  State<IDEInspectorOverlay> createState() => _IDEInspectorOverlayState();
}

class _IDEInspectorOverlayState extends State<IDEInspectorOverlay> {
  final _inspector = IDEInspectorService();
  bool _isActive = false;
  IDEWidgetInfo? _selectedWidget;
  Offset? _hoverPosition;
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      setState(() => _isActive = active);
    });
    _inspector.widgetSelectedStream.listen((widget) {
      setState(() => _selectedWidget = widget);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (!_isActive) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = details.localPosition;
    final widgetInfo = _findWidgetAtPosition(offset, box);

    if (widgetInfo != null) {
      _inspector.selectWidget(widgetInfo);
    }
  }

  void _handleHover(PointerEvent event) {
    if (!_isActive) return;
    setState(() => _hoverPosition = event.localPosition);
  }

  IDEWidgetInfo? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    RenderObject? deepestTarget;
    final List<String> hierarchy = [];

    for (var entry in result.path) {
      if (entry.target is RenderBox) {
        deepestTarget = entry.target as RenderObject;

        // Build hierarchy
        final widgetName = _getWidgetName(deepestTarget);
        if (widgetName.isNotEmpty && !widgetName.startsWith('_')) {
          hierarchy.insert(0, widgetName);
        }
      }
    }

    if (deepestTarget == null || deepestTarget is! RenderBox) return null;

    return _extractIDEWidgetInfo(deepestTarget, hierarchy);
  }

  String _getWidgetName(RenderObject renderObject) {
    String name = renderObject.runtimeType.toString();

    // Clean up render object names
    if (name.startsWith('Render')) {
      name = name.substring(6);
    }
    if (name.startsWith('_')) {
      return '';
    }

    return name;
  }

  IDEWidgetInfo _extractIDEWidgetInfo(RenderObject renderObject, List<String> hierarchy) {
    final box = renderObject as RenderBox;
    final size = box.size;
    final position = box.localToGlobal(Offset.zero);

    // Determine location based on hierarchy
    String location = 'Unknown';
    String sourceFile = 'lib/screens/home_page.dart';

    if (hierarchy.any((h) => h.contains('FileTree') || h.contains('file'))) {
      location = 'File Tree Panel';
      sourceFile = 'lib/widgets/file_tree_view.dart';
    } else if (hierarchy.any((h) => h.contains('CodeEditor') || h.contains('Editor'))) {
      location = 'Code Editor Panel';
      sourceFile = 'lib/widgets/enhanced_code_editor.dart';
    } else if (hierarchy.any((h) => h.contains('Preview') || h.contains('UI'))) {
      location = 'UI Preview Panel';
      sourceFile = 'lib/widgets/ui_preview_panel.dart';
    } else if (hierarchy.any((h) => h.contains('AI') || h.contains('Assistant'))) {
      location = 'AI Assistant Panel';
      sourceFile = 'lib/widgets/ai_assistant_panel.dart';
    } else if (hierarchy.any((h) => h.contains('Terminal'))) {
      location = 'Terminal Panel';
      sourceFile = 'lib/widgets/terminal_panel.dart';
    } else if (hierarchy.any((h) => h.contains('AppBar') || h.contains('Header'))) {
      location = 'Top App Bar';
      sourceFile = 'lib/screens/home_page.dart';
    }

    final properties = <String, dynamic>{};

    // Extract text if it's a text widget
    if (renderObject is RenderParagraph) {
      properties['text'] = renderObject.text.toPlainText();
    }

    String widgetType = _getWidgetName(renderObject);
    if (widgetType.isEmpty) {
      widgetType = 'Widget';
    }

    return IDEWidgetInfo(
      widgetType: widgetType,
      location: location,
      sourceFile: sourceFile,
      size: size,
      position: position,
      properties: properties,
      parentChain: hierarchy,
    );
  }

  void _sendNoteToAI() {
    if (_selectedWidget == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note')),
      );
      return;
    }

    _inspector.sendNoteToAI(
      _selectedWidget!,
      _noteController.text.trim(),
      action: _selectedAction,
    );

    // Copy to clipboard for easy pasting to AI
    final formatted = _inspector.formatNoteForAI(
      IDEWidgetNote(
        widget: _selectedWidget!,
        userNote: _noteController.text.trim(),
        action: _selectedAction,
        timestamp: DateTime.now(),
      ),
    );
    Clipboard.setData(ClipboardData(text: formatted));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Note sent to AI & copied to clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.withValues(alpha: 0.2),
      ),
    );

    // Clear note
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app
        widget.child,

        // Inspector overlay when active
        if (_isActive)
          Positioned.fill(
            child: MouseRegion(
              onHover: _handleHover,
              onExit: (_) => setState(() => _hoverPosition = null),
              child: GestureDetector(
                onTapDown: _handleTap,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.blue.withValues(alpha: 0.05),
                  child: CustomPaint(
                    painter: _IDEInspectorPainter(
                      selectedWidget: _selectedWidget,
                      hoverPosition: _hoverPosition,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Floating inspector indicator
        if (_isActive)
          Positioned(
            top: 8,
            left: 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'IDE Inspector Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Press Ctrl+Shift+I to exit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Widget info panel
        if (_isActive && _selectedWidget != null)
          Positioned(
            top: 60,
            right: 16,
            child: _WidgetNotePanel(
              widget: _selectedWidget!,
              noteController: _noteController,
              selectedAction: _selectedAction,
              onActionChanged: (action) => setState(() => _selectedAction = action),
              onSendNote: _sendNoteToAI,
              onClose: () => setState(() => _selectedWidget = null),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for inspector overlay
class _IDEInspectorPainter extends CustomPainter {
  final IDEWidgetInfo? selectedWidget;
  final Offset? hoverPosition;

  _IDEInspectorPainter({
    this.selectedWidget,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedWidget == null) return;

    final bounds = Rect.fromLTWH(
      selectedWidget!.position.dx,
      selectedWidget!.position.dy,
      selectedWidget!.size.width,
      selectedWidget!.size.height,
    );

    // Draw selection border
    final paint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(bounds, paint);

    // Draw corner handles
    final handlePaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill;

    final handleSize = 8.0;
    canvas.drawCircle(bounds.topLeft, handleSize, handlePaint);
    canvas.drawCircle(bounds.topRight, handleSize, handlePaint);
    canvas.drawCircle(bounds.bottomLeft, handleSize, handlePaint);
    canvas.drawCircle(bounds.bottomRight, handleSize, handlePaint);

    // Draw hover indicator
    if (hoverPosition != null) {
      final hoverPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(hoverPosition!, 8, hoverPaint);
    }
  }

  @override
  bool shouldRepaint(_IDEInspectorPainter oldDelegate) {
    return selectedWidget != oldDelegate.selectedWidget ||
           hoverPosition != oldDelegate.hoverPosition;
  }
}

/// Panel for adding notes to AI about selected widget
class _WidgetNotePanel extends StatelessWidget {
  final IDEWidgetInfo widget;
  final TextEditingController noteController;
  final NoteAction selectedAction;
  final ValueChanged<NoteAction> onActionChanged;
  final VoidCallback onSendNote;
  final VoidCallback onClose;

  const _WidgetNotePanel({
    required this.widget,
    required this.noteController,
    required this.selectedAction,
    required this.onActionChanged,
    required this.onSendNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade700],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Send Note to AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Widget info
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoSection(
                      title: 'Selected Widget',
                      children: [
                        _InfoRow(label: 'Type', value: widget.widgetType),
                        _InfoRow(label: 'Location', value: widget.location),
                        _InfoRow(label: 'File', value: widget.sourceFile),
                        _InfoRow(
                          label: 'Size',
                          value: '${widget.size.width.toStringAsFixed(0)} × ${widget.size.height.toStringAsFixed(0)}',
                        ),
                        if (widget.properties.containsKey('text'))
                          _InfoRow(label: 'Text', value: widget.properties['text'].toString()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action selector
                    const Text(
                      'What do you want to do?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NoteAction.values.map((action) {
                        final isSelected = action == selectedAction;
                        return ChoiceChip(
                          label: Text(action.name, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => onActionChanged(action),
                          selectedColor: Colors.blue.shade100,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Note input
                    const Text(
                      'Your note to AI:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe what you want changed, fixed, or explain your question...',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    // Send button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onSendNote,
                        icon: const Icon(Icons.send),
                        label: const Text('Send to AI (& Copy to Clipboard)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
