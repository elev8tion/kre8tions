import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Layout properties extracted from RenderObject
/// Based on Flutter DevTools inspector_data_models.dart
class LayoutProperties {
  final Size size;
  final BoxConstraints? constraints;
  final double? flexFactor;
  final FlexFit? flexFit;
  final bool isOverflowWidth;
  final bool isOverflowHeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Alignment? alignment;

  const LayoutProperties({
    required this.size,
    this.constraints,
    this.flexFactor,
    this.flexFit,
    this.isOverflowWidth = false,
    this.isOverflowHeight = false,
    this.padding,
    this.margin,
    this.alignment,
  });

  bool get hasOverflow => isOverflowWidth || isOverflowHeight;

  Map<String, dynamic> toJson() => {
    'width': size.width,
    'height': size.height,
    if (constraints != null) 'constraints': {
      'minWidth': constraints!.minWidth,
      'maxWidth': constraints!.maxWidth,
      'minHeight': constraints!.minHeight,
      'maxHeight': constraints!.maxHeight,
    },
    if (flexFactor != null) 'flexFactor': flexFactor,
    if (flexFit != null) 'flexFit': flexFit.toString(),
    if (hasOverflow) 'overflow': {
      'width': isOverflowWidth,
      'height': isOverflowHeight,
    },
    if (padding != null) 'padding': padding.toString(),
    if (margin != null) 'margin': margin.toString(),
    if (alignment != null) 'alignment': alignment.toString(),
  };
}

/// Enhanced hit test processor that uses specificity scoring to find
/// the most precise widget at a click point.
///
/// ## Alternative Widget Selection Strategies (Ideas for Future Implementation)
///
/// 1. **Source-First Selection (from Flutter Widget Catcher)**
///    - User clicks on widget name in code editor
///    - Use bracket matching algorithm to find complete widget code
///    - Highlight corresponding UI element
///    - Avoids hit-test ambiguity entirely
///
/// 2. **Popup Candidate List**
///    - On click, show popup with ALL widgets at that point
///    - User picks exact widget from list
///    - Similar to browser DevTools element picker
///
/// 3. **Tab/Keyboard Cycling**
///    - Click selects most specific widget
///    - Tab cycles through parent chain
///    - Shift+Tab cycles to children
///
/// 4. **Modifier Keys**
///    - Normal click = most specific widget
///    - Ctrl+click = parent
///    - Ctrl+Shift+click = grandparent
///
/// 5. **Depth Slider**
///    - Show slider after selection
///    - Drag to adjust depth in widget tree
///    - Live preview of selection change
///
/// 6. **Scroll Wheel Selection**
///    - Click to start selection mode
///    - Scroll wheel to move up/down tree
///    - Click again to confirm
///
/// 7. **Visual Tree Breadcrumb**
///    - Show clickable breadcrumb above selection
///    - Click any ancestor to select it
///    - Example: Scaffold > Column > Padding > Container > Text
///
/// ## Research Findings (from Browser DevTools, Figma, Sketch)
///
/// 8. **Shift + Right-Click Context Menu (Sketch pattern)**
///    - Show list of ALL overlapping layers at click point
///    - User selects from context menu
///    - Very precise, no ambiguity
///
/// 9. **Double-Click to Drill Down (Figma/Sketch pattern)**
///    - Single click selects parent/group
///    - Double-click enters group, selects child
///    - Enter/Return key also drills down
///    - Escape key goes up one level
///
/// 10. **Cmd/Ctrl + Click for Deep Select (Figma/Sketch pattern)**
///     - Normal click = parent container
///     - Cmd+Click = deepest layer under cursor
///     - Standard in professional design tools
///
/// 11. **VS Code Tree Reveal Pattern**
///     - When widget selected in code, reveal and highlight in tree
///     - When widget selected in UI, reveal in code AND tree
///     - Bidirectional synchronization
///
/// 12. **Chrome DevTools Arrow Navigation**
///     - After selection, arrow keys navigate DOM tree
///     - Left arrow = collapse/go to parent
///     - Right arrow = expand/go to child
///     - Up/Down = navigate siblings
///
///
/// Unlike the default approach that stops at the first "semantic" widget,
/// this processor scores all candidates and selects the most specific one
/// (typically the smallest widget that contains the click point).
///
/// Features corner-aware selection: clicking near corners selects parent widgets,
/// while clicking in the center selects the most specific child widget.
class EnhancedHitTestProcessor {
  /// Corner zone size constraints
  /// Actual zone is proportional to widget size (15% of smallest dimension)
  static const double _minCornerZone = 12.0;
  static const double _maxCornerZone = 24.0;
  // Singleton pattern
  static final EnhancedHitTestProcessor _instance = EnhancedHitTestProcessor._internal();
  static EnhancedHitTestProcessor get instance => _instance;
  EnhancedHitTestProcessor._internal();

