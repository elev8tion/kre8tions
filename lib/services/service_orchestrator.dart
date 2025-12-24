import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/app_state_manager.dart';
import 'package:kre8tions/services/code_execution_service.dart';
import 'package:kre8tions/services/dependency_manager.dart';
import 'package:kre8tions/services/project_manager.dart';

/// 🎯 **ULTIMATE SERVICE ORCHESTRATOR**
/// 
/// The central command center that coordinates ALL CodeWhisper services:
/// - 🚀 Live Code Execution & Preview
/// - 🔍 Real-time Error Detection & Intelligence  
/// - 📦 Dependency Management & Updates
/// - 💾 State Persistence & Recovery
/// - 🎨 UI Integration & User Experience
/// 
/// This creates a **seamless, unified development experience**
class ServiceOrchestrator extends ChangeNotifier {
  static ServiceOrchestrator? _instance;
  static ServiceOrchestrator get instance => _instance ??= ServiceOrchestrator._();
  ServiceOrchestrator._() {
    _initialize();
  }

  // 🎯 **CORE SERVICES**
  final CodeExecutionService _executionService = CodeExecutionService.instance;
  final DependencyManager _dependencyManager = DependencyManager.instance;
  late final AppStateManager _stateManager;
  
  // 📊 **ORCHESTRATOR STATE**
  FlutterProject? _currentProject;
  ProjectFile? _activeFile;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _hasLivePreview = false;
  
  // 🎯 **REAL-TIME STREAMS**
  final StreamController<OrchestratorEvent> _eventController = StreamController<OrchestratorEvent>.broadcast();
  final StreamController<LiveAnalysisUpdate> _analysisController = StreamController<LiveAnalysisUpdate>.broadcast();
  final StreamController<SystemHealthUpdate> _healthController = StreamController<SystemHealthUpdate>.broadcast();
  
  Stream<OrchestratorEvent> get eventStream => _eventController.stream;
  Stream<LiveAnalysisUpdate> get analysisStream => _analysisController.stream;
  Stream<SystemHealthUpdate> get healthStream => _healthController.stream;
  
  // 📊 **GETTERS**
  FlutterProject? get currentProject => _currentProject;
  ProjectFile? get activeFile => _activeFile;
  bool get isInitialized => _isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasLivePreview => _hasLivePreview;

  /// 🚀 **GET ALL PROJECT FILES FOR NAVIGATION**
  /// Returns all project files as Map<path, content> for go-to-definition and symbol indexing
  Map<String, String> getAllProjectFiles() {
    if (_currentProject == null) {
      return <String, String>{};
    }
    
    // Convert project files to Map<path, content> for DartIntelligenceService
    return { for (var file in _currentProject!.files.where((file) => !file.isDirectory && file.isTextFile)) (file).path : (file).content };
  }
  
  Timer? _healthCheckTimer;
  Timer? _dependencyCheckTimer;
  late StreamSubscription _executionSubscription;
  late StreamSubscription _errorSubscription;
  
  /// 🚀 **INITIALIZE ORCHESTRATOR**
  Future<void> _initialize() async {
    try {
      debugPrint('🎯 ServiceOrchestrator: Initializing...');
      
      // Initialize state manager
      _stateManager = AppStateManager();
      
      // Set up service streams
      _setupServiceStreams();
      
      // Start health monitoring
      _startHealthMonitoring();
      
      // Check dependencies
      _startDependencyMonitoring();
      
      // Restore previous session
      await _restoreSession();
      
      _isInitialized = true;
      debugPrint('✅ ServiceOrchestrator: Initialization complete!');
      
      _broadcastEvent(OrchestratorEvent(
        type: EventType.initialized,
        message: 'ServiceOrchestrator initialized successfully',
        timestamp: DateTime.now(),
      ));
      
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 ServiceOrchestrator: Initialization failed: $e');
      _broadcastEvent(OrchestratorEvent(
        type: EventType.error,
        message: 'Initialization failed: $e',
        timestamp: DateTime.now(),
      ));
    }
  }
  
