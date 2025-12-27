import 'dart:ui';
import 'package:flutter/material.dart';

/// Helper class for creating glass morphism effects
class GlassMorphismHelper {
  /// Creates a glass container decoration with blur effect
  static BoxDecoration glassContainer({
    required Color color,
    double opacity = 0.1,
    double blur = 10,
    bool enableGlow = false,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: enableGlow
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: blur,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  /// Creates a frosted glass effect
  static Widget frostedGlass({
    required Widget child,
    double blur = 10,
    Color? backgroundColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
