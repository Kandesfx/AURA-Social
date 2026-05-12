import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Privacy Settings Screen
///
/// Person 4, Task #11
/// Data export, delete account, privacy consent toggles.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quyền riêng tư'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Your Data ──
          _sectionHeader('DỮ LIỆU CỦA BẠN'),
          _buildCard(
            context,
            children: [
              _infoRow('Emotion Profile', '8D vector, cập nhật mỗi 30 phút'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _infoRow('Behavioral Events', 'Tự xóa sau 30 ngày'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _infoRow('Feed Cache', 'Pre-computed, refresh mỗi 15 phút'),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // ── Data Actions ──
          _sectionHeader('HÀNH ĐỘNG'),
          _buildCard(
            context,
            children: [
              _actionTile(
                icon: Icons.download_rounded,
                iconColor: AuraColors.info,
                title: 'Xuất dữ liệu',
                subtitle: 'Tải về toàn bộ dữ liệu của bạn (JSON)',
                onTap: () => _showExportDialog(context),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _actionTile(
                icon: Icons.visibility_off_rounded,
                iconColor: AuraColors.warning,
                title: 'Xóa dữ liệu AI',
                subtitle: 'Xóa Emotion Profile và Behavioral Events',
                onTap: () => _showDeleteDataDialog(context),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _actionTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AuraColors.error,
                title: 'Xóa tài khoản',
                subtitle: 'Xóa vĩnh viễn tài khoản và toàn bộ dữ liệu',
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 16),

          // ── GDPR Info ──
          _sectionHeader('THÔNG TIN BẢO MẬT'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuraColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bulletPoint('Dữ liệu cảm xúc được xử lý ẩn danh trên server'),
                const SizedBox(height: 8),
                _bulletPoint('Behavioral events tự động xóa sau 30 ngày'),
                const SizedBox(height: 8),
                _bulletPoint('AURA không bán dữ liệu cho bên thứ ba'),
                const SizedBox(height: 8),
                _bulletPoint('Bạn có quyền xuất và xóa dữ liệu bất kỳ lúc nào'),
                const SizedBox(height: 8),
                _bulletPoint('Tuân thủ GDPR và quy định bảo vệ dữ liệu'),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title, style: AuraTypography.labelSmall.copyWith(
        color: AuraColors.textTertiary, letterSpacing: 1.2)),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textPrimary)),
          ),
          Text(value, style: AuraTypography.bodySmall.copyWith(
            color: AuraColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(title, style: AuraTypography.bodyLarge.copyWith(
        color: AuraColors.textPrimary)),
      subtitle: Text(subtitle, style: AuraTypography.bodySmall.copyWith(
        color: AuraColors.textTertiary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AuraColors.textTertiary, size: 20),
    );
  }

  Widget _bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(top: 6, right: 10),
          decoration: BoxDecoration(
            color: AuraColors.success.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(text, style: AuraTypography.bodySmall.copyWith(
            color: AuraColors.textSecondary)),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất dữ liệu'),
        content: const Text('Toàn bộ dữ liệu của bạn sẽ được tải về dạng JSON. Tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang chuẩn bị dữ liệu...')),
              );
            },
            child: const Text('Xuất'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa dữ liệu AI?'),
        content: const Text('Emotion Profile và Behavioral Events sẽ bị xóa. '
            'AI sẽ bắt đầu học lại từ đầu. Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa dữ liệu AI')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.warning),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text('⚠️ Hành động này KHÔNG THỂ hoàn tác!\n\n'
            'Toàn bộ dữ liệu bao gồm bài viết, tin nhắn, kết nối và dữ liệu AI sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement GDPR cascade delete
            },
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.error),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
