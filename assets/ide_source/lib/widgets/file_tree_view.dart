import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/file_operations.dart';
import 'package:kre8tions/services/project_manager.dart';
import 'package:kre8tions/widgets/export_project_dialog.dart';

class FileTreeView extends StatefulWidget {
  final FlutterProject project;
  final ProjectFile? selectedFile;
  final Function(ProjectFile) onFileSelected;
  final Function(FlutterProject)? onProjectUpdated;

  const FileTreeView({
    super.key,
    required this.project,
    this.selectedFile,
    required this.onFileSelected,
    this.onProjectUpdated,
  });

  @override
  State<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends State<FileTreeView> {
  final Set<String> _expandedDirectories = <String>{};

  @override
  void initState() {
    super.initState();
    // Auto-expand lib directory
    _expandedDirectories.add('lib');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project info header (compact)
        GestureDetector(
          onSecondaryTapUp: (details) {
            _showProjectContextMenu(context, details.globalPosition);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.project.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  onSelected: (value) => _handleProjectAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16),
                          SizedBox(width: 8),
                          Text('Export Project'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 8),
                          Text('Share Project'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 16),
                          SizedBox(width: 8),
                          Text('Refresh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 8),
                          Text('Project Info'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _buildFileTree(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFileTree() {
    final fileTree = _organizeFilesIntoTree();
    return _buildTreeNodes(fileTree, 0);
  }

  Map<String, dynamic> _organizeFilesIntoTree() {
    final tree = <String, dynamic>{};
    
    for (final file in widget.project.files) {
      final parts = file.path.split('/');
      Map<String, dynamic> current = tree;
      
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1 && !file.isDirectory) {
          // This is a file
          current[part] = file;
        } else {
          // This is a directory
          current[part] ??= <String, dynamic>{};
          current = current[part] as Map<String, dynamic>;
        }
      }
    }
    
    return tree;
  }

  List<Widget> _buildTreeNodes(Map<String, dynamic> tree, int depth) {
    final widgets = <Widget>[];
    final sortedKeys = tree.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final value = tree[key];
      
      if (value is ProjectFile) {
        // This is a file
        widgets.add(_buildFileItem(value, depth));
      } else if (value is Map<String, dynamic>) {
        // This is a directory
        final dirPath = _buildPathFromDepth(key, depth);
        final isExpanded = _expandedDirectories.contains(dirPath);
        
        widgets.add(_buildDirectoryItem(key, depth, isExpanded, () {
          setState(() {
            if (isExpanded) {
              _expandedDirectories.remove(dirPath);
            } else {
              _expandedDirectories.add(dirPath);
            }
          });
        }));
        
        if (isExpanded) {
          widgets.addAll(_buildTreeNodes(value, depth + 1));
        }
      }
    }
    
    return widgets;
  }

  String _buildPathFromDepth(String name, int depth) {
    // This is a simplified approach - in a real implementation,
    // you'd need to track the full path properly
    return name;
  }

  String _buildFullPathFromDepth(String name, int depth) {
    // For now, simplified - in production you'd track full paths
    return depth == 0 ? name : 'lib/$name';
  }

  void _showFileContextMenu(BuildContext context, Offset position, ProjectFile file) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleFileAction(value, file);
      }
    });
  }

  void _showDirectoryContextMenu(BuildContext context, Offset position, String dirPath, String dirName) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'new_file',
          child: Row(
            children: [
              Icon(Icons.note_add, size: 16),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'new_folder',
          child: Row(
            children: [
              Icon(Icons.create_new_folder, size: 16),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleDirectoryAction(value, dirPath, dirName);
      }
    });
  }

  void _handleFileAction(String action, ProjectFile file) {
    switch (action) {
      case 'rename':
        _showRenameFileDialog(file);
        break;
      case 'duplicate':
        _duplicateFile(file);
        break;
      case 'delete':
        _showDeleteConfirmation(file: file);
        break;
    }
  }

  void _handleDirectoryAction(String action, String dirPath, String dirName) {
    switch (action) {
      case 'new_file':
        _showNewFileDialog(dirPath);
        break;
      case 'new_folder':
        _showNewFolderDialog(dirPath);
        break;
      case 'rename':
        _showRenameDirectoryDialog(dirPath, dirName);
        break;
      case 'delete':
        _showDeleteConfirmation(directoryPath: dirPath);
        break;
    }
  }

  void _showProjectContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, size: 16),
              SizedBox(width: 8),
              Text('Export Project'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 16),
              SizedBox(width: 8),
              Text('Share Project'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info, size: 16),
              SizedBox(width: 8),
              Text('Project Info'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleProjectAction(value);
      }
    });
  }

  void _handleProjectAction(String action) {
    switch (action) {
      case 'export':
      case 'share':
        showDialog(
          context: context,
          builder: (context) => ExportProjectDialog(project: widget.project),
        );
        break;
      case 'refresh':
        setState(() {
          // Refresh the file tree view
        });
        break;
      case 'info':
        _showProjectInfoDialog();
        break;
    }
  }

  void _showNewFileDialog(String parentPath) {
    _showCreateDialog(
      title: 'Create New File',
      hintText: 'Enter file name (e.g., widget.dart)',
      templates: FileOperations.getFileTemplates(),
      onConfirm: (String fileName, String? template) {
        try {
          final fullPath = parentPath.isEmpty ? fileName : '$parentPath/$fileName';
          final content = template != null ? FileOperations.getFileTemplate(template, fileName) : '';
          final updatedProject = ProjectManager.createFile(widget.project, fullPath, content);
          widget.onProjectUpdated?.call(updatedProject);
        } catch (e) {
          _showErrorDialog('Failed to create file: $e');
        }
      },
    );
  }

  void _showNewFolderDialog(String parentPath) {
    _showCreateDialog(
      title: 'Create New Folder',
      hintText: 'Enter folder name',
      onConfirm: (String folderName, String? template) {
        try {
          final fullPath = parentPath.isEmpty ? folderName : '$parentPath/$folderName';
          final updatedProject = ProjectManager.createDirectory(widget.project, fullPath);
          widget.onProjectUpdated?.call(updatedProject);
        } catch (e) {
          _showErrorDialog('Failed to create folder: $e');
        }
      },
    );
  }

  void _showRenameFileDialog(ProjectFile file) {
    final controller = TextEditingController(text: file.fileName);
    
    void performRename() {
      final newName = controller.text.trim();
      if (newName.isNotEmpty && FileOperations.isValidFileName(newName)) {
        try {
          final pathParts = file.path.split('/');
          pathParts[pathParts.length - 1] = newName;
          final newPath = pathParts.join('/');
          final updatedProject = ProjectManager.renameFile(widget.project, file.path, newPath);
          widget.onProjectUpdated?.call(updatedProject);
          Navigator.of(context).pop();
        } catch (e) {
          _showErrorDialog('Failed to rename file: $e');
        }
      } else {
        _showErrorDialog('Please enter a valid file name');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new file name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => performRename(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: performRename,
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRenameDirectoryDialog(String dirPath, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    void performRename() {
      final newName = controller.text.trim();
      if (newName.isNotEmpty && FileOperations.isValidDirectoryName(newName)) {
        try {
          final pathParts = dirPath.split('/');
          pathParts[pathParts.length - 1] = newName;
          final newPath = pathParts.join('/');
          final updatedProject = ProjectManager.renameDirectory(widget.project, dirPath, newPath);
          widget.onProjectUpdated?.call(updatedProject);
          Navigator.of(context).pop();
        } catch (e) {
          _showErrorDialog('Failed to rename folder: $e');
        }
      } else {
        _showErrorDialog('Please enter a valid folder name');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new folder name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => performRename(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: performRename,
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _duplicateFile(ProjectFile file) {
    try {
      final pathParts = file.path.split('/');
      final directory = pathParts.length > 1 ? pathParts.sublist(0, pathParts.length - 1).join('/') : '';
      final existingNames = ProjectManager.getExistingFileNames(widget.project, directory);
      final newFileName = FileOperations.generateUniqueFileName(file.fileName, existingNames);
      final newPath = directory.isEmpty ? newFileName : '$directory/$newFileName';
      
      final updatedProject = ProjectManager.createFile(widget.project, newPath, file.content);
      widget.onProjectUpdated?.call(updatedProject);
    } catch (e) {
      _showErrorDialog('Failed to duplicate file: $e');
    }
  }

  void _showDeleteConfirmation({ProjectFile? file, String? directoryPath}) {
    final isFile = file != null;
    final name = isFile ? file.fileName : directoryPath!.split('/').last;
    final type = isFile ? 'file' : 'folder';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete "$name"?${isFile ? '' : ' This will also delete all files inside it.'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final updatedProject = isFile 
                  ? ProjectManager.deleteFile(widget.project, file.path)
                  : ProjectManager.deleteDirectory(widget.project, directoryPath!);
                widget.onProjectUpdated?.call(updatedProject);
                Navigator.of(context).pop();
              } catch (e) {
                _showErrorDialog('Failed to delete $type: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog({
    required String title,
    required String hintText,
    List<String>? templates,
    required Function(String name, String? template) onConfirm,
  }) {
    final controller = TextEditingController();
    String? selectedTemplate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (templates != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Template (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: templates.map((template) => DropdownMenuItem(
                    value: template,
                    child: Text(template),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedTemplate = value),
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  onConfirm(name, selectedTemplate);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryItem(String name, int depth, bool isExpanded, VoidCallback onTap) {
    final theme = Theme.of(context);
    final dirPath = _buildFullPathFromDepth(name, depth);
    
    return GestureDetector(
      onSecondaryTapDown: (details) => _showDirectoryContextMenu(context, details.globalPosition, dirPath, name),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + (depth * 20.0),
            right: 16,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.folder_open : Icons.folder,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(ProjectFile file, int depth) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedFile?.path == file.path;
    
    return GestureDetector(
      onSecondaryTapDown: (details) => _showFileContextMenu(context, details.globalPosition, file),
      child: InkWell(
        onTap: () => widget.onFileSelected(file),
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + (depth * 20.0) + 20.0, // Extra indent for files
            right: 16,
            top: 6,
            bottom: 6,
          ),
          decoration: isSelected ? BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ) : null,
          child: Row(
            children: [
              Icon(
                file.type.icon,
                size: 16,
                color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectInfoDialog() {
    final project = widget.project;
    final dartFiles = project.files.where((f) => f.isDartFile).length;
    final totalFiles = project.files.where((f) => !f.isDirectory).length;
    final directories = project.files.where((f) => f.isDirectory).length;
    final hasTests = project.files.any((f) => f.path.startsWith('test/'));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Project Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', project.name),
            const SizedBox(height: 8),
            _buildInfoRow('Created:', _formatDate(project.uploadedAt)),
            const SizedBox(height: 8),
            _buildInfoRow('Total Files:', '$totalFiles'),
            const SizedBox(height: 8),
            _buildInfoRow('Dart Files:', '$dartFiles'),
            const SizedBox(height: 8),
            _buildInfoRow('Directories:', '$directories'),
            const SizedBox(height: 8),
            _buildInfoRow('Has Tests:', hasTests ? 'Yes' : 'No'),
            const SizedBox(height: 8),
            _buildInfoRow('Valid Flutter Project:', project.isValidFlutterProject ? 'Yes' : 'No'),
            if (project.pubspecFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Dependencies:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    _extractDependenciesInfo(project.pubspecFile!.content),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => ExportProjectDialog(project: project),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _extractDependenciesInfo(String pubspecContent) {
    final lines = pubspecContent.split('\n');
    final dependencies = <String>[];
    bool inDependencies = false;
    
    for (final line in lines) {
      if (line.trim() == 'dependencies:') {
        inDependencies = true;
        continue;
      }
      if (inDependencies) {
        if (line.startsWith('  ') && line.contains(':')) {
          dependencies.add(line.trim());
        } else if (!line.startsWith('  ') && line.trim().isNotEmpty) {
          break;
        }
      }
    }
    
    return dependencies.isEmpty 
        ? 'No dependencies found' 
        : dependencies.join('\n');
  }
}