import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/services/project_sharing_service.dart';

class ImportSharedProjectDialog extends StatefulWidget {
  final Function(FlutterProject)? onProjectImported;

  const ImportSharedProjectDialog({
    super.key,
    this.onProjectImported,
  });

  @override
  State<ImportSharedProjectDialog> createState() => _ImportSharedProjectDialogState();
}

class _ImportSharedProjectDialogState extends State<ImportSharedProjectDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Import by link tab
  final TextEditingController _shareLinkController = TextEditingController();
  
  // Browse templates tab
  List<ProjectTemplate> _templates = [];
  List<ProjectTemplate> _filteredTemplates = [];
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [];
  
  // State
  bool _isLoading = false;
  String _progressMessage = '';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set up progress callbacks
    ProjectSharingService.onImportProgress = _onImportProgress;
    
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shareLinkController.dispose();
    super.dispose();
  }

  void _onImportProgress(ShareProgress progress) {
    if (mounted) {
      setState(() {
        _progressMessage = progress.message;
        _progress = progress.progress;
        _hasError = progress.hasError;
        _errorMessage = progress.error;
        if (progress.isComplete) {
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _progressMessage = 'Loading templates...';
    });

    try {
      _templates = ProjectSharingService.getAvailableTemplates();
      _categories = ProjectSharingService.getTemplateCategories();
      _filteredTemplates = _templates;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load templates: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            if (_isLoading) _buildProgressIndicator(),
            if (!_isLoading) Expanded(child: _buildContent()),
            if (!_isLoading) _buildActionButtons(context),
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
            Icons.cloud_download,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Shared Project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Import from link or browse community templates',
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
            Tab(icon: Icon(Icons.link), text: 'Import by Link'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Browse Templates'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildImportByLinkTab(),
              _buildBrowseTemplatesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportByLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Link',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste the project share link you received:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shareLinkController,
            decoration: const InputDecoration(
              hintText: 'codewhisper://share/proj_...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'How to get a share link:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Someone shared their project with you'),
                  const Text('2. They provided a link starting with "codewhisper://share/"'),
                  const Text('3. Paste that link above to import the project'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTemplatesTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _buildTemplateGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search templates...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterTemplates();
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', _selectedCategory == null),
                ..._categories.map((category) => 
                  _buildCategoryChip(category, _selectedCategory == category)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? (label == 'All' ? null : label) : null;
            _filterTemplates();
          });
        },
      ),
    );
  }

  void _filterTemplates() {
    _filteredTemplates = _templates.where((template) {
      final matchesSearch = _searchQuery.isEmpty ||
          template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          template.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          template.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesCategory = _selectedCategory == null || template.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildTemplateGrid() {
    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(ProjectTemplate template) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTemplateDetails(template),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  template.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        template.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(Icons.download, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${template.downloadCount}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetails(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: 16),
            Text('Category: ${template.category}'),
            const SizedBox(height: 8),
            Text('Created by: ${template.createdBy}'),
            const SizedBox(height: 8),
            Text('Rating: ${template.rating.toStringAsFixed(1)} stars'),
            const SizedBox(height: 8),
            Text('Downloads: ${template.downloadCount}'),
            if (template.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: template.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _importFromTemplate(template);
            },
            child: const Text('Use Template'),
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
            onPressed: _canImport() ? _performImport : null,
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  bool _canImport() {
    return _tabController.index == 0 && _shareLinkController.text.isNotEmpty;
  }

  Future<void> _performImport() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final result = await ProjectSharingService.importSharedProject(_shareLinkController.text);
      
      if (result.success && result.project != null) {
        widget.onProjectImported?.call(result.project!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project "${result.project!.name}" imported successfully')),
          );
        }
      } else {
        throw Exception(result.error ?? 'Import failed');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importFromTemplate(ProjectTemplate template) async {
    // Show project name dialog
    final projectName = await _showProjectNameDialog();
    if (projectName == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final result = await ProjectSharingService.importFromTemplate(
        template.id,
        projectName: projectName,
        customizations: {}, // Could be extended to allow customizations
      );

      if (result.success && result.project != null) {
        widget.onProjectImported?.call(result.project!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project "$projectName" created from template')),
          );
        }
      } else {
        throw Exception(result.error ?? 'Template import failed');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String?> _showProjectNameDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter project name...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}