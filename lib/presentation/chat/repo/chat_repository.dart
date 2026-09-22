
import '../../../model/message_model.dart';

abstract class ChatRepository {
  Future<List<MessageModel>> getMessages(
      int otherUserId,
      );

  Future<MessageModel> sendMessage({
    required int receiverId,
    required String message,
  });

  Future<void> markDelivered(
      int messageId,
      );

  Future<void> markRead(
      int messageId,
      );
}