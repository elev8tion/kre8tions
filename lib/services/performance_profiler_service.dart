import 'dart:async';
import 'dart:math';

enum ProfilerMetric {
  framerate,
  frameTime,
  cpuUsage,
  memoryUsage,
  renderTime,
  layoutTime,
  paintTime,
  buildTime,
  networkLatency,
  diskIO,
}

enum PerformanceIssueType {
  slowFrames,
  memoryLeak,
  highCpuUsage,
  inefficientRebuild,
  oversizedImages,
  tooManyAnimations,
  blockingIO,
}

class PerformanceMetric {
  final ProfilerMetric type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final bool isAlert;
  final double? threshold;

  const PerformanceMetric({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.isAlert = false,
    this.threshold,
  });

  String get displayName {
    switch (type) {
      case ProfilerMetric.framerate:
        return 'Frame Rate';
      case ProfilerMetric.frameTime:
        return 'Frame Time';
      case ProfilerMetric.cpuUsage:
        return 'CPU Usage';
      case ProfilerMetric.memoryUsage:
        return 'Memory Usage';
      case ProfilerMetric.renderTime:
        return 'Render Time';
      case ProfilerMetric.layoutTime:
        return 'Layout Time';
      case ProfilerMetric.paintTime:
        return 'Paint Time';
      case ProfilerMetric.buildTime:
        return 'Build Time';
      case ProfilerMetric.networkLatency:
        return 'Network Latency';
      case ProfilerMetric.diskIO:
        return 'Disk I/O';
    }
  }

  String get icon {
    switch (type) {
      case ProfilerMetric.framerate:
        return '📊';
      case ProfilerMetric.frameTime:
        return '⏱️';
      case ProfilerMetric.cpuUsage:
        return '🖥️';
      case ProfilerMetric.memoryUsage:
        return '💾';
      case ProfilerMetric.renderTime:
        return '🎨';
      case ProfilerMetric.layoutTime:
        return '📐';
      case ProfilerMetric.paintTime:
        return '🖌️';
      case ProfilerMetric.buildTime:
        return '🏗️';
      case ProfilerMetric.networkLatency:
        return '🌐';
      case ProfilerMetric.diskIO:
        return '💽';
    }
  }

  String get formattedValue {
    return '${value.toStringAsFixed(1)} $unit';
  }
}

class PerformanceIssue {
  final String id;
  final PerformanceIssueType type;
  final String title;
  final String description;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final List<String> suggestions;
  final String? filePath;
  final int? line;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  const PerformanceIssue({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.suggestions,
    this.filePath,
    this.line,
    required this.detectedAt,
    this.metadata = const {},
  });

  String get icon {
    switch (type) {
      case PerformanceIssueType.slowFrames:
        return '🐌';
      case PerformanceIssueType.memoryLeak:
        return '🔍';
      case PerformanceIssueType.highCpuUsage:
        return '🔥';
      case PerformanceIssueType.inefficientRebuild:
        return '♻️';
      case PerformanceIssueType.oversizedImages:
        return '📷';
      case PerformanceIssueType.tooManyAnimations:
        return '🎬';
      case PerformanceIssueType.blockingIO:
        return '⏳';
    }
  }

  String get severityColor {
    switch (severity) {
      case 'low':
        return 'blue';
      case 'medium':
        return 'orange';
      case 'high':
        return 'red';
      case 'critical':
        return 'purple';
      default:
        return 'grey';
    }
  }
}

class FrameData {
  final int frameNumber;
  final double frameTime;
  final double renderTime;
  final double layoutTime;
  final double paintTime;
  final double buildTime;
  final DateTime timestamp;
  final bool isSlowFrame;

  const FrameData({
    required this.frameNumber,
    required this.frameTime,
    required this.renderTime,
    required this.layoutTime,
    required this.paintTime,
    required this.buildTime,
    required this.timestamp,
    this.isSlowFrame = false,
  });

  double get framerate => 1000.0 / frameTime;
}

class MemorySnapshot {
  final double totalMemory;
  final double usedMemory;
  final double heapMemory;
  final double stackMemory;
  final int objectCount;
  final int gcCollections;
  final DateTime timestamp;

  const MemorySnapshot({
    required this.totalMemory,
    required this.usedMemory,
    required this.heapMemory,
    required this.stackMemory,
    required this.objectCount,
    required this.gcCollections,
    required this.timestamp,
  });

