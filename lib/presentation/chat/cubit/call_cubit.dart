import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/calls_api.dart';
import '../../../model/call_model.dart';
import '../../../realtime/signalr_service.dart';
import 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final CallsApi _callsApi;
  final SignalRService _signalRService;

  CallCubit(
      this._callsApi,
      this._signalRService,
      ) : super(const CallInitial());

  Future<void> createCall({
    required int receiverId,
    required String callType,
  }) async {
    debugPrint(
      'CALL CUBIT: createCall receiverId=$receiverId callType=$callType',
    );

    try {
      final call = await _callsApi.createCall(
        receiverId: receiverId,
        callType: callType,
      );

      debugPrint(
        'CALL CUBIT: CREATE SUCCESS '
            'callId=${call.id} '
            'callerId=${call.callerId} '
            'receiverId=${call.receiverId} '
            'status=${call.status} '
            'room=${call.roomName}',
      );

      emit(CallOutgoing(call));
    } catch (e, stackTrace) {
      debugPrint('CALL CUBIT: CREATE ERROR: $e');
      debugPrint('CALL CUBIT STACK: $stackTrace');

      emit(CallError(e.toString()));
    }
  }

  Future<void> acceptCall(int callId) async {
    try {
      final call = await _callsApi.acceptCall(callId);
      emit(CallAccepted(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> rejectCall(int callId) async {
    try {
      final call = await _callsApi.rejectCall(callId);
      emit(CallRejected(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> cancelCall(int callId) async {
    try {
      final call = await _callsApi.cancelCall(callId);
      emit(CallCancelled(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> connectedCall(int callId) async {
    try {
      final call = await _callsApi.connectedCall(callId);
      emit(CallConnected(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> endCall(int callId) async {
    try {
      final call = await _callsApi.endCall(callId);
      emit(CallEnded(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> missedCall(int callId) async {
    try {
      final call = await _callsApi.missedCall(callId);
      emit(CallMissed(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<AgoraTokenResponse?> getAgoraToken(int callId) async {
    debugPrint(
      'CALL CUBIT: requesting Agora token callId=$callId',
    );

    try {
      final response = await _callsApi.getAgoraToken(callId);

      debugPrint(
        'CALL CUBIT: AGORA TOKEN SUCCESS '
            'callId=$callId '
            'room=${response.roomName} '
            'uid=${response.uid} '
            'tokenLength=${response.token.length}',
      );

      return response;
    } catch (e, stackTrace) {
      debugPrint('CALL CUBIT: AGORA TOKEN ERROR: $e');
      debugPrint('CALL CUBIT: AGORA TOKEN STACK: $stackTrace');

      return null;
    }
  }

  void handleIncomingCall(
      List<Object?>? arguments,
      ) {
    final data = _firstMap(arguments);

    if (data == null) {
      return;
    }

    final call = CallModel.fromJson(data);

    final callerName =
        data['callerName']?.toString() ?? 'Unknown caller';

    emit(
      CallIncoming(
        call: call,
        callerName: callerName,
      ),
    );
  }

  void handleCallAccepted(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallAccepted(call));
    }
  }

  void handleCallRejected(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallRejected(call));
    }
  }

  void handleCallCancelled(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallCancelled(call));
    }
  }

  void handleCallConnected(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallConnected(call));
    }
  }

  void handleCallEnded(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallEnded(call));
    }
  }

  void handleCallMissed(
      List<Object?>? arguments,
      ) {
    final call = _parseCall(arguments);

    if (call != null) {
      emit(CallMissed(call));
    }
  }

  Map<String, dynamic>? _firstMap(
      List<Object?>? arguments,
      ) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final value = arguments.first;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  CallModel? _parseCall(
      List<Object?>? arguments,
      ) {
    final data = _firstMap(arguments);

    if (data == null) {
      return null;
    }

    return CallModel.fromJson(data);
  }
}