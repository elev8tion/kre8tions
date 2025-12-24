import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/services/dart_intelligence_service.dart';
import 'package:kre8tions/services/service_orchestrator.dart';
import 'package:kre8tions/services/code_execution_service.dart';
import 'dart:async';

class EnhancedCodeEditor extends StatefulWidget {
  final ProjectFile? file;
  final Function(String, String)? onContentChanged;

  const EnhancedCodeEditor({
    super.key,
    this.file,
    this.onContentChanged,
  });

  @override
  State<EnhancedCodeEditor> createState() => _EnhancedCodeEditorState();
}

class _EnhancedCodeEditorState extends State<EnhancedCodeEditor> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  late ServiceOrchestrator _orchestrator;
  
  int _lineCount = 1;
  List<CodeError> _errors = [];
  List<AutocompleteSuggestion> _suggestions = [];
  bool _showingSuggestions = false;
  OverlayEntry? _suggestionOverlay;
  
  // 🔥 Live Analysis State
  bool _isLiveAnalysisActive = false;
  ExecutionResult? _lastExecutionResult;
  StreamSubscription? _analysisSubscription;
  Timer? _liveUpdateTimer;
  
  // 🚀 NAVIGATION STATE
  Map<String, List<SymbolDefinition>> _symbolIndex = {};
  HoverInfo? _hoverInfo;
  OverlayEntry? _hoverOverlay;
  Timer? _hoverTimer;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _orchestrator = ServiceOrchestrator.instance;
    _updateContent();
    
    // 🎯 Setup Service Orchestrator Integration
    _setupLiveAnalysis();
    
    // 🚀 Setup Symbol Indexing
    _buildSymbolIndex();
    
    // Listen to text changes for real-time intelligence
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(EnhancedCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file?.path != widget.file?.path) {
      _updateContent();
    }
  }

  @override
  void dispose() {
    _hideSuggestions();
    _hideHover();
    _analysisSubscription?.cancel();
    _liveUpdateTimer?.cancel();
    _hoverTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateContent() {
    if (widget.file != null) {
      _controller.text = widget.file!.content;
      _updateLineCount();
      _analyzeCode();
    } else {
      _controller.text = '';
      _lineCount = 1;
      _errors.clear();
    }
  }

  void _onTextChanged() {
    _updateLineCount();
    _analyzeCode();
    
    // Trigger autocomplete
    final cursorPosition = _controller.selection.baseOffset;
    if (cursorPosition >= 0) {
      _updateAutocomplete(cursorPosition);
    }
    
    // 🚀 Rebuild symbol index when content changes
    if (widget.file?.path.endsWith('.dart') == true) {
      _buildSymbolIndex();
    }
    
    if (widget.file != null && widget.onContentChanged != null) {
      widget.onContentChanged!(widget.file!.path, _controller.text);
    }
  }

  void _updateLineCount() {
    setState(() {
      _lineCount = _controller.text.split('\n').length;
    });
  }

  void _analyzeCode() {
    if (widget.file?.path.endsWith('.dart') == true) {
      // 🔥 Use live analysis from Service Orchestrator
      _triggerLiveAnalysis();
      
      // Fallback to basic analysis if live analysis not available
      if (!_isLiveAnalysisActive) {
        setState(() {
          _errors = DartIntelligenceService.detectErrors(_controller.text);
        });
      }
    }
  }

  void _updateAutocomplete(int cursorPosition) {
    if (widget.file?.path.endsWith('.dart') == true) {
      final suggestions = DartIntelligenceService.getAutocompleteSuggestions(
        _controller.text, 
        cursorPosition
      );
      
      if (suggestions.isNotEmpty) {
        _showSuggestions(suggestions);
      } else {
        _hideSuggestions();
      }
    }
  }

  void _showSuggestions(List<AutocompleteSuggestion> suggestions) {
    if (!mounted) return;
    
    _hideSuggestions();
    
    setState(() {
      _suggestions = suggestions.take(8).toList(); // Limit suggestions
      _showingSuggestions = true;
    });
    
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    
    _suggestionOverlay = OverlayEntry(
      builder: (context) => _buildSuggestionOverlay(position),
    );
    
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  void _hideSuggestions() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
    
    if (mounted) {
      setState(() {
        _showingSuggestions = false;
        _suggestions.clear();
      });
    }
  }
  
  /// 🎯 **SETUP LIVE ANALYSIS INTEGRATION**
  void _setupLiveAnalysis() {
    // Listen to live analysis updates from Service Orchestrator
    _analysisSubscription = _orchestrator.analysisStream.listen((update) {
      if (mounted && widget.file?.path == update.file?.path) {
        setState(() {
          _lastExecutionResult = update.executionResult;
          _errors = update.executionResult.errors;
          _isLiveAnalysisActive = true;
        });
      }
    });
  }
  
  /// ⚡ **TRIGGER LIVE ANALYSIS**
  void _triggerLiveAnalysis() {
    if (widget.file == null) return;
    
    // Debounce live updates to avoid overwhelming the system
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) {
        _orchestrator.updateCode(_controller.text);
      }
    });
  }

  /// 🎆 **BUILD LIVE ANALYSIS STATUS BAR**
  Widget _buildAnalysisStatusBar(ThemeData theme) {
    if (!_isLiveAnalysisActive || _lastExecutionResult == null) {
      return const SizedBox.shrink();
    }
    
    final result = _lastExecutionResult!;
    final errorCount = result.errors.length;
    final warningCount = result.warnings.length;
    final hasErrors = errorCount > 0;
    
    Color statusColor = theme.colorScheme.tertiary;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'Code Analysis: OK';
    
    if (hasErrors) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error;
      statusText = '$errorCount errors, $warningCount warnings';
    } else if (warningCount > 0) {
      statusColor = theme.colorScheme.secondary;
      statusIcon = Icons.warning;
      statusText = '$warningCount warnings detected';
    }
    
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (result.performance != null) ...[
            Icon(
              Icons.speed,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              result.performance!.grade,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionOverlay(Offset position) {
    final theme = Theme.of(context);
    
    return Positioned(
      left: position.dx + 60, // Offset from line numbers
      top: position.dy + 80,  // Offset from header
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return _buildSuggestionItem(suggestion, theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(AutocompleteSuggestion suggestion, ThemeData theme) {
    Color typeColor;
    IconData typeIcon;
    
    switch (suggestion.type) {
      case SuggestionType.widget:
        typeColor = Colors.blue;
        typeIcon = Icons.widgets;
        break;
      case SuggestionType.keyword:
        typeColor = Colors.purple;
        typeIcon = Icons.code;
        break;
      case SuggestionType.type:
        typeColor = Colors.teal;
        typeIcon = Icons.data_object;
        break;
      case SuggestionType.import:
        typeColor = Colors.green;
        typeIcon = Icons.input;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
    }
    
    return InkWell(
      onTap: () => _applySuggestion(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(typeIcon, size: 16, color: typeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    suggestion.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applySuggestion(AutocompleteSuggestion suggestion) {
    final cursorPosition = _controller.selection.baseOffset;
    final text = _controller.text;
    
    // Find the start of the word being completed
    int wordStart = cursorPosition;
    while (wordStart > 0 && 
           RegExp(r'[a-zA-Z0-9_]').hasMatch(text[wordStart - 1])) {
      wordStart--;
    }
    
    // Replace the partial word with the suggestion
    final newText = text.substring(0, wordStart) + 
                   suggestion.insertText + 
                   text.substring(cursorPosition);
    
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: wordStart + suggestion.insertText.length
    );
    
    _hideSuggestions();
  }

  void _formatCode() {
    if (widget.file?.path.endsWith('.dart') == true) {
      final formatted = DartIntelligenceService.formatCode(_controller.text);
      _controller.text = formatted;
      _analyzeCode();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code formatted successfully')),
      );
    }
  }

  void _showImportSuggestions() {
    if (widget.file?.path.endsWith('.dart') == true) {
      final imports = DartIntelligenceService.suggestImports(_controller.text);
      if (imports.isNotEmpty) {
        _showImportDialog(imports);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No missing imports detected')),
        );
      }
    }
  }

  void _showImportDialog(List<String> imports) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Imports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: imports.map((import) => ListTile(
            leading: const Icon(Icons.input, color: Colors.green),
            title: Text(import, style: const TextStyle(fontFamily: 'monospace')),
            onTap: () {
              // Add import to the top of the file
              final lines = _controller.text.split('\n');
              final importLines = <String>[];
              final codeLines = <String>[];
              
              bool foundFirstImport = false;
              for (final line in lines) {
                if (line.startsWith('import ')) {
                  importLines.add(line);
                  foundFirstImport = true;
                } else if (foundFirstImport && line.trim().isEmpty) {
                  importLines.add(line);
                } else {
                  codeLines.add(line);
                }
              }
              
              importLines.add(import);
              importLines.add('');
              
              _controller.text = [...importLines, ...codeLines].join('\n');
              Navigator.of(context).pop();
              _analyzeCode();
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// 🚀 NAVIGATION FUNCTIONALITY
  
  void _buildSymbolIndex() {
    // Get all project files from the orchestrator
    final projectFiles = _orchestrator.getAllProjectFiles();
    if (projectFiles.isNotEmpty) {
      _symbolIndex = DartIntelligenceService.buildSymbolIndex(projectFiles);
    }
  }

  void _goToDefinition() {
    if (widget.file?.path.endsWith('.dart') != true) return;
    
    final cursorPosition = _controller.selection.baseOffset;
    final projectFiles = _orchestrator.getAllProjectFiles();
    
    final definition = DartIntelligenceService.findDefinition(
      _controller.text,
      cursorPosition,
      projectFiles,
    );
    
    if (definition != null) {
      _navigateToDefinition(definition);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No definition found for symbol'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _findReferences() {
    if (widget.file?.path.endsWith('.dart') != true) return;
    
    final cursorPosition = _controller.selection.baseOffset;
    final symbol = _getWordAtCursor(cursorPosition);
    
    if (symbol.isEmpty) return;
    
    final projectFiles = _orchestrator.getAllProjectFiles();
    final references = DartIntelligenceService.findReferences(symbol, projectFiles);
    
    _showReferencesDialog(symbol, references);
  }

  void _navigateToDefinition(DefinitionResult definition) {
    if (definition.filePath == 'current') {
      // Navigate within current file
      _jumpToLine(definition.line);
    } else {
      // Navigate to different file - notify parent to open file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Definition found in ${definition.filePath}:${definition.line}'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () {
              // TODO: Implement file navigation through parent callback
            },
          ),
        ),
      );
    }
  }

  void _jumpToLine(int lineNumber) {
    final lines = _controller.text.split('\n');
    if (lineNumber > 0 && lineNumber <= lines.length) {
      int offset = 0;
      for (int i = 0; i < lineNumber - 1; i++) {
        offset += lines[i].length + 1; // +1 for newline
      }
      
      _controller.selection = TextSelection.collapsed(offset: offset);
      
      // Scroll to show the line
      const lineHeight = 19.6; // Match line height
      final targetOffset = (lineNumber - 1) * lineHeight;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showReferencesDialog(String symbol, List<ReferenceLocation> references) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('References to "$symbol"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: references.isEmpty
              ? const Center(child: Text('No references found'))
              : ListView.builder(
                  itemCount: references.length,
                  itemBuilder: (context, index) {
                    final reference = references[index];
                    return ListTile(
                      leading: Icon(
                        Icons.code,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      title: Text(
                        '${reference.filePath}:${reference.line}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        reference.context,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (reference.filePath == widget.file?.path) {
                          _jumpToLine(reference.line);
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHover(Offset position, HoverInfo hoverInfo) {
    _hideHover();
    
    _hoverOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy - 80,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hoverInfo.symbol,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hoverInfo.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hoverInfo.signature.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hoverInfo.signature,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  hoverInfo.documentation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_hoverOverlay!);
  }

  void _hideHover() {
    _hoverOverlay?.remove();
    _hoverOverlay = null;
    _hoverTimer?.cancel();
  }

  void _onHover(PointerHoverEvent event) {
    if (widget.file?.path.endsWith('.dart') != true) return;
    
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      final cursorPosition = _controller.selection.baseOffset;
      final hoverInfo = DartIntelligenceService.getHoverInfo(
        _controller.text,
        cursorPosition,
        _symbolIndex,
      );
      
      if (hoverInfo != null && mounted) {
        _showHover(event.position, hoverInfo);
      }
    });
  }

  String _getWordAtCursor(int position) {
    if (position >= _controller.text.length || position < 0) return '';
    
    final text = _controller.text;
    int start = position;
    int end = position;
    
    // Find start of word
    while (start > 0 && RegExp(r'[a-zA-Z0-9_]').hasMatch(text[start - 1])) {
      start--;
    }
    
    // Find end of word
    while (end < text.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(text[end])) {
      end++;
    }
    
    return text.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.file == null) {
      return _buildEmptyState(theme);
    }

    if (!widget.file!.isTextFile) {
      return _buildNonTextFileView(theme);
    }

    return GestureDetector(
      onTap: _hideSuggestions,
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF16171B),  // Changed from blue-tinted 0xFF1E293B to neutral dark
          border: Border.all(
            color: theme.brightness == Brightness.light
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF26272B),  // Changed from blue-tinted 0xFF334155 to neutral border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildEnhancedHeader(theme),
            if (_errors.isNotEmpty) _buildErrorPanel(theme),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedLineNumbers(theme),
                  Expanded(
                    child: _buildEnhancedEditor(theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Enhanced Code Editor',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a file to experience intelligent coding',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.palette, size: 16),
                  label: const Text('Syntax Highlighting'),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                ),
                Chip(
                  avatar: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Smart Autocomplete'),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                ),
                Chip(
                  avatar: const Icon(Icons.error_outline, size: 16),
                  label: const Text('Error Detection'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonTextFileView(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.file!.type.icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Binary file cannot be edited',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.file!.fileName,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme) {
    final isDartFile = widget.file?.path.endsWith('.dart') == true;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.file!.type.icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.file!.path,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDartFile) ...[
            IconButton(
              onPressed: _goToDefinition,
              icon: const Icon(Icons.navigation, size: 16),
              tooltip: 'Go to Definition (F12)',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _findReferences,
              icon: const Icon(Icons.search, size: 16),
              tooltip: 'Find References (Ctrl+D)',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _formatCode,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              tooltip: 'Format Code (Ctrl+Shift+F)',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _showImportSuggestions,
              icon: const Icon(Icons.input, size: 16),
              tooltip: 'Organize Imports',
              visualDensity: VisualDensity.compact,
            ),
          ],
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _controller.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy code',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_errors.length} error${_errors.length == 1 ? '' : 's'} found',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLineNumbers(ThemeData theme) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_lineCount, (index) {
          final lineNumber = index + 1;
          final hasError = _errors.any((error) => error.line == lineNumber);
          
          return Container(
            height: 19.6, // Match line height
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasError) ...[
                  Icon(
                    Icons.error,
                    size: 12,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$lineNumber',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError 
                        ? Colors.red[600]
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: hasError ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedEditor(ThemeData theme) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Ctrl+Shift+F for formatting
          if (event.logicalKey == LogicalKeyboardKey.keyF &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            _formatCode();
          }
          // F12 for go-to-definition
          if (event.logicalKey == LogicalKeyboardKey.f12) {
            _goToDefinition();
          }
          // Ctrl+D for find references
          if (event.logicalKey == LogicalKeyboardKey.keyD &&
              HardwareKeyboard.instance.isControlPressed) {
            _findReferences();
          }
          // Escape to hide suggestions and hover
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _hideSuggestions();
            _hideHover();
          }
        }
      },
      child: Scrollbar(
        controller: _scrollController,
        child: widget.file?.path.endsWith('.dart') == true
            ? _buildSyntaxHighlightedEditor(theme)
            : _buildPlainEditor(theme),
      ),
    );
  }

  Widget _buildSyntaxHighlightedEditor(ThemeData theme) {
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _hideHover(),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              // Syntax highlighted text overlay
              _buildSyntaxHighlightedText(theme),
              // Invisible text field for input
              TextField(
                controller: _controller,
                maxLines: null,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.transparent, // Hide regular text
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => _onTextChanged(),
                onTap: _hideSuggestions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedText(ThemeData theme) {
    if (_controller.text.isEmpty) return const SizedBox.shrink();
    
    final spans = DartIntelligenceService.generateSyntaxHighlighting(
      _controller.text,
      theme,
    );
    
    return IgnorePointer(
      child: RichText(
        text: TextSpan(
          children: spans,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildPlainEditor(ThemeData theme) {
    return TextField(
      controller: _controller,
      scrollController: _scrollController,
      maxLines: null,
      expands: true,
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.4,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
      onChanged: (_) => _onTextChanged(),
      onTap: _hideSuggestions,
    );
  }
}