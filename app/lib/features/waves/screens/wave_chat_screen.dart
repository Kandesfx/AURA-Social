import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/wave_model.dart';
import '../providers/waves_provider.dart';
import '../widgets/wave_momentum_bar.dart';
import '../widgets/wave_member_list.dart';

/// AURA Social – Wave Chat Screen
///
/// Person 3, Task #17
/// Group chat screen cho 1 Emotional Wave.
/// - Wave info header
/// - Message list
/// - Input bar
/// - Member list drawer
class WaveChatScreen extends ConsumerStatefulWidget {
  const WaveChatScreen({
    super.key,
    required this.waveId,
  });

  final String waveId;

  @override
  ConsumerState<WaveChatScreen> createState() => _WaveChatScreenState();
}

class _WaveChatScreenState extends ConsumerState<WaveChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(waveMessagesProvider(widget.waveId).notifier)
        .sendMessage(text, 'Bạn');
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(waveMessagesProvider(widget.waveId));
    final wavesAsync = ref.watch(activeWavesProvider);

    // Find wave info
    final wave = wavesAsync.whenOrNull(
      data: (waves) => waves.where((w) => w.id == widget.waveId).firstOrNull,
    );

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: _buildAppBar(context, wave),
      body: Column(
        children: [
          // ── Wave Info Banner ──
          if (wave != null) _buildWaveInfoBanner(wave),

          // ── Messages ──
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = msg.senderId == 'current-user-id';

                      return _WaveMessageBubble(
                        message: msg,
                        isMine: isMine,
                      ).animate(delay: Duration(milliseconds: (index * 30).clamp(0, 300)))
                          .fadeIn(duration: 250.ms);
                    },
                  ),
          ),

          // ── Input ──
          _buildInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WaveModel? wave) {
    return AppBar(
      backgroundColor: AuraColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(wave?.emoji ?? '🌊', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wave?.title ?? 'Wave Chat',
                  style: AuraTypography.titleSmall.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${wave?.memberCount ?? 0} thành viên',
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline_rounded, size: 22),
          onPressed: () => _showMemberSheet(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AuraColors.surfaceBorder),
      ),
    );
  }

  Widget _buildWaveInfoBanner(WaveModel wave) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        border: Border(
          bottom: BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: WaveMomentumBar(momentum: wave.momentum, height: 4),
          ),
          const SizedBox(width: 12),
          if (wave.timeRemainingText.isNotEmpty)
            Text(
              '⏰ ${wave.timeRemainingText}',
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        border: Border(
          top: BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AuraColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AuraColors.surfaceBorder,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AuraColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện!',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chia sẻ cảm xúc của bạn\nvới mọi người trong wave này.',
            textAlign: TextAlign.center,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  void _showMemberSheet(BuildContext context) {
    final membersAsync = ref.read(waveMembersProvider(widget.waveId));

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AuraColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thành viên',
                  style: AuraTypography.headlineSmall.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                membersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AuraColors.primary,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Không thể tải danh sách thành viên',
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                  data: (members) => WaveMemberListExpanded(members: members),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Message bubble cho Wave chat
class _WaveMessageBubble extends StatelessWidget {
  const _WaveMessageBubble({
    required this.message,
    required this.isMine,
  });

  final WaveMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 64 : 12,
        right: isMine ? 12 : 64,
        top: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (not for own messages)
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                message.senderName,
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMine
                  ? LinearGradient(
                      colors: [
                        AuraColors.primary.withValues(alpha: 0.25),
                        AuraColors.primary.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              color: isMine ? null : AuraColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine
                  ? null
                  : Border.all(
                      color: AuraColors.surfaceBorder,
                      width: 0.5,
                    ),
            ),
            child: Text(
              message.content,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
          ),

          // Time
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
            child: Text(
              _formatTime(message.timestamp),
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.textTertiary,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
