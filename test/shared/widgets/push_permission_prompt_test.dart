import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/shared/widgets/push_permission_prompt.dart';

void main() {
  group('PushPermissionPrompt bottom sheet', () {
    testWidgets('renders title and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => PushPermissionPrompt.show(context),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify Korean title
      expect(
        find.text('아티스트의 새 메시지를 놓치지 마세요!'),
        findsOneWidget,
      );

      // Verify accept button
      expect(find.text('알림 허용하기'), findsOneWidget);

      // Verify dismiss text
      expect(find.text('나중에 할게요'), findsOneWidget);

      // Verify benefit items
      expect(find.text('새 메시지 알림'), findsOneWidget);
      expect(find.text('펀딩 알림'), findsOneWidget);
      expect(find.text('이벤트 & 혜택'), findsOneWidget);

      // Verify privacy note
      expect(
        find.text('알림 설정은 언제든지 앱 설정에서 변경할 수 있습니다'),
        findsOneWidget,
      );
    });

    testWidgets('dismiss returns false', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await PushPermissionPrompt.show(context);
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      // Show bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Tap "나중에 할게요" to dismiss
      await tester.tap(find.text('나중에 할게요'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
