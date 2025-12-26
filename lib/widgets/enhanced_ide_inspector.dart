import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../services/ide_inspector_service.dart';
import 'enhanced_ide_inspector_widgets.dart';

/// Enhanced IDE Inspector with better selection and communication
class EnhancedIDEInspector extends StatefulWidget {
  final Widget child;

  const EnhancedIDEInspector({
    super.key,
    required this.child,
  });

  @override
  State<EnhancedIDEInspector> createState() => _EnhancedIDEInspectorState();
}

class _EnhancedIDEInspectorState extends State<EnhancedIDEInspector> {
  final _inspector = IDEInspectorService();
  bool _isActive = false;
  IDEWidgetInfo? _selectedWidget;
  IDEWidgetInfo? _hoveredWidget;
  List<IDEWidgetInfo> _widgetPath = [];
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;
  ui.Image? _screenshot;

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

  void _handleTap(TapDownDetails details) {
    if (!_isActive) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = details.localPosition;
    final widgetInfo = _findWidgetAtPosition(offset, box);

    if (widgetInfo != null) {
      setState(() {
        _selectedWidget = widgetInfo;
        _widgetPath = _buildWidgetPath(widgetInfo);
      });
      _inspector.selectWidget(widgetInfo);
      _captureScreenshot();
    }
  }

  void _handleHover(PointerEvent event) {
    if (!_isActive) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final widgetInfo = _findWidgetAtPosition(event.localPosition, box);
    if (widgetInfo != null && widgetInfo != _hoveredWidget) {
      setState(() => _hoveredWidget = widgetInfo);
    }
  }

  List<IDEWidgetInfo> _buildWidgetPath(IDEWidgetInfo widget) {
    final path = <IDEWidgetInfo>[];

    // Build path from root to this widget
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

  Future<void> _captureScreenshot() async {
    try {
      final RenderRepaintBoundary? boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      setState(() => _screenshot = image);
    } catch (e) {
      debugPrint('Screenshot capture failed: $e');
    }
  }

  IDEWidgetInfo? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    RenderObject? deepestTarget;
    final List<String> hierarchy = [];
    Rect? targetBounds;

    for (var entry in result.path) {
      if (entry.target is RenderBox) {
        final target = entry.target as RenderObject;
        deepestTarget = target;

        // Build hierarchy
        final widgetName = _getWidgetName(target);
        if (widgetName.isNotEmpty && !widgetName.startsWith('_') && widgetName != 'Listener') {
          hierarchy.insert(0, widgetName);
        }

        // Get bounds of deepest target
        if (entry.target is RenderBox) {
          final box = entry.target as RenderBox;
          targetBounds = Rect.fromLTWH(
            box.localToGlobal(Offset.zero).dx,
            box.localToGlobal(Offset.zero).dy,
            box.size.width,
            box.size.height,
          );
        }
      }
    }

    if (deepestTarget == null || deepestTarget is! RenderBox) return null;

    return _extractIDEWidgetInfo(deepestTarget, hierarchy, targetBounds);
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

    // Filter out internal widgets
    if (name.contains('Pipeline') ||
        name.contains('View') ||
        name.contains('Semantics') ||
        name.contains('Offstage')) {
      return '';
    }

    return name;
  }

