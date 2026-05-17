import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/screens/login_screen.dart';
import 'package:app/features/auth/screens/register_screen.dart';

/// AURA Social – Integration Tests cho Auth Flow
///
/// Person 4, Task #22
/// Test luồng authentication: Login → Register → form validation.
///
/// Lưu ý: Đây là widget-level integration tests (không cần Firebase emulator).
/// Full integration tests (với Firebase) cần setup riêng trong `integration_test/`.
void main() {
  group('Auth Flow – Login Screen', () {
    testWidgets('renders all essential elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Brand elements
      expect(find.text('AURA'), findsOneWidget);
      expect(find.text('Your Emotional Space'), findsOneWidget);

      // Welcome text
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
      expect(find.textContaining('Đăng nhập để tiếp tục'), findsOneWidget);

      // Form fields
      expect(find.widgetWithText(TextField, 'Email hoặc username'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mật khẩu'), findsOneWidget);

      // Buttons
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.textContaining('Google'), findsOneWidget);

      // Register link
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);
      expect(find.textContaining('Đăng ký'), findsOneWidget);
    });

    testWidgets('email field accepts input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter email
      final emailField = find.widgetWithText(TextField, 'Email hoặc username');
      await tester.enterText(emailField, 'test@aura.social');
      await tester.pump();

      expect(find.text('test@aura.social'), findsOneWidget);
    });

    testWidgets('password field accepts input and toggles visibility', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

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
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextField, 'Email hoặc username'),
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

      // Button should work without error
      // (actual Firebase auth would be tested in full integration test)
    });

    testWidgets('divider shows "hoặc" text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('hoặc'), findsOneWidget);
    });
  });

  group('Auth Flow – Register Screen', () {
    testWidgets('renders all essential elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.textContaining('AURA'), findsWidgets);

      // Register-specific text
      expect(find.textContaining('Tạo tài khoản'), findsOneWidget);
    });

    testWidgets('has form fields for registration', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have at least email and password fields
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('has link back to login', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have "Đã có tài khoản?" or similar login link
      expect(find.textContaining('tài khoản'), findsWidgets);
    });
  });

  group('Auth Flow – Form Validation UX', () {
    testWidgets('empty form should not crash on submit', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap login without filling form
      final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      await tester.tap(loginButton);
      await tester.pump();

      // Should not crash – graceful handling
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('keyboard type is correct for email field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email hoặc username'),
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);
    });
  });
}
