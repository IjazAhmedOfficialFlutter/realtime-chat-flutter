import '../../model/call_model.dart';
import 'api_client.dart';

class CallsApi {
  final ApiClient _apiClient;

  CallsApi(this._apiClient);

  Future<CallModel> createCall({
    required int receiverId,
    required String callType,
  }) async {
    final response = await _apiClient.post(
      '/api/calls',
      data: {'receiverId': receiverId, 'callType': callType},
    );
    return CallModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CallModel> acceptCall(int callId) async {
    return _action('/api/calls/$callId/accept');
  }

  Future<CallModel> rejectCall(int callId) async {
    return _action('/api/calls/$callId/reject');
  }

  Future<CallModel> cancelCall(int callId) async {
    return _action('/api/calls/$callId/cancel');
  }

  Future<CallModel> connectedCall(int callId) async {
    return _action('/api/calls/$callId/connected');
  }

  Future<CallModel> endCall(int callId) async {
    return _action('/api/calls/$callId/end');
  }

  Future<CallModel> missedCall(int callId) async {
    return _action('/api/calls/$callId/missed');
  }

  Future<List<CallModel>> getCallHistory() async {
    final response = await _apiClient.get('/api/calls');
    final data = response.data;
    if (data is! List) {
      throw Exception('Invalid call history response.');
    }
    return data
        .map(
          (item) => CallModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AgoraTokenResponse> getAgoraToken(int callId) async {
    final response = await _apiClient.get('/api/calls/$callId/agora-token');
    return AgoraTokenResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CallModel> _action(String path) async {
    final response = await _apiClient.post(path);
    return CallModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}

class AgoraTokenResponse {
  final String token;
  final String roomName;
  final int uid;

  const AgoraTokenResponse({
    required this.token,
    required this.roomName,
    required this.uid,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      uid: int.tryParse(json['uid']?.toString() ?? '') ?? 0,
    );
  }

  AgoraTokenResponse copyWith({String? token, String? roomName, int? uid}) {
    return AgoraTokenResponse(
      token: token ?? this.token,
      roomName: roomName ?? this.roomName,
      uid: uid ?? this.uid,
    );
  }
}
