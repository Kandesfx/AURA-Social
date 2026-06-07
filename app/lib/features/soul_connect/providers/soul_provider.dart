import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/soul_service.dart';
import '../models/soul_connection_model.dart';
import '../../chat/providers/chat_provider.dart';

/// AURA Social – Soul Connect Providers
///
/// Person 3, Task #11
/// Riverpod providers cho Soul Connect feature.

/// Danh sách suggestions từ API
final soulSuggestionsProvider =
    FutureProvider.autoDispose<List<SoulSuggestion>>((ref) async {
  final service = ref.read(soulConnectServiceProvider);
  return service.getSuggestions(limit: 10);
});

/// Index card hiện tại đang hiển thị
final currentSoulIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Action provider cho accept/reject
final soulActionProvider =
    StateNotifierProvider.autoDispose<SoulActionNotifier, SoulActionState>(
        (ref) {
  return SoulActionNotifier(ref.read(soulConnectServiceProvider), ref);
});

/// State cho soul actions
class SoulActionState {
  final bool isProcessing;
  final String? lastAction;
  final String? lastConnectionId;
  final String? error;

  const SoulActionState({
    this.isProcessing = false,
    this.lastAction,
    this.lastConnectionId,
    this.error,
  });

  SoulActionState copyWith({
    bool? isProcessing,
    String? lastAction,
    String? lastConnectionId,
    String? error,
  }) {
    return SoulActionState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastAction: lastAction ?? this.lastAction,
      lastConnectionId: lastConnectionId ?? this.lastConnectionId,
      error: error,
    );
  }
}

class SoulActionNotifier extends StateNotifier<SoulActionState> {
  SoulActionNotifier(this._service, this._ref) : super(const SoulActionState());

  final SoulConnectService _service;
  final Ref _ref;

  /// Accept connection
  Future<void> accept(String connectionId, String peerId) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await _service.respondToConnection(connectionId, 'accept');
      
      // Chống cháy: Tự động tạo phòng chat trống khi Accept
      await _ref.read(conversationActionsProvider).getOrCreateConversation(peerId);

      state = state.copyWith(
        isProcessing: false,
        lastAction: 'accept',
        lastConnectionId: connectionId,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Không thể kết nối. Thử lại sau.',
      );
    }
  }

  /// Reject connection
  Future<void> reject(String connectionId) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await _service.respondToConnection(connectionId, 'reject');
      state = state.copyWith(
        isProcessing: false,
        lastAction: 'reject',
        lastConnectionId: connectionId,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Có lỗi xảy ra. Thử lại sau.',
      );
    }
  }
}