  /// Internal Flutter widgets to skip (not user-facing)
  static const Set<String> _internalWidgets = {
    'Semantics',
    'MergeSemantics',
    'BlockSemantics',
    'ExcludeSemantics',
    'Actions',
    'Focus',
    'FocusScope',
    'FocusTrap',
    'FocusTraversalGroup',
    'Shortcuts',
    'PrimaryScrollController',
    'ScrollConfiguration',
    'NotificationListener',
    'RepaintBoundary',
    'IgnorePointer',
    'AbsorbPointer',
    'MetaData',
    'KeyedSubtree',
    'Offstage',
    'TickerMode',
    'MediaQuery',
    'DefaultTextStyle',
    'DefaultTextHeightBehavior',
    'IconTheme',
    'AnimatedBuilder',
    'ListenableBuilder',
    'ValueListenableBuilder',
    'StreamBuilder',
    'FutureBuilder',
    'Builder',
    'StatefulBuilder',
    'LayoutBuilder',
    'OrientationBuilder',
    'CustomPaint',
    'RawGestureDetector',
    'Listener',
    'MouseRegion',
    '_FocusMarker',
    '_EffectiveTickerMode',
    '_InheritedTheme',
    '_LocalizationsScope',
  };

  /// User-facing widgets that should be prioritized
  static const Set<String> _userFacingWidgets = {
    'Text',
    'RichText',
    'Icon',
    'Image',
    'Container',
    'DecoratedBox',
    'Card',
    'ListTile',
    'AppBar',
    'Scaffold',
    'FloatingActionButton',
    'ElevatedButton',
    'TextButton',
    'OutlinedButton',
    'IconButton',
    'TextField',
    'TextFormField',
    'Checkbox',
    'Radio',
    'Switch',
    'Slider',
    'DropdownButton',
    'PopupMenuButton',
    'Chip',
    'Avatar',
    'CircleAvatar',
    'Badge',
    'Tooltip',
    'SnackBar',
    'Dialog',
    'AlertDialog',
    'BottomSheet',
    'Drawer',
    'NavigationBar',
    'NavigationRail',
    'TabBar',
    'Tab',
    'DataTable',
    'PaginatedDataTable',
    'GridView',
    'ListView',
    'SingleChildScrollView',
    'CustomScrollView',
    'SizedBox',
    'Padding',
    'Center',
    'Align',
    'Expanded',
    'Flexible',
    'Spacer',
    'Row',
    'Column',
    'Stack',
    'Positioned',
    'Wrap',
    'Flow',
  };

  /// Find the most specific widget at the given click point
  WidgetMatch? findMostSpecificWidget(
    BoxHitTestResult result,
    Offset globalClickPoint,
  ) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      // Must have DebugCreator for Widget access
      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      // Skip internal Flutter widgets
      if (_isInternalWidget(widgetType)) continue;

      // Calculate specificity score
      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    if (candidates.isEmpty) return null;

