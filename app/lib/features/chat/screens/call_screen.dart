import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../services/call_service.dart';
import '../models/call_model.dart';
import '../../../core/services/web_helpers.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    required this.callId,
    required this.isIncoming,
  });

  final String callId;
  final bool isIncoming;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _durationTimer;
  int _durationSeconds = 0;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  StreamSubscription? _callSub;

  @override
  void initState() {
    super.initState();
    requestMicPermission();
    _listenToCallState();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

  void _listenToCallState() {
    final callService = ref.read(callServiceProvider);
    _callSub = callService.streamCall(widget.callId).listen((call) {
      if (call == null) {
        _exitCall();
        return;
      }

      // Nếu cuộc gọi bị hủy, từ chối hoặc đã kết thúc
      if (call.status == CallStatus.ended || call.status == CallStatus.declined) {
        _exitCall();
        return;
      }

      // Bắt đầu đếm giây khi kết nối thành công
      if (call.status == CallStatus.connected && _durationTimer == null) {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  void _exitCall() {
    _callSub?.cancel();
    _durationTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration() {
    final minutes = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleDecline(CallModel call) async {
    await ref.read(callServiceProvider).declineCall(call.id);
    _exitCall();
  }

  Future<void> _handleAccept(CallModel call) async {
    await ref.read(callServiceProvider).acceptCall(call.id);
  }

  Future<void> _handleEndCall(CallModel call) async {
    await ref.read(callServiceProvider).endCall(call.id);
    _exitCall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<CallModel?>(
        stream: ref.read(callServiceProvider).streamCall(widget.callId),
        builder: (context, snapshot) {
          final call = snapshot.data;
          if (call == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final isCaller = !widget.isIncoming;
          final isRinging = call.status == CallStatus.ringing;
          final isConnected = call.status == CallStatus.connected;

          // Xác định thông tin đối phương để hiển thị
          final peerName = isCaller ? call.receiverName : call.callerName;
          final peerAvatar = isCaller ? call.receiverAvatar : call.callerAvatar;

          return Stack(
            children: [
              // ── Nền Camera mô phỏng (cho cuộc gọi Video đang kết nối) ──
              if (isConnected && call.type == CallType.video && !_isCameraOff)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuraColors.primary.withValues(alpha: 0.15),
                          AuraColors.tertiary.withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        color: Colors.white.withValues(alpha: 0.1),
                        size: 100,
                      ),
                    ),
                  ),
                )
              else
                // Nền tối huyền bí với các vòng tròn chuyển động chậm
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0F0C20),
                          Color(0xFF15102A),
                          Color(0xFF0A0814),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

              // ── Giao diện thông tin User ở giữa màn hình ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Trạng thái cuộc gọi dạng tag nổi bật
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          call.type == CallType.video ? '🎥 VIDEO CALL' : '📞 AUDIO CALL',
                          style: AuraTypography.labelMedium.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Avatar lớn ở giữa với xung Aura
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Vòng tròn Aura Ring đập theo nhịp (Pulsing ring)
                          if (isRinging)
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AuraColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.5.seconds, curve: Curves.easeOut)
                                .fadeOut(duration: 1.5.seconds),

                          AuraRing(
                            size: 130,
                            emotionVector: const {'joy': 0.8, 'trust': 0.6},
                            animate: true,
                            glowIntensity: isRinging ? 0.4 : 0.2,
                          ),

                          // Avatar
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AuraColors.surfaceVariant,
                            backgroundImage: peerAvatar != null && peerAvatar.isNotEmpty
                                ? NetworkImage(peerAvatar)
                                : null,
                            child: peerAvatar == null || peerAvatar.isEmpty
                                ? Text(
                                    peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                                    style: AuraTypography.headlineLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Tên đối phương
                      Text(
                        peerName,
                        style: AuraTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Trạng thái (Đang đổ chuông / Thời gian cuộc gọi)
                      if (isRinging)
                        Text(
                          isCaller ? 'Đang đổ chuông...' : 'Cuộc gọi đến...',
                          style: AuraTypography.bodyMedium.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (isConnected) ...[
                        Text(
                          _formatTimeText(call),
                          style: AuraTypography.titleLarge.copyWith(
                            color: AuraColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Đang kết nối âm thanh thử nghiệm. Trình duyệt đã được cấp quyền micro.',
                            style: AuraTypography.bodySmall.copyWith(
                              color: Colors.white38,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // ── Điều khiển cuộc gọi ở góc dưới ──
                      _buildControlButtons(context, call, isCaller, isRinging, isConnected),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimeText(CallModel call) {
    if (_durationSeconds == 0) return 'Đang kết nối...';
    return _formatDuration();
  }

  Widget _buildControlButtons(
    BuildContext context,
    CallModel call,
    bool isCaller,
    bool isRinging,
    bool isConnected,
  ) {
    if (isRinging && !isCaller) {
      // Giao diện nhận cuộc gọi của người nhận
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Nút Từ chối (Đỏ)
          _CircleButton(
            icon: Icons.call_end_rounded,
            color: AuraColors.error,
            onPressed: () => _handleDecline(call),
            size: 64,
          ),

          // Nút Nhận (Xanh lá)
          _CircleButton(
            icon: Icons.call_rounded,
            color: AuraColors.success,
            onPressed: () => _handleAccept(call),
            size: 64,
          ),
        ],
      );
    }

    // Giao diện khi đang đổ chuông bên gọi HOẶC khi đã kết nối
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isConnected) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mute Mic
              _CircleButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: _isMuted ? Colors.white24 : Colors.white10,
                iconColor: _isMuted ? Colors.redAccent : Colors.white,
                onPressed: () => setState(() => _isMuted = !_isMuted),
              ),
              const SizedBox(width: 24),

              // Camera Toggle (Chỉ hiện khi cuộc gọi video)
              if (call.type == CallType.video) ...[
                _CircleButton(
                  icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                  color: _isCameraOff ? Colors.white24 : Colors.white10,
                  iconColor: _isCameraOff ? Colors.redAccent : Colors.white,
                  onPressed: () => setState(() => _isCameraOff = !_isCameraOff),
                ),
                const SizedBox(width: 24),
              ],

              // Speaker switch (Simulate/Mock)
              _CircleButton(
                icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _isSpeakerOn ? Colors.white10 : Colors.white24,
                iconColor: _isSpeakerOn ? Colors.white : Colors.redAccent,
                onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],

        // Nút Gác máy (Đỏ)
        _CircleButton(
          icon: Icons.call_end_rounded,
          color: AuraColors.error,
          onPressed: () => _handleEndCall(call),
          size: 68,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.onPressed,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RawMaterialButton(
        onPressed: onPressed,
        elevation: 2.0,
        fillColor: color,
        shape: const CircleBorder(),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.45,
        ),
      ),
    );
  }
}
