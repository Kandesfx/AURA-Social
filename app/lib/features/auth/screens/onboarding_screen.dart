import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Onboarding Screen
///
/// Hiển thị 1 lần khi lần đầu mở app. Giới thiệu 4 tính năng chính:
/// 1. Aura Ring – hiển thị cảm xúc qua màu sắc
/// 2. For You Feed – AI cá nhân hóa nội dung
/// 3. Soul Connect – kết nối tâm hồn đồng điệu
/// 4. Privacy – AI minh bạch, người dùng kiểm soát
///
/// Sau khi xem xong → navigate tới Login.
/// Flag `onboarding_seen` lưu trong SharedPreferences.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Key trong SharedPreferences đánh dấu đã xem onboarding
  static const seenKey = 'onboarding_seen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      emoji: '🔮',
      title: 'Aura Ring',
      subtitle: 'Vòng hào quang cảm xúc',
      description:
          'Mỗi người có một Aura Ring riêng – phản ánh trạng thái cảm xúc '
          'thông qua dải màu gradient. Cảm xúc của bạn, thể hiện qua màu sắc.',
      gradient: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    ),
    _OnboardingPage(
      icon: Icons.explore_rounded,
      emoji: '🧠',
      title: 'Feed Thông Minh',
      subtitle: 'AI hiểu bạn, không cần nói',
      description:
          'AURA đọc hành vi của bạn (không phải suy nghĩ!) để hiểu cảm xúc. '
          'Feed For You được cá nhân hóa theo tâm trạng, không chỉ sở thích.',
      gradient: [Color(0xFF06B6D4), Color(0xFF22C55E)],
    ),
    _OnboardingPage(
      icon: Icons.favorite_rounded,
      emoji: '💜',
      title: 'Soul Connect',
      subtitle: 'Kết nối sâu, không chỉ bề mặt',
      description:
          'AI phân tích mẫu cảm xúc để tìm những người thực sự đồng điệu. '
          'Không phải match bề ngoài – mà match từ bên trong.',
      gradient: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      emoji: '🛡️',
      title: 'Quyền Riêng Tư',
      subtitle: 'Bạn luôn kiểm soát',
      description:
          'Mọi tính năng AI đều có thể tắt/bật. Dữ liệu cảm xúc chỉ thuộc về bạn. '
          'AURA luôn hiển thị khi AI đang hoạt động.',
      gradient: [Color(0xFF22C55E), Color(0xFF06B6D4)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.seenKey, true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Bỏ qua',
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? AuraColors.primary
                              : AuraColors.surfaceBorder,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next/Done button
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AuraColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Bắt đầu'
                            : 'Tiếp theo',
                        style: AuraTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một trang trong onboarding
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient icon circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradient.map((c) => c.withValues(alpha: 0.15)).toList(),
              ),
              border: Border.all(
                color: gradient.first.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 40),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradient,
            ).createShader(bounds),
            child: Text(
              title,
              style: AuraTypography.displayLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: AuraTypography.titleMedium.copyWith(
              color: AuraColors.textSecondary,
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Description
          Text(
            description,
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.textTertiary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.1, duration: 400.ms),
        ],
      ),
    );
  }
}
