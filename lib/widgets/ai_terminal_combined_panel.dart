import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kre8tions/models/flutter_project.dart';
import 'package:kre8tions/models/project_file.dart';
import 'package:kre8tions/models/widget_selection.dart';
import 'package:kre8tions/openai/openai_config.dart';
import 'package:kre8tions/services/file_operations.dart';
import 'package:kre8tions/widgets/ai_assistant_panel.dart';
import 'package:kre8tions/widgets/terminal_panel.dart';

class AiTerminalCombinedPanel extends StatefulWidget {
  final ProjectFile? selectedFile;
  final WidgetSelection? selectedWidget;
  final Function(String)? onCodeGenerated;
  final Function()? onProjectUpdated;
  final FlutterProject? project;
  
  const AiTerminalCombinedPanel({
    super.key,
    this.selectedFile,
    this.selectedWidget,
    this.onCodeGenerated,
    this.onProjectUpdated,
    this.project,
  });

  @override
  State<AiTerminalCombinedPanel> createState() => _AiTerminalCombinedPanelState();
}

class _AiTerminalCombinedPanelState extends State<AiTerminalCombinedPanel> {
  double _aiPanelHeight = 0.6; // 60% for AI, 40% for terminal
  bool _isDragging = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final aiHeight = totalHeight * _aiPanelHeight;
        final terminalHeight = totalHeight * (1 - _aiPanelHeight);
        
        return Column(
          children: [
            // AI Assistant Section
            SizedBox(
              height: aiHeight,
              child: AIAssistantPanel(
                selectedFile: widget.selectedFile,
                selectedWidget: widget.selectedWidget,
                currentProject: widget.project,
                onCodeGenerated: widget.onCodeGenerated,
                onFilesGenerated: _handleFilesGenerated,
              ),
            ),
            
            // Resizable Divider
            _buildResizeDivider(theme),
            
            // Terminal Section
            SizedBox(
              height: terminalHeight - 8, // Subtract divider height
              child: TerminalPanel(
                height: terminalHeight - 8,
                project: widget.project,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildResizeDivider(ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          if (!_isDragging) return;
          
          setState(() {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final totalHeight = renderBox.size.height;
            
            // Calculate new ratio based on drag position
            final newRatio = (details.globalPosition.dy - renderBox.localToGlobal(Offset.zero).dy) / totalHeight;
            
            // Clamp between 20% and 80% to prevent either section from becoming too small
            _aiPanelHeight = newRatio.clamp(0.2, 0.8);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: _isDragging 
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.1),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: _isDragging 
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleFilesGenerated(List<FileOperation> operations) async {
    try {
      // Web version: Download files individually
      for (final operation in operations) {
        // Convert content to bytes and download
        final bytes = utf8.encode(operation.content);
        FileOperations.downloadFile(bytes, operation.filePath.split('/').last);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generated \${operations.length} files downloaded!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent to refresh project
        widget.onProjectUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error downloading files: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}