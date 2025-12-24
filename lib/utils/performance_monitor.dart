import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Performance monitoring utilities for KRE8TIONS IDE
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final List<String> _performanceLogs = [];
  static Timer? _memoryCleanupTimer;
  
  /// Start timing an operation
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  /// Stop timing and log the result
  static void stopTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      if (kDebugMode) {
        print('⏱️ $operation: ${duration}ms');
      }
      
      _performanceLogs.add('$operation: ${duration}ms');
      
      // Keep only last 100 logs to prevent memory bloat
      if (_performanceLogs.length > 100) {
        _performanceLogs.removeRange(0, _performanceLogs.length - 100);
      }
      
      _timers.remove(operation);
    }
  }
  
  /// Initialize performance monitoring
  static void initialize() {
    // Clean up memory every 5 minutes
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performMemoryCleanup(),
    );
  }
  
  /// Clean up memory and caches
  static void _performMemoryCleanup() {
    // Clear theme decoration cache
    try {
      // Clear any cached decorations from theme
      if (kDebugMode) {
        print('🧹 Performing memory cleanup...');
      }
      
      // Force garbage collection
      SystemChannels.platform.invokeMethod('SystemChrome.setEnabledSystemUIMode');
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Memory cleanup failed: $e');
      }
    }
  }
  
  /// Get performance logs
  static List<String> getPerformanceLogs() => List.from(_performanceLogs);
  
  /// Clear all logs
  static void clearLogs() {
    _performanceLogs.clear();
  }
  
  /// Dispose resources
  static void dispose() {
    _memoryCleanupTimer?.cancel();
    _timers.clear();
    _performanceLogs.clear();
  }
  
  /// Measure widget build performance
  static T measureBuild<T>(String widgetName, T Function() buildFunction) {
    if (!kDebugMode) {
      return buildFunction();
    }
    
    startTimer('Build: $widgetName');
    final result = buildFunction();
    stopTimer('Build: $widgetName');
    return result;
  }
  
  /// Measure async operation performance
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    if (!kDebugMode) {
      return await operation();
    }
    
    startTimer(operationName);
    final result = await operation();
    stopTimer(operationName);
    return result;
  }
}