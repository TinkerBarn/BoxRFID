// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'package:flutter/material.dart';
import '../data/defaults.dart';
import '../data/translations.dart';
import '../models/tag_data.dart';

/// Dialog that shows the details of a recently read tag.
class TagInfoDialog extends StatelessWidget {
  final TagData tagData;
  final Map<int, String> materials;
  final Map<int, String> manufacturers;
  final String language;

  const TagInfoDialog({
    super.key,
    required this.tagData,
    required this.materials,
    required this.manufacturers,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final materialName =
        materials[tagData.materialCode] ?? '? (${tagData.materialCode})';
    final mfgName = manufacturers[tagData.manufacturerCode] ??
        '? (${tagData.manufacturerCode})';
    final colorHex = _colorCodeToHex(tagData.colorCode);
    final colorLabel = colorHex != null
        ? colorName(language, colorHex)
        : '? (${tagData.colorCode})';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(language, 'tagInfoTitle'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              label: tr(language, 'material'),
              value: '$materialName  (${tagData.materialCode})',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: tr(language, 'color'),
              value: '$colorLabel',
              colorHex: colorHex,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: tr(language, 'manufacturer'),
              value: '$mfgName  (${tagData.manufacturerCode})',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(tr(language, 'closePopupBtn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _colorCodeToHex(int code) {
    for (final entry in kDefaultColors.entries) {
      if (entry.value == code) return entry.key;
    }
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? colorHex;

  const _InfoRow({
    required this.label,
    required this.value,
    this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    Color? swatch;
    if (colorHex != null) {
      final cleaned = colorHex!.replaceFirst('#', '');
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      swatch = parsed != null ? Color(parsed) : null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          if (swatch != null) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
