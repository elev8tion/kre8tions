import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/models/widget_property_schema.dart';
import 'package:kre8tions/services/visual_property_manager.dart';

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
  final VisualPropertyManager _propertyManager = VisualPropertyManager();

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

  // Advanced properties
  Alignment _alignment = Alignment.center;
  BoxConstraints? _constraints;
  double _rotationAngle = 0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Changed from 5 to 6
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
          Tab(
            icon: Icon(Icons.settings, size: 16),
            text: 'Constructor',
          ),
          Tab(
            icon: Icon(Icons.touch_app, size: 16),
            text: 'Interaction',
          ),
          Tab(
            icon: Icon(Icons.tune, size: 16),
            text: 'Advanced',
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
        _buildConstructorTab(theme),
        _buildInteractionTab(theme),
        _buildAdvancedTab(theme),
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

  Widget _buildConstructorTab(ThemeData theme) {
    final schema = WidgetSchemas.getSchema(widget.selectedWidget.widgetType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme,
            'Widget Type',
            Icons.category,
            [
              _buildWidgetTypeDisplay(theme),
            ],
          ),
          const SizedBox(height: 20),
          if (schema != null) ...[
            _buildSection(
              theme,
              'Required Parameters',
              Icons.star,
              _buildSchemaParameters(theme, schema.constructor.where((p) => p.required).toList()),
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme,
              'Optional Parameters',
              Icons.settings_suggest,
              _buildSchemaParameters(theme, schema.constructor.where((p) => !p.required).toList()),
            ),
          ] else ...[
            // Fallback for widgets without schema
            _buildSection(
              theme,
              'Constructor Type',
              Icons.category,
              [
                _buildConstructorTypeSelector(theme),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme,
              'Required Parameters',
              Icons.star,
              _buildRequiredParameters(theme),
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme,
              'Optional Parameters',
              Icons.settings_suggest,
              _buildOptionalParameters(theme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionTab(ThemeData theme) {
    final schema = WidgetSchemas.getSchema(widget.selectedWidget.widgetType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schema != null && schema.interaction.isNotEmpty) ...[
            _buildSection(
              theme,
              'Event Handlers',
              Icons.flash_on,
              _buildSchemaParameters(theme, schema.interaction),
            ),
          ] else ...[
            // Fallback for widgets without schema
            _buildSection(
              theme,
              'Events',
              Icons.flash_on,
              [
                _buildFunctionEditor(theme, 'onPressed', null),
                _buildFunctionEditor(theme, 'onLongPress', null),
                _buildFunctionEditor(theme, 'onTap', null),
                _buildFunctionEditor(theme, 'onDoubleTap', null),
                _buildFunctionEditor(theme, 'onHover', null),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'State',
            Icons.toggle_on,
            [
              _buildToggleProperty(theme, 'enabled', true),
              _buildToggleProperty(theme, 'autofocus', false),
              _buildToggleProperty(theme, 'enableFeedback', true),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Focus',
            Icons.filter_center_focus,
            [
              _buildWidgetSelector(theme, 'focusNode', null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(ThemeData theme) {
    final schema = WidgetSchemas.getSchema(widget.selectedWidget.widgetType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            theme,
            'Alignment',
            Icons.control_camera,
            [
              _buildAlignmentPicker(theme),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Constraints',
            Icons.crop,
            [
              _buildConstraintsEditor(theme),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            theme,
            'Transform',
            Icons.transform,
            [
              _buildSliderProperty(
                theme,
                'Rotation',
                _rotationAngle,
                0.0,
                360.0,
                (value) {
                  setState(() => _rotationAngle = value);
                  widget.onPropertyChanged('rotation', value);
                  _propertyManager.updateProperty(widget.selectedWidget, 'rotation', value);
                },
              ),
              _buildSliderProperty(
                theme,
                'Scale',
                _scale,
                0.5,
                3.0,
                (value) {
                  setState(() => _scale = value);
                  widget.onPropertyChanged('scale', value);
                  _propertyManager.updateProperty(widget.selectedWidget, 'scale', value);
                },
              ),
            ],
          ),
          if (schema != null && schema.advanced.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              theme,
              'Advanced Properties',
              Icons.settings_applications,
              _buildSchemaParameters(theme, schema.advanced),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlignmentPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Alignment Picker',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildAlignmentCell(theme, Alignment.topLeft, 'TL'),
              _buildAlignmentCell(theme, Alignment.topCenter, 'TC'),
              _buildAlignmentCell(theme, Alignment.topRight, 'TR'),
              _buildAlignmentCell(theme, Alignment.centerLeft, 'CL'),
              _buildAlignmentCell(theme, Alignment.center, 'C'),
              _buildAlignmentCell(theme, Alignment.centerRight, 'CR'),
              _buildAlignmentCell(theme, Alignment.bottomLeft, 'BL'),
              _buildAlignmentCell(theme, Alignment.bottomCenter, 'BC'),
              _buildAlignmentCell(theme, Alignment.bottomRight, 'BR'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentCell(ThemeData theme, Alignment alignment, String label) {
    final isSelected = _alignment == alignment;
    return InkWell(
      onTap: () {
        setState(() => _alignment = alignment);
        widget.onPropertyChanged('alignment', alignment);
        _propertyManager.updateProperty(widget.selectedWidget, 'alignment', alignment);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConstraintsEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildConstraintInput(
                theme,
                'Min Width',
                _constraints?.minWidth ?? 0,
                (value) => _updateConstraints(minWidth: value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConstraintInput(
                theme,
                'Max Width',
                _constraints?.maxWidth ?? double.infinity,
                (value) => _updateConstraints(maxWidth: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildConstraintInput(
                theme,
                'Min Height',
                _constraints?.minHeight ?? 0,
                (value) => _updateConstraints(minHeight: value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConstraintInput(
                theme,
                'Max Height',
                _constraints?.maxHeight ?? double.infinity,
                (value) => _updateConstraints(maxHeight: value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConstraintInput(ThemeData theme, String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: TextEditingController(
              text: value == double.infinity ? '∞' : value.toStringAsFixed(0),
            ),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            onChanged: (text) {
              if (text == '∞' || text.isEmpty) {
                onChanged(double.infinity);
              } else {
                final val = double.tryParse(text) ?? 0;
                onChanged(val);
              }
            },
          ),
        ),
      ],
    );
  }

  void _updateConstraints({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    setState(() {
      _constraints = BoxConstraints(
        minWidth: minWidth ?? _constraints?.minWidth ?? 0,
        minHeight: minHeight ?? _constraints?.minHeight ?? 0,
        maxWidth: maxWidth ?? _constraints?.maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? _constraints?.maxHeight ?? double.infinity,
      );
    });
    widget.onPropertyChanged('constraints', _constraints);
    _propertyManager.updateProperty(widget.selectedWidget, 'constraints', _constraints);
  }

  Widget _buildWidgetTypeDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.widgets,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            widget.selectedWidget.widgetType,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSchemaParameters(ThemeData theme, List<PropertyDefinition> properties) {
    if (properties.isEmpty) {
      return [
        Text(
          'No parameters defined',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    return properties.map((prop) => _buildPropertyInput(theme, prop)).toList();
  }

  Widget _buildPropertyInput(ThemeData theme, PropertyDefinition prop) {
    final label = prop.required ? '${prop.name} *' : prop.name;

    switch (prop.type) {
      case PropertyType.string:
        return _buildTextInput(theme, label, prop.defaultValue?.toString());

      case PropertyType.int:
      case PropertyType.double:
        return _buildSliderProperty(
          theme,
          label,
          (prop.defaultValue as num?)?.toDouble() ?? prop.min ?? 0,
          prop.min ?? 0,
          prop.max ?? 100,
          (value) {
            widget.onPropertyChanged(prop.name, value);
            _propertyManager.updateProperty(widget.selectedWidget, prop.name, value);
          },
        );

      case PropertyType.bool:
        return _buildToggleProperty(theme, label, prop.defaultValue ?? false);

      case PropertyType.color:
        return _buildColorProperty(
          theme,
          label,
          prop.defaultValue ?? Colors.blue,
          (color) {
            widget.onPropertyChanged(prop.name, color);
            _propertyManager.updateProperty(widget.selectedWidget, prop.name, color);
          },
        );

      case PropertyType.enumValue:
        if (prop.enumValues != null && prop.enumValues!.isNotEmpty) {
          return _buildDropdownProperty(
            theme,
            label,
            prop.defaultValue ?? prop.enumValues!.first,
            prop.enumValues!,
            (value) {
              widget.onPropertyChanged(prop.name, value);
              _propertyManager.updateProperty(widget.selectedWidget, prop.name, value);
            },
          );
        }
        return _buildTextInput(theme, label, prop.defaultValue?.toString());

      case PropertyType.function:
        return _buildFunctionEditor(theme, label, prop.defaultValue?.toString());

      case PropertyType.widget:
        return _buildWidgetSelector(theme, label, prop.defaultValue?.toString());

      case PropertyType.alignment:
        return _buildDropdownProperty(
          theme,
          label,
          prop.defaultValue ?? 'Alignment.center',
          [
            'Alignment.topLeft',
            'Alignment.topCenter',
            'Alignment.topRight',
            'Alignment.centerLeft',
            'Alignment.center',
            'Alignment.centerRight',
            'Alignment.bottomLeft',
            'Alignment.bottomCenter',
            'Alignment.bottomRight',
          ],
          (value) {
            widget.onPropertyChanged(prop.name, value);
            _propertyManager.updateProperty(widget.selectedWidget, prop.name, value);
          },
        );

      default:
        return _buildTextInput(theme, label, prop.defaultValue?.toString());
    }
  }

  Widget _buildConstructorTypeSelector(ThemeData theme) {
    final constructors = _getConstructorTypes();
    return _buildDropdownProperty(
      theme,
      'Type',
      constructors.first,
      constructors,
      (value) {
        widget.onPropertyChanged('constructor', value);
      },
    );
  }

  List<String> _getConstructorTypes() {
    final widgetType = widget.selectedWidget.widgetType;
    switch (widgetType) {
      case 'Container':
        return ['Default', 'Container.fromColor'];
      case 'FloatingActionButton':
        return ['Default', 'FloatingActionButton.small', 'FloatingActionButton.large', 'FloatingActionButton.extended'];
      case 'Text':
        return ['Default', 'Text.rich'];
      case 'Icon':
        return ['Default'];
      default:
        return ['Default'];
    }
  }

  List<Widget> _buildRequiredParameters(ThemeData theme) {
    final widgetType = widget.selectedWidget.widgetType;
    switch (widgetType) {
      case 'FloatingActionButton':
        return [
          _buildFunctionEditor(theme, 'onPressed', '_incrementCounter'),
          _buildWidgetSelector(theme, 'child', 'Icon(Icons.add)'),
        ];
      case 'Text':
        return [
          _buildTextInput(theme, 'data', 'Hello World'),
        ];
      case 'Icon':
        return [
          _buildTextInput(theme, 'icon', 'Icons.star'),
        ];
      case 'Container':
        return [
          _buildWidgetSelector(theme, 'child', null),
        ];
      default:
        return [
          Text(
            'No required parameters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ];
    }
  }

  List<Widget> _buildOptionalParameters(ThemeData theme) {
    final widgetType = widget.selectedWidget.widgetType;
    switch (widgetType) {
      case 'FloatingActionButton':
        return [
          _buildTextInput(theme, 'tooltip', 'Increment'),
          _buildTextInput(theme, 'heroTag', 'fab'),
          _buildSliderProperty(theme, 'elevation', 6.0, 0.0, 24.0, (value) {
            widget.onPropertyChanged('elevation', value);
          }),
          _buildColorProperty(theme, 'backgroundColor', Theme.of(context).colorScheme.secondary, (color) {
            widget.onPropertyChanged('backgroundColor', color);
          }),
          _buildColorProperty(theme, 'foregroundColor', Colors.white, (color) {
            widget.onPropertyChanged('foregroundColor', color);
          }),
        ];
      case 'Text':
        return [
          _buildDropdownProperty(theme, 'textAlign', 'TextAlign.start',
            ['TextAlign.start', 'TextAlign.center', 'TextAlign.end', 'TextAlign.justify'],
            (value) {
              widget.onPropertyChanged('textAlign', value);
            },
          ),
          _buildToggleProperty(theme, 'softWrap', true),
          _buildDropdownProperty(theme, 'overflow', 'TextOverflow.clip',
            ['TextOverflow.clip', 'TextOverflow.ellipsis', 'TextOverflow.fade', 'TextOverflow.visible'],
            (value) {
              widget.onPropertyChanged('overflow', value);
            },
          ),
        ];
      case 'Container':
        return [
          _buildSliderProperty(theme, 'width', 100.0, 0.0, 500.0, (value) {
            widget.onPropertyChanged('width', value);
          }),
          _buildSliderProperty(theme, 'height', 100.0, 0.0, 500.0, (value) {
            widget.onPropertyChanged('height', value);
          }),
          _buildDropdownProperty(theme, 'alignment', 'Alignment.center',
            ['Alignment.topLeft', 'Alignment.topCenter', 'Alignment.topRight',
             'Alignment.centerLeft', 'Alignment.center', 'Alignment.centerRight',
             'Alignment.bottomLeft', 'Alignment.bottomCenter', 'Alignment.bottomRight'],
            (value) {
              widget.onPropertyChanged('alignment', value);
            },
          ),
        ];
      default:
        return [
          Text(
            'No optional parameters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ];
    }
  }

  Widget _buildFunctionEditor(ThemeData theme, String label, String? currentFunction) {
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: currentFunction),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Function name or () => {}',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    widget.onPropertyChanged(label, value.isEmpty ? null : value);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.code, size: 18, color: theme.colorScheme.primary),
                onPressed: () => _showCodeEditor(label, currentFunction),
                tooltip: 'Open code editor',
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetSelector(ThemeData theme, String label, String? currentWidget) {
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: currentWidget),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Widget code or select...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    widget.onPropertyChanged(label, value.isEmpty ? null : value);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.widgets, size: 18, color: theme.colorScheme.primary),
                onPressed: () => _showWidgetPicker(label, currentWidget),
                tooltip: 'Select widget',
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(ThemeData theme, String label, String? defaultValue) {
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
          child: TextField(
            controller: TextEditingController(text: defaultValue),
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: 'Enter $label...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              widget.onPropertyChanged(label, value.isEmpty ? null : value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleProperty(ThemeData theme, String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            widget.onPropertyChanged(label, newValue);
          },
          activeThumbColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  void _showCodeEditor(String propertyName, String? currentCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $propertyName'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[900],
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: TextEditingController(text: currentCode ?? ''),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white,
              ),
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: '() {\n  // Your code here\n}',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                // Update will happen on save
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save the code
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWidgetPicker(String propertyName, String? currentWidget) {
    final commonWidgets = [
      'Icon(Icons.add)',
      'Icon(Icons.edit)',
      'Icon(Icons.delete)',
      'Text("Click me")',
      'CircularProgressIndicator()',
      'Container()',
      'SizedBox()',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Widget for $propertyName'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: commonWidgets.length,
            itemBuilder: (context, index) {
              final widgetCode = commonWidgets[index];
              return ListTile(
                title: Text(
                  widgetCode,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                selected: currentWidget == widgetCode,
                onTap: () {
                  widget.onPropertyChanged(propertyName, widgetCode);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
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
                '#${value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
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