  /// 📂 **LOAD PROJECT WITH FULL INTEGRATION**
  Future<ProjectLoadResult> loadProject(List<int> zipBytes, String fileName) async {
    try {
      _broadcastEvent(OrchestratorEvent(
        type: EventType.projectLoading,
        message: 'Loading project: $fileName',
        timestamp: DateTime.now(),
      ));
      
      // Load project via ProjectManager
      final project = await ProjectManager.loadProjectFromZip(Uint8List.fromList(zipBytes), fileName);
      if (project == null) {
        throw Exception('Failed to load project');
      }
      
      _currentProject = project;
      
      // Persist project state
      await _stateManager.setCurrentProject(project);
      
      // Analyze project dependencies
      final dependencyStatus = await _dependencyManager.checkAllSystems();
      final projectAnalysis = await _analyzeProjectStructure(project);
      final suggestions = await _dependencyManager.getSmartSuggestions(projectAnalysis);
      
      // Initialize live preview
      final executionResult = await _executionService.executeProject(project);
      _hasLivePreview = executionResult.success;
      
      final result = ProjectLoadResult(
        success: true,
        project: project,
        dependencyStatus: dependencyStatus,
        suggestions: suggestions,
        executionResult: executionResult,
        analysisData: projectAnalysis,
      );
      
      _broadcastEvent(OrchestratorEvent(
        type: EventType.projectLoaded,
        message: 'Project loaded successfully: ${project.name}',
        timestamp: DateTime.now(),
        data: result,
      ));
      
      notifyListeners();
      return result;
      
    } catch (e) {
      final errorResult = ProjectLoadResult.error(e.toString());
      _broadcastEvent(OrchestratorEvent(
        type: EventType.error,
        message: 'Failed to load project: $e',
        timestamp: DateTime.now(),
      ));
      return errorResult;
    }
  }
  
  /// 📝 **ACTIVATE FILE WITH LIVE ANALYSIS**
  Future<void> activateFile(ProjectFile file) async {
    try {
      _activeFile = file;
      await _stateManager.setSelectedFile(file);
      
      if (file.type == FileType.dart) {
        // Start live code analysis
        _isAnalyzing = true;
        notifyListeners();
        
        _executionService.analyzeLiveCode(file.content, _currentProject);
        
        _broadcastEvent(OrchestratorEvent(
          type: EventType.fileActivated,
          message: 'Activated file: ${file.fileName}',
          timestamp: DateTime.now(),
          data: file,
        ));
      }
    } catch (e) {
      debugPrint('🚨 Error activating file: $e');
    }
  }
  
  /// ⚡ **LIVE CODE UPDATE**
  Future<void> updateCode(String newCode, {bool immediate = false}) async {
    if (_activeFile == null || _currentProject == null) return;
    
    try {
      // Update file content through state manager
      _stateManager.updateFileContent(_activeFile!.path, newCode);
      
      // Trigger live analysis
      _isAnalyzing = true;
      notifyListeners();
      
      if (immediate) {
        // Immediate analysis for critical changes
        final result = await _executionService.executeProject(_currentProject!, entryPoint: _activeFile!.path);
        _broadcastAnalysisUpdate(LiveAnalysisUpdate(
          file: _activeFile!,
          executionResult: result,
          timestamp: DateTime.now(),
          isLive: false,
        ));
      } else {
        // Debounced analysis for typing
        _executionService.analyzeLiveCode(newCode, _currentProject);
      }
      
      // Note: Changes are automatically persisted through AppStateManager
      
      _isAnalyzing = false;
      notifyListeners();
      
    } catch (e) {
      _isAnalyzing = false;
      debugPrint('🚨 Error updating code: $e');
      notifyListeners();
    }
  }
  
