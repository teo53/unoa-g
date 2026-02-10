import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/shared/widgets/error_boundary.dart';

void main() {
  group('ErrorDisplay', () {
    group('generateErrorCode', () {
      test('returns code in ERR-XXXX-NNN format', () {
        final code = ErrorDisplay.generateErrorCode();
        expect(code, startsWith('ERR-'));
        expect(code.split('-').length, equals(3));
      });

      test('generates unique codes on successive calls', () {
        final codes =
            List.generate(10, (_) => ErrorDisplay.generateErrorCode());
        // At least most should be unique (timestamp-based + random)
        final unique = codes.toSet();
        expect(unique.length, greaterThan(5));
      });
    });

    group('rendering', () {
      testWidgets('displays custom title and message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay(
                error: Exception('test'),
                title: '커스텀 에러',
                message: '에러 메시지입니다',
              ),
            ),
          ),
        );

        expect(find.text('커스텀 에러'), findsOneWidget);
        expect(find.text('에러 메시지입니다'), findsOneWidget);
      });

      testWidgets('shows retry button when onRetry provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay(
                error: Exception('test'),
                onRetry: () {},
              ),
            ),
          ),
        );

        expect(find.text('다시 시도'), findsOneWidget);
      });

      testWidgets('hides retry button when onRetry is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay(
                error: Exception('test'),
              ),
            ),
          ),
        );

        expect(find.text('다시 시도'), findsNothing);
      });

      testWidgets('displays error code', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay(
                error: Exception('test'),
                errorCode: 'ERR-TEST-001',
              ),
            ),
          ),
        );

        expect(find.textContaining('ERR-TEST-001'), findsOneWidget);
      });
    });

    group('factory presets', () {
      testWidgets('ErrorDisplay.network shows network title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay.network(),
            ),
          ),
        );

        expect(find.text('네트워크 오류'), findsOneWidget);
        expect(find.textContaining('인터넷'), findsOneWidget);
      });

      testWidgets('ErrorDisplay.notFound shows item name', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplay.notFound(itemName: '아티스트'),
            ),
          ),
        );

        expect(find.text('찾을 수 없음'), findsOneWidget);
        expect(find.textContaining('아티스트'), findsOneWidget);
      });
    });
  });

  group('EmptyState', () {
    group('rendering', () {
      testWidgets('displays title and message', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyState(
                title: '비어있음',
                message: '내용이 없습니다',
              ),
            ),
          ),
        );

        expect(find.text('비어있음'), findsOneWidget);
        expect(find.text('내용이 없습니다'), findsOneWidget);
      });

      testWidgets('shows action button when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyState(
                title: '비어있음',
                action: ElevatedButton(
                  onPressed: () {},
                  child: const Text('추가하기'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('추가하기'), findsOneWidget);
      });

      testWidgets('compact mode renders Row layout', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyState(
                title: '비어있음',
                compact: true,
              ),
            ),
          ),
        );

        expect(find.text('비어있음'), findsOneWidget);
        // In compact mode, it renders as a Row
        expect(find.byType(Row), findsWidgets);
      });
    });

    group('factory presets', () {
      testWidgets('noMessages shows correct content', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyState.noMessages(),
            ),
          ),
        );

        expect(find.text('아직 메시지가 없어요'), findsOneWidget);
      });

      testWidgets('noSearchResults includes query', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyState.noSearchResults('하늘달'),
            ),
          ),
        );

        expect(find.textContaining('하늘달'), findsOneWidget);
      });
    });
  });

  group('LoadingState', () {
    testWidgets('displays CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingState(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingState(message: '로딩 중...'),
          ),
        ),
      );

      expect(find.text('로딩 중...'), findsOneWidget);
    });

    testWidgets('compact mode renders inline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingState(
              message: '처리 중',
              compact: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('처리 중'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('Custom exceptions', () {
    test('NetworkException toString', () {
      expect(NetworkException().toString(), equals('Network error occurred'));
      expect(
        NetworkException('Custom').toString(),
        equals('Custom'),
      );
    });

    test('NotFoundException toString', () {
      expect(
        const NotFoundException().toString(),
        equals('Resource not found'),
      );
    });

    test('UnauthorizedException toString', () {
      expect(
        const UnauthorizedException().toString(),
        equals('Unauthorized access'),
      );
    });
  });
}
