import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

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
  late RtcEngine _engine;

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

  bool get _isVideo => widget.call.callType.toLowerCase() == 'video';

  int get _localUid => widget.agoraToken.uid;

  String get _displayName {
    final name = widget.receiverName.trim();
    return name.isEmpty ? 'Unknown' : name;
  }

  String get _initial {
    final name = widget.receiverName.trim();
    return name.isEmpty ? '?' : name.characters.first.toUpperCase();
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
    debugPrint('========== CALL PAGE DEBUG ==========');
    debugPrint('CALL ID: ${widget.call.id}');
    debugPrint('CALL TYPE: ${widget.call.callType}');
    debugPrint('CALLER ID: ${widget.call.callerId}');
    debugPrint('RECEIVER ID: ${widget.call.receiverId}');
    debugPrint('ROOM NAME: ${widget.agoraToken.roomName}');
    debugPrint('LOCAL UID: ${widget.agoraToken.uid}');
    debugPrint('AGORA APP ID: $agoraAppId');
    debugPrint(
      'AGORA TOKEN: ${_tokenDebug(widget.agoraToken.token)}',
    );
    debugPrint('====================================');

    debugPrint('CALL PAGE: opened');
    debugPrint('CALL PAGE: callId=${widget.call.id}');
    debugPrint('CALL PAGE: callType=${widget.call.callType}');
    debugPrint('CALL PAGE: room=${widget.agoraToken.roomName}');
    debugPrint('CALL PAGE: uid=$_localUid');
    debugPrint(
      'CALL PAGE: tokenLength=${widget.agoraToken.token.length}',
    );

    _initializeAgora();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _initializeAgora() async {
    debugPrint('========== AGORA INITIALIZATION ==========');
    debugPrint('CALL ID: ${widget.call.id}');
    debugPrint('APP ID: $agoraAppId');
    debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
    debugPrint('UID: $_localUid');
    debugPrint(
      'TOKEN: ${_tokenDebug(widget.agoraToken.token)}',
    );
    debugPrint('VIDEO CALL: $_isVideo');
    debugPrint('==========================================');

    if (agoraAppId.isEmpty) {
      _showError('Agora App ID is not configured.');
      return;
    }

    if (widget.agoraToken.token.isEmpty) {
      _showError('Agora token is missing.');
      return;
    }

    if (widget.agoraToken.roomName.isEmpty) {
      _showError('Agora channel is missing.');
      return;
    }

    if (_localUid <= 0) {
      _showError('Invalid Agora user ID.');
      return;
    }

    try {
      debugPrint('AGORA STEP 1: createAgoraRtcEngine');

      _engine = createAgoraRtcEngine();
      _engineCreated = true;

      debugPrint('AGORA STEP 2: initialize');

      await _engine.initialize(
        const RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      debugPrint('AGORA STEP 3: initialize SUCCESS');

      _engine.registerEventHandler(
        RtcEngineEventHandler(
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

            if (!_isVideo) {
              try {
                await _engine.setEnableSpeakerphone(true);

                if (!mounted) {
                  return;
                }

                setState(() {
                  _speakerEnabled = true;
                });

                debugPrint(
                  'AGORA SPEAKER: enabled',
                );
              } catch (e) {
                debugPrint(
                  'AGORA SPEAKER ERROR: $e',
                );
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
              'CALL CONNECTED API START: callId=${widget.call.id}',
            );

            try {
              await widget.callCubit.connectedCall(
                widget.call.id,
              );

              debugPrint(
                'CALL CONNECTED API SUCCESS: callId=${widget.call.id}',
              );
            } catch (e) {
              debugPrint(
                'CALL CONNECTED API ERROR: $e',
              );
            }
          },

          onUserOffline: (
              connection,
              remoteUid,
              reason,
              ) {
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

            setState(() {
              if (_remoteUid == remoteUid) {
                _remoteUid = null;
                _remoteJoined = false;
              }
            });
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

          onConnectionStateChanged: (
              connection,
              state,
              reason,
              ) {
            debugPrint(
              'AGORA CONNECTION STATE: '
                  'callId=${widget.call.id} '
                  'state=$state '
                  'reason=$reason '
                  'channel=${connection.channelId} '
                  'uid=${connection.localUid}',
            );
          },

          onLocalVideoStateChanged: (
              source,
              state,
              error,
              ) {
            debugPrint(
              'AGORA LOCAL VIDEO: '
                  'source=$source '
                  'state=$state '
                  'error=$error',
            );
          },

          onRemoteVideoStateChanged: (
              connection,
              remoteUid,
              state,
              reason,
              elapsed,
              ) {
            debugPrint(
              'AGORA REMOTE VIDEO: '
                  'callId=${widget.call.id} '
                  'remoteUid=$remoteUid '
                  'state=$state '
                  'reason=$reason '
                  'elapsed=$elapsed',
            );
          },
        ),
      );

      debugPrint('AGORA STEP 4: event handler registered');

      debugPrint('AGORA STEP 5: enableAudio');

      await _engine.enableAudio();

      debugPrint('AGORA STEP 5 SUCCESS: audio enabled');

      if (_isVideo) {
        debugPrint('AGORA STEP 6: enableVideo');

        await _engine.enableVideo();

        debugPrint('AGORA STEP 6 SUCCESS: video enabled');

        debugPrint('AGORA STEP 7: startPreview');

        await _engine.startPreview();

        debugPrint('AGORA STEP 7 SUCCESS: preview started');
      }

      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: _isVideo,
        autoSubscribeAudio: true,
        autoSubscribeVideo: _isVideo,
      );

      debugPrint('==========================================');
      debugPrint('AGORA STEP 8: JOIN CHANNEL');
      debugPrint('CALL ID: ${widget.call.id}');
      debugPrint('APP ID: $agoraAppId');
      debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
      debugPrint('UID: $_localUid');
      debugPrint(
        'TOKEN: ${_tokenDebug(widget.agoraToken.token)}',
      );
      debugPrint('PUBLISH AUDIO: true');
      debugPrint('PUBLISH VIDEO: $_isVideo');
      debugPrint('SUBSCRIBE AUDIO: true');
      debugPrint('SUBSCRIBE VIDEO: $_isVideo');
      debugPrint('==========================================');

      await _engine.joinChannel(
        token: widget.agoraToken.token,
        channelId: widget.agoraToken.roomName,
        uid: _localUid,
        options: options,
      );

      debugPrint(
        'AGORA STEP 9: joinChannel() RETURNED',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = true;
      });

      debugPrint(
        'AGORA INITIALIZATION COMPLETE: callId=${widget.call.id}',
      );
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('AGORA INITIALIZATION ERROR');
      debugPrint('CALL ID: ${widget.call.id}');
      debugPrint('APP ID: $agoraAppId');
      debugPrint('CHANNEL: ${widget.agoraToken.roomName}');
      debugPrint('UID: $_localUid');
      debugPrint(
        'TOKEN: ${_tokenDebug(widget.agoraToken.token)}',
      );
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('==========================================');

      _showError(
        'Unable to start the call.',
      );
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted || _connectedAt == null) {
          return;
        }

        setState(() {
          _durationSeconds =
              DateTime.now().difference(_connectedAt!).inSeconds;
        });
      },
    );
  }

  Future<void> _disposeAgora() async {
    if (!_engineCreated) {
      return;
    }

    try {
      debugPrint('AGORA: disposing');

      if (_joined) {
        await _engine.leaveChannel();
        _joined = false;
      }

      await _engine.release();

      _engineCreated = false;

      debugPrint('AGORA: disposed');
    } catch (e) {
      debugPrint(
        'AGORA DISPOSE ERROR: $e',
      );
    }
  }

  Future<void> _toggleMute() async {
    if (!_engineCreated || _endingCall) {
      return;
    }

    try {
      final next = !_muted;

      await _engine.muteLocalAudioStream(next);

      if (!mounted) {
        return;
      }

      setState(() {
        _muted = next;
      });
    } catch (e) {
      debugPrint(
        'AGORA MUTE ERROR: $e',
      );
    }
  }

  Future<void> _toggleSpeaker() async {
    if (!_engineCreated || _endingCall) {
      return;
    }

    try {
      final next = !_speakerEnabled;

      await _engine.setEnableSpeakerphone(next);

      if (!mounted) {
        return;
      }

      setState(() {
        _speakerEnabled = next;
      });
    } catch (e) {
      debugPrint(
        'AGORA SPEAKER ERROR: $e',
      );
    }
  }

  Future<void> _toggleCamera() async {
    if (!_isVideo || !_engineCreated || _endingCall) {
      return;
    }

    try {
      final next = !_cameraEnabled;

      await _engine.enableLocalVideo(next);

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraEnabled = next;
      });
    } catch (e) {
      debugPrint(
        'AGORA CAMERA ERROR: $e',
      );
    }
  }

  Future<void> _switchCamera() async {
    if (!_isVideo || !_engineCreated || _endingCall) {
      return;
    }

    try {
      await _engine.switchCamera();
    } catch (e) {
      debugPrint(
        'AGORA SWITCH CAMERA ERROR: $e',
      );
    }
  }

  Future<void> _endCall() async {
    if (_endingCall) {
      return;
    }

    setState(() {
      _endingCall = true;
    });

    _durationTimer?.cancel();

    try {
      await _disposeAgora();

      await widget.callCubit.endCall(
        widget.call.id,
      );
    } catch (e) {
      debugPrint(
        'END CALL ERROR: $e',
      );
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
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
    });
  }

  Widget _buildVideoBackground() {
    if (!_remoteJoined || _remoteUid == null) {
      return _buildVideoWaitingView();
    }

    return Positioned.fill(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(
            uid: _remoteUid,
          ),
          connection: RtcConnection(
            channelId: widget.agoraToken.roomName,
          ),
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
                    colors: [
                      Color(0xFF202020),
                      Color(0xFF080808),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(
                    radius: 54,
                    large: true,
                  ),
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
                        : 'Connected',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.62,
                      ),
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
    if (!_isVideo ||
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
            rtcEngine: _engine,
            canvas: VideoCanvas(
              uid: _localUid,
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
            colors: [
              Color(0xFF202020),
              Color(0xFF080808),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(
                radius: 68,
                large: true,
              ),
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
                    : _formatDuration(
                  _durationSeconds,
                ),
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.65,
                  ),
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

  Widget _buildAvatar({
    required double radius,
    bool large = false,
  }) {
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
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
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
                              : _formatDuration(
                            _durationSeconds,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GlassIcon(
                icon: _isVideo
                    ? Icons.videocam_rounded
                    : Icons.call_rounded,
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
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            18,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CallControlButton(
                    icon: _muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: _muted ? 'Unmute' : 'Mute',
                    active: _muted,
                    onPressed: _toggleMute,
                  ),
                  const SizedBox(width: 14),
                  _CallControlButton(
                    icon: _speakerEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: _speakerEnabled
                        ? 'Speaker'
                        : 'Earpiece',
                    active: !_speakerEnabled,
                    onPressed: _toggleSpeaker,
                  ),
                  if (_isVideo) ...[
                    const SizedBox(width: 14),
                    _CallControlButton(
                      icon: _cameraEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: _cameraEnabled
                          ? 'Camera'
                          : 'Camera off',
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
            if (_isVideo)
              _buildVideoBackground()
            else
              _buildVoiceContent(),
            if (_isVideo) _buildLocalPreview(),
            _buildTopBar(),
            _buildControls(),
            if (_endingCall)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
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

  const _GlassButton({
    required this.icon,
    required this.onPressed,
  });

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
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;

  const _GlassIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 19,
      ),
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
          color: backgroundColor ??
              (active ? Colors.white24 : Colors.white12),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
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