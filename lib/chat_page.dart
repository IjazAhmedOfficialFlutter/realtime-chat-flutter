import 'package:flutter/material.dart';

import '../realtime/signalr_service.dart';
import 'core/auth_services.dart';
import 'model/chat_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final SignalRService _signalR = SignalRService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  String _status = 'Connecting...';
  String _userName = '';
  String _receiverName = '';

  int _userId = 0;
  int _receiverId = 0;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final token = await _authService.getToken();
      final user = await _authService.getUser();

      if (token == null || user == null) {
        if (!mounted) {
          return;
        }

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _userId = (user['id'] as num).toInt();
      _userName = user['name']?.toString() ?? '';

      _setReceiver();

      debugPrint('LOGIN USER: $_userId - $_userName');

      debugPrint('CHAT RECEIVER: $_receiverId - $_receiverName');

      await _signalR.connect(
        token,
        onStatus: (status) {
          if (!mounted) {
            return;
          }

          setState(() {
            _status = status;
          });
        },
        onMessage: _handleIncomingMessage,
      );

      await _loadMessages();
    } catch (e) {
      debugPrint('SignalR error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Connection failed';
      });
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _authService.getMessages(_receiverId);

      if (!mounted) {
        return;
      }

      final messages = data.map(_mapMessage).whereType<ChatMessage>().toList();

      setState(() {
        for (final message in messages) {
          if (!_messages.any((item) => item.id == message.id)) {
            _messages.add(message);
          }
        }

        _messages.sort((a, b) => a.time.compareTo(b.time));
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Load messages error: $e');
    }
  }

  ChatMessage? _mapMessage(Map<String, dynamic> data) {
    final id = (data['id'] as num?)?.toInt();
    final senderId = (data['senderId'] as num?)?.toInt();
    final receiverId = (data['receiverId'] as num?)?.toInt();
    final content = data['content']?.toString();
    final createdAt = data['createdAt']?.toString();

    if (id == null ||
        senderId == null ||
        receiverId == null ||
        content == null ||
        createdAt == null ||
        content.trim().isEmpty) {
      return null;
    }

    return ChatMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      message: content,
      time: DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now(),
      isDelivered: data['isDelivered'] == true,
      isRead: data['isRead'] == true,
    );
  }

  void _setReceiver() {
    if (_userId == 1) {
      _receiverId = 2;
      _receiverName = 'Test User';
      return;
    }

    if (_userId == 2) {
      _receiverId = 1;
      _receiverName = 'Ijaz';
      return;
    }

    throw Exception('No receiver configured for user $_userId');
  }

  void _handleIncomingMessage(List<Object?>? arguments) {
    debugPrint('RECEIVED: $arguments');

    if (!mounted || arguments == null || arguments.isEmpty) {
      return;
    }

    final rawData = arguments.first;

    if (rawData is! Map) {
      return;
    }

    final data = Map<String, dynamic>.from(rawData);

    final message = _mapMessage(data);

    if (message == null) {
      return;
    }

    if (message.receiverId != _userId) {
      return;
    }

    if (_messages.any((item) => item.id == message.id)) {
      return;
    }

    setState(() {
      _messages.add(message);

      _messages.sort((a, b) => a.time.compareTo(b.time));
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty ||
        _status != 'Connected' ||
        _sending ||
        _receiverId == 0) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final result = await _signalR.sendMessage(_receiverId, text);

      if (!mounted) {
        return;
      }

      if (result is Map) {
        final data = Map<String, dynamic>.from(result);

        final message = _mapMessage(data);

        if (message != null &&
            !_messages.any((item) => item.id == message.id)) {
          setState(() {
            _messages.add(message);

            _messages.sort((a, b) => a.time.compareTo(b.time));
          });
        }
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Send message error: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message could not be sent')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _logout() async {
    await _signalR.disconnect();
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      return _MessageBubble(
                        message: message.message,
                        time: _formatTime(message.time),
                        isMine: message.senderId == _userId,
                        isDelivered: message.isDelivered,
                        isRead: message.isRead,
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isConnected = _status == 'Connected';

    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFF25D366),
            child: Text(
              _receiverName.isEmpty ? '?' : _receiverName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _receiverName.isEmpty ? 'Chat' : _receiverName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF25D366)
                          : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _status,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(35),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 34,
              color: Color(0xFF25D366),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            'Start a conversation with $_receiverName',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final canSend = _status == 'Connected' && !_sending;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, -2),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: canSend ? const Color(0xFF25D366) : Colors.grey,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canSend ? _sendMessage : null,
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: _sending
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMine;
  final bool isDelivered;
  final bool isRead;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMine,
    required this.isDelivered,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 55 : 0,
          right: isMine ? 0 : 55,
          bottom: 8,
        ),
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 7),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFFD9FDD3) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF202124),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            if (isMine) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.done_all,
                size: 15,
                color: isRead
                    ? const Color(0xFF53BDEB)
                    : isDelivered
                    ? Colors.grey
                    : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
