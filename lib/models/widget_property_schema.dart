enum PropertyType {
  string,
  int,
  double,
  bool,
  color,
  enumValue,
  function,
  widget,
  alignment,
  edgeInsets,
  constraints,
  decoration,
  textStyle,
}

class PropertyDefinition {
  final String name;
  final PropertyType type;
  final bool required;
  final dynamic defaultValue;
  final List<String>? enumValues;
  final String? description;
  final double? min;
  final double? max;

  const PropertyDefinition({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.enumValues,
    this.description,
    this.min,
    this.max,
  });
}

class WidgetPropertySchema {
  final String widgetType;
  final List<PropertyDefinition> constructor;
  final List<PropertyDefinition> interaction;
  final List<PropertyDefinition> advanced;

  const WidgetPropertySchema({
    required this.widgetType,
    this.constructor = const [],
    this.interaction = const [],
    this.advanced = const [],
  });
}

class WidgetSchemas {
  static final Map<String, WidgetPropertySchema> schemas = {
    'Container': WidgetPropertySchema(
      widgetType: 'Container',
      constructor: [
        PropertyDefinition(
          name: 'child',
          type: PropertyType.widget,
          description: 'The child widget',
        ),
        PropertyDefinition(
          name: 'width',
          type: PropertyType.double,
          min: 0,
          max: 500,
          description: 'Container width',
        ),
        PropertyDefinition(
          name: 'height',
          type: PropertyType.double,
          min: 0,
          max: 500,
          description: 'Container height',
        ),
        PropertyDefinition(
          name: 'color',
          type: PropertyType.color,
          description: 'Background color',
        ),
        PropertyDefinition(
          name: 'alignment',
          type: PropertyType.alignment,
          defaultValue: 'Alignment.center',
          description: 'Child alignment',
        ),
      ],
      interaction: [],
      advanced: [
        PropertyDefinition(
          name: 'constraints',
          type: PropertyType.constraints,
          description: 'Size constraints',
        ),
        PropertyDefinition(
          name: 'decoration',
          type: PropertyType.decoration,
          description: 'Container decoration',
        ),
        PropertyDefinition(
          name: 'transform',
          type: PropertyType.double,
          description: 'Transform matrix',
        ),
      ],
    ),
    'Text': WidgetPropertySchema(
      widgetType: 'Text',
      constructor: [
        PropertyDefinition(
          name: 'data',
          type: PropertyType.string,
          required: true,
          defaultValue: 'Hello World',
          description: 'Text to display',
        ),
        PropertyDefinition(
          name: 'textAlign',
          type: PropertyType.enumValue,
          enumValues: [
            'TextAlign.start',
            'TextAlign.center',
            'TextAlign.end',
            'TextAlign.justify',
          ],
          defaultValue: 'TextAlign.start',
        ),
        PropertyDefinition(
          name: 'overflow',
          type: PropertyType.enumValue,
          enumValues: [
            'TextOverflow.clip',
            'TextOverflow.ellipsis',
            'TextOverflow.fade',
            'TextOverflow.visible',
          ],
          defaultValue: 'TextOverflow.clip',
        ),
        PropertyDefinition(
          name: 'softWrap',
          type: PropertyType.bool,
          defaultValue: true,
        ),
        PropertyDefinition(
          name: 'maxLines',
          type: PropertyType.int,
          min: 1,
          max: 100,
        ),
      ],
      interaction: [],
      advanced: [
        PropertyDefinition(
          name: 'textScaleFactor',
          type: PropertyType.double,
          min: 0.5,
          max: 3.0,
          defaultValue: 1.0,
        ),
        PropertyDefinition(
          name: 'semanticsLabel',
          type: PropertyType.string,
          description: 'Accessibility label',
        ),
      ],
    ),
    'Icon': WidgetPropertySchema(
      widgetType: 'Icon',
      constructor: [
        PropertyDefinition(
          name: 'icon',
          type: PropertyType.string,
          required: true,
          defaultValue: 'Icons.star',
          description: 'Icon to display',
        ),
        PropertyDefinition(
          name: 'size',
          type: PropertyType.double,
          min: 8,
          max: 128,
          defaultValue: 24,
        ),
        PropertyDefinition(
          name: 'color',
          type: PropertyType.color,
        ),
      ],
      interaction: [],
      advanced: [
        PropertyDefinition(
          name: 'semanticLabel',
          type: PropertyType.string,
          description: 'Accessibility label',
        ),
      ],
    ),
    'ElevatedButton': WidgetPropertySchema(
      widgetType: 'ElevatedButton',
      constructor: [
        PropertyDefinition(
          name: 'child',
          type: PropertyType.widget,
          required: true,
          description: 'Button child widget',
        ),
        PropertyDefinition(
          name: 'autofocus',
          type: PropertyType.bool,
          defaultValue: false,
        ),
      ],
      interaction: [
        PropertyDefinition(
          name: 'onPressed',
          type: PropertyType.function,
          required: true,
          description: 'Called when button is pressed',
        ),
        PropertyDefinition(
          name: 'onLongPress',
          type: PropertyType.function,
          description: 'Called when button is long pressed',
        ),
        PropertyDefinition(
          name: 'onHover',
          type: PropertyType.function,
          description: 'Called when button is hovered',
        ),
      ],
      advanced: [
        PropertyDefinition(
          name: 'clipBehavior',
          type: PropertyType.enumValue,
          enumValues: ['Clip.none', 'Clip.hardEdge', 'Clip.antiAlias'],
          defaultValue: 'Clip.none',
        ),
      ],
    ),
    'FloatingActionButton': WidgetPropertySchema(
      widgetType: 'FloatingActionButton',
      constructor: [
        PropertyDefinition(
          name: 'child',
          type: PropertyType.widget,
          description: 'Button child (usually Icon)',
        ),
        PropertyDefinition(
          name: 'tooltip',
          type: PropertyType.string,
          defaultValue: '',
          description: 'Tooltip text',
        ),
        PropertyDefinition(
          name: 'heroTag',
          type: PropertyType.string,
          defaultValue: 'fab',
          description: 'Hero animation tag',
        ),
        PropertyDefinition(
          name: 'elevation',
          type: PropertyType.double,
          min: 0,
          max: 24,
          defaultValue: 6.0,
        ),
        PropertyDefinition(
          name: 'backgroundColor',
          type: PropertyType.color,
        ),
        PropertyDefinition(
          name: 'foregroundColor',
          type: PropertyType.color,
        ),
        PropertyDefinition(
          name: 'mini',
          type: PropertyType.bool,
          defaultValue: false,
        ),
      ],
      interaction: [
        PropertyDefinition(
          name: 'onPressed',
          type: PropertyType.function,
          required: true,
          description: 'Called when FAB is pressed',
        ),
      ],
      advanced: [
        PropertyDefinition(
          name: 'autofocus',
          type: PropertyType.bool,
          defaultValue: false,
        ),
        PropertyDefinition(
          name: 'enableFeedback',
          type: PropertyType.bool,
          defaultValue: true,
        ),
      ],
    ),
    'TextField': WidgetPropertySchema(
      widgetType: 'TextField',
      constructor: [
        PropertyDefinition(
          name: 'decoration',
          type: PropertyType.decoration,
          description: 'Input decoration',
        ),
        PropertyDefinition(
          name: 'maxLines',
          type: PropertyType.int,
          min: 1,
          max: 100,
          defaultValue: 1,
        ),
        PropertyDefinition(
          name: 'obscureText',
          type: PropertyType.bool,
          defaultValue: false,
        ),
        PropertyDefinition(
          name: 'enabled',
          type: PropertyType.bool,
          defaultValue: true,
        ),
        PropertyDefinition(
          name: 'autofocus',
          type: PropertyType.bool,
          defaultValue: false,
        ),
      ],
      interaction: [
        PropertyDefinition(
          name: 'onChanged',
          type: PropertyType.function,
          description: 'Called when text changes',
        ),
        PropertyDefinition(
          name: 'onSubmitted',
          type: PropertyType.function,
          description: 'Called when user submits',
        ),
        PropertyDefinition(
          name: 'onTap',
          type: PropertyType.function,
          description: 'Called when field is tapped',
        ),
      ],
      advanced: [
        PropertyDefinition(
          name: 'textAlign',
          type: PropertyType.enumValue,
          enumValues: [
            'TextAlign.start',
            'TextAlign.center',
            'TextAlign.end',
          ],
          defaultValue: 'TextAlign.start',
        ),
      ],
    ),
    'Column': WidgetPropertySchema(
      widgetType: 'Column',
      constructor: [
        PropertyDefinition(
          name: 'children',
          type: PropertyType.widget,
          required: true,
          description: 'List of child widgets',
        ),
        PropertyDefinition(
          name: 'mainAxisAlignment',
          type: PropertyType.enumValue,
          enumValues: [
            'MainAxisAlignment.start',
            'MainAxisAlignment.center',
            'MainAxisAlignment.end',
            'MainAxisAlignment.spaceAround',
            'MainAxisAlignment.spaceBetween',
            'MainAxisAlignment.spaceEvenly',
          ],
          defaultValue: 'MainAxisAlignment.start',
        ),
        PropertyDefinition(
          name: 'crossAxisAlignment',
          type: PropertyType.enumValue,
          enumValues: [
            'CrossAxisAlignment.start',
            'CrossAxisAlignment.center',
            'CrossAxisAlignment.end',
            'CrossAxisAlignment.stretch',
          ],
          defaultValue: 'CrossAxisAlignment.center',
        ),
        PropertyDefinition(
          name: 'mainAxisSize',
          type: PropertyType.enumValue,
          enumValues: [
            'MainAxisSize.min',
            'MainAxisSize.max',
          ],
          defaultValue: 'MainAxisSize.max',
        ),
      ],
      interaction: [],
      advanced: [],
    ),
    'Row': WidgetPropertySchema(
      widgetType: 'Row',
      constructor: [
        PropertyDefinition(
          name: 'children',
          type: PropertyType.widget,
          required: true,
          description: 'List of child widgets',
        ),
        PropertyDefinition(
          name: 'mainAxisAlignment',
          type: PropertyType.enumValue,
          enumValues: [
            'MainAxisAlignment.start',
            'MainAxisAlignment.center',
            'MainAxisAlignment.end',
            'MainAxisAlignment.spaceAround',
            'MainAxisAlignment.spaceBetween',
            'MainAxisAlignment.spaceEvenly',
          ],
          defaultValue: 'MainAxisAlignment.start',
        ),
        PropertyDefinition(
          name: 'crossAxisAlignment',
          type: PropertyType.enumValue,
          enumValues: [
            'CrossAxisAlignment.start',
            'CrossAxisAlignment.center',
            'CrossAxisAlignment.end',
            'CrossAxisAlignment.stretch',
          ],
          defaultValue: 'CrossAxisAlignment.center',
        ),
        PropertyDefinition(
          name: 'mainAxisSize',
          type: PropertyType.enumValue,
          enumValues: [
            'MainAxisSize.min',
            'MainAxisSize.max',
          ],
          defaultValue: 'MainAxisSize.max',
        ),
      ],
      interaction: [],
      advanced: [],
    ),
    'ListView': WidgetPropertySchema(
      widgetType: 'ListView',
      constructor: [
        PropertyDefinition(
          name: 'children',
          type: PropertyType.widget,
          description: 'List items',
        ),
        PropertyDefinition(
          name: 'scrollDirection',
          type: PropertyType.enumValue,
          enumValues: [
            'Axis.vertical',
            'Axis.horizontal',
          ],
          defaultValue: 'Axis.vertical',
        ),
        PropertyDefinition(
          name: 'shrinkWrap',
          type: PropertyType.bool,
          defaultValue: false,
        ),
      ],
      interaction: [],
      advanced: [
        PropertyDefinition(
          name: 'physics',
          type: PropertyType.enumValue,
          enumValues: [
            'AlwaysScrollableScrollPhysics()',
            'NeverScrollableScrollPhysics()',
            'BouncingScrollPhysics()',
          ],
        ),
      ],
    ),
  };

  static WidgetPropertySchema? getSchema(String widgetType) {
    return schemas[widgetType];
  }

  static List<String> getSupportedWidgets() {
    return schemas.keys.toList();
  }
}
