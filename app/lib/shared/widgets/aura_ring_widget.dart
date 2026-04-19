import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/emotion_gradients.dart';

/// AURA Social – Aura Ring Widget
///
/// Gradient ring quanh avatar, phản ánh cảm xúc của user.
/// ★ Component visual cốt lõi của AURA Social.
///
/// Usage:
/// ```dart
/// AuraRing(
///   size: 60,
///   imageUrl: user.avatarUrl,
///   emotionVector: user.emotionVector,
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
  });

  /// Kích thước tổng thể (bao gồm ring)
  final double size;

  /// URL avatar (nếu null → hiện icon mặc định)
  final String? imageUrl;

  /// Emotion vector 8D – quyết định màu ring
  final Map<String, double>? emotionVector;

  /// Độ dày ring (auto-calculated nếu null)
  final double? ringWidth;

  /// Cường độ glow effect (0.0 – 1.0)
  final double glowIntensity;

  /// Có animation pulse không
  final bool animate;

  /// Widget con thay thế cho avatar image
  final Widget? child;

  @override
  State<AuraRing> createState() => _AuraRingState();
}

class _AuraRingState extends State<AuraRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _ringWidth =>
      widget.ringWidth ?? (widget.size < 50 ? 2.5 : widget.size < 80 ? 3.5 : 4.5);

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
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, st) => _defaultAvatar(),
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