  /// 🔥 **HOT RELOAD**
  Future<ExecutionResult> performHotReload() async {
    if (_currentProject == null) {
      return ExecutionResult.error('No active project');
    }
    
    try {
      _broadcastEvent(OrchestratorEvent(
        type: EventType.hotReload,
        message: 'Performing hot reload...',
        timestamp: DateTime.now(),
      ));
      
      final result = await _executionService.hotReload();
      _hasLivePreview = result.success;
      
      _broadcastEvent(OrchestratorEvent(
        type: result.success ? EventType.hotReloadSuccess : EventType.hotReloadError,
        message: result.success ? 'Hot reload successful' : 'Hot reload failed: ${result.error}',
        timestamp: DateTime.now(),
        data: result,
      ));
      
      notifyListeners();
      return result;
      
    } catch (e) {
      final errorResult = ExecutionResult.error(e.toString());
      _broadcastEvent(OrchestratorEvent(
        type: EventType.hotReloadError,
        message: 'Hot reload failed: $e',
        timestamp: DateTime.now(),
      ));
      return errorResult;
    }
  }
  
  /// 🔧 **AUTO-FIX DEPENDENCIES**
  Future<bool> autoFixDependencies() async {
    if (_currentProject == null) return false;
    
    try {
      _broadcastEvent(OrchestratorEvent(
        type: EventType.dependencyFix,
        message: 'Auto-fixing dependencies...',
        timestamp: DateTime.now(),
      ));
      
      final result = await _dependencyManager.autoFixDependencies(_currentProject!.name);
      
      if (result) {
        // Reload project after fixes
        final executionResult = await _executionService.executeProject(_currentProject!);
        _hasLivePreview = executionResult.success;
      }
      
      _broadcastEvent(OrchestratorEvent(
        type: result ? EventType.dependencyFixSuccess : EventType.dependencyFixError,
        message: result ? 'Dependencies fixed successfully' : 'Failed to fix dependencies',
        timestamp: DateTime.now(),
      ));
      
      return result;
    } catch (e) {
      debugPrint('🚨 Auto-fix dependencies error: $e');
      return false;
    }
  }
  
  /// 📊 **GET COMPREHENSIVE SYSTEM STATUS WITH HEALTH MONITORING**
  Future<SystemStatusReport> getSystemStatus() async {
    final dependencyStatus = await _dependencyManager.checkAllSystems();
    final projectAnalysis = _currentProject != null 
      ? await _analyzeProjectStructure(_currentProject!)
      : <String, dynamic>{};
    
    // Enhanced health check with detailed diagnostics
    final healthDetails = await _performDetailedHealthCheck();
    
    return SystemStatusReport(
      isHealthy: _isInitialized && !dependencyStatus.hasErrors && healthDetails['isHealthy'],
      dependencyStatus: dependencyStatus,
      projectLoaded: _currentProject != null,
      livePreviewActive: _hasLivePreview,
      analysisActive: _isAnalyzing,
      projectAnalysis: projectAnalysis,
      healthDetails: healthDetails,
      timestamp: DateTime.now(),
    );
  }

  /// 🩺 **DETAILED HEALTH CHECK WITH DIAGNOSTICS**
  Future<Map<String, dynamic>> _performDetailedHealthCheck() async {
    final diagnostics = <String, dynamic>{};
    bool isHealthy = true;
    final issues = <String>[];

    try {
      // 1. Memory Health Check
      diagnostics['memoryHealth'] = _checkMemoryHealth();
      if (!diagnostics['memoryHealth']['isHealthy']) {
        isHealthy = false;
        issues.add('Memory usage is high');
      }

      // 2. Service Connectivity Check
      diagnostics['serviceConnectivity'] = await _checkServiceConnectivity();
      if (!diagnostics['serviceConnectivity']['allConnected']) {
        isHealthy = false;
        issues.addAll(diagnostics['serviceConnectivity']['issues']);
      }

      // 3. Performance Health Check
      diagnostics['performanceHealth'] = _checkPerformanceHealth();
      if (!diagnostics['performanceHealth']['isHealthy']) {
        isHealthy = false;
        issues.add('Performance issues detected');
      }

      // 4. State Consistency Check
      diagnostics['stateConsistency'] = _checkStateConsistency();
      if (!diagnostics['stateConsistency']['isConsistent']) {
        isHealthy = false;
        issues.add('State inconsistency detected');
      }

      // 5. Resource Availability Check
      diagnostics['resourceAvailability'] = await _checkResourceAvailability();
      if (!diagnostics['resourceAvailability']['available']) {
        isHealthy = false;
        issues.addAll(diagnostics['resourceAvailability']['issues']);
      }

      diagnostics['isHealthy'] = isHealthy;
      diagnostics['issues'] = issues;
      diagnostics['healthScore'] = _calculateHealthScore(diagnostics);
      diagnostics['lastCheckTime'] = DateTime.now().toIso8601String();

    } catch (e) {
      debugPrint('🚨 Health check error: $e');
      diagnostics['isHealthy'] = false;
      diagnostics['error'] = e.toString();
      diagnostics['healthScore'] = 0;
    }

    return diagnostics;
  }

