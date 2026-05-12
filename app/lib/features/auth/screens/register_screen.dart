import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Register Screen
///
/// Màn hình đăng ký: logo, tagline, username/email/password/confirm-password, và liên kết đăng nhập.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              const SizedBox(height: 48),

              // ── Logo + Brand ──
              _buildLogo(),

              const SizedBox(height: 36),

              // ── Welcome Text ──
              _buildWelcomeText(),

              const SizedBox(height: 32),

              // ── Register Form ──
              _buildRegisterForm(),

              const SizedBox(height: 24),

              // ── Register Button ──
              _buildRegisterButton(),

              const SizedBox(height: 32),

              // ── Login Link ──
              _buildLoginLink(),

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
          'Tạo tài khoản mới',
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
          'Đăng ký để bắt đầu hành trình cảm xúc của bạn',
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

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Username field
        TextField(
          controller: _usernameController,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Tên người dùng',
            prefixIcon: Icon(
              Icons.alternate_email_outlined,
              color: AuraColors.textTertiary,
              size: 20,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AuraColors.textTertiary,
              size: 20,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
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
            .fadeIn(delay: 600.ms, duration: 400.ms)
            .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Confirm Password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: AuraTypography.bodyLarge.copyWith(
            color: AuraColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Xác nhận mật khẩu',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AuraColors.textTertiary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AuraColors.textTertiary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 700.ms, duration: 400.ms)
            .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Terms & Privacy note
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AuraColors.textTertiary,
              ),
            ),
            Expanded(
              child: Text(
                'Bằng việc đăng ký, bạn đồng ý với',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.textTertiary,
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 750.ms, duration: 300.ms),
        const SizedBox(height: 2),
        Row(
          children: [
            const SizedBox(width: 22),
            Text(
              'Điều khoản dịch vụ',
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' và ',
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
            Text(
              'Chính sách bảo mật',
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' của AURA',
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 800.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Handle register
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
              'Tạo tài khoản',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 850.ms, duration: 400.ms)
            .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Divider "or"
        _buildDivider(),
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
    ).animate().fadeIn(delay: 900.ms, duration: 300.ms);
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản?',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(
            ' Đăng nhập',
            style: AuraTypography.labelLarge.copyWith(
              color: AuraColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 950.ms, duration: 300.ms);
  }
}
