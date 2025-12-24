import 'package:flutter/material.dart';
import 'package:kre8tions/models/widget_selection.dart';

class VisualPropertyManager {
  static final VisualPropertyManager _instance = VisualPropertyManager._internal();
  factory VisualPropertyManager() => _instance;
  VisualPropertyManager._internal();

  // Current visual properties for selected widgets
  final Map<String, Map<String, dynamic>> _visualProperties = {};
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void updateProperty(WidgetSelection selection, String property, dynamic value) {
    final key = _getSelectionKey(selection);
    
    _visualProperties[key] ??= {};
    _visualProperties[key]![property] = value;
    
    _notifyListeners();
  }

  T? getProperty<T>(WidgetSelection selection, String property) {
    final key = _getSelectionKey(selection);
    return _visualProperties[key]?[property] as T?;
  }

  Map<String, dynamic> getAllProperties(WidgetSelection selection) {
    final key = _getSelectionKey(selection);
    return _visualProperties[key] ?? {};
  }

  void clearProperties(WidgetSelection selection) {
    final key = _getSelectionKey(selection);
    _visualProperties.remove(key);
    _notifyListeners();
  }

  String _getSelectionKey(WidgetSelection selection) {
    return '${selection.widgetType}_${selection.filePath}_${selection.lineNumber}';
  }

  // Helper methods for getting styled properties
  Color getBackgroundColor(WidgetSelection selection, Color defaultColor) {
    return getProperty<Color>(selection, 'backgroundColor') ?? defaultColor;
  }

  Color getTextColor(WidgetSelection selection, Color defaultColor) {
    return getProperty<Color>(selection, 'textColor') ?? defaultColor;
  }

  double getBorderRadius(WidgetSelection selection, double defaultRadius) {
    return getProperty<double>(selection, 'borderRadius') ?? defaultRadius;
  }

  double getElevation(WidgetSelection selection, double defaultElevation) {
    return getProperty<double>(selection, 'elevation') ?? defaultElevation;
  }

  double getOpacity(WidgetSelection selection, double defaultOpacity) {
    return getProperty<double>(selection, 'opacity') ?? defaultOpacity;
  }

  EdgeInsets getPadding(WidgetSelection selection, EdgeInsets defaultPadding) {
    return getProperty<EdgeInsets>(selection, 'padding') ?? defaultPadding;
  }

  EdgeInsets getMargin(WidgetSelection selection, EdgeInsets defaultMargin) {
    return getProperty<EdgeInsets>(selection, 'margin') ?? defaultMargin;
  }

  double getFontSize(WidgetSelection selection, double defaultSize) {
    return getProperty<double>(selection, 'fontSize') ?? defaultSize;
  }

  FontWeight getFontWeight(WidgetSelection selection, FontWeight defaultWeight) {
    return getProperty<FontWeight>(selection, 'fontWeight') ?? defaultWeight;
  }

  String getFontFamily(WidgetSelection selection, String defaultFamily) {
    return getProperty<String>(selection, 'fontFamily') ?? defaultFamily;
  }

  // Generate decoration based on current properties
  BoxDecoration getDecoration(WidgetSelection selection, BoxDecoration defaultDecoration) {
    final properties = getAllProperties(selection);
    
    if (properties.isEmpty) return defaultDecoration;
    
    return BoxDecoration(
      color: getBackgroundColor(selection, defaultDecoration.color ?? Colors.transparent),
      borderRadius: BorderRadius.circular(getBorderRadius(selection, 0)),
      boxShadow: getElevation(selection, 0) > 0 ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: getElevation(selection, 0) * 2,
          offset: Offset(0, getElevation(selection, 0)),
        ),
      ] : null,
      border: defaultDecoration.border,
    );
  }

  // Generate text style based on current properties
  TextStyle getTextStyle(WidgetSelection selection, TextStyle defaultStyle) {
    final properties = getAllProperties(selection);
    
    if (properties.isEmpty) return defaultStyle;
    
    return defaultStyle.copyWith(
      color: getTextColor(selection, defaultStyle.color ?? Colors.black),
      fontSize: getFontSize(selection, defaultStyle.fontSize ?? 14.0),
      fontWeight: getFontWeight(selection, defaultStyle.fontWeight ?? FontWeight.normal),
      fontFamily: getFontFamily(selection, defaultStyle.fontFamily ?? 'System') == 'System' 
        ? null 
        : getFontFamily(selection, defaultStyle.fontFamily ?? 'System'),
    );
  }

  // Get container with all applied properties
  Widget getStyledContainer({
    required WidgetSelection selection,
    required Widget child,
    BoxDecoration? defaultDecoration,
    EdgeInsets? defaultPadding,
    EdgeInsets? defaultMargin,
  }) {
    final decoration = getDecoration(selection, defaultDecoration ?? const BoxDecoration());
    final padding = getPadding(selection, defaultPadding ?? EdgeInsets.zero);
    final margin = getMargin(selection, defaultMargin ?? EdgeInsets.zero);
    final opacity = getOpacity(selection, 1.0);
    
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }

  // Reset all properties
  void reset() {
    _visualProperties.clear();
    _notifyListeners();
  }
}