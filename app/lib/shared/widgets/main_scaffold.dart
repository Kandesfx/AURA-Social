import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// AURA Social – Main Scaffold with Bottom Navigation
///
/// ShellRoute wrapper chứa bottom navigation bar cho 4 tabs chính.
/// Tab "Create Post" mở fullscreen → không nằm trong shell.
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/soul')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AuraColors.surface,
          border: Border(
            top: BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Feed',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/feed'),
                ),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Soul',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/soul'),
                ),

                // ── Create Post FAB ──
                GestureDetector(
                  onTap: () => context.push('/create-post'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AuraColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AuraColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/chat'),
                  badgeCount: 3, // TODO: từ provider
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Me',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item đơn lẻ trong bottom nav
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AuraColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? AuraColors.primary
                        : AuraColors.textTertiary,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AuraColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AuraColors.primary
                    : AuraColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
