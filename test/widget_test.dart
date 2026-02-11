import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/shared/widgets/error_boundary.dart';

void main() {
  group('ErrorDisplay', () {
    testWidgets('renders default error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(error: Exception('Test error')),
          ),
        ),
      );

      // Default title
      expect(find.text('문제가 발생했습니다'), findsOneWidget);

      // Error icon
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided',
        (WidgetTester tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: Exception('Test error'),
              onRetry: () => retryCount++,
            ),
          ),
        ),
      );

      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      expect(retryCount, equals(1));
    });

    testWidgets('renders custom title and message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: Exception('Test'),
              title: '서버 오류',
              message: '잠시 후 다시 시도해주세요.',
            ),
          ),
        ),
      );

      expect(find.text('서버 오류'), findsOneWidget);
      expect(find.text('잠시 후 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('generates error code in ERR-xxx format',
        (WidgetTester tester) async {
      final code = ErrorDisplay.generateErrorCode();
      expect(code, startsWith('ERR-'));
      expect(code.split('-').length, equals(3));
    });
  });

  group('EmptyState', () {
    testWidgets('renders title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: '아직 메시지가 없어요',
              message: '첫 메시지를 보내보세요',
            ),
          ),
        ),
      );

      expect(find.text('아직 메시지가 없어요'), findsOneWidget);
      expect(find.text('첫 메시지를 보내보세요'), findsOneWidget);
    });

    testWidgets('noMessages factory renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noMessages(),
          ),
        ),
      );

      expect(find.text('아직 메시지가 없어요'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });
}
