import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_state_provider.dart';

/// AURA Social – Login Screen (Connected to Firebase Auth)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    // Router tự redirect tới /feed khi Firebase Auth state thay đổi
    await ref.read(authNotifierProvider.notifier)
        .signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AuraColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 60),
              _logo(),
              const SizedBox(height: 40),
              _welcome(),
              const SizedBox(height: 36),
              _form(auth),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 24),
              _googleBtn(auth),
              const SizedBox(height: 32),
              _registerLink(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _logo() => Column(children: [
    Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: AuraColors.primary.withValues(alpha: .25), blurRadius: 50, spreadRadius: 8),
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset('assets/images/logo_icon.png', width: 80, height: 80, fit: BoxFit.cover),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(.7,.7), duration: 600.ms, curve: Curves.easeOutBack),
    const SizedBox(height: 20),
    ShaderMask(
      shaderCallback: (b) => AuraColors.primaryGradient.createShader(b),
      child: Text('AURA', style: AuraTypography.displayLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 6, fontSize: 32)),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
    const SizedBox(height: 8),
    Text('Your Emotional Space', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary, letterSpacing: 1.5))
        .animate().fadeIn(delay: 400.ms),
  ]);

  Widget _welcome() => Column(children: [
    Text('Chào mừng trở lại', style: AuraTypography.headlineMedium.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w700))
        .animate().fadeIn(delay: 300.ms).slideX(begin: -.1),
    const SizedBox(height: 8),
    Text('Đăng nhập để tiếp tục kết nối cảm xúc của bạn', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary), textAlign: TextAlign.center)
        .animate().fadeIn(delay: 400.ms),
  ]);

  Widget _form(AuthState auth) => Column(children: [
    TextFormField(
      controller: _emailCtrl, keyboardType: TextInputType.emailAddress, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AuraColors.textTertiary, size: 20)),
      validator: (v) => v == null || !v.contains('@') ? 'Email không hợp lệ' : null,
    ).animate().fadeIn(delay: 400.ms).slideY(begin: .15),
    const SizedBox(height: 16),
    TextFormField(
      controller: _passwordCtrl, obscureText: _obscure, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Mật khẩu',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: AuraColors.textTertiary, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AuraColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
      onFieldSubmitted: (_) => _login(),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: .15),
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _login,
        style: ElevatedButton.styleFrom(backgroundColor: AuraColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: auth.isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Text('Đăng nhập', style: AuraTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: .2),
  ]);

  Widget _divider() => Row(children: [
    Expanded(child: Container(height: 1, color: AuraColors.surfaceBorder)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('hoặc', style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary))),
    Expanded(child: Container(height: 1, color: AuraColors.surfaceBorder)),
  ]).animate().fadeIn(delay: 700.ms);

  Widget _googleBtn(AuthState auth) => SizedBox(
    width: double.infinity, height: 52,
    child: OutlinedButton.icon(
      onPressed: auth.isLoading ? null : () async {
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
        // Router tự redirect khi Firebase Auth state thay đổi
      },
      icon: SvgPicture.asset('assets/images/google_g_icon.svg', width: 22, height: 22),
      label: Text('Tiếp tục với Google', style: AuraTypography.labelLarge.copyWith(color: AuraColors.textPrimary)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AuraColors.surfaceBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  ).animate().fadeIn(delay: 800.ms);

  Widget _registerLink() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text('Chưa có tài khoản?', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary)),
    TextButton(onPressed: () => context.push('/register'), child: Text(' Đăng ký', style: AuraTypography.labelLarge.copyWith(color: AuraColors.primary, fontWeight: FontWeight.w600))),
  ]).animate().fadeIn(delay: 900.ms);
}
