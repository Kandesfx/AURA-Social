import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/shared/widgets/aura_state_builder.dart';

void main() {
  group('AuraAsyncValueRetry Extension', () {
    test('hasError returns true when AsyncValue has error', () {
      final errorState = AsyncValue<String>.error(
        Exception('Test error'),
        StackTrace.current,
      );
      expect(errorState.hasError, isTrue);
    });

    test('hasError returns false when AsyncValue is loading', () {
      const loadingState = AsyncValue<String>.loading();
      expect(loadingState.hasError, isFalse);
    });

    test('hasError returns false when AsyncValue has data', () {
      const dataState = AsyncValue<String>.data('test');
      expect(dataState.hasError, isFalse);
    });

    test('isLoading returns true only when loading', () {
      const loadingState = AsyncValue<String>.loading();
      const dataState = AsyncValue<String>.data('test');
      final errorState = AsyncValue<String>.error(
        Exception('e'),
        StackTrace.current,
      );

      expect(loadingState.isLoading, isTrue);
      expect(dataState.isLoading, isFalse);
      expect(errorState.isLoading, isFalse);
    });

    test('hasData returns true only when has data', () {
      const dataState = AsyncValue<String>.data('test');
      const loadingState = AsyncValue<String>.loading();
      final errorState = AsyncValue<String>.error(
        Exception('e'),
        StackTrace.current,
      );

      expect(dataState.hasData, isTrue);
      expect(loadingState.hasData, isFalse);
      expect(errorState.hasData, isFalse);
    });

    test('isEmpty returns true for empty list', () {
      const emptyListState = AsyncValue<List<String>>.data([]);
      expect(emptyListState.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty list', () {
      const nonEmptyListState = AsyncValue<List<String>>.data(['item']);
      expect(nonEmptyListState.isEmpty, isFalse);
    });

    test('isEmpty returns true for null data', () {
      const nullState = AsyncValue<String?>.data(null);
      expect(nullState.isEmpty, isTrue);
    });

    test('errorMessage returns error string', () {
      final errorState = AsyncValue<String>.error(
        'Test error message',
        StackTrace.current,
      );
      expect(errorState.errorMessage, equals('Test error message'));
    });

    test('errorMessage returns null for non-error state', () {
      const dataState = AsyncValue<String>.data('test');
      expect(dataState.errorMessage, isNull);
    });
  });

  group('AuraStateBuilder Widget', () {
    testWidgets('shows loading widget when state is loading', (tester) async {
      const loadingState = AsyncValue<String>.loading();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraStateBuilder<String>(
              state: loadingState,
              onLoading: () => const Text('Loading...'),
              onEmpty: () => const Text('Empty'),
              onError: (e, r) => Text('Error: $e'),
              onSuccess: (d) => Text('Data: $d'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows error widget when state has error', (tester) async {
      final errorState = AsyncValue<String>.error(
        'Test error',
        StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraStateBuilder<String>(
              state: errorState,
              onLoading: () => const Text('Loading...'),
              onEmpty: () => const Text('Empty'),
              onError: (e, r) => Text('Error: $e'),
              onSuccess: (d) => Text('Data: $d'),
            ),
          ),
        ),
      );

      expect(find.text('Error: Test error'), findsOneWidget);
    });

    testWidgets('shows success widget when state has data', (tester) async {
      const dataState = AsyncValue<String>.data('Hello World');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraStateBuilder<String>(
              state: dataState,
              onLoading: () => const Text('Loading...'),
              onEmpty: () => const Text('Empty'),
              onError: (e, r) => Text('Error: $e'),
              onSuccess: (d) => Text('Data: $d'),
            ),
          ),
        ),
      );

      expect(find.text('Data: Hello World'), findsOneWidget);
    });

    testWidgets('shows empty widget for null data', (tester) async {
      const nullState = AsyncValue<String?>.data(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraStateBuilder<String?>(
              state: nullState,
              onLoading: () => const Text('Loading...'),
              onEmpty: () => const Text('Empty'),
              onError: (e, r) => Text('Error: $e'),
              onSuccess: (d) => Text('Data: $d'),
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('shows empty widget for empty list', (tester) async {
      const emptyListState = AsyncValue<List<String>>.data([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraStateBuilder<List<String>>(
              state: emptyListState,
              onLoading: () => const Text('Loading...'),
              onEmpty: () => const Text('Empty List'),
              onError: (e, r) => Text('Error: $e'),
              onSuccess: (d) => Text('Items: ${d.length}'),
            ),
          ),
        ),
      );

      expect(find.text('Empty List'), findsOneWidget);
    });
  });
}
