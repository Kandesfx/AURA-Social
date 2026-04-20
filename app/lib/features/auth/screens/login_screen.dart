import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Login Screen
///
/// Màn hình đăng nhập: logo, tagline, username/password, Google login, và liên kết đăng ký.
/// Được hiển thị sau splash screen khi app khởi động.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ── Logo + Brand ──
              _buildLogo(),

              const SizedBox(height: 40),

              // ── Welcome Text ──
              _buildWelcomeText(),

              const SizedBox(height: 36),

              // ── Login Form ──
              _buildLoginForm(),

              const SizedBox(height: 24),

              // ── Divider "or" ──
              _buildDivider(),

              const SizedBox(height: 24),

              // ── Google Login Button ──
              _buildGoogleButton(),

              const SizedBox(height: 32),

              // ── Register Link ──
              _buildRegisterLink(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo icon with glow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AuraColors.primary.withValues(alpha: 0.25),
                blurRadius: 50,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AuraColors.secondary.withValues(alpha: 0.1),
                blurRadius: 80,
                spreadRadius: 15,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/logo_icon.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 20),

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
              fontSize: 32,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Your Emotional Space',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textTertiary,
            letterSpacing: 1.5,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Chào mừng trở lại',
          style: AuraTypography.headlineMedium.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideX(begin: -0.1, duration: 400.ms),

        const SizedBox(height: 8),

        Text(
          'Đăng nhập để tiếp tục kết nối cảm xúc của bạn',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideX(begin: 0.1, duration: 400.ms),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email / Username field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Email hoặc username',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AuraColors.textTertiary,
              size: 20,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Mật khẩu',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AuraColors.textTertiary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AuraColors.textTertiary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 12),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Navigate to forgot password
            },
            child: Text(
              'Quên mật khẩu?',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.primary,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 550.ms, duration: 300.ms),

        const SizedBox(height: 8),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Handle login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Đăng nhập',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 400.ms)
            .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AuraColors.surfaceBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuraColors.surfaceBorder,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 300.ms);
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AuraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            // TODO: Handle Google login
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: AuraColors.primary.withValues(alpha: 0.1),
          highlightColor: AuraColors.primary.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AuraColors.surfaceBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" logo – official SVG from Google branding assets
                SvgPicture.asset(
                  'assets/images/google_g_icon.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  'Đăng nhập với Google',
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 400.ms)
        .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản?',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push('/register');
          },
          child: Text(
            ' Đăng ký',
            style: AuraTypography.labelLarge.copyWith(
              color: AuraColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 900.ms, duration: 300.ms);
  }
}
