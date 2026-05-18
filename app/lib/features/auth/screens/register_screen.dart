import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_state_provider.dart';

/// AURA Social – Register Screen (Connected to Firebase Auth)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure1 = true, _obscure2 = true;
  bool _agreedTerms = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đồng ý với Điều khoản dịch vụ'),
        backgroundColor: AuraColors.warning,
      ));
      return;
    }

    // Router tự redirect tới /feed khi Firebase Auth state thay đổi
    await ref.read(authNotifierProvider.notifier).registerWithEmail(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _usernameCtrl.text,
      username: _usernameCtrl.text.toLowerCase().replaceAll(' ', '_'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!), backgroundColor: AuraColors.error, behavior: SnackBarBehavior.floating,
        ));
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(key: _formKey, child: Column(children: [
            const SizedBox(height: 48),
            _logo(),
            const SizedBox(height: 36),
            _welcome(),
            const SizedBox(height: 32),
            _form(auth),
            const SizedBox(height: 16),
            _termsCheckbox(),
            const SizedBox(height: 24),
            _registerBtn(auth),
            const SizedBox(height: 32),
            _loginLink(),
            const SizedBox(height: 32),
          ])),
        ),
      ),
    );
  }

  Widget _logo() => Column(children: [
    Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: AuraColors.primary.withValues(alpha: .25), blurRadius: 50, spreadRadius: 8),
      ]),
      child: ClipRRect(borderRadius: BorderRadius.circular(24),
        child: Image.asset('assets/images/logo_icon.png', width: 80, height: 80, fit: BoxFit.cover)),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(.7,.7), duration: 600.ms, curve: Curves.easeOutBack),
    const SizedBox(height: 20),
    ShaderMask(
      shaderCallback: (b) => AuraColors.primaryGradient.createShader(b),
      child: Text('AURA', style: AuraTypography.displayLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 6, fontSize: 32)),
    ).animate().fadeIn(delay: 200.ms),
  ]);

  Widget _welcome() => Column(children: [
    Text('Tạo tài khoản mới', style: AuraTypography.headlineMedium.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w700))
        .animate().fadeIn(delay: 300.ms),
    const SizedBox(height: 8),
    Text('Đăng ký để bắt đầu hành trình cảm xúc', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary), textAlign: TextAlign.center)
        .animate().fadeIn(delay: 400.ms),
  ]);

  Widget _form(AuthState auth) => Column(children: [
    TextFormField(
      controller: _usernameCtrl, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(hintText: 'Tên hiển thị', prefixIcon: Icon(Icons.person_outline, color: AuraColors.textTertiary, size: 20)),
      validator: (v) => v == null || v.trim().length < 2 ? 'Tên tối thiểu 2 ký tự' : null,
    ).animate().fadeIn(delay: 400.ms),
    const SizedBox(height: 16),
    TextFormField(
      controller: _emailCtrl, keyboardType: TextInputType.emailAddress, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AuraColors.textTertiary, size: 20)),
      validator: (v) => v == null || !v.contains('@') ? 'Email không hợp lệ' : null,
    ).animate().fadeIn(delay: 500.ms),
    const SizedBox(height: 16),
    TextFormField(
      controller: _passwordCtrl, obscureText: _obscure1, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(hintText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline, color: AuraColors.textTertiary, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AuraColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure1 = !_obscure1))),
      validator: (v) => v == null || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
    ).animate().fadeIn(delay: 600.ms),
    const SizedBox(height: 16),
    TextFormField(
      controller: _confirmCtrl, obscureText: _obscure2, enabled: !auth.isLoading,
      style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      decoration: InputDecoration(hintText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock_outline, color: AuraColors.textTertiary, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AuraColors.textTertiary, size: 20), onPressed: () => setState(() => _obscure2 = !_obscure2))),
      validator: (v) => v != _passwordCtrl.text ? 'Mật khẩu không khớp' : null,
    ).animate().fadeIn(delay: 700.ms),
  ]);

  Widget _termsCheckbox() => Row(children: [
    SizedBox(
      width: 24, height: 24,
      child: Checkbox(
        value: _agreedTerms,
        onChanged: (v) => setState(() => _agreedTerms = v ?? false),
        activeColor: AuraColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: AuraColors.textTertiary),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text.rich(TextSpan(children: [
      TextSpan(text: 'Tôi đồng ý với ', style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary)),
      TextSpan(text: 'Điều khoản', style: AuraTypography.bodySmall.copyWith(color: AuraColors.primary, fontWeight: FontWeight.w500)),
      TextSpan(text: ' và ', style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary)),
      TextSpan(text: 'Chính sách bảo mật', style: AuraTypography.bodySmall.copyWith(color: AuraColors.primary, fontWeight: FontWeight.w500)),
    ]))),
  ]).animate().fadeIn(delay: 750.ms);

  Widget _registerBtn(AuthState auth) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: auth.isLoading ? null : _register,
      style: ElevatedButton.styleFrom(backgroundColor: AuraColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: auth.isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text('Tạo tài khoản', style: AuraTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    ),
  ).animate().fadeIn(delay: 850.ms);

  Widget _loginLink() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text('Đã có tài khoản?', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary)),
    TextButton(onPressed: () => context.pop(), child: Text(' Đăng nhập', style: AuraTypography.labelLarge.copyWith(color: AuraColors.primary, fontWeight: FontWeight.w600))),
  ]).animate().fadeIn(delay: 950.ms);
}
