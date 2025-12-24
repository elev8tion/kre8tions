import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/services/project_export_service.dart';
import 'package:kre8tions/services/project_sharing_service.dart';

class ExportProjectDialog extends StatefulWidget {
  final FlutterProject project;

  const ExportProjectDialog({
    super.key,
    required this.project,
  });

  @override
  State<ExportProjectDialog> createState() => _ExportProjectDialogState();
}

class _ExportProjectDialogState extends State<ExportProjectDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Export tab state
  ExportFormat _selectedFormat = ExportFormat.zip;
  bool _includeLibFiles = true;
  bool _includeTestFiles = true;
  bool _includeAndroidFiles = false;
  bool _includeIosFiles = false;
  bool _includeWebFiles = false;
  bool _includeAssets = true;
  bool _includeDependencies = true;
  bool _includeHiddenFiles = false;
  bool _includeBuildFiles = false;
  bool _includeGitFiles = false;
  final List<String> _customExcludePaths = [];
  final List<String> _customIncludePaths = [];
  final TextEditingController _excludePathController = TextEditingController();
  final TextEditingController _includePathController = TextEditingController();
  
  // Share tab state
  final TextEditingController _shareDescriptionController = TextEditingController();
  final TextEditingController _shareCreatorController = TextEditingController();
  final TextEditingController _shareTagsController = TextEditingController();
  ProjectShareType _shareType = ProjectShareType.full;
  bool _isPublicShare = false;
  int _expirationDays = 30;
  
  // Template tab state
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _templateDescriptionController = TextEditingController();
  final TextEditingController _templateCategoryController = TextEditingController();
  final TextEditingController _templateTagsController = TextEditingController();
  
  // Progress state
  bool _isProcessing = false;
  String _progressMessage = '';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set up progress callbacks
    ProjectExportService.onProgress = _onExportProgress;
    ProjectSharingService.onShareProgress = _onShareProgress;
    
    // Initialize default values
    _shareCreatorController.text = 'CodeWhisper User';
    _templateCategoryController.text = 'General';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _excludePathController.dispose();
    _includePathController.dispose();
    _shareDescriptionController.dispose();
    _shareCreatorController.dispose();
    _shareTagsController.dispose();
    _templateNameController.dispose();
    _templateDescriptionController.dispose();
    _templateCategoryController.dispose();
    _templateTagsController.dispose();
    super.dispose();
  }

  void _onExportProgress(ExportProgress progress) {
    if (mounted) {
      setState(() {
        _progressMessage = progress.message;
        _progress = progress.progress;
        _hasError = progress.hasError;
        _errorMessage = progress.error;
        if (progress.isComplete) {
          _isProcessing = false;
        }
      });
    }
  }

  void _onShareProgress(ShareProgress progress) {
    if (mounted) {
      setState(() {
        _progressMessage = progress.message;
        _progress = progress.progress;
        _hasError = progress.hasError;
        _errorMessage = progress.error;
        if (progress.isComplete) {
          _isProcessing = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            if (_isProcessing) _buildProgressIndicator(),
            if (!_isProcessing) Expanded(child: _buildContent()),
            if (!_isProcessing) _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,  // Flat primary color - no gradient
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.share,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export & Share Project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.project.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          CircularProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(
            _progressMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_hasError && _errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
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

  Widget _buildContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.download), text: 'Export'),
            Tab(icon: Icon(Icons.share), text: 'Share'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Template'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildExportTab(),
              _buildShareTab(),
              _buildTemplateTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormatSection(),
          const SizedBox(height: 24),
          _buildInclusionOptionsSection(),
          const SizedBox(height: 24),
          _buildCustomPathsSection(),
          const SizedBox(height: 24),
          _buildExportPreview(),
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...ExportFormat.values.map((format) {
              return RadioListTile<ExportFormat>(
                title: Text(_getFormatDisplayName(format)),
                subtitle: Text(_getFormatDescription(format)),
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFormat = value;
                      _updateOptionsForFormat(value);
                    });
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInclusionOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Include Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionChip('Library Files', _includeLibFiles, (value) => setState(() => _includeLibFiles = value)),
                _buildOptionChip('Test Files', _includeTestFiles, (value) => setState(() => _includeTestFiles = value)),
                _buildOptionChip('Android Files', _includeAndroidFiles, (value) => setState(() => _includeAndroidFiles = value)),
                _buildOptionChip('iOS Files', _includeIosFiles, (value) => setState(() => _includeIosFiles = value)),
                _buildOptionChip('Web Files', _includeWebFiles, (value) => setState(() => _includeWebFiles = value)),
                _buildOptionChip('Assets', _includeAssets, (value) => setState(() => _includeAssets = value)),
                _buildOptionChip('Dependencies', _includeDependencies, (value) => setState(() => _includeDependencies = value)),
                _buildOptionChip('Hidden Files', _includeHiddenFiles, (value) => setState(() => _includeHiddenFiles = value)),
                _buildOptionChip('Build Files', _includeBuildFiles, (value) => setState(() => _includeBuildFiles = value)),
                _buildOptionChip('Git Files', _includeGitFiles, (value) => setState(() => _includeGitFiles = value)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildCustomPathsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Paths',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPathSection('Exclude Paths', _customExcludePaths, _excludePathController),
            const SizedBox(height: 16),
            _buildPathSection('Include Paths', _customIncludePaths, _includePathController),
          ],
        ),
      ),
    );
  }

  Widget _buildPathSection(String title, List<String> paths, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g., *.log, temp/, build/*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    paths.add(controller.text);
                    controller.clear();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        if (paths.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: paths.map((path) => Chip(
              label: Text(path),
              onDeleted: () {
                setState(() {
                  paths.remove(path);
                });
              },
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildExportPreview() {
    final filteredFiles = _getFilteredFiles();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Files', '${filteredFiles.length}', Icons.folder),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Dart Files', '${filteredFiles.where((f) => f.isDartFile).length}', Icons.code),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Directories', '${filteredFiles.where((f) => f.isDirectory).length}', Icons.folder_open),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredFiles.take(10).length,
                itemBuilder: (context, index) {
                  final file = filteredFiles[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                      size: 16,
                    ),
                    title: Text(
                      file.path,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            if (filteredFiles.length > 10)
              Text(
                '... and ${filteredFiles.length - 10} more files',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shareDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your project...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shareCreatorController,
                    decoration: const InputDecoration(
                      labelText: 'Created By',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shareTagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'flutter, mobile, ui, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ProjectShareType.values.map((type) {
                    return RadioListTile<ProjectShareType>(
                      title: Text(_getShareTypeDisplayName(type)),
                      subtitle: Text(_getShareTypeDescription(type)),
                      value: type,
                      groupValue: _shareType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _shareType = value;
                          });
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Make Public'),
                    subtitle: const Text('Allow anyone to discover and import this project'),
                    value: _isPublicShare,
                    onChanged: (value) {
                      setState(() {
                        _isPublicShare = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Expiration'),
                  Slider(
                    value: _expirationDays.toDouble(),
                    min: 1,
                    max: 365,
                    divisions: 11,
                    label: '$_expirationDays days',
                    onChanged: (value) {
                      setState(() {
                        _expirationDays = value.round();
                      });
                    },
                  ),
                  Text(
                    'Link expires in $_expirationDays days',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _templateNameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _templateDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe what this template provides...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _templateCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _templateTagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'ui, animation, state-management, etc.',
                      border: OutlineInputBorder(),
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _canExecuteAction() ? _executeAction : null,
            child: Text(_getActionButtonText()),
          ),
        ],
      ),
    );
  }

  bool _canExecuteAction() {
    switch (_tabController.index) {
      case 0: // Export
        return true;
      case 1: // Share
        return _shareDescriptionController.text.isNotEmpty;
      case 2: // Template
        return _templateNameController.text.isNotEmpty && 
               _templateDescriptionController.text.isNotEmpty;
      default:
        return false;
    }
  }

  String _getActionButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Export';
      case 1:
        return 'Share';
      case 2:
        return 'Create Template';
      default:
        return 'Execute';
    }
  }

  Future<void> _executeAction() async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      switch (_tabController.index) {
        case 0:
          await _performExport();
          break;
        case 1:
          await _performShare();
          break;
        case 2:
          await _performCreateTemplate();
          break;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _performExport() async {
    final options = ProjectExportOptions(
      includeLibFiles: _includeLibFiles,
      includeTestFiles: _includeTestFiles,
      includeAndroidFiles: _includeAndroidFiles,
      includeIosFiles: _includeIosFiles,
      includeWebFiles: _includeWebFiles,
      includeAssets: _includeAssets,
      includeDependencies: _includeDependencies,
      includeHiddenFiles: _includeHiddenFiles,
      includeBuildFiles: _includeBuildFiles,
      includeGitFiles: _includeGitFiles,
      format: _selectedFormat,
      customExcludePaths: _customExcludePaths,
      customIncludePaths: _customIncludePaths,
    );

    final result = await ProjectExportService.exportProject(widget.project, options);

    if (result.success && result.data != null) {
      _downloadFile(result.data!, result.filename);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project exported successfully as ${result.filename}')),
        );
      }
    } else {
      throw Exception(result.error ?? 'Export failed');
    }
  }

  Future<void> _performShare() async {
    final tags = _shareTagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final shareLink = await ProjectSharingService.shareProject(
      widget.project,
      description: _shareDescriptionController.text,
      createdBy: _shareCreatorController.text,
      expirationDuration: Duration(days: _expirationDays),
      isPublic: _isPublicShare,
      tags: tags,
      shareType: _shareType,
    );

    if (mounted) {
      Navigator.of(context).pop();
      _showShareLinkDialog(shareLink);
    }
  }

  Future<void> _performCreateTemplate() async {
    final tags = _templateTagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final template = await ProjectSharingService.createTemplate(
      widget.project,
      templateName: _templateNameController.text,
      description: _templateDescriptionController.text,
      category: _templateCategoryController.text,
      tags: tags,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "${template.name}" created successfully')),
      );
    }
  }

  void _showShareLinkDialog(String shareLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project Shared Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your project has been shared! Use this link to let others import it:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                shareLink,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard (web implementation)
              html.window.navigator.clipboard?.writeText(shareLink);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied to clipboard')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(List<int> bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = filename;
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  List<dynamic> _getFilteredFiles() {
    final options = ProjectExportOptions(
      includeLibFiles: _includeLibFiles,
      includeTestFiles: _includeTestFiles,
      includeAndroidFiles: _includeAndroidFiles,
      includeIosFiles: _includeIosFiles,
      includeWebFiles: _includeWebFiles,
      includeAssets: _includeAssets,
      includeDependencies: _includeDependencies,
      includeHiddenFiles: _includeHiddenFiles,
      includeBuildFiles: _includeBuildFiles,
      includeGitFiles: _includeGitFiles,
      customExcludePaths: _customExcludePaths,
      customIncludePaths: _customIncludePaths,
    );

    // Use the same filtering logic as the export service
    return widget.project.files.where((file) {
      // Custom include paths override everything
      if (options.customIncludePaths.isNotEmpty) {
        final included = options.customIncludePaths.any((pattern) => 
          file.path.contains(pattern) || _matchesGlob(file.path, pattern));
        if (!included) return false;
      }

      // Custom exclude paths
      if (options.customExcludePaths.any((pattern) => 
          file.path.contains(pattern) || _matchesGlob(file.path, pattern))) {
        return false;
      }

      // Built-in filters
      if (!options.includeLibFiles && file.path.startsWith('lib/')) return false;
      if (!options.includeTestFiles && file.path.startsWith('test/')) return false;
      if (!options.includeAndroidFiles && file.path.startsWith('android/')) return false;
      if (!options.includeIosFiles && file.path.startsWith('ios/')) return false;
      if (!options.includeWebFiles && file.path.startsWith('web/')) return false;
      if (!options.includeAssets && file.path.startsWith('assets/')) return false;
      if (!options.includeHiddenFiles && file.path.contains('/.')) return false;
      if (!options.includeBuildFiles && file.path.startsWith('build/')) return false;
      if (!options.includeGitFiles && (file.path.startsWith('.git/') || file.path == '.gitignore')) return false;

      return true;
    }).toList();
  }

  bool _matchesGlob(String path, String pattern) {
    if (pattern.contains('*')) {
      final regexPattern = pattern.replaceAll('*', '.*');
      return RegExp(regexPattern).hasMatch(path);
    }
    return path.contains(pattern);
  }

  void _updateOptionsForFormat(ExportFormat format) {
    final defaultOptions = ProjectExportService.getDefaultOptions(format);
    _includeLibFiles = defaultOptions.includeLibFiles;
    _includeTestFiles = defaultOptions.includeTestFiles;
    _includeAndroidFiles = defaultOptions.includeAndroidFiles;
    _includeIosFiles = defaultOptions.includeIosFiles;
    _includeWebFiles = defaultOptions.includeWebFiles;
    _includeAssets = defaultOptions.includeAssets;
    _includeDependencies = defaultOptions.includeDependencies;
    _includeHiddenFiles = defaultOptions.includeHiddenFiles;
    _includeBuildFiles = defaultOptions.includeBuildFiles;
    _includeGitFiles = defaultOptions.includeGitFiles;
  }

  String _getFormatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.zip:
        return 'Standard ZIP Archive';
      case ExportFormat.flutterTemplate:
        return 'Flutter Project Template';
      case ExportFormat.codeWhisperProject:
        return 'CodeWhisper Project Format';
      case ExportFormat.sourceOnly:
        return 'Source Code Only';
      case ExportFormat.apk:
        return 'Android APK';
      case ExportFormat.aab:
        return 'Android App Bundle';
      case ExportFormat.ipa:
        return 'iOS App Archive';
      case ExportFormat.webBuild:
        return 'Web Build';
      case ExportFormat.windowsExe:
        return 'Windows Executable';
      case ExportFormat.macosApp:
        return 'macOS Application';
      case ExportFormat.linuxBinary:
        return 'Linux Binary';
      case ExportFormat.dockerImage:
        return 'Docker Image';
      case ExportFormat.githubRepo:
        return 'GitHub Repository';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.zip:
        return 'Standard ZIP file containing all selected files and folders';
      case ExportFormat.flutterTemplate:
        return 'Flutter project template with metadata and documentation';
      case ExportFormat.codeWhisperProject:
        return 'CodeWhisper native format with full project information';
      case ExportFormat.sourceOnly:
        return 'Only source code files (Dart, YAML, JSON, etc.)';
      case ExportFormat.apk:
        return 'Android application package ready for installation';
      case ExportFormat.aab:
        return 'Android App Bundle for Play Store distribution';
      case ExportFormat.ipa:
        return 'iOS application archive for App Store or enterprise distribution';
      case ExportFormat.webBuild:
        return 'Web build ready for hosting on any web server';
      case ExportFormat.windowsExe:
        return 'Windows executable for desktop distribution';
      case ExportFormat.macosApp:
        return 'macOS application bundle for Mac distribution';
      case ExportFormat.linuxBinary:
        return 'Linux binary for distribution on Linux systems';
      case ExportFormat.dockerImage:
        return 'Docker container image for deployment';
      case ExportFormat.githubRepo:
        return 'Complete repository ready for GitHub hosting';
    }
  }

  String _getShareTypeDisplayName(ProjectShareType type) {
    switch (type) {
      case ProjectShareType.full:
        return 'Complete Project';
      case ProjectShareType.template:
        return 'Project Template';
      case ProjectShareType.configuration:
        return 'Configuration Only';
      case ProjectShareType.structure:
        return 'Structure Only';
    }
  }

  String _getShareTypeDescription(ProjectShareType type) {
    switch (type) {
      case ProjectShareType.full:
        return 'Share the complete project with all files and content';
      case ProjectShareType.template:
        return 'Share as a reusable template with placeholder values';
      case ProjectShareType.configuration:
        return 'Share only configuration files (pubspec.yaml, etc.)';
      case ProjectShareType.structure:
        return 'Share only the folder structure and metadata';
    }
  }
}