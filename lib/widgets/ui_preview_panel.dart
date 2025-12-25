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
import 'package:kre8tions/services/widget_reconstructor_service.dart';
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
  List<DeviceInfo> _selectedDevices = [
    Devices.ios.iPhone13,
    Devices.ios.iPadPro11Inches,
    Devices.android.samsungGalaxyS20,
  ];

  // 🔥 Live Execution State
  ExecutionResult? _liveExecutionResult;
  WidgetTreeNode? _liveWidgetTree;
  bool _hasLivePreview = false;
  StreamSubscription? _analysisSubscription;
  StreamSubscription? _widgetTreeSubscription;

  // 🎯 Inspect Mode & Zoom State
  bool _inspectMode = false;
  double _zoomLevel = 1.0;
  Rect? _hoveredWidgetBounds;
  String? _hoveredWidgetType;
  Offset? _lastHoverPosition;
  final List<double> _zoomPresets = [0.25, 0.5, 0.75, 1.0, 1.2, 1.5, 2.0];
  int _currentZoomIndex = 3; // 1.0 (100%)

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
        // Multiple Device Selector
        InkWell(
          onTap: () => _showDeviceSelectionDialog(theme),
          borderRadius: BorderRadius.circular(16),
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
                  Icons.devices,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_selectedDevices.length} Device${_selectedDevices.length != 1 ? 's' : ''}',
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

        // Inspect Mode Toggle
        Tooltip(
          message: 'Inspect Mode ${_inspectMode ? 'On' : 'Off'}',
          child: IconButton(
            icon: Icon(_inspectMode ? Icons.touch_app : Icons.touch_app_outlined),
            onPressed: () => setState(() => _inspectMode = !_inspectMode),
            color: _inspectMode ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            iconSize: 18,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),

        // Zoom Controls
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom out button
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'Zoom Out',
                iconSize: 14,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: _currentZoomIndex > 0
                    ? () => _changeZoom(_currentZoomIndex - 1)
                    : null,
              ),
              const SizedBox(width: 4),

              // Zoom percentage dropdown
              PopupMenuButton<int>(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                tooltip: 'Zoom Level',
                padding: EdgeInsets.zero,
                itemBuilder: (context) => _zoomPresets.asMap().entries.map((entry) {
                  return PopupMenuItem<int>(
                    value: entry.key,
                    child: Text('${(entry.value * 100).toInt()}%'),
                  );
                }).toList(),
                onSelected: _changeZoom,
              ),

              const SizedBox(width: 4),
              // Zoom in button
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Zoom In',
                iconSize: 14,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: _currentZoomIndex < _zoomPresets.length - 1
                    ? () => _changeZoom(_currentZoomIndex + 1)
                    : null,
              ),

              const SizedBox(width: 4),
              // Fit to screen button
              IconButton(
                icon: const Icon(Icons.fit_screen),
                tooltip: 'Fit to Screen (100%)',
                iconSize: 14,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _changeZoom(3), // Reset to 100%
              ),
            ],
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
            _inspectMode
              ? 'Inspect Mode: Hover to highlight, click to select'
              : (_currentMode == 'mockUI' ? 'Click widgets to inspect them' : 'Safe preview mode active'),
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
    if (_selectedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices selected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showDeviceSelectionDialog(theme),
              icon: const Icon(Icons.add),
              label: const Text('Add Devices'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _selectedDevices.map((device) {
            return Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Device label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smartphone,
                          size: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Device frame with LIVE WIDGET preview (with zoom and pan)
                  _buildZoomedAndPannablePreview(
                    DeviceFrame(
                      device: device,
                      screen: _buildInspectModeWrapper(
                        _buildLiveWidgetPreview(theme),
                        theme,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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

  /// 🎨 **BUILD LIVE WIDGET PREVIEW**
  /// Reconstructs actual Flutter widgets from WidgetTreeNode metadata
  Widget _buildLiveWidgetPreview(ThemeData theme) {
    final reconstructor = WidgetReconstructorService.instance;

    // Check if we have live execution result with widget tree
    if (_hasLivePreview && _liveExecutionResult?.widgetTree != null) {
      return reconstructor.reconstructWidget(
        _liveExecutionResult!.widgetTree!,
        theme: theme,
      );
    }

    // Demo widget tree to showcase live reconstruction when no project is loaded
    final demoTree = WidgetTreeNode(
      name: 'MaterialApp',
      type: WidgetType.app,
      line: 0,
      properties: {
        'title': 'Live Widget Demo',
        'debugShowCheckedModeBanner': false,
      },
      children: [
        WidgetTreeNode(
          name: 'Scaffold',
          type: WidgetType.layout,
          line: 0,
          properties: {},
          children: [
            WidgetTreeNode(
              name: 'AppBar',
              type: WidgetType.component,
              line: 0,
              properties: {
                'title': 'Widget Reconstruction Demo',
                'backgroundColor': '0x${theme.colorScheme.primary.toARGB32().toRadixString(16)}',
              },
              children: [],
            ),
            WidgetTreeNode(
              name: 'Center',
              type: WidgetType.layout,
              line: 0,
              properties: {},
              children: [
                WidgetTreeNode(
                  name: 'Column',
                  type: WidgetType.layout,
                  line: 0,
                  properties: {
                    'mainAxisAlignment': 'center',
                    'crossAxisAlignment': 'center',
                  },
                  children: [
                    WidgetTreeNode(
                      name: 'Icon',
                      type: WidgetType.display,
                      line: 0,
                      properties: {
                        'icon': 'widgets',
                        'size': 64.0,
                        'color': '0x${theme.colorScheme.primary.toARGB32().toRadixString(16)}',
                      },
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'SizedBox',
                      type: WidgetType.layout,
                      line: 0,
                      properties: {'height': 24.0},
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'Text',
                      type: WidgetType.display,
                      line: 0,
                      properties: {
                        'data': 'Live Widget Reconstruction',
                        'fontSize': 24.0,
                        'fontWeight': 'bold',
                        'color': '0x${theme.colorScheme.onSurface.toARGB32().toRadixString(16)}',
                      },
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'SizedBox',
                      type: WidgetType.layout,
                      line: 0,
                      properties: {'height': 16.0},
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'Text',
                      type: WidgetType.display,
                      line: 0,
                      properties: {
                        'data': 'Upload a project to see your widgets rendered live!',
                        'fontSize': 14.0,
                        'color': '0x${theme.colorScheme.onSurface.withValues(alpha: 0.7).toARGB32().toRadixString(16)}',
                      },
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'SizedBox',
                      type: WidgetType.layout,
                      line: 0,
                      properties: {'height': 32.0},
                      children: [],
                    ),
                    WidgetTreeNode(
                      name: 'ElevatedButton',
                      type: WidgetType.input,
                      line: 0,
                      properties: {
                        'text': 'Get Started',
                        'backgroundColor': '0x${theme.colorScheme.primary.toARGB32().toRadixString(16)}',
                      },
                      children: [],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return reconstructor.reconstructWidget(demoTree, theme: theme);
  }

  void _showDeviceSelectionDialog(ThemeData theme) {
    // Available devices organized by platform
    final availableDevices = [
      // iOS Devices
      {'category': 'iOS', 'devices': [
        Devices.ios.iPhone13,
        Devices.ios.iPhone13ProMax,
        Devices.ios.iPhone13Mini,
        Devices.ios.iPhoneSE,
        Devices.ios.iPadPro11Inches,
        Devices.ios.iPadAir4,
      ]},
      // Android Devices
      {'category': 'Android', 'devices': [
        Devices.android.samsungGalaxyS20,
        Devices.android.samsungGalaxyNote20,
        Devices.android.samsungGalaxyNote20Ultra,
        Devices.android.onePlus8Pro,
        Devices.android.sonyXperia1II,
      ]},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.devices, size: 24),
              const SizedBox(width: 12),
              const Text('Select Devices to Preview'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    setState(() {
                      _selectedDevices.clear();
                    });
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: availableDevices.map((category) {
                  final categoryName = category['category'] as String;
                  final devices = category['devices'] as List<DeviceInfo>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              categoryName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...devices.map((device) {
                        final isSelected = _selectedDevices.contains(device);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(
                            device.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            '${device.screenSize.width.toInt()}x${device.screenSize.height.toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              setState(() {
                                if (value == true) {
                                  _selectedDevices.add(device);
                                } else {
                                  _selectedDevices.remove(device);
                                }
                              });
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text('Apply (${_selectedDevices.length} devices)'),
            ),
          ],
        ),
      ),
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

  /// 🎯 **BUILD ZOOMED AND PANNABLE PREVIEW**
  /// Applies zoom and enables panning when zoomed > 100%
  Widget _buildZoomedAndPannablePreview(Widget preview) {
    if (_zoomLevel <= 1.0) {
      // No zoom or zoomed out - just apply scale transform
      return Transform.scale(
        scale: _zoomLevel,
        child: preview,
      );
    }

    // Zoomed in - enable panning with InteractiveViewer
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 2.0,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      child: Transform.scale(
        scale: _zoomLevel,
        child: preview,
      ),
    );
  }

  /// 🎯 **INSPECT MODE WRAPPER**
  /// Wraps the preview with inspect mode capabilities (hover detection, click to select)
  Widget _buildInspectModeWrapper(Widget preview, ThemeData theme) {
    if (!_inspectMode) {
      return preview;
    }

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _lastHoverPosition = event.position;
          // Detect widget at position (simplified for demo - would use real hit testing)
          _hoveredWidgetBounds = _detectWidgetAtPosition(event.position);
          // Set a demo widget type based on position
          _hoveredWidgetType = _getWidgetTypeAtPosition(event.position);
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredWidgetBounds = null;
          _hoveredWidgetType = null;
          _lastHoverPosition = null;
        });
      },
      child: GestureDetector(
        onTapUp: (details) {
          if (_hoveredWidgetBounds != null && _hoveredWidgetType != null) {
            // Create a widget selection from hovered widget
            final selection = WidgetSelection(
              widgetType: _hoveredWidgetType!,
              widgetId: 'inspect_${_hoveredWidgetType}_${DateTime.now().millisecondsSinceEpoch}',
              filePath: widget.selectedFile?.path ?? 'preview',
              lineNumber: 0,
              properties: {},
              sourceCode: '// Inspected widget: $_hoveredWidgetType',
            );
            widget.onWidgetSelected(selection);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: $_hoveredWidgetType'),
                duration: const Duration(milliseconds: 1000),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Stack(
          children: [
            preview,
            if (_hoveredWidgetBounds != null)
              _buildWidgetOverlay(_hoveredWidgetBounds!, _hoveredWidgetType ?? 'Widget', theme),
            if (widget.selectedWidget != null)
              _buildSelectedWidgetIndicator(widget.selectedWidget!, theme),
          ],
        ),
      ),
    );
  }

  /// 🎯 **DETECT WIDGET AT POSITION**
  /// Simplified widget detection for demo purposes
  /// In production, this would use RenderBox hit testing
  Rect? _detectWidgetAtPosition(Offset position) {
    // Simplified: Create a mock bounding box around the hover position
    // In real implementation, would traverse the widget tree and use RenderBox.globalPaintBounds
    final mockSize = 100.0;
    return Rect.fromLTWH(
      position.dx - mockSize / 2,
      position.dy - mockSize / 2,
      mockSize,
      mockSize,
    );
  }

  /// 🎯 **GET WIDGET TYPE AT POSITION**
  /// Returns a widget type based on hover position (demo implementation)
  /// In production, would use actual widget tree traversal
  String _getWidgetTypeAtPosition(Offset position) {
    // Demo: Return different widget types based on Y position
    final y = position.dy;
    if (y < 100) return 'AppBar';
    if (y < 200) return 'Text';
    if (y < 300) return 'Container';
    if (y < 400) return 'Column';
    if (y < 500) return 'Row';
    if (y < 600) return 'ElevatedButton';
    return 'Widget';
  }

  /// 🎯 **BUILD WIDGET OVERLAY**
  /// Shows boundary and metadata for hovered widget
  Widget _buildWidgetOverlay(Rect bounds, String widgetType, ThemeData theme) {
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              width: 2,
              style: BorderStyle.solid,
            ),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Stack(
            children: [
              // Widget type badge
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: theme.colorScheme.primary,
                  child: Text(
                    widgetType,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Size dimensions
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Text(
                    '${bounds.width.toInt()} × ${bounds.height.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 **BUILD SELECTED WIDGET INDICATOR**
  /// Shows blue outline for currently selected widget
  Widget _buildSelectedWidgetIndicator(WidgetSelection selection, ThemeData theme) {
    // For demo purposes, create a centered indicator
    // In production, would calculate actual bounds from widget tree
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Breadcrumb at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBreadcrumb(selection, theme),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 **BUILD BREADCRUMB**
  /// Shows widget path hierarchy
  Widget _buildBreadcrumb(WidgetSelection selection, ThemeData theme) {
    // Simplified: Show single widget type
    // In production, would traverse up the widget tree
    final path = ['Scaffold', 'Column', selection.widgetType];

    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: path.asMap().entries.map((entry) {
          final isLast = entry.key == path.length - 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value,
                style: TextStyle(
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  color: isLast ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
              if (!isLast) const Icon(Icons.chevron_right, size: 14),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 🎯 **CHANGE ZOOM LEVEL**
  void _changeZoom(int index) {
    setState(() {
      _currentZoomIndex = index;
      _zoomLevel = _zoomPresets[index];
    });
  }
}