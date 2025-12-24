import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kre8tions/models/widget_selection.dart';

class WidgetInspectorPanel extends StatefulWidget {
  final WidgetSelection selectedWidget;
  final Function(String property, dynamic value) onPropertyChanged;
  final VoidCallback onClose;

  const WidgetInspectorPanel({
    super.key,
    required this.selectedWidget,
    required this.onPropertyChanged,
    required this.onClose,
  });

  @override
  State<WidgetInspectorPanel> createState() => _WidgetInspectorPanelState();
}

class _WidgetInspectorPanelState extends State<WidgetInspectorPanel> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Current property values (will be populated from widget selection)
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black87;
  double _borderRadius = 0;
  double _elevation = 0;
  double _opacity = 1.0;
  EdgeInsets _padding = EdgeInsets.zero;
  EdgeInsets _margin = EdgeInsets.zero;
  String _fontFamily = 'System';
  double _fontSize = 14;
  FontWeight _fontWeight = FontWeight.normal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeProperties();
  }

  void _initializeProperties() {
    // Initialize properties from the selected widget
    // This would typically parse the source code or use reflection
    // For now, using defaults with some smart detection
    final widgetType = widget.selectedWidget.widgetType;
    
    switch (widgetType) {
      case 'Container':
        _backgroundColor = Colors.grey[100] ?? Colors.grey;
        _borderRadius = 8;
        _padding = const EdgeInsets.all(16);
        break;
      case 'Card':
        _backgroundColor = Colors.white;
        _elevation = 4;
        _borderRadius = 12;
        _padding = const EdgeInsets.all(16);
        break;
      case 'AppBar':
        _backgroundColor = Theme.of(context).colorScheme.primary;
        _textColor = Colors.white;
        _elevation = 4;
        break;
      case 'Text':
        _fontSize = 16;
        _fontWeight = FontWeight.normal;
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive width with overflow protection
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = math.min(350.0, screenWidth * 0.4); // Max 40% of screen
        final width = math.max(280.0, maxWidth); // Min 280px
        
        return Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTabBar(theme),
              Expanded(
                child: _buildTabBarView(theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Widget Inspector',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedWidget.widgetType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.labelSmall,
        tabs: const [
          Tab(
            icon: Icon(Icons.palette, size: 16),
            text: 'Style',
          ),
          Tab(
            icon: Icon(Icons.crop_free, size: 16),
            text: 'Layout',
          ),
          Tab(
            icon: Icon(Icons.text_fields, size: 16),
            text: 'Content',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ThemeData theme) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildStyleTab(theme),
        _buildLayoutTab(theme),
        _buildContentTab(theme),
      ],
    );
  }

  Widget _buildStyleTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme,
            'Colors',
            Icons.color_lens,
            [
              _buildColorProperty(
                theme,
                'Background Color',
                _backgroundColor,
                (color) {
                  setState(() => _backgroundColor = color);
                  widget.onPropertyChanged('backgroundColor', color);
                },
              ),
              _buildColorProperty(
                theme,
                'Text Color',
                _textColor,
                (color) {
                  setState(() => _textColor = color);
                  widget.onPropertyChanged('textColor', color);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Effects',
            Icons.auto_awesome,
            [
              _buildSliderProperty(
                theme,
                'Opacity',
                _opacity,
                0.0,
                1.0,
                (value) {
                  setState(() => _opacity = value);
                  widget.onPropertyChanged('opacity', value);
                },
                showPercentage: true,
              ),
              _buildSliderProperty(
                theme,
                'Elevation',
                _elevation,
                0.0,
                24.0,
                (value) {
                  setState(() => _elevation = value);
                  widget.onPropertyChanged('elevation', value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme,
            'Border Radius',
            Icons.rounded_corner,
            [
              _buildSliderProperty(
                theme,
                'Border Radius',
                _borderRadius,
                0.0,
                50.0,
                (value) {
                  setState(() => _borderRadius = value);
                  widget.onPropertyChanged('borderRadius', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Spacing',
            Icons.space_bar,
            [
              _buildSpacingProperty(
                theme,
                'Padding',
                _padding,
                (padding) {
                  setState(() => _padding = padding);
                  widget.onPropertyChanged('padding', padding);
                },
              ),
              _buildSpacingProperty(
                theme,
                'Margin',
                _margin,
                (margin) {
                  setState(() => _margin = margin);
                  widget.onPropertyChanged('margin', margin);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme,
            'Typography',
            Icons.text_fields,
            [
              _buildDropdownProperty(
                theme,
                'Font Family',
                _fontFamily,
                ['System', 'Roboto', 'Open Sans', 'Lato', 'Montserrat'],
                (value) {
                  setState(() => _fontFamily = value);
                  widget.onPropertyChanged('fontFamily', value);
                },
              ),
              _buildSliderProperty(
                theme,
                'Font Size',
                _fontSize,
                8.0,
                48.0,
                (value) {
                  setState(() => _fontSize = value);
                  widget.onPropertyChanged('fontSize', value);
                },
              ),
              _buildDropdownProperty(
                theme,
                'Font Weight',
                _fontWeight.toString(),
                ['FontWeight.w100', 'FontWeight.w300', 'FontWeight.normal', 'FontWeight.w500', 'FontWeight.w600', 'FontWeight.bold', 'FontWeight.w800', 'FontWeight.w900'],
                (value) {
                  final weight = _parseFontWeight(value);
                  setState(() => _fontWeight = weight);
                  widget.onPropertyChanged('fontWeight', weight);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        )),
      ],
    );
  }

  Widget _buildColorProperty(ThemeData theme, String label, Color value, Function(Color) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker(context, value, onChanged),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${value.value.toRadixString(16).substring(2).toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showColorPicker(context, value, onChanged),
              child: const Text('Change'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderProperty(ThemeData theme, String label, double value, double min, double max, Function(double) onChanged, {bool showPercentage = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              showPercentage ? '${(value * 100).round()}%' : value.toStringAsFixed(1),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: theme.colorScheme.primary,
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSpacingProperty(ThemeData theme, String label, EdgeInsets value, Function(EdgeInsets) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSpacingInput(theme, 'All', value.top, (val) {
                onChanged(EdgeInsets.all(val));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpacingInput(theme, 'H', value.left, (val) {
                onChanged(EdgeInsets.symmetric(horizontal: val, vertical: value.top));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpacingInput(theme, 'V', value.top, (val) {
                onChanged(EdgeInsets.symmetric(vertical: val, horizontal: value.left));
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingInput(ThemeData theme, String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
            ),
            onChanged: (text) {
              final val = double.tryParse(text) ?? 0;
              onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownProperty<T>(ThemeData theme, String label, T value, List<T> options, Function(T) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option.toString().replaceAll('FontWeight.', ''),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basic color palette
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
                Colors.white,
              ].map((color) => GestureDetector(
                onTap: () {
                  onColorChanged(color);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentColor == color ? Colors.black : Colors.grey.withValues(alpha: 0.3),
                      width: currentColor == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  FontWeight _parseFontWeight(String value) {
    switch (value) {
      case 'FontWeight.w100': return FontWeight.w100;
      case 'FontWeight.w300': return FontWeight.w300;
      case 'FontWeight.normal': return FontWeight.normal;
      case 'FontWeight.w500': return FontWeight.w500;
      case 'FontWeight.w600': return FontWeight.w600;
      case 'FontWeight.bold': return FontWeight.bold;
      case 'FontWeight.w800': return FontWeight.w800;
      case 'FontWeight.w900': return FontWeight.w900;
      default: return FontWeight.normal;
    }
  }
}