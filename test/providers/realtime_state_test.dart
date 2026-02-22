import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/providers/realtime_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RealtimeState sealed class hierarchy
  // ---------------------------------------------------------------------------

  group('RealtimeState sealed class hierarchy', () {
    group('RealtimeInitial', () {
      test('can be constructed with const', () {
        const state = RealtimeInitial();
        expect(state, isA<RealtimeState>());
        expect(state, isA<RealtimeInitial>());
      });

      test('const instances are identical', () {
        const a = RealtimeInitial();
        const b = RealtimeInitial();
        expect(identical(a, b), isTrue);
      });
    });

    group('RealtimeConnecting', () {
      test('can be constructed with const', () {
        const state = RealtimeConnecting();
        expect(state, isA<RealtimeState>());
        expect(state, isA<RealtimeConnecting>());
      });

      test('const instances are identical', () {
        const a = RealtimeConnecting();
        const b = RealtimeConnecting();
        expect(identical(a, b), isTrue);
      });
    });

    group('RealtimeConnected', () {
      test('constructs with default empty collections', () {
        const state = RealtimeConnected();
        expect(state, isA<RealtimeState>());
        expect(state.subscribedChannels, isEmpty);
        expect(state.onlineUsers, isEmpty);
        expect(state.typingUsers, isEmpty);
      });

      test('constructs with provided subscribedChannels', () {
        const state = RealtimeConnected(
          subscribedChannels: {'channel-1', 'channel-2'},
        );
        expect(state.subscribedChannels, equals({'channel-1', 'channel-2'}));
        expect(state.subscribedChannels.length, equals(2));
      });

      test('constructs with provided onlineUsers', () {
        const state = RealtimeConnected(
          onlineUsers: {
            'channel-1': {'user-a': true, 'user-b': false},
          },
        );
        expect(state.onlineUsers['channel-1'], isNotNull);
        expect(state.onlineUsers['channel-1']!['user-a'], isTrue);
        expect(state.onlineUsers['channel-1']!['user-b'], isFalse);
      });

      test('constructs with provided typingUsers', () {
        const state = RealtimeConnected(
          typingUsers: {
            'channel-1': {'user-a', 'user-b'},
          },
        );
        expect(state.typingUsers['channel-1'], isNotNull);
        expect(state.typingUsers['channel-1']!.contains('user-a'), isTrue);
        expect(state.typingUsers['channel-1']!.contains('user-b'), isTrue);
      });

      test('constructs with all fields populated', () {
        const state = RealtimeConnected(
          subscribedChannels: {'ch-1'},
          onlineUsers: {
            'ch-1': {'user-1': true},
          },
          typingUsers: {
            'ch-1': {'user-2'},
          },
        );

        expect(state.subscribedChannels, equals({'ch-1'}));
        expect(state.onlineUsers['ch-1']!['user-1'], isTrue);
        expect(state.typingUsers['ch-1']!.contains('user-2'), isTrue);
      });
    });

    group('RealtimeError', () {
      test('constructs with message only', () {
        const state = RealtimeError('Connection failed');
        expect(state, isA<RealtimeState>());
        expect(state.message, equals('Connection failed'));
        expect(state.error, isNull);
      });

      test('constructs with message and error object', () {
        final err = Exception('socket error');
        final state = RealtimeError('Failed to connect', err);
        expect(state.message, equals('Failed to connect'));
        expect(state.error, same(err));
      });

      test('error field is optional and defaults to null', () {
        const state = RealtimeError('timeout');
        expect(state.error, isNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // RealtimeConnected.copyWith
  // ---------------------------------------------------------------------------

  group('RealtimeConnected.copyWith', () {
    const baseline = RealtimeConnected(
      subscribedChannels: {'channel-A', 'channel-B'},
      onlineUsers: {
        'channel-A': {'user-1': true, 'user-2': false},
      },
      typingUsers: {
        'channel-A': {'user-3'},
      },
    );

    test('returns a new RealtimeConnected instance', () {
      final copy = baseline.copyWith();
      expect(copy, isA<RealtimeConnected>());
      // Not the same object reference
      expect(identical(copy, baseline), isFalse);
    });

    test('copyWith with no arguments preserves all fields', () {
      final copy = baseline.copyWith();

      expect(copy.subscribedChannels, equals(baseline.subscribedChannels));
      expect(copy.onlineUsers, equals(baseline.onlineUsers));
      expect(copy.typingUsers, equals(baseline.typingUsers));
    });

    group('updating only subscribedChannels', () {
      test('sets new subscribedChannels', () {
        final copy = baseline.copyWith(
          subscribedChannels: {'channel-C'},
        );

        expect(copy.subscribedChannels, equals({'channel-C'}));
      });

      test('does not change onlineUsers', () {
        final copy = baseline.copyWith(
          subscribedChannels: {'channel-C'},
        );

        expect(copy.onlineUsers, equals(baseline.onlineUsers));
      });

      test('does not change typingUsers', () {
        final copy = baseline.copyWith(
          subscribedChannels: {'channel-C'},
        );

        expect(copy.typingUsers, equals(baseline.typingUsers));
      });
    });

    group('updating only onlineUsers', () {
      test('sets new onlineUsers map', () {
        final newOnlineUsers = {
          'channel-B': {'user-5': true},
        };
        final copy = baseline.copyWith(onlineUsers: newOnlineUsers);

        expect(copy.onlineUsers, equals(newOnlineUsers));
      });

      test('does not change subscribedChannels', () {
        final copy = baseline.copyWith(
          onlineUsers: {
            'channel-B': {'user-5': true}
          },
        );

        expect(copy.subscribedChannels, equals(baseline.subscribedChannels));
      });

      test('does not change typingUsers', () {
        final copy = baseline.copyWith(
          onlineUsers: {
            'channel-B': {'user-5': true}
          },
        );

        expect(copy.typingUsers, equals(baseline.typingUsers));
      });
    });

    group('updating only typingUsers', () {
      test('sets new typingUsers map', () {
        final newTypingUsers = {
          'channel-B': {'user-7', 'user-8'},
        };
        final copy = baseline.copyWith(typingUsers: newTypingUsers);

        expect(copy.typingUsers, equals(newTypingUsers));
      });

      test('does not change subscribedChannels', () {
        final copy = baseline.copyWith(
          typingUsers: {
            'channel-B': {'user-7'}
          },
        );

        expect(copy.subscribedChannels, equals(baseline.subscribedChannels));
      });

      test('does not change onlineUsers', () {
        final copy = baseline.copyWith(
          typingUsers: {
            'channel-B': {'user-7'}
          },
        );

        expect(copy.onlineUsers, equals(baseline.onlineUsers));
      });
    });

    test('can clear subscribedChannels to empty set', () {
      final copy = baseline.copyWith(subscribedChannels: {});
      expect(copy.subscribedChannels, isEmpty);
      expect(copy.onlineUsers, equals(baseline.onlineUsers));
      expect(copy.typingUsers, equals(baseline.typingUsers));
    });

    test('can clear onlineUsers to empty map', () {
      final copy = baseline.copyWith(onlineUsers: {});
      expect(copy.onlineUsers, isEmpty);
      expect(copy.subscribedChannels, equals(baseline.subscribedChannels));
      expect(copy.typingUsers, equals(baseline.typingUsers));
    });

    test('can clear typingUsers to empty map', () {
      final copy = baseline.copyWith(typingUsers: {});
      expect(copy.typingUsers, isEmpty);
      expect(copy.subscribedChannels, equals(baseline.subscribedChannels));
      expect(copy.onlineUsers, equals(baseline.onlineUsers));
    });

    test('can update all fields simultaneously', () {
      final newChannels = {'channel-X'};
      final newOnlineUsers = {
        'channel-X': {'user-99': true}
      };
      final newTypingUsers = {
        'channel-X': {'user-99'}
      };

      final copy = baseline.copyWith(
        subscribedChannels: newChannels,
        onlineUsers: newOnlineUsers,
        typingUsers: newTypingUsers,
      );

      expect(copy.subscribedChannels, equals(newChannels));
      expect(copy.onlineUsers, equals(newOnlineUsers));
      expect(copy.typingUsers, equals(newTypingUsers));
    });

    test('spread-merge pattern adds channel to existing set', () {
      const current = RealtimeConnected(
        subscribedChannels: {'channel-1'},
      );

      final updated = current.copyWith(
        subscribedChannels: {...current.subscribedChannels, 'channel-2'},
      );

      expect(updated.subscribedChannels, equals({'channel-1', 'channel-2'}));
    });

    test('spread-merge pattern adds online user to existing channel map', () {
      const current = RealtimeConnected(
        onlineUsers: {
          'channel-1': {'user-1': true},
        },
      );

      final updated = current.copyWith(
        onlineUsers: {
          ...current.onlineUsers,
          'channel-2': {'user-2': false},
        },
      );

      expect(updated.onlineUsers.length, equals(2));
      expect(updated.onlineUsers['channel-1']!['user-1'], isTrue);
      expect(updated.onlineUsers['channel-2']!['user-2'], isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Type pattern matching via is-checks
  // ---------------------------------------------------------------------------

  group('RealtimeState type discrimination', () {
    test('RealtimeInitial is not RealtimeConnected', () {
      const RealtimeState state = RealtimeInitial();
      expect(state is RealtimeConnected, isFalse);
      expect(state is RealtimeInitial, isTrue);
    });

    test('RealtimeConnecting is not RealtimeConnected', () {
      const RealtimeState state = RealtimeConnecting();
      expect(state is RealtimeConnected, isFalse);
      expect(state is RealtimeConnecting, isTrue);
    });

    test('RealtimeConnected is not RealtimeError', () {
      const RealtimeState state = RealtimeConnected();
      expect(state is RealtimeError, isFalse);
      expect(state is RealtimeConnected, isTrue);
    });

    test('RealtimeError is not RealtimeConnected', () {
      const RealtimeState state = RealtimeError('err');
      expect(state is RealtimeConnected, isFalse);
      expect(state is RealtimeError, isTrue);
    });

    test('cast to RealtimeConnected exposes fields', () {
      const RealtimeState state = RealtimeConnected(
        subscribedChannels: {'ch-1'},
      );

      if (state is RealtimeConnected) {
        expect(state.subscribedChannels, contains('ch-1'));
      } else {
        fail('Expected RealtimeConnected');
      }
    });
  });
}
