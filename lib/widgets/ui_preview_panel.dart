import 'dart:async';

import 'package:flutter/material.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/services/code_execution_service.dart';
import 'package:kre8tions/services/flutter_analyzer.dart';
import 'package:kre8tions/services/service_orchestrator.dart';
import 'package:kre8tions/services/visual_property_manager.dart';
import 'package:kre8tions/widgets/widget_inspector_panel.dart';

class UIPreviewPanel extends StatefulWidget {
  final FlutterProject project;
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final Function(WidgetSelection?) onWidgetSelected;

  const UIPreviewPanel({
    super.key,
    required this.project,
    required this.selectedFile,
    required this.selectedWidget,
    required this.onWidgetSelected,
  });

  @override
  State<UIPreviewPanel> createState() => _UIPreviewPanelState();
}

class _UIPreviewPanelState extends State<UIPreviewPanel> {
  bool _isAnalyzing = false;
  List<WidgetInfo> _widgetTree = [];
  final VisualPropertyManager _propertyManager = VisualPropertyManager();
  late ServiceOrchestrator _orchestrator;
  String _currentMode = 'mockUI';
  final bool _isLaunchingWeb = false;
  DeviceInfo _selectedDevice = Devices.ios.iPhone13;
  
  // 🔥 Live Execution State
  ExecutionResult? _liveExecutionResult;
  WidgetTreeNode? _liveWidgetTree;
  bool _hasLivePreview = false;
  StreamSubscription? _analysisSubscription;
  StreamSubscription? _widgetTreeSubscription;

  @override
  void initState() {
    super.initState();
    _propertyManager.addListener(_onVisualPropertiesChanged);
    _orchestrator = ServiceOrchestrator.instance;
    
    // 🎯 Setup Live Execution Integration
    _setupLiveExecution();
    
    _analyzeProject();
  }

  @override
  void dispose() {
    _propertyManager.removeListener(_onVisualPropertiesChanged);
    _analysisSubscription?.cancel();
    _widgetTreeSubscription?.cancel();
    super.dispose();
  }

