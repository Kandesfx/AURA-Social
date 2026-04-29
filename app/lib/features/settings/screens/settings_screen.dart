import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/settings_provider.dart';

/// AURA Social – Settings Screen
///
/// Person 4, Task #9
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Profile Section ──
          _buildSection(
            context,
            children: [
              _buildTile(
                icon: Icons.person_outline_rounded,
                iconColor: AuraColors.primary,
                title: 'Chỉnh sửa hồ sơ',
                subtitle: 'Tên, ảnh đại diện, bio',
                onTap: () {},
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 8),

          // ── Appearance ──
          _buildSection(
            context,
            header: 'GIAO DIỆN',
            children: [
              _buildThemeTile(context, ref, settings),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

          const SizedBox(height: 8),

          // ── Notifications ──
          _buildSection(
            context,
            header: 'THÔNG BÁO',
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                iconColor: AuraColors.emotionJoy,
                title: 'Push Notifications',
                subtitle: 'Nhận thông báo trên thiết bị',
                value: settings.notificationsEnabled,
                onChanged: (v) => ref.read(settingsProvider.notifier).setNotificationsEnabled(v),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 8),

          // ── AI & Privacy ──
          _buildSection(
            context,
            header: 'AI & QUYỀN RIÊNG TƯ',
            children: [
              _buildTile(
                icon: Icons.auto_awesome_rounded,
                iconColor: AuraColors.secondary,
                title: 'Cài đặt AI',
                subtitle: 'Quản lý các tính năng AI',
                onTap: () => context.push('/settings/ai'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AuraColors.textTertiary, size: 20),
              ),
              _divider(),
              _buildTile(
                icon: Icons.shield_outlined,
                iconColor: AuraColors.success,
                title: 'Quyền riêng tư',
                subtitle: 'Dữ liệu, xuất & xóa tài khoản',
                onTap: () => context.push('/settings/privacy'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AuraColors.textTertiary, size: 20),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

          const SizedBox(height: 8),

          // ── About ──
          _buildSection(
            context,
            header: 'THÔNG TIN',
            children: [
              _buildTile(
                icon: Icons.info_outline_rounded,
                iconColor: AuraColors.info,
                title: 'Về AURA Social',
                subtitle: 'Phiên bản 1.0.0',
                onTap: () {},
              ),
              _divider(),
              _buildTile(
                icon: Icons.description_outlined,
                iconColor: AuraColors.textTertiary,
                title: 'Điều khoản sử dụng',
                onTap: () {},
              ),
              _divider(),
              _buildTile(
                icon: Icons.policy_outlined,
                iconColor: AuraColors.textTertiary,
                title: 'Chính sách bảo mật',
                onTap: () {},
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 8),

          // ── Logout ──
          _buildSection(
            context,
            children: [
              _buildTile(
                icon: Icons.logout_rounded,
                iconColor: AuraColors.error,
                title: 'Đăng xuất',
                titleColor: AuraColors.error,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {String? header, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(header, style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.textTertiary, letterSpacing: 1.2)),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(title, style: AuraTypography.bodyLarge.copyWith(
        color: titleColor ?? AuraColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle, style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary))
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AuraColors.primary,
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return _buildTile(
      icon: settings.themeMode == ThemeMode.dark
          ? Icons.dark_mode_rounded
          : settings.themeMode == ThemeMode.light
              ? Icons.light_mode_rounded
              : Icons.brightness_auto_rounded,
      iconColor: AuraColors.emotionSurprise,
      title: 'Giao diện',
      subtitle: settings.themeMode == ThemeMode.dark
          ? 'Tối'
          : settings.themeMode == ThemeMode.light
              ? 'Sáng'
              : 'Tự động',
      onTap: () => _showThemeDialog(context, ref, settings),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AuraColors.textTertiary, size: 20),
    );
  }

  Widget _divider() {
    return const Divider(height: 0.5, indent: 56, endIndent: 16);
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn giao diện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(ctx, ref, 'Tối', ThemeMode.dark, settings.themeMode),
            _themeOption(ctx, ref, 'Sáng', ThemeMode.light, settings.themeMode),
            _themeOption(ctx, ref, 'Theo hệ thống', ThemeMode.system, settings.themeMode),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, WidgetRef ref, String label, ThemeMode mode, ThemeMode current) {
    return ListTile(
      title: Text(label),
      leading: Icon(
        mode == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: mode == current ? AuraColors.primary : AuraColors.textTertiary,
      ),
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
        Navigator.pop(ctx);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi AURA Social?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: FirebaseAuth.instance.signOut() + navigate to login
            },
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
