class WidgetSelection {
  final String widgetType;
  final String widgetId;
  final String filePath;
  final int lineNumber;
  final Map<String, dynamic> properties;
  final String sourceCode;

  const WidgetSelection({
    required this.widgetType,
    required this.widgetId,
    required this.filePath,
    required this.lineNumber,
    required this.properties,
    required this.sourceCode,
  });

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

  Map<String, dynamic> toJson() {
    return {
      'widgetType': widgetType,
      'widgetId': widgetId,
      'filePath': filePath,
      'lineNumber': lineNumber,
      'properties': properties,
      'sourceCode': sourceCode,
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
    );
  }

  WidgetSelection copyWith({
    String? widgetType,
    String? widgetId,
    String? filePath,
    int? lineNumber,
    Map<String, dynamic>? properties,
    String? sourceCode,
  }) {
    return WidgetSelection(
      widgetType: widgetType ?? this.widgetType,
      widgetId: widgetId ?? this.widgetId,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      properties: properties ?? this.properties,
      sourceCode: sourceCode ?? this.sourceCode,
    );
  }
}