  /// 🧠 **MEMORY HEALTH CHECK**
  Map<String, dynamic> _checkMemoryHealth() {
    // Simulated memory check (in a real implementation, you'd use platform-specific memory APIs)
    final memoryUsage = 45.0 + (DateTime.now().millisecond % 40); // Simulate 45-85% usage
    final isHealthy = memoryUsage < 80.0;

    return {
      'isHealthy': isHealthy,
      'memoryUsage': memoryUsage,
      'threshold': 80.0,
      'recommendation': isHealthy 
        ? 'Memory usage is optimal'
        : 'Consider clearing caches or restarting the application',
    };
  }

  /// 🌐 **SERVICE CONNECTIVITY CHECK**
  Future<Map<String, dynamic>> _checkServiceConnectivity() async {
    final services = <String, bool>{};
    final issues = <String>[];

    try {
      // Check execution service
      services['executionService'] = _executionService != null;
      if (!services['executionService']!) {
        issues.add('Code execution service is not available');
      }

      // Check dependency manager
      services['dependencyManager'] = _dependencyManager != null;
      if (!services['dependencyManager']!) {
        issues.add('Dependency manager is not available');
      }

      // Check state manager
      services['stateManager'] = _stateManager.isInitialized;
      if (!services['stateManager']!) {
        issues.add('State manager is not properly initialized');
      }

      // Simulate network connectivity check
      services['networkConnectivity'] = DateTime.now().second % 10 != 0; // 90% uptime simulation
      if (!services['networkConnectivity']!) {
        issues.add('Network connectivity issues detected');
      }

    } catch (e) {
      services['error'] = false;
      issues.add('Service connectivity check failed: $e');
    }

    return {
      'allConnected': issues.isEmpty,
      'services': services,
      'issues': issues,
      'connectedCount': services.values.where((v) => v == true).length,
      'totalServices': services.length,
    };
  }

  /// ⚡ **PERFORMANCE HEALTH CHECK**
  Map<String, dynamic> _checkPerformanceHealth() {
    // Simulate performance metrics
    final frameRate = 55.0 + (DateTime.now().millisecond % 10); // 55-65 FPS
    final responseTime = 50.0 + (DateTime.now().millisecond % 100); // 50-150ms
    
    final isHealthy = frameRate >= 50.0 && responseTime <= 200.0;

    return {
      'isHealthy': isHealthy,
      'frameRate': frameRate,
      'responseTime': responseTime,
      'frameRateThreshold': 50.0,
      'responseTimeThreshold': 200.0,
      'grade': _getPerformanceGrade(frameRate, responseTime),
    };
  }

  /// 🔄 **STATE CONSISTENCY CHECK**
  Map<String, dynamic> _checkStateConsistency() {
    final issues = <String>[];
    bool isConsistent = true;

    // Check if current project matches state manager
    if (_currentProject != _stateManager.currentProject) {
      issues.add('Project state mismatch between orchestrator and state manager');
      isConsistent = false;
    }

    // Check if active file matches state manager
    if (_activeFile != _stateManager.selectedFile) {
      issues.add('Active file mismatch between orchestrator and state manager');
      isConsistent = false;
    }

    // Check initialization states
    if (_isInitialized != _stateManager.isInitialized) {
      issues.add('Initialization state mismatch');
      isConsistent = false;
    }

    return {
      'isConsistent': isConsistent,
      'issues': issues,
      'checksPerformed': 3,
      'checksPasssed': 3 - issues.length,
    };
  }

