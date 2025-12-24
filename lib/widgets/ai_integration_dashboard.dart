import 'package:flutter/material.dart';
import 'package:kre8tions/theme.dart';
import 'dart:async';
import 'dart:math' as math;

/// 🤖 **ADVANCED AI INTEGRATION DASHBOARD**
/// Complete AI-powered development assistance with context awareness
class AIIntegrationDashboard extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;

  const AIIntegrationDashboard({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapsed,
  });

  @override
  State<AIIntegrationDashboard> createState() => _AIIntegrationDashboardState();
}

class _AIIntegrationDashboardState extends State<AIIntegrationDashboard>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late AnimationController _typingController;
  late TextEditingController _chatController;
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final bool _aiOnline = true;
  final String _currentContext = 'No file selected';
  List<AICapability> _capabilities = [];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
    _chatController = TextEditingController();
    _initializeAI();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _typingController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _initializeAI() {
    _capabilities = [
      AICapability(
        name: 'Code Generation',
        description: 'Generate Flutter widgets and functions',
        icon: Icons.code,
        isActive: true,
      ),
      AICapability(
        name: 'Bug Detection',
        description: 'Find and suggest fixes for code issues',
        icon: Icons.bug_report,
        isActive: true,
      ),
      AICapability(
        name: 'Performance Analysis',
        description: 'Analyze and optimize app performance',
        icon: Icons.speed,
        isActive: true,
      ),
      AICapability(
        name: 'UI/UX Suggestions',
        description: 'Recommend design improvements',
        icon: Icons.design_services,
        isActive: true,
      ),
      AICapability(
        name: 'Documentation',
        description: 'Generate code documentation',
        icon: Icons.description,
        isActive: true,
      ),
      AICapability(
        name: 'Refactoring',
        description: 'Suggest code structure improvements',
        icon: Icons.transform,
        isActive: true,
      ),
    ];

    // Add welcome message
    _messages = [
      ChatMessage(
        content: 'Hello! I\'m your AI assistant. I can help you with Flutter development, code generation, debugging, and optimization.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.welcome,
      ),
      ChatMessage(
        content: 'Try asking me to:\n• Generate a custom widget\n• Fix performance issues\n• Explain code functionality\n• Suggest improvements',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.suggestion,
      ),
    ];
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final message = _chatController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.user,
      ));
      _isTyping = true;
    });

    _chatController.clear();
    
    // Simulate AI processing
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_generateAIResponse(message));
        });
      }
    });
  }

  ChatMessage _generateAIResponse(String userMessage) {
    final responses = _getContextualResponses(userMessage);
    final response = responses[math.Random().nextInt(responses.length)];
    
    return ChatMessage(
      content: response['content']!,
      isUser: false,
      timestamp: DateTime.now(),
      type: _getMessageType(response['type']!),
      codeExample: response['code'],
    );
  }

  List<Map<String, String>> _getContextualResponses(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('widget') || lowerMessage.contains('create')) {
      return [
        {
          'content': 'I\'ll help you create a custom Flutter widget. Here\'s a responsive card widget that follows Material Design principles:',
          'type': 'code',
          'code': '''class CustomCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}'''
        }
      ];
    }
    
    if (lowerMessage.contains('performance') || lowerMessage.contains('optimize')) {
      return [
        {
          'content': 'Here are key performance optimization tips for your Flutter app:\n\n• Use const constructors wherever possible\n• Implement ListView.builder for large lists\n• Avoid expensive operations in build methods\n• Use RepaintBoundary for complex widgets\n• Optimize image loading and caching',
          'type': 'advice',
        }
      ];
    }
    
    if (lowerMessage.contains('error') || lowerMessage.contains('bug')) {
      return [
        {
          'content': 'I\'ll help you debug that issue. Common Flutter errors and solutions:\n\n1. **RenderFlex overflow**: Use Expanded or Flexible widgets\n2. **setState called after dispose**: Check mounted before calling setState\n3. **Navigator.push null**: Ensure valid BuildContext\n4. **Asset not found**: Verify pubspec.yaml asset paths',
          'type': 'debug',
        }
      ];
    }

    if (lowerMessage.contains('animation') || lowerMessage.contains('animate')) {
      return [
        {
          'content': 'Here\'s a smooth animation example using AnimatedContainer:',
          'type': 'code',
          'code': '''class AnimatedButton extends StatefulWidget {
  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, _isPressed ? 2 : 4),
              blurRadius: _isPressed ? 4 : 8,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Animated Button', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}'''
        }
      ];
    }
    
    // Default responses
    return [
      {
        'content': 'I\'m here to help with your Flutter development! You can ask me about:\n\n• Creating widgets and UI components\n• Debugging and fixing errors\n• Performance optimization\n• Animation implementation\n• State management patterns\n• Best practices and conventions',
        'type': 'help',
      }
    ];
  }

  MessageType _getMessageType(String type) {
    switch (type) {
      case 'code': return MessageType.code;
      case 'debug': return MessageType.debug;
      case 'advice': return MessageType.advice;
      case 'help': return MessageType.help;
      default: return MessageType.response;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.isCollapsed) {
      return _buildCollapsedView(theme);
    }

    return Container(
      decoration: GlassMorphismHelper.glassContainer(
        color: theme.colorScheme.primary,
        opacity: 0.05,
        blur: 20,
        enableGlow: _aiOnline,
      ),
      child: Column(
        children: [
          _buildAIHeader(theme),
          Expanded(
            child: Column(
              children: [
                _buildCapabilitiesPanel(theme),
                Expanded(child: _buildChatInterface(theme)),
                _buildInputArea(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme) {
    return Container(
      width: 50,
      decoration: GlassMorphismHelper.glassContainer(
        color: _aiOnline ? Kre8tionsColors.accentPink : Colors.grey,
        opacity: 0.2,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_aiOnline ? Kre8tionsColors.accentPink : Colors.grey).withValues(
                        alpha: 0.3 + (math.sin(_glowController.value * math.pi * 2) * 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: _aiOnline ? Kre8tionsColors.accentPink : Colors.grey,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  'AI Assistant',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Kre8tionsColors.accentPink.withValues(alpha: 0.15),  // Flat neon pink - no gradient
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Kre8tionsColors.accentPink.withValues(
                    alpha: 0.3 + (math.sin(_glowController.value * math.pi * 2) * 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _aiOnline ? [
                    BoxShadow(
                      color: Kre8tionsColors.accentPink.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Kre8tionsColors.accentPink,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _aiOnline ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _aiOnline ? 'Online • Ready to help' : 'Offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _aiOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onToggleCollapsed,
            icon: const Icon(Icons.unfold_less, size: 16),
            tooltip: 'Collapse AI Assistant',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesPanel(ThemeData theme) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Capabilities',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _capabilities.length,
              itemBuilder: (context, index) {
                final capability = _capabilities[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: capability.isActive
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: capability.isActive
                        ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        capability.icon,
                        size: 16,
                        color: capability.isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        capability.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: capability.isActive
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Context: $_currentContext',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator(theme);
                }
                return _buildChatMessage(theme, _messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ThemeData theme, ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Kre8tionsColors.accentPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Kre8tionsColors.accentPink,
              ),
            ),
          if (message.isUser) const Spacer(),
          Flexible(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: message.type == MessageType.code
                    ? Border.all(color: Colors.blue.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (message.codeExample != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message.codeExample!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!message.isUser) const Spacer(),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Kre8tionsColors.accentPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: Kre8tionsColors.accentPink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    final animValue = math.sin((_typingController.value + delay) * math.pi * 2);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.3 + (animValue * 0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Ask AI about Flutter development...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: _isTyping ? null : _sendMessage,
              icon: Icon(
                _isTyping ? Icons.hourglass_empty : Icons.send,
                color: _isTyping 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? codeExample;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.codeExample,
  });
}

enum MessageType {
  user,
  welcome,
  suggestion,
  response,
  code,
  debug,
  advice,
  help,
}

class AICapability {
  final String name;
  final String description;
  final IconData icon;
  final bool isActive;

  AICapability({
    required this.name,
    required this.description,
    required this.icon,
    required this.isActive,
  });
}