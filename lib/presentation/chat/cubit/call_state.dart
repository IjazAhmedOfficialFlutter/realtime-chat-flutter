import '../../../model/call_model.dart';

sealed class CallState {
  const CallState();
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallIdle extends CallState {
  const CallIdle();
}

class CallOutgoing extends CallState {
  final CallModel call;

  const CallOutgoing(this.call);
}

class CallIncoming extends CallState {
  final CallModel call;
  final String callerName;

  const CallIncoming({
    required this.call,
    required this.callerName,
  });
}

class CallAccepted extends CallState {
  final CallModel call;

  const CallAccepted(this.call);
}

class CallRejected extends CallState {
  final CallModel call;

  const CallRejected(this.call);
}

class CallCancelled extends CallState {
  final CallModel call;

  const CallCancelled(this.call);
}

class CallConnected extends CallState {
  final CallModel call;

  const CallConnected(this.call);
}

class CallEnded extends CallState {
  final CallModel call;

  const CallEnded(this.call);
}

class CallMissed extends CallState {
  final CallModel call;

  const CallMissed(this.call);
}

class CallError extends CallState {
  final String message;

  const CallError(this.message);
}