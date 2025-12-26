import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/ide_inspector_service.dart';

/// Inspector banner at the top
class InspectorBanner extends StatelessWidget {
  final VoidCallback onClose;

  const InspectorBanner({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IDE Inspector Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Click any widget to inspect',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'F2 to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget path breadcrumb navigation
class WidgetPathBreadcrumb extends StatelessWidget {
  final List<IDEWidgetInfo> path;
  final ValueChanged<IDEWidgetInfo> onSelect;

  const WidgetPathBreadcrumb({
    super.key,
    required this.path,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.account_tree, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              ...List.generate(path.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  );
                }

                final widgetIndex = index ~/ 2;
                final widget = path[widgetIndex];
                final isLast = widgetIndex == path.length - 1;

                return InkWell(
                  onTap: () => onSelect(widget),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLast ? Colors.blue.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.widgetType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                        color: isLast ? Colors.blue.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced note panel with rich features
class EnhancedNotePanel extends StatelessWidget {
  final IDEWidgetInfo widget;
  final TextEditingController noteController;
  final NoteAction selectedAction;
  final ui.Image? screenshot;
  final ValueChanged<NoteAction> onActionChanged;
  final VoidCallback onSendNote;
  final VoidCallback onClose;

  const EnhancedNotePanel({
    super.key,
    required this.widget,
    required this.noteController,
    required this.selectedAction,
    this.screenshot,
    required this.onActionChanged,
    required this.onSendNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade700],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Widget Modification Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Tell Claude exactly what you want',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Widget info card
                    _WidgetInfoCard(widget: widget),

                    const SizedBox(height: 16),

                    // Action selector
                    const Text(
                      'What do you want to do?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ActionSelector(
                      selectedAction: selectedAction,
                      onChanged: onActionChanged,
                    ),

                    const SizedBox(height: 16),

                    // Note editor
                    const Text(
                      'Describe your request:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Example: "Change the background color to blue and increase the padding to 16px"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    // Quick suggestions
                    _QuickSuggestions(
                      widgetType: widget.widgetType,
                      onSuggestionTap: (suggestion) {
                        noteController.text = suggestion;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Send button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onSendNote,
                        icon: const Icon(Icons.send, size: 20),
                        label: const Text(
                          'Send to Claude & Copy to Clipboard',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your request will be formatted and copied. Just paste it to Claude!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade900,
                              ),
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
      ),
    );
  }
}

class _WidgetInfoCard extends StatelessWidget {
  final IDEWidgetInfo widget;

  const _WidgetInfoCard({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.widgetType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.size.width.toInt()} × ${widget.size.height.toInt()}px',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on, label: 'Location', value: widget.location),
          _InfoRow(icon: Icons.code, label: 'File', value: widget.sourceFile),
          if (widget.properties.containsKey('text'))
            _InfoRow(icon: Icons.text_fields, label: 'Text', value: widget.properties['text'].toString()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSelector extends StatelessWidget {
  final NoteAction selectedAction;
  final ValueChanged<NoteAction> onChanged;

  const _ActionSelector({
    required this.selectedAction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: NoteAction.values.map((action) {
        final isSelected = action == selectedAction;
        return ChoiceChip(
          label: Text(
            action.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(action),
          selectedColor: Colors.blue.shade200,
          backgroundColor: Colors.grey.shade100,
        );
      }).toList(),
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  final String widgetType;
  final ValueChanged<String> onSuggestionTap;

  const _QuickSuggestions({
    required this.widgetType,
    required this.onSuggestionTap,
  });

  List<String> _getSuggestions() {
    final suggestions = <String>[];

    if (widgetType.contains('Text')) {
      suggestions.addAll([
        'Change the text color to blue',
        'Increase font size to 16px',
        'Make the text bold',
      ]);
    } else if (widgetType.contains('Button')) {
      suggestions.addAll([
        'Change button color to purple',
        'Add rounded corners',
        'Increase button padding',
      ]);
    } else if (widgetType.contains('Container') || widgetType.contains('Box')) {
      suggestions.addAll([
        'Add background color',
        'Add border radius',
        'Increase padding to 16px',
      ]);
    } else {
      suggestions.addAll([
        'Change the styling',
        'Adjust the layout',
        'Remove this widget',
      ]);
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick suggestions:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions.map((suggestion) {
            return InkWell(
              onTap: () => onSuggestionTap(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