  double get memoryUsagePercent => (usedMemory / totalMemory) * 100;
  double get freeMemory => totalMemory - usedMemory;
}

class NetworkRequest {
  final String id;
  final String url;
  final String method;
  final int statusCode;
  final double latency;
  final int requestSize;
  final int responseSize;
  final DateTime timestamp;
  final Map<String, String> headers;

  const NetworkRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.statusCode,
    required this.latency,
    required this.requestSize,
    required this.responseSize,
    required this.timestamp,
    this.headers = const {},
  });

  bool get isSlowRequest => latency > 1000; // > 1 second
  bool get isLargeResponse => responseSize > 1024 * 1024; // > 1 MB
}

class PerformanceProfilerService {
  static final PerformanceProfilerService _instance = PerformanceProfilerService._internal();
  factory PerformanceProfilerService() => _instance;
  PerformanceProfilerService._internal();

  final StreamController<PerformanceMetric> _metricsController = 
      StreamController<PerformanceMetric>.broadcast();
  final StreamController<PerformanceIssue> _issuesController = 
      StreamController<PerformanceIssue>.broadcast();
  final StreamController<FrameData> _frameDataController = 
      StreamController<FrameData>.broadcast();
  final StreamController<MemorySnapshot> _memoryController = 
      StreamController<MemorySnapshot>.broadcast();
  final StreamController<NetworkRequest> _networkController = 
      StreamController<NetworkRequest>.broadcast();

  Stream<PerformanceMetric> get metricsStream => _metricsController.stream;
  Stream<PerformanceIssue> get issuesStream => _issuesController.stream;
  Stream<FrameData> get frameDataStream => _frameDataController.stream;
  Stream<MemorySnapshot> get memoryStream => _memoryController.stream;
  Stream<NetworkRequest> get networkStream => _networkController.stream;

  bool _isProfilingActive = false;
  Timer? _profilingTimer;
  final List<PerformanceMetric> _recentMetrics = [];
  final List<PerformanceIssue> _detectedIssues = [];
  final List<FrameData> _frameHistory = [];
  final List<MemorySnapshot> _memoryHistory = [];
  final List<NetworkRequest> _networkHistory = [];

  bool get isProfilingActive => _isProfilingActive;
  List<PerformanceMetric> get recentMetrics => List.unmodifiable(_recentMetrics);
  List<PerformanceIssue> get detectedIssues => List.unmodifiable(_detectedIssues);
  List<FrameData> get frameHistory => List.unmodifiable(_frameHistory);
  List<MemorySnapshot> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<NetworkRequest> get networkHistory => List.unmodifiable(_networkHistory);

  // Profiling Control
  void startProfiling({Duration interval = const Duration(milliseconds: 100)}) {
    if (_isProfilingActive) return;

    _isProfilingActive = true;
    _profilingTimer = Timer.periodic(interval, (_) {
      _collectMetrics();
    });
  }

  void stopProfiling() {
    _isProfilingActive = false;
    _profilingTimer?.cancel();
    _profilingTimer = null;
  }

