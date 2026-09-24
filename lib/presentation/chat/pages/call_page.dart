import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/calls_api.dart';
import '../../../model/call_model.dart';
import '../cubit/call_cubit.dart';

const String agoraAppId = '65583eccc19b4559b3660971a948e065';

class CallPage extends StatefulWidget {
  final CallModel call;
  final CallCubit callCubit;
  final String receiverName;
  final AgoraTokenResponse agoraToken;

  const CallPage({
    super.key,
    required this.call,
    required this.callCubit,
    required this.receiverName,
    required this.agoraToken,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;

  Timer? _durationTimer;
  DateTime? _connectedAt;

  bool _engineCreated = false;
  bool _initialized = false;
  bool _joined = false;
  bool _remoteJoined = false;

  bool _connectedReported = false;
  bool _muted = false;
  bool _speakerEnabled = true;
  bool _cameraEnabled = true;
  bool _endingCall = false;

  int _durationSeconds = 0;
  int? _remoteUid;

  bool get _isVideo => widget.call.callType.trim().toLowerCase() == 'video';

  int get _localUid => widget.agoraToken.uid;

  String get _displayName {
    final name = widget.receiverName.trim();

    return name.isEmpty ? 'Unknown' : name;
  }

  String get _initial {
    final name = widget.receiverName.trim();

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  String _tokenDebug(String token) {
    if (token.isEmpty) {
      return 'EMPTY';
    }

    if (token.length <= 12) {
      return 'length=${token.length}';
    }

    return 'length=${token.length}, '
        'prefix=${token.substring(0, 6)}, '
        'suffix=${token.substring(token.length - 6)}';
  }

  @override
  void initState() {
    super.initState();

    debugPrint('==========================================');
    debugPrint('CALL PAGE OPENED');
    debugPrint('CALL ID: ${widget.call.id}');
    debugPrint('CALL TYPE: ${widget.call.callType}');
    debugPrint('CALLER ID: ${widget.call.callerId}');
    debugPrint('RECEIVER ID: ${widget.call.receiverId}');
    debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
    debugPrint('LOCAL UID: $_localUid');
    debugPrint('TOKEN: ${_tokenDebug(widget.agoraToken.token)}');
    debugPrint('==========================================');

    _initializeAgora();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _disposeAgora();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();

    debugPrint(
      'AGORA MICROPHONE PERMISSION: '
      '$microphoneStatus',
    );

    if (!microphoneStatus.isGranted) {
      if (microphoneStatus.isPermanentlyDenied) {
        await openAppSettings();
      }

      _showError('Microphone permission is required for calls.');

      return false;
    }

    if (_isVideo) {
      final cameraStatus = await Permission.camera.request();

      debugPrint(
        'AGORA CAMERA PERMISSION: '
        '$cameraStatus',
      );

      if (!cameraStatus.isGranted) {
        if (cameraStatus.isPermanentlyDenied) {
          await openAppSettings();
        }

        _showError('Camera permission is required for video calls.');

        return false;
      }
    }

    return true;
  }

  Future<void> _initializeAgora() async {
    debugPrint('==========================================');
    debugPrint('AGORA INITIALIZATION START');
    debugPrint('APP ID: $agoraAppId');
    debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
    debugPrint('UID: $_localUid');
    debugPrint('VIDEO CALL: $_isVideo');
    debugPrint('==========================================');

    if (agoraAppId.trim().isEmpty) {
      _showError('Agora App ID is not configured.');
      return;
    }

    if (widget.agoraToken.token.trim().isEmpty) {
      _showError('Agora token is missing.');
      return;
    }

    if (widget.agoraToken.roomName.trim().isEmpty) {
      _showError('Agora channel is missing.');
      return;
    }

    if (_localUid <= 0) {
      _showError('Invalid Agora user ID.');
      return;
    }

    final permissionGranted = await _requestPermissions();

    if (!permissionGranted) {
      return;
    }

    try {
      debugPrint('AGORA STEP 1: create engine');

      final engine = createAgoraRtcEngine();

      _engine = engine;
      _engineCreated = true;

      debugPrint('AGORA STEP 2: initialize engine');

      await engine.initialize(
        const RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      debugPrint('AGORA STEP 2 SUCCESS');

      _eventHandler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) async {
          debugPrint('==========================================');
          debugPrint('AGORA LOCAL JOIN SUCCESS');
          debugPrint('CALL ID: ${widget.call.id}');
          debugPrint('CHANNEL: ${connection.channelId}');
          debugPrint('LOCAL UID: ${connection.localUid}');
          debugPrint('EXPECTED UID: $_localUid');
          debugPrint('ELAPSED: $elapsed');
          debugPrint('==========================================');

          if (!mounted) {
            return;
          }

          setState(() {
            _joined = true;
          });

          try {
            await engine.enableLocalAudio(true);

            debugPrint('AGORA LOCAL AUDIO: ENABLED');
          } catch (e) {
            debugPrint('AGORA LOCAL AUDIO ENABLE ERROR: $e');
          }

          if (!_isVideo) {
            try {
              await engine.setEnableSpeakerphone(_speakerEnabled);

              debugPrint(
                'AGORA SPEAKER: '
                '${_speakerEnabled ? 'ON' : 'OFF'}',
              );
            } catch (e) {
              debugPrint('AGORA SPEAKER ERROR: $e');
            }
          }
        },

        onUserJoined: (connection, remoteUid, elapsed) async {
          debugPrint('==========================================');
          debugPrint('AGORA REMOTE USER JOINED');
          debugPrint('CALL ID: ${widget.call.id}');
          debugPrint('CHANNEL: ${connection.channelId}');
          debugPrint('REMOTE UID: $remoteUid');
          debugPrint('LOCAL UID: ${connection.localUid}');
          debugPrint('ELAPSED: $elapsed');
          debugPrint('==========================================');

          if (remoteUid <= 0) {
            debugPrint(
              'AGORA INVALID REMOTE UID: '
              '$remoteUid',
            );
            return;
          }

          if (!mounted) {
            return;
          }

          setState(() {
            _remoteUid = remoteUid;
            _remoteJoined = true;
            _connectedAt = DateTime.now();
          });

          _startDurationTimer();

          if (_connectedReported) {
            return;
          }

          _connectedReported = true;

          debugPrint(
            'CALL CONNECTED API START '
            'callId=${widget.call.id}',
          );

          try {
            await widget.callCubit.connectedCall(widget.call.id);

            debugPrint(
              'CALL CONNECTED API SUCCESS '
              'callId=${widget.call.id}',
            );
          } catch (e) {
            debugPrint('CALL CONNECTED API ERROR: $e');
          }
        },

        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('==========================================');
          debugPrint('AGORA REMOTE USER OFFLINE');
          debugPrint('CALL ID: ${widget.call.id}');
          debugPrint('CHANNEL: ${connection.channelId}');
          debugPrint('REMOTE UID: $remoteUid');
          debugPrint('REASON: $reason');
          debugPrint('==========================================');

          if (!mounted) {
            return;
          }

          if (_remoteUid == remoteUid) {
            setState(() {
              _remoteUid = null;
              _remoteJoined = false;
            });
          }

          _handleRemoteDisconnected();
        },

        onFirstLocalAudioFramePublished: (connection, uid) {
          debugPrint(
            'AGORA FIRST LOCAL AUDIO PUBLISHED '
            'uid=$uid',
          );
        },

        onFirstRemoteAudioFrame: (connection, uid, elapsed) {
          debugPrint(
            'AGORA FIRST REMOTE AUDIO FRAME '
            'uid=$uid '
            'elapsed=$elapsed',
          );
        },

        onRemoteAudioStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
              debugPrint(
                'AGORA REMOTE AUDIO '
                'uid=$remoteUid '
                'state=$state '
                'reason=$reason '
                'elapsed=$elapsed',
              );
            },

        onLocalAudioStateChanged: (connection, state, reason) {
          debugPrint(
            'AGORA LOCAL AUDIO '
            'state=$state '
            'reason=$reason',
          );
        },

        onAudioPublishStateChanged: (channel, oldState, newState, elapsed) {
          debugPrint(
            'AGORA AUDIO PUBLISH STATE '
            'channel=$channel '
            'old=$oldState '
            'new=$newState '
            'elapsed=$elapsed',
          );
        },

        onAudioSubscribeStateChanged:
            (channel, uid, oldState, newState, elapsed) {
              debugPrint(
                'AGORA AUDIO SUBSCRIBE STATE '
                'channel=$channel '
                'uid=$uid '
                'old=$oldState '
                'new=$newState '
                'elapsed=$elapsed',
              );
            },

        onFirstLocalVideoFramePublished: (connection, uid) {
          debugPrint(
            'AGORA FIRST LOCAL VIDEO PUBLISHED '
            'uid=$uid',
          );
        },

        onFirstLocalVideoFrame: (source, width, height, elapsed) {
          debugPrint(
            'AGORA FIRST LOCAL VIDEO FRAME '
            'source=$source '
            'size=${width}x$height '
            'elapsed=$elapsed',
          );
        },

        onFirstRemoteVideoDecoded:
            (connection, remoteUid, width, height, elapsed) {
              debugPrint(
                'AGORA FIRST REMOTE VIDEO DECODED '
                'uid=$remoteUid '
                'size=${width}x$height '
                'elapsed=$elapsed',
              );
            },

        onFirstRemoteVideoFrame:
            (connection, remoteUid, width, height, elapsed) {
              debugPrint(
                'AGORA FIRST REMOTE VIDEO FRAME '
                'uid=$remoteUid '
                'size=${width}x$height '
                'elapsed=$elapsed',
              );
            },

        onLocalVideoStateChanged: (source, state, reason) {
          debugPrint(
            'AGORA LOCAL VIDEO '
            'source=$source '
            'state=$state '
            'reason=$reason',
          );
        },

        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
              debugPrint(
                'AGORA REMOTE VIDEO '
                'uid=$remoteUid '
                'state=$state '
                'reason=$reason '
                'elapsed=$elapsed',
              );
            },

        onUserMuteAudio: (connection, remoteUid, muted) {
          debugPrint(
            'AGORA REMOTE USER AUDIO '
            'uid=$remoteUid '
            'muted=$muted',
          );
        },

        onUserMuteVideo: (connection, remoteUid, muted) {
          debugPrint(
            'AGORA REMOTE USER VIDEO '
            'uid=$remoteUid '
            'muted=$muted',
          );
        },

        onConnectionStateChanged: (connection, state, reason) {
          debugPrint(
            'AGORA CONNECTION STATE '
            'callId=${widget.call.id} '
            'state=$state '
            'reason=$reason '
            'channel=${connection.channelId} '
            'uid=${connection.localUid}',
          );

          if (state == ConnectionStateType.connectionStateFailed) {
            _handleLocalConnectionFailure();
          }
        },

        onConnectionInterrupted: (connection) {
          debugPrint(
            'AGORA CONNECTION INTERRUPTED '
            'channel=${connection.channelId} '
            'uid=${connection.localUid}',
          );
        },

        onConnectionLost: (connection) {
          debugPrint(
            'AGORA CONNECTION LOST '
            'channel=${connection.channelId} '
            'uid=${connection.localUid}',
          );

          _handleLocalConnectionFailure();
        },

        onConnectionBanned: (connection) {
          debugPrint(
            'AGORA CONNECTION BANNED '
            'channel=${connection.channelId} '
            'uid=${connection.localUid}',
          );

          _handleLocalConnectionFailure();
        },

        onRequestToken: (connection) {
          debugPrint(
            'AGORA TOKEN REQUESTED '
            'channel=${connection.channelId} '
            'uid=${connection.localUid}',
          );
        },

        onPermissionError: (permissionType) {
          debugPrint(
            'AGORA PERMISSION ERROR: '
            '$permissionType',
          );
        },

        onPermissionGranted: (permissionType) {
          debugPrint(
            'AGORA PERMISSION GRANTED: '
            '$permissionType',
          );
        },

        onError: (errorCode, errorMessage) {
          debugPrint('==========================================');
          debugPrint('AGORA ERROR');
          debugPrint('CALL ID: ${widget.call.id}');
          debugPrint('CODE: $errorCode');
          debugPrint('MESSAGE: $errorMessage');
          debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
          debugPrint('UID: $_localUid');
          debugPrint('==========================================');
        },
      );

      engine.registerEventHandler(_eventHandler!);

      debugPrint('AGORA STEP 3: event handler registered');

      debugPrint('AGORA STEP 4: enable audio');

      await engine.enableAudio();

      await engine.enableLocalAudio(true);

      debugPrint('AGORA AUDIO READY');

      if (_isVideo) {
        debugPrint('AGORA STEP 5: enable video');

        await engine.enableVideo();

        await engine.enableLocalVideo(true);

        debugPrint('AGORA VIDEO READY');

        await engine.setupLocalVideo(
          const VideoCanvas(
            uid: 0,
            sourceType: VideoSourceType.videoSourceCamera,
            renderMode: RenderModeType.renderModeHidden,
            mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
          ),
        );

        debugPrint('AGORA LOCAL VIDEO VIEW READY');

        await engine.startPreview();

        debugPrint('AGORA LOCAL PREVIEW STARTED');
      }

      if (!_isVideo) {
        try {
          await engine.setDefaultAudioRouteToSpeakerphone(true);

          await engine.setEnableSpeakerphone(true);

          if (mounted) {
            setState(() {
              _speakerEnabled = true;
            });
          }

          debugPrint('AGORA DEFAULT AUDIO ROUTE: SPEAKER');
        } catch (e) {
          debugPrint('AGORA AUDIO ROUTE ERROR: $e');
        }
      }

      final mediaOptions = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: _isVideo,
        autoSubscribeAudio: true,
        autoSubscribeVideo: _isVideo,
        enableAudioRecordingOrPlayout: true,
      );

