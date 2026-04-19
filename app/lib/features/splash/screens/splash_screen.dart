import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Splash Screen
///
/// Màn hình chờ khi mở app, hiển thị logo với animation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (mounted) {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icon with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.primary.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AuraColors.secondary.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // Brand name
            ShaderMask(
              shaderCallback: (bounds) =>
                  AuraColors.primaryGradient.createShader(bounds),
              child: Text(
                'AURA',
                style: AuraTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  fontSize: 36,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Your Emotional Space',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  AuraColors.primary.withValues(alpha: 0.6),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