  void _collectMetrics() {
    final now = DateTime.now();
    final random = Random();

    // Simulate frame data
    final frameTime = 16.0 + random.nextDouble() * 10.0; // 16-26ms
    final renderTime = frameTime * 0.4 + random.nextDouble() * 2.0;
    final layoutTime = frameTime * 0.2 + random.nextDouble() * 1.0;
    final paintTime = frameTime * 0.25 + random.nextDouble() * 1.5;
    final buildTime = frameTime * 0.15 + random.nextDouble() * 1.0;

    final frameData = FrameData(
      frameNumber: _frameHistory.length + 1,
      frameTime: frameTime,
      renderTime: renderTime,
      layoutTime: layoutTime,
      paintTime: paintTime,
      buildTime: buildTime,
      timestamp: now,
      isSlowFrame: frameTime > 30.0,
    );

    _frameHistory.add(frameData);
    if (_frameHistory.length > 1000) {
      _frameHistory.removeAt(0);
    }
    _frameDataController.add(frameData);

    // Emit individual metrics
    _emitMetric(ProfilerMetric.framerate, frameData.framerate, 'FPS', now);
    _emitMetric(ProfilerMetric.frameTime, frameTime, 'ms', now);
    _emitMetric(ProfilerMetric.renderTime, renderTime, 'ms', now);
    _emitMetric(ProfilerMetric.layoutTime, layoutTime, 'ms', now);
    _emitMetric(ProfilerMetric.paintTime, paintTime, 'ms', now);
    _emitMetric(ProfilerMetric.buildTime, buildTime, 'ms', now);

    // Simulate memory data
    final totalMemory = 128.0 + random.nextDouble() * 32.0; // 128-160 MB
    final usedMemory = 40.0 + random.nextDouble() * 60.0; // 40-100 MB
    final heapMemory = usedMemory * 0.8;
    final stackMemory = usedMemory * 0.2;

    final memorySnapshot = MemorySnapshot(
      totalMemory: totalMemory,
      usedMemory: usedMemory,
      heapMemory: heapMemory,
      stackMemory: stackMemory,
      objectCount: 25000 + random.nextInt(10000),
      gcCollections: random.nextInt(5),
      timestamp: now,
    );

    _memoryHistory.add(memorySnapshot);
    if (_memoryHistory.length > 500) {
      _memoryHistory.removeAt(0);
    }
    _memoryController.add(memorySnapshot);

    _emitMetric(ProfilerMetric.memoryUsage, memorySnapshot.memoryUsagePercent, '%', now);

    // Simulate CPU usage
    final cpuUsage = 5.0 + random.nextDouble() * 25.0; // 5-30%
    _emitMetric(ProfilerMetric.cpuUsage, cpuUsage, '%', now);

    // Detect performance issues
    _detectPerformanceIssues(frameData, memorySnapshot, cpuUsage);
  }

  void _emitMetric(ProfilerMetric type, double value, String unit, DateTime timestamp) {
    final threshold = _getThreshold(type);
    final isAlert = threshold != null && value > threshold;

    final metric = PerformanceMetric(
      type: type,
      value: value,
      unit: unit,
      timestamp: timestamp,
      isAlert: isAlert,
      threshold: threshold,
    );

    _recentMetrics.add(metric);
    if (_recentMetrics.length > 100) {
      _recentMetrics.removeAt(0);
    }

    _metricsController.add(metric);
  }

  double? _getThreshold(ProfilerMetric type) {
    switch (type) {
      case ProfilerMetric.framerate:
        return null; // Lower is worse for framerate
      case ProfilerMetric.frameTime:
        return 30.0; // 30ms threshold
      case ProfilerMetric.cpuUsage:
        return 80.0; // 80% CPU
      case ProfilerMetric.memoryUsage:
        return 85.0; // 85% memory
      case ProfilerMetric.renderTime:
        return 20.0; // 20ms
      case ProfilerMetric.layoutTime:
        return 10.0; // 10ms
      case ProfilerMetric.paintTime:
        return 15.0; // 15ms
      case ProfilerMetric.buildTime:
        return 8.0; // 8ms
      case ProfilerMetric.networkLatency:
        return 1000.0; // 1 second
      case ProfilerMetric.diskIO:
        return 100.0; // 100ms
    }
  }

