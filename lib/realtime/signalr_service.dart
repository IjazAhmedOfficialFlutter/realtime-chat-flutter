import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

  void Function(String status)? _statusCallback;
  void Function(List<Object?>? arguments)? _messageCallback;

  Future<void> connect(
    String token, {
    void Function(String status)? onStatus,
    void Function(List<Object?>? arguments)? onMessage,
  }) async {
    _statusCallback = onStatus;
    _messageCallback = onMessage;

    final currentConnection = _connection;

    if (currentConnection != null &&
        currentConnection.state != HubConnectionState.Disconnected) {
      return;
    }

    const url = 'http://192.168.110.180:5082/hubs/chat';

    debugPrint('SignalR connecting: $url');

    final connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    _connection = connection;

    connection.on('ReceiveMessage', (arguments) {
      _messageCallback?.call(arguments);
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

    debugPrint('Sending message to $receiverId: $message');

    return connection.invoke('SendMessage', args: [receiverId, message]);
  }

  Future<void> disconnect() async {
    final connection = _connection;

    _connection = null;
    _statusCallback = null;
    _messageCallback = null;

    await connection?.stop();
  }

  bool get isConnected => _connection?.state == HubConnectionState.Connected;
}
