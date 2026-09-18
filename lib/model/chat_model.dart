class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime time;
  final bool isDelivered;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.time,
    required this.isDelivered,
    required this.isRead,
  });
}