  void _detectPerformanceIssues(FrameData frameData, MemorySnapshot memorySnapshot, double cpuUsage) {
    final now = DateTime.now();

    // Detect slow frames
    if (frameData.isSlowFrame) {
      _addIssue(PerformanceIssue(
        id: '${now.millisecondsSinceEpoch}_slow_frame',
        type: PerformanceIssueType.slowFrames,
        title: 'Slow Frame Detected',
        description: 'Frame took ${frameData.frameTime.toStringAsFixed(1)}ms to render (target: 16.7ms)',
        severity: frameData.frameTime > 50 ? 'high' : 'medium',
        suggestions: [
          'Check for expensive operations in build methods',
          'Use const constructors where possible',
          'Avoid creating widgets in loops',
          'Consider using ListView.builder for large lists',
        ],
        detectedAt: now,
        metadata: {
          'frameTime': frameData.frameTime,
          'frameNumber': frameData.frameNumber,
        },
      ));
    }

    // Detect high memory usage
    if (memorySnapshot.memoryUsagePercent > 85) {
      _addIssue(PerformanceIssue(
        id: '${now.millisecondsSinceEpoch}_high_memory',
        type: PerformanceIssueType.memoryLeak,
        title: 'High Memory Usage',
        description: 'Memory usage is at ${memorySnapshot.memoryUsagePercent.toStringAsFixed(1)}%',
        severity: memorySnapshot.memoryUsagePercent > 95 ? 'critical' : 'high',
        suggestions: [
          'Check for memory leaks in your code',
          'Dispose of controllers and streams properly',
          'Use WeakReference for callbacks',
          'Avoid storing large objects in memory',
        ],
        detectedAt: now,
        metadata: {
          'memoryUsage': memorySnapshot.memoryUsagePercent,
          'usedMemory': memorySnapshot.usedMemory,
        },
      ));
    }

    // Detect high CPU usage
    if (cpuUsage > 80) {
      _addIssue(PerformanceIssue(
        id: '${now.millisecondsSinceEpoch}_high_cpu',
        type: PerformanceIssueType.highCpuUsage,
        title: 'High CPU Usage',
        description: 'CPU usage is at ${cpuUsage.toStringAsFixed(1)}%',
        severity: cpuUsage > 95 ? 'critical' : 'high',
        suggestions: [
          'Optimize expensive computations',
          'Use Isolates for heavy processing',
          'Reduce the frequency of setState calls',
          'Cache computed values where possible',
        ],
        detectedAt: now,
        metadata: {
          'cpuUsage': cpuUsage,
        },
      ));
    }

    // Detect inefficient rebuilds
    if (frameData.buildTime > 8.0) {
      _addIssue(PerformanceIssue(
        id: '${now.millisecondsSinceEpoch}_slow_build',
        type: PerformanceIssueType.inefficientRebuild,
        title: 'Slow Widget Build',
        description: 'Widget build took ${frameData.buildTime.toStringAsFixed(1)}ms',
        severity: frameData.buildTime > 15 ? 'high' : 'medium',
        suggestions: [
          'Split large widgets into smaller ones',
          'Use const constructors',
          'Implement shouldRebuild in custom widgets',
          'Move expensive operations out of build method',
        ],
        detectedAt: now,
        metadata: {
          'buildTime': frameData.buildTime,
        },
      ));
    }
  }

  void _addIssue(PerformanceIssue issue) {
    // Avoid duplicate issues within a short time window
    final existingIssue = _detectedIssues
        .where((i) => i.type == issue.type)
        .where((i) => DateTime.now().difference(i.detectedAt).inSeconds < 5)
        .firstOrNull;

    if (existingIssue == null) {
      _detectedIssues.add(issue);
      if (_detectedIssues.length > 50) {
        _detectedIssues.removeAt(0);
      }
      _issuesController.add(issue);
    }
  }

  // Network Profiling
  void logNetworkRequest(NetworkRequest request) {
    _networkHistory.add(request);
    if (_networkHistory.length > 100) {
      _networkHistory.removeAt(0);
    }
    _networkController.add(request);

    // Check for performance issues
    if (request.isSlowRequest) {
      _addIssue(PerformanceIssue(
        id: '${request.timestamp.millisecondsSinceEpoch}_slow_network',
        type: PerformanceIssueType.blockingIO,
        title: 'Slow Network Request',
        description: 'Request to ${request.url} took ${request.latency.toStringAsFixed(0)}ms',
        severity: request.latency > 5000 ? 'high' : 'medium',
        suggestions: [
          'Optimize API endpoints',
          'Implement request caching',
          'Use pagination for large datasets',
          'Consider using GraphQL for selective data fetching',
        ],
        detectedAt: request.timestamp,
        metadata: {
          'url': request.url,
          'latency': request.latency,
          'responseSize': request.responseSize,
        },
      ));
    }

    if (request.isLargeResponse) {
      _addIssue(PerformanceIssue(
        id: '${request.timestamp.millisecondsSinceEpoch}_large_response',
        type: PerformanceIssueType.blockingIO,
        title: 'Large Network Response',
        description: 'Response from ${request.url} was ${(request.responseSize / 1024 / 1024).toStringAsFixed(1)} MB',
        severity: 'medium',
        suggestions: [
          'Compress response data',
          'Implement response pagination',
          'Only request necessary fields',
          'Use image compression for media',
        ],
        detectedAt: request.timestamp,
        metadata: {
          'url': request.url,
          'responseSize': request.responseSize,
        },
      ));
    }
  }

