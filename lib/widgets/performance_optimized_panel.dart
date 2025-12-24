import 'package:flutter/material.dart';
import 'package:kre8tions/theme.dart';

/// Performance-optimized panel with caching and efficient rendering
class PerformanceOptimizedPanel extends StatefulWidget {
  final Widget child;
  final String title;
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final double? width;
  final double? minWidth;
  final double collapsedWidth;
  final Duration animationDuration;
  final bool enableGlassMorphism;
  final bool cacheChild;

  const PerformanceOptimizedPanel({
    super.key,
    required this.child,
    required this.title,
    this.isCollapsed = false,
    this.onToggle,
    this.width,
    this.minWidth,
    this.collapsedWidth = 48.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableGlassMorphism = true,
    this.cacheChild = true,
  });

  @override
  State<PerformanceOptimizedPanel> createState() => _PerformanceOptimizedPanelState();
}

class _PerformanceOptimizedPanelState extends State<PerformanceOptimizedPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;
  
  Widget? _cachedChild;
  bool _childNeedsRebuild = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(
      begin: widget.isCollapsed ? widget.collapsedWidth : (widget.width ?? 300),
      end: widget.isCollapsed ? widget.collapsedWidth : (widget.width ?? 300),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: widget.isCollapsed ? 0.0 : 1.0,
      end: widget.isCollapsed ? 0.0 : 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (!widget.isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PerformanceOptimizedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      _updateAnimations();
      if (widget.isCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
    
    if (oldWidget.child != widget.child) {
      _childNeedsRebuild = true;
    }
  }

  void _updateAnimations() {
    final targetWidth = widget.isCollapsed ? widget.collapsedWidth : (widget.width ?? 300);
    final targetOpacity = widget.isCollapsed ? 0.0 : 1.0;
    
    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: targetWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: _opacityAnimation.value,
      end: targetOpacity,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Widget _buildCachedChild() {
    if (!widget.cacheChild || _childNeedsRebuild || _cachedChild == null) {
      _cachedChild = widget.child;
      _childNeedsRebuild = false;
    }
    return _cachedChild!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          constraints: BoxConstraints(
            minWidth: widget.isCollapsed ? widget.collapsedWidth : (widget.minWidth ?? 200),
          ),
          decoration: widget.enableGlassMorphism 
            ? GlassMorphismHelper.glassContainer(
                color: isDark ? Kre8tionsColors.glassPrimary : Colors.white,
                opacity: isDark ? 0.15 : 0.8,
                enableGlow: true,
              )
            : BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.isCollapsed) ...[
                      // Collapsed header with vertical text
                      Expanded(
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              widget.title,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Expanded header
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    // Toggle button
                    if (widget.onToggle != null)
                      InkWell(
                        onTap: widget.onToggle,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedRotation(
                            turns: widget.isCollapsed ? 0.5 : 0.0,
                            duration: widget.animationDuration,
                            child: Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Panel Content
              if (!widget.isCollapsed)
                Expanded(
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: _buildCachedChild(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Enhanced performance-optimized container with lazy loading
class LazyLoadContainer extends StatefulWidget {
  final Widget Function() builder;
  final bool shouldLoad;
  final Widget? placeholder;
  final Duration delay;

  const LazyLoadContainer({
    super.key,
    required this.builder,
    this.shouldLoad = true,
    this.placeholder,
    this.delay = Duration.zero,
  });

  @override
  State<LazyLoadContainer> createState() => _LazyLoadContainerState();
}

class _LazyLoadContainerState extends State<LazyLoadContainer> {
  bool _isLoaded = false;
  Widget? _cachedWidget;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoad) {
      _loadContent();
    }
  }

  @override
  void didUpdateWidget(LazyLoadContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoad && !_isLoaded) {
      _loadContent();
    }
  }

  void _loadContent() {
    if (widget.delay == Duration.zero) {
      setState(() {
        _isLoaded = true;
        _cachedWidget = widget.builder();
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _cachedWidget = widget.builder();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _cachedWidget != null) {
      return _cachedWidget!;
    }
    
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// Memory-efficient scroll view with viewport optimization
class OptimizedScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedScrollView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    // Use ListView.builder for better performance with large lists
    if (children.length > 50) {
      return ListView.builder(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }
    
    // Use regular ListView for smaller lists
    return ListView(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}