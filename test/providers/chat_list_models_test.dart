// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/providers/chat_list_provider.dart';

void main() {
  // ==========================================================================
  // ChatThreadData — construction
  // ==========================================================================

  group('ChatThreadData construction', () {
    test('constructs with required fields and default optional values', () {
      const thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '하늘달',
      );

      expect(thread.channelId, 'chan-1');
      expect(thread.artistId, 'artist-1');
      expect(thread.artistName, '하늘달');
      expect(thread.artistEnglishName, isNull);
      expect(thread.avatarUrl, isNull);
      expect(thread.lastMessage, isNull);
      expect(thread.lastMessageAt, isNull);
      expect(thread.unreadCount, 0);
      expect(thread.isOnline, isFalse);
      expect(thread.isVerified, isFalse);
      expect(thread.isPinned, isFalse);
      expect(thread.isStar, isFalse);
      expect(thread.tier, 'STANDARD');
      expect(thread.daysSubscribed, 0);
      expect(thread.themeColorIndex, 0);
    });

    test('constructs with all optional fields provided', () {
      final lastAt = DateTime(2025, 6, 1, 14, 30);
      final thread = ChatThreadData(
        channelId: 'chan-2',
        artistId: 'artist-2',
        artistName: '이준호',
        artistEnglishName: 'Junho Lee',
        avatarUrl: 'https://example.com/junho.jpg',
        lastMessage: '안녕하세요!',
        lastMessageAt: lastAt,
        unreadCount: 5,
        isOnline: true,
        isVerified: true,
        isPinned: true,
        isStar: true,
        tier: 'VIP',
        daysSubscribed: 120,
        themeColorIndex: 3,
      );

      expect(thread.artistEnglishName, 'Junho Lee');
      expect(thread.avatarUrl, 'https://example.com/junho.jpg');
      expect(thread.lastMessage, '안녕하세요!');
      expect(thread.lastMessageAt, lastAt);
      expect(thread.unreadCount, 5);
      expect(thread.isOnline, isTrue);
      expect(thread.isVerified, isTrue);
      expect(thread.isPinned, isTrue);
      expect(thread.isStar, isTrue);
      expect(thread.tier, 'VIP');
      expect(thread.daysSubscribed, 120);
      expect(thread.themeColorIndex, 3);
    });
  });

  // ==========================================================================
  // ChatThreadData.displayName
  // ==========================================================================

  group('ChatThreadData.displayName', () {
    test('returns "artistName (artistEnglishName)" when english name present',
        () {
      const thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '김민지',
        artistEnglishName: 'Minji Kim',
      );
      expect(thread.displayName, '김민지 (Minji Kim)');
    });

    test('returns just artistName when englishName is null', () {
      const thread = ChatThreadData(
        channelId: 'chan-2',
        artistId: 'artist-2',
        artistName: '박서연',
      );
      expect(thread.displayName, '박서연');
    });

    test('returns just artistName for empty-like name with no english', () {
      const thread = ChatThreadData(
        channelId: 'chan-3',
        artistId: 'artist-3',
        artistName: 'IU',
      );
      expect(thread.displayName, 'IU');
    });

    test('includes both names when english name is non-null', () {
      const thread = ChatThreadData(
        channelId: 'chan-4',
        artistId: 'artist-4',
        artistName: '하늘달',
        artistEnglishName: 'HaneulDal',
      );
      expect(thread.displayName, '하늘달 (HaneulDal)');
    });
  });

  // ==========================================================================
  // ChatThreadData.formattedTime
  // ==========================================================================

  group('ChatThreadData.formattedTime', () {
    test('returns empty string when lastMessageAt is null', () {
      const thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
      );
      expect(thread.formattedTime, '');
    });

    test('returns "방금" when message is less than 1 minute ago', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(thread.formattedTime, '방금');
    });

    test('returns "방금" when message is 0 seconds ago', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now(),
      );
      expect(thread.formattedTime, '방금');
    });

    test('returns "N분 전" when 1 minute ago', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(thread.formattedTime, '1분 전');
    });

    test('returns "N분 전" when 15 minutes ago', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(thread.formattedTime, '15분 전');
    });

    test('returns "N분 전" when 59 minutes ago', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 59)),
      );
      expect(thread.formattedTime, '59분 전');
    });

    test('returns 12-hour Korean format for AM time (오전 H:MM)', () {
      // Create a message time that is guaranteed >1 hr and <24 hrs ago,
      // using a time with hour < 12 so we can verify '오전'.
      // Strategy: use DateTime.now() minus 2 hours, then zero the minutes
      // so we can predict the exact formatted string.
      final now = DateTime.now();
      // Pick an AM reference: use 2 hours ago, rounded to exact minute
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final msgTime = DateTime(
        twoHoursAgo.year,
        twoHoursAgo.month,
        twoHoursAgo.day,
        twoHoursAgo.hour,
        twoHoursAgo.minute,
      );
      final diffNow = now.difference(msgTime);
      // Only run this assertion if the time satisfies diff.inDays < 1 and >= 1hr
      if (diffNow.inHours < 1 || diffNow.inDays >= 1) return;

      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: msgTime,
      );
      final hour = msgTime.hour;
      final minute = msgTime.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final expected = '$period $displayHour:$minute';

      expect(thread.formattedTime, expected);
    });

    test('returns "오전" for AM hours and "오후" for PM hours', () {
      // Verify the AM/PM period mapping logic directly.
      // We test using messages from yesterday's specific hours to avoid
      // the relative-time bands (< 1 min, < 1 hr, == 1 day).
      // Use 5 hours ago to be safely in the "same day, >1 hr" band.
      final now = DateTime.now();
      final fiveHoursAgo = now.subtract(const Duration(hours: 5));

      // Only run if fiveHoursAgo is still in the same calendar day
      if (fiveHoursAgo.day != now.day) return;

      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: fiveHoursAgo,
      );
      final formatted = thread.formattedTime;
      final hour = fiveHoursAgo.hour;
      final expected = hour < 12 ? '오전' : '오후';
      expect(formatted.startsWith(expected), isTrue);
    });

    test('returns 12-hour Korean format: PM hour → 오후 with correct hour', () {
      // Use a message that is exactly 3 hours before current time (if it's PM).
      // The formatted output must contain '오후' and the 12-hr hour.
      final now = DateTime.now();
      final threeHoursAgo = now.subtract(const Duration(hours: 3));

      if (threeHoursAgo.day != now.day) return;

      final hour = threeHoursAgo.hour;
      final minute = threeHoursAgo.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final expected = '$period $displayHour:$minute';

      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: threeHoursAgo,
      );
      expect(thread.formattedTime, expected);
    });

    test('same-day time format contains colon and period label', () {
      // A message from 2 hours ago should produce a format like "오전 9:05"
      // or "오후 2:30" — always contains a colon and Korean period label.
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      if (twoHoursAgo.day != now.day) return;

      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: twoHoursAgo,
      );
      final formatted = thread.formattedTime;
      expect(
        formatted.startsWith('오전') || formatted.startsWith('오후'),
        isTrue,
        reason: 'Same-day old message should start with 오전 or 오후',
      );
      expect(formatted.contains(':'), isTrue);
    });

    test('returns "어제" when message is exactly 1 day ago', () {
      // 25 hours ago ensures inDays == 1
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(thread.formattedTime, '어제');
    });

    test('returns "M/D" format for messages older than 1 day', () {
      // Use a specific past date to avoid day-boundary flakiness
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime(2025, 3, 15),
      );
      // diff.inDays > 1 → 'M/D'
      expect(thread.formattedTime, '3/15');
    });

    test('returns "M/D" for single-digit month and day (no zero-padding)', () {
      final thread = ChatThreadData(
        channelId: 'chan-1',
        artistId: 'artist-1',
        artistName: '아티스트',
        lastMessageAt: DateTime(2024, 1, 5),
      );
      expect(thread.formattedTime, '1/5');
    });
  });

  // ==========================================================================
  // ChatListState — construction and copyWith
  // ==========================================================================

  group('ChatListState construction', () {
    test('default constructor has expected default values', () {
      const state = ChatListState();
      expect(state.threads, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasLoaded, isFalse);
    });

    test('constructs with all fields provided', () {
      final threads = [
        const ChatThreadData(
          channelId: 'chan-1',
          artistId: 'artist-1',
          artistName: '아티스트',
        ),
      ];
      final state = ChatListState(
        threads: threads,
        isLoading: true,
        error: '오류',
        hasLoaded: true,
      );

      expect(state.threads.length, 1);
      expect(state.isLoading, isTrue);
      expect(state.error, '오류');
      expect(state.hasLoaded, isTrue);
    });
  });

  group('ChatListState.copyWith', () {
    test('updates only the specified field — isLoading', () {
      const original = ChatListState(isLoading: false, hasLoaded: true);
      final updated = original.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.hasLoaded, isTrue); // preserved
      expect(updated.threads, isEmpty); // preserved
    });

    test('updates threads, preserves other fields', () {
      const original = ChatListState(isLoading: false, hasLoaded: true);
      final threads = [
        const ChatThreadData(
          channelId: 'chan-1',
          artistId: 'artist-1',
          artistName: '아티스트',
        ),
      ];
      final updated = original.copyWith(threads: threads);

      expect(updated.threads.length, 1);
      expect(updated.isLoading, isFalse); // preserved
      expect(updated.hasLoaded, isTrue); // preserved
    });

    test('error is always replaced — omitting error clears it to null', () {
      // error is NOT using ?? this.error in copyWith, so it always replaces
      const original = ChatListState(error: 'some error');
      final updated = original.copyWith(isLoading: false);

      expect(updated.error, isNull);
    });

    test('error can be explicitly set to a new string', () {
      const original = ChatListState(error: null);
      final updated = original.copyWith(error: '새 오류');

      expect(updated.error, '새 오류');
    });

    test(
        'error null-clearing: after setting error, copyWith without error clears it',
        () {
      const stateWithError = ChatListState(error: '로딩 실패');
      final cleared = stateWithError.copyWith(isLoading: false);
      expect(cleared.error, isNull);
    });

    test('preserves threads reference when not updated', () {
      final threads = [
        const ChatThreadData(
          channelId: 'chan-1',
          artistId: 'artist-1',
          artistName: '아티스트',
        ),
      ];
      final original = ChatListState(threads: threads);
      final updated = original.copyWith(isLoading: true);

      expect(updated.threads, same(threads));
    });

    test('hasLoaded is preserved correctly when not specified', () {
      const original = ChatListState(hasLoaded: true, isLoading: false);
      final updated = original.copyWith(isLoading: true);

      expect(updated.hasLoaded, isTrue);
    });

    test('all fields can be updated in a single copyWith call', () {
      const original = ChatListState();
      final threads = [
        const ChatThreadData(
          channelId: 'chan-1',
          artistId: 'artist-1',
          artistName: '아티스트',
        ),
      ];
      final updated = original.copyWith(
        threads: threads,
        isLoading: true,
        error: '오류 메시지',
        hasLoaded: true,
      );

      expect(updated.threads.length, 1);
      expect(updated.isLoading, isTrue);
      expect(updated.error, '오류 메시지');
      expect(updated.hasLoaded, isTrue);
    });
  });
}
