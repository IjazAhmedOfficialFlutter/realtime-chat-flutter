import '../../model/user_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class UserApi {
  final ApiClient _apiClient;

  UserApi(this._apiClient);

  Future<List<UserModel>> getUsers() async {
    final response = await _apiClient.get(
      ApiConstants.users,
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid users response.');
    }

    return data
        .map(
          (item) => UserModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }
}