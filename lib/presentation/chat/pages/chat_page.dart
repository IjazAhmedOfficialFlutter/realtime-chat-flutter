import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/messages_api.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../model/call_model.dart';
import '../../../model/message_model.dart';
import '../../../model/user_model.dart';
import '../../../realtime/signalr_service.dart';
import '../cubit/call_cubit.dart';
import '../cubit/call_state.dart';
import 'call_page.dart';

class ChatPage extends StatefulWidget {
  final UserModel receiver;

  const ChatPage({
    super.key,
    required this.receiver,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final _signalRService = locator<SignalRService>();
  final _preferences = locator<AppPreferences>();
  final _callCubit = locator<CallCubit>();
  final _messagesApi = locator<MessagesApi>();

  final List<MessageModel> _messages = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  late UserModel _receiver;

  bool _callDialogVisible = false;
  bool _sending = false;
  bool _isLoading = true;

  int? _activeCallId;

  String _connectionStatus = 'Connecting';

  int get _currentUserId => _preferences.userId ?? 0;

  @override
  void initState() {
    super.initState();

    _receiver = widget.receiver;

    _loadConversation();

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
          (results) {
        final hasNetwork = results.any(
              (result) => result != ConnectivityResult.none,
        );

        if (hasNetwork && !_signalRService.isConnected) {
          debugPrint('Network restored — reconnecting SignalR');
          _connectSignalR();
          return;
        }

        if (!hasNetwork && mounted) {
          setState(() {
            _connectionStatus = 'No internet connection';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _signalRService.disconnect();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      await _connectSignalR();

      final messages = await _messagesApi.getConversation(
        _receiver.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages
          ..clear()
          ..addAll(messages);

        _isLoading = false;
      });

      await _messagesApi.markConversationRead(
        _receiver.id,
      );

      if (!mounted) {
        return;
      }

      _jumpToBottom();
    } catch (e) {
      debugPrint('LOAD CONVERSATION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load messages: $e'),
        ),
      );
    }
  }

  Future<void> _connectSignalR() async {
    final token = _preferences.token;

    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _connectionStatus = 'Not authenticated';
      });

      return;
    }

