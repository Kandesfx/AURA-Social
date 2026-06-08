import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/screens/login_screen.dart';
import 'package:app/features/auth/screens/register_screen.dart';
import 'package:app/providers/auth_state_provider.dart';

/// Mock Auth Notifier implementing AuthNotifier interface to bypass Firebase Auth
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState());

  @override
  Future<bool> signInWithEmail(String email, String password) async {
    return true;
  }

  @override
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    return true;
  }

  @override
  Future<bool> signInWithGoogle() async {
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> resetPassword(String email) async {
    return true;
  }

  @override
  Future<bool> deleteAccount() async {
    return true;
  }

  @override
  void clearError() {}
}

Widget buildTestWidget(Widget home) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
      authStateProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: MaterialApp(
      home: home,
    ),
  );
}

void main() {
  group('Auth Flow – Login Screen', () {
    testWidgets('renders all essential elements', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Brand elements
      expect(find.text('AURA'), findsOneWidget);
      expect(find.text('Your Emotional Space'), findsOneWidget);

      // Welcome text
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
      expect(find.textContaining('Đăng nhập để tiếp tục'), findsOneWidget);

      // Form fields
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mật khẩu'), findsOneWidget);

      // Buttons
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.textContaining('Google'), findsOneWidget);

      // Register link
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);
      expect(find.textContaining('Đăng ký'), findsOneWidget);
    });

    testWidgets('email field accepts input', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter email
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.enterText(emailField, 'test@aura.social');
      await tester.pump();

      expect(find.text('test@aura.social'), findsOneWidget);
    });

    testWidgets('password field accepts input and toggles visibility', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.widgetWithText(TextField, 'Mật khẩu');
      await tester.enterText(passwordField, 'securePassword123');
      await tester.pump();

      // Password should be obscured initially
      final textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isTrue);

      // Tap visibility toggle
      final toggleButton = find.descendant(
        of: find.byType(TextField).last,
        matching: find.byType(IconButton),
      );
      await tester.tap(toggleButton);
      await tester.pump();

      // Password should now be visible
      final updatedField = tester.widget<TextField>(passwordField);
      expect(updatedField.obscureText, isFalse);
    });

    testWidgets('login button is tappable', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'user@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'),
        'password123',
      );
      await tester.pump();

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pump();
    });

    testWidgets('divider shows "hoặc" text', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();
      expect(find.text('hoặc'), findsOneWidget);
    });
  });

  group('Auth Flow – Register Screen', () {
    testWidgets('renders all essential elements', (tester) async {
      await tester.pumpWidget(buildTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Header
      expect(find.textContaining('AURA'), findsWidgets);

      // Register-specific text
      expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    });

    testWidgets('has form fields for registration', (tester) async {
      await tester.pumpWidget(buildTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Should have at least email and password fields
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('has link back to login', (tester) async {
      await tester.pumpWidget(buildTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Should have "Đã có tài khoản?" or similar login link
      expect(find.textContaining('tài khoản'), findsWidgets);
    });
  });

  group('Auth Flow – Form Validation UX', () {
    testWidgets('empty form should not crash on submit', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Tap login without filling form
      final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      await tester.tap(loginButton);
      await tester.pump();

      // Should not crash – graceful handling
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('keyboard type is correct for email field', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);
    });
  });
}
