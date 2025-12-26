/// Layout properties for detailed widget inspection
/// Based on Flutter DevTools inspector_data_models.dart
class WidgetLayoutInfo {
  final double width;
  final double height;
  final double? flexFactor;
  final String? flexFit;
  final bool hasOverflow;
  final String? constraints;
  final String? padding;
  final String? alignment;

  const WidgetLayoutInfo({
    required this.width,
    required this.height,
    this.flexFactor,
    this.flexFit,
    this.hasOverflow = false,
    this.constraints,
    this.padding,
    this.alignment,
  });

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    if (flexFactor != null) 'flexFactor': flexFactor,
    if (flexFit != null) 'flexFit': flexFit,
    if (hasOverflow) 'hasOverflow': hasOverflow,
    if (constraints != null) 'constraints': constraints,
    if (padding != null) 'padding': padding,
    if (alignment != null) 'alignment': alignment,
  };

  factory WidgetLayoutInfo.fromJson(Map<String, dynamic> json) {
    return WidgetLayoutInfo(
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      flexFactor: json['flexFactor']?.toDouble(),
      flexFit: json['flexFit'],
      hasOverflow: json['hasOverflow'] ?? false,
      constraints: json['constraints'],
      padding: json['padding'],
      alignment: json['alignment'],
    );
  }
}

class WidgetSelection {
  final String widgetType;
  final String widgetId;
  final String filePath;
  final int lineNumber;
  final Map<String, dynamic> properties;
  final String sourceCode;

  // New fields for precise widget identification
  final String? uniqueInstanceId;
  final int siblingIndex;
  final double matchConfidence;
  final int? columnNumber;
  final List<String> parentChain;

  // Layout information (from DevTools patterns)
  final WidgetLayoutInfo? layoutInfo;
  final Map<String, dynamic>? diagnosticProperties;

  const WidgetSelection({
    required this.widgetType,
    required this.widgetId,
    required this.filePath,
    required this.lineNumber,
    required this.properties,
    required this.sourceCode,
    this.uniqueInstanceId,
    this.siblingIndex = 0,
    this.matchConfidence = 1.0,
    this.columnNumber,
    this.parentChain = const [],
    this.layoutInfo,
    this.diagnosticProperties,
  });

  /// Check if this is an exact match (high confidence)
  bool get isExactMatch => matchConfidence > 0.95;

  /// Check if this is an approximate match
  bool get isApproximateMatch => matchConfidence > 0.5 && matchConfidence <= 0.95;

  /// Get formatted location string
  String get locationString {
    if (columnNumber != null) {
      return '$filePath:$lineNumber:$columnNumber';
    }
    return '$filePath:$lineNumber';
  }

  /// Get short description for display
  String get shortDescription {
    final siblingInfo = siblingIndex > 0 ? ' #$siblingIndex' : '';
    return '$widgetType$siblingInfo';
  }

  @override
  String toString() => 'WidgetSelection($widgetType at $filePath:$lineNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetSelection &&
          runtimeType == other.runtimeType &&
          widgetId == other.widgetId &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => widgetId.hashCode ^ filePath.hashCode ^ lineNumber.hashCode;

  /// Get layout summary for display
  String get layoutSummary {
    if (layoutInfo == null) return '';
    final li = layoutInfo!;
    final parts = <String>[];
    parts.add('${li.width.toInt()}×${li.height.toInt()}');
    if (li.flexFactor != null) parts.add('flex:${li.flexFactor}');
    if (li.hasOverflow) parts.add('OVERFLOW');
    return parts.join(' | ');
  }

  Map<String, dynamic> toJson() {
    return {
      'widgetType': widgetType,
      'widgetId': widgetId,
      'filePath': filePath,
      'lineNumber': lineNumber,
      'properties': properties,
      'sourceCode': sourceCode,
      'uniqueInstanceId': uniqueInstanceId,
      'siblingIndex': siblingIndex,
      'matchConfidence': matchConfidence,
      'columnNumber': columnNumber,
      'parentChain': parentChain,
      if (layoutInfo != null) 'layoutInfo': layoutInfo!.toJson(),
      if (diagnosticProperties != null) 'diagnosticProperties': diagnosticProperties,
    };
  }

  factory WidgetSelection.fromJson(Map<String, dynamic> json) {
    return WidgetSelection(
      widgetType: json['widgetType'] ?? '',
      widgetId: json['widgetId'] ?? '',
      filePath: json['filePath'] ?? '',
      lineNumber: json['lineNumber'] ?? 0,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      sourceCode: json['sourceCode'] ?? '',
      uniqueInstanceId: json['uniqueInstanceId'],
      siblingIndex: json['siblingIndex'] ?? 0,
      matchConfidence: (json['matchConfidence'] ?? 1.0).toDouble(),
      columnNumber: json['columnNumber'],
      parentChain: List<String>.from(json['parentChain'] ?? []),
      layoutInfo: json['layoutInfo'] != null
          ? WidgetLayoutInfo.fromJson(json['layoutInfo'])
          : null,
      diagnosticProperties: json['diagnosticProperties'] != null
          ? Map<String, dynamic>.from(json['diagnosticProperties'])
          : null,
    );
  }

  WidgetSelection copyWith({
    String? widgetType,
    String? widgetId,
    String? filePath,
    int? lineNumber,
    Map<String, dynamic>? properties,
    String? sourceCode,
    String? uniqueInstanceId,
    int? siblingIndex,
    double? matchConfidence,
    int? columnNumber,
    List<String>? parentChain,
    WidgetLayoutInfo? layoutInfo,
    Map<String, dynamic>? diagnosticProperties,
  }) {
    return WidgetSelection(
      widgetType: widgetType ?? this.widgetType,
      widgetId: widgetId ?? this.widgetId,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      properties: properties ?? this.properties,
      sourceCode: sourceCode ?? this.sourceCode,
      uniqueInstanceId: uniqueInstanceId ?? this.uniqueInstanceId,
      siblingIndex: siblingIndex ?? this.siblingIndex,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      columnNumber: columnNumber ?? this.columnNumber,
      parentChain: parentChain ?? this.parentChain,
      layoutInfo: layoutInfo ?? this.layoutInfo,
      diagnosticProperties: diagnosticProperties ?? this.diagnosticProperties,
    );
  }
}
