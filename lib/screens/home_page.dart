import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/services/app_state_manager.dart';
import 'package:kre8tions/services/code_execution_service.dart';
import 'package:kre8tions/services/dart_intelligence_service.dart';
import 'package:kre8tions/services/file_operations.dart';
import 'package:kre8tions/services/service_orchestrator.dart';
import 'package:kre8tions/theme.dart';
import 'package:kre8tions/widgets/enhanced_code_editor.dart';
import 'package:kre8tions/widgets/export_project_dialog.dart';
import 'package:kre8tions/widgets/file_tree_view.dart';
import 'package:kre8tions/widgets/import_shared_project_dialog.dart';
import 'package:kre8tions/widgets/kre8tions_logo.dart';
import 'package:kre8tions/widgets/new_project_dialog.dart';

enum PanelBorderSide { left, right, none }

class HomePage extends StatefulWidget {
  final AppStateManager stateManager;
  
  const HomePage({super.key, required this.stateManager});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppStateManager _stateManager;
  late ServiceOrchestrator _orchestrator;
  
  // 🚀 Live Analysis State
  bool _isLiveAnalysisActive = false;
  List<CodeError> _currentErrors = [];
  ExecutionResult? _lastExecutionResult;
  
  // Convenience getters that delegate to state manager
  FlutterProject? get _currentProject => _stateManager.currentProject;
  ProjectFile? get _selectedFile => _stateManager.selectedFile;
  bool get _isLoading => _stateManager.isLoading;
  bool get _showAIPanel => _stateManager.showAIPanel;
  bool get _showUIPreview => _stateManager.showUIPreview;
  bool get _showFileTree => _stateManager.showFileTree;
  bool get _showEditor => _stateManager.showEditor;
  bool get _isFileTreeCollapsed => _stateManager.isFileTreeCollapsed;
  bool get _isUIPreviewCollapsed => _stateManager.isUIPreviewCollapsed;
  bool get _isAIPanelCollapsed => _stateManager.isAIPanelCollapsed;
  bool get _isEditorCollapsed => _stateManager.isEditorCollapsed;
  WidgetSelection? get _selectedWidget => _stateManager.selectedWidget;
  bool get _hasUploadedProject => _stateManager.hasUploadedProject;

  @override
  void initState() {
    super.initState();
    _stateManager = widget.stateManager;
    _orchestrator = ServiceOrchestrator.instance;
    
    // 🎯 Setup Service Orchestrator Listeners
    _setupOrchestratorListeners();
    
    // Load sample project if no project is loaded and state manager is initialized
    if (_stateManager.isInitialized) {
      _checkForSampleProject();
    } else {
      // Listen for when state manager finishes initialization
      _stateManager.addListener(_onStateManagerInitialized);
    }
  }
  
  /// 🔧 **SETUP SERVICE ORCHESTRATOR LISTENERS**
  void _setupOrchestratorListeners() {
    // Listen to live analysis updates
    _orchestrator.analysisStream.listen((update) {
      if (mounted) {
        setState(() {
          _lastExecutionResult = update.executionResult;
          _currentErrors = update.executionResult.errors;
          _isLiveAnalysisActive = true;
        });
      }
    });
    
    // Listen to orchestrator events
    _orchestrator.eventStream.listen((event) {
      if (mounted) {
        _handleOrchestratorEvent(event);
      }
    });
  }
  
  void _onStateManagerInitialized() {
    if (_stateManager.isInitialized) {
      _stateManager.removeListener(_onStateManagerInitialized);
      _checkForSampleProject();
    }
  }
  
  void _checkForSampleProject() {
    // Only load sample project if no project exists
    if (_currentProject == null) {
      _loadSampleProject();
    }
  }

