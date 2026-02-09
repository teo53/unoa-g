import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/core/config/demo_config.dart';

void main() {
  group('DemoConfig', () {
    group('avatarUrl', () {
      test('generates correct URL with default size', () {
        final url = DemoConfig.avatarUrl('vtuber1');
        expect(url, equals('https://picsum.photos/seed/vtuber1/200'));
      });

      test('generates correct URL with custom size', () {
        final url = DemoConfig.avatarUrl('kpop1', size: 400);
        expect(url, equals('https://picsum.photos/seed/kpop1/400'));
      });

      test('demoCreatorAvatarUrl matches expected format', () {
        expect(
          DemoConfig.demoCreatorAvatarUrl,
          equals('https://picsum.photos/seed/vtuber1/200'),
        );
      });
    });

    group('bannerUrl', () {
      test('generates correct URL with default dimensions', () {
        final url = DemoConfig.bannerUrl('banner1');
        expect(url, equals('https://picsum.photos/seed/banner1/400/200'));
      });

      test('generates correct URL with custom dimensions', () {
        final url = DemoConfig.bannerUrl('promo1', width: 800, height: 400);
        expect(url, equals('https://picsum.photos/seed/promo1/800/400'));
      });
    });

    group('data integrity', () {
      test('sampleArtists has expected entries and required keys', () {
        expect(DemoConfig.sampleArtists.length, equals(6));
        for (final artist in DemoConfig.sampleArtists) {
          expect(artist.containsKey('name'), isTrue);
          expect(artist.containsKey('nameEn'), isTrue);
          expect(artist.containsKey('category'), isTrue);
        }
      });

      test('demoFans has expected entries and required keys', () {
        expect(DemoConfig.demoFans.length, equals(10));
        for (final fan in DemoConfig.demoFans) {
          expect(fan.containsKey('id'), isTrue);
          expect(fan.containsKey('name'), isTrue);
          expect(fan.containsKey('tier'), isTrue);
          expect(fan.containsKey('days'), isTrue);
        }
      });

      test('chargeAmountOptions is sorted ascending', () {
        for (int i = 1; i < DemoConfig.chargeAmountOptions.length; i++) {
          expect(
            DemoConfig.chargeAmountOptions[i],
            greaterThan(DemoConfig.chargeAmountOptions[i - 1]),
          );
        }
      });
    });
  });
}