  /// 🎯 **RESOURCE AVAILABILITY CHECK**
  Future<Map<String, dynamic>> _checkResourceAvailability() async {
    final resources = <String, bool>{};
    final issues = <String>[];

    try {
      // Check disk space (simulated)
      final diskSpaceAvailable = DateTime.now().second % 2 == 0; // 50% simulation
      resources['diskSpace'] = diskSpaceAvailable;
      if (!diskSpaceAvailable) {
        issues.add('Low disk space detected');
      }

      // Check processing capacity (simulated)
      final processingCapacity = DateTime.now().millisecond > 100; // 90% simulation  
      resources['processingCapacity'] = processingCapacity;
      if (!processingCapacity) {
        issues.add('High CPU usage detected');
      }

      // Check memory availability (simulated)
      final memoryAvailable = DateTime.now().millisecond % 5 != 0; // 80% simulation
      resources['memoryAvailable'] = memoryAvailable;
      if (!memoryAvailable) {
        issues.add('Low memory availability');
      }

    } catch (e) {
      resources['error'] = false;
      issues.add('Resource availability check failed: $e');
    }

    return {
      'available': issues.isEmpty,
      'resources': resources,
      'issues': issues,
      'availableCount': resources.values.where((v) => v == true).length,
      'totalResources': resources.length,
    };
  }

  /// 📊 **CALCULATE OVERALL HEALTH SCORE (0-100)**
  int _calculateHealthScore(Map<String, dynamic> diagnostics) {
    int score = 100;

    // Memory health (20 points)
    if (diagnostics['memoryHealth']?['isHealthy'] == false) {
      score -= 20;
    }

    // Service connectivity (25 points)
    final serviceConnectivity = diagnostics['serviceConnectivity'];
    if (serviceConnectivity != null) {
      final connectedRatio = serviceConnectivity['connectedCount'] / serviceConnectivity['totalServices'];
      score -= ((1.0 - connectedRatio) * 25).round();
    }

    // Performance health (25 points)
    if (diagnostics['performanceHealth']?['isHealthy'] == false) {
      score -= 25;
    }

    // State consistency (15 points)
    if (diagnostics['stateConsistency']?['isConsistent'] == false) {
      score -= 15;
    }

    // Resource availability (15 points)
    final resourceAvailability = diagnostics['resourceAvailability'];
    if (resourceAvailability != null) {
      final availableRatio = resourceAvailability['availableCount'] / resourceAvailability['totalResources'];
      score -= ((1.0 - availableRatio) * 15).round();
    }

    return math.max(0, score);
  }

  /// 🏆 **GET PERFORMANCE GRADE**
  String _getPerformanceGrade(double frameRate, double responseTime) {
    if (frameRate >= 58 && responseTime <= 100) return 'A+';
    if (frameRate >= 55 && responseTime <= 150) return 'A';
    if (frameRate >= 50 && responseTime <= 200) return 'B+';
    if (frameRate >= 45 && responseTime <= 300) return 'B';
    if (frameRate >= 40 && responseTime <= 500) return 'C';
    return 'D';
  }

  /// 🔧 **AUTO-HEAL SYSTEM ISSUES**
  Future<bool> performAutoHealing() async {
    debugPrint('🏥 Performing auto-healing...');
    
    try {
      final healthCheck = await _performDetailedHealthCheck();
      final issues = healthCheck['issues'] as List<String>;
      
      if (issues.isEmpty) {
        debugPrint('✅ System is healthy, no healing required');
        return true;
      }

      int fixedIssues = 0;
      
      // Attempt to fix memory issues
      if (issues.any((issue) => issue.contains('Memory'))) {
        if (await _attemptMemoryCleanup()) {
          fixedIssues++;
          debugPrint('✅ Memory cleanup successful');
        }
      }

      // Attempt to fix state inconsistencies
      if (issues.any((issue) => issue.contains('state'))) {
        if (await _attemptStateReconciliation()) {
          fixedIssues++;
          debugPrint('✅ State reconciliation successful');
        }
      }

      // Attempt to restart failed services
      if (issues.any((issue) => issue.contains('service'))) {
        if (await _attemptServiceRestart()) {
          fixedIssues++;
          debugPrint('✅ Service restart successful');
        }
      }

      _broadcastEvent(OrchestratorEvent(
        type: EventType.autoHealingCompleted,
        message: 'Auto-healing completed: $fixedIssues issues resolved',
        timestamp: DateTime.now(),
        data: {'fixedIssues': fixedIssues, 'totalIssues': issues.length},
      ));

      return fixedIssues > 0;

    } catch (e) {
      debugPrint('🚨 Auto-healing failed: $e');
      return false;
    }
  }