      debugPrint('==========================================');
      debugPrint('AGORA JOIN CHANNEL');
      debugPrint('CALL ID: ${widget.call.id}');
      debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
      debugPrint('UID: $_localUid');
      debugPrint('VIDEO: $_isVideo');
      debugPrint('PUBLISH AUDIO: true');
      debugPrint('PUBLISH VIDEO: $_isVideo');
      debugPrint('SUBSCRIBE AUDIO: true');
      debugPrint('SUBSCRIBE VIDEO: $_isVideo');
      debugPrint('AUDIO RECORDING/PLAYOUT: true');
      debugPrint('==========================================');

      await engine.joinChannel(
        token: widget.agoraToken.token,
        channelId: widget.agoraToken.roomName,
        uid: _localUid,
        options: mediaOptions,
      );

      debugPrint('AGORA JOIN CHANNEL RETURNED');

      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = true;
      });

      debugPrint(
        'AGORA INITIALIZATION COMPLETE '
        'callId=${widget.call.id}',
      );
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('AGORA INITIALIZATION ERROR');
      debugPrint('CALL ID: ${widget.call.id}');
      debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
      debugPrint('UID: $_localUid');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('==========================================');

      await _disposeAgora();

      _showError('Unable to start the call.');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _connectedAt == null) {
        return;
      }

      setState(() {
        _durationSeconds = DateTime.now().difference(_connectedAt!).inSeconds;
      });
    });
  }

  Future<void> _disposeAgora() async {
    final engine = _engine;

    if (engine == null || !_engineCreated) {
      return;
    }

    debugPrint('AGORA DISPOSE START');

    _durationTimer?.cancel();

    try {
      if (_eventHandler != null) {
        try {
          engine.unregisterEventHandler(_eventHandler!);
        } catch (e) {
          debugPrint('AGORA UNREGISTER HANDLER ERROR: $e');
        }

        _eventHandler = null;
      }

      if (_isVideo) {
        try {
          await engine.stopPreview();
        } catch (e) {
          debugPrint('AGORA STOP PREVIEW ERROR: $e');
        }
      }

      if (_joined) {
        try {
          await engine.leaveChannel();

          debugPrint('AGORA LEFT CHANNEL');
        } catch (e) {
          debugPrint('AGORA LEAVE CHANNEL ERROR: $e');
        }

        _joined = false;
      }

      try {
        await engine.release();

        debugPrint('AGORA ENGINE RELEASED');
      } catch (e) {
        debugPrint('AGORA RELEASE ERROR: $e');
      }
    } catch (e) {
      debugPrint('AGORA DISPOSE ERROR: $e');
    } finally {
      _engine = null;
      _engineCreated = false;
    }

    debugPrint('AGORA DISPOSE COMPLETE');
  }

  Future<void> _handleRemoteDisconnected() async {
    if (_endingCall) {
      return;
    }

    debugPrint('REMOTE DISCONNECTED -> END LOCAL CALL');

    if (mounted) {
      setState(() {
        _endingCall = true;
      });
    }

    _durationTimer?.cancel();

    await _disposeAgora();

    try {
      await widget.callCubit.endCall(widget.call.id);

      debugPrint('REMOTE DISCONNECT END CALL API SUCCESS');
    } catch (e) {
      debugPrint('REMOTE DISCONNECT END CALL API ERROR: $e');
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _handleLocalConnectionFailure() async {
    if (_endingCall) {
      return;
    }

    debugPrint('LOCAL AGORA CONNECTION FAILURE -> END CALL');

    if (mounted) {
      setState(() {
        _endingCall = true;
      });
    }

    _durationTimer?.cancel();

    await _disposeAgora();

    try {
      await widget.callCubit.endCall(widget.call.id);

      debugPrint('LOCAL CONNECTION FAILURE END CALL API SUCCESS');
    } catch (e) {
      debugPrint('LOCAL CONNECTION FAILURE END CALL API ERROR: $e');
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    final engine = _engine;

    if (engine == null || !_engineCreated || _endingCall) {
      return;
    }

    try {
      final nextMuted = !_muted;

      await engine.muteLocalAudioStream(nextMuted);

      if (!mounted) {
        return;
      }

      setState(() {
        _muted = nextMuted;
      });

      debugPrint('AGORA LOCAL MUTE: $nextMuted');
    } catch (e) {
      debugPrint('AGORA MUTE ERROR: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    final engine = _engine;

    if (engine == null || !_engineCreated || _endingCall) {
      return;
    }

    try {
      final nextSpeaker = !_speakerEnabled;

      await engine.setEnableSpeakerphone(nextSpeaker);

      if (!mounted) {
        return;
      }

      setState(() {
        _speakerEnabled = nextSpeaker;
      });

      debugPrint('AGORA SPEAKER: $nextSpeaker');
    } catch (e) {
      debugPrint('AGORA SPEAKER ERROR: $e');
    }
  }

  Future<void> _toggleCamera() async {
    final engine = _engine;

    if (!_isVideo || engine == null || !_engineCreated || _endingCall) {
      return;
    }

    try {
      final nextCamera = !_cameraEnabled;

      await engine.enableLocalVideo(nextCamera);

      await engine.muteLocalVideoStream(!nextCamera);

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraEnabled = nextCamera;
      });

      debugPrint('AGORA LOCAL CAMERA: $nextCamera');
    } catch (e) {
      debugPrint('AGORA CAMERA ERROR: $e');
    }
  }

  Future<void> _switchCamera() async {
    final engine = _engine;

    if (!_isVideo || engine == null || !_engineCreated || _endingCall) {
      return;
    }

    try {
      await engine.switchCamera();

      debugPrint('AGORA CAMERA SWITCHED');
    } catch (e) {
      debugPrint('AGORA SWITCH CAMERA ERROR: $e');
    }
  }

  Future<void> _endCall() async {
    if (_endingCall) {
      return;
    }

    if (mounted) {
      setState(() {
        _endingCall = true;
      });
    }

    _durationTimer?.cancel();

    await _disposeAgora();

    try {
      await widget.callCubit.endCall(widget.call.id);

      debugPrint('END CALL API SUCCESS');
    } catch (e) {
      debugPrint('END CALL API ERROR: $e');
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Widget _buildRemoteVideo() {
    final engine = _engine;
    final remoteUid = _remoteUid;

    if (engine == null ||
        !_engineCreated ||
        !_remoteJoined ||
        remoteUid == null ||
        remoteUid <= 0) {
      return _buildVideoWaitingView();
    }

    return Positioned.fill(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(
            uid: remoteUid,
            sourceType: VideoSourceType.videoSourceRemote,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: widget.agoraToken.roomName),
        ),
      ),
    );
  }

  Widget _buildVideoWaitingView() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF111111),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF202020), Color(0xFF080808)],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(radius: 54, large: true),
                  const SizedBox(height: 22),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    !_initialized
                        ? 'Starting camera...'
                        : !_joined
                        ? 'Connecting...'
                        : !_remoteJoined
                        ? 'Waiting for $_displayName...'
                        : 'Camera is off',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPreview() {
    final engine = _engine;

    if (!_isVideo ||
        engine == null ||
        !_engineCreated ||
        !_initialized ||
        !_cameraEnabled) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 82,
      right: 16,
      child: Container(
        width: 112,
        height: 158,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.75),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: engine,
            canvas: const VideoCanvas(
              uid: 0,
              sourceType: VideoSourceType.videoSourceCamera,
              renderMode: RenderModeType.renderModeHidden,
              mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceContent() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF202020), Color(0xFF080808)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(radius: 68, large: true),
              const SizedBox(height: 26),
              Text(
                _displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                !_initialized
                    ? 'Starting...'
                    : !_joined
                    ? 'Connecting...'
                    : !_remoteJoined
                    ? 'Ringing...'
                    : _formatDuration(_durationSeconds),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required double radius, bool large = false}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: large ? 2 : 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              _GlassButton(
                icon: Icons.keyboard_arrow_down_rounded,
                onPressed: _endCall,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _remoteJoined
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          !_joined
                              ? 'Connecting'
                              : !_remoteJoined
                              ? 'Waiting'
                              : _formatDuration(_durationSeconds),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GlassIcon(
                icon: _isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CallControlButton(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? 'Unmute' : 'Mute',
                    active: _muted,
                    onPressed: _toggleMute,
                  ),
                  const SizedBox(width: 14),
                  _CallControlButton(
                    icon: _speakerEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: _speakerEnabled ? 'Speaker' : 'Earpiece',
                    active: !_speakerEnabled,
                    onPressed: _toggleSpeaker,
                  ),
                  if (_isVideo) ...[
                    const SizedBox(width: 14),
                    _CallControlButton(
                      icon: _cameraEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: _cameraEnabled ? 'Camera' : 'Camera off',
                      active: !_cameraEnabled,
                      onPressed: _toggleCamera,
                    ),
                    const SizedBox(width: 14),
                    _CallControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onPressed: _switchCamera,
                    ),
                  ],
                  const SizedBox(width: 14),
                  _CallControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    backgroundColor: const Color(0xFFE53935),
                    size: 56,
                    iconSize: 26,
                    onPressed: _endCall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _endCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideo) _buildRemoteVideo() else _buildVoiceContent(),
            if (_isVideo) _buildLocalPreview(),
            _buildTopBar(),
            _buildControls(),
            if (_endingCall)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;

  const _GlassIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final bool active;
  final double size;
  final double iconSize;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.active = false,
    this.size = 50,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor ?? (active ? Colors.white24 : Colors.white12),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