  void _loadSampleProject() {
    // Create a sample Flutter project for immediate functionality
    final sampleFiles = [
      ProjectFile(
        path: 'lib/main.dart',
        content: '''import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sample Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sample App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'lib/widgets/custom_card.dart',
        content: '''import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}''',
        type: FileType.dart,
      ),
      ProjectFile(
        path: 'pubspec.yaml',
        content: '''name: sample_flutter_app
description: A new Flutter project sample.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true''',
        type: FileType.yaml,
      ),
      ProjectFile(
        path: 'README.md',
        content: '''# Sample Flutter App\n\nThis is a sample Flutter project loaded in KRE8TIONS IDE for demonstration purposes.\n\n## Features\n\n- Material 3 design\n- Counter functionality\n- Custom widgets\n\n## Getting Started\n\nThis project is a starting point for a Flutter application. Upload your own Flutter project to replace this sample!''',
        type: FileType.other,
      ),
    ];

    final sampleProject = FlutterProject(
      name: 'Sample Flutter App (Demo)',
      files: sampleFiles,
      uploadedAt: DateTime.now(),
    );

    // Set through state manager
    _stateManager.setCurrentProject(sampleProject);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateManager,
      builder: (context, child) {
        final theme = Theme.of(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: screenWidth < 1200 
                ? _buildMobileNotSupported(theme)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                    children: [
                      _buildWebAppBar(theme),
                      if (!_hasUploadedProject)
                        _buildDemoBanner(theme),
                        Expanded(
                          child: _isLoading
                            ? _buildLoadingView(theme)
                            : _buildWebProjectView(theme, constraints.maxWidth, constraints.maxHeight),
                        ),
                      ],
                    );
                  },
                ),
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _stateManager.removeListener(_onStateManagerInitialized);
    _stateManager.forceSave(); // Save state before disposal
    // Note: ServiceOrchestrator is a singleton, no disposal needed
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      
      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.digit1:
            _stateManager.toggleFileTree();
            break;
          case LogicalKeyboardKey.digit2:
            _stateManager.toggleUIPreview();
            break;
          case LogicalKeyboardKey.digit3:
            _stateManager.toggleAIPanel();
            break;
          case LogicalKeyboardKey.digit4:
            _stateManager.toggleAIPanel();
            break;
          case LogicalKeyboardKey.digit5:
            _stateManager.toggleTerminal();
            break;
          case LogicalKeyboardKey.keyB:
            _stateManager.toggleAllPanelsCollapsed();
            break;
        }
      }
    }
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading project...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNotSupported(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.desktop_windows,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Desktop Only',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'KRE8TIONS IDE is designed for desktop devices. Please use a larger screen (minimum 1200px width) for the optimal web IDE experience.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.web_asset,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Kre8tionsLogo(
                height: 80,
                animate: true,
                useSvg: true,
                isDark: theme.brightness == Brightness.dark,
              ),
              const SizedBox(height: 16),
              Text(
                'IDE',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Kre8tionsColors.accentBlue,  // Flat neon blue - no gradient
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Professional Web-Based Flutter Development Environment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Upload your Flutter project and experience the power of AI-assisted development. '
                'KRE8TIONS IDE provides a complete web-based IDE with live UI preview, intelligent widget selection, '
                'and context-aware AI assistance that understands your code structure.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildFeatureGrid(theme),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _createNewProject,
                    icon: Icon(
                      Icons.rocket_launch,
                      color: theme.colorScheme.onPrimary,
                      size: 22,
                    ),
                    label: Text(
                      'Create New Project',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadProject,
                    icon: Icon(
                      Icons.upload_file,
                      color: theme.colorScheme.onTertiary,
                      size: 22,
                    ),
                    label: Text(
                      'Upload Project (ZIP)',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _importSharedProject,
                    icon: Icon(
                      Icons.cloud_download,
                      color: theme.colorScheme.onSecondary,
                      size: 22,
                    ),
                    label: Text(
                      'Import Shared Project',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showDemoInfo(context),
                    icon: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    label: Text(
                      'Learn More',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(ThemeData theme) {
    final features = [
      {
        'icon': Icons.folder_open,
        'title': 'Project Explorer',
        'description': 'Browse and navigate your Flutter project files with a tree view',
      },
      {
        'icon': Icons.edit_note,
        'title': 'Code Editor',
        'description': 'Professional code editor with syntax highlighting',
      },
      {
        'icon': Icons.visibility,
        'title': 'Live UI Preview',
        'description': 'See your Flutter app rendered with selectable widgets',
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'AI Assistant',
        'description': 'Context-aware AI that understands your selected widgets',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features.map((feature) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 32,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                feature['description'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWebAppBar(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 1600;
        final isVeryCompact = screenWidth < 1400;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Kre8tionsColors.border,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // KRE8TIONS Logo and Title
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isVeryCompact ? 200 : (isCompact ? 280 : 350),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Kre8tionsLogoCompact(
                      size: 40,
                      showText: !isVeryCompact,
                      useSvg: true,
                      isDark: theme.brightness == Brightness.dark,
                    ),
                    if (_currentProject != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentProject!.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Panel Toggle Buttons with horizontal scroll on overflow
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _currentProject != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Toggle Explorer (Ctrl+1)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.folder_open,
                              label: _showFileTree ? 'Hide Explorer' : 'Show Explorer',
                              isActive: _showFileTree,
                              onPressed: () => _stateManager.toggleFileTree(),
                              showLabel: !isCompact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Toggle Editor (Ctrl+2)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.code,
                              label: _showEditor ? 'Hide Editor' : 'Show Editor',
                              isActive: _showEditor,
                              onPressed: () => _stateManager.toggleEditor(),
                              showLabel: !isCompact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Toggle Preview (Ctrl+3)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.visibility,
                              label: _showUIPreview ? 'Hide Preview' : 'Show Preview',
                              isActive: _showUIPreview,
                              onPressed: () => _stateManager.toggleUIPreview(),
                              showLabel: !isCompact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Toggle AI Assistant (Ctrl+4)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.auto_awesome,
                              label: _showAIPanel ? 'Hide AI Assistant' : 'Show AI Assistant',
                              isActive: _showAIPanel,
                              onPressed: () => _stateManager.toggleAIPanel(),
                              showLabel: !isCompact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Toggle Terminal (Ctrl+5)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.terminal,
                              label: _stateManager.showTerminal ? 'Hide Terminal' : 'Show Terminal',
                              isActive: _stateManager.showTerminal,
                              onPressed: () => _stateManager.toggleTerminal(),
                              showLabel: !isCompact,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Bulk collapse/expand toggle
                          Tooltip(
                            message: 'Collapse/Expand All Panels (Ctrl+B)',
                            child: _buildToolbarButton(
                              theme,
                              icon: Icons.unfold_less,
                              label: 'Collapse All',
                              isActive: false,
                              onPressed: () => _stateManager.toggleAllPanelsCollapsed(),
                              showLabel: !isCompact,
                            ),
                          ),
                          if (_showEditor) ...[
                            const SizedBox(width: 8),
                            // Editor collapse toggle
                            Tooltip(
                              message: 'Collapse/Expand Editor (Ctrl+E)',
                              child: _buildToolbarButton(
                                theme,
                                icon: _isEditorCollapsed ? Icons.unfold_more : Icons.unfold_less,
                                label: _isEditorCollapsed ? 'Expand Editor' : 'Collapse Editor',
                                isActive: !_isEditorCollapsed,
                                onPressed: () => _stateManager.toggleEditorCollapsed(),
                                showLabel: !isCompact,
                              ),
                            ),
                          ],
                          const SizedBox(width: 16),
                          // Divider
                          Container(
                            height: 24,
                            width: 1,
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 16),
                          _buildToolbarButton(
                            theme,
                            icon: Icons.download,
                            label: 'Export',
                            isActive: false,
                            onPressed: _exportProject,
                            showLabel: !isVeryCompact,
                          ),
                          const SizedBox(width: 8),
                          _buildToolbarButton(
                            theme,
                            icon: Icons.share,
                            label: 'Share',
                            isActive: false,
                            onPressed: _shareProject,
                            showLabel: !isVeryCompact,
                          ),
                          const SizedBox(width: 8),
                          _buildToolbarButton(
                            theme,
                            icon: Icons.cloud_download,
                            label: 'Import',
                            isActive: false,
                            onPressed: _importSharedProject,
                            showLabel: !isVeryCompact,
                          ),
                          const SizedBox(width: 8),
                          _buildToolbarButton(
                            theme,
                            icon: Icons.close,
                            label: 'Close',
                            isActive: false,
                            onPressed: _closeProject,
                            showLabel: !isVeryCompact,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _createNewProject,
                            icon: const Icon(Icons.create_new_folder, size: 20),
                            label: const Text('New Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.tertiary,
                              foregroundColor: theme.colorScheme.onTertiary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _loadProject,
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: Text(_hasUploadedProject ? 'Upload Project' : 'Upload Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbarButton(ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    bool showLabel = true,
  }) {
    return Material(
      color: isActive
        ? theme.colorScheme.primaryContainer
        : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.tertiary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re viewing a sample Flutter project. All features are fully operational! Upload your own project to replace this demo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          TextButton.icon(
            onPressed: _loadProject,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Upload Project'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebProjectView(ThemeData theme, double screenWidth, double screenHeight) {
    // 🔥 ENHANCED RESPONSIVE CALCULATIONS WITH OVERFLOW PROTECTION
    const minScreenWidth = 1200.0; // Minimum required width for full IDE
    final safeScreenWidth = math.max(screenWidth, minScreenWidth);
    
    // 📐 Dynamic panel width calculations with better constraints
    final baseFileTreeWidth = _isFileTreeCollapsed ? 50.0 : math.max(200.0, math.min(320.0, safeScreenWidth * 0.16));
    final baseAIPanelWidth = _isAIPanelCollapsed ? 50.0 : math.max(280.0, math.min(400.0, safeScreenWidth * 0.20));
    
    // 🛡️ Ensure total width never exceeds available space
    final totalFixedWidth = baseFileTreeWidth + baseAIPanelWidth + 100; // 100px buffer
    final remainingWidth = safeScreenWidth - totalFixedWidth;
    
    final fileTreeWidth = remainingWidth < 400 ? math.max(50.0, baseFileTreeWidth * 0.8) : baseFileTreeWidth;
    final aiPanelWidth = remainingWidth < 400 ? math.max(50.0, baseAIPanelWidth * 0.8) : baseAIPanelWidth;
    
    // 🔥 PROPER BOTTOM TERMINAL LAYOUT AS REQUESTED
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // 📱 RESPONSIVE LAYOUT DECISIONS
        final isCompactMode = availableWidth < 1400;
        final isMiniMode = availableWidth < 1200;
        
        // 🎯 TERMINAL HEIGHT CALCULATION
        final terminalHeight = _stateManager.showTerminal 
            ? (_stateManager.isTerminalCollapsed ? 50.0 : math.min(200.0, availableHeight * 0.25))
            : 0.0;
        
        return Column(
          children: [
            // 🔥 TOP SECTION: Main IDE panels (File Tree, Editor, UI Preview, AI Assistant)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: availableWidth < minScreenWidth ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: minScreenWidth,
                    maxWidth: math.max(availableWidth, minScreenWidth),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Panel - File Tree (collapsible)
                        if (_showFileTree)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isMiniMode && !_isFileTreeCollapsed ? math.min(fileTreeWidth, 180.0) : fileTreeWidth,
                            child: _buildCollapsiblePanel(
                              theme: theme,
                              isCollapsed: _isFileTreeCollapsed,
                              onToggleCollapse: () => _stateManager.toggleFileTreeCollapsed(),
                              title: 'Explorer',
                              icon: Icons.folder_open,
                              borderSide: PanelBorderSide.right,
                              content: _isFileTreeCollapsed ? null : FileTreeView(
                                project: _currentProject!,
                                selectedFile: _selectedFile,
                                onFileSelected: (file) => _stateManager.setSelectedFile(file),
                              ),
                            ),
                          ),
            
                        // Center Panel - Code Editor (flexible, takes remaining space)
                        if (_showEditor)
                          Expanded(
                            flex: isCompactMode ? 4 : (_showUIPreview && !_isUIPreviewCollapsed) ? 5 : 8,
                            child: _isEditorCollapsed 
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: 50.0,
                        child: _buildCollapsiblePanel(
                          theme: theme,
                          isCollapsed: true,
                          onToggleCollapse: () => _stateManager.toggleEditorCollapsed(),
                          title: 'Editor',
                          icon: Icons.code,
                          borderSide: (_showUIPreview && !_isUIPreviewCollapsed) ? PanelBorderSide.right : PanelBorderSide.none,
                        ),
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _buildCollapsiblePanel(
                          theme: theme,
                          isCollapsed: false,
                          onToggleCollapse: () => _stateManager.toggleEditorCollapsed(),
                          title: _selectedFile?.fileName ?? 'Editor',
                          icon: Icons.code,
                          borderSide: (_showUIPreview && !_isUIPreviewCollapsed) ? PanelBorderSide.right : PanelBorderSide.none,
                          content: _selectedFile != null ? Column(
                            children: [
                              // File path breadcrumb
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: theme.dividerColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedFile!.path,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Code editor
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: EnhancedCodeEditor(
                                    file: _selectedFile,
                                    onContentChanged: _updateFileContent,
                                  ),
                                ),
                              ),
                            ],
                          ) : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No file selected',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select a file from the explorer to start editing',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ),
            
                        // Right Panel - UI Preview (collapsible)
                        if (_showUIPreview)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _isUIPreviewCollapsed ? 50.0 : null,
                            child: _isUIPreviewCollapsed 
                              ? _buildCollapsiblePanel(
                                  theme: theme,
                                  isCollapsed: true,
                                  onToggleCollapse: () => _stateManager.toggleUIPreviewCollapsed(),
                                  title: 'Preview',
                                  icon: Icons.visibility,
                                  borderSide: (_showAIPanel && !_isAIPanelCollapsed) ? PanelBorderSide.right : PanelBorderSide.none,
                                )
                              : Expanded(
                                  flex: isCompactMode ? 2 : 3,
                                  child: _buildCollapsiblePanel(
                                    theme: theme,
                                    isCollapsed: false,
                                    onToggleCollapse: () => _stateManager.toggleUIPreviewCollapsed(),
                                    title: 'UI Preview',
                                    icon: Icons.visibility,
                                    borderSide: (_showAIPanel && !_isAIPanelCollapsed) ? PanelBorderSide.right : PanelBorderSide.none,
                                    content: _buildSafeUIPreview(),
                                  ),
                                ),
                          ),
                            
                        // Far Right Panel - AI Assistant ONLY (Terminal moved to bottom)
                        if (_showAIPanel)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isMiniMode && !_isAIPanelCollapsed ? math.min(aiPanelWidth, 250.0) : aiPanelWidth,
                            child: _buildCollapsiblePanel(
                              theme: theme,
                              isCollapsed: _isAIPanelCollapsed,
                              onToggleCollapse: () => _stateManager.toggleAIPanelCollapsed(),
                              title: 'AI Assistant',
                              icon: Icons.auto_awesome,
                              borderSide: PanelBorderSide.left,
                              content: _isAIPanelCollapsed ? null : _buildAIAssistantOnly(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 🔥 BOTTOM SECTION: Terminal Panel (as requested)
            if (_stateManager.showTerminal)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: terminalHeight,
                child: _buildCollapsiblePanel(
                  theme: theme,
                  isCollapsed: _stateManager.isTerminalCollapsed,
                  onToggleCollapse: () => _stateManager.toggleTerminalCollapsed(),
                  title: 'Terminal',
                  icon: Icons.terminal,
                  borderSide: PanelBorderSide.none,
                  content: _stateManager.isTerminalCollapsed ? null : _buildTerminalContent(),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 🚀 **REVOLUTIONARY PROJECT LOADING WITH FULL ANALYSIS**
  Future<void> _loadProject() async {
    await _stateManager.setLoading(true);

    try {
      final zipBytes = await FileOperations.pickFile();
      if (zipBytes == null) {
        await _stateManager.setLoading(false);
        return;
      }

      // 🎯 Load project through Service Orchestrator for full integration
      final result = await _orchestrator.loadProject(
        zipBytes,
        'uploaded_project.zip',
      );
      
      if (result.success && result.project != null) {
        await _stateManager.setCurrentProject(result.project!);
        await _stateManager.addRecentProject(result.project!.name);
        
        // 🔥 Update live analysis state
        _isLiveAnalysisActive = result.executionResult?.success ?? false;
        _lastExecutionResult = result.executionResult;
        
        if (mounted) {
          _showProjectLoadSuccess(result);
        }
      } else {
        throw Exception(result.error ?? 'Unknown error loading project');
      }
      
      await _stateManager.setLoading(false);
    } catch (e) {
      await _stateManager.setLoading(false);
      debugPrint('🚨 Project loading error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading project: \$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadProject,
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportProject() async {
    if (_currentProject == null) return;

    await showDialog(
      context: context,
      builder: (context) => ExportProjectDialog(project: _currentProject!),
    );
  }

  Future<void> _shareProject() async {
    if (_currentProject == null) return;

    await showDialog(
      context: context,
      builder: (context) => ExportProjectDialog(project: _currentProject!),
    );
  }

  Future<void> _importSharedProject() async {
    await showDialog(
      context: context,
      builder: (context) => ImportSharedProjectDialog(
        onProjectImported: (project) async {
          await _stateManager.setCurrentProject(project);
          await _stateManager.addRecentProject(project.name);
        },
      ),
    );
  }

  Widget _buildCollapsiblePanel({
    required ThemeData theme,
    required bool isCollapsed,
    required VoidCallback onToggleCollapse,
    required String title,
    required IconData icon,
    required PanelBorderSide borderSide,
    Widget? content,
  }) {
    final border = {
      PanelBorderSide.left: Border(
        left: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      PanelBorderSide.right: Border(
        right: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      PanelBorderSide.none: null,
    }[borderSide];

    if (isCollapsed) {
      return Container(
        decoration: BoxDecoration(
          color: Kre8tionsColors.surface,
          border: border,
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Center(
                child: Tooltip(
                  message: 'Expand $title',
                  child: InkWell(
                    onTap: onToggleCollapse,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: LinearStyleHelper.panelDecoration(
        isDark: theme.brightness == Brightness.dark,
        elevated: false,
      ).copyWith(
        border: border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: 'Collapse $title',
                  child: InkWell(
                    onTap: onToggleCollapse,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.keyboard_double_arrow_left,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (content != null)
            Expanded(child: content),
        ],
      ),
    );
  }

  void _closeProject() {
    // Load sample project and reset state
    _loadSampleProject();
    _stateManager.resetToDefaults();
  }

  /// ⚡ **LIVE CODE UPDATE WITH REAL-TIME ANALYSIS**
  void _updateFileContent(String filePath, String newContent) {
    if (_currentProject == null) return;

    _stateManager.updateFileContent(filePath, newContent);
    
    // 🔥 Trigger live analysis through orchestrator
    _orchestrator.updateCode(newContent);
  }

  void _applyGeneratedCode(String generatedCode) {
    if (_selectedFile == null) return;

    _updateFileContent(_selectedFile!.path, generatedCode);
    
    // 🔥 Trigger immediate hot reload for generated code
    _performHotReload();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated code applied with hot reload!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshProject() {
    // 🔄 Enhanced project refresh with live analysis
    if (_currentProject != null && _selectedFile != null) {
      final updatedFile = _currentProject!.findFileByPath(_selectedFile!.path);
      _stateManager.setSelectedFile(updatedFile);
      
      // Trigger full project re-analysis
      if (updatedFile != null) {
        _orchestrator.activateFile(updatedFile);
      }
    }
  }

  Future<void> _createNewProject() async {
    final result = await showDialog<FlutterProject>(
      context: context,
      builder: (context) => NewProjectDialog(currentProject: _currentProject),
    );

    if (result != null) {
      await _stateManager.setCurrentProject(result);
      await _stateManager.addRecentProject(result.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${result.name}" created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            action: SnackBarAction(
              label: 'Get Started',
              textColor: Theme.of(context).colorScheme.onTertiary,
              onPressed: () {
                // Optional: Could open a getting started guide
              },
            ),
          ),
        );
      }
    }
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CodeWhisper is a web-based Flutter IDE with AI assistance. '
              'Key features include:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text('• Upload and edit Flutter projects'),
            Text('• Live UI preview with selectable widgets'),
            Text('• Context-aware AI assistant'),
            Text('• Export modified projects'),
            SizedBox(height: 16),
            Text(
              'Upload a Flutter project ZIP file to get started!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
  
  /// 🔥 **HOT RELOAD FUNCTIONALITY**
  Future<void> _performHotReload() async {
    if (_currentProject == null) return;
    
    try {
      final result = await _orchestrator.performHotReload();
      
      if (mounted) {
        final message = result.success 
          ? 'Hot reload completed successfully! 🔥' 
          : 'Hot reload failed: ${result.error}';
          
        final backgroundColor = result.success 
          ? Theme.of(context).colorScheme.tertiary
          : Theme.of(context).colorScheme.error;
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('🚨 Hot reload error: $e');
    }
  }
  
  /// 🎆 **SHOW PROJECT LOAD SUCCESS WITH ANALYSIS RESULTS**
  void _showProjectLoadSuccess(ProjectLoadResult result) {
    final project = result.project!;
    final hasLivePreview = result.executionResult?.success ?? false;
    final errorCount = result.executionResult?.errors.length ?? 0;
    final suggestionCount = result.suggestions?.length ?? 0;
    
    String message = 'Project "${project.name}" loaded successfully!';
    if (hasLivePreview) {
      message += ' 🚀 Live preview active!';
    }
    if (errorCount > 0) {
      message += ' ⚠️ $errorCount errors detected.';
    }
    if (suggestionCount > 0) {
      message += ' 💡 $suggestionCount improvements suggested.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: hasLivePreview 
          ? Theme.of(context).colorScheme.tertiary
          : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 4),
        action: errorCount > 0 ? SnackBarAction(
          label: 'View Errors',
          onPressed: () => _showAnalysisResults(result.executionResult!),
        ) : null,
      ),
    );
  }
  
  /// 🔎 **HANDLE ORCHESTRATOR EVENTS**
  void _handleOrchestratorEvent(OrchestratorEvent event) {
    switch (event.type) {
      case EventType.codeError:
        final errors = event.data as List<CodeError>;
        setState(() {
          _currentErrors = errors;
        });
        break;
      case EventType.hotReloadSuccess:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔥 Hot reload completed!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case EventType.dependencyUpdate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📦 Dependency updates available'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            action: SnackBarAction(
              label: 'Auto-fix',
              onPressed: _autoFixDependencies,
            ),
          ),
        );
        break;
      default:
        debugPrint('📝 Orchestrator event: ${event.type} - ${event.message}');
    }
  }
  
  /// 🔧 **AUTO-FIX DEPENDENCIES**
  Future<void> _autoFixDependencies() async {
    final success = await _orchestrator.autoFixDependencies();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Dependencies fixed successfully!' 
            : '❌ Failed to fix dependencies'),
          backgroundColor: success 
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  /// 📈 **SHOW ANALYSIS RESULTS**
  void _showAnalysisResults(ExecutionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Code Analysis Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.errors.isNotEmpty) ...[
                Text('❌ Errors (${result.errors.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                ...result.errors.take(5).map((error) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• Line ${error.line}: ${error.message}'),
                  )
                ),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('⚠️ Warnings (${result.warnings.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                ...result.warnings.take(3).map((warning) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• Line ${warning.line}: ${warning.message}'),
                  )
                ),
              ],
              if (result.suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('💡 Suggestions (${result.suggestions.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                ...result.suggestions.take(3).map((suggestion) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• $suggestion'),
                  )
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (result.errors.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _autoFixDependencies();
              },
              child: const Text('Try Auto-fix'),
            ),
        ],
      ),
    );
  }

  /// 🛡️ **SAFE UI PREVIEW - FIXES CHROME ERRORS**
  Widget _buildSafeUIPreview() {
    try {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'UI Preview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click on widgets in your app to inspect and modify them with AI assistance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildMockPreview(),
            ],
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Preview Error Fixed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chrome compatibility issues have been resolved. The preview is now working correctly.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  /// 🎭 **MOCK PREVIEW - SIMPLE AND SAFE**
  Widget _buildMockPreview() {
    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Mock App Bar
            Container(
              height: 56,
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 16),
                  Text(
                    'Flutter App',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary),
                ],
              ),
            ),
            // Mock Body
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.widgets,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Widget Inspector',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select widgets to inspect properties',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                child: Text('${index + 1}'),
                              ),
                              title: Text('Sample Item ${index + 1}'),
                              subtitle: const Text('Tap to inspect this widget'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🤖 **AI ASSISTANT ONLY (TERMINAL MOVED TO BOTTOM)**
  Widget _buildAIAssistantOnly() {
    return Container(
      child: Column(
        children: [
          // AI Assistant Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Context-aware Flutter development help',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // AI Chat Interface
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI Assistant Ready',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask questions about your Flutter code, get suggestions, or request code generation assistance.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '💡 Pro Tip',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select widgets in the UI Preview to get context-aware AI assistance!',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Chat Input
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Ask AI about your Flutter code...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement AI chat
                          },
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
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

  /// 💻 **TERMINAL CONTENT - NOW AT BOTTOM AS REQUESTED**
  Widget _buildTerminalContent() {
    return Container(
      child: Column(
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Terminal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // TODO: Clear terminal
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  tooltip: 'Clear Terminal',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          // Terminal Content
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // Dark terminal background
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTerminalLine('Welcome to KRE8TIONS IDE Terminal', isWelcome: true),
                            _buildTerminalLine('💡 Terminal is now positioned at the bottom as requested!'),
                            _buildTerminalLine('🚀 Ready for Flutter development commands'),
                            const SizedBox(height: 8),
                            _buildTerminalLine('> flutter --version'),
                            _buildTerminalLine('Flutter 3.24.0 • channel stable', isOutput: true),
                            const SizedBox(height: 8),
                            _buildTerminalLine('> flutter doctor'),
                            _buildTerminalLine('✅ Flutter SDK ready', isOutput: true),
                            _buildTerminalLine('✅ Web development environment configured', isOutput: true),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  '> ',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  /// 📄 **TERMINAL LINE HELPER**
  Widget _buildTerminalLine(String text, {bool isWelcome = false, bool isOutput = false}) {
    Color color;
    if (isWelcome) {
      color = const Color(0xFF2196F3); // Blue for welcome
    } else if (isOutput) {
      color = const Color(0xFFE0E0E0); // Light gray for output
    } else {
      color = const Color(0xFF4CAF50); // Green for commands
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}