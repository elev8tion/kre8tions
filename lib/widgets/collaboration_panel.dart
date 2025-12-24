import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kre8tions/services/collaboration_service.dart';
import 'package:kre8tions/services/real_time_communication_service.dart';

/// Widget that displays the collaboration panel showing active users and session info
class CollaborationPanel extends StatefulWidget {
  final double width;
  final VoidCallback? onToggle;

  const CollaborationPanel({
    super.key,
    this.width = 300,
    this.onToggle,
  });

  @override
  State<CollaborationPanel> createState() => _CollaborationPanelState();
}

class _CollaborationPanelState extends State<CollaborationPanel> with TickerProviderStateMixin {
  late final CollaborationService _collaborationService;
  late TabController _tabController;
  
  List<CollaborativeUser> _connectedUsers = [];
  CollaborationSession? _currentSession;
  List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  StreamSubscription? _usersSubscription;
  StreamSubscription? _chatSubscription;
  
  @override
  void initState() {
    super.initState();
    _collaborationService = CollaborationService();
    _tabController = TabController(length: 3, vsync: this);
    _loadCollaborationData();
    _setupStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _usersSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _loadCollaborationData() {
    setState(() {
      _currentSession = _collaborationService.currentSession;
      _connectedUsers = _collaborationService.connectedUsers;
      _chatMessages = _collaborationService.sessionChatMessages;
    });
  }

  void _setupStreams() {
    _usersSubscription = _collaborationService.realtimeUsersStream.listen((users) {
      if (mounted) {
        setState(() {
          _connectedUsers = users;
        });
      }
    });
    
    _chatSubscription = _collaborationService.realtimeChatStream.listen((message) {
      if (mounted) {
        setState(() {
          _chatMessages = _collaborationService.sessionChatMessages;
        });
        _scrollToBottom();
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
    
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(theme),
                _buildChatTab(theme),
                _buildSessionTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Collaboration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (widget.onToggle != null)
                IconButton(
                  onPressed: widget.onToggle,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text('Users (${_connectedUsers.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat, size: 16),
                    const SizedBox(width: 4),
                    Text('Chat (${_chatMessages.length})'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 16),
                    SizedBox(width: 4),
                    Text('Session'),
                  ],
                ),
              ),
            ],
            labelStyle: theme.textTheme.bodySmall,
            unselectedLabelStyle: theme.textTheme.bodySmall,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    if (_currentSession == null) {
      return _buildNoSessionView(theme);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _connectedUsers.length,
            itemBuilder: (context, index) {
              final user = _connectedUsers[index];
              return _buildUserItem(user, theme);
            },
          ),
        ),
        _buildCollaborationActions(theme),
      ],
    );
  }

  Widget _buildUserItem(CollaborativeUser user, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (user.status) {
      case UserStatus.online:
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        statusText = 'Online';
        break;
      case UserStatus.typing:
        statusColor = Colors.orange;
        statusIcon = Icons.edit;
        statusText = 'Typing...';
        break;
      case UserStatus.idle:
        statusColor = Colors.yellow;
        statusIcon = Icons.pause_circle;
        statusText = 'Idle';
        break;
      case UserStatus.away:
        statusColor = Colors.grey;
        statusIcon = Icons.access_time;
        statusText = 'Away';
        break;
      case UserStatus.offline:
        statusColor = Colors.red;
        statusIcon = Icons.offline_bolt;
        statusText = 'Offline';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000)
              .withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user.avatarUrl),
                backgroundColor: Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000),
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    statusIcon,
                    size: 6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(ThemeData theme) {
    if (_currentSession == null) {
      return _buildNoSessionView(theme);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              return _buildChatMessage(message, theme);
            },
          ),
        ),
        _buildChatInput(theme),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message, ThemeData theme) {
    final user = _connectedUsers.firstWhere(
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

    final isCurrentUser = message.senderId == _collaborationService.currentSession?.ownerId;
    final userColor = user.color.isNotEmpty
        ? Color(int.parse(user.color.substring(1), radix: 16) + 0xFF000000)
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            backgroundColor: userColor.withValues(alpha: 0.3),
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: userColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: userColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              minLines: 1,
              onSubmitted: _sendChatMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendChatMessage(_chatController.text),
            icon: const Icon(Icons.send),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTab(ThemeData theme) {
    if (_currentSession == null) {
      return _buildNoSessionView(theme);
    }

    final stats = _collaborationService.getRealtimeCollaborationStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfo(theme),
          const SizedBox(height: 24),
          _buildSessionStats(theme, stats),
          const SizedBox(height: 24),
          _buildSessionActions(theme),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(ThemeData theme) {
    final session = _currentSession!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group_work,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session Info',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', session.name, theme),
            _buildInfoRow('Description', session.description, theme),
            _buildInfoRow('Created', _formatTime(session.createdAt), theme),
            _buildInfoRow('Max Users', session.maxUsers.toString(), theme),
            _buildInfoRow('Permission', session.defaultPermission.name.toUpperCase(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats(ThemeData theme, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Connected Users', stats['realtimeStats']['connectedUsers'].toString(), theme),
            _buildStatRow('Active Users', stats['realtimeStats']['activeUsers'].toString(), theme),
            _buildStatRow('Total Messages', stats['realtimeStats']['totalMessages'].toString(), theme),
            _buildStatRow('Operations', stats['realtimeStats']['totalOperations'].toString(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionActions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareSessionLink,
                icon: const Icon(Icons.link),
                label: const Text('Share Session Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _leaveSession,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Leave Session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startCollaborativeDebugging,
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Start Debugging'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareScreen,
                  icon: const Icon(Icons.screen_share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _createSharedTerminal,
                  icon: const Icon(Icons.terminal, size: 16),
                  label: const Text('Terminal'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Session',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a collaboration session to start working with others',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateSessionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Session'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendChatMessage(String message) {
    if (message.trim().isEmpty) return;
    
    _collaborationService.sendCollaborationMessage(message.trim());
    _chatController.clear();
    
    // Update typing status
    _collaborationService.updateCollaborationStatus(UserStatus.online);
  }

  void _shareSessionLink() {
    if (_currentSession == null) return;
    
    // In a real app, this would generate and share a proper session link
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session link: codewhisper://join/${_currentSession!.id}'),
        action: SnackBarAction(
          label: 'COPY',
          onPressed: () {
            // Copy to clipboard
          },
        ),
      ),
    );
  }

  void _leaveSession() async {
    await _collaborationService.leaveCollaborationSession();
    if (mounted) {
      setState(() {
        _currentSession = null;
        _connectedUsers.clear();
        _chatMessages.clear();
      });
    }
  }

  void _showCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateSessionDialog(
        onSessionCreated: (session) {
          _collaborationService.joinCollaborationSession(session.id);
          _loadCollaborationData();
        },
      ),
    );
  }

  void _startCollaborativeDebugging() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Collaborative debugging session started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen sharing not implemented yet')),
    );
  }

  void _createSharedTerminal() async {
    try {
      await _collaborationService.createSharedTerminal(
        name: 'Shared Terminal ${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shared terminal created'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create terminal: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Dialog for creating a new collaboration session
class CreateSessionDialog extends StatefulWidget {
  final Function(CollaborationSession) onSessionCreated;

  const CreateSessionDialog({
    super.key,
    required this.onSessionCreated,
  });

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SharePermission _defaultPermission = SharePermission.edit;
  int _maxUsers = 10;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Create Collaboration Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'Enter a name for this session',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what you\'ll be working on',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SharePermission>(
              initialValue: _defaultPermission,
              decoration: const InputDecoration(
                labelText: 'Default Permission',
              ),
              items: SharePermission.values.map((permission) {
                return DropdownMenuItem(
                  value: permission,
                  child: Text(permission.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _defaultPermission = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Max Users:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _maxUsers.toDouble(),
                    min: 2,
                    max: 50,
                    divisions: 24,
                    label: _maxUsers.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxUsers = value.round();
                      });
                    },
                  ),
                ),
                Text(_maxUsers.toString()),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createSession,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  void _createSession() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a session name')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final session = await CollaborationService().createCollaborationSession(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        projectId: 'current-project', // In a real app, this would be actual project ID
        defaultPermission: _defaultPermission,
        maxUsers: _maxUsers,
      );

      widget.onSessionCreated(session);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}