import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/openai/openai_config.dart';
import 'package:kre8tions/widgets/system_status_panel.dart';

class AIAssistantPanel extends StatefulWidget {
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final FlutterProject? currentProject;
  final Function(String)? onCodeGenerated;
  final Function(List<FileOperation>)? onFilesGenerated;

  const AIAssistantPanel({
    super.key,
    this.selectedFile,
    this.selectedWidget,
    this.currentProject,
    this.onCodeGenerated,
    this.onFilesGenerated,
  });

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _lastResponse;
  AIAction _selectedAction = AIAction.improve;
  
  // Systematic Generation State
  SystematicGenerationResult? _systematicResult;
  SystematicStep? _currentStep;
  bool _showSystematicResults = false;
  bool _autoCompileEnabled = true;
  
  // Tab Controller for AI Assistant and System Status
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Beautiful Tab Bar
          _buildTabBar(theme),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAIAssistantTab(theme),
                _buildSystemStatusTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16),
                SizedBox(width: 8),
                Text('AI Assistant'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update, size: 16),
                SizedBox(width: 8),
                Text('System Status'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIAssistantTab(ThemeData theme) {
    return Column(
      children: [
        _buildContextInfo(theme),
        _buildActionSelector(theme),
        _buildPromptInput(theme),
        _buildActionButtons(theme),
        Expanded(
          child: _buildResponseArea(theme),
        ),
      ],
    );
  }
  
  Widget _buildSystemStatusTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const SystemStatusPanel(),
    );
  }

  Widget _buildContextInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // API Status
          if (!OpenAIConfig.isConfigured)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'OpenAI API not configured',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Widget Context
          if (widget.selectedWidget != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.widgets,
                    color: theme.colorScheme.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${widget.selectedWidget!.widgetType}:${widget.selectedWidget!.lineNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Action',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AIAction.values.map((action) {
              final isSelected = _selectedAction == action;
              return FilterChip(
                label: Text(
                  action.displayName,
                  style: TextStyle(
                    color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedAction = action;
                    });
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedAction.promptLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _selectedAction.promptHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading || !OpenAIConfig.isConfigured
                ? null
                : _processAIRequest,
              icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
              label: Text(
                _isLoading ? 'Processing...' : 'Generate',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _promptController.clear();
                _lastResponse = null;
              });
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
          ),
        ],
      ),
    );
  }

  Widget _buildResponseArea(ThemeData theme) {
    if (_lastResponse == null) {
      return _buildEmptyResponseState(theme);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
          ? const Color(0xFFF1F5F9)
          : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.light
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Response',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lastResponse!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Response copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy response',
                  visualDensity: VisualDensity.compact,
                ),
                if (_selectedAction == AIAction.improve || _selectedAction == AIAction.generate)
                  IconButton(
                    onPressed: () {
                      if (widget.onCodeGenerated != null) {
                        widget.onCodeGenerated!(_lastResponse!);
                      }
                    },
                    icon: const Icon(Icons.integration_instructions, size: 16),
                    tooltip: 'Apply to editor',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _lastResponse!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResponseState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'AI responses will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (!OpenAIConfig.isConfigured) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OpenAI API not configured. Please set environment variables.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _processAIRequest() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    if (widget.selectedFile == null && widget.selectedWidget == null && _selectedAction != AIAction.generate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file or widget first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _showSystematicResults = false;
    });

    try {
      if (_selectedAction == AIAction.systematic) {
        await _processSystematicGeneration();
        return;
      }
      
      String response;
      
      switch (_selectedAction) {
        case AIAction.improve:
          String contextInfo = _promptController.text;
          if (widget.selectedWidget != null) {
            contextInfo += '\n\n[WIDGET CONTEXT: ${widget.selectedWidget!.widgetType} at ${widget.selectedWidget!.filePath}:${widget.selectedWidget!.lineNumber}]';
          }
          response = await OpenAIService.improveCode(
            code: widget.selectedFile?.content ?? widget.selectedWidget?.sourceCode ?? '',
            fileName: widget.selectedFile?.fileName ?? widget.selectedWidget?.filePath ?? 'unknown.dart',
            context: contextInfo,
          );
          break;
        case AIAction.generate:
          String description = _promptController.text;
          if (widget.selectedWidget != null) {
            description += '\n\nGenerate code for a ${widget.selectedWidget!.widgetType} widget.';
          }
          response = await OpenAIService.generateCode(
            description: description,
            fileName: 'generated_code.dart',
          );
          break;
        case AIAction.explain:
          String codeToExplain = widget.selectedFile?.content ?? widget.selectedWidget?.sourceCode ?? '';
          if (widget.selectedWidget != null) {
            codeToExplain = 'Widget: ${widget.selectedWidget!.widgetType}\nLocation: ${widget.selectedWidget!.filePath}:${widget.selectedWidget!.lineNumber}\n\n$codeToExplain';
          }
          response = await OpenAIService.explainCode(
            code: codeToExplain,
            fileName: widget.selectedFile?.fileName ?? widget.selectedWidget?.filePath ?? 'unknown.dart',
          );
          break;
        case AIAction.systematic:
          // Handled above
          return;
      }

      setState(() {
        _lastResponse = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: \$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NEW SYSTEMATIC GENERATION METHODS
  Future<void> _processSystematicGeneration() async {
    if (widget.currentProject == null) {
      throw Exception('No project loaded for systematic generation');
    }

    setState(() {
      _showSystematicResults = true;
    });

    final result = await OpenAIService.generateSystematically(
      task: _promptController.text,
      project: widget.currentProject!,
      onStepUpdate: (step) {
        if (mounted) {
          setState(() {
            _currentStep = step;
          });
        }
      },
    );

    setState(() {
      _systematicResult = result;
    });

    if (result.success && _autoCompileEnabled) {
      await _autoCompileAndFix();
    }
  }

  Future<void> _autoCompileAndFix() async {
    if (_systematicResult?.fileOperations.isEmpty == true) return;

    try {
      setState(() {
        _currentStep = SystematicStep.complete;
      });
      
      // Web version: Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Files ready for download! Use "Apply All" to download generated files.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Auto-compile error: \$e');
    }
  }

  // NEW UI BUILDER METHODS
  Widget _buildSystematicOptions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              title: Text(
                'Auto-Compile & Fix',
                style: theme.textTheme.bodySmall,
              ),
              subtitle: Text(
                'Automatically compile and fix errors',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: _autoCompileEnabled,
              onChanged: (value) {
                setState(() {
                  _autoCompileEnabled = value ?? true;
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystematicResults(ThemeData theme) {
    if (_systematicResult == null && _currentStep == null) {
      return _buildEmptySystematicState(theme);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF1A202C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildSystematicHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep != null) _buildStepIndicator(theme),
                  if (_systematicResult != null) 
                    ..._buildResultSections(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystematicHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Systematic Generation',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStep!.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultSections(ThemeData theme) {
    final result = _systematicResult!;
    final sections = <Widget>[];

    if (result.analysis != null) {
      sections.add(_buildResultSection('📋 Analysis', result.analysis!, theme));
    }
    
    if (result.plan != null) {
      sections.add(_buildResultSection('🗺️ Implementation Plan', result.plan!, theme));
    }
    
    if (result.generatedCode != null) {
      sections.add(_buildResultSection('⚡ Generated Code', result.generatedCode!, theme));
    }
    
    if (result.fileOperations.isNotEmpty) {
      sections.add(_buildFileOperationsSection(theme));
    }

    if (result.error != null) {
      sections.add(_buildErrorSection(result.error!, theme));
    }

    return sections;
  }

  Widget _buildResultSection(String title, String content, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileOperationsSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📁 File Operations (${_systematicResult!.fileOperations.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  if (widget.onFilesGenerated != null) {
                    widget.onFilesGenerated!(_systematicResult!.fileOperations);
                  }
                },
                icon: const Icon(Icons.integration_instructions, size: 16),
                label: const Text('Apply All'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_systematicResult!.fileOperations.map((op) => 
            _buildFileOperationCard(op, theme),
          )),
        ],
      ),
    );
  }

  Widget _buildFileOperationCard(FileOperation operation, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
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
                operation.type == 'create' ? Icons.add_circle : Icons.edit,
                size: 16,
                color: operation.type == 'create' 
                  ? Colors.green 
                  : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  operation.filePath,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                operation.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: operation.type == 'create' 
                    ? Colors.green 
                    : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (operation.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              operation.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection(String error, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySystematicState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Systematic Generation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mirrors Hologram\'s systematic approach:\nAnalyze → Plan → Generate → Compile → Fix',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

enum AIAction {
  improve,
  generate,
  explain,
  systematic,
}

extension AIActionExtension on AIAction {
  String get displayName {
    switch (this) {
      case AIAction.improve:
        return '✨ Improve';
      case AIAction.generate:
        return '🔧 Generate';
      case AIAction.explain:
        return '💡 Explain';
      case AIAction.systematic:
        return '🚀 Systematic';
    }
  }

  String get promptLabel {
    switch (this) {
      case AIAction.improve:
        return 'Improvement Instructions';
      case AIAction.generate:
        return 'Code Description';
      case AIAction.explain:
        return 'Questions (Optional)';
      case AIAction.systematic:
        return 'Development Task';
    }
  }

  String get promptHint {
    switch (this) {
      case AIAction.improve:
        return 'Describe what improvements you want to make...';
      case AIAction.generate:
        return 'Describe the code you want to generate...';
      case AIAction.explain:
        return 'Ask specific questions about the code...';
      case AIAction.systematic:
        return 'Describe what you want to build (e.g., "Create a user profile page with avatar upload")';
    }
  }
}