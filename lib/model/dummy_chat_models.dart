class DummyUser {
  final int id;
  final String name;
  final String username;
  final bool isOnline;
  final String lastSeen;
  final int unreadCount;

  const DummyUser({
    required this.id,
    required this.name,
    required this.username,
    required this.isOnline,
    required this.lastSeen,
    this.unreadCount = 0,
  });
}

class DummyMessage {
  final int id;
  final int senderId;
  final String message;
  final String time;
  final bool isRead;

  const DummyMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.time,
    required this.isRead,
  });
}

enum DummyCallType {
  incoming,
  outgoing,
  missed,
}

enum DummyCallMode {
  audio,
  video,
}

class DummyCall {
  final int id;
  final String userName;
  final DummyCallType type;
  final DummyCallMode mode;
  final String time;
  final String duration;

  const DummyCall({
    required this.id,
    required this.userName,
    required this.type,
    required this.mode,
    required this.time,
    required this.duration,
  });
}