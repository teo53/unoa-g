import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/artist.dart';

void main() {
  group('YouTubeFancam', () {
    group('extractVideoId', () {
      test('extracts from standard watch URL', () {
        expect(
          YouTubeFancam.extractVideoId(
              'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts from short youtu.be URL', () {
        expect(
          YouTubeFancam.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts from embed URL', () {
        expect(
          YouTubeFancam.extractVideoId(
              'https://www.youtube.com/embed/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts from shorts URL', () {
        expect(
          YouTubeFancam.extractVideoId(
              'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('returns raw 11-char video ID', () {
        expect(
          YouTubeFancam.extractVideoId('dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('returns null for invalid URL', () {
        expect(
          YouTubeFancam.extractVideoId('https://example.com/video'),
          isNull,
        );
      });

      test('returns null for empty string', () {
        expect(YouTubeFancam.extractVideoId(''), isNull);
      });
    });

    group('computed properties', () {
      final fancam = YouTubeFancam(
        id: 'fc-1',
        videoId: 'dQw4w9WgXcQ',
        title: 'Test Fancam',
      );

      test('videoUrl returns correct YouTube URL', () {
        expect(
          fancam.videoUrl,
          equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        );
      });

      test('thumbnailUrl returns correct hqdefault URL', () {
        expect(
          fancam.thumbnailUrl,
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
        );
      });
    });

    group('formattedViewCount', () {
      test('returns empty string when viewCount is null', () {
        const fancam = YouTubeFancam(
          id: 'fc-1',
          videoId: 'abc',
          title: 'Test',
        );
        expect(fancam.formattedViewCount, equals(''));
      });

      test('returns M format for millions', () {
        const fancam = YouTubeFancam(
          id: 'fc-1',
          videoId: 'abc',
          title: 'Test',
          viewCount: 1500000,
        );
        expect(fancam.formattedViewCount, equals('1.5M views'));
      });

      test('returns 만 format for ten-thousands', () {
        const fancam = YouTubeFancam(
          id: 'fc-1',
          videoId: 'abc',
          title: 'Test',
          viewCount: 50000,
        );
        expect(fancam.formattedViewCount, equals('5만 views'));
      });

      test('returns K format for thousands', () {
        const fancam = YouTubeFancam(
          id: 'fc-1',
          videoId: 'abc',
          title: 'Test',
          viewCount: 2500,
        );
        expect(fancam.formattedViewCount, equals('2.5K views'));
      });

      test('returns raw count for small numbers', () {
        const fancam = YouTubeFancam(
          id: 'fc-1',
          videoId: 'abc',
          title: 'Test',
          viewCount: 500,
        );
        expect(fancam.formattedViewCount, equals('500 views'));
      });
    });
  });

  group('Artist', () {
    group('displayName', () {
      test('includes English name in parentheses when available', () {
        const artist = Artist(
          id: 'a-1',
          name: '하늘달',
          englishName: 'HaneulDal',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );
        expect(artist.displayName, equals('하늘달 (HaneulDal)'));
      });

      test('returns name only when no English name', () {
        const artist = Artist(
          id: 'a-1',
          name: '하늘달',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );
        expect(artist.displayName, equals('하늘달'));
      });
    });

    group('formattedFollowers', () {
      test('formats millions with M suffix', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 1500000,
        );
        expect(artist.formattedFollowers, equals('1.5M'));
      });

      test('formats ten-thousands with 만 suffix', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 50000,
        );
        expect(artist.formattedFollowers, equals('5만'));
      });

      test('formats thousands with 천 suffix', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 3000,
        );
        expect(artist.formattedFollowers, equals('3천'));
      });

      test('returns raw count for small numbers', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 500,
        );
        expect(artist.formattedFollowers, equals('500'));
      });
    });

    group('pinnedFancam', () {
      test('returns pinned fancam when one is pinned', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 1000,
          fancams: [
            YouTubeFancam(id: 'fc-1', videoId: 'aaa', title: 'First'),
            YouTubeFancam(
              id: 'fc-2',
              videoId: 'bbb',
              title: 'Pinned',
              isPinned: true,
            ),
          ],
        );
        expect(artist.pinnedFancam?.id, equals('fc-2'));
      });

      test('returns first fancam when none is pinned', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 1000,
          fancams: [
            YouTubeFancam(id: 'fc-1', videoId: 'aaa', title: 'First'),
            YouTubeFancam(id: 'fc-2', videoId: 'bbb', title: 'Second'),
          ],
        );
        expect(artist.pinnedFancam?.id, equals('fc-1'));
      });

      test('returns null for empty fancams list', () {
        const artist = Artist(
          id: 'a-1',
          name: 'Test',
          avatarUrl: '',
          followerCount: 1000,
        );
        expect(artist.pinnedFancam, isNull);
      });
    });
  });
}
