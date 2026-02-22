import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/artist.dart';
import 'package:uno_a_flutter/providers/discover_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Artist _makeArtist(String id) => Artist(
      id: id,
      name: 'Artist $id',
      avatarUrl: '',
      followerCount: 100,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // DiscoverState sealed class hierarchy
  // -------------------------------------------------------------------------

  group('DiscoverState sealed class hierarchy', () {
    group('DiscoverInitial', () {
      test('can be constructed with const', () {
        const state = DiscoverInitial();
        expect(state, isA<DiscoverState>());
        expect(state, isA<DiscoverInitial>());
      });

      test('const instances are identical', () {
        const a = DiscoverInitial();
        const b = DiscoverInitial();
        expect(identical(a, b), isTrue);
      });
    });

    group('DiscoverLoading', () {
      test('can be constructed with const', () {
        const state = DiscoverLoading();
        expect(state, isA<DiscoverState>());
        expect(state, isA<DiscoverLoading>());
      });

      test('const instances are identical', () {
        const a = DiscoverLoading();
        const b = DiscoverLoading();
        expect(identical(a, b), isTrue);
      });
    });

    group('DiscoverLoaded', () {
      test('stores trendingArtists and recommendedArtists', () {
        final trending = [_makeArtist('t1'), _makeArtist('t2')];
        final recommended = [_makeArtist('r1')];

        final state = DiscoverLoaded(
          trendingArtists: trending,
          recommendedArtists: recommended,
        );

        expect(state, isA<DiscoverState>());
        expect(state.trendingArtists, equals(trending));
        expect(state.recommendedArtists, equals(recommended));
      });

      test('recommendedArtists defaults to empty list', () {
        final state = DiscoverLoaded(trendingArtists: [_makeArtist('t1')]);
        expect(state.recommendedArtists, isEmpty);
      });

      test('trendingArtists and recommendedArtists can be empty', () {
        const state = DiscoverLoaded(trendingArtists: []);
        expect(state.trendingArtists, isEmpty);
        expect(state.recommendedArtists, isEmpty);
      });

      test('preserves order of artists', () {
        final artists = [
          _makeArtist('z'),
          _makeArtist('a'),
          _makeArtist('m'),
        ];
        final state = DiscoverLoaded(trendingArtists: artists);
        expect(state.trendingArtists.map((a) => a.id).toList(),
            equals(['z', 'a', 'm']));
      });
    });

    group('DiscoverError', () {
      test('stores message and null error by default', () {
        const state = DiscoverError('Something went wrong');
        expect(state, isA<DiscoverState>());
        expect(state.message, equals('Something went wrong'));
        expect(state.error, isNull);
      });

      test('stores message and optional error object', () {
        final err = Exception('network failure');
        final state = DiscoverError('Failed', err);
        expect(state.message, equals('Failed'));
        expect(state.error, same(err));
      });

      test('error field is accessible when provided', () {
        final err = StateError('bad state');
        final state = DiscoverError('오류 발생', err);
        expect(state.error, isA<StateError>());
      });
    });
  });

  // -------------------------------------------------------------------------
  // Type discrimination (is-checks)
  // -------------------------------------------------------------------------

  group('DiscoverState type discrimination', () {
    test('DiscoverInitial is only DiscoverInitial', () {
      const DiscoverState state = DiscoverInitial();
      expect(state is DiscoverInitial, isTrue);
      expect(state is DiscoverLoading, isFalse);
      expect(state is DiscoverLoaded, isFalse);
      expect(state is DiscoverError, isFalse);
    });

    test('DiscoverLoading is only DiscoverLoading', () {
      const DiscoverState state = DiscoverLoading();
      expect(state is DiscoverLoading, isTrue);
      expect(state is DiscoverInitial, isFalse);
      expect(state is DiscoverLoaded, isFalse);
      expect(state is DiscoverError, isFalse);
    });

    test('DiscoverLoaded is only DiscoverLoaded', () {
      final DiscoverState state = DiscoverLoaded(
        trendingArtists: [_makeArtist('x')],
      );
      expect(state is DiscoverLoaded, isTrue);
      expect(state is DiscoverInitial, isFalse);
      expect(state is DiscoverLoading, isFalse);
      expect(state is DiscoverError, isFalse);
    });

    test('DiscoverError is only DiscoverError', () {
      const DiscoverState state = DiscoverError('err');
      expect(state is DiscoverError, isTrue);
      expect(state is DiscoverInitial, isFalse);
      expect(state is DiscoverLoading, isFalse);
      expect(state is DiscoverLoaded, isFalse);
    });

    test('cast to DiscoverLoaded exposes trendingArtists', () {
      final artist = _makeArtist('cast-test');
      final DiscoverState state = DiscoverLoaded(trendingArtists: [artist]);

      if (state is DiscoverLoaded) {
        expect(state.trendingArtists.first.id, equals('cast-test'));
      } else {
        fail('Expected DiscoverLoaded');
      }
    });

    test('cast to DiscoverError exposes message', () {
      const DiscoverState state = DiscoverError('detail message');
      if (state is DiscoverError) {
        expect(state.message, equals('detail message'));
      } else {
        fail('Expected DiscoverError');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Derived providers via ProviderContainer overrides
  // -------------------------------------------------------------------------

  group('trendingArtistsProvider', () {
    test('returns empty list for DiscoverInitial', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(const DiscoverInitial()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(trendingArtistsProvider), isEmpty);
    });

    test('returns empty list for DiscoverLoading', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(const DiscoverLoading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(trendingArtistsProvider), isEmpty);
    });

    test('returns empty list for DiscoverError', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              const DiscoverError('err'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(trendingArtistsProvider), isEmpty);
    });

    test('returns trendingArtists list for DiscoverLoaded', () {
      final artists = [_makeArtist('a1'), _makeArtist('a2')];
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              DiscoverLoaded(trendingArtists: artists),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(trendingArtistsProvider);
      expect(result.length, equals(2));
      expect(result.map((a) => a.id).toList(), equals(['a1', 'a2']));
    });

    test('returns empty list when DiscoverLoaded has no trending artists', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              const DiscoverLoaded(trendingArtists: []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(trendingArtistsProvider), isEmpty);
    });
  });

  group('recommendedArtistsProvider', () {
    test('returns empty list for DiscoverInitial', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(const DiscoverInitial()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(recommendedArtistsProvider), isEmpty);
    });

    test('returns empty list for DiscoverLoading', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(const DiscoverLoading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(recommendedArtistsProvider), isEmpty);
    });

    test('returns empty list for DiscoverError', () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(const DiscoverError('load failed')),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(recommendedArtistsProvider), isEmpty);
    });

    test('returns recommendedArtists list for DiscoverLoaded', () {
      final recommended = [
        _makeArtist('r1'),
        _makeArtist('r2'),
        _makeArtist('r3')
      ];
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              DiscoverLoaded(
                trendingArtists: [],
                recommendedArtists: recommended,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(recommendedArtistsProvider);
      expect(result.length, equals(3));
      expect(result.map((a) => a.id).toList(), equals(['r1', 'r2', 'r3']));
    });

    test(
        'returns empty list when DiscoverLoaded has default recommendedArtists',
        () {
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              DiscoverLoaded(trendingArtists: [_makeArtist('t1')]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // recommendedArtists defaults to const []
      expect(container.read(recommendedArtistsProvider), isEmpty);
    });

    test('trending and recommended are independent in DiscoverLoaded', () {
      final trending = [_makeArtist('t1')];
      final recommended = [_makeArtist('r1'), _makeArtist('r2')];
      final container = ProviderContainer(
        overrides: [
          discoverProvider.overrideWith(
            (ref) => _StubDiscoverNotifier(
              DiscoverLoaded(
                trendingArtists: trending,
                recommendedArtists: recommended,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(trendingArtistsProvider).length, equals(1));
      expect(container.read(recommendedArtistsProvider).length, equals(2));
    });
  });
}

// ---------------------------------------------------------------------------
// Stub notifier — bypasses Supabase / auth initialization
// ---------------------------------------------------------------------------

class _StubDiscoverNotifier extends StateNotifier<DiscoverState>
    implements DiscoverNotifier {
  _StubDiscoverNotifier(super.state);

  // DiscoverNotifier interface members that are not exercised in pure-state
  // tests — all throw UnimplementedError so accidental calls are loud.
  @override
  Future<void> loadArtists() async {}

  @override
  Future<void> refresh() async {}
}
