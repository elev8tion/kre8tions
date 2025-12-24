import 'package:flutter/material.dart';
import 'package:kre8tions/services/dependency_manager.dart';

/// 🚀 **SYSTEM STATUS PANEL**
/// Beautiful UI displaying dependency status, API updates, design trends
class SystemStatusPanel extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const SystemStatusPanel({
    super.key,
    this.onRefresh,
  });

  @override
  State<SystemStatusPanel> createState() => _SystemStatusPanelState();
}

class _SystemStatusPanelState extends State<SystemStatusPanel>
    with TickerProviderStateMixin {
  SystemStatus? _status;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _checkSystemStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSystemStatus() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await DependencyManager.instance.checkAllSystems();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = SystemStatus.error(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? _buildLoadingView(theme)
                : _status != null
                    ? _buildStatusContent(theme)
                    : _buildEmptyView(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,  // Flat primary color - no gradient
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.system_update,
            color: theme.colorScheme.onPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Dependencies • APIs • Design Trends',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : _checkSystemStatus,
          icon: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isLoading ? _pulseAnimation.value : 1.0,
                child: Icon(
                  Icons.refresh,
                  color: _isLoading 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              );
            },
          ),
          tooltip: 'Refresh Status',
        ),
      ],
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Checking system status...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing dependencies, APIs, and trends',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No status data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click refresh to check system status',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(ThemeData theme) {
    final status = _status!;
    
    if (status.hasErrors) {
      return _buildErrorView(theme, status.error!);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(theme, status),
          const SizedBox(height: 20),
          _buildPackageStatus(theme, status.packages),
          const SizedBox(height: 16),
          _buildAPIStatus(theme, status.apis),
          const SizedBox(height: 16),
          _buildDesignStatus(theme, status.design),
          const SizedBox(height: 16),
          _buildMCPStatus(theme, status.mcp),
          const SizedBox(height: 16),
          _buildLastUpdated(theme, status.lastChecked),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'System Check Failed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checkSystemStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme, SystemStatus status) {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            theme,
            icon: Icons.inventory_2,
            title: 'Packages',
            value: '${status.packages.updates.length}',
            subtitle: status.packages.updates.isEmpty ? 'Up to date' : 'Updates available',
            color: status.packages.updates.isEmpty ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            theme,
            icon: Icons.api,
            title: 'APIs',
            value: '${status.apis.patterns.length}',
            subtitle: 'Patterns tracked',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageStatus(ThemeData theme, PackageStatus packages) {
    return _buildStatusSection(
      theme,
      title: 'Package Dependencies',
      icon: Icons.inventory,
      statusText: packages.status,
      isHealthy: packages.updates.isEmpty,
      children: [
        if (packages.updates.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...packages.updates.take(3).map((update) => _buildPackageItem(theme, update)),
          if (packages.updates.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${packages.updates.length - 3} more updates available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if (packages.breakingChanges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${packages.breakingChanges.length} breaking changes detected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackageItem(ThemeData theme, PackageUpdate update) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: update.isBreaking ? Colors.red : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${update.currentVersion} → ${update.latestVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (update.isBreaking)
            const Icon(
              Icons.warning,
              color: Colors.red,
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildAPIStatus(ThemeData theme, APIStatus apis) {
    return _buildStatusSection(
      theme,
      title: 'API Patterns',
      icon: Icons.api,
      statusText: apis.status,
      isHealthy: true,
      children: [
        if (apis.patterns.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...apis.patterns.take(3).map((pattern) => _buildAPIItem(theme, pattern)),
        ],
      ],
    );
  }

  Widget _buildAPIItem(ThemeData theme, APIPattern pattern) {
    final trendColor = switch (pattern.trend) {
      TrendLevel.hot => Colors.red,
      TrendLevel.rising => Colors.green,
      TrendLevel.stable => Colors.blue,
      TrendLevel.declining => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pattern.trend.name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: trendColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  pattern.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignStatus(ThemeData theme, DesignStatus design) {
    return _buildStatusSection(
      theme,
      title: 'Design Trends',
      icon: Icons.palette,
      statusText: design.status,
      isHealthy: true,
      children: [
        if (design.trends.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...design.trends.take(2).map((trend) => _buildDesignItem(theme, trend)),
        ],
      ],
    );
  }

  Widget _buildDesignItem(ThemeData theme, DesignTrend trend) {
    final adoptionColor = trend.adoption > 0.7 
        ? Colors.green 
        : trend.adoption > 0.4 
            ? Colors.orange 
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: LinearProgressIndicator(
              value: trend.adoption,
              backgroundColor: adoptionColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(adoptionColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${(trend.adoption * 100).toInt()}% adoption',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCPStatus(ThemeData theme, MCPStatus mcp) {
    return _buildStatusSection(
      theme,
      title: 'MCP Servers',
      icon: Icons.dns,
      statusText: mcp.status,
      isHealthy: mcp.healthy == mcp.total,
      children: [
        if (mcp.servers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: mcp.healthPercentage,
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${mcp.healthy}/${mcp.total}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: mcp.healthy == mcp.total ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required String statusText,
    required bool isHealthy,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLastUpdated(ThemeData theme, DateTime lastChecked) {
    final now = DateTime.now();
    final difference = now.difference(lastChecked);
    final timeAgo = difference.inMinutes < 1 
        ? 'Just now'
        : difference.inHours < 1
            ? '${difference.inMinutes}m ago'
            : difference.inDays < 1
                ? '${difference.inHours}h ago'
                : '${difference.inDays}d ago';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: $timeAgo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}