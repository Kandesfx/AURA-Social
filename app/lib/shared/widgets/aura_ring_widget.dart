import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/emotion_gradients.dart';

/// AURA Social – Aura Ring Widget (v2 – Connected to EmotionProfileModel)
///
/// Gradient ring quanh avatar, phản ánh cảm xúc của user.
/// ★ Component visual cốt lõi của AURA Social.
///
/// ### v2 improvements:
/// - [confidence] → điều chỉnh độ dày ring (cao = dày hơn)
/// - [arousal] → điều chỉnh tốc độ pulse (cao = nhanh hơn)
/// - CachedNetworkImage thay vì Image.network
/// - AnimatedSwitcher cho smooth transition khi emotion thay đổi
///
/// ### Usage:
/// ```dart
/// AuraRing(
///   size: 60,
///   imageUrl: user.avatarUrl,
///   emotionVector: emotionProfile.currentEmotionVector,
///   confidence: emotionProfile.emotionConfidence,
///   arousal: emotionProfile.arousal,
/// )
/// ```
class AuraRing extends StatefulWidget {
  const AuraRing({
    super.key,
    required this.size,
    this.imageUrl,
    this.emotionVector,
    this.ringWidth,
    this.glowIntensity = 0.4,
    this.animate = true,
    this.child,
    this.confidence = 0.5,
    this.arousal = 0.3,
  });

  /// Kích thước tổng thể (bao gồm ring)
  final double size;

  /// URL avatar (nếu null → hiện icon mặc định)
  final String? imageUrl;

  /// Emotion vector 8D – quyết định màu ring
  final Map<String, double>? emotionVector;

  /// Độ dày ring (auto-calculated dựa trên confidence nếu null)
  final double? ringWidth;

  /// Cường độ glow effect (0.0 – 1.0)
  final double glowIntensity;

  /// Có animation pulse không
  final bool animate;

  /// Widget con thay thế cho avatar image
  final Widget? child;

  /// Confidence score (0.0 – 1.0) → ảnh hưởng độ dày ring
  /// Confidence cao = ring dày hơn = AI tự tin hơn về emotion
  final double confidence;

  /// Arousal score (0.0 – 1.0) → ảnh hưởng tốc độ pulse
  /// Arousal cao = pulse nhanh hơn = trạng thái phấn khích
  final double arousal;

  @override
  State<AuraRing> createState() => _AuraRingState();
}

class _AuraRingState extends State<AuraRing>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    // Arousal ảnh hưởng tốc độ pulse: 0.0 → 3500ms, 1.0 → 1200ms
    final durationMs = (3500 - (widget.arousal * 2300)).clamp(1200, 3500).toInt();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
      _pulseController.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuraRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cập nhật animation speed khi arousal thay đổi đáng kể
    if ((oldWidget.arousal - widget.arousal).abs() > 0.1) {
      _pulseController.dispose();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Ring width dựa trên confidence: 2px (low) → 5px (high)
  double get _ringWidth {
    if (widget.ringWidth != null) return widget.ringWidth!;
    final base = widget.size < 50 ? 2.0 : widget.size < 80 ? 3.0 : 3.5;
    return base + (widget.confidence * 2.0); // 2.0–5.5px range
  }

  double get _glowRadius => widget.size < 50 ? 6 : 10;

  SweepGradient get _gradient {
    if (widget.emotionVector != null && widget.emotionVector!.isNotEmpty) {
      return EmotionGradients.fromVector(widget.emotionVector!);
    }
    return EmotionGradients.defaultAuraGradient;
  }

  @override
  Widget build(BuildContext context) {
    final pulseValue = widget.animate ? _pulseAnimation.value : 1.0;
    return _buildRing(pulseValue);
  }

  Widget _buildRing(double pulseValue) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer
          Container(
            width: widget.size * pulseValue,
            height: widget.size * pulseValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getDominantColor().withValues(
                    alpha: widget.glowIntensity * pulseValue,
                  ),
                  blurRadius: _glowRadius * pulseValue,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // Gradient ring
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AuraRingPainter(
              gradient: _gradient,
              ringWidth: _ringWidth,
            ),
          ),

          // Avatar clipped inside
          ClipOval(
            child: SizedBox(
              width: widget.size - (_ringWidth * 2) - 4,
              height: widget.size - (_ringWidth * 2) - 4,
              child: _buildAvatar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.child != null) return widget.child!;

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _defaultAvatar(),
        errorWidget: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: AuraColors.surfaceVariant,
      child: Icon(
        Icons.person_rounded,
        size: widget.size * 0.4,
        color: AuraColors.textTertiary,
      ),
    );
  }

  Color _getDominantColor() {
    if (widget.emotionVector == null || widget.emotionVector!.isEmpty) {
      return AuraColors.primary;
    }
    final sorted = widget.emotionVector!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return AuraColors.getEmotionColor(sorted.first.key);
  }
}

/// Custom painter vẽ gradient ring tròn
class _AuraRingPainter extends CustomPainter {
  _AuraRingPainter({required this.gradient, required this.ringWidth});

  final SweepGradient gradient;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (ringWidth / 2);

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuraRingPainter oldDelegate) =>
      oldDelegate.gradient != gradient || oldDelegate.ringWidth != ringWidth;
}
