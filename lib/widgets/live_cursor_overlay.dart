import 'package:flutter/material.dart';
import 'package:kre8tions/services/real_time_communication_service.dart';
import 'dart:async';

/// Widget that displays live cursors and selections from other collaborative users
class LiveCursorOverlay extends StatefulWidget {
  final String fileName;
  final TextEditingController textController;
  final ScrollController scrollController;
  final Map<String, CursorPosition> cursorPositions;
  final Map<String, CollaborativeUser> users;
  final double lineHeight;
  final EdgeInsets padding;

  const LiveCursorOverlay({
    super.key,
    required this.fileName,
    required this.textController,
    required this.scrollController,
    required this.cursorPositions,
    required this.users,
    this.lineHeight = 19.6,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<LiveCursorOverlay> createState() => _LiveCursorOverlayState();
}

class _LiveCursorOverlayState extends State<LiveCursorOverlay> with TickerProviderStateMixin {
  final Map<String, AnimationController> _cursorAnimations = {};
  Timer? _cursorBlinkTimer;

  @override
  void initState() {
    super.initState();
    _setupCursorAnimations();
  }

  @override
  void dispose() {
    _cursorBlinkTimer?.cancel();
    for (final controller in _cursorAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveCursorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupCursorAnimations();
  }

  void _setupCursorAnimations() {
    // Clean up old animations
    final currentUserIds = widget.cursorPositions.keys.toSet();
    final oldUserIds = _cursorAnimations.keys.toSet();
    
    // Remove animations for users no longer present
    for (final userId in oldUserIds.difference(currentUserIds)) {
      _cursorAnimations[userId]?.dispose();
      _cursorAnimations.remove(userId);
    }
    
    // Add animations for new users
    for (final userId in currentUserIds.difference(oldUserIds)) {
      _cursorAnimations[userId] = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      )..repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Render selections first (behind cursors)
        ..._buildSelectionOverlays(),
        // Then render cursors on top
        ..._buildCursorOverlays(),
      ],
    );
  }

  List<Widget> _buildSelectionOverlays() {
    final overlays = <Widget>[];
    
    for (final entry in widget.cursorPositions.entries) {
      final userId = entry.key;
      final cursor = entry.value;
      
      // Only show cursors for the current file
      if (cursor.fileName != widget.fileName) continue;
      
      final user = widget.users[userId];
      if (user == null) continue;
      
      // Check if there's a selection
      if (cursor.selectionStart != null && cursor.selectionEnd != null) {
        final selectionOverlay = _buildSelectionOverlay(cursor, user);
        if (selectionOverlay != null) {
          overlays.add(selectionOverlay);
        }
      }
    }
    
    return overlays;
  }

  List<Widget> _buildCursorOverlays() {
    final overlays = <Widget>[];
    
    for (final entry in widget.cursorPositions.entries) {
      final userId = entry.key;
      final cursor = entry.value;
      
      // Only show cursors for the current file
      if (cursor.fileName != widget.fileName) continue;
      
      final user = widget.users[userId];
      if (user == null) continue;
      
      final cursorOverlay = _buildCursorOverlay(cursor, user);
      if (cursorOverlay != null) {
        overlays.add(cursorOverlay);
      }
    }
    
    return overlays;
  }

  Widget? _buildSelectionOverlay(CursorPosition cursor, CollaborativeUser user) {
    if (cursor.selectionStart == null || cursor.selectionEnd == null) return null;
    
    final text = widget.textController.text;
    final start = cursor.selectionStart!;
    final end = cursor.selectionEnd!;
    
    if (start >= text.length || end >= text.length || start == end) return null;
    
    final userColor = Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000);
    
    // Calculate position and size of selection
    final selectionRects = _calculateSelectionRects(start, end);
    
    return Stack(
      children: selectionRects.map((rect) => Positioned(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: Container(
          decoration: BoxDecoration(
            color: userColor.withValues(alpha: 0.2),
            border: Border.all(
              color: userColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )).toList(),
    );
  }

  Widget? _buildCursorOverlay(CursorPosition cursor, CollaborativeUser user) {
    final text = widget.textController.text;
    if (cursor.offset >= text.length) return null;
    
    final position = _calculateCursorPosition(cursor.offset);
    if (position == null) return null;
    
    final userColor = Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000);
    final animation = _cursorAnimations[user.id];
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: userColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Cursor line
          if (animation != null)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: 2,
                  height: widget.lineHeight,
                  decoration: BoxDecoration(
                    color: userColor.withValues(alpha: animation.value * 0.5 + 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Rect> _calculateSelectionRects(int start, int end) {
    final rects = <Rect>[];
    final text = widget.textController.text;
    final lines = text.split('\n');
    
    int currentOffset = 0;
    int lineNumber = 0;
    
    for (final line in lines) {
      final lineStart = currentOffset;
      final lineEnd = currentOffset + line.length;
      
      // Check if selection intersects with this line
      if (start < lineEnd && end > lineStart) {
        final selectionStart = start > lineStart ? start - lineStart : 0;
        final selectionEnd = end < lineEnd ? end - lineStart : line.length;
        
        if (selectionStart < selectionEnd) {
          // Calculate approximate character width (monospace assumption)
          const charWidth = 8.0; // Approximate character width
          final startX = widget.padding.left + 48 + (selectionStart * charWidth); // 48 for line numbers
          final endX = widget.padding.left + 48 + (selectionEnd * charWidth);
          final y = widget.padding.top + (lineNumber * widget.lineHeight);
          
          rects.add(Rect.fromLTWH(
            startX,
            y,
            endX - startX,
            widget.lineHeight,
          ));
        }
      }
      
      currentOffset = lineEnd + 1; // +1 for newline character
      lineNumber++;
    }
    
    return rects;
  }

  Offset? _calculateCursorPosition(int offset) {
    final text = widget.textController.text;
    if (offset >= text.length) return null;
    
    final lines = text.substring(0, offset).split('\n');
    final lineNumber = lines.length - 1;
    final columnNumber = lines.last.length;
    
    // Calculate approximate position
    const charWidth = 8.0; // Approximate character width for monospace
    final x = widget.padding.left + 48 + (columnNumber * charWidth); // 48 for line numbers
    final y = widget.padding.top + (lineNumber * widget.lineHeight);
    
    return Offset(x, y);
  }
}

/// Widget that shows typing indicators for users currently typing
class TypingIndicator extends StatefulWidget {
  final List<CollaborativeUser> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.typingUsers.isNotEmpty) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typingUsers.isNotEmpty && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (widget.typingUsers.isEmpty && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Typing animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final animValue = (_animation.value + delay) % 1.0;
                  final opacity = animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 2),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: opacity),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          // User avatars and names
          Expanded(
            child: Wrap(
              spacing: 4,
              children: widget.typingUsers.map((user) {
                final userColor = Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: userColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: userColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundImage: user.avatarUrl.isNotEmpty 
                            ? NetworkImage(user.avatarUrl) 
                            : null,
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
                      const SizedBox(width: 4),
                      Text(
                        user.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: userColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Text(
            widget.typingUsers.length == 1 
                ? 'is typing...' 
                : 'are typing...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows user presence in the file tree or project explorer
class UserPresenceIndicator extends StatelessWidget {
  final String fileName;
  final Map<String, CursorPosition> cursorPositions;
  final Map<String, CollaborativeUser> users;
  final double size;

  const UserPresenceIndicator({
    super.key,
    required this.fileName,
    required this.cursorPositions,
    required this.users,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final usersInFile = _getUsersInFile();
    
    if (usersInFile.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size * 2,
      height: size,
      child: Stack(
        children: usersInFile.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          final userColor = Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000);
          
          return Positioned(
            right: index * (size * 0.6),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: userColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: user.avatarUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: size / 2 - 1,
                      backgroundImage: NetworkImage(user.avatarUrl),
                    )
                  : Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<CollaborativeUser> _getUsersInFile() {
    final usersInFile = <CollaborativeUser>[];
    
    for (final entry in cursorPositions.entries) {
      if (entry.value.fileName == fileName) {
        final user = users[entry.key];
        if (user != null && user.status != UserStatus.offline) {
          usersInFile.add(user);
        }
      }
    }
    
    return usersInFile;
  }
}

/// Widget that displays a collaborative activity feed
class ActivityFeed extends StatefulWidget {
  final List<RealTimeMessage> messages;
  final double height;

  const ActivityFeed({
    super.key,
    required this.messages,
    this.height = 200,
  });

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActivityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity Feed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return _buildActivityItem(message, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RealTimeMessage message, ThemeData theme) {
    IconData icon;
    Color iconColor;
    String activityText;
    
    switch (message.type) {
      case MessageType.userJoined:
        icon = Icons.person_add;
        iconColor = Colors.green;
        activityText = '${message.payload['name']} joined the session';
        break;
      case MessageType.userLeft:
        icon = Icons.person_remove;
        iconColor = Colors.red;
        activityText = '${message.payload['name'] ?? 'User'} left the session';
        break;
      case MessageType.codeEdit:
        icon = Icons.edit;
        iconColor = Colors.blue;
        activityText = 'Code edited in ${message.payload['fileName']}';
        break;
      case MessageType.fileOpen:
        icon = Icons.folder_open;
        iconColor = Colors.orange;
        activityText = 'Opened ${message.payload['fileName']}';
        break;
      case MessageType.textMessage:
        icon = Icons.chat;
        iconColor = Colors.purple;
        activityText = 'New message in chat';
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        activityText = 'Activity: ${message.type.name}';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}