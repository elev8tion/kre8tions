import 'package:flutter/foundation.dart';

/// 📝 **PRODUCTION-SAFE LOGGER**
///
/// Provides conditional logging that only outputs in debug mode.
/// Prevents console spam in production builds.
class Logger {
  /// Log info messages (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// Log error messages (only in debug mode)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🚨 $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: $stackTrace');
      }
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🐛 $message');
    }
  }
}
