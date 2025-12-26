import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/ide_inspector_service.dart';
import '../services/enhanced_hit_test_processor.dart';
import '../services/widget_instance_tracker.dart';
import '../services/project_source_search_service.dart';
import '../services/app_state_manager.dart';
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
/// Enhanced based on DiDi DoKit source_code_kit.dart patterns
WidgetSourceLocation? _extractWidgetSourceLocation(Widget widget, Element? element) {
  debugPrint('🔍 Attempting source location extraction for: ${widget.runtimeType}');

  // Method 1: Try via DiagnosticsNode JSON (works with --track-widget-creation)
  // Based on DiDi DoKit pattern for parsing creationLocation
  try {
    final node = widget.toDiagnosticsNode();
    final json = node.toJsonMap(const DiagnosticsSerializationDelegate(
      subtreeDepth: 0,
      includeProperties: true,
    ));

    // Debug: Show what keys are available in the JSON
    debugPrint('  JSON keys: ${json.keys.take(10).join(", ")}${json.keys.length > 10 ? "..." : ""}');

    // Primary: Check creationLocation (standard Flutter debug key)
    if (json.containsKey('creationLocation')) {
      final loc = json['creationLocation'] as Map<String, dynamic>?;
      if (loc != null) {
        final file = loc['file'] as String?;
        final line = loc['line'] as int?;
        final column = loc['column'] as int?;
        if (file != null && line != null) {
          debugPrint('📍 Found location via JSON creationLocation: $file:$line');
          return WidgetSourceLocation(file: file, line: line, column: column);
        }
      }
    }

    // Alternative keys used by some Flutter versions (from DoKit research)
    const locationKeys = ['locationId', 'locationFile', 'source', 'debugLocation'];
    for (final key in locationKeys) {
      if (json.containsKey(key)) {
        final value = json[key];
        if (value is String) {
          final match = RegExp(r'([^:]+\.dart):(\d+)(?::(\d+))?').firstMatch(value);
          if (match != null) {
            debugPrint('📍 Found location via $key: $value');
            return WidgetSourceLocation(
              file: match.group(1)!,
              line: int.parse(match.group(2)!),
              column: match.group(3) != null ? int.parse(match.group(3)!) : null,
            );
          }
        } else if (value is Map<String, dynamic>) {
          final file = value['file'] ?? value['path'];
          final line = value['line'] ?? value['lineNumber'];
          if (file != null && line != null) {
            debugPrint('📍 Found location via $key map: $file:$line');
            return WidgetSourceLocation(
              file: file.toString(),
              line: line is int ? line : int.parse(line.toString()),
              column: value['column'] as int?,
            );
          }
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

    // Try to extract from debugFillProperties output (DoKit pattern)
    try {
      final description = node.toDescription();
      if (description.contains('.dart:')) {
        final match = RegExp(r'([^\s:]+\.dart):(\d+)(?::(\d+))?').firstMatch(description);
        if (match != null) {
          debugPrint('📍 Found location via description: ${match.group(0)}');
          return WidgetSourceLocation(
            file: match.group(1)!,
            line: int.parse(match.group(2)!),
            column: match.group(3) != null ? int.parse(match.group(3)!) : null,
          );
        }
      }
    } catch (_) {}
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

  // Method 7: Walk up the Element tree looking for creationLocation in ancestors
  // (inspired by DevTools debugGetDiagnosticChain pattern)
  if (element != null) {
    try {
      Element? current = element;
      int depth = 0;
      while (current != null && depth < 15) {
        try {
          final ancestorWidget = current.widget;
          final ancestorNode = ancestorWidget.toDiagnosticsNode();
          final ancestorJson = ancestorNode.toJsonMap(const DiagnosticsSerializationDelegate(
            subtreeDepth: 0,
            includeProperties: true,
          ));

          if (ancestorJson.containsKey('creationLocation')) {
            final loc = ancestorJson['creationLocation'] as Map<String, dynamic>?;
            if (loc != null) {
              final file = loc['file'] as String?;
              final line = loc['line'] as int?;
              final column = loc['column'] as int?;
              if (file != null && line != null) {
                debugPrint('📍 Found location via ancestor chain (depth $depth): $file:$line');
                return WidgetSourceLocation(file: file, line: line, column: column);
              }
            }
          }
        } catch (_) {}

        // Walk up to parent
        Element? parent;
        current.visitAncestorElements((ancestor) {
          parent = ancestor;
          return false; // Stop at first ancestor
        });
        current = parent;
        depth++;
      }
    } catch (e) {
      debugPrint('Method 7 (ancestor chain) failed: $e');
    }
  }

  return null;
}

/// Extract diagnostic properties as a map (for enhanced widget info)
/// Based on Flutter DevTools serialization patterns
Map<String, dynamic> extractDiagnosticProperties(Widget widget) {
  final properties = <String, dynamic>{};

  try {
    final node = widget.toDiagnosticsNode();
    final props = node.getProperties();

    for (final prop in props) {
      final name = prop.name;
      if (name == null) continue;

      // Skip internal/debug properties
      if (name.startsWith('_')) continue;
      if (name == 'dependencies' || name == 'state') continue;

      try {
        final value = prop.value;
        if (value != null) {
          // Convert to string representation
          final valueStr = value.toString();
          // Truncate very long values
          properties[name] = valueStr.length > 200
              ? '${valueStr.substring(0, 200)}...'
              : valueStr;
        }
      } catch (_) {}
    }
  } catch (_) {}

  return properties;
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
  CornerZone _currentCornerZone = CornerZone.center;
  List<IDEWidgetInfo> _widgetPath = [];
  final _noteController = TextEditingController();
  NoteAction _selectedAction = NoteAction.discuss;

  // Keyboard navigation support
  final FocusNode _focusNode = FocusNode();
  int _currentPathIndex = 0;

  // All candidates at last click position (for popup menu)
  List<WidgetMatch> _allCandidates = [];

  // Z key state for deep select mode
  bool _isZKeyHeld = false;

  // Screenshot capture
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  ui.Image? _currentScreenshot;
  bool _isCapturingScreenshot = false;

  // Draggable panel positions
  Offset _bannerPosition = const Offset(8, 8);
  Offset _breadcrumbPosition = const Offset(8, 60);
  Offset _notePanelPosition = const Offset(-458, 8); // Relative to right edge

  @override
  void initState() {
    super.initState();
    _inspector.activeStream.listen((active) {
      if (mounted) {
        setState(() {
          _isActive = active;
          if (!active) {
            _clearSelection();
          } else {
            // Request focus when inspector activates
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedWidget = null;
      _hoveredWidget = null;
      _widgetPath = [];
      _currentPathIndex = 0;
      _allCandidates = [];
      _currentScreenshot = null;
    });
  }

  /// Capture a screenshot of the current screen with widget overlay
  /// Hides inspector UI elements during capture for clean screenshots
  Future<void> _captureScreenshot() async {
    try {
      // Hide inspector UI elements
      setState(() => _isCapturingScreenshot = true);

      // Wait for UI to update and overlay to render
      await Future.delayed(const Duration(milliseconds: 200));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('⚠️ Screenshot: RenderRepaintBoundary not found');
        if (mounted) setState(() => _isCapturingScreenshot = false);
        return;
      }

      // Capture at device pixel ratio for crisp screenshots
      final pixelRatio = View.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      if (mounted) {
        setState(() {
          _currentScreenshot = image;
          _isCapturingScreenshot = false;
        });
        debugPrint('📸 Screenshot captured: ${image.width}x${image.height}');
      }
    } catch (e) {
      debugPrint('⚠️ Screenshot capture failed: $e');
      if (mounted) setState(() => _isCapturingScreenshot = false);
    }
  }

  /// Handle keyboard events for widget navigation and Z key deep select
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (!_isActive) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Track Z key state for deep select mode
    if (key == LogicalKeyboardKey.keyZ) {
      if (event is KeyDownEvent) {
        if (!_isZKeyHeld) {
          setState(() => _isZKeyHeld = true);
          debugPrint('🎯 Deep Select Mode: ACTIVE (hold Z and click)');
        }
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        setState(() => _isZKeyHeld = false);
        debugPrint('🎯 Deep Select Mode: OFF');
        return KeyEventResult.handled;
      }
    }

    // Navigation only works when a widget is selected
    if (_selectedWidget == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Tab / Shift+Tab - cycle through widget path
    if (key == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        // Shift+Tab = go deeper (to child)
        _navigateToChild();
      } else {
        // Tab = go to parent
        _navigateToParent();
      }
      return KeyEventResult.handled;
    }

    // Arrow Up = go to parent
    if (key == LogicalKeyboardKey.arrowUp) {
      _navigateToParent();
      return KeyEventResult.handled;
    }

    // Arrow Down = go to child
    if (key == LogicalKeyboardKey.arrowDown) {
      _navigateToChild();
      return KeyEventResult.handled;
    }

    // Escape = clear selection
    if (key == LogicalKeyboardKey.escape) {
      _clearSelection();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Navigate to parent widget in the path
  void _navigateToParent() {
    if (_widgetPath.isEmpty || _currentPathIndex <= 0) {
      debugPrint('🔼 Already at root of widget path');
      return;
    }

    setState(() {
      _currentPathIndex--;
      final parentInfo = _widgetPath[_currentPathIndex];
      _selectedWidget = WidgetBounds(
        rect: Rect.fromLTWH(
          parentInfo.position.dx,
          parentInfo.position.dy,
          parentInfo.size.width,
          parentInfo.size.height,
        ),
        info: parentInfo,
      );
    });
    _inspector.selectWidget(_widgetPath[_currentPathIndex]);
    debugPrint('🔼 Navigated to parent: ${_widgetPath[_currentPathIndex].widgetType}');
  }

  /// Navigate to child widget in the path
  void _navigateToChild() {
    if (_widgetPath.isEmpty || _currentPathIndex >= _widgetPath.length - 1) {
      debugPrint('🔽 Already at deepest widget in path');
      return;
    }

    setState(() {
      _currentPathIndex++;
      final childInfo = _widgetPath[_currentPathIndex];
      _selectedWidget = WidgetBounds(
        rect: Rect.fromLTWH(
          childInfo.position.dx,
          childInfo.position.dy,
          childInfo.size.width,
          childInfo.size.height,
        ),
        info: childInfo,
      );
    });
    _inspector.selectWidget(_widgetPath[_currentPathIndex]);
    debugPrint('🔽 Navigated to child: ${_widgetPath[_currentPathIndex].widgetType}');
  }

  // Key for the child widget to get its RenderBox
  final GlobalKey _childKey = GlobalKey();

  void _handlePointerHover(Offset localPosition) {
    if (!_isActive) return;

    // Get the child's render box for hit testing
    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    final widgetBounds = _findWidgetAtPosition(localPosition, childBox);
    if (widgetBounds != null) {
      // Detect which corner zone we're in for the hovered widget
      final result = BoxHitTestResult();
      childBox.hitTest(result, position: localPosition);
      final processor = EnhancedHitTestProcessor.instance;

      // Find the corner zone for visual feedback
      CornerZone detectedZone = CornerZone.center;
      for (final entry in result.path) {
        if (entry.target is! RenderBox) continue;
        final box = entry.target as RenderBox;
        if (processor.isInCornerZone(box, localPosition)) {
          // Determine which corner
          final local = box.globalToLocal(localPosition);
          final size = box.size;
          final zoneSize = processor.getCornerZoneSizeForWidget(size);

          if (local.dx < zoneSize && local.dy < zoneSize) {
            detectedZone = CornerZone.topLeft;
          } else if (local.dx > size.width - zoneSize && local.dy < zoneSize) {
            detectedZone = CornerZone.topRight;
          } else if (local.dx < zoneSize && local.dy > size.height - zoneSize) {
            detectedZone = CornerZone.bottomLeft;
          } else if (local.dx > size.width - zoneSize && local.dy > size.height - zoneSize) {
            detectedZone = CornerZone.bottomRight;
          }
          break;
        }
      }

      if (widgetBounds != _hoveredWidget || detectedZone != _currentCornerZone) {
        setState(() {
          _hoveredWidget = widgetBounds;
          _currentCornerZone = detectedZone;
        });
      }
    }
  }

  void _handlePointerDown(Offset localPosition, {bool forceDeepSelect = false}) {
    if (!_isActive) return;

    // Get the child's render box for hit testing
    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    // Use Z key for deep select (tracked via _isZKeyHeld state)
    final useDeepSelect = forceDeepSelect || _isZKeyHeld;

    // Get all candidates for potential popup menu
    final result = BoxHitTestResult();
    childBox.hitTest(result, position: localPosition);
    final processor = EnhancedHitTestProcessor.instance;
    _allCandidates = processor.getAllCandidates(result, localPosition);

    // Choose selection mode based on Z key state
    WidgetBounds? widgetBounds;
    if (useDeepSelect) {
      // Z+Click = always select the MOST specific widget (smallest, highest score)
      debugPrint('🎯 DEEP SELECT (Z+Click) - selecting smallest widget');
      final match = processor.findMostSpecificWidget(result, localPosition);
      if (match != null) {
        debugPrint('   Found: ${match.widgetType} (${match.size.width.toInt()}x${match.size.height.toInt()})');
        widgetBounds = _extractWidgetBoundsFromMatch(
          match,
          'deep_${match.widgetType}_${match.hashCode}',
          0,
        );
      }
    } else {
      // Normal click = corner-aware selection (current behavior)
      widgetBounds = _findWidgetAtPosition(localPosition, childBox, debugMode: true);
    }

    if (widgetBounds != null) {
      setState(() {
        _selectedWidget = widgetBounds;
        _hoveredWidget = null;
        _widgetPath = _buildWidgetPath(widgetBounds!.info);
        _currentPathIndex = _widgetPath.length - 1; // Start at selected widget
        _currentScreenshot = null; // Clear previous screenshot
      });
      _inspector.selectWidget(widgetBounds.info);
      _focusNode.requestFocus(); // Ensure we can receive keyboard events
      // Capture screenshot after overlay is rendered
      _captureScreenshot();
    }
  }

  /// Handle secondary tap (right-click) for candidate popup menu
  void _handleSecondaryTap(Offset localPosition) {
    if (!_isActive) return;

    // Get the child's render box for hit testing
    final RenderBox? childBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null) return;

    // Get all candidates at this position
    final result = BoxHitTestResult();
    childBox.hitTest(result, position: localPosition);
    final processor = EnhancedHitTestProcessor.instance;
    _allCandidates = processor.getAllCandidates(result, localPosition);

    if (_allCandidates.isEmpty) {
      debugPrint('❌ No widgets found at position');
      return;
    }

    debugPrint('📋 Showing ${_allCandidates.length} candidates in popup menu');

    // Show popup menu with all candidates
    _showCandidateMenu(localPosition);
  }

  /// Show popup menu with all widget candidates
  void _showCandidateMenu(Offset position) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    // Convert local position to global for menu positioning
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final globalPosition = box.localToGlobal(position);

    showMenu<WidgetMatch>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      items: _allCandidates.asMap().entries.map((entry) {
        final index = entry.key;
        final candidate = entry.value;
        final sizeStr = '${candidate.size.width.toInt()}x${candidate.size.height.toInt()}';
        final scoreStr = candidate.specificityScore.toStringAsFixed(2);

        return PopupMenuItem<WidgetMatch>(
          value: candidate,
          child: Row(
            children: [
              // Rank indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: index == 0 ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Widget type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      candidate.widgetType,
                      style: TextStyle(
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '$sizeStr • score: $scoreStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Most specific indicator
              if (index == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BEST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        _selectFromCandidate(selected);
      }
    });
  }

  /// Select a widget from a candidate match
  void _selectFromCandidate(WidgetMatch match) {
    final widgetBounds = _extractWidgetBoundsFromMatch(
      match,
      'menu_${match.widgetType}_${match.hashCode}',
      0,
    );

    setState(() {
      _selectedWidget = widgetBounds;
      _hoveredWidget = null;
      _widgetPath = _buildWidgetPath(widgetBounds.info);
      _currentPathIndex = _widgetPath.length - 1;
      _currentScreenshot = null;
    });
    _inspector.selectWidget(widgetBounds.info);
    _focusNode.requestFocus();
    _captureScreenshot();
    debugPrint('✅ Selected from menu: ${match.widgetType}');
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

  WidgetBounds? _findWidgetAtPosition(Offset position, RenderBox rootBox, {bool debugMode = false}) {
    final result = BoxHitTestResult();
    rootBox.hitTest(result, position: position);

    // Use EnhancedHitTestProcessor with corner-aware selection
    // - Center clicks: select most specific widget
    // - Corner clicks: select parent widget for easier container selection
    final processor = EnhancedHitTestProcessor.instance;
    final match = processor.findWidgetWithCornerAwareness(result, position, debugOutput: debugMode);

    if (match == null) {
      debugPrint('❌ No widget match found at position $position');
      return null;
    }

    final cornerInfo = match.isCornerSelected
        ? ' [corner→parent: ${match.cornerZone.name}]'
        : '';
    debugPrint('🎯 Enhanced selection: ${match.widgetType} (score: ${match.specificityScore.toStringAsFixed(3)})$cornerInfo');
    debugPrint('   Size: ${match.size.width.toInt()}x${match.size.height.toInt()}');
    debugPrint('   Parent chain: ${match.parentChain.take(5).join(" > ")}');

    // Generate unique instance ID using WidgetInstanceTracker
    final tracker = WidgetInstanceTracker.instance;
    final uniqueId = tracker.generateUniqueIdWithBounds(
      match.widgetType,
      match.bounds,
    );
    final siblingIndex = tracker.findSiblingIndexByBounds(
      match.widgetType,
      match.bounds,
    );

    debugPrint('   Unique ID: $uniqueId (sibling #$siblingIndex)');

    // Extract widget bounds with enhanced info
    final bounds = _extractWidgetBoundsFromMatch(match, uniqueId, siblingIndex);
    debugPrint('📦 Final selection: ${bounds.info.widgetType} (${bounds.rect.width.toInt()}x${bounds.rect.height.toInt()})');
    return bounds;
  }

  /// Extract widget bounds from EnhancedHitTestProcessor match
  WidgetBounds _extractWidgetBoundsFromMatch(
    WidgetMatch match,
    String uniqueId,
    int siblingIndex,
  ) {
    final renderBox = match.renderBox;

    // Get size and position
    final size = match.size;
    final globalOffset = match.globalOffset;

    // Try to extract source location
    WidgetSourceLocation? sourceLocation;
    try {
      sourceLocation = _extractWidgetSourceLocation(match.widget, match.element);
    } catch (e) {
      debugPrint('Source location extraction failed: $e');
    }

    // Extract widget properties from render object
    final properties = <String, dynamic>{};
    if (renderBox is RenderParagraph) {
      properties['text'] = renderBox.text.toPlainText();
    }
    if (renderBox is RenderDecoratedBox) {
      final decoration = renderBox.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        properties['color'] = decoration.color.toString();
      }
    }

    // Detect source file based on UI location, widget type, and parent chain
    final uiLocation = _detectLocation(match.parentChain, globalOffset);

    // Get source file, line number, and precise widget code
    String sourceFile;
    int? lineNumber = sourceLocation?.line;
    String? preciseWidgetCode;

    if (sourceLocation?.file != null) {
      sourceFile = sourceLocation!.file;
    } else {
      // Use enhanced source detection with SourceCodeCorrelator integration
      final sourceDetails = _getSourceLocationDetails(
        uiLocation,
        widgetType: match.widgetType,
        parentChain: match.parentChain,
      );

      sourceFile = sourceDetails.filePath;
      lineNumber ??= sourceDetails.lineNumber;
      preciseWidgetCode = sourceDetails.preciseWidgetCode;

      if (preciseWidgetCode != null) {
        debugPrint('📍 Precise code extracted (${preciseWidgetCode.length} chars)');
      }
    }

    // Create IDEWidgetInfo with enhanced data including precise widget code
    final info = IDEWidgetInfo(
      widgetType: match.widgetType,
      location: uiLocation,
      sourceFile: sourceFile,
      lineNumber: lineNumber,
      size: size,
      position: globalOffset,
      parentChain: match.parentChain,
      properties: properties,
      preciseWidgetCode: preciseWidgetCode,
    );

    return WidgetBounds(
      rect: match.bounds,
      info: info,
    );
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

  /// Get full source location details including precise widget code
  /// Returns SourceLocation with file path, line number, and extracted widget code
  SourceLocation _getSourceLocationDetails(
    String location, {
    String? widgetType,
    List<String>? parentChain,
  }) {
    final widget = widgetType ?? '';

    // Try to search the actual uploaded project files
    final stateManager = AppStateManager();
    final currentProject = stateManager.currentProject;

    if (currentProject != null && widget.isNotEmpty) {
      final searchService = ProjectSourceSearchService.instance;
      searchService.setProject(currentProject);

      // This now returns SourceLocation with preciseWidgetCode from SourceCodeCorrelator
      final match = searchService.findBestMatch(
        widget,
        parentChain: parentChain,
        uiLocation: location,
      );

      if (match != null) {
        debugPrint('🎯 FOUND IN PROJECT: ${match.filePath}:${match.lineNumber}');
        if (match.hasPreciseCode) {
          debugPrint('   Precise code: ${match.preciseWidgetCode!.substring(0, match.preciseWidgetCode!.length.clamp(0, 80))}...');
        }
        return match;
      }
    }

    // Fallback: return basic source location from heuristics
    final fallbackPath = _detectSourceFile(
      location,
      widgetType: widgetType,
      parentChain: parentChain,
    );

    // Parse path:lineNumber format if present
    if (fallbackPath.contains(':') && RegExp(r':\d+$').hasMatch(fallbackPath)) {
      final lastColonIndex = fallbackPath.lastIndexOf(':');
      final filePath = fallbackPath.substring(0, lastColonIndex);
      final lineNumber = int.tryParse(fallbackPath.substring(lastColonIndex + 1));
      return SourceLocation(
        filePath: filePath,
        lineNumber: lineNumber ?? 1,
        matchType: MatchType.instantiation,
      );
    }

    return SourceLocation(
      filePath: fallbackPath,
      lineNumber: 1,
      matchType: MatchType.instantiation,
    );
  }

  /// Detect source file based on widget type, parent chain, and UI location
  /// SEARCHES ACTUAL PROJECT FILES when a project is loaded
  /// Returns actual file path with line number when possible
  String _detectSourceFile(String location, {String? widgetType, List<String>? parentChain}) {
    final widget = widgetType ?? '';

    // FIRST: Try to search the actual uploaded project files
    final stateManager = AppStateManager();
    final currentProject = stateManager.currentProject;

    if (currentProject != null && widget.isNotEmpty) {
      // Set up the search service with the current project
      final searchService = ProjectSourceSearchService.instance;
      searchService.setProject(currentProject);

      // Search for the widget in actual source files
      final match = searchService.findBestMatch(
        widget,
        parentChain: parentChain,
        uiLocation: location,
      );

      if (match != null) {
        debugPrint('🎯 FOUND IN PROJECT: ${match.filePath}:${match.lineNumber}');
        debugPrint('   Snippet: ${match.codeSnippet?.substring(0, (match.codeSnippet?.length ?? 0).clamp(0, 60))}...');
        // Return the actual path and line number
        return '${match.filePath}:${match.lineNumber}';
      } else {
        debugPrint('⚠️ Widget "$widget" not found in project source files');
      }
    }

    // FALLBACK: Use heuristics for IDE's own widgets (when no project is loaded
    // or widget not found in project)
    final chain = parentChain?.join(' ') ?? '';

    // Check parent chain for specific component hints
    if (chain.contains('FileTree') || chain.contains('TreeView')) {
      return 'lib/widgets/file_tree_view.dart';
    }
    if (chain.contains('CodeEditor') || chain.contains('CodeMirror')) {
      return 'lib/widgets/enhanced_code_editor.dart';
    }
    if (chain.contains('Preview') || chain.contains('DeviceFrame')) {
      return 'lib/widgets/ui_preview_panel.dart';
    }
    if (chain.contains('AIAssistant') || chain.contains('ChatMessage')) {
      return 'lib/widgets/ai_assistant_panel.dart';
    }
    if (chain.contains('Terminal') || chain.contains('Console')) {
      return 'lib/widgets/terminal_panel.dart';
    }
    if (chain.contains('Inspector') || chain.contains('IDEInspector')) {
      return 'lib/widgets/precise_widget_selector.dart';
    }
    if (chain.contains('Properties') || chain.contains('PropertyEditor')) {
      return 'lib/panels/properties_panel.dart';
    }

    // Check widget type for specific components
    if (widget.contains('InspectorBanner') || widget.contains('WidgetPathBreadcrumb')) {
      return 'lib/widgets/enhanced_ide_inspector_widgets.dart';
    }
    if (widget.contains('EnhancedNotePanel')) {
      return 'lib/widgets/enhanced_ide_inspector_widgets.dart';
    }

    // Location-based fallback
    if (location.contains('File Tree')) return 'lib/widgets/file_tree_view.dart';
    if (location.contains('Code Editor')) return 'lib/widgets/enhanced_code_editor.dart';
    if (location.contains('Preview')) return 'lib/widgets/ui_preview_panel.dart';
    if (location.contains('AI Assistant')) return 'lib/widgets/ai_assistant_panel.dart';
    if (location.contains('Properties')) return 'lib/panels/properties_panel.dart';
    if (location.contains('Terminal')) return 'lib/widgets/terminal_panel.dart';
    if (location.contains('App Bar')) return 'lib/screens/home_page.dart';

    // Default to home_page which contains the main layout
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

  /// Dynamic corner zone indicator - size matches actual corner zone
  Widget _cornerZoneIndicator(Size widgetSize, {bool isActive = false}) {
    final processor = EnhancedHitTestProcessor.instance;
    final zoneSize = processor.getCornerZoneSizeForWidget(widgetSize);

    return Container(
      width: zoneSize,
      height: zoneSize,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.purple.withValues(alpha: 0.5)
            : Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isActive
              ? Colors.purple
              : Colors.purple.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.open_with,
          size: zoneSize * 0.5,
          color: isActive
              ? Colors.white
              : Colors.purple.withValues(alpha: 0.6),
        ),
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
    // Wrap in Focus for keyboard navigation
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      // RepaintBoundary for screenshot capture
      child: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Stack(
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
                onSecondaryTapDown: (details) {
                  // Right-click shows candidate menu
                  debugPrint('🖱️ Right-click at: ${details.localPosition}');
                  _handleSecondaryTap(details.localPosition);
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
            final isInCorner = _currentCornerZone != CornerZone.center;
            final borderColor = isInCorner ? Colors.purple : Colors.orange.shade600;
            final bgColor = isInCorner
                ? Colors.purple.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.2);

            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Widget type label (changes when in corner mode)
                      Positioned(
                        top: -22,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInCorner ? Colors.purple : Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hoveredWidget!.info.widgetType,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              if (isInCorner) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 10, color: Colors.white70),
                                const SizedBox(width: 2),
                                const Text(
                                  'Parent',
                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Corner zone indicators (sized to match actual hit zones, active when hovered)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _cornerZoneIndicator(
                          _hoveredWidget!.info.size,
                          isActive: _currentCornerZone == CornerZone.topLeft,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _cornerZoneIndicator(
                          _hoveredWidget!.info.size,
                          isActive: _currentCornerZone == CornerZone.topRight,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _cornerZoneIndicator(
                          _hoveredWidget!.info.size,
                          isActive: _currentCornerZone == CornerZone.bottomLeft,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _cornerZoneIndicator(
                          _hoveredWidget!.info.size,
                          isActive: _currentCornerZone == CornerZone.bottomRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

        // Selection highlight overlay - convert global to local coordinates
        // Enhanced with prominent styling for clear identification in screenshots
        if (_isActive && _selectedWidget != null)
          Builder(builder: (context) {
            final localRect = _globalToLocal(_selectedWidget!.rect);
            final widgetInfo = _selectedWidget!.info;
            return Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  // More prominent blue overlay
                  color: Colors.blue.withValues(alpha: 0.25),
                  // Thicker, brighter border for visibility
                  border: Border.all(color: Colors.blue.shade600, width: 4),
                  // Outer glow effect using boxShadow
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Widget type label - larger and more prominent
                    Positioned(
                      top: -28,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.widgets, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              widgetInfo.widgetType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Corner handles - larger for visibility
                    Positioned(top: -6, left: -6, child: _cornerHandle()),
                    Positioned(top: -6, right: -6, child: _cornerHandle()),
                    Positioned(bottom: -6, left: -6, child: _cornerHandle()),
                    Positioned(bottom: -6, right: -6, child: _cornerHandle()),
                    // Size label - shows both width and height
                    Positioned(
                      bottom: -24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_selectedWidget!.rect.width.toInt()} × ${_selectedWidget!.rect.height.toInt()} px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Position indicator (top-right)
                    Positioned(
                      top: -28,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '(${_selectedWidget!.rect.left.toInt()}, ${_selectedWidget!.rect.top.toInt()})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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

        // Inspector UI elements - hidden during screenshot capture
        if (_isActive && !_isCapturingScreenshot) ...[
          // Draggable Inspector banner (shows Z key state)
          Positioned(
            left: _bannerPosition.dx,
            top: _bannerPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _bannerPosition += details.delta;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: InspectorBanner(
                  onClose: () => _inspector.disable(),
                  isDeepSelectActive: _isZKeyHeld,
                ),
              ),
            ),
          ),

          // Draggable Widget path breadcrumb
          if (_widgetPath.isNotEmpty)
            Positioned(
              left: _breadcrumbPosition.dx,
              top: _breadcrumbPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _breadcrumbPosition += details.delta;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
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
                        setState(() {
                          _selectedWidget = bounds;
                          _currentScreenshot = null;
                        });
                        _captureScreenshot();
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Draggable Enhanced note panel
          if (_selectedWidget != null)
            Positioned(
              right: -_notePanelPosition.dx,
              top: _notePanelPosition.dy,
              bottom: 8,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _notePanelPosition += Offset(-details.delta.dx, details.delta.dy);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: EnhancedNotePanel(
                    widget: _selectedWidget!.info,
                    noteController: _noteController,
                    selectedAction: _selectedAction,
                    screenshot: _currentScreenshot,
                    onActionChanged: (action) => setState(() => _selectedAction = action),
                    onSendNote: _sendNoteToAI,
                    onClose: _clearSelection,
                  ),
                ),
              ),
            ),
        ],
        ],
        ),
      ),
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
