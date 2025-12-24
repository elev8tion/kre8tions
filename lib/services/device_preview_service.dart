import 'package:flutter/material.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/utils/logger.dart';

enum PreviewMode {
  mockUI,      // Current mock UI approach
  deviceSim,   // Device simulation with device_preview
  webLive,     // Live web browser target
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  web,
}

class DevicePreviewService {
  static final DevicePreviewService _instance = DevicePreviewService._internal();
  factory DevicePreviewService() => _instance;
  DevicePreviewService._internal();

  PreviewMode _currentMode = PreviewMode.mockUI;
  DeviceType _currentDevice = DeviceType.mobile;
  String? _webPreviewUrl;

  PreviewMode get currentMode => _currentMode;
  DeviceType get currentDevice => _currentDevice;
  String? get webPreviewUrl => _webPreviewUrl;

  // Available device configurations for simulation
  List<DeviceInfo> get availableDevices => [
    Devices.ios.iPhone13,
    Devices.ios.iPhone13ProMax,
    Devices.ios.iPhone13Mini,
    Devices.ios.iPadPro11Inches,
    Devices.android.samsungGalaxyS20,
    Devices.android.samsungGalaxyNote20,
    Devices.android.samsungGalaxyA50,
    Devices.android.onePlus8Pro,
    Devices.android.samsungGalaxyA50, // Using A50 as tablet substitute
    Devices.linux.laptop,
    Devices.macOS.macBookPro,
    Devices.windows.laptop,
  ];

  // Get devices by type
  List<DeviceInfo> getDevicesByType(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return availableDevices.where((d) => 
          d.name.contains('iPhone') || 
          (d.name.contains('Galaxy') && !d.name.contains('Tab')) ||
          d.name.contains('OnePlus')).toList();
      case DeviceType.tablet:
        return availableDevices.where((d) => 
          d.name.contains('iPad') || 
          d.name.contains('Tab')).toList();
      case DeviceType.desktop:
        return availableDevices.where((d) => 
          d.name.contains('laptop') || 
          d.name.contains('MacBook')).toList();
      case DeviceType.web:
        return []; // Web uses browser, not device simulation
    }
  }

  void setPreviewMode(PreviewMode mode) {
    _currentMode = mode;
  }

  void setDeviceType(DeviceType type) {
    _currentDevice = type;
  }

  // Launch web preview in new browser tab/window
  Future<bool> launchWebPreview(FlutterProject project) async {
    try {
      // In a real implementation, this would:
      // 1. Start a Flutter web development server
      // 2. Compile the project for web
      // 3. Launch the browser with the local server URL
      
      // For now, we simulate this with a placeholder URL
      const webUrl = 'http://localhost:8080'; // This would be the actual dev server
      _webPreviewUrl = webUrl;
      
      final Uri url = Uri.parse(webUrl);
      
      // Launch in new browser tab/window
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      Logger.error('Failed to launch web preview', e);
      return false;
    }
  }

  // Stop web preview server
  Future<void> stopWebPreview() async {
    _webPreviewUrl = null;
    // In a real implementation, this would stop the dev server
  }

  // Generate Flutter web build command
  String getWebBuildCommand(FlutterProject project) {
    return 'flutter run -d chrome --web-port=8080 --web-hostname=localhost';
  }

  // Generate device-specific run command
  String getDeviceRunCommand(FlutterProject project, DeviceInfo device) {
    // This would generate the appropriate Flutter run command for the device
    return 'flutter run -d ${device.name.toLowerCase().replaceAll(' ', '-')}';
  }

  // Simulate hot reload for web preview
  Future<bool> triggerHotReload() async {
    if (_webPreviewUrl == null) return false;

    // In a real implementation, this would send hot reload command to dev server
    // For now, we simulate it
    Logger.info('Hot reload triggered for $_webPreviewUrl');
    return true;
  }

  // Simulate hot restart for web preview
  Future<bool> triggerHotRestart() async {
    if (_webPreviewUrl == null) return false;

    // In a real implementation, this would send hot restart command to dev server
    Logger.info('Hot restart triggered for $_webPreviewUrl');
    return true;
  }

  // Check if web preview is running
  bool get isWebPreviewRunning => _webPreviewUrl != null;

  // Get appropriate preview widget based on current mode
  Widget buildPreviewWidget(
    BuildContext context,
    FlutterProject project, {
    Widget? mockUI,
    DeviceInfo? selectedDevice,
  }) {
    switch (_currentMode) {
      case PreviewMode.mockUI:
        return mockUI ?? const SizedBox.shrink();
        
      case PreviewMode.deviceSim:
        return _buildDeviceSimulation(context, project, selectedDevice);
        
      case PreviewMode.webLive:
        return _buildWebLivePreview(context, project);
    }
  }

  Widget _buildDeviceSimulation(
    BuildContext context, 
    FlutterProject project, 
    DeviceInfo? device
  ) {
    final selectedDevice = device ?? availableDevices.first;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Device selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedDevice.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedDevice.screenSize.width.toInt()} × ${selectedDevice.screenSize.height.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Device frame simulation
          Expanded(
            child: Center(
              child: Container(
                width: selectedDevice.screenSize.width * 0.3,
                height: selectedDevice.screenSize.height * 0.3,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    selectedDevice.name.contains('iPhone') ? 25 : 16,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      selectedDevice.name.contains('iPhone') ? 21 : 12,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      selectedDevice.name.contains('iPhone') ? 21 : 12,
                    ),
                    child: _buildSimulatedApp(context, selectedDevice),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLivePreview(BuildContext context, FlutterProject project) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Web preview controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.web,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isWebPreviewRunning ? 'Web Preview Running' : 'Web Preview Stopped',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isWebPreviewRunning) ...[
                  IconButton(
                    onPressed: triggerHotReload,
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Hot Reload',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: Size.zero,
                    ),
                  ),
                  IconButton(
                    onPressed: triggerHotRestart,
                    icon: const Icon(Icons.restart_alt, size: 16),
                    tooltip: 'Hot Restart',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Web preview frame
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isWebPreviewRunning
                    ? _buildWebPreviewFrame(context)
                    : _buildWebPreviewPlaceholder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedApp(BuildContext context, DeviceInfo device) {
    // This would render the actual app in device simulation
    // For now, we show a placeholder
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Status bar simulation
          Container(
            height: 30,
            color: Colors.black,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '9:41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 12),
                      SizedBox(width: 2),
                      Icon(Icons.wifi, color: Colors.white, size: 12),
                      SizedBox(width: 2),
                      Icon(Icons.battery_full, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // App content simulation
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Device Simulation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Live Flutter app will\nrender here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPreviewFrame(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Live Web Preview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Running at $_webPreviewUrl',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Flutter app is running\nlive in the browser',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPreviewPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Web Preview Not Started',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Launch Web Preview" to start',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}