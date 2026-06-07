import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/soul_connection_model.dart';
import 'soul_card.dart';

/// AURA Social – Swipe Card Stack
///
/// PageView-based container cho soul suggestion cards.
/// Swipe left = skip, swipe right = connect.
/// Hiển thị overlay indicator khi đang swipe.
class SwipeCardStack extends StatefulWidget {
  const SwipeCardStack({
    super.key,
    required this.suggestions,
    required this.currentIndex,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
  });

  final List<SoulSuggestion> suggestions;
  final int currentIndex;
  final Function(SoulSuggestion) onAccept;
  final Function(SoulSuggestion) onReject;
  final bool isProcessing;

  @override
  State<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<SwipeCardStack> {
  double _dragOffset = 0;
  bool _isDragging = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.primaryDelta ?? 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.abs() > threshold && widget.currentIndex < widget.suggestions.length) {
      final suggestion = widget.suggestions[widget.currentIndex];
      if (_dragOffset > 0) {
        widget.onAccept(suggestion);
      } else {
        widget.onReject(suggestion);
      }
    }

    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentIndex >= widget.suggestions.length) {
      return _buildEmptyState();
    }

    final suggestion = widget.suggestions[widget.currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = _dragOffset / screenWidth * 0.2;
    final opacity = (_dragOffset.abs() / screenWidth).clamp(0.0, 0.8);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Next card (behind, slightly smaller) ──
          if (widget.currentIndex + 1 < widget.suggestions.length)
            Transform.scale(
              scale: 0.92 + (_dragOffset.abs() / screenWidth * 0.08).clamp(0.0, 0.08),
              child: Opacity(
                opacity: 0.5 + (_dragOffset.abs() / screenWidth * 0.5).clamp(0.0, 0.5),
                child: SoulCard(
                  suggestion: widget.suggestions[widget.currentIndex + 1],
                  onAccept: () {},
                  onReject: () {},
                ),
              ),
            ),

          // ── Current card ──
          AnimatedContainer(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..translate(_dragOffset, 0.0, 0.0)
              ..rotateZ(rotation),
            transformAlignment: Alignment.center,
            child: Stack(
              children: [
                SoulCard(
                  suggestion: suggestion,
                  onAccept: () => widget.onAccept(suggestion),
                  onReject: () => widget.onReject(suggestion),
                  isProcessing: widget.isProcessing,
                ),

                // ── Swipe overlay indicators ──
                if (_isDragging && _dragOffset > 30)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: AuraColors.success.withValues(alpha: opacity * 0.15),
                        border: Border.all(
                          color: AuraColors.success.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AuraColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '💜 KẾT NỐI',
                              style: AuraTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_isDragging && _dragOffset < -30)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: AuraColors.error.withValues(alpha: opacity * 0.15),
                        border: Border.all(
                          color: AuraColors.error.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AuraColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '❌ BỎ QUA',
                              style: AuraTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: AuraColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã hết gợi ý',
              style: AuraTypography.headlineSmall.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau để khám phá thêm\nnhững tâm hồn đồng điệu! 💜',
              textAlign: TextAlign.center,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