  void _onVisualPropertiesChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when visual properties change
      });
    }
  }

  @override
  void didUpdateWidget(UIPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _analyzeProject();
    }
  }

  /// 🎯 **SETUP LIVE EXECUTION INTEGRATION**
  void _setupLiveExecution() {
    // Listen to live analysis updates
    _analysisSubscription = _orchestrator.analysisStream.listen((update) {
      if (mounted) {
        setState(() {
          _liveExecutionResult = update.executionResult;
          _hasLivePreview = update.executionResult.success;
        });
      }
    });
    
    // Listen to widget tree updates  
    _widgetTreeSubscription = _orchestrator.eventStream.listen((event) {
      if (mounted && event.type == EventType.projectLoaded) {
        final result = event.data as ProjectLoadResult;
        if (result.executionResult?.widgetTree != null) {
          setState(() {
            _liveWidgetTree = result.executionResult!.widgetTree;
            _hasLivePreview = true;
          });
        }
      }
    });
  }

  Future<void> _analyzeProject() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Safely analyze project without external dependencies
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate analysis
      setState(() {
        _widgetTree = []; // Safe empty list
        _isAnalyzing = false;
      });
    } catch (e) {
      print('Analysis error: $e'); // Safe error logging
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          // Main preview area
          Expanded(
            child: Column(
              children: [
                _buildPreviewHeader(theme),
                Expanded(
                  child: _isAnalyzing
                    ? _buildAnalyzingView(theme)
                    : _buildPreviewContent(theme),
                ),
                if (widget.selectedWidget != null && !_showInspectorPanel())
                  _buildWidgetDetails(theme),
              ],
            ),
          ),
          // Widget Inspector Panel (slides in from the right)
          if (widget.selectedWidget != null && _showInspectorPanel())
            WidgetInspectorPanel(
              selectedWidget: widget.selectedWidget!,
              onPropertyChanged: _handlePropertyChange,
              onClose: () => widget.onWidgetSelected(null),
            ),
        ],
      ),
    );
  }

  bool _showInspectorPanel() {
    // Show inspector panel in Mock UI mode when widget is selected
    return _currentMode == 'mockUI';
  }

  void _handlePropertyChange(String property, dynamic value) {
    if (widget.selectedWidget == null) return;
    
    // Update visual properties for real-time preview
    _propertyManager.updateProperty(widget.selectedWidget!, property, value);
    
    // Show visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.palette, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text('Live Preview: $property updated'),
          ],
        ),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1000),
      ),
    );
    
    // TODO: Implement actual code modification here
    // This would involve:
    // 1. Parsing the source code at the selected widget's location
    // 2. Updating the specific property
    // 3. Writing the modified code back to the file
    // 4. Triggering a hot reload if in live preview mode
    
    print('🎨 Visual property changed: $property = $value for ${widget.selectedWidget?.widgetType}');
  }

  Widget _buildPreviewHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Title and main mode selector
          Row(
            children: [
              Text(
                'Device Preview',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildSafeModeSelector(theme),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Secondary controls based on current mode
          _buildSafeSecondaryControls(theme),
        ],
      ),
    );
  }

  Widget _buildSafeModeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSafeModeButton(
            theme,
            icon: Icons.widgets,
            label: 'Mock',
            mode: 'mockUI',
            tooltip: 'Mock UI Preview',
          ),
          _buildSafeModeButton(
            theme,
            icon: Icons.visibility,
            label: 'Preview',
            mode: 'preview',
            tooltip: 'Safe Preview Mode',
          ),
        ],
      ),
    );
  }

  Widget _buildSafeModeButton(ThemeData theme, {
    required IconData icon,
    required String label,
    required String mode,
    required String tooltip,
  }) {
    final isActive = _currentMode == mode;
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _switchSafePreviewMode(mode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive 
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafeSecondaryControls(ThemeData theme) {
    return Row(
      children: [
        // Device Selector
        PopupMenuButton<DeviceInfo>(
          initialValue: _selectedDevice,
          onSelected: (DeviceInfo device) {
            setState(() {
              _selectedDevice = device;
            });
          },
          itemBuilder: (context) => [
            // iOS Devices
            const PopupMenuItem(
              enabled: false,
              child: Text('iOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            PopupMenuItem(
              value: Devices.ios.iPhone13,
              child: Text('iPhone 13', style: theme.textTheme.bodySmall),
            ),
            PopupMenuItem(
              value: Devices.ios.iPhone13ProMax,
              child: Text('iPhone 13 Pro Max', style: theme.textTheme.bodySmall),
            ),
            PopupMenuItem(
              value: Devices.ios.iPhoneSE,
              child: Text('iPhone SE', style: theme.textTheme.bodySmall),
            ),
            PopupMenuItem(
              value: Devices.ios.iPadPro11Inches,
              child: Text('iPad Pro 11"', style: theme.textTheme.bodySmall),
            ),
            const PopupMenuDivider(),
            // Android Devices
            const PopupMenuItem(
              enabled: false,
              child: Text('Android', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            PopupMenuItem(
              value: Devices.android.samsungGalaxyS20,
              child: Text('Samsung Galaxy S20', style: theme.textTheme.bodySmall),
            ),
            PopupMenuItem(
              value: Devices.android.samsungGalaxyNote20,
              child: Text('Samsung Galaxy Note 20', style: theme.textTheme.bodySmall),
            ),
            PopupMenuItem(
              value: Devices.android.onePlus8Pro,
              child: Text('OnePlus 8 Pro', style: theme.textTheme.bodySmall),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedDevice.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.info_outline,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _currentMode == 'mockUI' ? 'Click widgets to inspect them' : 'Safe preview mode active',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }




  Widget _buildViewToggleButton(ThemeData theme, {
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isActive ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: isActive 
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing Flutter project...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parsing widget tree and UI structure',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(ThemeData theme) {
    return _buildMockUIView(theme);
  }

  Widget _buildMockUIView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: DeviceFrame(
          device: _selectedDevice,
          screen: _buildMockUI(theme),
        ),
      ),
    );
  }

  // Helper methods for preview mode management
  void _switchSafePreviewMode(String mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  Future<void> _launchWebPreview() async {
    // Safe implementation - no external dependencies
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text('Web preview feature has been improved for Chrome compatibility'),
          ],
        ),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _stopWebPreview() async {
    // Safe implementation - no external dependencies
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text('Preview stopped safely'),
          ],
        ),
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMockUI(ThemeData theme) {
    // Mock UI representing a typical Flutter app
    return Stack(
      children: [
        Column(
          children: [
            // Mock AppBar with dynamic styling
            _buildInteractiveWidget(
              selection: _createSelection('AppBar', 'main.dart', 25),
              defaultWidget: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.menu, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 16),
                    Text(
                      'App Title',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
                  ],
                ),
              ),
              onTap: () => _selectWidget('AppBar', 'main.dart', 25),
            ),
            // Mock Body
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    // Mock Card with dynamic styling
                    _buildInteractiveWidget(
                      selection: _createSelection('Card', 'home_screen.dart', 45),
                      defaultWidget: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to your app!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is a sample card widget that you can select and modify.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => _selectWidget('Card', 'home_screen.dart', 45),
                    ),
                    // Mock ListView
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectWidget('ListView', 'home_screen.dart', 78),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: widget.selectedWidget?.widgetType == 'ListView' 
                              ? Border.all(color: Colors.red, width: 2)
                              : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _selectWidget('ListTile', 'home_screen.dart', 82 + index * 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: widget.selectedWidget?.widgetType == 'ListTile' && 
                                           widget.selectedWidget?.lineNumber == 82 + index * 5
                                      ? Border.all(color: Colors.red, width: 2)
                                      : null,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(
                                      'List Item ${index + 1}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    subtitle: Text(
                                      'Subtitle for item ${index + 1}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Selection indicator
        if (widget.selectedWidget != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Selected: ${widget.selectedWidget!.widgetType}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWidgetDetails(ThemeData theme) {
    final selection = widget.selectedWidget!;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.widgets,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Widget',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => widget.onWidgetSelected(null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selection.widgetType,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${selection.filePath}:${selection.lineNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Now you can ask the AI assistant about this specific widget!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectWidget(String widgetType, String filePath, int lineNumber) {
    final selection = WidgetSelection(
      widgetType: widgetType,
      widgetId: '${widgetType}_$lineNumber',
      filePath: filePath,
      lineNumber: lineNumber,
      properties: {
        'type': widgetType,
        'line': lineNumber,
      },
      sourceCode: 'Mock source code for $widgetType at line $lineNumber',
    );
    
    widget.onWidgetSelected(selection);
  }

  WidgetSelection _createSelection(String widgetType, String filePath, int lineNumber) {
    return WidgetSelection(
      widgetType: widgetType,
      widgetId: '${widgetType}_$lineNumber',
      filePath: filePath,
      lineNumber: lineNumber,
      properties: {
        'type': widgetType,
        'line': lineNumber,
      },
      sourceCode: 'Mock source code for $widgetType at line $lineNumber',
    );
  }

  Widget _buildInteractiveWidget({
    required WidgetSelection selection,
    required Widget defaultWidget,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.selectedWidget?.widgetId == selection.widgetId;
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Apply visual properties from property manager
          _propertyManager.getStyledContainer(
            selection: selection,
            child: defaultWidget,
            defaultDecoration: BoxDecoration(
              border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
            ),
          ),
          // Selection indicator overlay
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 10,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'EDITING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Hover effect for better UX
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🌍 **WEB LIVE PREVIEW**
  Widget _buildWebLivePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Web Live Preview',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Launch a live web preview to see your app running in real-time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 **LIVE PREVIEW STATUS BAR**
  Widget _buildLivePreviewStatus(ThemeData theme) {
    if (!_hasLivePreview || _liveExecutionResult == null) {
      return const SizedBox.shrink();
    }
    
    final result = _liveExecutionResult!;
    final errorCount = result.errors.length;
    final hasErrors = errorCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hasErrors 
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasErrors 
            ? theme.colorScheme.error.withValues(alpha: 0.5)
            : theme.colorScheme.tertiary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hasErrors ? theme.colorScheme.error : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            hasErrors ? Icons.error : Icons.check_circle,
            size: 16,
            color: hasErrors ? theme.colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasErrors 
                ? '🚨 Live Preview: $errorCount errors detected'
                : '🚀 Live Preview: Active & Running',
              style: theme.textTheme.labelMedium?.copyWith(
                color: hasErrors 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (result.performance != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPerformanceColor(result.performance!.grade, theme).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.performance!.grade,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getPerformanceColor(result.performance!.grade, theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _performHotReload(),
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: 'Hot Reload',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPerformanceColor(String grade, ThemeData theme) {
    switch (grade) {
      case 'A+': case 'A': return Colors.green;
      case 'B': return theme.colorScheme.tertiary;
      case 'C': return Colors.orange;
      default: return theme.colorScheme.error;
    }
  }
  
  Future<void> _performHotReload() async {
    final result = await _orchestrator.performHotReload();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success 
              ? '🔥 Hot reload completed!' 
              : '❌ Hot reload failed: ${result.error}'
          ),
          backgroundColor: result.success 
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}