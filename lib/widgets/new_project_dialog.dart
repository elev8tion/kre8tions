import 'package:flutter/material.dart';
import 'package:kre8tions/services/project_template_service.dart';
import 'package:kre8tions/services/ai_project_genesis_service.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/custom_template.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({
    super.key,
    this.currentProject,
  });
  
  final FlutterProject? currentProject;

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _aiDescriptionController = TextEditingController();
  dynamic _selectedTemplate = ProjectTemplate.basic;
  bool _isCreating = false;
  int _selectedTabIndex = 0; // 0: Built-in, 1: Custom, 2: AI Genesis
  bool _isGeneratingWithAI = false;
  String _generationProgress = '';

  @override
  void dispose() {
    _projectNameController.dispose();
    _aiDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 800,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTabIndex != 2) ...[
                      _buildProjectNameSection(context),
                      const SizedBox(height: 24),
                      _buildTemplateSection(context),
                      const SizedBox(height: 32),
                      _buildPreviewSection(context),
                    ] else ...[
                      _buildAIGenesisSection(context),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.rocket_launch,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            _selectedTabIndex == 2 ? 'AI Project Genesis' : 'Create New Flutter Project',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const Spacer(),
          // Template management buttons
          if (widget.currentProject != null) ...[
            IconButton(
              onPressed: _showCreateTemplateDialog,
              icon: Icon(
                Icons.save_alt,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              tooltip: 'Save Current Project as Template',
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectNameSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Name',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _projectNameController,
          decoration: InputDecoration(
            hintText: 'Enter your project name (e.g., My Awesome App)',
            prefixIcon: const Icon(Icons.drive_file_rename_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This will be used as the app title and project identifier',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Choose Template',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            _buildTemplateCounter(context),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select a starting template for your Flutter project',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 16),
        _buildTemplateTabs(context),
        const SizedBox(height: 16),
        _buildTemplateGrid(context),
      ],
    );
  }

  Widget _buildTemplateCounter(BuildContext context) {
    final customCount = ProjectTemplateService.getCustomTemplates().length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${ProjectTemplate.values.length} built-in • $customCount custom',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildTemplateTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              context,
              'Built-in Templates',
              Icons.apps,
              0,
              ProjectTemplate.values.length,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              context,
              'My Templates',
              Icons.bookmark,
              1,
              ProjectTemplateService.getCustomTemplates().length,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              context,
              'AI Genesis',
              Icons.auto_awesome,
              2,
              null,
              gradient: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, IconData icon, int index, int? count, {bool gradient = false}) {
    final isSelected = _selectedTabIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          // Reset selection when switching tabs
          if (index == 0 && _selectedTemplate is! ProjectTemplate) {
            _selectedTemplate = ProjectTemplate.basic;
          } else if (index == 1 && _selectedTemplate is! CustomTemplate) {
            final customTemplates = ProjectTemplateService.getCustomTemplates();
            if (customTemplates.isNotEmpty) {
              _selectedTemplate = customTemplates.first;
            }
          } else if (index == 2) {
            _selectedTemplate = null; // AI Genesis doesn't use templates
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
            ? Theme.of(context).colorScheme.primary  // Flat primary color - no gradient
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (gradient 
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2))
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                          ? (gradient ? Colors.white : Theme.of(context).colorScheme.onPrimary)
                          : Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    List<dynamic> templates;
    
    if (_selectedTabIndex == 0) {
      templates = ProjectTemplate.values;
    } else {
      templates = ProjectTemplateService.getCustomTemplates();
      if (templates.isEmpty) {
        return _buildEmptyCustomTemplates(context);
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, dynamic template) {
    final isSelected = _selectedTemplate == template;
    final isCustom = template is CustomTemplate;
    
    final title = isCustom ? template.name : template.title;
    final description = isCustom ? template.description : template.description;
    final icon = isCustom ? template.icon : template.icon;
    
    return InkWell(
      onTap: () => setState(() => _selectedTemplate = template),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                if (isCustom) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                ],
                const Spacer(),
                if (isCustom)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteTemplateDialog(template);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Template'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isCustom) ...[
              const SizedBox(height: 4),
              Text(
                'Created ${_formatDate(template.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCustomTemplates(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Custom Templates Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom template\nfrom an existing project',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          if (widget.currentProject != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateTemplateDialog,
              icon: const Icon(Icons.save_alt),
              label: const Text('Create Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    if (_selectedTemplate == null) return const SizedBox.shrink();
    
    final isCustom = _selectedTemplate is CustomTemplate;
    final title = isCustom ? _selectedTemplate.name : _selectedTemplate.title;
    final description = isCustom ? _selectedTemplate.description : _selectedTemplate.description;
    final icon = isCustom ? _selectedTemplate.icon : _selectedTemplate.icon;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'CUSTOM',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 16),
          _buildFeatureList(context),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    List<String> features;
    
    if (_selectedTemplate is CustomTemplate) {
      final customTemplate = _selectedTemplate as CustomTemplate;
      features = customTemplate.tags.isEmpty 
        ? ['Custom Template', 'Saved Structure'] 
        : customTemplate.tags;
    } else {
      features = _getTemplateFeatures(_selectedTemplate);
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            feature,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getTemplateFeatures(ProjectTemplate template) {
    switch (template) {
      case ProjectTemplate.basic:
        return ['Material 3', 'Counter Demo', 'Clean Architecture'];
      case ProjectTemplate.material:
        return ['Material 3', 'Navigation', 'Dark/Light Theme', 'Custom Widgets'];
      case ProjectTemplate.cupertino:
        return ['iOS Design', 'Cupertino Widgets', 'Tab Navigation'];
      case ProjectTemplate.responsive:
        return ['Responsive Layout', 'Web Support', 'Adaptive UI', 'Breakpoints'];
      case ProjectTemplate.listView:
        return ['Dynamic Lists', 'Search', 'Filter', 'Card Views'];
      case ProjectTemplate.navigation:
        return ['Bottom Navigation', 'Multiple Pages', 'Tab System'];
      case ProjectTemplate.ecommerce:
        return ['Product Grid', 'Shopping Cart', 'Categories', 'Product Details'];
      case ProjectTemplate.social:
        return ['Social Feed', 'Posts', 'Likes & Comments', 'Image Support'];
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    bool canCreate;
    if (_selectedTabIndex == 2) {
      // AI Genesis mode
      canCreate = _projectNameController.text.trim().isNotEmpty && 
                  _aiDescriptionController.text.trim().isNotEmpty;
    } else {
      // Template mode
      canCreate = _projectNameController.text.trim().isNotEmpty;
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: (canCreate && !_isCreating && !_isGeneratingWithAI) ? _createProject : null,
            icon: (_isCreating || _isGeneratingWithAI) 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_selectedTabIndex == 2 ? Icons.auto_awesome : Icons.create),
            label: Text(_getCreateButtonText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTabIndex == 2 
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.primary,
              foregroundColor: _selectedTabIndex == 2
                ? Theme.of(context).colorScheme.onTertiary
                : Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getCreateButtonText() {
    if (_selectedTabIndex == 2) {
      if (_isGeneratingWithAI) {
        return _generationProgress.isNotEmpty ? _generationProgress : 'Generating with AI...';
      }
      return 'Generate with AI';
    } else {
      return _isCreating ? 'Creating...' : 'Create Project';
    }
  }

  Future<void> _createProject() async {
    if (_projectNameController.text.trim().isEmpty) return;
    
    if (_selectedTabIndex == 2) {
      // AI Genesis mode
      await _createAIProject();
    } else {
      // Template mode
      if (_selectedTemplate == null) return;
      await _createTemplateProject();
    }
  }

  Future<void> _createTemplateProject() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // Simulate project creation delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final projectName = _projectNameController.text.trim();
      final project = ProjectTemplateService.createFromAnyTemplate(_selectedTemplate, projectName);
      
      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createAIProject() async {
    if (_aiDescriptionController.text.trim().isEmpty) return;

    setState(() {
      _isGeneratingWithAI = true;
      _generationProgress = 'Initializing AI Genesis...';
    });

    try {
      final projectName = _projectNameController.text.trim();
      final description = _aiDescriptionController.text.trim();
      
      // Create base project structure first
      final baseProject = ProjectTemplateService.createFromAnyTemplate(ProjectTemplate.basic, projectName);
      
      // Use AI Project Genesis service to enhance it
      final project = await AIProjectGenesisService.generateProject(
        projectName: projectName,
        description: description,
        baseProject: baseProject,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _generationProgress = progress;
            });
          }
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingWithAI = false;
          _generationProgress = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating AI project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showCreateTemplateDialog() {
    if (widget.currentProject == null) return;
    
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    IconData selectedIcon = Icons.apps;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Template'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'My Custom Template',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this template is for...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  hintText: 'UI Components, Navigation, API',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Icon:', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  ...([
                    Icons.apps,
                    Icons.web,
                    Icons.mobile_friendly,
                    Icons.dashboard,
                    Icons.code,
                    Icons.widgets,
                    Icons.build,
                    Icons.star,
                  ].map((icon) => IconButton(
                    onPressed: () {
                      selectedIcon = icon;
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(
                      icon,
                      color: selectedIcon == icon
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                return;
              }
              
              final tags = tagsController.text
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
              
              ProjectTemplateService.createCustomTemplate(
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                icon: selectedIcon,
                sourceProject: widget.currentProject!,
                tags: tags,
              );
              
              Navigator.of(context).pop();
              setState(() {}); // Refresh the template list
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom template created successfully!')),
              );
            },
            child: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTemplateDialog(CustomTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete the template "${template.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ProjectTemplateService.deleteCustomTemplate(template.id);
              Navigator.of(context).pop();
              
              // If the deleted template was selected, switch to a built-in template
              if (_selectedTemplate == template) {
                setState(() {
                  _selectedTemplate = ProjectTemplate.basic;
                  _selectedTabIndex = 0;
                });
              } else {
                setState(() {}); // Refresh the template list
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Template "${template.name}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAIGenesisSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAIGenesisHeader(context),
        const SizedBox(height: 24),
        _buildProjectNameSection(context),
        const SizedBox(height: 24),
        _buildDescriptionSection(context),
        const SizedBox(height: 24),
        _buildExamplesSection(context),
        const SizedBox(height: 24),
        if (_isGeneratingWithAI)
          _buildProgressSection(context),
      ],
    );
  }

  Widget _buildAIGenesisHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,  // Flat primary container - no gradient
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 AI Project Genesis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Describe your app vision and watch it come to life!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeatureChip(context, '🧠', 'Smart Analysis'),
              const SizedBox(width: 8),
              _buildFeatureChip(context, '⚡', 'Complete Architecture'),
              const SizedBox(width: 8),
              _buildFeatureChip(context, '📱', 'Ready to Run'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Describe Your App Vision',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Be as detailed as possible. Describe features, screens, functionality, and design preferences.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: TextField(
            controller: _aiDescriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Example: "Create a fitness tracking app with workout logging, progress charts, social features, and meal planning. Users should be able to create custom workouts, track their exercises, and share achievements with friends. Include a dark theme and modern design."',
              hintMaxLines: 4,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    final examples = [
      {
        'icon': Icons.fitness_center,
        'title': 'Fitness Tracker',
        'description': 'Workout logging, progress charts, social sharing',
      },
      {
        'icon': Icons.restaurant,
        'title': 'Recipe Platform',
        'description': 'Recipe sharing, favorites, meal planning',
      },
      {
        'icon': Icons.task_alt,
        'title': 'Task Manager',
        'description': 'Team collaboration, deadlines, project tracking',
      },
      {
        'icon': Icons.shopping_bag,
        'title': 'E-Commerce Store',
        'description': 'Product catalog, shopping cart, user accounts',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tips_and_updates,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Need Inspiration?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final example = examples[index];
            return InkWell(
              onTap: () {
                final title = example['title'] as String? ?? '';
          final description = example['description'] as String? ?? '';
          _aiDescriptionController.text = 'Create a ${title.toLowerCase()} app with $description';
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          example['icon'] as IconData,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            example['title'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      example['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _generationProgress,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}