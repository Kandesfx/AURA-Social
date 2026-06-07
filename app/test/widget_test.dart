import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/app.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/providers/auth_state_provider.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('AURA')),
          ),
        ),
      ],
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const AuraApp(),
      ),
    );

    // Verify app renders
    expect(find.text('AURA'), findsOneWidget);
  });
}
