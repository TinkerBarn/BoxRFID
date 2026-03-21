// BoxRFID – Filament Tag Manager
//
// Basic unit tests for data models and translation helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:box_rfid/data/defaults.dart';
import 'package:box_rfid/data/translations.dart';
import 'package:box_rfid/models/tag_data.dart';
import 'package:box_rfid/models/app_settings.dart';

void main() {
  group('TagData', () {
    test('fromBytes decodes correctly', () {
      final bytes = [1, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      final tag = TagData.fromBytes(bytes);
      expect(tag.materialCode, 1);
      expect(tag.colorCode, 5);
      expect(tag.manufacturerCode, 1);
      expect(tag.rawBytes.length, 16);
    });

    test('fromBytes handles short input', () {
      final tag = TagData.fromBytes([10]);
      expect(tag.materialCode, 10);
      expect(tag.colorCode, 0);
      expect(tag.manufacturerCode, 1);
    });
  });

  group('AppSettings', () {
    test('defaults returns expected values', () {
      final s = AppSettings.defaults();
      expect(s.language, 'en');
      expect(s.useManufacturer, false);
      expect(s.materials, kDefaultMaterials);
      expect(s.manufacturers, kDefaultManufacturers);
    });

    test('copyWith preserves unmodified fields', () {
      final s = AppSettings.defaults().copyWith(language: 'de');
      expect(s.language, 'de');
      expect(s.useManufacturer, false);
    });

    test('toJson / fromJson round-trips correctly', () {
      final original = AppSettings.defaults().copyWith(
        language: 'fr',
        useManufacturer: true,
      );
      final json = original.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.language, 'fr');
      expect(restored.useManufacturer, true);
      expect(restored.materials, original.materials);
    });
  });

  group('Translations', () {
    test('tr returns correct English string', () {
      expect(tr('en', 'writeBtn'), 'Write Tag');
      expect(tr('en', 'readBtn'), 'Read Tag');
    });

    test('tr returns correct German string', () {
      expect(tr('de', 'writeBtn'), 'Tag schreiben');
    });

    test('tr falls back to English for missing language', () {
      expect(tr('xx', 'writeBtn'), 'Write Tag');
    });

    test('colorName returns correct name for known hex', () {
      expect(colorName('en', '#FAFAFA'), 'White');
      expect(colorName('de', '#FAFAFA'), 'Weiß');
      expect(colorName('zh', '#060606'), '黑色');
    });
  });

  group('Default data', () {
    test('kDefaultMaterials is not empty', () {
      expect(kDefaultMaterials.isNotEmpty, true);
    });

    test('kDefaultColors contains 24 entries', () {
      expect(kDefaultColors.length, 24);
    });

    test('kDefaultManufacturers contains QIDI and Generic', () {
      expect(kDefaultManufacturers[0], 'Generic');
      expect(kDefaultManufacturers[1], 'QIDI');
    });

    test('kMifareAuthKeys contains vendor key and default key', () {
      expect(kMifareAuthKeys[0], [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7]);
      expect(kMifareAuthKeys[1], [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
    });
  });
}