  // Analysis and Reporting
  Map<String, dynamic> generatePerformanceReport() {
    final now = DateTime.now();
    final last10Frames = _frameHistory.take(10).toList();
    final averageFrameTime = last10Frames.isNotEmpty
        ? last10Frames.map((f) => f.frameTime).reduce((a, b) => a + b) / last10Frames.length
        : 0.0;

    final slowFramesCount = _frameHistory.where((f) => f.isSlowFrame).length;
    final totalFrames = _frameHistory.length;

    final currentMemory = _memoryHistory.isNotEmpty ? _memoryHistory.last : null;
    final criticalIssues = _detectedIssues.where((i) => i.severity == 'critical').length;
    final highIssues = _detectedIssues.where((i) => i.severity == 'high').length;

    return {
      'timestamp': now.toIso8601String(),
      'summary': {
        'averageFrameTime': averageFrameTime,
        'slowFramesPercentage': totalFrames > 0 ? (slowFramesCount / totalFrames) * 100 : 0,
        'currentMemoryUsage': currentMemory?.memoryUsagePercent ?? 0,
        'totalIssues': _detectedIssues.length,
        'criticalIssues': criticalIssues,
        'highIssues': highIssues,
      },
      'frameAnalysis': {
        'totalFrames': totalFrames,
        'slowFrames': slowFramesCount,
        'averageFramerate': last10Frames.isNotEmpty
            ? last10Frames.map((f) => f.framerate).reduce((a, b) => a + b) / last10Frames.length
            : 60.0,
      },
      'memoryAnalysis': {
        'currentUsage': currentMemory?.usedMemory ?? 0,
        'peakUsage': _memoryHistory.isNotEmpty
            ? _memoryHistory.map((m) => m.usedMemory).reduce((a, b) => a > b ? a : b)
            : 0,
        'gcCollections': currentMemory?.gcCollections ?? 0,
      },
      'networkAnalysis': {
        'totalRequests': _networkHistory.length,
        'slowRequests': _networkHistory.where((r) => r.isSlowRequest).length,
        'averageLatency': _networkHistory.isNotEmpty
            ? _networkHistory.map((r) => r.latency).reduce((a, b) => a + b) / _networkHistory.length
            : 0,
      },
      'recommendations': _generateRecommendations(),
    };
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    final slowFramesPercentage = _frameHistory.isNotEmpty
        ? (_frameHistory.where((f) => f.isSlowFrame).length / _frameHistory.length) * 100
        : 0;

    if (slowFramesPercentage > 5) {
      recommendations.add('Consider optimizing your UI - more than 5% of frames are slow');
    }

    final currentMemory = _memoryHistory.isNotEmpty ? _memoryHistory.last : null;
    if (currentMemory != null && currentMemory.memoryUsagePercent > 80) {
      recommendations.add('Memory usage is high - consider implementing memory optimizations');
    }

    final slowNetworkRequests = _networkHistory.where((r) => r.isSlowRequest).length;
    if (slowNetworkRequests > _networkHistory.length * 0.2) {
      recommendations.add('Network performance is poor - optimize your API calls');
    }

    final highPriorityIssues = _detectedIssues
        .where((i) => i.severity == 'high' || i.severity == 'critical')
        .length;
    if (highPriorityIssues > 5) {
      recommendations.add('Address high-priority performance issues');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance looks good! Keep monitoring for any changes.');
    }

    return recommendations;
  }

  // Cleanup and utility methods
  void clearHistory() {
    _frameHistory.clear();
    _memoryHistory.clear();
    _networkHistory.clear();
    _detectedIssues.clear();
    _recentMetrics.clear();
  }

  void clearIssues() {
    _detectedIssues.clear();
  }

  List<PerformanceIssue> getIssuesByType(PerformanceIssueType type) {
    return _detectedIssues.where((issue) => issue.type == type).toList();
  }

  List<PerformanceIssue> getIssuesBySeverity(String severity) {
    return _detectedIssues.where((issue) => issue.severity == severity).toList();
  }

  PerformanceMetric? getLatestMetric(ProfilerMetric type) {
    return _recentMetrics
        .where((metric) => metric.type == type)
        .lastOrNull;
  }

  void dispose() {
    stopProfiling();
    _metricsController.close();
    _issuesController.close();
    _frameDataController.close();
    _memoryController.close();
    _networkController.close();
  }
}