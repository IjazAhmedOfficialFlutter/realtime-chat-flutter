import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

  Future<void> connect(String token) async {
    const url = 'http://192.168.110.180:5082/hubs/chat';

    debugPrint('SignalR connecting: $url');

    _connection = HubConnectionBuilder()
        .withUrl(
      url,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
      ),
    )
        .build();

    _connection!.onclose(({error}) {
      debugPrint('SignalR disconnected: $error');
    });

    await _connection!.start();

    debugPrint('SignalR connected');
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  Future<void> sendMessage(
      int receiverId,
      String message,
      ) async {
    debugPrint(
      'Sending message to $receiverId: $message',
    );

    await _connection?.invoke(
      'SendMessage',
      args: [
        receiverId,
        message,
      ],
    );
  }

  void onMessage(
      void Function(List<Object?>?) callback,
      ) {
    _connection?.on(
      'ReceiveMessage',
      callback,
    );
  }
}