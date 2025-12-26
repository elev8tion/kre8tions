import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import '../services/ide_inspector_service.dart';
import 'enhanced_ide_inspector_widgets.dart';

/// Holds exact source location for a widget
class WidgetSourceLocation {
  final String file;
  final int line;
  final int? column;

  WidgetSourceLocation({required this.file, required this.line, this.column});

  @override
  String toString() => '$file:$line${column != null ? ':$column' : ''}';

  /// Get just the filename without the full path
  String get shortFile {
    final parts = file.split('/');
    return parts.length > 1 ? parts.sublist(parts.length - 2).join('/') : file;
  }
}

/// Try to extract widget creation location using multiple methods
WidgetSourceLocation? _extractWidgetSourceLocation(Widget widget, Element? element) {
  debugPrint('🔍 Attempting source location extraction for: ${widget.runtimeType}');

  // Method 1: Try via DiagnosticsNode JSON (works with --track-widget-creation)
  try {
    final node = widget.toDiagnosticsNode();
    final json = node.toJsonMap(const DiagnosticsSerializationDelegate(
      subtreeDepth: 0,
      includeProperties: true,
    ));

    // Debug: Show what keys are available in the JSON
    debugPrint('  JSON keys: ${json.keys.take(10).join(", ")}${json.keys.length > 10 ? "..." : ""}');

    if (json.containsKey('creationLocation')) {
      final loc = json['creationLocation'] as Map<String, dynamic>?;
      if (loc != null) {
        final file = loc['file'] as String?;
        final line = loc['line'] as int?;
        final column = loc['column'] as int?;
        if (file != null && line != null) {
          debugPrint('📍 Found location via JSON: $file:$line');
          return WidgetSourceLocation(file: file, line: line, column: column);
        }
      }
    }

    // Check properties for location info
    final props = node.getProperties();
    debugPrint('  Properties count: ${props.length}');
    for (final prop in props) {
      final name = prop.name?.toLowerCase() ?? '';
      if (name.contains('location') || name.contains('source') || name.contains('file')) {
        debugPrint('  Found prop: ${prop.name} = ${prop.value}');
        final value = prop.value;
        if (value != null) {
          final str = value.toString();
          final match = RegExp(r'([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(str);
          if (match != null) {
            debugPrint('📍 Found location via property: $str');
            return WidgetSourceLocation(
              file: match.group(1)!,
              line: int.parse(match.group(2)!),
              column: match.group(3) != null ? int.parse(match.group(3)!) : null,
            );
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Method 1 (JSON) failed: $e');
  }

  // Method 2: Try via Element's widget debug info
  if (element != null) {
    try {
      final widgetNode = element.widget.toDiagnosticsNode();
      final desc = widgetNode.toDescription();
      // Sometimes description contains location info
      final match = RegExp(r'([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(desc);
      if (match != null) {
        debugPrint('📍 Found location via description: $desc');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 2 (description) failed: $e');
    }
  }

  // Method 3: Check if widget has any debug properties with location
  try {
    final props = widget.toDiagnosticsNode().getProperties();
    for (final prop in props) {
      try {
        // prop is already a DiagnosticsNode
        final propJson = prop.toJsonMap(const DiagnosticsSerializationDelegate());
        if (propJson.containsKey('locationUri') || propJson.containsKey('file')) {
          final file = propJson['locationUri'] ?? propJson['file'];
          final line = propJson['locationLine'] ?? propJson['line'];
          if (file != null && line != null) {
            debugPrint('📍 Found location via prop JSON: $file:$line');
            return WidgetSourceLocation(file: file.toString(), line: line as int);
          }
        }
      } catch (_) {}
    }
  } catch (e) {
    debugPrint('Method 3 (prop JSON) failed: $e');
  }

  // Method 4: Parse from widget's debug representation (e.g., "Text:file:///.../file.dart:123:45")
  try {
    final widgetString = widget.toString();
    // Match pattern like: "file:///path/to/file.dart:123:45" or "file.dart:123:45"
    final fileMatch = RegExp(r'(?:file:\/\/\/)?([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(widgetString);
    if (fileMatch != null) {
      final file = fileMatch.group(1)!;
      final line = int.parse(fileMatch.group(2)!);
      final column = fileMatch.group(3) != null ? int.parse(fileMatch.group(3)!) : null;
      debugPrint('📍 Found location via toString: $file:$line');
      return WidgetSourceLocation(file: file, line: line, column: column);
    }
  } catch (e) {
    debugPrint('Method 4 (toString) failed: $e');
  }

  // Method 5: Try accessing widget's debugLabel or toStringShort
  if (element != null) {
    try {
      final elementDesc = element.toStringShort();
      final match = RegExp(r'(?:file:\/\/\/)?([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(elementDesc);
      if (match != null) {
        debugPrint('📍 Found location via element toStringShort: ${match.group(0)}');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 5 (toStringShort) failed: $e');
    }

    // Method 6: Try full toString representation which includes locations in debug mode
    try {
      // Use toStringDeep which includes more detailed debug info
      final deepString = element.toStringDeep();
      final match = RegExp(r'(?:file:\/\/\/)?([^:\s]+\.dart):(\d+)(?::(\d+))?').firstMatch(deepString);
      if (match != null) {
        debugPrint('📍 Found location via toStringDeep: ${match.group(0)}');
        return WidgetSourceLocation(
          file: match.group(1)!,
          line: int.parse(match.group(2)!),
          column: match.group(3) != null ? int.parse(match.group(3)!) : null,
        );
      }
    } catch (e) {
      debugPrint('Method 6 (toStringDeep) failed: $e');
    }
  }

  return null;
}

/// Precise widget selector that wraps EXACTLY around selected widgets
/// Shows hover highlighting and precise borders for individual widgets
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
  WidgetBounds? _hoveredWidget;
  List<IDEWidgetInfo> _widgetPath = [];
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      if (mounted) {
        setState(() {
          _isActive = active;
          if (!active) {
            _clearSelection();
          }
        });
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

  // Key for the child widget to get its RenderBox
  final GlobalKey _childKey = GlobalKey();

  void _handlePointerHover(Offset localPosition) {
    if (!_isActive) return;

    // Get the child's render box for hit testing
    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    final widgetBounds = _findWidgetAtPosition(localPosition, childBox);
    if (widgetBounds != null && widgetBounds != _hoveredWidget) {
      setState(() => _hoveredWidget = widgetBounds);
    }
  }

  void _handlePointerDown(Offset localPosition) {
    if (!_isActive) return;

    // Get the child's render box for hit testing
    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    final widgetBounds = _findWidgetAtPosition(localPosition, childBox);
    if (widgetBounds != null) {
      setState(() {
        _selectedWidget = widgetBounds;
        _hoveredWidget = null;
        _widgetPath = _buildWidgetPath(widgetBounds.info);
      });
      _inspector.selectWidget(widgetBounds.info);
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

  WidgetBounds? _findWidgetAtPosition(Offset position, RenderBox rootBox) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    RenderObject? bestTarget;
    final List<String> hierarchy = [];
    final pathList = result.path.toList(); // Convert to list for reverse iteration

    // Debug: print all widgets found in path
    debugPrint('🔍 Hit test path (${pathList.length} entries):');

    // Build hierarchy from result path (Flutter hit test goes ROOT → DEEPEST)
    // So forward iteration gives us root-to-deepest order for the hierarchy
    for (var entry in pathList) {
      if (entry.target is RenderBox) {
        final rawName = entry.target.runtimeType.toString();
        final widgetName = _getCleanWidgetName(entry.target as RenderObject);
        debugPrint('  - Raw: $rawName -> Clean: "$widgetName" (semantic: ${widgetName.isNotEmpty && _isSemanticWidget(widgetName)})');
        if (widgetName.isNotEmpty) {
          hierarchy.add(widgetName); // Add in order (root to deepest)
        }
      }
    }

    // Iterate FORWARD to find innermost (deepest) semantic widget
    // Flutter's hit test path goes DEEPEST → ROOT, so FIRST entries are the innermost
    debugPrint('🔄 Starting selection loop FORWARD (${pathList.length} entries)...');
    for (var i = 0; i < pathList.length; i++) {
      final entry = pathList[i];
      if (entry.target is RenderBox) {
        final target = entry.target as RenderObject;
        final widgetName = _getCleanWidgetName(target);
        final isSemantic = widgetName.isNotEmpty && _isSemanticWidget(widgetName);
        debugPrint('  [$i] "$widgetName" isRenderBox:true semantic:$isSemantic');

        if (isSemantic) {
          debugPrint('✅ Selected at index $i: $widgetName');
          bestTarget = target;
          break; // Found innermost semantic widget, stop
        }

        // Track as fallback if no semantic widget found yet
        bestTarget ??= target;
      } else {
        debugPrint('  [$i] NOT a RenderBox, skipping');
      }
    }

    if (bestTarget == null || bestTarget is! RenderBox) return null;

    final bounds = _extractWidgetBounds(bestTarget, hierarchy, position);
    debugPrint('📦 Final selection: ${bounds.info.widgetType} (${bounds.rect.width.toInt()}x${bounds.rect.height.toInt()})');
    return bounds;
  }

  String _getCleanWidgetName(RenderObject renderObject) {
    String name = renderObject.runtimeType.toString();

    if (name.startsWith('Render')) {
      name = name.substring(6);
    }

    // Filter out internal/utility widgets that users don't care about
    const internalPrefixes = [
      '_', 'Listener', 'Semantics', 'Pipeline', 'Offstage', 'View',
      'RepaintBoundary', 'AnnotatedRegion', 'Focus', 'Actions',
      'Shortcuts', 'DefaultTextEditingShortcuts', 'Scrollable',
    ];

    for (final prefix in internalPrefixes) {
      if (name.startsWith(prefix)) return '';
    }

    return name;
  }

  bool _isSemanticWidget(String name) {
    // These are RenderObject names (after "Render" prefix removed)
    // Higher priority = more specific widgets users want to select
    const highPriorityWidgets = [
      // Text/Paragraph widgets (RenderParagraph becomes "Paragraph")
      'Paragraph', 'EditableText', 'RichText',
      // Buttons and interactive
      'Button', 'InkWell', 'GestureDetector', 'Ink',
      // Icons and images
      'Icon', 'Image', 'CircleAvatar',
      // Input widgets
      'TextField', 'Checkbox', 'Switch', 'Slider',
      // Cards and chips
      'Card', 'Chip', 'Tooltip',
    ];

    // Lower priority - layout widgets
    const layoutWidgets = [
      'Container', 'DecoratedBox', 'ConstrainedBox', 'SizedBox',
      'Padding', 'Center', 'Align', 'ClipRRect', 'ClipOval',
      'Row', 'Column', 'Flex', 'Wrap',
      'Stack', 'Positioned', 'Expanded', 'Flexible',
      'ListView', 'GridView', 'CustomScrollView',
      'Scaffold', 'AppBar', 'Drawer', 'Dialog', 'Material',
      'Transform', 'Opacity', 'AnimatedContainer', 'AnimatedOpacity',
    ];

    // Check high priority first - these are the specific widgets
    for (final widget in highPriorityWidgets) {
      if (name.contains(widget)) return true;
    }

    // Then check layout widgets
    for (final widget in layoutWidgets) {
      if (name.contains(widget)) return true;
    }

    return false;
  }

  WidgetBounds _extractWidgetBounds(RenderBox box, List<String> hierarchy, Offset tapPosition) {
    final size = box.size;
    final position = box.localToGlobal(Offset.zero);

    String uiLocation = _detectLocation(hierarchy, position);
    String sourceFile = _detectSourceFile(uiLocation);
    int? lineNumber;

    final properties = <String, dynamic>{};

    // Extract properties based on render object type
    if (box is RenderParagraph) {
      properties['text'] = box.text.toPlainText();
    }

    if (box is RenderDecoratedBox) {
      final decoration = box.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        properties['color'] = decoration.color.toString();
      }
    }

    // Get actual Widget name from Element tree (not just RenderObject name)
    String widgetType = _getActualWidgetName(box);
    Element? targetElement;
    Widget? targetWidget;

    // Try to get Element via DebugCreator for source location extraction
    final creator = box.debugCreator;
    if (creator is DebugCreator) {
      targetElement = creator.element;
      targetWidget = targetElement.widget;

      // Try to extract exact source file and line number
      final sourceLocation = _extractWidgetSourceLocation(targetWidget, targetElement);
      if (sourceLocation != null) {
        sourceFile = sourceLocation.file;
        lineNumber = sourceLocation.line;
        debugPrint('🎯 EXACT LOCATION: ${sourceLocation.shortFile}:$lineNumber');
      }
    }

    if (widgetType.isEmpty) {
      widgetType = _getCleanWidgetName(box);
    }
    if (widgetType.isEmpty) {
      widgetType = hierarchy.isNotEmpty ? hierarchy.last : 'Widget';
    }

    // Get widget hierarchy with actual widget names
    final widgetHierarchy = _getWidgetHierarchy(box);

    final info = IDEWidgetInfo(
      widgetType: widgetType,
      location: uiLocation,
      sourceFile: sourceFile,
      lineNumber: lineNumber,
      size: size,
      position: position,
      properties: properties,
      parentChain: widgetHierarchy.isNotEmpty ? widgetHierarchy : hierarchy,
    );

    return WidgetBounds(
      rect: Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
      info: info,
    );
  }

  /// Get the actual Widget class name from the RenderObject using DebugCreator
  /// Reference: https://api.flutter.dev/flutter/widgets/DebugCreator-class.html
  String _getActualWidgetName(RenderObject renderObject) {
    // Use debugCreator to get the Element that created this RenderObject
    final creator = renderObject.debugCreator;
    if (creator is DebugCreator) {
      Element element = creator.element;

      // Walk up the Element tree to find a user-facing widget
      Element? current = element;
      while (current != null) {
        final widgetName = current.widget.runtimeType.toString();
        if (_isUserFacingWidget(widgetName)) {
          debugPrint('🎯 Found widget via DebugCreator: $widgetName');
          return widgetName;
        }
        current = _getParentElement(current);
      }

      // If no user-facing widget found, return the direct widget name
      return element.widget.runtimeType.toString();
    }

    // Fallback: map RenderObject names to Widget names
    debugPrint('⚠️ No DebugCreator found, using fallback mapping');
    return _mapRenderToWidgetName(renderObject);
  }

  /// Get the widget hierarchy with actual Widget names using DebugCreator
  List<String> _getWidgetHierarchy(RenderObject renderObject) {
    final hierarchy = <String>[];

    final creator = renderObject.debugCreator;
    if (creator is DebugCreator) {
      Element? element = creator.element;
      int depth = 0;

      while (element != null && depth < 25) {
        final widgetName = element.widget.runtimeType.toString();

        // Only include user-facing widgets
        if (_isUserFacingWidget(widgetName)) {
          hierarchy.add(widgetName);
        }

        element = _getParentElement(element);
        depth++;
      }
    }

    // If no hierarchy found via DebugCreator, build from RenderObject names
    if (hierarchy.isEmpty) {
      debugPrint('⚠️ Building fallback hierarchy from RenderObject');
    }

    return hierarchy;
  }

  Element? _getParentElement(Element element) {
    Element? parent;
    element.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    return parent;
  }

  /// Map common RenderObject names to their Widget equivalents
  String _mapRenderToWidgetName(RenderObject renderObject) {
    final renderName = renderObject.runtimeType.toString();

    // Common mappings
    const mappings = {
      'RenderParagraph': 'Text',
      'RenderFlex': 'Row/Column',
      'RenderDecoratedBox': 'Container/DecoratedBox',
      'RenderPadding': 'Padding',
      'RenderConstrainedBox': 'SizedBox/ConstrainedBox',
      'RenderPositionedBox': 'Center/Align',
      'RenderClipRRect': 'ClipRRect',
      'RenderClipOval': 'ClipOval',
      'RenderClipRect': 'ClipRect',
      'RenderOpacity': 'Opacity',
      'RenderAnimatedOpacity': 'AnimatedOpacity',
      'RenderTransform': 'Transform',
      'RenderImage': 'Image',
      'RenderPhysicalModel': 'Material/PhysicalModel',
      'RenderPhysicalShape': 'PhysicalShape',
      'RenderSliverList': 'ListView',
      'RenderSliverGrid': 'GridView',
      'RenderStack': 'Stack',
      'RenderIndexedStack': 'IndexedStack',
      'RenderWrap': 'Wrap',
      'RenderFlow': 'Flow',
      'RenderTable': 'Table',
      'RenderEditable': 'TextField',
      'RenderListBody': 'ListBody',
    };

    return mappings[renderName] ?? renderName.replaceFirst('Render', '');
  }

  bool _isUserFacingWidget(String name) {
    if (name.startsWith('_')) return false;

    // Skip internal/implementation Flutter widgets
    // These are low-level widgets that users don't write directly
    const internalWidgets = {
      // Framework internals
      'RenderObjectToWidgetAdapter', 'View', 'RawView',
      'Semantics', 'MergeSemantics', 'BlockSemantics',
      'ExcludeSemantics', 'IndexedSemantics',
      'Focus', 'FocusScope', 'FocusTrap', 'TapRegionSurface',
      'Actions', 'Shortcuts', 'DefaultTextEditingShortcuts',
      'CallbackShortcuts', 'PrimaryScrollController',
      'ScrollConfiguration', 'ScrollNotificationObserver',
      'NotificationListener', 'RepaintBoundary',
      'KeepAlive', 'AutomaticKeepAlive', 'SliverKeepAlive',
      'KeyedSubtree', 'Builder', 'StatefulBuilder',
      'IgnorePointer', 'AbsorbPointer', 'MetaData',
      'Listener', 'MouseRegion', 'RawGestureDetector',
      'CustomPaint', 'CustomSingleChildLayout', 'CustomMultiChildLayout',
      'LayoutBuilder', 'OrientationBuilder', 'MediaQuery',
      'InheritedElement', 'InheritedWidget', 'InheritedTheme',
      'TickerMode', 'Offstage', 'Visibility',
      'Directionality',

      // Low-level rendering widgets (Container uses these internally)
      'DecoratedBox', 'ColoredBox', 'ConstrainedBox', 'LimitedBox',
      'OverflowBox', 'SizedOverflowBox', 'FractionallySizedBox',
      'Padding', 'Align', 'Center', 'FittedBox', 'AspectRatio',
      'IntrinsicWidth', 'IntrinsicHeight', 'Baseline',
      'ClipRect', 'ClipRRect', 'ClipOval', 'ClipPath',
      'PhysicalModel', 'PhysicalShape', 'Transform',
      'CompositedTransformTarget', 'CompositedTransformFollower',
      'FadeTransition', 'ScaleTransition', 'RotationTransition',
      'SlideTransition', 'SizeTransition', 'PositionedTransition',
      'DecoratedBoxTransition', 'AlignTransition', 'DefaultTextStyleTransition',

      // Text rendering internals
      'RichText', 'RawImage',

      // Layout internals
      'Expanded', 'Flexible', 'Spacer', 'SizedBox',
      'Positioned', 'PositionedDirectional',

      // Scroll internals
      'Scrollable', 'Viewport', 'ShrinkWrappingViewport',
      'SingleChildScrollView',
    };

    return !internalWidgets.contains(name);
  }

  String _detectLocation(List<String> hierarchy, Offset position) {
    final hierarchyStr = hierarchy.join(' ');
    final screenWidth = MediaQuery.of(context).size.width;

    if (position.dx < 300) return 'File Tree Panel (Left)';
    if (position.dx > screenWidth - 400) {
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
    if (location.contains('App Bar')) return 'lib/screens/home_page.dart';
    return 'lib/screens/home_page.dart';
  }

  Widget _cornerHandle() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _sendNoteToAI() async {
    if (_selectedWidget == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note about what you want changed')),
      );
      return;
    }

    final success = await _inspector.sendNoteToAI(
      _selectedWidget!.info,
      _noteController.text.trim(),
      action: _selectedAction,
    );

    if (!mounted) return;

    if (success) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Failed to copy to clipboard. Try again.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _noteController.clear();
  }

  /// Convert global position to local position relative to this widget's Stack
  Rect _globalToLocal(Rect globalRect) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return globalRect;
    final localOffset = box.globalToLocal(Offset(globalRect.left, globalRect.top));
    return Rect.fromLTWH(localOffset.dx, localOffset.dy, globalRect.width, globalRect.height);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content - rendered first (at bottom of stack)
        // Wrapped with key to access its RenderBox for hit testing
        KeyedSubtree(
          key: _childKey,
          child: widget.child,
        ),

        // Event interception overlay - on TOP of the child when inspector is active
        // Uses GestureDetector with opaque behavior to capture all taps
        if (_isActive)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                debugPrint('🎯 Inspector overlay received tap at: ${details.localPosition}');
                _handlePointerDown(details.localPosition);
              },
              onPanStart: (details) {
                // Also capture drag starts to prevent scrolling etc.
                debugPrint('🎯 Inspector overlay received drag at: ${details.localPosition}');
              },
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                onHover: (event) => _handlePointerHover(event.localPosition),
                onExit: (_) => setState(() => _hoveredWidget = null),
                // Slightly visible for debugging - remove later
                child: Container(color: Colors.black.withValues(alpha: 0.01)),
              ),
            ),
          ),

        // Hover highlight overlay - convert global to local coordinates
        if (_isActive && _hoveredWidget != null && _hoveredWidget != _selectedWidget)
          Builder(builder: (context) {
            final localRect = _globalToLocal(_hoveredWidget!.rect);
            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.orange.shade600, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _hoveredWidget!.info.widgetType,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        // Selection highlight overlay - convert global to local coordinates
        if (_isActive && _selectedWidget != null)
          Builder(builder: (context) {
            final localRect = _globalToLocal(_selectedWidget!.rect);
            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.blue.shade700, width: 3),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Widget type label
                    Positioned(
                      top: -24,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedWidget!.info.widgetType,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Corner handles
                    Positioned(top: -5, left: -5, child: _cornerHandle()),
                    Positioned(top: -5, right: -5, child: _cornerHandle()),
                    Positioned(bottom: -5, left: -5, child: _cornerHandle()),
                    Positioned(bottom: -5, right: -5, child: _cornerHandle()),
                    // Width label
                    Positioned(
                      bottom: -20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${_selectedWidget!.rect.width.toInt()}px',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            );
          }),

        // Inspector UI elements
        if (_isActive) ...[
          // Inspector banner
          Positioned(
            top: 8,
            left: 8,
            child: InspectorBanner(onClose: () => _inspector.disable()),
          ),

          // Widget path breadcrumb
          if (_widgetPath.isNotEmpty)
            Positioned(
              top: 60,
              left: 8,
              right: MediaQuery.of(context).size.width / 2,
              child: WidgetPathBreadcrumb(
                path: _widgetPath,
                onSelect: (widget) {
                  final bounds = WidgetBounds(
                    rect: Rect.fromLTWH(
                      widget.position.dx,
                      widget.position.dy,
                      widget.size.width,
                      widget.size.height,
                    ),
                    info: widget,
                  );
                  setState(() => _selectedWidget = bounds);
                },
              ),
            ),

          // Enhanced note panel
          if (_selectedWidget != null)
            Positioned(
              top: 8,
              right: 8,
              bottom: 8,
              child: EnhancedNotePanel(
                widget: _selectedWidget!.info,
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
