import 'package:flutter/material.dart';
import 'package:kre8tions/services/real_time_communication_service.dart';
import 'package:kre8tions/services/collaboration_service.dart';
import 'dart:async';

/// Floating chat widget for real-time collaboration communication
class CollaborationChatWidget extends StatefulWidget {
  final VoidCallback? onToggle;
  final bool isMinimized;

  const CollaborationChatWidget({
    super.key,
    this.onToggle,
    this.isMinimized = false,
  });

  @override
  State<CollaborationChatWidget> createState() => _CollaborationChatWidgetState();
}

class _CollaborationChatWidgetState extends State<CollaborationChatWidget> with TickerProviderStateMixin {
  late final CollaborationService _collaborationService;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  List<CollaborativeUser> _typingUsers = [];
  StreamSubscription? _chatSubscription;
  StreamSubscription? _usersSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _collaborationService = CollaborationService();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    if (!widget.isMinimized) {
      _slideController.forward();
    }
    
    _loadMessages();
    _setupStreams();
    
    // Listen to message input changes for typing indicators
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _messageFocusNode.dispose();
    _chatSubscription?.cancel();
    _usersSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CollaborationChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMinimized != oldWidget.isMinimized) {
      if (widget.isMinimized) {
        _slideController.reverse();
      } else {
        _slideController.forward();
      }
    }
  }

  void _loadMessages() {
    setState(() {
      _messages = _collaborationService.sessionChatMessages;
    });
  }

  void _setupStreams() {
    _chatSubscription = _collaborationService.realtimeChatStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages = _collaborationService.sessionChatMessages;
        });
        _scrollToBottom();
      }
    });
    
    _usersSubscription = _collaborationService.realtimeUsersStream.listen((users) {
      if (mounted) {
        setState(() {
          _typingUsers = _collaborationService.typingUsers;
        });
      }
    });
  }

  void _onMessageChanged() {
    if (_messageController.text.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      _collaborationService.updateCollaborationStatus(UserStatus.typing);
    } else if (_messageController.text.trim().isEmpty && _isTyping) {
      _isTyping = false;
      _collaborationService.updateCollaborationStatus(UserStatus.online);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _collaborationService.updateCollaborationStatus(UserStatus.online);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    return Positioned(
      right: 16,
      bottom: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: screenSize.width > 1200 ? 320 : 280,
          height: screenSize.height > 800 ? 400 : 320,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(child: _buildChatContent(theme)),
              if (_typingUsers.isNotEmpty) _buildTypingIndicator(theme),
              _buildMessageInput(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final connectedUsers = _collaborationService.connectedUsers;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Chat',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${connectedUsers.length} member${connectedUsers.length == 1 ? '' : 's'} online',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...connectedUsers.take(3).map((user) {
                final userColor = Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000);
                return Container(
                  margin: const EdgeInsets.only(left: 2),
                  child: CircleAvatar(
                    radius: 8,
                    backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                    backgroundColor: userColor.withValues(alpha: 0.3),
                    child: user.avatarUrl.isEmpty 
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: userColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                );
              }),
              if (connectedUsers.length > 3)
                Container(
                  margin: const EdgeInsets.only(left: 2),
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                    child: Text(
                      '+${connectedUsers.length - 3}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onToggle,
            icon: Icon(
              widget.isMinimized ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: widget.isMinimized ? 'Expand chat' : 'Minimize chat',
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(ThemeData theme) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a conversation with your team',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, theme);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final connectedUsers = _collaborationService.connectedUsers;
    final user = connectedUsers.firstWhere(
      (u) => u.id == message.senderId,
      orElse: () => CollaborativeUser(
        id: message.senderId,
        name: message.senderName,
        email: '',
        avatarUrl: '',
        status: UserStatus.offline,
        color: '#666666',
        lastActivity: DateTime.now(),
      ),
    );

    final currentUser = _collaborationService.currentSession?.ownerId;
    final isCurrentUser = message.senderId == currentUser;
    final userColor = user.color.isNotEmpty
        ? Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000)
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              backgroundColor: userColor.withValues(alpha: 0.3),
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: userColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Text(
                    message.senderName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: userColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isCurrentUser 
                          ? const Radius.circular(12) 
                          : const Radius.circular(4),
                      bottomRight: isCurrentUser 
                          ? const Radius.circular(4) 
                          : const Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCurrentUser 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (message.mentions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: message.mentions.map((mentionId) {
                            final mentionedUser = connectedUsers.firstWhere(
                              (u) => u.id == mentionId,
                              orElse: () => CollaborativeUser(
                                id: mentionId,
                                name: 'Unknown User',
                                email: '',
                                avatarUrl: '',
                                status: UserStatus.offline,
                                color: '#666666',
                                lastActivity: DateTime.now(),
                              ),
                            );
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '@${mentionedUser.name}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrentUser 
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              backgroundColor: userColor.withValues(alpha: 0.3),
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: userColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          _buildTypingAnimation(theme),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _typingUsers.length == 1
                  ? '${_typingUsers.first.name} is typing...'
                  : '${_typingUsers.map((u) => u.name).join(', ')} are typing...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (value + delay) % 1.0;
            final opacity = animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2;
            
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _showEmojiPicker,
                        icon: const Icon(Icons.emoji_emotions_outlined, size: 20),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Add emoji',
                      ),
                      IconButton(
                        onPressed: _attachFile,
                        icon: const Icon(Icons.attach_file, size: 20),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Attach file',
                      ),
                    ],
                  ),
                ),
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: Icon(
                Icons.send,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    _collaborationService.sendCollaborationMessage(message.trim());
    _messageController.clear();
    
    // Update typing status
    _isTyping = false;
    _collaborationService.updateCollaborationStatus(UserStatus.online);
    _typingTimer?.cancel();
    
    _messageFocusNode.requestFocus();
  }

  void _showEmojiPicker() {
    // Placeholder for emoji picker implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emoji picker not implemented yet')),
    );
  }

  void _attachFile() {
    // Placeholder for file attachment implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File attachment not implemented yet')),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Quick chat overlay for minimal space usage
class QuickChatOverlay extends StatefulWidget {
  final VoidCallback? onExpand;

  const QuickChatOverlay({super.key, this.onExpand});

  @override
  State<QuickChatOverlay> createState() => _QuickChatOverlayState();
}

class _QuickChatOverlayState extends State<QuickChatOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  int _unreadMessages = 0;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _setupChatSubscription();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _setupChatSubscription() {
    final collaborationService = CollaborationService();
    _chatSubscription = collaborationService.realtimeChatStream.listen((message) {
      if (mounted) {
        setState(() {
          _unreadMessages++;
        });
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _unreadMessages = 0;
                        });
                        widget.onExpand?.call();
                      },
                      icon: Icon(
                        Icons.chat,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (_unreadMessages > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            _unreadMessages > 99 ? '99+' : _unreadMessages.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}