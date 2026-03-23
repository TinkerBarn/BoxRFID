// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import '../data/defaults.dart';

/// All persisted app settings.
class AppSettings {
  final String language;
  final bool useManufacturer;
  final Map<int, String> materials;
  final Map<int, String> manufacturers;

  const AppSettings({
    required this.language,
    required this.useManufacturer,
    required this.materials,
    required this.manufacturers,
  });

  factory AppSettings.defaults() => const AppSettings(
        language: 'en',
        useManufacturer: false,
        materials: kDefaultMaterials,
        manufacturers: kDefaultManufacturers,
      );

  AppSettings copyWith({
    String? language,
    bool? useManufacturer,
    Map<int, String>? materials,
    Map<int, String>? manufacturers,
  }) {
    return AppSettings(
      language: language ?? this.language,
      useManufacturer: useManufacturer ?? this.useManufacturer,
      materials: materials ?? this.materials,
      manufacturers: manufacturers ?? this.manufacturers,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'useManufacturer': useManufacturer,
        'materials': {
          for (final e in materials.entries) e.key.toString(): e.value,
        },
        'manufacturers': {
          for (final e in manufacturers.entries) e.key.toString(): e.value,
        },
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    Map<int, String> parseMaterialsMap(dynamic raw) {
      if (raw is Map) {
        final result = <int, String>{};
        raw.forEach((k, v) {
          final code = int.tryParse(k.toString());
          if (code != null && v is String) result[code] = v;
        });
        return result;
      }
      return {};
    }

    /// Merge saved entries with the current defaults so that:
    ///   - All default codes always reflect the latest spec names.
    ///   - User-added codes (not in [defaults]) are preserved on top.
    Map<int, String> mergeWithDefaults(
        Map<int, String> saved, Map<int, String> defaults) {
      return {
        ...defaults,
        for (final e in saved.entries)
          if (!defaults.containsKey(e.key)) e.key: e.value,
      };
    }

    final savedMaterials = json.containsKey('materials')
        ? parseMaterialsMap(json['materials'])
        : <int, String>{};
    final savedManufacturers = json.containsKey('manufacturers')
        ? parseMaterialsMap(json['manufacturers'])
        : <int, String>{};

    return AppSettings(
      language: (json['language'] as String?) ?? 'en',
      useManufacturer: (json['useManufacturer'] as bool?) ?? false,
      materials: mergeWithDefaults(savedMaterials, kDefaultMaterials),
      manufacturers:
          mergeWithDefaults(savedManufacturers, kDefaultManufacturers),
    );
  }
}
