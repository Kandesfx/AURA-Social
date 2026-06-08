import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'error_widget.dart' show AuraErrorWidget, AuraEmptyWidget;
import 'loading_widget.dart' show AuraLoadingWidget;
import 'shimmer_loading.dart' show ShimmerFeedLoading, ShimmerNotificationTile, ShimmerChatList, ShimmerCompassLoading;

/// AURA Social – Unified State Builder
///
/// Widget tổng hợp xử lý mọi trạng thái: loading, success, error, empty.
/// Thay thế việc viết if/else lặp lại trong từng screen.
///
/// ### Usage:
/// ```dart
/// AuraStateBuilder<List<Post>>(
///   state: posts,
///   onLoading: () => const ShimmerFeedLoading(),
///   onEmpty: () => AuraEmptyWidget(title: 'Không có bài viết'),
///   onError: (error, retry) => AuraErrorWidget(message: error, onRetry: retry),
///   onSuccess: (posts) => PostList(posts: posts),
/// )
/// ```
///
/// Hoặc dùng variant có sẵn shimmer cho list:
/// ```dart
/// AuraStateListBuilder<List<Post>>(
///   state: posts,
///   onEmpty: () => AuraEmptyWidget(title: 'Không có bài viết'),
///   onError: (error, retry) => AuraErrorWidget(message: error, onRetry: retry),
///   onSuccess: (posts) => PostList(posts: posts),
/// )
/// ```
class AuraStateBuilder<T> extends StatelessWidget {
  const AuraStateBuilder({
    super.key,
    required this.state,
    required this.onLoading,
    required this.onEmpty,
    required this.onError,
    required this.onSuccess,
  });

  /// AsyncValue state từ Riverpod
  final AsyncValue<T> state;

  /// Widget hiển thị khi đang loading
  final Widget Function() onLoading;

  /// Widget hiển thị khi không có data
  final Widget Function() onEmpty;

  /// Widget hiển thị khi có lỗi
  /// - `error`: Error message
  /// - `onRetry`: Callback để thử lại
  final Widget Function(String error, VoidCallback? onRetry) onError;

  /// Widget hiển thị khi load thành công
  final Widget Function(T data) onSuccess;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (data) {
        if (data == null) return onEmpty();
        if (data is List && (data as List).isEmpty) return onEmpty();
        return onSuccess(data);
      },
      loading: onLoading,
      error: (error, stack) => onError(
        error.toString(),
        () => throw error, // Re-throw để trigger retry via ref.invalidate
      ),
    );
  }
}

/// Variant của AuraStateBuilder cho data dạng list với shimmer loading mặc định.
class AuraStateListBuilder<T> extends StatelessWidget {
  const AuraStateListBuilder({
    super.key,
    required this.state,
    this.shimmerItemCount = 3,
    this.onLoading,
    required this.onEmpty,
    required this.onError,
    required this.onSuccess,
  });

  final AsyncValue<T> state;
  final int shimmerItemCount;

  /// Override widget loading nếu cần, null = dùng shimmer mặc định
  final Widget Function()? onLoading;

  final Widget Function() onEmpty;
  final Widget Function(String error, VoidCallback? onRetry) onError;
  final Widget Function(T data) onSuccess;

  @override
  Widget build(BuildContext context) {
    return AuraStateBuilder<T>(
      state: state,
      onLoading: onLoading ?? () => _DefaultShimmerList(itemCount: shimmerItemCount),
      onEmpty: onEmpty,
      onError: onError,
      onSuccess: onSuccess,
    );
  }
}

/// Shimmer list mặc định cho AuraStateListBuilder
class _DefaultShimmerList extends StatelessWidget {
  const _DefaultShimmerList({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: itemCount,
      itemBuilder: (_, i) => _ShimmerPostItem(index: i),
    );
  }
}

class _ShimmerPostItem extends StatefulWidget {
  const _ShimmerPostItem({required this.index});
  final int index;

  @override
  State<_ShimmerPostItem> createState() => _ShimmerPostItemState();
}

class _ShimmerPostItemState extends State<_ShimmerPostItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AuraColors.surfaceVariant,
                      AuraColors.surfaceHigh,
                      _animation.value,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            AuraColors.surfaceVariant,
                            AuraColors.surfaceHigh,
                            _animation.value * 0.8,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            AuraColors.surfaceVariant,
                            AuraColors.surfaceHigh,
                            _animation.value * 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Content lines
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AuraColors.surfaceVariant,
                  AuraColors.surfaceHigh,
                  _animation.value * 0.6,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AuraColors.surfaceVariant,
                  AuraColors.surfaceHigh,
                  _animation.value * 0.6,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AuraColors.surfaceVariant,
                  AuraColors.surfaceHigh,
                  _animation.value * 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            // Reaction bar
            Row(
              children: List.generate(
                5,
                (i) => Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AuraColors.surfaceVariant,
                      AuraColors.surfaceHigh,
                      _animation.value * 0.4,
                    ),
                    shape: BoxShape.circle,
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

/// Retry helper provider wrapper
///
/// Wrap widget với retry support. Khi retry được gọi,
/// provider sẽ được invalidate và reload.
///
/// ```dart
/// Consumer(
///   builder: (context, ref, _) {
///     return AuraRetryWrapper(
///       onRetry: () => ref.invalidate(myProvider),
///       child: AuraStateBuilder(state: ref.watch(myProvider), ...),
///     );
///   },
/// )
/// ```
class AuraRetryWrapper extends StatelessWidget {
  const AuraRetryWrapper({
    super.key,
    required this.child,
    required this.onRetry,
  });

  final Widget child;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  VoidCallback? get retryCallback => onRetry;
}

/// Provider helper để create state với retry
/// ```dart
/// final myProvider = FutureProvider.autoDispose((ref) async {
///   return await fetchData();
/// });
///
/// // Trong screen:
/// AuraStateBuilder(
///   state: ref.watch(myProvider),
///   onRetry: () => ref.invalidate(myProvider),
///   ...
/// )
/// ```
extension AuraAsyncValueRetry<T> on AsyncValue<T> {
  /// Trả về error message hoặc null nếu không có lỗi
  String? get errorMessage {
    return maybeWhen(
      error: (e, _) => e.toString(),
      orElse: () => null,
    );
  }

  /// Kiểm tra có đang loading không
  bool get isLoading {
    return maybeWhen(orElse: () => false, loading: () => true);
  }

  /// Kiểm tra có data không
  bool get hasData {
    return maybeWhen(orElse: () => false, data: (_) => true);
  }

  /// Kiểm tra data có empty (với list)
  bool get isEmpty {
    return maybeWhen(
      orElse: () => false,
      data: (data) {
        if (data == null) return true;
        if (data is List) return (data as List).isEmpty;
        return false;
      },
    );
  }
}
