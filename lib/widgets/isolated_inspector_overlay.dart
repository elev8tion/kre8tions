import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../services/ide_inspector_service.dart';
import 'enhanced_ide_inspector_widgets.dart';

/// Fully isolated inspector overlay that prevents click propagation
/// Based on Flutter DevTools WidgetInspector implementation
class IsolatedInspectorOverlay extends StatefulWidget {
  final Widget child;

  const IsolatedInspectorOverlay({
    super.key,
    required this.child,
  });

  @override
  State<IsolatedInspectorOverlay> createState() => _IsolatedInspectorOverlayState();
}

class _IsolatedInspectorOverlayState extends State<IsolatedInspectorOverlay> {
  final _inspector = IDEInspectorService();
  bool _isActive = false;
  IDEWidgetInfo? _selectedWidget;
  IDEWidgetInfo? _hoveredWidget;
  List<IDEWidgetInfo> _widgetPath = [];
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      setState(() => _isActive = active);
      if (!active) {
        _clearSelection();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedWidget = null;
      _hoveredWidget = null;
      _widgetPath = [];
    });
  }

  /// Handle pointer events - this intercepts ALL events when inspector is active
  void _handlePointerEvent(PointerEvent event) {
    if (!_isActive) return;

    if (event is PointerHoverEvent || event is PointerMoveEvent) {
      _handleHover(event.localPosition);
    } else if (event is PointerDownEvent) {
      _handleSelection(event.localPosition);
    }
  }

  void _handleHover(Offset position) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final widgetInfo = _findWidgetAtPosition(position, box);
    if (widgetInfo != null && widgetInfo != _hoveredWidget) {
      setState(() => _hoveredWidget = widgetInfo);
    }
  }

  void _handleSelection(Offset position) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final widgetInfo = _findWidgetAtPosition(position, box);
    if (widgetInfo != null) {
      setState(() {
        _selectedWidget = widgetInfo;
        _widgetPath = _buildWidgetPath(widgetInfo);
        _hoveredWidget = null; // Clear hover when selected
      });
      _inspector.selectWidget(widgetInfo);
    }
  }

  List<IDEWidgetInfo> _buildWidgetPath(IDEWidgetInfo widget) {
    final path = <IDEWidgetInfo>[];
    for (int i = 0; i < widget.parentChain.length; i++) {
      path.add(IDEWidgetInfo(
        widgetType: widget.parentChain[i],
        location: widget.location,
        sourceFile: widget.sourceFile,
        size: Size.zero,
        position: Offset.zero,
        parentChain: widget.parentChain.sublist(0, i),
      ));
    }
    path.add(widget);
    return path;
  }

  IDEWidgetInfo? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();

    // Perform hit test but DON'T allow it to propagate to children
    // We only want to detect what's under the pointer, not trigger any actions
    rootBox.hitTest(result, position: position);

    RenderObject? deepestTarget;
    final List<String> hierarchy = [];

    for (var entry in result.path) {
      if (entry.target is RenderBox) {
        final target = entry.target as RenderObject;
        deepestTarget = target;

        final widgetName = _getCleanWidgetName(target);
        if (widgetName.isNotEmpty) {
          hierarchy.insert(0, widgetName);
        }
      }
    }

    if (deepestTarget == null || deepestTarget is! RenderBox) return null;

    return _extractWidgetInfo(deepestTarget, hierarchy);
  }

  String _getCleanWidgetName(RenderObject renderObject) {
    String name = renderObject.runtimeType.toString();

    if (name.startsWith('Render')) {
      name = name.substring(6);
    }

    // Filter out internal/utility widgets
    const internalPrefixes = ['_', 'Listener', 'Semantics', 'Pipeline', 'Offstage', 'View'];
    for (final prefix in internalPrefixes) {
      if (name.startsWith(prefix)) return '';
    }

    return name;
  }

  IDEWidgetInfo _extractWidgetInfo(RenderObject renderObject, List<String> hierarchy) {
    final box = renderObject as RenderBox;
    final size = box.size;
    final position = box.localToGlobal(Offset.zero);

    String location = _detectLocation(hierarchy, position);
    String sourceFile = _detectSourceFile(location);

    final properties = <String, dynamic>{};

    if (renderObject is RenderParagraph) {
      properties['text'] = renderObject.text.toPlainText();
    }

    if (renderObject is RenderDecoratedBox) {
      final decoration = renderObject.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        properties['color'] = decoration.color.toString();
      }
    }

    String widgetType = _getCleanWidgetName(renderObject);
    if (widgetType.isEmpty) widgetType = 'Widget';

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

  String _detectLocation(List<String> hierarchy, Offset position) {
    final hierarchyStr = hierarchy.join(' ');

    if (position.dx < 300) return 'File Tree Panel (Left)';
    if (position.dx > MediaQuery.of(context).size.width - 400) {
      if (hierarchyStr.contains('AI') || hierarchyStr.contains('Assistant')) {
        return 'AI Assistant Panel (Right)';
      }
      return 'Properties Panel (Right)';
    }

    if (hierarchyStr.contains('FileTree')) return 'File Tree Panel';
    if (hierarchyStr.contains('CodeEditor') || hierarchyStr.contains('Editor')) return 'Code Editor Panel';
    if (hierarchyStr.contains('Preview') || hierarchyStr.contains('Device')) return 'UI Preview Panel';
    if (hierarchyStr.contains('AI') || hierarchyStr.contains('Assistant')) return 'AI Assistant Panel';
    if (hierarchyStr.contains('Terminal')) return 'Terminal Panel';
    if (position.dy < 60) return 'Top App Bar';

    return 'Main Layout Area';
  }

  String _detectSourceFile(String location) {
    if (location.contains('File Tree')) return 'lib/widgets/file_tree_view.dart';
    if (location.contains('Code Editor')) return 'lib/widgets/enhanced_code_editor.dart';
    if (location.contains('Preview')) return 'lib/widgets/ui_preview_panel.dart';
    if (location.contains('AI Assistant')) return 'lib/widgets/ai_assistant_panel.dart';
    if (location.contains('Terminal')) return 'lib/widgets/terminal_panel.dart';
    return 'lib/screens/home_page.dart';
  }

  void _sendNoteToAI() {
    if (_selectedWidget == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note about what you want changed')),
      );
      return;
    }

    _inspector.sendNoteToAI(_selectedWidget!, _noteController.text.trim(), action: _selectedAction);

    final formatted = _createEnhancedNote();
    Clipboard.setData(ClipboardData(text: formatted));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Note copied! Paste it to Claude for precise changes.'),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.withValues(alpha: 0.15),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _noteController.clear();
  }

  String _createEnhancedNote() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════');
    buffer.writeln('🎯 KRE8TIONS IDE - Widget Modification Request');
    buffer.writeln('═══════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('📅 Timestamp: ${DateTime.now()}');
    buffer.writeln('🎬 Action: ${_selectedAction.description}');
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📍 SELECTED WIDGET');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('Widget Type: ${_selectedWidget!.widgetType}');
    buffer.writeln('Location: ${_selectedWidget!.location}');
    buffer.writeln('Source File: ${_selectedWidget!.sourceFile}');
    buffer.writeln('Size: ${_selectedWidget!.size.width.toInt()} × ${_selectedWidget!.size.height.toInt()} px');
    buffer.writeln('Position: (${_selectedWidget!.position.dx.toInt()}, ${_selectedWidget!.position.dy.toInt()})');

    if (_selectedWidget!.properties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Properties:');
      _selectedWidget!.properties.forEach((key, value) {
        buffer.writeln('  • $key: $value');
      });
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🌳 WIDGET HIERARCHY PATH');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    for (int i = 0; i < _widgetPath.length; i++) {
      final indent = '  ' * i;
      final widget = _widgetPath[i];
      buffer.writeln('$indent${i == _widgetPath.length - 1 ? "👉" : "↓"} ${widget.widgetType}');
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💬 USER REQUEST');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln(_noteController.text.trim());
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📝 RECOMMENDED ACTIONS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('1. Open file: ${_selectedWidget!.sourceFile}');
    buffer.writeln('2. Locate widget: ${_selectedWidget!.widgetType}');
    buffer.writeln('3. In location: ${_selectedWidget!.location}');
    buffer.writeln('4. Apply changes as described above');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app - wrapped to prevent interaction when inspector is active
        if (_isActive)
          AbsorbPointer(
            absorbing: true,
            child: Opacity(
              opacity: 0.7,
              child: widget.child,
            ),
          )
        else
          widget.child,

        // Inspector barrier layer - captures ALL events when active
        if (_isActive)
          Positioned.fill(
            child: Listener(
              onPointerDown: _handlePointerEvent,
              onPointerMove: _handlePointerEvent,
              onPointerHover: _handlePointerEvent,
              behavior: HitTestBehavior.opaque, // CRITICAL: Blocks all events
              child: CustomPaint(
                painter: _IsolatedInspectorPainter(
                  selectedWidget: _selectedWidget,
                  hoveredWidget: _hoveredWidget,
                ),
              ),
            ),
          ),

        // Inspector UI - always on top, not affected by AbsorbPointer
        if (_isActive) ...[
          Positioned(
            top: 8,
            left: 8,
            child: InspectorBanner(onClose: () => _inspector.disable()),
          ),

          if (_widgetPath.isNotEmpty)
            Positioned(
              top: 60,
              left: 8,
              right: MediaQuery.of(context).size.width / 2,
              child: WidgetPathBreadcrumb(
                path: _widgetPath,
                onSelect: (widget) => setState(() => _selectedWidget = widget),
              ),
            ),

          if (_selectedWidget != null)
            Positioned(
              top: 8,
              right: 8,
              bottom: 8,
              child: EnhancedNotePanel(
                widget: _selectedWidget!,
                noteController: _noteController,
                selectedAction: _selectedAction,
                screenshot: null,
                onActionChanged: (action) => setState(() => _selectedAction = action),
                onSendNote: _sendNoteToAI,
                onClose: _clearSelection,
              ),
            ),
        ],
      ],
    );
  }
}

