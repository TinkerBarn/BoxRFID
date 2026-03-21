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

    return AppSettings(
      language: (json['language'] as String?) ?? 'en',
      useManufacturer: (json['useManufacturer'] as bool?) ?? false,
      materials: json.containsKey('materials')
          ? parseMaterialsMap(json['materials'])
          : Map<int, String>.from(kDefaultMaterials),
      manufacturers: json.containsKey('manufacturers')
          ? parseMaterialsMap(json['manufacturers'])
          : Map<int, String>.from(kDefaultManufacturers),
    );
  }
}