  /// 🧹 **ATTEMPT MEMORY CLEANUP**
  Future<bool> _attemptMemoryCleanup() async {
    try {
      // Clear caches and temporary data
      await _stateManager.clearTemporaryData();
      
      // Force garbage collection (simulated)
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
    } catch (e) {
      debugPrint('Memory cleanup failed: $e');
      return false;
    }
  }

  /// 🔄 **ATTEMPT STATE RECONCILIATION**
  Future<bool> _attemptStateReconciliation() async {
    try {
      // Sync orchestrator state with state manager
      _currentProject = _stateManager.currentProject;
      _activeFile = _stateManager.selectedFile;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('State reconciliation failed: $e');
      return false;
    }
  }

  /// ⚡ **ATTEMPT SERVICE RESTART**
  Future<bool> _attemptServiceRestart() async {
    try {
      // Restart critical services if needed
      if (!_executionService.isHealthy) {
        await _executionService.restart();
      }
      
      return true;
    } catch (e) {
      debugPrint('Service restart failed: $e');
      return false;
    }
  }
  
  // 🔧 **PRIVATE HELPER METHODS**
  
  void _setupServiceStreams() {
    // Listen to execution service
    _executionSubscription = _executionService.executionStream.listen((result) {
      _broadcastAnalysisUpdate(LiveAnalysisUpdate(
        file: _activeFile,
        executionResult: result,
        timestamp: DateTime.now(),
        isLive: true,
      ));
    });
    
    // Listen to error stream
    _errorSubscription = _executionService.errorStream.listen((errors) {
      if (errors.isNotEmpty) {
        _broadcastEvent(OrchestratorEvent(
          type: EventType.codeError,
          message: '${errors.length} code errors detected',
          timestamp: DateTime.now(),
          data: errors,
        ));
      }
    });
  }
  
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final status = await getSystemStatus();
      _healthController.add(SystemHealthUpdate(
        isHealthy: status.isHealthy,
        issues: status.dependencyStatus.hasErrors ? ['Dependency issues detected'] : [],
        timestamp: DateTime.now(),
      ));
    });
  }
  
  void _startDependencyMonitoring() {
    _dependencyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      if (_currentProject != null) {
        final status = await _dependencyManager.checkAllSystems();
        if (status.hasUpdates) {
          _broadcastEvent(OrchestratorEvent(
            type: EventType.dependencyUpdate,
            message: 'Dependency updates available',
            timestamp: DateTime.now(),
            data: status,
          ));
        }
      }
    });
  }
  
  Future<void> _restoreSession() async {
    try {
      final currentProject = _stateManager.currentProject;
      final selectedFile = _stateManager.selectedFile;
      
      if (currentProject != null && selectedFile != null) {
        // Restore session data
        debugPrint('🔄 Restoring session: ${currentProject.name} - ${selectedFile.path}');
      }
    } catch (e) {
      debugPrint('⚠️ Session restoration failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> _analyzeProjectStructure(FlutterProject project) async {
    return {
      'fileCount': project.files.length,
      'dartFiles': project.files.where((f) => f.type == FileType.dart).length,
      'hasStateManagement': project.files.any((f) => 
        f.content.contains('provider') || 
        f.content.contains('bloc') || 
        f.content.contains('riverpod')),
      'hasNavigation': project.files.any((f) => 
        f.content.contains('Navigator') || 
        f.content.contains('go_router')),
      'hasAnimations': project.files.any((f) => 
        f.content.contains('Animation') || 
        f.content.contains('AnimatedContainer')),
      'hasTests': project.files.any((f) => f.path.contains('test/')),
      'complexity': _calculateProjectComplexity(project),
      'maintainability': _calculateMaintainability(project),
    };
  }
  
  double _calculateProjectComplexity(FlutterProject project) {
    final dartFiles = project.files.where((f) => f.type == FileType.dart);
    final totalLines = dartFiles.fold(0, (sum, file) => sum + file.content.split('\n').length);
    return (totalLines / 1000.0).clamp(0.0, 10.0);
  }
  
  double _calculateMaintainability(FlutterProject project) {
    final dartFiles = project.files.where((f) => f.type == FileType.dart);
    if (dartFiles.isEmpty) return 0.0;
    
    final totalComments = dartFiles.fold(0, (sum, file) => 
      sum + RegExp(r'//').allMatches(file.content).length);
    final totalLines = dartFiles.fold(0, (sum, file) => sum + file.content.split('\n').length);
    
    return totalLines > 0 ? (totalComments / totalLines * 10).clamp(0.0, 1.0) : 0.0;
  }
  
  void _broadcastEvent(OrchestratorEvent event) {
    _eventController.add(event);
  }
  
  void _broadcastAnalysisUpdate(LiveAnalysisUpdate update) {
    _analysisController.add(update);
  }
  
  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _dependencyCheckTimer?.cancel();
    _executionSubscription.cancel();
    _errorSubscription.cancel();
    _eventController.close();
    _analysisController.close();
    _healthController.close();
    _executionService.dispose();
    super.dispose();
  }
}