    // Sort by score (highest first)
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    return _createWidgetMatch(best, globalClickPoint);
  }

  /// Find widget with corner-aware selection
  ///
  /// When clicking/hovering near corners of a widget, selects the parent instead.
  /// This allows users to easily select parent containers by clicking corners.
  WidgetMatch? findWidgetWithCornerAwareness(
    BoxHitTestResult result,
    Offset globalClickPoint, {
    bool debugOutput = false,
  }) {
    final candidates = <_WidgetCandidate>[];
    final skipped = <String>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) {
        // Track what we're skipping for debugging
        if (debugOutput) {
          skipped.add('No DebugCreator: ${box.runtimeType}');
        }
        continue;
      }

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) {
        if (debugOutput) {
          skipped.add('Internal: $widgetType');
        }
        continue;
      }

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    if (candidates.isEmpty) return null;

    // Sort by score (highest first = most specific)
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Debug: show top 5 candidates
    if (debugOutput && candidates.isNotEmpty) {
      debugPrint('🔎 Top candidates:');
      for (int i = 0; i < candidates.length && i < 5; i++) {
        final c = candidates[i];
        final size = c.renderBox.size;
        debugPrint('   ${i + 1}. ${c.widgetType} (${size.width.toInt()}x${size.height.toInt()}) score: ${c.score.toStringAsFixed(3)}');
      }
      if (skipped.isNotEmpty) {
        debugPrint('   Skipped: ${skipped.take(5).join(", ")}${skipped.length > 5 ? "..." : ""}');
      }
    }

    // Check if click is in corner zone of the most specific widget
    final best = candidates.first;
    final cornerZone = _detectCornerZone(best.renderBox, globalClickPoint);

    if (cornerZone != CornerZone.center && candidates.length > 1) {
      // Click is in a corner - select the parent widget instead
      final parent = candidates[1];
      final match = _createWidgetMatch(parent, globalClickPoint);
      return match.copyWith(cornerZone: cornerZone, isCornerSelected: true);
    }

    return _createWidgetMatch(best, globalClickPoint).copyWith(cornerZone: cornerZone);
  }

  /// Calculate proportional corner zone size based on widget dimensions
  double _getCornerZoneSize(Size size) {
    // Use 15% of the smallest dimension, clamped to min/max
    final smallestDim = size.width < size.height ? size.width : size.height;
    final proportional = smallestDim * 0.15;
    return proportional.clamp(_minCornerZone, _maxCornerZone);
  }

  /// Detect which corner zone (if any) the click point is in
  CornerZone _detectCornerZone(RenderBox box, Offset globalClickPoint) {
    final localClick = box.globalToLocal(globalClickPoint);
    final size = box.size;
    final zoneSize = _getCornerZoneSize(size);

    final isNearLeft = localClick.dx < zoneSize;
    final isNearRight = localClick.dx > size.width - zoneSize;
    final isNearTop = localClick.dy < zoneSize;
    final isNearBottom = localClick.dy > size.height - zoneSize;

    // Check each corner
    if (isNearTop && isNearLeft) return CornerZone.topLeft;
    if (isNearTop && isNearRight) return CornerZone.topRight;
    if (isNearBottom && isNearLeft) return CornerZone.bottomLeft;
    if (isNearBottom && isNearRight) return CornerZone.bottomRight;

    // Not in any corner zone
    return CornerZone.center;
  }

  /// Check if a point is in any corner zone of a widget
  bool isInCornerZone(RenderBox box, Offset globalClickPoint) {
    return _detectCornerZone(box, globalClickPoint) != CornerZone.center;
  }

  /// Get the corner zone size for a given widget size (for UI indicators)
  double getCornerZoneSizeForWidget(Size size) => _getCornerZoneSize(size);

  /// Extract layout properties from a RenderBox
  /// Based on Flutter DevTools inspector_data_models.dart patterns
  LayoutProperties extractLayoutProperties(RenderBox box) {
    final size = box.size;

    // Get constraints
    BoxConstraints? constraints;
    try {
      constraints = box.constraints;
    } catch (_) {}

    // Check for flex properties (if parent is RenderFlex)
    double? flexFactor;
    FlexFit? flexFit;
    try {
      final parentData = box.parentData;
      if (parentData is FlexParentData) {
        flexFactor = parentData.flex?.toDouble();
        flexFit = parentData.fit;
      }
    } catch (_) {}

    // Detect overflow (when widget is larger than parent constraints allow)
    bool isOverflowWidth = false;
    bool isOverflowHeight = false;
    if (constraints != null) {
      isOverflowWidth = size.width > constraints.maxWidth;
      isOverflowHeight = size.height > constraints.maxHeight;
    }

    // Extract padding if RenderPadding
    EdgeInsets? padding;
    if (box is RenderPadding) {
      padding = box.padding.resolve(TextDirection.ltr);
    }

    // Extract alignment if RenderPositionedBox
    Alignment? alignment;
    if (box is RenderPositionedBox) {
      final align = box.alignment;
      if (align is Alignment) {
        alignment = align;
      }
    }

    return LayoutProperties(
      size: size,
      constraints: constraints,
      flexFactor: flexFactor,
      flexFit: flexFit,
      isOverflowWidth: isOverflowWidth,
      isOverflowHeight: isOverflowHeight,
      padding: padding,
      alignment: alignment,
    );
  }

  /// Calculate subtree bounds (inspired by Flutter widget_inspector.dart _calculateSubtreeBounds)
  /// Returns the union of bounds for a widget and all its descendants
  Rect calculateSubtreeBounds(RenderBox box) {
    Rect bounds = box.localToGlobal(Offset.zero) & box.size;

    void visitChild(RenderObject child) {
      if (child is RenderBox && child.hasSize) {
        final childBounds = child.localToGlobal(Offset.zero) & child.size;
        bounds = bounds.expandToInclude(childBounds);
      }
      child.visitChildren(visitChild);
    }

    box.visitChildren(visitChild);
    return bounds;
  }

  /// Find widget using edge-aware selection (enhanced version of corner-aware)
  /// Edges (not just corners) also trigger parent selection for thin/narrow widgets
  WidgetMatch? findWidgetWithEdgeAwareness(
    BoxHitTestResult result,
    Offset globalClickPoint, {
    double edgeThreshold = 8.0,
    bool debugOutput = false,
  }) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) continue;

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    final localClick = best.renderBox.globalToLocal(globalClickPoint);
    final size = best.renderBox.size;

    // Check if click is near any edge (for thin/narrow widgets)
    final nearLeftEdge = localClick.dx < edgeThreshold;
    final nearRightEdge = localClick.dx > size.width - edgeThreshold;
    final nearTopEdge = localClick.dy < edgeThreshold;
    final nearBottomEdge = localClick.dy > size.height - edgeThreshold;

    // For very thin widgets (< 20px in either dimension), select parent
    final isThinWidget = size.width < 20 || size.height < 20;

    // Also check corner zones
    final cornerZone = _detectCornerZone(best.renderBox, globalClickPoint);

    final shouldSelectParent = (isThinWidget && (nearLeftEdge || nearRightEdge || nearTopEdge || nearBottomEdge)) ||
                               cornerZone != CornerZone.center;

    if (shouldSelectParent && candidates.length > 1) {
      final parent = candidates[1];
      final match = _createWidgetMatch(parent, globalClickPoint);
      return match.copyWith(
        cornerZone: cornerZone,
        isCornerSelected: true,
        layoutProperties: extractLayoutProperties(parent.renderBox),
      );
    }

    return _createWidgetMatch(best, globalClickPoint).copyWith(
      cornerZone: cornerZone,
      layoutProperties: extractLayoutProperties(best.renderBox),
    );
  }

  /// Calculate specificity score for a widget
  /// Higher score = more specific (preferred)
  double _calculateSpecificityScore(
    RenderBox box,
    Offset globalClickPoint,
    String widgetType,
  ) {
    final size = box.size;

    // Area score: smaller widgets are more specific
    // Use inverse of area, normalized
    final area = size.width * size.height;
    final areaScore = area > 0 ? 1.0 / (area + 1) * 10000 : 0.0;

    // Center score: clicks closer to center are more likely the target
    final localClick = box.globalToLocal(globalClickPoint);
    final center = Offset(size.width / 2, size.height / 2);
    final distanceFromCenter = (localClick - center).distance;
    final maxDistance = (Offset.zero - center).distance;
    final centerScore = maxDistance > 0
        ? 1.0 - (distanceFromCenter / maxDistance).clamp(0.0, 1.0)
        : 1.0;

    // User-facing bonus: prioritize known user-facing widgets
    final userFacingBonus = _userFacingWidgets.contains(widgetType) ? 0.2 : 0.0;

    // Combine scores with weights
    final score = (areaScore * 0.5) +
                  (centerScore * 0.3) +
                  userFacingBonus;

    return score;
  }

  /// Check if widget type is an internal Flutter widget
  bool _isInternalWidget(String widgetType) {
    // Check exact match
    if (_internalWidgets.contains(widgetType)) return true;

    // Check if starts with underscore (private widget)
    if (widgetType.startsWith('_')) return true;

    // Check common internal prefixes
    if (widgetType.startsWith('_Render')) return true;
    if (widgetType.startsWith('_Inherited')) return true;
    if (widgetType.startsWith('_Default')) return true;

    return false;
  }

  /// Create a WidgetMatch from a candidate
  WidgetMatch _createWidgetMatch(_WidgetCandidate candidate, Offset globalClickPoint) {
    final box = candidate.renderBox;
    final size = box.size;
    final globalOffset = box.localToGlobal(Offset.zero);

    // Build parent chain
    final parentChain = <String>[];
    candidate.element.visitAncestorElements((ancestor) {
      final ancestorType = ancestor.widget.runtimeType.toString();
      if (!_isInternalWidget(ancestorType)) {
        parentChain.add(ancestorType);
      }
      return parentChain.length < 10; // Limit depth
    });

    return WidgetMatch(
      widget: candidate.widget,
      element: candidate.element,
      renderBox: candidate.renderBox,
      widgetType: candidate.widgetType,
      size: size,
      globalOffset: globalOffset,
      specificityScore: candidate.score,
      parentChain: parentChain,
    );
  }

  /// Get all widget candidates at a position (for debugging)
  List<WidgetMatch> getAllCandidates(
    BoxHitTestResult result,
    Offset globalClickPoint,
  ) {
    final candidates = <_WidgetCandidate>[];

    for (final entry in result.path) {
      if (entry.target is! RenderBox) continue;
      final box = entry.target as RenderBox;

      final creator = box.debugCreator;
      if (creator is! DebugCreator) continue;

      final element = creator.element;
      final widget = element.widget;
      final widgetType = widget.runtimeType.toString();

      if (_isInternalWidget(widgetType)) continue;

      final score = _calculateSpecificityScore(box, globalClickPoint, widgetType);

      candidates.add(_WidgetCandidate(
        renderBox: box,
        element: element,
        widget: widget,
        widgetType: widgetType,
        score: score,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates.map((c) => _createWidgetMatch(c, globalClickPoint)).toList();
  }
}

/// Internal class for tracking widget candidates during selection
class _WidgetCandidate {
  final RenderBox renderBox;
  final Element element;
  final Widget widget;
  final String widgetType;
  final double score;

  _WidgetCandidate({
    required this.renderBox,
    required this.element,
    required this.widget,
    required this.widgetType,
    required this.score,
  });
}

/// Corner zone indicator for selection behavior
enum CornerZone {
  center,      // Not in any corner - select most specific widget
  topLeft,     // Near top-left corner - select parent
  topRight,    // Near top-right corner - select parent
  bottomLeft,  // Near bottom-left corner - select parent
  bottomRight, // Near bottom-right corner - select parent
}

/// Result of widget matching with specificity scoring
class WidgetMatch {
  final Widget widget;
  final Element element;
  final RenderBox renderBox;
  final String widgetType;
  final Size size;
  final Offset globalOffset;
  final double specificityScore;
  final List<String> parentChain;
  final CornerZone cornerZone;
  final bool isCornerSelected;
  final LayoutProperties? layoutProperties;
  final Rect? subtreeBounds;

  WidgetMatch({
    required this.widget,
    required this.element,
    required this.renderBox,
    required this.widgetType,
    required this.size,
    required this.globalOffset,
    required this.specificityScore,
    required this.parentChain,
    this.cornerZone = CornerZone.center,
    this.isCornerSelected = false,
    this.layoutProperties,
    this.subtreeBounds,
  });

  /// Get bounds as Rect
  Rect get bounds => globalOffset & size;

  /// Create a copy with modified fields
  WidgetMatch copyWith({
    Widget? widget,
    Element? element,
    RenderBox? renderBox,
    String? widgetType,
    Size? size,
    Offset? globalOffset,
    double? specificityScore,
    List<String>? parentChain,
    CornerZone? cornerZone,
    bool? isCornerSelected,
    LayoutProperties? layoutProperties,
    Rect? subtreeBounds,
  }) {
    return WidgetMatch(
      widget: widget ?? this.widget,
      element: element ?? this.element,
      renderBox: renderBox ?? this.renderBox,
      widgetType: widgetType ?? this.widgetType,
      size: size ?? this.size,
      globalOffset: globalOffset ?? this.globalOffset,
      specificityScore: specificityScore ?? this.specificityScore,
      parentChain: parentChain ?? this.parentChain,
      cornerZone: cornerZone ?? this.cornerZone,
      isCornerSelected: isCornerSelected ?? this.isCornerSelected,
      layoutProperties: layoutProperties ?? this.layoutProperties,
      subtreeBounds: subtreeBounds ?? this.subtreeBounds,
    );
  }

  /// Get layout info as a formatted string
  String get layoutInfo {
    if (layoutProperties == null) return '';
    final lp = layoutProperties!;
    final parts = <String>[];

    if (lp.flexFactor != null) {
      parts.add('flex: ${lp.flexFactor}');
    }
    if (lp.constraints != null) {
      parts.add('constraints: ${lp.constraints!.minWidth.toInt()}-${lp.constraints!.maxWidth.toInt()} × ${lp.constraints!.minHeight.toInt()}-${lp.constraints!.maxHeight.toInt()}');
    }
    if (lp.hasOverflow) {
      parts.add('OVERFLOW: ${lp.isOverflowWidth ? "W" : ""}${lp.isOverflowHeight ? "H" : ""}');
    }
    if (lp.padding != null) {
      parts.add('padding: ${lp.padding}');
    }

    return parts.join(', ');
  }

  @override
  String toString() {
    final cornerInfo = isCornerSelected ? ' [corner→parent]' : '';
    return 'WidgetMatch($widgetType, score: ${specificityScore.toStringAsFixed(3)}, '
           'size: ${size.width.toInt()}x${size.height.toInt()}$cornerInfo)';
  }
}
