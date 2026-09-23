import '../../model/message_model.dart';
import 'api_client.dart';

class MessagesApi {
  final ApiClient _apiClient;

  MessagesApi(this._apiClient);

  Future<List<MessageModel>> getConversation(
      int otherUserId,
      ) async {
    final response = await _apiClient.get(
      '/api/messages/$otherUserId',
    );

    final data = response.data;

    if (data is! List) {
      throw Exception(
        'Invalid conversation response.',
      );
    }

    return data
        .map(
          (item) => MessageModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  Future<void> markConversationRead(
      int otherUserId,
      ) async {
    await _apiClient.post(
      '/api/messages/$otherUserId/read',
    );
  }
}