  IDEWidgetInfo _extractIDEWidgetInfo(RenderObject renderObject, List<String> hierarchy, Rect? bounds) {
    final box = renderObject as RenderBox;
    final size = box.size;
    final position = box.localToGlobal(Offset.zero);

    // Smart location detection based on hierarchy and position
    String location = _detectLocation(hierarchy, position);
    String sourceFile = _detectSourceFile(location, hierarchy);

    final properties = <String, dynamic>{};

    // Extract text if it's a text widget
    if (renderObject is RenderParagraph) {
      properties['text'] = renderObject.text.toPlainText();
      properties['textAlign'] = renderObject.textAlign.toString();
    }

    // Extract color if available
    if (renderObject is RenderDecoratedBox) {
      final decoration = renderObject.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        properties['color'] = decoration.color.toString();
      }
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

  String _detectLocation(List<String> hierarchy, Offset position) {
    final hierarchyStr = hierarchy.join(' ');

    // Detect based on position (left, center, right panels)
    if (position.dx < 300) {
      return 'File Tree Panel (Left)';
    } else if (position.dx > MediaQuery.of(context).size.width - 400) {
      if (hierarchyStr.contains('AI') || hierarchyStr.contains('Assistant')) {
        return 'AI Assistant Panel (Right)';
      }
      return 'Properties Panel (Right)';
    }

    // Detect based on hierarchy
    if (hierarchyStr.contains('FileTree') || hierarchyStr.contains('file')) {
      return 'File Tree Panel';
    } else if (hierarchyStr.contains('CodeEditor') || hierarchyStr.contains('Editor')) {
      return 'Code Editor Panel';
    } else if (hierarchyStr.contains('Preview') || hierarchyStr.contains('Device')) {
      return 'UI Preview Panel';
    } else if (hierarchyStr.contains('AI') || hierarchyStr.contains('Assistant')) {
      return 'AI Assistant Panel';
    } else if (hierarchyStr.contains('Terminal')) {
      return 'Terminal Panel';
    } else if (hierarchyStr.contains('AppBar') || position.dy < 60) {
      return 'Top App Bar';
    }

    return 'Main Layout Area';
  }

  String _detectSourceFile(String location, List<String> hierarchy) {
    if (location.contains('File Tree')) return 'lib/widgets/file_tree_view.dart';
    if (location.contains('Code Editor')) return 'lib/widgets/enhanced_code_editor.dart';
    if (location.contains('Preview')) return 'lib/widgets/ui_preview_panel.dart';
    if (location.contains('AI Assistant')) return 'lib/widgets/ai_assistant_panel.dart';
    if (location.contains('Terminal')) return 'lib/widgets/terminal_panel.dart';
    if (location.contains('Properties')) return 'lib/widgets/widget_inspector_panel.dart';
    return 'lib/screens/home_page.dart';
  }

  void _sendNoteToAI() {
    if (_selectedWidget == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note about what you want changed')),
      );
      return;
    }

    _inspector.sendNoteToAI(
      _selectedWidget!,
      _noteController.text.trim(),
      action: _selectedAction,
    );

    // Create enhanced formatted note
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
        // Main app
        widget.child,

        // Enhanced inspector overlay
        if (_isActive)
          Positioned.fill(
            child: MouseRegion(
              onHover: _handleHover,
              onExit: (_) => setState(() => _hoveredWidget = null),
              child: GestureDetector(
                onTapDown: _handleTap,
                behavior: HitTestBehavior.translucent,
                child: CustomPaint(
                  painter: _EnhancedInspectorPainter(
                    selectedWidget: _selectedWidget,
                    hoveredWidget: _hoveredWidget,
                  ),
                ),
              ),
            ),
          ),

        // Floating inspector banner
        if (_isActive)
          Positioned(
            top: 8,
            left: 8,
            child: InspectorBanner(onClose: () => _inspector.disable()),
          ),

        // Widget path breadcrumb
        if (_isActive && _widgetPath.isNotEmpty)
          Positioned(
            top: 60,
            left: 8,
            right: MediaQuery.of(context).size.width / 2,
            child: WidgetPathBreadcrumb(
              path: _widgetPath,
              onSelect: (widget) => setState(() => _selectedWidget = widget),
            ),
          ),

        // Enhanced note panel
        if (_isActive && _selectedWidget != null)
          Positioned(
            top: 8,
            right: 8,
            bottom: 8,
            child: EnhancedNotePanel(
              widget: _selectedWidget!,
              noteController: _noteController,
              selectedAction: _selectedAction,
              screenshot: _screenshot,
              onActionChanged: (action) => setState(() => _selectedAction = action),
              onSendNote: _sendNoteToAI,
              onClose: _clearSelection,
            ),
          ),
      ],
    );
  }
}

/// Custom painter for enhanced visual feedback
class _EnhancedInspectorPainter extends CustomPainter {
  final IDEWidgetInfo? selectedWidget;
  final IDEWidgetInfo? hoveredWidget;

  _EnhancedInspectorPainter({
    this.selectedWidget,
    this.hoveredWidget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw hovered widget
    if (hoveredWidget != null) {
      final hoverBounds = Rect.fromLTWH(
        hoveredWidget!.position.dx,
        hoveredWidget!.position.dy,
        hoveredWidget!.size.width,
        hoveredWidget!.size.height,
      );

      final hoverPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final hoverBorder = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(hoverBounds, hoverPaint);
      canvas.drawRect(hoverBounds, hoverBorder);
    }

    // Draw selected widget
    if (selectedWidget != null) {
      final bounds = Rect.fromLTWH(
        selectedWidget!.position.dx,
        selectedWidget!.position.dy,
        selectedWidget!.size.width,
        selectedWidget!.size.height,
      );

      // Fill
      final fillPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(bounds, fillPaint);

      // Animated border
      final borderPaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(bounds, borderPaint);

      // Corner handles
      final handlePaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill;

      final handleSize = 10.0;
      canvas.drawCircle(bounds.topLeft, handleSize, handlePaint);
      canvas.drawCircle(bounds.topRight, handleSize, handlePaint);
      canvas.drawCircle(bounds.bottomLeft, handleSize, handlePaint);
      canvas.drawCircle(bounds.bottomRight, handleSize, handlePaint);

      // Draw dimension lines
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

    // Width dimension
    final widthText = '${bounds.width.toInt()}px';
    final widthSpan = TextSpan(text: widthText, style: textStyle);
    final widthPainter = TextPainter(
      text: widthSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    widthPainter.paint(
      canvas,
      Offset(
        bounds.center.dx - widthPainter.width / 2,
        bounds.bottom + 5,
      ),
    );

    // Height dimension
    final heightText = '${bounds.height.toInt()}px';
    final heightSpan = TextSpan(text: heightText, style: textStyle);
    final heightPainter = TextPainter(
      text: heightSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(bounds.left - 25, bounds.center.dy);
    canvas.rotate(-1.5708); // -90 degrees
    heightPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EnhancedInspectorPainter oldDelegate) {
    return selectedWidget != oldDelegate.selectedWidget ||
           hoveredWidget != oldDelegate.hoveredWidget;
  }
}

// Continued in next message due to length...
