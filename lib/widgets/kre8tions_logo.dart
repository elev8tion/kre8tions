import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kre8tions/theme.dart';

/// KRE8TIONS Brand Logo Widget
/// Supports both light/dark variations and SVG/Icon modes
class Kre8tionsLogo extends StatelessWidget {
  final double height;
  final bool isDark;
  final bool animate;
  final bool useSvg;

  const Kre8tionsLogo({
    super.key,
    this.height = 40,
    this.isDark = true,
    this.animate = false,
    this.useSvg = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
      height: height,
      child: useSvg ? _buildSvgLogo() : _buildIconLogo(),
    );
  }

  /// Build SVG-based logo (preferred for crisp scaling)
  Widget _buildSvgLogo() {
    final svgPath = isDark 
      ? 'assets/logos/kre8tions_dark.svg'
      : 'assets/logos/kre8tions_light.svg';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown Icon for branding consistency
        Container(
          height: height * 0.7,
          width: height * 0.7,
          decoration: BoxDecoration(
            color: Kre8tionsColors.accentPink,  // Flat neon pink - no gradient
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Kre8tionsColors.accentPink.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: height * 0.35,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        // SVG Logo
        SvgPicture.asset(
          svgPath,
          height: height,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            isDark ? Colors.white : Colors.black87,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  /// Build icon-based logo (fallback for when SVG is not available)
  Widget _buildIconLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown Icon for the KRE8TIONS brand
        Container(
          height: height,
          width: height * 0.8,
          decoration: BoxDecoration(
            color: Kre8tionsColors.accentPink,  // Flat neon pink - no gradient
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Kre8tionsColors.accentPink.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: height * 0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        // KRE8TIONS Text
        Text(
          'KRE8TIONS',
          style: TextStyle(
            fontSize: height * 0.6,
            fontWeight: FontWeight.bold,
            color: Kre8tionsColors.accentBlue,  // Flat neon blue - no gradient
            letterSpacing: 1.5,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

/// Compact version for smaller spaces
class Kre8tionsLogoCompact extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final bool useSvg;

  const Kre8tionsLogoCompact({
    super.key,
    this.size = 32,
    this.showText = true,
    this.isDark = true,
    this.useSvg = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: useSvg ? _buildSvgCompact() : _buildIconCompact(),
    );
  }

  /// Compact SVG version
  Widget _buildSvgCompact() {
    final svgPath = isDark 
      ? 'assets/logos/kre8tions_dark.svg'
      : 'assets/logos/kre8tions_light.svg';
      
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size * 0.8,
          width: size * 0.8,
          decoration: BoxDecoration(
            color: Kre8tionsColors.accentPink,  // Flat neon pink - no gradient
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Kre8tionsColors.accentPink.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          SvgPicture.asset(
            svgPath,
            height: size * 0.7,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : Colors.black87,
              BlendMode.srcIn,
            ),
          ),
        ],
      ],
    );
  }

  /// Compact icon version
  Widget _buildIconCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Kre8tionsColors.accentPink,  // Flat neon pink - no gradient
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Kre8tionsColors.accentPink.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.6,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'KRE8',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: Kre8tionsColors.accentBlue,  // Flat neon blue - no gradient
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}