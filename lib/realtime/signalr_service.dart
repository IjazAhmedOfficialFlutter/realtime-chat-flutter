import 'package:flutter/cupertino.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class SignalRService {
  HubConnection? _connection;

  void Function(String status)? _statusCallback;
  void Function(List<Object?>? arguments)? _messageCallback;
  void Function(List<Object?>? arguments)? _deliveredCallback;
  void Function(List<Object?>? arguments)? _readCallback;
  void Function(List<Object?>? arguments)? _presenceCallback;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect(
      String token, {
        void Function(String status)? onStatus,
        void Function(List<Object?>? arguments)? onMessage,
        void Function(List<Object?>? arguments)? onDelivered,
        void Function(List<Object?>? arguments)? onRead,
        void Function(List<Object?>? arguments)? onPresenceChanged,
      }) async {
    _statusCallback = onStatus;
    _messageCallback = onMessage;
    _deliveredCallback = onDelivered;
    _readCallback = onRead;
    _presenceCallback = onPresenceChanged;

    final existing = _connection;

    if (existing != null) {
      if (existing.state == HubConnectionState.Connected) {
        _statusCallback?.call('Connected');
        return;
      }

      if (existing.state != HubConnectionState.Disconnected) {
        return;
      }
    }

    const url = 'http://192.168.110.180:5082/hubs/chat';

    debugPrint('SignalR connecting: $url');

    final connection = HubConnectionBuilder()
        .withUrl(
      url,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
      ),
    )
        .withAutomaticReconnect()
        .build();

    _connection = connection;

    connection.on('ReceiveMessage', (arguments) {
      debugPrint('SignalR ReceiveMessage event: $arguments');
      _messageCallback?.call(arguments);
    });

    connection.on('MessageDelivered', (arguments) {
      debugPrint('SignalR MessageDelivered event: $arguments');
      _deliveredCallback?.call(arguments);
    });

    connection.on('MessageRead', (arguments) {
      debugPrint('SignalR MessageRead event: $arguments');
      _readCallback?.call(arguments);
    });

    connection.on('UserStatusChanged', (arguments) {
      debugPrint('SignalR UserStatusChanged event: $arguments');
      _presenceCallback?.call(arguments);
    });

    connection.onreconnecting(({error}) {
      debugPrint('SignalR reconnecting: $error');
      _statusCallback?.call('Reconnecting');
    });

    connection.onreconnected(({connectionId}) {
      debugPrint('SignalR reconnected: $connectionId');
      _statusCallback?.call('Connected');
    });

    connection.onclose(({error}) {
      debugPrint('SignalR disconnected: $error');
      if (identical(_connection, connection)) {
        _connection = null;
      }
      _statusCallback?.call('Disconnected');
    });

    _statusCallback?.call('Connecting');

    try {
      await connection.start();
      debugPrint('SignalR connected');
      _statusCallback?.call('Connected');
    } catch (e) {
      debugPrint('SignalR connection failed: $e');
      if (identical(_connection, connection)) {
        _connection = null;
      }
      _statusCallback?.call('Connection failed');
      rethrow;
    }
  }

  Future<Object?> sendMessage(int receiverId, String message) async {
    final connection = _connection;

    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw Exception('SignalR is not connected.');
    }

    return connection.invoke('SendMessage', args: [receiverId, message]);
  }

  Future<Object?> markDelivered(int messageId) async {
    final connection = _connection;

    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw Exception('SignalR is not connected.');
    }

    return connection.invoke('MarkDelivered', args: [messageId]);
  }

  Future<Object?> markRead(int messageId) async {
    final connection = _connection;

    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw Exception('SignalR is not connected.');
    }

    return connection.invoke('MarkRead', args: [messageId]);
  }

  Future<void> disconnect() async {
    final connection = _connection;

    _connection = null;
    _statusCallback = null;
    _messageCallback = null;
    _deliveredCallback = null;
    _readCallback = null;
    _presenceCallback = null;

    await connection?.stop();
  }

  Future<Object?> getUserStatus(int userId) async {
    final connection = _connection;
    if (connection == null || connection.state != HubConnectionState.Connected) {
      return null;
    }
    return connection.invoke('GetUserStatus', args: [userId]);
  }
}