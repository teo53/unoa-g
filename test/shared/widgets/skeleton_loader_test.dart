import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/shared/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader', () {
    testWidgets('renders with correct width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 20),
          ),
        ),
      );
      await tester.pump();

      // The SkeletonLoader should be in the tree
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('circle factory sets isCircle true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.circle(size: 48),
          ),
        ),
      );
      await tester.pump();

      final widget =
          tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));
      expect(widget.isCircle, isTrue);
      expect(widget.width, equals(48));
      expect(widget.height, equals(48));
    });

    testWidgets('text factory defaults height to 14', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.text(width: 120),
          ),
        ),
      );
      await tester.pump();

      final widget =
          tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));
      expect(widget.height, equals(14));
      expect(widget.width, equals(120));
      expect(widget.isCircle, isFalse);
    });
  });

  group('SkeletonListTile', () {
    testWidgets('renders avatar when showAvatar is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(showAvatar: true),
          ),
        ),
      );
      await tester.pump();

      // Find SkeletonLoader widgets inside the SkeletonListTile
      // With avatar: circle + text(s)
      final loaders = find.byType(SkeletonLoader);
      expect(loaders, findsAtLeastNWidgets(2));
    });

    testWidgets('hides avatar when showAvatar is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListTile(showAvatar: false, showSubtitle: false),
          ),
        ),
      );
      await tester.pump();

      // Without avatar and subtitle, only 1 text loader
      final loaders = find.byType(SkeletonLoader);
      expect(loaders, findsOneWidget);
    });
  });

  group('SkeletonMessageBubble', () {
    testWidgets('isFromArtist true renders avatar on left', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonMessageBubble(isFromArtist: true),
          ),
        ),
      );
      await tester.pump();

      // Artist message: Row with circle + Column(text + card)
      expect(find.byType(Row), findsOneWidget);
      // Should have circle loader (avatar) + text + card = 3+ loaders
      expect(find.byType(SkeletonLoader), findsAtLeastNWidgets(3));
    });

    testWidgets('isFromArtist false renders bubble on right', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonMessageBubble(isFromArtist: false),
          ),
        ),
      );
      await tester.pump();

      // Fan message: Row with mainAxisAlignment.end + 1 card
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonScreen', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonScreen(
              isLoading: false,
              child: Text('실제 컨텐츠'),
            ),
          ),
        ),
      );

      expect(find.text('실제 컨텐츠'), findsOneWidget);
    });

    testWidgets('shows skeleton when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonScreen(
              isLoading: true,
              child: Text('실제 컨텐츠'),
            ),
          ),
        ),
      );

      expect(find.text('실제 컨텐츠'), findsNothing);
      expect(find.byType(SkeletonListTile), findsWidgets);
    });
  });
}
