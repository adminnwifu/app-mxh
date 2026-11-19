import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import 'call_screen.dart';

class IncomingCallDialog extends StatelessWidget {
  final CallModel call;

  const IncomingCallDialog({
    super.key,
    required this.call,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CẢNH BÁO CUỘC GỌI ĐẾN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  call.isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  call.isVideoCall ? 'CUỘC GỌI VIDEO ĐẾN' : 'CUỘC GỌI THOẠI ĐẾN',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AVATAR NGƯỜI GỌI
            CircleAvatar(
              radius: 42,
              backgroundImage: call.callerAvatar.isNotEmpty
                  ? NetworkImage(call.callerAvatar)
                  : null,
              child: call.callerAvatar.isEmpty
                  ? const Icon(Icons.person, size: 42, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 14),

            // TÊN NGƯỜI GỌI
            Text(
              call.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Đang gọi cho bạn...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),

            // NÚT TỪ CHỐI VÀ NGHE MÁY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // NÚT TỪ CHỐI
                GestureDetector(
                  onTap: () async {
                    await CallService().rejectCall(call.callId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent,
                              blurRadius: 10,
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
                      const SizedBox(height: 6),
                      const Text(
                        'Từ chối',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // NÚT NGHE MÁY (ĐỒNG Ý)
                GestureDetector(
                  onTap: () async {
                    await CallService().acceptCall(call.callId);
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Đóng hộp thoại

                      // Mở màn hình gọi điện ở chế độ Người nhận (Receiver)
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          fullscreenDialog: true,
                          pageBuilder: (context, anim, secAnim) => CallScreen(
                            caller: call.toCallerUserModel(),
                            receiver: call.toReceiverUserModel(),
                            isVideoCall: call.isVideoCall,
                            callId: call.callId,
                            isIncomingCall: true,
                          ),
                          transitionsBuilder: (context, anim, secAnim, child) {
                            return SlideTransition(
                              position: anim.drive(
                                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                                    .chain(CurveTween(curve: Curves.easeOutCubic)),
                              ),
                              child: child,
                            );
                          },
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nghe máy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
