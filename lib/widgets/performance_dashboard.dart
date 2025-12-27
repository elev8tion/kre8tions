import 'package:flutter/material.dart';
import 'package:kre8tions/services/performance_profiler_service.dart';
import 'package:kre8tions/theme.dart';
import 'package:kre8tions/utils/glass_morphism_helper.dart';
import 'dart:async';
import 'dart:math' as math;

/// 🚀 **ADVANCED PERFORMANCE DASHBOARD**
/// Real-time monitoring with intelligent insights and automated optimization suggestions
class PerformanceDashboard extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const PerformanceDashboard({
    super.key,
    this.isExpanded = true,
    this.onToggleExpanded,
  });

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> with TickerProviderStateMixin {
  late PerformanceProfilerService _profilerService;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _issuesSubscription;
  
  final List<PerformanceMetric> _recentMetrics = [];
  final List<PerformanceIssue> _activeIssues = [];
  bool _isMonitoring = false;
  String _systemHealth = 'Excellent';
  Color _systemHealthColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _profilerService = PerformanceProfilerService();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeMonitoring();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _metricsSubscription?.cancel();
    _issuesSubscription?.cancel();
    super.dispose();
  }

  void _initializeMonitoring() {
    _metricsSubscription = _profilerService.metricsStream.listen((metric) {
      setState(() {
        _recentMetrics.add(metric);
        if (_recentMetrics.length > 50) {
          _recentMetrics.removeAt(0);
        }
        _updateSystemHealth();
      });
    });

    _issuesSubscription = _profilerService.issuesStream.listen((issue) {
      setState(() {
        _activeIssues.add(issue);
        if (_activeIssues.length > 20) {
          _activeIssues.removeAt(0);
        }
        _updateSystemHealth();
      });
    });

    if (!_profilerService.isProfilingActive) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _profilerService.startProfiling();
    setState(() {
      _isMonitoring = true;
    });
    _slideController.forward();
  }

  void _stopMonitoring() {
    _profilerService.stopProfiling();
    setState(() {
      _isMonitoring = false;
    });
    _slideController.reverse();
  }

  void _updateSystemHealth() {
    final criticalIssues = _activeIssues.where((i) => i.severity == 'critical').length;
    final highIssues = _activeIssues.where((i) => i.severity == 'high').length;
    final recentFrameRate = _getLatestMetric(ProfilerMetric.framerate)?.value ?? 60.0;
    final recentMemory = _getLatestMetric(ProfilerMetric.memoryUsage)?.value ?? 0.0;

    if (criticalIssues > 0 || recentFrameRate < 30) {
      _systemHealth = 'Critical';
      _systemHealthColor = Colors.red;
    } else if (highIssues > 2 || recentMemory > 85 || recentFrameRate < 45) {
      _systemHealth = 'Poor';
      _systemHealthColor = Colors.orange;
    } else if (highIssues > 0 || recentMemory > 70 || recentFrameRate < 55) {
      _systemHealth = 'Good';
      _systemHealthColor = Colors.yellow[700]!;
    } else {
      _systemHealth = 'Excellent';
      _systemHealthColor = Colors.green;
    }
  }

  PerformanceMetric? _getLatestMetric(ProfilerMetric type) {
    return _recentMetrics
        .where((m) => m.type == type)
        .lastOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!widget.isExpanded) {
      return _buildCollapsedView(theme);
    }

    return Container(
      decoration: GlassMorphismHelper.glassContainer(
        color: theme.colorScheme.primary,
        opacity: 0.08,
        blur: 20,
        enableGlow: true,
      ),
      child: Column(
        children: [
          _buildDashboardHeader(theme),
          if (_isMonitoring) ...[
            Expanded(child: _buildMetricsGrid(theme)),
          ] else
            Expanded(child: _buildStartMonitoringView(theme)),
        ],
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme) {
    return Container(
      width: 50,
      decoration: GlassMorphismHelper.glassContainer(
        color: _systemHealthColor,
        opacity: 0.2,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _systemHealthColor.withValues(
                        alpha: 0.3 + (math.sin(_pulseController.value * math.pi * 2) * 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.monitor_heart,
                      color: _systemHealthColor,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  'Performance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _systemHealthColor.withValues(alpha: 0.15),  // Flat color - no gradient
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _systemHealthColor.withValues(
                    alpha: 0.3 + (math.sin(_pulseController.value * math.pi * 2) * 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isMonitoring ? [
                    BoxShadow(
                      color: _systemHealthColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: Icon(
                  Icons.monitor_heart,
                  color: _systemHealthColor,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Monitor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _systemHealthColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'System Health: $_systemHealth',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _systemHealthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isMonitoring)
                IconButton(
                  onPressed: _stopMonitoring,
                  icon: const Icon(Icons.pause_circle, size: 20),
                  tooltip: 'Pause Monitoring',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  ),
                )
              else
                IconButton(
                  onPressed: _startMonitoring,
                  icon: const Icon(Icons.play_circle, size: 20),
                  tooltip: 'Start Monitoring',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onToggleExpanded,
                icon: const Icon(Icons.unfold_less, size: 16),
                tooltip: 'Collapse Dashboard',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartMonitoringView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Performance Monitoring',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor frame rates, memory usage, and detect performance issues in real-time',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startMonitoring,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Start Monitoring'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '• Real-time frame rate monitoring\n'
            '• Memory usage tracking\n'
            '• Automatic issue detection\n'
            '• Performance optimization tips',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStats(theme),
          const SizedBox(height: 16),
          _buildMetricCards(theme),
          if (_activeIssues.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildIssuesPanel(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final frameRate = _getLatestMetric(ProfilerMetric.framerate)?.value ?? 60.0;
    final memoryUsage = _getLatestMetric(ProfilerMetric.memoryUsage)?.value ?? 0.0;
    final cpuUsage = _getLatestMetric(ProfilerMetric.cpuUsage)?.value ?? 0.0;

    return Row(
      children: [
        Expanded(child: _buildStatCard(theme, '${frameRate.toStringAsFixed(1)} FPS', 'Frame Rate', Icons.speed, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(theme, '${memoryUsage.toStringAsFixed(1)}%', 'Memory', Icons.memory, Colors.purple)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(theme, '${cpuUsage.toStringAsFixed(1)}%', 'CPU', Icons.computer, Colors.teal)),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(ThemeData theme) {
    final metrics = [
      ProfilerMetric.frameTime,
      ProfilerMetric.renderTime,
      ProfilerMetric.layoutTime,
      ProfilerMetric.paintTime,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = _getLatestMetric(metrics[index]);
        return _buildMetricCard(theme, metric);
      },
    );
  }

  Widget _buildMetricCard(ThemeData theme, PerformanceMetric? metric) {
    if (metric == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.isAlert
            ? Colors.red.withValues(alpha: 0.1)
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: metric.isAlert
            ? Border.all(color: Colors.red.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Text(metric.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  metric.formattedValue,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: metric.isAlert ? Colors.red : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (metric.isAlert)
            const Icon(Icons.warning, color: Colors.red, size: 16),
        ],
      ),
    );
  }

  Widget _buildIssuesPanel(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Performance Issues (${_activeIssues.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...(_activeIssues.take(3).map((issue) => _buildIssueItem(theme, issue)).toList()),
          if (_activeIssues.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '... and ${_activeIssues.length - 3} more issues',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(ThemeData theme, PerformanceIssue issue) {
    final severityColor = issue.severity == 'critical'
        ? Colors.red
        : issue.severity == 'high'
            ? Colors.orange
            : Colors.yellow[700]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(issue.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (issue.suggestions.isNotEmpty)
                  Text(
                    issue.suggestions.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              issue.severity.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}