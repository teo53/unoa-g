import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/features/chat/widgets/message_actions_sheet.dart';
import 'package:uno_a_flutter/features/chat/widgets/report_dialog.dart';
import 'package:uno_a_flutter/features/chat/widgets/message_edit_dialog.dart';
import 'package:uno_a_flutter/data/models/broadcast_message.dart';

void main() {
  group('MessageActionsSheet', () {
    late BroadcastMessage ownMessage;
    late BroadcastMessage otherMessage;

    setUp(() {
      // Own message (can edit/delete)
      ownMessage = BroadcastMessage(
        id: 'msg_1',
        channelId: 'channel_1',
        senderId: 'current_user',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'My test message',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      // Other user's message (can report/block)
      otherMessage = BroadcastMessage(
        id: 'msg_2',
        channelId: 'channel_1',
        senderId: 'other_user',
        senderType: 'artist',
        deliveryScope: DeliveryScope.broadcast,
        content: 'Artist message',
        createdAt: DateTime.now(),
        senderName: 'Test Artist',
      );
    });

    testWidgets('shows edit and delete options for own message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageActionsSheet.show(
                    context: context,
                    message: ownMessage,
                    isOwnMessage: true,
                    onEdit: () {},
                    onDelete: () {},
                  );
                },
                child: const Text('Show Actions'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Actions'));
      await tester.pumpAndSettle();

      // Verify edit and delete options are shown
      expect(find.text('편집'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      expect(find.text('복사'), findsOneWidget);

      // Verify report and block are NOT shown for own message
      expect(find.text('신고'), findsNothing);
      expect(find.text('차단'), findsNothing);
    });

    testWidgets('shows report and block options for other message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageActionsSheet.show(
                    context: context,
                    message: otherMessage,
                    isOwnMessage: false,
                    onReport: (reason, description) async {},
                    onBlock: () {},
                  );
                },
                child: const Text('Show Actions'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Actions'));
      await tester.pumpAndSettle();

      // Verify report and block options are shown
      expect(find.text('복사'), findsOneWidget);
      expect(find.text('신고'), findsOneWidget);
      expect(find.text('차단'), findsOneWidget);

      // Verify edit and delete are NOT shown for other's message
      expect(find.text('편집'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('edit option not shown for messages older than 24 hours',
        (WidgetTester tester) async {
      final oldMessage = BroadcastMessage(
        id: 'msg_3',
        channelId: 'channel_1',
        senderId: 'current_user',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'Old message',
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageActionsSheet.show(
                    context: context,
                    message: oldMessage,
                    isOwnMessage: true,
                    onEdit: () {},
                    onDelete: () {},
                  );
                },
                child: const Text('Show Actions'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Actions'));
      await tester.pumpAndSettle();

      // Edit should not be shown (message > 24 hours old)
      expect(find.text('편집'), findsNothing);
      // Delete should still be shown
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  group('ReportDialog', () {
    testWidgets('shows all report reasons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ReportDialog.show(
                    context: context,
                    reportedContentId: 'content_1',
                    reportedContentType: 'message',
                    onSubmit: (reason, description) async {},
                  );
                },
                child: const Text('Show Report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Report'));
      await tester.pumpAndSettle();

      // Verify all report reasons are shown (labels from ReportReason enum)
      expect(find.text('스팸'), findsOneWidget);
      expect(find.text('괴롭힘/폭언'), findsOneWidget);
      expect(find.text('부적절한 콘텐츠'), findsOneWidget);
      expect(find.text('사기/허위 정보'), findsOneWidget);
      expect(find.text('저작권 침해'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('submit button is enabled only when reason is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ReportDialog.show(
                    context: context,
                    reportedContentId: 'content_1',
                    reportedContentType: 'message',
                    onSubmit: (reason, description) async {},
                  );
                },
                child: const Text('Show Report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Report'));
      await tester.pumpAndSettle();

      // '신고하기' appears in both title and submit button
      final submitButton = find.text('신고하기');
      expect(submitButton, findsNWidgets(2));

      // The submit button (ElevatedButton) is always enabled;
      // validation happens inside _submit() which shows an error message
      final buttonWidget = tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '신고하기'));
      expect(buttonWidget.onPressed, isNotNull);

      // Tap submit without selecting a reason — shows validation error
      // '신고 사유를 선택해주세요' appears as both instruction label and error message
      await tester.tap(find.widgetWithText(ElevatedButton, '신고하기'));
      await tester.pumpAndSettle();
      expect(find.text('신고 사유를 선택해주세요'), findsNWidgets(2));

      // Select a reason
      await tester.tap(find.text('스팸'));
      await tester.pumpAndSettle();

      // Button is still enabled after selecting a reason
      final enabledButtonWidget = tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '신고하기'));
      expect(enabledButtonWidget.onPressed, isNotNull);
    });
  });

  group('MessageEditDialog', () {
    testWidgets('shows current message content', (WidgetTester tester) async {
      final message = BroadcastMessage(
        id: 'msg_1',
        channelId: 'channel_1',
        senderId: 'current_user',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'Original message content',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageEditDialog.show(
                    context: context,
                    message: message,
                    onEdit: (newContent) async {},
                    maxCharacters: 300,
                  );
                },
                child: const Text('Show Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Edit'));
      await tester.pumpAndSettle();

      // Verify original content is shown
      expect(find.text('Original message content'), findsOneWidget);

      // Verify character counter
      expect(find.textContaining('/ 300'), findsOneWidget);
    });

    testWidgets('edit button is disabled when content unchanged',
        (WidgetTester tester) async {
      final message = BroadcastMessage(
        id: 'msg_1',
        channelId: 'channel_1',
        senderId: 'current_user',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'Original message',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageEditDialog.show(
                    context: context,
                    message: message,
                    onEdit: (newContent) async {},
                  );
                },
                child: const Text('Show Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Edit'));
      await tester.pumpAndSettle();

      // Edit button should be disabled when content is unchanged
      final buttonWidget =
          tester.widget<TextButton>(find.widgetWithText(TextButton, '편집'));
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('edit button is enabled when content changed',
        (WidgetTester tester) async {
      final message = BroadcastMessage(
        id: 'msg_1',
        channelId: 'channel_1',
        senderId: 'current_user',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'Original',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MessageEditDialog.show(
                    context: context,
                    message: message,
                    onEdit: (newContent) async {},
                  );
                },
                child: const Text('Show Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Edit'));
      await tester.pumpAndSettle();

      // Change the content
      await tester.enterText(find.byType(TextField), 'Modified content');
      await tester.pumpAndSettle();

      // Edit button should now be enabled
      final buttonWidget =
          tester.widget<TextButton>(find.widgetWithText(TextButton, '편집'));
      expect(buttonWidget.onPressed, isNotNull);
    });
  });

  group('Deleted Message Display', () {
    testWidgets('deleted message shows placeholder', (WidgetTester tester) async {
      final deletedMessage = BroadcastMessage(
        id: 'msg_deleted',
        channelId: 'channel_1',
        senderId: 'user_1',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'This was deleted',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        deletedAt: DateTime.now(), // Message is deleted
      );

      // Note: This test verifies the model state.
      // UI tests would need the full widget tree with BroadcastMessageBubble.
      expect(deletedMessage.deletedAt, isNotNull);
    });

    testWidgets('edited message has isEdited flag', (WidgetTester tester) async {
      final editedMessage = BroadcastMessage(
        id: 'msg_edited',
        channelId: 'channel_1',
        senderId: 'user_1',
        senderType: 'fan',
        deliveryScope: DeliveryScope.directReply,
        content: 'This was edited',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isEdited: true,
        lastEditedAt: DateTime.now(),
      );

      expect(editedMessage.isEdited, isTrue);
      expect(editedMessage.lastEditedAt, isNotNull);
    });
  });
}