/// Isolated custom painter with enhanced visual feedback
class _IsolatedInspectorPainter extends CustomPainter {
  final IDEWidgetInfo? selectedWidget;
  final IDEWidgetInfo? hoveredWidget;

  _IsolatedInspectorPainter({
    this.selectedWidget,
    this.hoveredWidget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw hover state
    if (hoveredWidget != null) {
      final hoverBounds = Rect.fromLTWH(
        hoveredWidget!.position.dx,
        hoveredWidget!.position.dy,
        hoveredWidget!.size.width,
        hoveredWidget!.size.height,
      );

      // Hover fill
      final hoverFill = Paint()
        ..color = Colors.orange.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRect(hoverBounds, hoverFill);

      // Hover border
      final hoverBorder = Paint()
        ..color = Colors.orange.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(hoverBounds, hoverBorder);
    }

    // Draw selected state
    if (selectedWidget != null) {
      final bounds = Rect.fromLTWH(
        selectedWidget!.position.dx,
        selectedWidget!.position.dy,
        selectedWidget!.size.width,
        selectedWidget!.size.height,
      );

      // Selection fill
      final fillPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(bounds, fillPaint);

      // Selection border
      final borderPaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRect(bounds, borderPaint);

      // Corner handles
      final handlePaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill;

      const handleSize = 10.0;
      canvas.drawCircle(bounds.topLeft, handleSize, handlePaint);
      canvas.drawCircle(bounds.topRight, handleSize, handlePaint);
      canvas.drawCircle(bounds.bottomLeft, handleSize, handlePaint);
      canvas.drawCircle(bounds.bottomRight, handleSize, handlePaint);

      // Dimension labels
      _drawDimensions(canvas, bounds);
    }
  }

  void _drawDimensions(Canvas canvas, Rect bounds) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.blue.shade700,
    );

    // Width label
    final widthText = '${bounds.width.toInt()}px';
    final widthPainter = TextPainter(
      text: TextSpan(text: widthText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    widthPainter.paint(
      canvas,
      Offset(bounds.center.dx - widthPainter.width / 2, bounds.bottom + 5),
    );

    // Height label
    final heightText = '${bounds.height.toInt()}px';
    final heightPainter = TextPainter(
      text: TextSpan(text: heightText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(bounds.left - 25, bounds.center.dy);
    canvas.rotate(-1.5708);
    heightPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IsolatedInspectorPainter oldDelegate) {
    return selectedWidget != oldDelegate.selectedWidget ||
           hoveredWidget != oldDelegate.hoveredWidget;
  }
}
