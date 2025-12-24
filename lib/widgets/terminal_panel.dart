import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/services/enhanced_terminal_service.dart';

class TerminalPanel extends StatefulWidget {
  final double height;
  final FlutterProject? project;
  
  const TerminalPanel({
    super.key,
    this.height = 300.0,
    this.project,
  });

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EnhancedTerminalService _terminalService = EnhancedTerminalService();
  final List<String> _commandHistory = [];
  int _commandHistoryIndex = -1;
  String _currentDirectory = '';
  bool _isExecutingCommand = false;
  StreamSubscription<TerminalCommand>? _commandSubscription;
  
  @override
  void initState() {
    super.initState();
    _getCurrentDirectory();
    _addWelcomeMessage();
    
    // Listen to command stream
    _commandSubscription = _terminalService.commandStream.listen((command) {
      setState(() {
        // Update UI when commands complete
      });
      _scrollToBottom();
    });
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _commandSubscription?.cancel();
    super.dispose();
  }
  
  void _getCurrentDirectory() {
    try {
      _currentDirectory = '/project/${widget.project?.name ?? 'unnamed'}';
    } catch (e) {
      _currentDirectory = '/project';
    }
  }
  
  void _addWelcomeMessage() {
    // Welcome message is now handled by the enhanced terminal service
    // Initial help command will show the welcome
    _terminalService.executeCommand('help', widget.project);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light 
          ? const Color(0xFF1E1E1E) 
          : const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(theme),
          Expanded(
            child: _buildTerminalContent(theme),
          ),
          _buildCommandInput(theme),
        ],
      ),
    );
  }
  
  Widget _buildTerminalHeader(ThemeData theme) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light 
          ? const Color(0xFF2D2D30) 
          : const Color(0xFF161B22),
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
            Icons.terminal,
            size: 14,
            color: Colors.green.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Text(
            'Terminal',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            _getShortPath(_currentDirectory),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearTerminal,
            icon: const Icon(Icons.clear, size: 14),
            tooltip: 'Clear terminal',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            iconSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTerminalContent(ThemeData theme) {
    final history = _terminalService.history;
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...history.expand((command) => _buildCommandOutput(command, theme)),
              if (_isExecutingCommand) _buildExecutingIndicator(theme),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCommandOutput(TerminalCommand command, ThemeData theme) {
    final widgets = <Widget>[];
    
    // Command line
    widgets.add(
      _buildTerminalLine(
        '${_getPrompt()}\$ ${command.command}',
        Colors.cyan,
        theme,
        isCommand: true,
      ),
    );
    
    // Output lines
    for (final line in command.output) {
      Color color;
      switch (command.status) {
        case CommandStatus.success:
          color = line.startsWith('✅') || line.startsWith('✓') 
            ? Colors.green.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9);
          break;
        case CommandStatus.error:
          color = Colors.red.withValues(alpha: 0.8);
          break;
        case CommandStatus.running:
          color = Colors.yellow.withValues(alpha: 0.8);
          break;
        default:
          color = Colors.white.withValues(alpha: 0.9);
      }
      
      if (line.contains('🔍') || line.contains('📁') || line.contains('🚀') ||
          line.contains('💡') || line.contains('🔧') || line.contains('🎯')) {
        color = Colors.blue.withValues(alpha: 0.8);
      }
      
      widgets.add(_buildTerminalLine(line, color, theme));
    }
    
    // Status indicator for running commands
    if (command.status == CommandStatus.running) {
      widgets.add(_buildRunningIndicator(theme));
    }
    
    // Empty line between commands
    widgets.add(const SizedBox(height: 8));
    
    return widgets;
  }

  Widget _buildExecutingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Executing command...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.cyan.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Running...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.yellow.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getPrompt() {
    final projectName = widget.project?.name ?? 'project';
    return projectName;
  }
  
  Widget _buildTerminalLine(String content, Color color, ThemeData theme, {bool isCommand = false}) {
    if (content.trim().isEmpty) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SelectableText(
        content,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: color,
          height: 1.4,
          fontWeight: isCommand ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget _buildCommandInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light 
          ? const Color(0xFF2D2D30) 
          : const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_getPrompt()}\$',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              onSubmitted: _executeCommand,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter command...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                // Reset command history navigation when typing
                if (_commandHistoryIndex != -1) {
                  _commandHistoryIndex = -1;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    // Add command to history
    _commandHistory.add(command);
    _commandHistoryIndex = -1;
    
    // Clear input
    _inputController.clear();
    
    // Set executing state
    setState(() {
      _isExecutingCommand = true;
    });
    
    try {
      // Execute command using enhanced terminal service
      await _terminalService.executeCommand(command.trim(), widget.project);
    } catch (e) {
      // Error handling is done by the terminal service
    } finally {
      setState(() {
        _isExecutingCommand = false;
      });
    }
    
    // Scroll to bottom
    _scrollToBottom();
  }
  
  void _clearTerminal() {
    _terminalService.clearHistory();
    setState(() {
      // Trigger rebuild
    });
  }
  
  String _getShortPath(String path) {
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 2) return path;
    return '...${Platform.pathSeparator}${parts.sublist(parts.length - 2).join(Platform.pathSeparator)}';
  }
}