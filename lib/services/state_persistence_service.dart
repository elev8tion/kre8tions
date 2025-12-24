import 'dart:convert';
import 'dart:html' as html;

import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/utils/logger.dart';

/// Comprehensive state persistence service for CodeWhisper IDE
/// Handles all app state including projects, UI preferences, and session data
class StatePersistenceService {
  static const String _projectStateKey = 'codewhisper_project_state';
  static const String _uiPreferencesKey = 'codewhisper_ui_preferences';
  static const String _sessionDataKey = 'codewhisper_session_data';
  static const String _userPreferencesKey = 'codewhisper_user_preferences';

  // Singleton pattern
  static final StatePersistenceService _instance = StatePersistenceService._internal();
  factory StatePersistenceService() => _instance;
  StatePersistenceService._internal();

  /// Project State Management
  
  Future<void> saveProjectState(AppProjectState projectState) async {
    try {
      final json = projectState.toJson();
      html.window.localStorage[_projectStateKey] = jsonEncode(json);
    } catch (e) {
      Logger.error('Error saving project state', e);
    }
  }

  AppProjectState? loadProjectState() {
    try {
      final jsonString = html.window.localStorage[_projectStateKey];
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString);
      return AppProjectState.fromJson(json);
    } catch (e) {
      Logger.error('Error loading project state', e);
      return null;
    }
  }

  /// UI Preferences Management
  
  Future<void> saveUIPreferences(AppUIPreferences preferences) async {
    try {
      final json = preferences.toJson();
      html.window.localStorage[_uiPreferencesKey] = jsonEncode(json);
    } catch (e) {
      Logger.error('Error saving UI preferences', e);
    }
  }

  AppUIPreferences loadUIPreferences() {
    try {
      final jsonString = html.window.localStorage[_uiPreferencesKey];
      if (jsonString == null) return AppUIPreferences.defaultPreferences();
      
      final json = jsonDecode(jsonString);
      return AppUIPreferences.fromJson(json);
    } catch (e) {
      Logger.error('Error loading UI preferences', e);
      return AppUIPreferences.defaultPreferences();
    }
  }

  /// Session Data Management
  
  Future<void> saveSessionData(AppSessionData sessionData) async {
    try {
      final json = sessionData.toJson();
      html.window.localStorage[_sessionDataKey] = jsonEncode(json);
    } catch (e) {
      Logger.error('Error saving session data', e);
    }
  }

  AppSessionData loadSessionData() {
    try {
      final jsonString = html.window.localStorage[_sessionDataKey];
      if (jsonString == null) return AppSessionData.empty();
      
      final json = jsonDecode(jsonString);
      return AppSessionData.fromJson(json);
    } catch (e) {
      Logger.error('Error loading session data', e);
      return AppSessionData.empty();
    }
  }

  /// User Preferences Management
  
  Future<void> saveUserPreferences(AppUserPreferences userPreferences) async {
    try {
      final json = userPreferences.toJson();
      html.window.localStorage[_userPreferencesKey] = jsonEncode(json);
    } catch (e) {
      Logger.error('Error saving user preferences', e);
    }
  }

  AppUserPreferences loadUserPreferences() {
    try {
      final jsonString = html.window.localStorage[_userPreferencesKey];
      if (jsonString == null) return AppUserPreferences.defaultPreferences();
      
      final json = jsonDecode(jsonString);
      return AppUserPreferences.fromJson(json);
    } catch (e) {
      Logger.error('Error loading user preferences', e);
      return AppUserPreferences.defaultPreferences();
    }
  }

  /// Utility Methods
  
  Future<void> clearAllPersistedData() async {
    try {
      html.window.localStorage.remove(_projectStateKey);
      html.window.localStorage.remove(_uiPreferencesKey);
      html.window.localStorage.remove(_sessionDataKey);
      html.window.localStorage.remove(_userPreferencesKey);
    } catch (e) {
      Logger.error('Error clearing persisted data', e);
    }
  }

  Future<void> clearProjectData() async {
    try {
      html.window.localStorage.remove(_projectStateKey);
    } catch (e) {
      Logger.error('Error clearing project data', e);
    }
  }

  bool hasPersistedProjectState() {
    return html.window.localStorage.containsKey(_projectStateKey);
  }

  /// Get storage usage info for debugging
  Map<String, dynamic> getStorageInfo() {
    final info = <String, dynamic>{};
    
    try {
      info['projectState'] = html.window.localStorage[_projectStateKey]?.length ?? 0;
      info['uiPreferences'] = html.window.localStorage[_uiPreferencesKey]?.length ?? 0;
      info['sessionData'] = html.window.localStorage[_sessionDataKey]?.length ?? 0;
      info['userPreferences'] = html.window.localStorage[_userPreferencesKey]?.length ?? 0;
      info['totalKeys'] = html.window.localStorage.keys.length;
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
}

/// Project state data model
class AppProjectState {
  final FlutterProject? currentProject;
  final String? selectedFilePath;
  final bool hasUploadedProject;
  final DateTime? lastModified;
  final WidgetSelection? selectedWidget;

  AppProjectState({
    this.currentProject,
    this.selectedFilePath,
    this.hasUploadedProject = false,
    this.lastModified,
    this.selectedWidget,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentProject': currentProject?.toJson(),
      'selectedFilePath': selectedFilePath,
      'hasUploadedProject': hasUploadedProject,
      'lastModified': lastModified?.toIso8601String(),
      'selectedWidget': selectedWidget?.toJson(),
    };
  }

  factory AppProjectState.fromJson(Map<String, dynamic> json) {
    return AppProjectState(
      currentProject: json['currentProject'] != null 
        ? FlutterProject.fromJson(json['currentProject']) 
        : null,
      selectedFilePath: json['selectedFilePath'],
      hasUploadedProject: json['hasUploadedProject'] ?? false,
      lastModified: json['lastModified'] != null 
        ? DateTime.parse(json['lastModified']) 
        : null,
      selectedWidget: json['selectedWidget'] != null 
        ? WidgetSelection.fromJson(json['selectedWidget']) 
        : null,
    );
  }

  AppProjectState copyWith({
    FlutterProject? currentProject,
    String? selectedFilePath,
    bool? hasUploadedProject,
    DateTime? lastModified,
    WidgetSelection? selectedWidget,
  }) {
    return AppProjectState(
      currentProject: currentProject ?? this.currentProject,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      hasUploadedProject: hasUploadedProject ?? this.hasUploadedProject,
      lastModified: lastModified ?? this.lastModified,
      selectedWidget: selectedWidget ?? this.selectedWidget,
    );
  }
}

/// UI preferences data model
class AppUIPreferences {
  final bool showAIPanel;
  final bool showUIPreview;
  final bool showFileTree;
  final bool? showEditor;
  final bool? showTerminal;
  final bool isFileTreeCollapsed;
  final bool isUIPreviewCollapsed;
  final bool isAIPanelCollapsed;
  final bool? isEditorCollapsed;
  final bool? isTerminalCollapsed;
  final String themeMode; // 'light', 'dark', 'system'
  final Map<String, double> panelSizes;

  AppUIPreferences({
    this.showAIPanel = true,
    this.showUIPreview = true,
    this.showFileTree = true,
    this.showEditor,
    this.showTerminal,
    this.isFileTreeCollapsed = false,
    this.isUIPreviewCollapsed = false,
    this.isAIPanelCollapsed = false,
    this.isEditorCollapsed,
    this.isTerminalCollapsed,
    this.themeMode = 'system',
    this.panelSizes = const {},
  });

  factory AppUIPreferences.defaultPreferences() {
    return AppUIPreferences(
      showEditor: true,
      showTerminal: true,
      isEditorCollapsed: false,
      isTerminalCollapsed: false,
      panelSizes: {
        'fileTree': 300.0,
        'aiPanel': 350.0,
        'terminal': 200.0,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showAIPanel': showAIPanel,
      'showUIPreview': showUIPreview,
      'showFileTree': showFileTree,
      'showEditor': showEditor,
      'showTerminal': showTerminal,
      'isFileTreeCollapsed': isFileTreeCollapsed,
      'isUIPreviewCollapsed': isUIPreviewCollapsed,
      'isAIPanelCollapsed': isAIPanelCollapsed,
      'isEditorCollapsed': isEditorCollapsed,
      'isTerminalCollapsed': isTerminalCollapsed,
      'themeMode': themeMode,
      'panelSizes': panelSizes,
    };
  }

  factory AppUIPreferences.fromJson(Map<String, dynamic> json) {
    return AppUIPreferences(
      showAIPanel: json['showAIPanel'] ?? true,
      showUIPreview: json['showUIPreview'] ?? true,
      showFileTree: json['showFileTree'] ?? true,
      showEditor: json['showEditor'],
      showTerminal: json['showTerminal'],
      isFileTreeCollapsed: json['isFileTreeCollapsed'] ?? false,
      isUIPreviewCollapsed: json['isUIPreviewCollapsed'] ?? false,
      isAIPanelCollapsed: json['isAIPanelCollapsed'] ?? false,
      isEditorCollapsed: json['isEditorCollapsed'],
      isTerminalCollapsed: json['isTerminalCollapsed'],
      themeMode: json['themeMode'] ?? 'system',
      panelSizes: Map<String, double>.from(json['panelSizes'] ?? {}),
    );
  }

  AppUIPreferences copyWith({
    bool? showAIPanel,
    bool? showUIPreview,
    bool? showFileTree,
    bool? showEditor,
    bool? showTerminal,
    bool? isFileTreeCollapsed,
    bool? isUIPreviewCollapsed,
    bool? isAIPanelCollapsed,
    bool? isEditorCollapsed,
    bool? isTerminalCollapsed,
    String? themeMode,
    Map<String, double>? panelSizes,
  }) {
    return AppUIPreferences(
      showAIPanel: showAIPanel ?? this.showAIPanel,
      showUIPreview: showUIPreview ?? this.showUIPreview,
      showFileTree: showFileTree ?? this.showFileTree,
      showEditor: showEditor ?? this.showEditor,
      showTerminal: showTerminal ?? this.showTerminal,
      isFileTreeCollapsed: isFileTreeCollapsed ?? this.isFileTreeCollapsed,
      isUIPreviewCollapsed: isUIPreviewCollapsed ?? this.isUIPreviewCollapsed,
      isAIPanelCollapsed: isAIPanelCollapsed ?? this.isAIPanelCollapsed,
      isEditorCollapsed: isEditorCollapsed ?? this.isEditorCollapsed,
      isTerminalCollapsed: isTerminalCollapsed ?? this.isTerminalCollapsed,
      themeMode: themeMode ?? this.themeMode,
      panelSizes: panelSizes ?? this.panelSizes,
    );
  }
}

/// Session data model
class AppSessionData {
  final DateTime sessionStarted;
  final List<String> recentProjects;
  final Map<String, String> editorStates; // file path -> editor state
  final List<String> searchHistory;
  final Map<String, dynamic> aiChatHistory;

  AppSessionData({
    required this.sessionStarted,
    this.recentProjects = const [],
    this.editorStates = const {},
    this.searchHistory = const [],
    this.aiChatHistory = const {},
  });

  factory AppSessionData.empty() {
    return AppSessionData(
      sessionStarted: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionStarted': sessionStarted.toIso8601String(),
      'recentProjects': recentProjects,
      'editorStates': editorStates,
      'searchHistory': searchHistory,
      'aiChatHistory': aiChatHistory,
    };
  }

  factory AppSessionData.fromJson(Map<String, dynamic> json) {
    return AppSessionData(
      sessionStarted: DateTime.parse(json['sessionStarted']),
      recentProjects: List<String>.from(json['recentProjects'] ?? []),
      editorStates: Map<String, String>.from(json['editorStates'] ?? {}),
      searchHistory: List<String>.from(json['searchHistory'] ?? []),
      aiChatHistory: Map<String, dynamic>.from(json['aiChatHistory'] ?? {}),
    );
  }

  AppSessionData copyWith({
    DateTime? sessionStarted,
    List<String>? recentProjects,
    Map<String, String>? editorStates,
    List<String>? searchHistory,
    Map<String, dynamic>? aiChatHistory,
  }) {
    return AppSessionData(
      sessionStarted: sessionStarted ?? this.sessionStarted,
      recentProjects: recentProjects ?? this.recentProjects,
      editorStates: editorStates ?? this.editorStates,
      searchHistory: searchHistory ?? this.searchHistory,
      aiChatHistory: aiChatHistory ?? this.aiChatHistory,
    );
  }
}

/// User preferences data model
class AppUserPreferences {
  final String fontFamily;
  final double fontSize;
  final bool enableAutoSave;
  final int autoSaveIntervalMs;
  final bool enableKeyboardShortcuts;
  final Map<String, String> customKeyBindings;
  final bool enableCodeCompletion;
  final bool enableLivePreview;

  AppUserPreferences({
    this.fontFamily = 'Fira Code',
    this.fontSize = 14.0,
    this.enableAutoSave = true,
    this.autoSaveIntervalMs = 2000,
    this.enableKeyboardShortcuts = true,
    this.customKeyBindings = const {},
    this.enableCodeCompletion = true,
    this.enableLivePreview = true,
  });

  factory AppUserPreferences.defaultPreferences() {
    return AppUserPreferences();
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'enableAutoSave': enableAutoSave,
      'autoSaveIntervalMs': autoSaveIntervalMs,
      'enableKeyboardShortcuts': enableKeyboardShortcuts,
      'customKeyBindings': customKeyBindings,
      'enableCodeCompletion': enableCodeCompletion,
      'enableLivePreview': enableLivePreview,
    };
  }

  factory AppUserPreferences.fromJson(Map<String, dynamic> json) {
    return AppUserPreferences(
      fontFamily: json['fontFamily'] ?? 'Fira Code',
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      enableAutoSave: json['enableAutoSave'] ?? true,
      autoSaveIntervalMs: json['autoSaveIntervalMs'] ?? 2000,
      enableKeyboardShortcuts: json['enableKeyboardShortcuts'] ?? true,
      customKeyBindings: Map<String, String>.from(json['customKeyBindings'] ?? {}),
      enableCodeCompletion: json['enableCodeCompletion'] ?? true,
      enableLivePreview: json['enableLivePreview'] ?? true,
    );
  }

  AppUserPreferences copyWith({
    String? fontFamily,
    double? fontSize,
    bool? enableAutoSave,
    int? autoSaveIntervalMs,
    bool? enableKeyboardShortcuts,
    Map<String, String>? customKeyBindings,
    bool? enableCodeCompletion,
    bool? enableLivePreview,
  }) {
    return AppUserPreferences(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      enableAutoSave: enableAutoSave ?? this.enableAutoSave,
      autoSaveIntervalMs: autoSaveIntervalMs ?? this.autoSaveIntervalMs,
      enableKeyboardShortcuts: enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
      customKeyBindings: customKeyBindings ?? this.customKeyBindings,
      enableCodeCompletion: enableCodeCompletion ?? this.enableCodeCompletion,
      enableLivePreview: enableLivePreview ?? this.enableLivePreview,
    );
  }
}