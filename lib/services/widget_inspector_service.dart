import 'package:flutter/material.dart';
import 'dart:async';

/// Service for inspecting widgets in the UI preview
/// Provides overlay highlighting and metadata extraction
class WidgetInspectorService {
  static final WidgetInspectorService _instance = WidgetInspectorService._internal();
  factory WidgetInspectorService() => _instance;
  WidgetInspectorService._internal();

  bool _isInspectionMode = false;
  final _inspectionModeController = StreamController<bool>.broadcast();
  final _selectedWidgetController = StreamController<WidgetInspectionData?>.broadcast();

  Stream<bool> get inspectionModeStream => _inspectionModeController.stream;
  Stream<WidgetInspectionData?> get selectedWidgetStream => _selectedWidgetController.stream;
  bool get isInspectionMode => _isInspectionMode;

  void toggleInspectionMode() {
    _isInspectionMode = !_isInspectionMode;
    _inspectionModeController.add(_isInspectionMode);
    if (!_isInspectionMode) {
      _selectedWidgetController.add(null);
    }
  }

  void enableInspectionMode() {
    _isInspectionMode = true;
    _inspectionModeController.add(true);
  }

  void disableInspectionMode() {
    _isInspectionMode = false;
    _inspectionModeController.add(false);
    _selectedWidgetController.add(null);
  }

  void selectWidget(WidgetInspectionData data) {
    _selectedWidgetController.add(data);
  }

  void dispose() {
    _inspectionModeController.close();
    _selectedWidgetController.close();
  }
}

/// Data about an inspected widget
class WidgetInspectionData {
  final String widgetType;
  final Rect bounds;
  final Map<String, dynamic> properties;
  final List<WidgetInspectionData> children;
  final int depth;
  final String? sourceLocation;

  WidgetInspectionData({
    required this.widgetType,
    required this.bounds,
    this.properties = const {},
    this.children = const [],
    this.depth = 0,
    this.sourceLocation,
  });

  Map<String, dynamic> toJson() => {
    'widgetType': widgetType,
    'bounds': {
      'left': bounds.left,
      'top': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
    },
    'properties': properties,
    'children': children.map((c) => c.toJson()).toList(),
    'depth': depth,
    'sourceLocation': sourceLocation,
  };

  @override
  String toString() {
    final props = properties.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$widgetType (depth: $depth, props: {$props}, children: ${children.length})';
  }
}
