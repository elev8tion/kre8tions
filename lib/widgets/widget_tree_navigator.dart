import 'package:flutter/material.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/services/dart_ast_parser_service.dart';
import 'package:kre8tions/services/code_execution_service.dart';

/// Widget Tree Navigator - Shows hierarchical widget structure from Flutter code
///
/// **TRACK D Implementation**
/// - Parses Dart code using DartASTParserService
/// - Displays widget tree with expand/collapse
/// - Widget type icons (layout/input/display/component)
/// - Click to select widget
/// - Search/filter widgets
/// - Integration with visual builder workflow
class WidgetTreeNavigator extends StatefulWidget {
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final Function(WidgetSelection) onWidgetSelected;

  const WidgetTreeNavigator({
    super.key,
    required this.selectedFile,
    this.selectedWidget,
    required this.onWidgetSelected,
  });

  @override
  State<WidgetTreeNavigator> createState() => _WidgetTreeNavigatorState();
}

class _WidgetTreeNavigatorState extends State<WidgetTreeNavigator> {
  final DartAstParserService _astParser = DartAstParserService.instance;
  final TextEditingController _searchController = TextEditingController();

  WidgetTreeNode? _widgetTree;
  bool _isLoading = false;
  String _searchQuery = '';
  final Set<String> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    _loadWidgetTree();
  }

  @override
  void didUpdateWidget(WidgetTreeNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFile != oldWidget.selectedFile) {
      _loadWidgetTree();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWidgetTree() async {
    if (widget.selectedFile == null) {
      setState(() {
        _widgetTree = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tree = await _astParser.parseWidgetTree(
        widget.selectedFile!.content,
        widget.selectedFile!.path,
      );

      setState(() {
        _widgetTree = tree;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading widget tree: $e');
      setState(() {
        _widgetTree = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildSearchBar(theme),
          Expanded(
            child: _buildTreeContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Widget Tree',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loadWidgetTree,
            tooltip: 'Refresh tree',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search widgets...',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        style: theme.textTheme.bodySmall,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildTreeContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.selectedFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No file selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_widgetTree == null || _widgetTree!.children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No widgets found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: _widgetTree!.children
          .map((node) => _buildTreeNode(theme, node, 0))
          .toList(),
    );
  }

  Widget _buildTreeNode(ThemeData theme, WidgetTreeNode node, int depth) {
    final isSelected = widget.selectedWidget?.widgetId == '${node.name}_${node.line}';
    final hasChildren = node.children.isNotEmpty;
    final nodeId = '${node.name}_${node.line}_$depth';
    final isExpanded = _expandedNodes.contains(nodeId);

    // Filter by search query
    if (_searchQuery.isNotEmpty && !node.name.toLowerCase().contains(_searchQuery)) {
      // Check if any children match
      final hasMatchingChild = _hasMatchingDescendant(node, _searchQuery);
      if (!hasMatchingChild) {
        return const SizedBox.shrink();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _handleNodeTap(node),
          child: Container(
            padding: EdgeInsets.only(
              left: depth * 16.0 + 8,
              right: 8,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedNodes.remove(nodeId);
                        } else {
                          _expandedNodes.add(nodeId);
                        }
                      });
                    },
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                _getWidgetIcon(node.type, theme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ':${node.line}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...node.children.map((child) => _buildTreeNode(theme, child, depth + 1)),
      ],
    );
  }

  bool _hasMatchingDescendant(WidgetTreeNode node, String query) {
    for (final child in node.children) {
      if (child.name.toLowerCase().contains(query)) {
        return true;
      }
      if (_hasMatchingDescendant(child, query)) {
        return true;
      }
    }
    return false;
  }

  void _handleNodeTap(WidgetTreeNode node) {
    final selection = WidgetSelection(
      widgetType: node.name,
      widgetId: '${node.name}_${node.line}',
      filePath: widget.selectedFile?.path ?? '',
      lineNumber: node.line,
      properties: node.properties,
      sourceCode: '',
    );
    widget.onWidgetSelected(selection);
  }

  Icon _getWidgetIcon(WidgetType type, ThemeData theme) {
    final iconData = _getIconData(type);
    final color = _getIconColor(type, theme);

    return Icon(
      iconData,
      size: 16,
      color: color,
    );
  }

  IconData _getIconData(WidgetType type) {
    switch (type) {
      case WidgetType.layout:
        return Icons.crop_square; // 📐
      case WidgetType.input:
        return Icons.edit; // 📝
      case WidgetType.display:
        return Icons.palette; // 🎨
      case WidgetType.component:
        return Icons.extension; // 🔧
      case WidgetType.app:
        return Icons.phone_android; // 📱
      case WidgetType.root:
        return Icons.account_tree;
      default:
        return Icons.widgets;
    }
  }

  Color _getIconColor(WidgetType type, ThemeData theme) {
    switch (type) {
      case WidgetType.layout:
        return Colors.blue.shade400;
      case WidgetType.input:
        return Colors.green.shade400;
      case WidgetType.display:
        return Colors.purple.shade400;
      case WidgetType.component:
        return Colors.orange.shade400;
      case WidgetType.app:
        return Colors.red.shade400;
      case WidgetType.root:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
