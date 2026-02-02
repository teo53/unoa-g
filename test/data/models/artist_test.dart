import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/artist.dart';

void main() {
  group('YouTubeFancam', () {
    group('extractVideoId', () {
      test('extracts ID from standard watch URL', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from watch URL with additional params', () {
        const url =
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from short URL (youtu.be)', () {
        const url = 'https://youtu.be/dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from short URL with params', () {
        const url = 'https://youtu.be/dQw4w9WgXcQ?t=42';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from embed URL', () {
        const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from shorts URL', () {
        const url = 'https://www.youtube.com/shorts/dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('extracts ID from URL without www', () {
        const url = 'https://youtube.com/watch?v=dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(url), equals('dQw4w9WgXcQ'));
      });

      test('returns input if already a valid video ID', () {
        const videoId = 'dQw4w9WgXcQ';
        expect(YouTubeFancam.extractVideoId(videoId), equals('dQw4w9WgXcQ'));
      });

      test('handles video ID with underscores', () {
        const videoId = 'abc_123_XYZ';
        expect(YouTubeFancam.extractVideoId(videoId), equals('abc_123_XYZ'));
      });

      test('handles video ID with dashes', () {
        const videoId = 'abc-123-XYZ';
        expect(YouTubeFancam.extractVideoId(videoId), equals('abc-123-XYZ'));
      });

      test('returns null for invalid URL', () {
        const url = 'https://example.com/video';
        expect(YouTubeFancam.extractVideoId(url), isNull);
      });

      test('returns null for empty string', () {
        expect(YouTubeFancam.extractVideoId(''), isNull);
      });

      test('returns null for too short video ID', () {
        const shortId = 'abc123';
        expect(YouTubeFancam.extractVideoId(shortId), isNull);
      });

      test('returns null for too long video ID', () {
        const longId = 'abc123456789012';
        expect(YouTubeFancam.extractVideoId(longId), isNull);
      });

      test('returns null for video ID with invalid characters', () {
        const invalidId = 'abc!@#\$%^&*(';
        expect(YouTubeFancam.extractVideoId(invalidId), isNull);
      });
    });

    group('thumbnail URLs', () {
      test('generates correct default thumbnail URL', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'dQw4w9WgXcQ',
          title: 'Test Video',
        );

        expect(fancam.thumbnailUrl,
            equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'));
      });

      test('generates correct HQ thumbnail URL', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'dQw4w9WgXcQ',
          title: 'Test Video',
        );

        expect(fancam.thumbnailUrlHQ,
            equals('https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg'));
      });

      test('generates correct MQ thumbnail URL', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'dQw4w9WgXcQ',
          title: 'Test Video',
        );

        expect(fancam.thumbnailUrlMQ,
            equals('https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg'));
      });

      test('generates correct SD thumbnail URL', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'dQw4w9WgXcQ',
          title: 'Test Video',
        );

        expect(fancam.thumbnailUrlSD,
            equals('https://img.youtube.com/vi/dQw4w9WgXcQ/sddefault.jpg'));
      });
    });

    group('videoUrl', () {
      test('generates correct video URL', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'dQw4w9WgXcQ',
          title: 'Test Video',
        );

        expect(fancam.videoUrl,
            equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
      });
    });

    group('formattedViewCount', () {
      test('returns empty string for null viewCount', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: null,
        );

        expect(fancam.formattedViewCount, equals(''));
      });

      test('returns raw count for less than 1000', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 999,
        );

        expect(fancam.formattedViewCount, equals('999 views'));
      });

      test('returns K format for 1000-9999', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 1500,
        );

        expect(fancam.formattedViewCount, equals('1.5K views'));
      });

      test('returns 만 format for 10000-999999', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 50000,
        );

        expect(fancam.formattedViewCount, equals('5만 views'));
      });

      test('returns 만 format for 150000', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 150000,
        );

        expect(fancam.formattedViewCount, equals('15만 views'));
      });

      test('returns M format for 1000000+', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 1500000,
        );

        expect(fancam.formattedViewCount, equals('1.5M views'));
      });

      test('returns M format for 10000000', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          viewCount: 10000000,
        );

        expect(fancam.formattedViewCount, equals('10.0M views'));
      });
    });

    group('isPinned', () {
      test('defaults to false', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
        );

        expect(fancam.isPinned, isFalse);
      });

      test('can be set to true', () {
        final fancam = YouTubeFancam(
          id: '1',
          videoId: 'test123abcd',
          title: 'Test Video',
          isPinned: true,
        );

        expect(fancam.isPinned, isTrue);
      });
    });
  });

  group('Artist', () {
    group('displayName', () {
      test('returns name when no English name', () {
        const artist = Artist(
          id: '1',
          name: '민지',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.displayName, equals('민지'));
      });

      test('returns name with English name when available', () {
        const artist = Artist(
          id: '1',
          name: '민지',
          englishName: 'Minji',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.displayName, equals('민지 (Minji)'));
      });
    });

    group('formattedFollowers', () {
      test('returns raw count for less than 1000', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 999,
        );

        expect(artist.formattedFollowers, equals('999'));
      });

      test('returns 천 format for 1000-9999', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 5000,
        );

        expect(artist.formattedFollowers, equals('5천'));
      });

      test('returns 만 format for 10000-999999', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 150000,
        );

        expect(artist.formattedFollowers, equals('15만'));
      });

      test('returns M format for 1000000+', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 2500000,
        );

        expect(artist.formattedFollowers, equals('2.5M'));
      });
    });

    group('pinnedFancam', () {
      test('returns null when no fancams', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
          fancams: [],
        );

        expect(artist.pinnedFancam, isNull);
      });

      test('returns first fancam when none are pinned', () {
        final artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
          fancams: [
            YouTubeFancam(
              id: '1',
              videoId: 'video1aaaaaa',
              title: 'First Video',
              isPinned: false,
            ),
            YouTubeFancam(
              id: '2',
              videoId: 'video2aaaaaa',
              title: 'Second Video',
              isPinned: false,
            ),
          ],
        );

        expect(artist.pinnedFancam?.id, equals('1'));
        expect(artist.pinnedFancam?.title, equals('First Video'));
      });

      test('returns pinned fancam when one exists', () {
        final artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
          fancams: [
            YouTubeFancam(
              id: '1',
              videoId: 'video1aaaaaa',
              title: 'First Video',
              isPinned: false,
            ),
            YouTubeFancam(
              id: '2',
              videoId: 'video2aaaaaa',
              title: 'Pinned Video',
              isPinned: true,
            ),
            YouTubeFancam(
              id: '3',
              videoId: 'video3aaaaaa',
              title: 'Third Video',
              isPinned: false,
            ),
          ],
        );

        expect(artist.pinnedFancam?.id, equals('2'));
        expect(artist.pinnedFancam?.title, equals('Pinned Video'));
      });

      test('returns first pinned fancam when multiple are pinned', () {
        final artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
          fancams: [
            YouTubeFancam(
              id: '1',
              videoId: 'video1aaaaaa',
              title: 'First Pinned',
              isPinned: true,
            ),
            YouTubeFancam(
              id: '2',
              videoId: 'video2aaaaaa',
              title: 'Second Pinned',
              isPinned: true,
            ),
          ],
        );

        expect(artist.pinnedFancam?.id, equals('1'));
        expect(artist.pinnedFancam?.title, equals('First Pinned'));
      });
    });

    group('default values', () {
      test('isVerified defaults to false', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.isVerified, isFalse);
      });

      test('isOnline defaults to false', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.isOnline, isFalse);
      });

      test('postCount defaults to 0', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.postCount, equals(0));
      });

      test('tier defaults to STANDARD', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.tier, equals('STANDARD'));
      });

      test('fancams defaults to empty list', () {
        const artist = Artist(
          id: '1',
          name: 'Test',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 1000,
        );

        expect(artist.fancams, isEmpty);
      });
    });
  });
}