    try {
      await _signalRService.connect(
        token,
        onStatus: (status) {
          if (!mounted) {
            return;
          }

          setState(() {
            _connectionStatus = status;
          });
        },
        onMessage: _handleIncomingMessage,
        onDelivered: _handleDelivered,
        onRead: _handleRead,
        onPresenceChanged: _handlePresenceChanged,
        onIncomingCall: (arguments) {
          debugPrint('CHAT PAGE IncomingCall: $arguments');
          _callCubit.handleIncomingCall(arguments);
        },
        onCallAccepted: (arguments) {
          debugPrint('CHAT PAGE CallAccepted: $arguments');
          _callCubit.handleCallAccepted(arguments);
        },
        onCallRejected: (arguments) {
          debugPrint('CHAT PAGE CallRejected: $arguments');
          _callCubit.handleCallRejected(arguments);
        },
        onCallCancelled: (arguments) {
          debugPrint('CHAT PAGE CallCancelled: $arguments');
          _callCubit.handleCallCancelled(arguments);
        },
        onCallConnected: (arguments) {
          debugPrint('CHAT PAGE CallConnected: $arguments');
          _callCubit.handleCallConnected(arguments);
        },
        onCallEnded: (arguments) {
          debugPrint('CHAT PAGE CallEnded: $arguments');
          _callCubit.handleCallEnded(arguments);
        },
        onCallMissed: (arguments) {
          debugPrint('CHAT PAGE CallMissed: $arguments');
          _callCubit.handleCallMissed(arguments);
        },
      );

      final status = await _signalRService.getUserStatus(
        _receiver.id,
      );

      if (status is! Map || !mounted) {
        return;
      }

      final json = Map<String, dynamic>.from(status);

      setState(() {
        _receiver = _receiver.copyWith(
          isOnline: json['isOnline'] == true,
          lastSeenAt: json['lastSeenAt'] == null
              ? null
              : DateTime.tryParse(
            json['lastSeenAt'].toString(),
          ),
        );
      });
    } catch (e) {
      debugPrint('SIGNALR CONNECTION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _connectionStatus = 'Connection failed';
      });
    }
  }

  Future<void> _startVoiceCall() async {
    debugPrint(
      'VOICE CALL BUTTON PRESSED - receiverId: ${_receiver.id}',
    );

    if (!_signalRService.isConnected) {
      debugPrint(
        'VOICE CALL FAILED: SignalR is not connected.',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat is not connected.'),
        ),
      );

      return;
    }

    debugPrint(
      'VOICE CALL STARTING - receiverId: ${_receiver.id}',
    );

    await _callCubit.createCall(
      receiverId: _receiver.id,
      callType: 'voice',
    );

    debugPrint('VOICE CALL REQUEST FINISHED');
  }

  Future<void> _startVideoCall() async {
    debugPrint(
      'VIDEO CALL BUTTON PRESSED - receiverId: ${_receiver.id}',
    );

    if (!_signalRService.isConnected) {
      debugPrint(
        'VIDEO CALL FAILED: SignalR is not connected.',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat is not connected.'),
        ),
      );

      return;
    }

    debugPrint(
      'VIDEO CALL STARTING - receiverId: ${_receiver.id}',
    );

    await _callCubit.createCall(
      receiverId: _receiver.id,
      callType: 'video',
    );

    debugPrint('VIDEO CALL REQUEST FINISHED');
  }

  void _handleIncomingMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final data = arguments.first;

    if (data is! Map) {
      return;
    }

    try {
      final message = MessageModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      if (!mounted) {
        return;
      }

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

      _scrollToBottom();

      if (message.receiverId == _currentUserId) {
        _markMessageAsRead(message.id);
      }
    } catch (e) {
      debugPrint('FAILED TO PARSE INCOMING MESSAGE: $e');
    }
  }

  Future<void> _markMessageAsRead(int messageId) async {
    if (!_signalRService.isConnected) {
      return;
    }

    try {
      await _signalRService.markDelivered(messageId);
      await _signalRService.markRead(messageId);
    } catch (e) {
      debugPrint('MARK MESSAGE READ ERROR: $e');
    }
  }

  void _handleDelivered(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final messageId = _parseIntArg(arguments.first);

    if (messageId == null || !mounted) {
      return;
    }

    setState(() {
      final index = _messages.indexWhere(
            (message) => message.id == messageId,
      );

      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isDelivered: true,
        );
      }
    });
  }

  void _handleRead(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final messageId = _parseIntArg(arguments.first);

    if (messageId == null || !mounted) {
      return;
    }

    setState(() {
      final index = _messages.indexWhere(
            (message) => message.id == messageId,
      );

      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isDelivered: true,
          isRead: true,
        );
      }
    });
  }

  void _handlePresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final data = arguments.first;

    if (data is! Map) {
      return;
    }

    final json = Map<String, dynamic>.from(data);

    final userId = _parseIntArg(json['userId']);

    if (userId == null ||
        userId != _receiver.id ||
        !mounted) {
      return;
    }

    setState(() {
      _receiver = _receiver.copyWith(
        isOnline: json['isOnline'] == true,
        lastSeenAt: json['lastSeenAt'] == null
            ? null
            : DateTime.tryParse(
          json['lastSeenAt'].toString(),
        ),
      );
    });
  }

  int? _parseIntArg(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

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

      if (result is! Map) {
        debugPrint(
          'SEND MESSAGE RETURNED UNEXPECTED DATA: $result',
        );
        return;
      }

      final message = MessageModel.fromJson(
        Map<String, dynamic>.from(result),
      );

      if (!mounted) {
        return;
      }

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
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
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
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _showIncomingCallDialog(CallIncoming state) {
    if (!mounted || _callDialogVisible) {
      return;
    }

    _callDialogVisible = true;

    final call = state.call;
    final isVideo = call.callType.toLowerCase() == 'video';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isVideo
                ? 'Incoming video call'
                : 'Incoming voice call',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(
                  state.callerName.trim().isEmpty
                      ? '?'
                      : state.callerName
                      .trim()
                      .characters
                      .first
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.callerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVideo ? 'Video call' : 'Voice call',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _callDialogVisible = false;

                await _callCubit.rejectCall(call.id);
              },
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _callDialogVisible = false;

                await _callCubit.acceptCall(call.id);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _callDialogVisible = false;
    });
  }

  void _showOutgoingCallDialog(CallOutgoing state) {
    if (!mounted || _callDialogVisible) {
      return;
    }

    _callDialogVisible = true;

    final call = state.call;
    final isVideo = call.callType.toLowerCase() == 'video';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Calling...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                child: Icon(
                  isVideo
                      ? Icons.videocam_outlined
                      : Icons.call_outlined,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _receiver.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Waiting for answer...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _callDialogVisible = false;

                await _callCubit.cancelCall(call.id);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _callDialogVisible = false;
    });
  }

  void _closeCallDialog() {
    if (!_callDialogVisible || !mounted) {
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).pop();

    _callDialogVisible = false;
  }

  void _handleCallState(
      BuildContext context,
      CallState state,
      ) {
    if (state is CallOutgoing) {
      _showOutgoingCallDialog(state);
      return;
    }

    if (state is CallIncoming) {
      _showIncomingCallDialog(state);
      return;
    }

    if (state is CallAccepted) {
      _closeCallDialog();
      _openCallPage(state.call);
      return;
    }

    if (state is CallRejected) {
      _closeCallDialog();
      _showCallMessage('Call rejected');
      return;
    }

    if (state is CallCancelled) {
      _closeCallDialog();
      _showCallMessage('Call cancelled');
      return;
    }

    if (state is CallMissed) {
      _closeCallDialog();
      _showCallMessage('Missed call');
      return;
    }

    if (state is CallEnded) {
      _closeCallDialog();
      _showCallMessage('Call ended');
      return;
    }

    if (state is CallConnected) {
      _showCallMessage('Call connected');
      return;
    }

    if (state is CallError) {
      _closeCallDialog();
      _showCallMessage(state.message);
    }
  }

  Future<void> _openCallPage(CallModel call) async {
    if (!mounted || _activeCallId == call.id) {
      return;
    }

    _activeCallId = call.id;

    try {
      debugPrint(
        'CHAT PAGE: requesting Agora token callId=${call.id}',
      );

      final agoraToken = await _callCubit.getAgoraToken(call.id);

      if (agoraToken == null) {
        debugPrint(
          'CHAT PAGE: Agora token request failed callId=${call.id}',
        );

        _activeCallId = null;

        if (mounted) {
          _showCallMessage(
            'Unable to start the call.',
          );
        }

        return;
      }

      debugPrint(
        'CHAT PAGE: Agora token received '
            'callId=${call.id} '
            'room=${agoraToken.roomName} '
            'uid=${agoraToken.uid} '
            'tokenLength=${agoraToken.token.length}',
      );

      if (!mounted) {
        _activeCallId = null;
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CallPage(
            call: call,
            callCubit: _callCubit,
            receiverName: _receiver.name,
            agoraToken: agoraToken,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CHAT PAGE: OPEN CALL ERROR: $e',
      );
      debugPrint(
        'CHAT PAGE: OPEN CALL STACK: $stackTrace',
      );

      if (mounted) {
        _showCallMessage(
          'Unable to start the call.',
        );
      }
    } finally {
      if (_activeCallId == call.id) {
        _activeCallId = null;
      }
    }
  }

  void _showCallMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
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

    return BlocProvider.value(
      value: _callCubit,
      child: BlocListener<CallCubit, CallState>(
        listener: _handleCallState,
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    _receiverInitial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                onPressed: _startVoiceCall,
                icon: const Icon(Icons.call_outlined),
              ),
              IconButton(
                tooltip: 'Video call',
                onPressed: _startVideoCall,
                icon: const Icon(Icons.videocam_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {},
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'search',
                    child: Text('Search'),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear chat'),
                  ),
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
                child: _isLoading
                    ? const SizedBox.shrink()
                    : _messages.isEmpty
                    ? _EmptyChat(
                  receiverName: _receiver.name,
                )
                    : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    20,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message =
                    _messages[_messages.length - 1 - index];

                    final mine =
                        message.senderId == _currentUserId;

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
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization:
                          TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor:
                            colors.surfaceContainerHighest,
                            prefixIcon: const Icon(
                              Icons.emoji_emotions_outlined,
                            ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String receiverName;

  const _EmptyChat({
    required this.receiverName,
  });

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

  const _MessageBubble({
    required this.message,
    required this.mine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: mine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: mine
              ? colors.primary
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              mine ? 18 : 4,
            ),
            bottomRight: Radius.circular(
              mine ? 4 : 18,
            ),
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
                  color: mine
                      ? colors.onPrimary
                      : colors.onSurface,
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
                message.isRead
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
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