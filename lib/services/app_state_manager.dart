import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/services/state_persistence_service.dart';

/// Centralized app state manager with automatic persistence
/// Manages all app state including projects, UI preferences, and session data
class AppStateManager extends ChangeNotifier {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    _initializeState();
  }

  final StatePersistenceService _persistence = StatePersistenceService();
  
  Timer? _autoSaveTimer;
  bool _isInitialized = false;

  // Project State
  FlutterProject? _currentProject;
  ProjectFile? _selectedFile;
  bool _hasUploadedProject = false;
  bool _isLoading = false;
  WidgetSelection? _selectedWidget;

  // UI State
  bool _showAIPanel = true;
  bool _showUIPreview = true;
  bool _showFileTree = true;
  bool _showEditor = true;
  bool _showTerminal = true;
  bool _isFileTreeCollapsed = false;
  bool _isUIPreviewCollapsed = false;
  bool _isAIPanelCollapsed = false;
  bool _isEditorCollapsed = false;
  bool _isTerminalCollapsed = false;
  Map<String, double> _panelSizes = {};

  // Session State
  late AppSessionData _sessionData;
  late AppUserPreferences _userPreferences;

  // Getters for Project State
  FlutterProject? get currentProject => _currentProject;
  ProjectFile? get selectedFile => _selectedFile;
  bool get hasUploadedProject => _hasUploadedProject;
  bool get isLoading => _isLoading;
  WidgetSelection? get selectedWidget => _selectedWidget;

  // Getters for UI State
  bool get showAIPanel => _showAIPanel;
  bool get showUIPreview => _showUIPreview;
  bool get showFileTree => _showFileTree;
  bool get showEditor => _showEditor;
  bool get showTerminal => _showTerminal;
  bool get isFileTreeCollapsed => _isFileTreeCollapsed;
  bool get isUIPreviewCollapsed => _isUIPreviewCollapsed;
  bool get isAIPanelCollapsed => _isAIPanelCollapsed;
  bool get isEditorCollapsed => _isEditorCollapsed;
  bool get isTerminalCollapsed => _isTerminalCollapsed;
  Map<String, double> get panelSizes => Map.unmodifiable(_panelSizes);

  // Getters for Session/User State
  AppSessionData get sessionData => _sessionData;
  AppUserPreferences get userPreferences => _userPreferences;
  bool get isInitialized => _isInitialized;

  /// Initialize state from persistence with enhanced error recovery
  Future<void> _initializeState() async {
    try {
      print('🚀 Initializing AppStateManager...');
      
      // Enhanced error recovery - load each component separately
      await _loadUIPreferencesWithFallback();
      await _loadSessionDataWithFallback();
      await _loadUserPreferencesWithFallback();
      await _loadProjectStateWithFallback();

      _isInitialized = true;
      
      // Start auto-save timer
      _startAutoSave();
      
      print('✅ AppStateManager initialized successfully');
      notifyListeners();
    } catch (e) {
      print('🚨 Critical error initializing app state: $e');
      await _handleCriticalInitializationError(e);
    }
  }

  /// Load UI preferences with intelligent fallback
  Future<void> _loadUIPreferencesWithFallback() async {
    try {
      final uiPrefs = _persistence.loadUIPreferences();
      _showAIPanel = uiPrefs.showAIPanel;
      _showUIPreview = uiPrefs.showUIPreview;
      _showFileTree = uiPrefs.showFileTree;
      _showEditor = uiPrefs.showEditor ?? true;
      _showTerminal = uiPrefs.showTerminal ?? true;
      _isFileTreeCollapsed = uiPrefs.isFileTreeCollapsed;
      _isUIPreviewCollapsed = uiPrefs.isUIPreviewCollapsed;
      _isAIPanelCollapsed = uiPrefs.isAIPanelCollapsed;
      _isEditorCollapsed = uiPrefs.isEditorCollapsed ?? false;
      _isTerminalCollapsed = uiPrefs.isTerminalCollapsed ?? false;
      _panelSizes = Map.from(uiPrefs.panelSizes);
      print('✅ UI preferences loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load UI preferences, using defaults: $e');
      _showAIPanel = true;
      _showUIPreview = true;
      _showFileTree = true;
      _showEditor = true;
      _showTerminal = true;
      _isFileTreeCollapsed = false;
      _isUIPreviewCollapsed = false;
      _isAIPanelCollapsed = false;
      _isEditorCollapsed = false;
      _isTerminalCollapsed = false;
      _panelSizes = {};
    }
  }

  /// Load session data with intelligent fallback
  Future<void> _loadSessionDataWithFallback() async {
    try {
      _sessionData = _persistence.loadSessionData();
      print('✅ Session data loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load session data, creating new session: $e');
      _sessionData = AppSessionData.empty();
    }
  }

  /// Load user preferences with intelligent fallback
  Future<void> _loadUserPreferencesWithFallback() async {
    try {
      _userPreferences = _persistence.loadUserPreferences();
      print('✅ User preferences loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load user preferences, using defaults: $e');
      _userPreferences = AppUserPreferences.defaultPreferences();
    }
  }

  /// Load project state with intelligent fallback and validation
  Future<void> _loadProjectStateWithFallback() async {
    try {
      final projectState = _persistence.loadProjectState();
      if (projectState != null) {
        // Validate project integrity
        if (_validateProjectState(projectState)) {
          _currentProject = projectState.currentProject;
          _hasUploadedProject = projectState.hasUploadedProject;
          _selectedWidget = projectState.selectedWidget;
          
          // Restore selected file with validation
          if (projectState.selectedFilePath != null && _currentProject != null) {
            final restoredFile = _currentProject!.findFileByPath(projectState.selectedFilePath!);
            if (restoredFile != null) {
              _selectedFile = restoredFile;
              print('✅ Project file restored: ${restoredFile.path}');
            } else {
              print('⚠️ Selected file path not found, defaulting to main.dart');
              _selectedFile = _currentProject!.findFileByPath('lib/main.dart') ?? _currentProject!.files.firstOrNull;
            }
          }
          print('✅ Project state loaded and validated successfully');
        } else {
          print('⚠️ Project state validation failed, clearing corrupted data');
          await _persistence.clearProjectData();
        }
      } else {
        print('ℹ️ No previous project state found');
      }
    } catch (e) {
      print('🚨 Failed to load project state: $e');
      await _persistence.clearProjectData();
      _currentProject = null;
      _selectedFile = null;
      _hasUploadedProject = false;
      _selectedWidget = null;
    }
  }

  /// Validate project state integrity
  bool _validateProjectState(AppProjectState projectState) {
    try {
      if (projectState.currentProject == null) return true; // No project is valid
      
      final project = projectState.currentProject!;
      
      // Basic validation checks
      if (project.name.isEmpty) return false;
      if (project.files.isEmpty) return false;
      
      // Validate file structure
      final hasDartFiles = project.files.any((f) => f.path.endsWith('.dart'));
      final hasPubspec = project.files.any((f) => f.path.endsWith('pubspec.yaml'));
      
      if (!hasDartFiles || !hasPubspec) {
        print('⚠️ Project validation: Missing essential files');
        return false;
      }
      
      // Check for file corruption
      for (final file in project.files.take(5)) { // Check first 5 files
        if (file.path.isEmpty || (file.isTextFile && file.content.contains('\x00'))) {
          print('⚠️ Project validation: Corrupted file detected - ${file.path}');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('🚨 Project validation error: $e');
      return false;
    }
  }

  /// Handle critical initialization errors with recovery
  Future<void> _handleCriticalInitializationError(dynamic error) async {
    print('🆘 Attempting recovery from critical initialization error...');
    
    try {
      // Clear all potentially corrupted data
      await _persistence.clearAllPersistedData();
      
      // Reset to factory defaults
      _showAIPanel = true;
      _showUIPreview = true;
      _showFileTree = true;
      _showEditor = true;
      _showTerminal = true;
      _isFileTreeCollapsed = false;
      _isUIPreviewCollapsed = false;
      _isAIPanelCollapsed = false;
      _isEditorCollapsed = false;
      _isTerminalCollapsed = false;
      _panelSizes = {};
      
      _sessionData = AppSessionData.empty();
      _userPreferences = AppUserPreferences.defaultPreferences();
      
      _currentProject = null;
      _selectedFile = null;
      _hasUploadedProject = false;
      _selectedWidget = null;
      
      _isInitialized = true;
      _startAutoSave();
      
      print('✅ Recovery successful - using factory defaults');
      notifyListeners();
    } catch (e) {
      print('💀 Recovery failed: $e');
      // Last resort - minimal functional state
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(milliseconds: _userPreferences.autoSaveIntervalMs),
      (_) => _saveAllState(),
    );
  }

  /// Save all state to persistence
  Future<void> _saveAllState() async {
    if (!_isInitialized) return;

    try {
      // Save project state
      final projectState = AppProjectState(
        currentProject: _currentProject,
        selectedFilePath: _selectedFile?.path,
        hasUploadedProject: _hasUploadedProject,
        lastModified: DateTime.now(),
        selectedWidget: _selectedWidget,
      );
      await _persistence.saveProjectState(projectState);

      // Save UI preferences
      final uiPrefs = AppUIPreferences(
        showAIPanel: _showAIPanel,
        showUIPreview: _showUIPreview,
        showFileTree: _showFileTree,
        showEditor: _showEditor,
        showTerminal: _showTerminal,
        isFileTreeCollapsed: _isFileTreeCollapsed,
        isUIPreviewCollapsed: _isUIPreviewCollapsed,
        isAIPanelCollapsed: _isAIPanelCollapsed,
        isEditorCollapsed: _isEditorCollapsed,
        isTerminalCollapsed: _isTerminalCollapsed,
        panelSizes: _panelSizes,
      );
      await _persistence.saveUIPreferences(uiPrefs);

      // Save session data
      await _persistence.saveSessionData(_sessionData);

      // Save user preferences  
      await _persistence.saveUserPreferences(_userPreferences);
    } catch (e) {
      print('Error saving app state: $e');
    }
  }

  // Project State Methods

  Future<void> setCurrentProject(FlutterProject? project) async {
    _currentProject = project;
    _hasUploadedProject = project != null;
    
    // Auto-select main.dart if available
    if (project != null) {
      _selectedFile = project.findFileByPath('lib/main.dart') ?? project.files.firstOrNull;
    } else {
      _selectedFile = null;
    }
    
    _selectedWidget = null;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> setSelectedFile(ProjectFile? file) async {
    _selectedFile = file;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> setSelectedWidget(WidgetSelection? widget) async {
    _selectedWidget = widget;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> updateFileContent(String filePath, String newContent) async {
    if (_currentProject == null) return;

    _currentProject = _currentProject!.updateFile(filePath, newContent);
    _selectedFile = _currentProject!.findFileByPath(filePath);
    
    // Add to session editor states
    _sessionData = _sessionData.copyWith(
      editorStates: {
        ..._sessionData.editorStates,
        filePath: newContent,
      },
    );
    
    notifyListeners();
    await _saveAllState();
  }

  // UI State Methods

  Future<void> toggleAIPanel() async {
    _showAIPanel = !_showAIPanel;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleUIPreview() async {
    _showUIPreview = !_showUIPreview;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleFileTree() async {
    _showFileTree = !_showFileTree;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleFileTreeCollapsed() async {
    _isFileTreeCollapsed = !_isFileTreeCollapsed;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleUIPreviewCollapsed() async {
    _isUIPreviewCollapsed = !_isUIPreviewCollapsed;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleAIPanelCollapsed() async {
    _isAIPanelCollapsed = !_isAIPanelCollapsed;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleEditor() async {
    _showEditor = !_showEditor;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleEditorCollapsed() async {
    _isEditorCollapsed = !_isEditorCollapsed;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleAllPanelsCollapsed() async {
    final shouldCollapse = !(_isFileTreeCollapsed && _isUIPreviewCollapsed && _isAIPanelCollapsed && _isEditorCollapsed && _isTerminalCollapsed);
    _isFileTreeCollapsed = shouldCollapse;
    _isUIPreviewCollapsed = shouldCollapse;
    _isAIPanelCollapsed = shouldCollapse;
    _isEditorCollapsed = shouldCollapse;
    _isTerminalCollapsed = shouldCollapse;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleTerminal() async {
    _showTerminal = !_showTerminal;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> toggleTerminalCollapsed() async {
    _isTerminalCollapsed = !_isTerminalCollapsed;
    notifyListeners();
    await _saveAllState();
  }

  Future<void> setPanelSize(String panelName, double size) async {
    _panelSizes[panelName] = size;
    notifyListeners();
    await _saveAllState();
  }

  // Session Methods

  Future<void> addToSearchHistory(String query) async {
    final history = [..._sessionData.searchHistory];
    history.remove(query); // Remove if already exists
    history.insert(0, query); // Add to front
    
    // Keep only last 20 searches
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    _sessionData = _sessionData.copyWith(searchHistory: history);
    await _saveAllState();
  }

  Future<void> addRecentProject(String projectName) async {
    final recent = [..._sessionData.recentProjects];
    recent.remove(projectName); // Remove if already exists
    recent.insert(0, projectName); // Add to front
    
    // Keep only last 10 projects
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }
    
    _sessionData = _sessionData.copyWith(recentProjects: recent);
    await _saveAllState();
  }

  // Utility Methods

  Future<void> resetToDefaults() async {
    _showAIPanel = true;
    _showUIPreview = true;
    _showFileTree = true;
    _isFileTreeCollapsed = false;
    _isUIPreviewCollapsed = false;
    _isAIPanelCollapsed = false;
    _panelSizes = {};
    
    _userPreferences = AppUserPreferences.defaultPreferences();
    _startAutoSave(); // Restart with new interval
    
    notifyListeners();
    await _saveAllState();
  }

  Future<void> clearAllData() async {
    await _persistence.clearAllPersistedData();
    
    _currentProject = null;
    _selectedFile = null;
    _hasUploadedProject = false;
    _selectedWidget = null;
    
    await resetToDefaults();
  }

  Future<void> clearProjectOnly() async {
    await _persistence.clearProjectData();
    
    _currentProject = null;
    _selectedFile = null;
    _hasUploadedProject = false;
    _selectedWidget = null;
    
    notifyListeners();
  }

  /// Force immediate save (useful before navigation/close)
  Future<void> forceSave() async {
    await _saveAllState();
  }

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasProject': _currentProject != null,
      'selectedFile': _selectedFile?.fileName,
      'panelStates': {
        'showAIPanel': _showAIPanel,
        'showUIPreview': _showUIPreview,
        'showFileTree': _showFileTree,
        'collapsed': {
          'fileTree': _isFileTreeCollapsed,
          'uiPreview': _isUIPreviewCollapsed,
          'aiPanel': _isAIPanelCollapsed,
        },
      },
      'storageInfo': _persistence.getStorageInfo(),
      'sessionStart': _sessionData.sessionStarted.toIso8601String(),
      'autoSaveInterval': _userPreferences.autoSaveIntervalMs,
    };
  }

  /// 🗑️ **CLEAR TEMPORARY DATA FOR MEMORY CLEANUP**
  Future<void> clearTemporaryData() async {
    try {
      // Clear temporary session data  
      _sessionData = _sessionData.copyWith(
        editorStates: <String, String>{},
        searchHistory: _sessionData.searchHistory.take(5).toList(), // Keep only recent 5
      );
      
      // Save cleaned session data
      await _persistence.saveSessionData(_sessionData);
      
      print('✅ Temporary data cleared successfully');
    } catch (e) {
      print('⚠️ Failed to clear temporary data: $e');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}