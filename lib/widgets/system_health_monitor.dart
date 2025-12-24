import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kre8tions/services/performance_profiler_service.dart';
import 'package:kre8tions/services/service_orchestrator.dart';

/// 🏥 **COMPREHENSIVE SYSTEM HEALTH MONITOR**
/// Real-time system diagnostics with auto-healing capabilities
class SystemHealthMonitor extends StatefulWidget {
  const SystemHealthMonitor({super.key});

  @override
  State<SystemHealthMonitor> createState() => _SystemHealthMonitorState();
}

class _SystemHealthMonitorState extends State<SystemHealthMonitor>
    with TickerProviderStateMixin {
  
  late ServiceOrchestrator _orchestrator;
  late PerformanceProfilerService _profiler;
  late AnimationController _pulseController;
  late AnimationController _healingController;
  
  Timer? _healthCheckTimer;
  Map<String, dynamic>? _lastHealthReport;
  bool _isAutoHealingActive = false;
  bool _showDetailedView = false;
  int _healthScore = 100;
  String _overallStatus = 'Excellent';
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _orchestrator = ServiceOrchestrator.instance;
    _profiler = PerformanceProfilerService();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _healingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _startHealthMonitoring();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _healingController.dispose();
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  void _startHealthMonitoring() {
    _performHealthCheck();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performHealthCheck();
    });
  }

  Future<void> _performHealthCheck() async {
    final healthReport = await _orchestrator.getSystemStatus();
    
    setState(() {
      _lastHealthReport = healthReport.healthDetails;
      _healthScore = _lastHealthReport?['healthScore'] ?? 100;
      _updateOverallStatus();
    });
  }

  void _updateOverallStatus() {
    if (_healthScore >= 90) {
      _overallStatus = 'Excellent';
      _statusColor = Colors.green;
    } else if (_healthScore >= 75) {
      _overallStatus = 'Good';
      _statusColor = Colors.blue;
    } else if (_healthScore >= 60) {
      _overallStatus = 'Fair';
      _statusColor = Colors.orange;
    } else if (_healthScore >= 40) {
      _overallStatus = 'Poor';
      _statusColor = Colors.red;
    } else {
      _overallStatus = 'Critical';
      _statusColor = Colors.purple;
    }
  }

  Future<void> _performAutoHealing() async {
    setState(() {
      _isAutoHealingActive = true;
    });
    
    _healingController.forward();
    
    final success = await _orchestrator.performAutoHealing();
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isAutoHealingActive = false;
    });
    
    _healingController.reset();
    
    // Refresh health check
    await _performHealthCheck();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Auto-healing completed successfully'
            : '⚠️ Auto-healing partially completed'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _statusColor.withValues(alpha: 0.08),  // Flat color - no gradient
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthHeader(theme),
            const SizedBox(height: 16),
            _buildHealthScore(theme),
            const SizedBox(height: 16),
            if (_showDetailedView) ...[
              _buildDetailedDiagnostics(theme),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthHeader(ThemeData theme) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withValues(
                  alpha: 0.2 + (math.sin(_pulseController.value * math.pi * 2) * 0.1),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.monitor_heart,
                color: _statusColor,
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Health Monitor',
                style: theme.textTheme.titleLarge?.copyWith(
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
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: $_overallStatus',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _showDetailedView = !_showDetailedView;
            });
          },
          icon: Icon(
            _showDetailedView ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.primary,
          ),
          tooltip: _showDetailedView ? 'Hide Details' : 'Show Details',
        ),
      ],
    );
  }

  Widget _buildHealthScore(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Score',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$_healthScore',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/100',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildHealthMeter(theme),
                const SizedBox(height: 8),
                Text(
                  _getHealthDescription(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMeter(ThemeData theme) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _healthScore / 100,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _statusColor,  // Flat status color - no gradient
          ),
        ),
      ),
    );
  }

  String _getHealthDescription() {
    switch (_overallStatus) {
      case 'Excellent':
        return 'All systems operating optimally';
      case 'Good':
        return 'Minor issues detected, performance stable';
      case 'Fair':
        return 'Some performance degradation observed';
      case 'Poor':
        return 'Multiple issues affecting performance';
      case 'Critical':
        return 'Immediate attention required';
      default:
        return 'System status unknown';
    }
  }

  Widget _buildDetailedDiagnostics(ThemeData theme) {
    if (_lastHealthReport == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final diagnostics = [
      _buildDiagnosticItem(theme, 'Memory Health', 
          _lastHealthReport!['memoryHealth'], Icons.memory),
      _buildDiagnosticItem(theme, 'Service Connectivity', 
          _lastHealthReport!['serviceConnectivity'], Icons.link),
      _buildDiagnosticItem(theme, 'Performance Health', 
          _lastHealthReport!['performanceHealth'], Icons.speed),
      _buildDiagnosticItem(theme, 'State Consistency', 
          _lastHealthReport!['stateConsistency'], Icons.sync),
      _buildDiagnosticItem(theme, 'Resource Availability', 
          _lastHealthReport!['resourceAvailability'], Icons.storage),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Diagnostics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...diagnostics,
      ],
    );
  }

  Widget _buildDiagnosticItem(ThemeData theme, String title, dynamic data, IconData icon) {
    if (data == null) return const SizedBox.shrink();
    
    final isHealthy = data['isHealthy'] ?? data['isConsistent'] ?? data['allConnected'] ?? data['available'] ?? false;
    final color = isHealthy ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data['issues'] != null && (data['issues'] as List).isNotEmpty)
                  Text(
                    (data['issues'] as List).first.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isHealthy ? 'OK' : 'ISSUE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _performHealthCheck,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _healingController,
            builder: (context, child) {
              return ElevatedButton.icon(
                onPressed: _isAutoHealingActive ? null : _performAutoHealing,
                icon: _isAutoHealingActive
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : const Icon(Icons.healing, size: 18),
                label: Text(_isAutoHealingActive ? 'Healing...' : 'Auto-Heal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAutoHealingActive
                      ? theme.colorScheme.surface
                      : theme.colorScheme.secondaryContainer,
                  foregroundColor: _isAutoHealingActive
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                      : theme.colorScheme.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}