import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/call_service.dart';
import '../../services/chat_service.dart';

enum CallState { dialing, ringing, connected, ended }

class CallScreen extends StatefulWidget {
  final UserModel caller;
  final UserModel receiver;
  final bool isVideoCall;
  final String callId;
  final bool isIncomingCall;

  const CallScreen({
    super.key,
    required this.caller,
    required this.receiver,
    this.isVideoCall = false,
    this.callId = '',
    this.isIncomingCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  CallState _callState = CallState.dialing;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;
  bool _isFrontCamera = true;
  int _callDurationSeconds = 0;
  String _activeCallId = '';

  Timer? _ringTimeoutTimer;
  Timer? _dialingTimer;
  Timer? _durationTimer;
  StreamSubscription<CallModel?>? _callSubscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isVideoOn = widget.isVideoCall;
    _activeCallId = widget.callId;

    // Hiệu ứng sóng nhịp đập avatar khi gọi thoại
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.isIncomingCall) {
      // Người nhận vừa bấm Nghe máy -> Trực tiếp kết nối
      _callState = CallState.connected;
      _startTimer();
      _listenToCallStatus();
    } else {
      // Người gọi (Caller) -> Khởi tạo cuộc gọi trên Firestore
      _initOutgoingCall();
    }
  }

  Future<void> _initOutgoingCall() async {
    if (_activeCallId.isEmpty) {
      _activeCallId = await CallService().startCall(
        caller: widget.caller,
        receiver: widget.receiver,
        isVideoCall: widget.isVideoCall,
      );
    }

    _listenToCallStatus();

    // Chuyển từ "Đang gọi..." sang "Đang đổ chuông..." sau 1.2 giây
    _dialingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _callState == CallState.dialing) {
        setState(() {
          _callState = CallState.ringing;
        });

        // Hết 20 giây không có phản hồi -> Báo nhỡ
        _ringTimeoutTimer = Timer(const Duration(seconds: 20), () {
          if (mounted && _callState == CallState.ringing) {
            _onCallRejected(reason: '${widget.receiver.displayName} không nhấc máy');
          }
        });
      }
    });
  }

  /// Lắng nghe phản hồi thời gian thực từ Firestore (Đồng ý / Từ chối / Kết thúc)
  void _listenToCallStatus() {
    if (_activeCallId.isEmpty) return;
    _callSubscription?.cancel();
    _callSubscription = CallService().getCallStream(_activeCallId).listen((callDoc) {
      if (!mounted || callDoc == null) return;

      if (callDoc.status == 'accepted' && _callState != CallState.connected) {
        // Bên kia đã bấm NGHE MÁY!
        _ringTimeoutTimer?.cancel();
        setState(() {
          _callState = CallState.connected;
        });
        _startTimer();
      } else if (callDoc.status == 'rejected') {
        // Bên kia đã bấm TỪ CHỐI!
        _onCallRejected(reason: '${widget.receiver.displayName} đã từ chối cuộc gọi');
      } else if (callDoc.status == 'ended' && _callState != CallState.ended) {
        // Cuộc gọi kết thúc
        _endCall(isRemote: true);
      }
    });
  }

  bool _hasSavedMessage = false;

  Future<void> _saveCallSummaryToChat({required bool isRejected}) async {
    if (_hasSavedMessage) return;
    _hasSavedMessage = true;

    final callerId = widget.caller.uid;
    final receiverId = widget.receiver.uid;
    final callType = widget.isVideoCall ? '🎥 Cuộc gọi video' : '📞 Cuộc gọi thoại';

    String text = '';
    if (_callDurationSeconds > 0) {
      text = '$callType • ${_formatDuration(_callDurationSeconds)}';
    } else if (isRejected) {
      text = '$callType bị từ chối';
    } else {
      text = '$callType nhỡ';
    }

    try {
      await ChatService().sendMessage(
        senderId: callerId,
        receiverId: receiverId,
        text: text,
      );
    } catch (e) {
      debugPrint('Lỗi lưu lịch sử cuộc gọi: $e');
    }
  }

  void _onCallRejected({String reason = 'Cuộc gọi đã bị từ chối'}) {
    _ringTimeoutTimer?.cancel();
    _dialingTimer?.cancel();
    _durationTimer?.cancel();
    _callSubscription?.cancel();

    _saveCallSummaryToChat(isRejected: true);

    if (_activeCallId.isNotEmpty) {
      CallService().rejectCall(_activeCallId);
    }

    if (mounted) {
      setState(() {
        _callState = CallState.ended;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _endCall({bool isRemote = false}) {
    _ringTimeoutTimer?.cancel();
    _dialingTimer?.cancel();
    _durationTimer?.cancel();
    _callSubscription?.cancel();

    _saveCallSummaryToChat(isRejected: false);

    if (!isRemote && _activeCallId.isNotEmpty) {
      CallService().endCall(_activeCallId);
    }

    if (mounted) {
      setState(() {
        _callState = CallState.ended;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _callDurationSeconds > 0
                ? 'Cuộc gọi kết thúc (${_formatDuration(_callDurationSeconds)})'
                : 'Đã hủy cuộc gọi',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  @override
  void dispose() {
    _ringTimeoutTimer?.cancel();
    _dialingTimer?.cancel();
    _durationTimer?.cancel();
    _callSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetUser = widget.isIncomingCall ? widget.caller : widget.receiver;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // MÀN HÌNH CHÍNH (GỌI THOẠI HẶC VIDEO)
            if (widget.isVideoCall && _isVideoOn && _callState == CallState.connected)
              _buildVideoBackground(targetUser)
            else
              _buildVoiceBackground(targetUser),

            // NÚT BACK VÀ TIÊU ĐỀ TRÊN CÙNG
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => _endCall(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isVideoCall ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),
                ],
              ),
            ),

            // PIP SELF CAMERA VIEW (CHO CUỘC GỌI VIDEO KHI ĐÃ KẾT NỐI)
            if (widget.isVideoCall && _isVideoOn && _callState == CallState.connected)
              Positioned(
                top: 70,
                right: 20,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.caller.avatarUrl.isNotEmpty
                            ? Image.network(widget.caller.avatarUrl, fit: BoxFit.cover)
                            : Container(
                                color: const Color(0xFF334155),
                                child: const Icon(Icons.person, color: Colors.white54, size: 40),
                              ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Tôi',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // CỤM NÚT ĐIỀU KHIỂN BÊN DƯỚI
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // MUTE MIC
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Bật mic' : 'Tắt mic',
                          isActive: _isMuted,
                          onTap: () {
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                          },
                        ),

                        // TOGGLE VIDEO (CHO CUỘC GỌI VIDEO)
                        if (widget.isVideoCall)
                          _buildControlButton(
                            icon: _isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                            label: _isVideoOn ? 'Tắt cam' : 'Bật cam',
                            isActive: !_isVideoOn,
                            onTap: () {
                              setState(() {
                                _isVideoOn = !_isVideoOn;
                              });
                            },
                          ),

                        // SWITCH CAMERA
                        if (widget.isVideoCall && _isVideoOn && _callState == CallState.connected)
                          _buildControlButton(
                            icon: Icons.cameraswitch_rounded,
                            label: 'Lật cam',
                            isActive: false,
                            onTap: () {
                              setState(() {
                                _isFrontCamera = !_isFrontCamera;
                              });
                            },
                          ),

                        // SPEAKER
                        _buildControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          label: 'Loa ngoài',
                          isActive: _isSpeakerOn,
                          onTap: () {
                            setState(() {
                              _isSpeakerOn = !_isSpeakerOn;
                            });
                          },
                        ),

                        // END CALL BUTTON
                        GestureDetector(
                          onTap: () => _endCall(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent,
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
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

  // GIAO DIỆN NỀN GỌI THOẠI
  Widget _buildVoiceBackground(UserModel targetUser) {
    String statusText;
    Color statusColor;

    switch (_callState) {
      case CallState.dialing:
        statusText = 'Đang gọi cho ${targetUser.displayName}...';
        statusColor = Colors.amberAccent;
        break;
      case CallState.ringing:
        statusText = 'Đang đổ chuông... Chờ đối phương nhấc máy';
        statusColor = Colors.lightBlueAccent;
        break;
      case CallState.connected:
        statusText = _formatDuration(_callDurationSeconds);
        statusColor = Colors.white70;
        break;
      case CallState.ended:
        statusText = 'Đã kết thúc';
        statusColor = Colors.redAccent;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // AVATAR CÓ HIỆU ỨNG NHỊP ĐẬP
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.1).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                border: Border.all(
                  color: _callState == CallState.connected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1).withValues(alpha: 0.5),
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundImage: targetUser.avatarUrl.isNotEmpty
                    ? NetworkImage(targetUser.avatarUrl)
                    : null,
                child: targetUser.avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 64, color: Colors.white70)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            targetUser.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // GIAO DIỆN NỀN GỌI VIDEO
  Widget _buildVideoBackground(UserModel targetUser) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // GIẢ LẬP CAMERA CỦA NGƯỜI NHẬN
        targetUser.avatarUrl.isNotEmpty
            ? Image.network(targetUser.avatarUrl, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Icon(Icons.person, size: 100, color: Colors.white24),
                ),
              ),

        // LỚP PHỦ TỐI MỜ
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // TÊN VÀ THỜI GIAN GỌI
        Positioned(
          top: 70,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                targetUser.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _callState == CallState.connected
                    ? _formatDuration(_callDurationSeconds)
                    : 'Đang đổ chuông...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black87 : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
