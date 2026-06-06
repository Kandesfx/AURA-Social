import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// AURA Social – Loading Widget
///
/// Widget loading tái sử dụng xuyên suốt app.
/// Hiển thị spinner với brand colors + optional message.
///
/// ### Usage:
/// ```dart
/// const AuraLoadingWidget()
/// AuraLoadingWidget(message: 'Đang tải...')
/// ```
class AuraLoadingWidget extends StatelessWidget {
  const AuraLoadingWidget({super.key, this.message});

  /// Optional: message hiển thị bên dưới spinner
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient spinner container
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AuraColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AuraColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder cho list items (posts, comments, etc.)
///
/// ### Usage:
/// ```dart
/// AuraShimmerList(itemCount: 3) // 3 shimmer cards
/// ```
class AuraShimmerList extends StatelessWidget {
  const AuraShimmerList({super.key, this.itemCount = 3, this.itemHeight = 160});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, i) => _ShimmerCard(height: itemHeight, index: i),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard({required this.height, required this.index});
  final double height;
  final int index;

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Stagger animation start based on index
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color.lerp(
            AuraColors.surfaceVariant,
            AuraColors.surfaceHigh,
            _animation.value,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer (avatar + lines)
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.surfaceHigh.withValues(alpha: _animation.value),
                  ),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 120, height: 12, decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AuraColors.surfaceHigh.withValues(alpha: _animation.value),
                  )),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 10, decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AuraColors.surfaceHigh.withValues(alpha: _animation.value * 0.7),
                  )),
                ]),
              ]),
              const Spacer(),
              // Content lines shimmer
              Container(width: double.infinity, height: 10, decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AuraColors.surfaceHigh.withValues(alpha: _animation.value * 0.6),
              )),
              const SizedBox(height: 8),
              Container(width: 200, height: 10, decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AuraColors.surfaceHigh.withValues(alpha: _animation.value * 0.4),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
