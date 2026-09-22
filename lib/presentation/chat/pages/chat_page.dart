import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../data/services/firebase_messaging_service.dart';
import '../../../model/message_model.dart';
import '../../../model/user_model.dart';
import '../../../realtime/signalr_service.dart';

class ChatPage extends StatefulWidget {
  final UserModel receiver;

  const ChatPage({super.key, required this.receiver});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _signalRService = locator<SignalRService>();
  final _preferences = locator<AppPreferences>();
  final List<MessageModel> _messages = [];
  String _connectionStatus = 'Connecting';
  bool _sending = false;
  late UserModel _receiver;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int get _currentUserId => _preferences.userId ?? 0;
  final _firebaseMessagingService = locator<FirebaseMessagingService>();
  @override
  void initState() {
    super.initState();

    _receiver = widget.receiver;
    _connectSignalR();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);

      if (hasNetwork && !_signalRService.isConnected) {
        debugPrint('Network restored — reconnecting SignalR');
        _connectSignalR();
      } else if (!hasNetwork && mounted) {
        setState(() {
          _connectionStatus = 'No internet connection';
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _signalRService.disconnect();
    super.dispose();
  }
  Future<void> _connectSignalR() async {
    final token = _preferences.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = 'Not authenticated';
      });
      return;
    }
    try {
      await _signalRService.connect(
        token,
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _connectionStatus = status;
          });
        },
        onMessage: _handleIncomingMessage,
        onDelivered: _handleDelivered,
        onRead: _handleRead,
        onPresenceChanged: _handlePresenceChanged,
      );

      final status = await _signalRService.getUserStatus(_receiver.id);
      if (status is Map && mounted) {
        final json = Map<String, dynamic>.from(status);
        setState(() {
          _receiver = _receiver.copyWith(isOnline: json['isOnline'] == true);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = 'Connection failed';
      });
    }
  }

  void _handleIncomingMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    final data = arguments.first;
    if (data is! Map) return;

    try {
      final message = MessageModel.fromJson(Map<String, dynamic>.from(data));

      if (!mounted) return;

      setState(() {
        final exists = _messages.any((item) => item.id == message.id);
        if (!exists) {
          _messages.add(message);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
      });

      _scrollToBottom();

      // Chat is open and visible, so a message addressed to me is both
      // delivered and read the moment it arrives.
      if (message.receiverId == _currentUserId) {
        _signalRService.markDelivered(message.id);
        _signalRService.markRead(message.id);
      }
    } catch (e) {
      debugPrint('Failed to parse incoming message: $e');
    }
  }

  void _handleDelivered(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    final messageId = _parseIntArg(arguments.first);
    if (messageId == null || !mounted) return;

    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isDelivered: true);
      }
    });
  }

  void _handleRead(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    final messageId = _parseIntArg(arguments.first);
    if (messageId == null || !mounted) return;

    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isDelivered: true,
          isRead: true,
        );
      }
    });
  }

  void _handlePresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    final data = arguments.first;
    if (data is! Map) return;

    final json = Map<String, dynamic>.from(data);
    final userId = _parseIntArg(json['userId']);

    if (userId == null || userId != _receiver.id || !mounted) return;

    setState(() {
      _receiver = _receiver.copyWith(
        isOnline: json['isOnline'] == true,
        lastSeenAt: json['lastSeenAt'] == null
            ? null
            : DateTime.tryParse(json['lastSeenAt'].toString()),
      );
    });
  }

  int? _parseIntArg(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    if (!_signalRService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat is not connected.'),
        ),
      );

      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final result = await _signalRService.sendMessage(
        _receiver.id,
        text,
      );

      if (result is Map) {
        final message = MessageModel.fromJson(
          Map<String, dynamic>.from(result),
        );

        if (mounted) {
          setState(() {
            final exists = _messages.any(
                  (item) => item.id == message.id,
            );

            if (!exists) {
              _messages.add(message);

              _messages.sort(
                    (a, b) => a.createdAt.compareTo(b.createdAt),
              );
            }
          });

          _messageController.clear();
          _scrollToBottom();
        }
      } else {
        debugPrint(
          'SendMessage returned unexpected data: $result',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: $e',
          ),
        ),
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

  String get _receiverInitial {
    final name = _receiver.name.trim();
    if (name.isEmpty) {
      return '?';
    }
    return name[0].toUpperCase();
  }

  String get _receiverStatus {
    if (_receiver.isOnline) {
      return 'Online';
    }
    if (_receiver.lastSeenAt != null) {
      return 'Last seen ${_formatLastSeen(_receiver.lastSeenAt!)}';
    }
    return 'Offline';
  }

  String _formatLastSeen(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(
                _receiverInitial,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _receiverStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _receiver.isOnline
                          ? Colors.green
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Voice call',
            onPressed: () {},
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'search', child: Text('Search')),
              PopupMenuItem(value: 'clear', child: Text('Clear chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_connectionStatus != 'Connected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: colors.surfaceContainerHighest,
              child: Text(
                _connectionStatus,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(receiverName: _receiver.name)
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final mine = message.senderId == _currentUserId;

                return _MessageBubble(
                  message: message,
                  mine: mine,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: _sending ? null : _sendMessage,
                    child: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String receiverName;

  const _EmptyChat({required this.receiverName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initial = receiverName.trim().isEmpty
        ? '?'
        : receiverName.trim()[0].toUpperCase();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colors.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start a conversation',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to $receiverName',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool mine;

  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: mine ? colors.onPrimary : colors.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? colors.onPrimary.withValues(alpha: 0.75)
                    : colors.onSurfaceVariant,
              ),
            ),
            if (mine) ...[
              const SizedBox(width: 3),
              Icon(
                message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 15,
                color: message.isRead
                    ? colors.onPrimary
                    : colors.onPrimary.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}