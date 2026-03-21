// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'package:flutter/material.dart';
import '../data/translations.dart';

/// Displays a grid of color swatches. Tapping one selects it.
class ColorGridWidget extends StatelessWidget {
  final Map<String, int> colors;
  final String? selectedHex;
  final String language;
  final ValueChanged<String?> onColorSelected;

  const ColorGridWidget({
    super.key,
    required this.colors,
    required this.selectedHex,
    required this.language,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hexList = colors.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: hexList.length,
          itemBuilder: (context, index) {
            final hex = hexList[index];
            final isSelected = hex == selectedHex;
            final color = _hexToColor(hex);
            return Tooltip(
              message: colorName(language, hex),
              child: GestureDetector(
                onTap: () => onColorSelected(isSelected ? null : hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2.5)
                        : Border.all(color: Colors.transparent, width: 2.5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  transform: isSelected
                      ? (Matrix4.identity()..scale(1.1))
                      : Matrix4.identity(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _ColorPreviewBar(
          selectedHex: selectedHex,
          language: language,
        ),
      ],
    );
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : Colors.grey;
  }
}

class _ColorPreviewBar extends StatelessWidget {
  final String? selectedHex;
  final String language;

  const _ColorPreviewBar({
    required this.selectedHex,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final hasColor = selectedHex != null;
    final color = hasColor ? ColorGridWidget._hexToColor(selectedHex!) : null;
    final name = hasColor ? colorName(language, selectedHex!) : null;
    final label = hasColor
        ? '${tr(language, 'colorSelected')} $name'
        : tr(language, 'noColorSelected');
    final textColor = hasColor ? _contrastColor(color!) : Colors.grey[600]!;

    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 14,
        ),
      ),
    );
  }

  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }
}