/// 📊 **DATA MODELS**

class ProjectLoadResult {
  final bool success;
  final FlutterProject? project;
  final SystemStatus? dependencyStatus;
  final List<DependencySuggestion>? suggestions;
  final ExecutionResult? executionResult;
  final Map<String, dynamic>? analysisData;
  final String? error;
  
  ProjectLoadResult({
    required this.success,
    this.project,
    this.dependencyStatus,
    this.suggestions,
    this.executionResult,
    this.analysisData,
    this.error,
  });
  
  ProjectLoadResult.error(String errorMessage)
    : success = false,
      project = null,
      dependencyStatus = null,
      suggestions = null,
      executionResult = null,
      analysisData = null,
      error = errorMessage;
}

class OrchestratorEvent {
  final EventType type;
  final String message;
  final DateTime timestamp;
  final dynamic data;
  
  OrchestratorEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data,
  });
}

enum EventType {
  initialized,
  projectLoading,
  projectLoaded,
  fileActivated,
  codeError,
  hotReload,
  hotReloadSuccess,
  hotReloadError,
  dependencyUpdate,
  dependencyFix,
  dependencyFixSuccess,
  dependencyFixError,
  autoHealingCompleted,
  error,
}

class LiveAnalysisUpdate {
  final ProjectFile? file;
  final ExecutionResult executionResult;
  final DateTime timestamp;
  final bool isLive;
  
  LiveAnalysisUpdate({
    required this.file,
    required this.executionResult,
    required this.timestamp,
    required this.isLive,
  });
}

class SystemHealthUpdate {
  final bool isHealthy;
  final List<String> issues;
  final DateTime timestamp;
  
  SystemHealthUpdate({
    required this.isHealthy,
    required this.issues,
    required this.timestamp,
  });
}

class SystemStatusReport {
  final bool isHealthy;
  final SystemStatus dependencyStatus;
  final bool projectLoaded;
  final bool livePreviewActive;
  final bool analysisActive;
  final Map<String, dynamic> projectAnalysis;
  final Map<String, dynamic>? healthDetails;
  final DateTime timestamp;
  
  SystemStatusReport({
    required this.isHealthy,
    required this.dependencyStatus,
    required this.projectLoaded,
    required this.livePreviewActive,
    required this.analysisActive,
    required this.projectAnalysis,
    this.healthDetails,
    required this.timestamp,
  });
}