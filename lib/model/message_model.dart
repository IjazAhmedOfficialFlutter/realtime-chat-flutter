import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isDelivered;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isDelivered,
    required this.isRead,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MessageModel(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      content: json['content'] as String? ?? '',
      isDelivered:
      json['isDelivered'] as bool? ?? false,
      isRead:
      json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'].toString(),
      ),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(
        json['deliveredAt'].toString(),
      )
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(
        json['readAt'].toString(),
      )
          : null,
    );
  }

  MessageModel copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    bool? isDelivered,
    bool? isRead,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isDelivered:
      isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    isDelivered,
    isRead,
    createdAt,
    deliveredAt,
    readAt,
  ];
}