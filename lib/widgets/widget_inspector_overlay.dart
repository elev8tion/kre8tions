import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/widget_inspector_service.dart' as inspector;

/// Overlay that wraps around the preview to enable widget inspection
class WidgetInspectorOverlay extends StatefulWidget {
  final Widget child;

  const WidgetInspectorOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<WidgetInspectorOverlay> createState() => _WidgetInspectorOverlayState();
}

class _WidgetInspectorOverlayState extends State<WidgetInspectorOverlay> {
  final _inspector = inspector.WidgetInspectorService();
  bool _isInspecting = false;
  inspector.WidgetInspectionData? _selectedWidget;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _inspector.inspectionModeStream.listen((isInspecting) {
      setState(() => _isInspecting = isInspecting);
    });
    _inspector.selectedWidgetStream.listen((widget) {
      setState(() => _selectedWidget = widget);
    });
  }

  void _handleTap(TapDownDetails details) {
    if (!_isInspecting) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = details.localPosition;
    final widgetData = _findWidgetAtPosition(offset, box);

    if (widgetData != null) {
      _inspector.selectWidget(widgetData);
    }
  }

  void _handleHover(PointerEvent event) {
    if (!_isInspecting) return;
    setState(() => _hoverPosition = event.localPosition);
  }

  inspector.WidgetInspectionData? _findWidgetAtPosition(Offset position, RenderBox box) {
    // Try to find the deepest widget at this position
    final result = BoxHitTestResult();
    box.hitTest(result, position: position);

    RenderObject? target;
    int depth = 0;

    for (var entry in result.path) {
      if (entry.target is RenderBox) {
        target = entry.target as RenderObject;
        depth++;
      }
    }

    if (target == null || target is! RenderBox) return null;

    // Extract widget information
    return _extractWidgetData(target, depth);
  }

  inspector.WidgetInspectionData _extractWidgetData(RenderObject renderObject, int depth) {
    final box = renderObject as RenderBox;
    final bounds = Rect.fromLTWH(
      0,
      0,
      box.size.width,
      box.size.height,
    );

    final properties = <String, dynamic>{};

    // Extract common properties based on render object type
    if (renderObject is RenderParagraph) {
      properties['text'] = renderObject.text.toPlainText();
    }

    if (renderObject.parent != null) {
      properties['parentType'] = renderObject.parent.runtimeType.toString();
    }

    // Try to get widget name from render object
    String widgetType = renderObject.runtimeType.toString();
    if (widgetType.startsWith('Render')) {
      widgetType = widgetType.substring(6); // Remove 'Render' prefix
    }

    // Get children
    final children = <inspector.WidgetInspectionData>[];
    renderObject.visitChildren((child) {
      if (child is RenderBox) {
        children.add(_extractWidgetData(child, depth + 1));
      }
    });

    return inspector.WidgetInspectionData(
      widgetType: widgetType,
      bounds: bounds,
      properties: properties,
      children: children,
      depth: depth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isInspecting)
          Positioned.fill(
            child: MouseRegion(
              onHover: _handleHover,
              onExit: (_) => setState(() => _hoverPosition = null),
              child: GestureDetector(
                onTapDown: _handleTap,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.blue.withOpacity(0.1),
                  child: CustomPaint(
                    painter: _WidgetBoundsPainter(
                      selectedWidget: _selectedWidget,
                      hoverPosition: _hoverPosition,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_isInspecting && _selectedWidget != null)
          Positioned(
            top: 8,
            right: 8,
            child: _WidgetInfoPanel(widget: _selectedWidget!),
          ),
      ],
    );
  }
}

/// Custom painter to draw widget boundaries
class _WidgetBoundsPainter extends CustomPainter {
  final inspector.WidgetInspectionData? selectedWidget;
  final Offset? hoverPosition;

  _WidgetBoundsPainter({
    this.selectedWidget,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedWidget == null) return;

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw selected widget bounds
    canvas.drawRect(selectedWidget!.bounds, paint);

    // Draw children bounds with different colors
    _drawChildrenBounds(canvas, selectedWidget!.children, 1);

    // Draw hover indicator
    if (hoverPosition != null) {
      final hoverPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(hoverPosition!, 5, hoverPaint);
    }
  }

  void _drawChildrenBounds(Canvas canvas, List<inspector.WidgetInspectionData> children, int level) {
    final colors = [Colors.green, Colors.purple, Colors.orange, Colors.red];
    final color = colors[level % colors.length];

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var child in children) {
      canvas.drawRect(child.bounds, paint);
      if (child.children.isNotEmpty) {
        _drawChildrenBounds(canvas, child.children, level + 1);
      }
    }
  }

  @override
  bool shouldRepaint(_WidgetBoundsPainter oldDelegate) {
    return selectedWidget != oldDelegate.selectedWidget ||
           hoverPosition != oldDelegate.hoverPosition;
  }
}

/// Panel showing widget information
class _WidgetInfoPanel extends StatelessWidget {
  final inspector.WidgetInspectionData widget;

  const _WidgetInfoPanel({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.widgets, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.widgetType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => inspector.WidgetInspectorService().disableInspectionMode(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Depth', value: widget.depth.toString()),
                  _InfoRow(
                    label: 'Size',
                    value: '${widget.bounds.width.toStringAsFixed(1)} × ${widget.bounds.height.toStringAsFixed(1)}',
                  ),
                  _InfoRow(label: 'Children', value: widget.children.length.toString()),
                  if (widget.properties.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Properties:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    ...widget.properties.entries.map((e) =>
                      _InfoRow(label: e.key, value: e.value.toString())
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendNoteToAI(widget),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Send Note to AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendNoteToAI(inspector.WidgetInspectionData widget) {
    // This will be handled by the AI assistant panel
    debugPrint('Sending widget data to AI: ${widget.toJson()}');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
