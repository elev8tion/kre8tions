import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/ide_inspector_service.dart';

/// Precise widget selector that wraps EXACTLY around selected widgets
/// NO full-screen overlays, NO dimming, ONLY precise borders
class PreciseWidgetSelector extends StatefulWidget {
  final Widget child;

  const PreciseWidgetSelector({
    super.key,
    required this.child,
  });

  @override
  State<PreciseWidgetSelector> createState() => _PreciseWidgetSelectorState();
}

class _PreciseWidgetSelectorState extends State<PreciseWidgetSelector> {
  final _inspector = IDEInspectorService();
  bool _isActive = false;
  WidgetBounds? _selectedWidget;
  OverlayEntry? _borderOverlay;

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      setState(() {
        _isActive = active;
        if (!active) {
          _clearSelection();
        }
      });
    });
  }

  @override
  void dispose() {
    _removeBorderOverlay();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedWidget = null;
      _removeBorderOverlay();
    });
  }

  void _removeBorderOverlay() {
    _borderOverlay?.remove();
    _borderOverlay = null;
  }

  void _handleTap(TapDownDetails details) {
    if (!_isActive) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final widgetBounds = _findWidgetAtPosition(details.localPosition, box);
    if (widgetBounds != null) {
      setState(() {
        _selectedWidget = widgetBounds;
        _updateBorderOverlay();
      });
      _inspector.selectWidget(widgetBounds.info);
    }
  }

  void _updateBorderOverlay() {
    _removeBorderOverlay();
    if (_selectedWidget == null || !_isActive) return;

    _borderOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: _selectedWidget!.rect.left,
        top: _selectedWidget!.rect.top,
        width: _selectedWidget!.rect.width,
        height: _selectedWidget!.rect.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              color: Colors.blue.withValues(alpha: 0.1),
            ),
            child: Stack(
              children: [
                // Widget type label
                Positioned(
                  top: -20,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.blue,
                    child: Text(
                      _selectedWidget!.info.widgetType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Corner handles
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  left: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_borderOverlay!);
  }

  WidgetBounds? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    RenderObject? deepestTarget;
    final List<String> hierarchy = [];

    for (var entry in result.path) {
      if (entry.target is RenderBox) {
        final target = entry.target as RenderObject;
        deepestTarget = target;
        final widgetName = target.runtimeType.toString().replaceFirst('Render', '');
        if (!widgetName.startsWith('_')) {
          hierarchy.insert(0, widgetName);
        }
      }
    }

    if (deepestTarget == null || deepestTarget is! RenderBox) return null;

    final box = deepestTarget;
    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;

    final info = IDEWidgetInfo(
      widgetType: hierarchy.isEmpty ? 'Widget' : hierarchy.last,
      location: 'Screen',
      sourceFile: 'lib/screens/home_page.dart',
      size: size,
      position: topLeft,
      properties: {},
      parentChain: hierarchy,
    );

    return WidgetBounds(
      rect: Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height),
      info: info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isActive ? _handleTap : null,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

/// Holds exact bounds information for a widget
class WidgetBounds {
  final Rect rect;
  final IDEWidgetInfo info;

  WidgetBounds({
    required this.rect,
    required this.info,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetBounds && other.rect == rect;
  }

  @override
  int get hashCode => rect.hashCode;
}
