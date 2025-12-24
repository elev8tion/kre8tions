import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Enum representing different user statuses
enum UserStatus { online, typing, idle, away, offline }

/// Enum representing different message types for real-time communication
enum MessageType {
  // Connection events
  userJoined,
  userLeft,
  heartbeat,
  
  // Collaboration events
  codeEdit,
  cursorMove,
  selectionChange,
  fileOpen,
  fileClose,
  
  // Chat events
  textMessage,
  voiceMessage,
  
  // Session events
  sessionUpdate,
  permissionChange,
  
  // Operational Transform events
  operation,
  operationAck,
  operationReject,
  
  // System events
  error,
  warning,
  info
}

/// Represents a collaborative user in the session
class CollaborativeUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserStatus status;
  final String color; // Unique color for this user's cursor and edits
  final DateTime lastActivity;
  final Map<String, dynamic> metadata;

  const CollaborativeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.status,
    required this.color,
    required this.lastActivity,
    this.metadata = const {},
  });

  CollaborativeUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserStatus? status,
    String? color,
    DateTime? lastActivity,
    Map<String, dynamic>? metadata,
  }) {
    return CollaborativeUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      color: color ?? this.color,
      lastActivity: lastActivity ?? this.lastActivity,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'status': status.name,
      'color': color,
      'lastActivity': lastActivity.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CollaborativeUser.fromJson(Map<String, dynamic> json) {
    return CollaborativeUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      status: UserStatus.values.byName(json['status']),
      color: json['color'],
      lastActivity: DateTime.parse(json['lastActivity']),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Represents a cursor position in a collaborative session
class CursorPosition {
  final String userId;
  final String fileName;
  final int offset;
  final int? selectionStart;
  final int? selectionEnd;
  final DateTime timestamp;

  const CursorPosition({
    required this.userId,
    required this.fileName,
    required this.offset,
    this.selectionStart,
    this.selectionEnd,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fileName': fileName,
      'offset': offset,
      'selectionStart': selectionStart,
      'selectionEnd': selectionEnd,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CursorPosition.fromJson(Map<String, dynamic> json) {
    return CursorPosition(
      userId: json['userId'],
      fileName: json['fileName'],
      offset: json['offset'],
      selectionStart: json['selectionStart'],
      selectionEnd: json['selectionEnd'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Represents a real-time message in the collaboration system
class RealTimeMessage {
  final String id;
  final MessageType type;
  final String senderId;
  final String? targetId; // For direct messages
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const RealTimeMessage({
    required this.id,
    required this.type,
    required this.senderId,
    this.targetId,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'senderId': senderId,
      'targetId': targetId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RealTimeMessage.fromJson(Map<String, dynamic> json) {
    return RealTimeMessage(
      id: json['id'],
      type: MessageType.values.byName(json['type']),
      senderId: json['senderId'],
      targetId: json['targetId'],
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Represents an Operational Transform operation
class Operation {
  final String id;
  final String userId;
  final String fileName;
  final String type; // insert, delete, retain
  final int position;
  final String? text;
  final int? length;
  final DateTime timestamp;
  final int version; // Document version when operation was created

  const Operation({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.type,
    required this.position,
    this.text,
    this.length,
    required this.timestamp,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'type': type,
      'position': position,
      'text': text,
      'length': length,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'],
      userId: json['userId'],
      fileName: json['fileName'],
      type: json['type'],
      position: json['position'],
      text: json['text'],
      length: json['length'],
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
    );
  }
}

/// Chat message for text/voice communication
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final bool isVoice;
  final DateTime timestamp;
  final List<String> mentions; // User IDs mentioned in the message

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.isVoice = false,
    required this.timestamp,
    this.mentions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'isVoice': isVoice,
      'timestamp': timestamp.toIso8601String(),
      'mentions': mentions,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      isVoice: json['isVoice'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      mentions: List<String>.from(json['mentions'] ?? []),
    );
  }
}

/// Main service for real-time communication and collaboration
class RealTimeCommunicationService {
  static final RealTimeCommunicationService _instance = RealTimeCommunicationService._internal();
  factory RealTimeCommunicationService() => _instance;
  RealTimeCommunicationService._internal();

  final Uuid _uuid = const Uuid();
  
  // WebSocket connection
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _sessionId;
  late CollaborativeUser _currentUser;
  
  // Collaboration state
  final Map<String, CollaborativeUser> _connectedUsers = {};
  final Map<String, CursorPosition> _cursorPositions = {};
  final Map<String, int> _documentVersions = {}; // fileName -> version
  final List<Operation> _operationBuffer = []; // Buffered operations for conflict resolution
  final List<ChatMessage> _chatMessages = [];
  
  // Stream controllers for real-time updates
  final StreamController<List<CollaborativeUser>> _usersController = 
      StreamController<List<CollaborativeUser>>.broadcast();
  final StreamController<Map<String, CursorPosition>> _cursorsController = 
      StreamController<Map<String, CursorPosition>>.broadcast();
  final StreamController<Operation> _operationController = 
      StreamController<Operation>.broadcast();
  final StreamController<ChatMessage> _chatController = 
      StreamController<ChatMessage>.broadcast();
  final StreamController<RealTimeMessage> _messageController = 
      StreamController<RealTimeMessage>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
      
  // Connection management
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Getters for streams
  Stream<List<CollaborativeUser>> get usersStream => _usersController.stream;
  Stream<Map<String, CursorPosition>> get cursorsStream => _cursorsController.stream;
  Stream<Operation> get operationStream => _operationController.stream;
  Stream<ChatMessage> get chatStream => _chatController.stream;
  Stream<RealTimeMessage> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  // Getters for current state
  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  CollaborativeUser? get currentUser => _isConnected ? _currentUser : null;
  List<CollaborativeUser> get connectedUsers => _connectedUsers.values.toList();
  Map<String, CursorPosition> get cursorPositions => Map.from(_cursorPositions);
  List<ChatMessage> get chatMessages => List.from(_chatMessages);

  /// Initialize the service with user information
  Future<bool> initialize({
    required String userId,
    required String userName,
    required String userEmail,
    String? avatarUrl,
  }) async {
    try {
      // Generate a unique color for this user
      final colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
        '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
      ];
      final userColor = colors[userId.hashCode % colors.length];

      _currentUser = CollaborativeUser(
        id: userId,
        name: userName,
        email: userEmail,
        avatarUrl: avatarUrl ?? 'https://api.dicebear.com/6.x/avataaars/svg?seed=$userName',
        status: UserStatus.online,
        color: userColor,
        lastActivity: DateTime.now(),
      );

      _status('Real-time communication service initialized for $userName');
      return true;
    } catch (e) {
      _status('Failed to initialize real-time service: $e');
      return false;
    }
  }

  /// Connect to a collaboration session
  Future<bool> connectToSession(String sessionId, {String? serverUrl}) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      _sessionId = sessionId;
      
      // In a real implementation, this would connect to an actual WebSocket server
      // For now, we'll simulate the connection
      _simulateWebSocketConnection(sessionId, serverUrl);
      
      _status('Connecting to collaboration session: $sessionId');
      
      // Start heartbeat
      _startHeartbeat();
      
      return true;
    } catch (e) {
      _status('Failed to connect to session: $e');
      return false;
    }
  }

  /// Simulate WebSocket connection for demo purposes
  void _simulateWebSocketConnection(String sessionId, String? serverUrl) {
    _isConnected = true;
    _reconnectAttempts = 0;
    
    // Simulate connection delay
    Timer(const Duration(milliseconds: 500), () {
      _status('Connected to collaboration session');
      _sendMessage(RealTimeMessage(
        id: _uuid.v4(),
        type: MessageType.userJoined,
        senderId: _currentUser.id,
        payload: _currentUser.toJson(),
        timestamp: DateTime.now(),
      ));
      
      // Simulate other users already in the session
      _simulateExistingUsers();
    });
    
    // Simulate periodic messages from other users
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      _simulateRandomActivity();
    });
  }

  /// Simulate existing users in the session
  void _simulateExistingUsers() {
    final existingUsers = [
      CollaborativeUser(
        id: 'user_2',
        name: 'Alice Developer',
        email: 'alice@example.com',
        avatarUrl: 'https://api.dicebear.com/6.x/avataaars/svg?seed=Alice',
        status: UserStatus.online,
        color: '#4ECDC4',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      CollaborativeUser(
        id: 'user_3',
        name: 'Bob Coder',
        email: 'bob@example.com',
        avatarUrl: 'https://api.dicebear.com/6.x/avataaars/svg?seed=Bob',
        status: UserStatus.typing,
        color: '#FF6B6B',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    for (final user in existingUsers) {
      _connectedUsers[user.id] = user;
    }
    _usersController.add(connectedUsers);
  }

  /// Simulate random collaborative activity
  void _simulateRandomActivity() {
    final random = Random();
    final activities = ['typing', 'cursor_move', 'chat', 'file_switch'];
    final activity = activities[random.nextInt(activities.length)];
    
    final users = _connectedUsers.values.where((u) => u.id != _currentUser.id).toList();
    if (users.isEmpty) return;
    
    final user = users[random.nextInt(users.length)];
    
    switch (activity) {
      case 'typing':
        _simulateTyping(user);
        break;
      case 'cursor_move':
        _simulateCursorMove(user);
        break;
      case 'chat':
        _simulateChat(user);
        break;
      case 'file_switch':
        _simulateFileSwitch(user);
        break;
    }
  }

  void _simulateTyping(CollaborativeUser user) {
    // Update user status to typing
    _connectedUsers[user.id] = user.copyWith(
      status: UserStatus.typing,
      lastActivity: DateTime.now(),
    );
    _usersController.add(connectedUsers);

    // Reset to online after typing
    Timer(const Duration(seconds: 3), () {
      if (_connectedUsers.containsKey(user.id)) {
        _connectedUsers[user.id] = user.copyWith(
          status: UserStatus.online,
          lastActivity: DateTime.now(),
        );
        _usersController.add(connectedUsers);
      }
    });
  }

  void _simulateCursorMove(CollaborativeUser user) {
    final files = ['main.dart', 'home_page.dart', 'models/user.dart'];
    final file = files[Random().nextInt(files.length)];
    final offset = Random().nextInt(1000);
    
    final cursor = CursorPosition(
      userId: user.id,
      fileName: file,
      offset: offset,
      timestamp: DateTime.now(),
    );
    
    _cursorPositions[user.id] = cursor;
    _cursorsController.add(cursorPositions);
  }

  void _simulateChat(CollaborativeUser user) {
    final messages = [
      'Looking good! 👍',
      'Should we refactor this function?',
      'I found a bug in the login logic',
      'Great work on the UI improvements!',
      'Can you review this change?',
    ];
    
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: user.id,
      senderName: user.name,
      content: messages[Random().nextInt(messages.length)],
      timestamp: DateTime.now(),
    );
    
    _chatMessages.add(message);
    _chatController.add(message);
  }

  void _simulateFileSwitch(CollaborativeUser user) {
    _sendMessage(RealTimeMessage(
      id: _uuid.v4(),
      type: MessageType.fileOpen,
      senderId: user.id,
      payload: {
        'fileName': 'lib/widgets/code_editor.dart',
        'action': 'opened',
      },
      timestamp: DateTime.now(),
    ));
  }

  /// Disconnect from the current session
  Future<void> disconnect() async {
    if (_isConnected) {
      _sendMessage(RealTimeMessage(
        id: _uuid.v4(),
        type: MessageType.userLeft,
        senderId: _currentUser.id,
        payload: {'reason': 'user_disconnected'},
        timestamp: DateTime.now(),
      ));
    }

    _channel?.sink.close(status.normalClosure);
    _isConnected = false;
    _sessionId = null;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    _connectedUsers.clear();
    _cursorPositions.clear();
    _operationBuffer.clear();
    
    _usersController.add([]);
    _cursorsController.add({});
    
    _status('Disconnected from collaboration session');
  }

  /// Send a real-time message
  void _sendMessage(RealTimeMessage message) {
    if (!_isConnected) return;
    
    // In a real implementation, this would send through WebSocket
    // For simulation, we'll process it locally
    _messageController.add(message);
    
    // Simulate server processing
    Timer(const Duration(milliseconds: 50), () {
      _handleMessage(message);
    });
  }

  /// Handle incoming messages
  void _handleMessage(RealTimeMessage message) {
    switch (message.type) {
      case MessageType.userJoined:
        final user = CollaborativeUser.fromJson(message.payload);
        _connectedUsers[user.id] = user;
        _usersController.add(connectedUsers);
        _status('${user.name} joined the session');
        break;
        
      case MessageType.userLeft:
        final userId = message.senderId;
        final user = _connectedUsers.remove(userId);
        _cursorPositions.remove(userId);
        _usersController.add(connectedUsers);
        _cursorsController.add(cursorPositions);
        if (user != null) {
          _status('${user.name} left the session');
        }
        break;
        
      case MessageType.codeEdit:
        final operation = Operation.fromJson(message.payload);
        _handleOperation(operation);
        break;
        
      case MessageType.cursorMove:
        final cursor = CursorPosition.fromJson(message.payload);
        _cursorPositions[cursor.userId] = cursor;
        _cursorsController.add(cursorPositions);
        break;
        
      case MessageType.textMessage:
        final chatMessage = ChatMessage.fromJson(message.payload);
        _chatMessages.add(chatMessage);
        _chatController.add(chatMessage);
        break;
        
      default:
        // Handle other message types
        break;
    }
  }

  /// Send a code edit operation
  Future<void> sendCodeEdit({
    required String fileName,
    required String operationType, // insert, delete, retain
    required int position,
    String? text,
    int? length,
  }) async {
    if (!_isConnected) return;

    final version = _documentVersions[fileName] ?? 0;
    
    final operation = Operation(
      id: _uuid.v4(),
      userId: _currentUser.id,
      fileName: fileName,
      type: operationType,
      position: position,
      text: text,
      length: length,
      timestamp: DateTime.now(),
      version: version,
    );

    _sendMessage(RealTimeMessage(
      id: _uuid.v4(),
      type: MessageType.codeEdit,
      senderId: _currentUser.id,
      payload: operation.toJson(),
      timestamp: DateTime.now(),
    ));

    // Increment document version
    _documentVersions[fileName] = version + 1;
  }

  /// Send cursor position update
  void sendCursorUpdate({
    required String fileName,
    required int offset,
    int? selectionStart,
    int? selectionEnd,
  }) {
    if (!_isConnected) return;

    final cursor = CursorPosition(
      userId: _currentUser.id,
      fileName: fileName,
      offset: offset,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      timestamp: DateTime.now(),
    );

    _sendMessage(RealTimeMessage(
      id: _uuid.v4(),
      type: MessageType.cursorMove,
      senderId: _currentUser.id,
      payload: cursor.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Send a chat message
  void sendChatMessage(String content, {List<String> mentions = const []}) {
    if (!_isConnected) return;

    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUser.id,
      senderName: _currentUser.name,
      content: content,
      timestamp: DateTime.now(),
      mentions: mentions,
    );

    _sendMessage(RealTimeMessage(
      id: _uuid.v4(),
      type: MessageType.textMessage,
      senderId: _currentUser.id,
      payload: message.toJson(),
      timestamp: DateTime.now(),
    ));
  }

  /// Update user status
  void updateUserStatus(UserStatus status) {
    if (!_isConnected) return;

    _currentUser = _currentUser.copyWith(
      status: status,
      lastActivity: DateTime.now(),
    );

    _sendMessage(RealTimeMessage(
      id: _uuid.v4(),
      type: MessageType.sessionUpdate,
      senderId: _currentUser.id,
      payload: {
        'type': 'status_update',
        'status': status.name,
      },
      timestamp: DateTime.now(),
    ));
  }

  /// Handle operational transform for conflict resolution
  void _handleOperation(Operation operation) {
    // Add to operation buffer
    _operationBuffer.add(operation);
    
    // Apply operation immediately (in a real implementation, this would be more sophisticated)
    _operationController.add(operation);
    
    // Clean up old operations (keep last 100)
    if (_operationBuffer.length > 100) {
      _operationBuffer.removeAt(0);
    }
  }

  /// Apply operational transform to resolve conflicts
  Operation? transformOperation(Operation op1, Operation op2) {
    // Simplified operational transform implementation
    // In a real system, this would be much more sophisticated
    
    if (op1.fileName != op2.fileName) {
      return op1; // Operations on different files don't conflict
    }

    if (op1.type == 'insert' && op2.type == 'insert') {
      if (op2.position <= op1.position) {
        // op2 was inserted before op1, adjust op1's position
        return Operation(
          id: op1.id,
          userId: op1.userId,
          fileName: op1.fileName,
          type: op1.type,
          position: op1.position + (op2.text?.length ?? 0),
          text: op1.text,
          length: op1.length,
          timestamp: op1.timestamp,
          version: op1.version,
        );
      }
    }

    // Add more transformation rules as needed
    return op1;
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage(RealTimeMessage(
          id: _uuid.v4(),
          type: MessageType.heartbeat,
          senderId: _currentUser.id,
          payload: {'timestamp': DateTime.now().toIso8601String()},
          timestamp: DateTime.now(),
        ));
      } else {
        timer.cancel();
      }
    });
  }

  /// Get collaboration statistics
  Map<String, dynamic> getCollaborationStats() {
    return {
      'connectedUsers': _connectedUsers.length,
      'activeUsers': _connectedUsers.values.where((u) => 
          u.status == UserStatus.online || u.status == UserStatus.typing).length,
      'totalMessages': _chatMessages.length,
      'totalOperations': _operationBuffer.length,
      'sessionDuration': _isConnected && _sessionId != null 
          ? DateTime.now().difference(_currentUser.lastActivity).inMinutes
          : 0,
    };
  }

  /// Clear chat history
  void clearChatHistory() {
    _chatMessages.clear();
    _chatController.add(ChatMessage(
      id: _uuid.v4(),
      senderId: 'system',
      senderName: 'System',
      content: 'Chat history cleared',
      timestamp: DateTime.now(),
    ));
  }

  /// Get users currently typing
  List<CollaborativeUser> getTypingUsers() {
    return _connectedUsers.values
        .where((user) => user.status == UserStatus.typing && user.id != _currentUser.id)
        .toList();
  }

  /// Get user by ID
  CollaborativeUser? getUserById(String userId) {
    return _connectedUsers[userId];
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    final user = _connectedUsers[userId];
    return user != null && user.status != UserStatus.offline;
  }

  void _status(String message) {
    _statusController.add('[${DateTime.now().toIso8601String()}] $message');
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    _usersController.close();
    _cursorsController.close();
    _operationController.close();
    _chatController.close();
    _messageController.close();
    _statusController.close();
  }
}