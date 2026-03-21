// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/defaults.dart';
import '../data/translations.dart';
import '../providers/app_provider.dart';
import '../services/nfc_service.dart';
import '../widgets/color_grid_widget.dart';
import '../widgets/tag_info_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _nfcAvailable = false;
  bool _nfcChecked = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcService.instance.isAvailable();
    if (mounted) {
      setState(() {
        _nfcAvailable = available;
        _nfcChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.settings.language;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              tr(lang, 'appTitle'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            actions: [
              // NFC status indicator
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Center(
                  child: _NfcStatusDot(available: _nfcChecked && _nfcAvailable),
                ),
              ),
              // Settings button
              IconButton(
                icon: const Text('⚙️', style: TextStyle(fontSize: 20)),
                onPressed: () => _openSettings(context),
                tooltip: tr(lang, 'setupTitle'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NFC unavailable warning
                if (_nfcChecked && !_nfcAvailable)
                  _WarningBanner(message: tr(lang, 'nfcNotAvailable')),
                // Manufacturer selector (optional)
                if (provider.settings.useManufacturer)
                  _SectionCard(
                    title: tr(lang, 'manufacturerLabel'),
                    child: _ManufacturerDropdown(lang: lang),
                  ),
                // Material selector
                _SectionCard(
                  title: tr(lang, 'materialLabel'),
                  child: _MaterialDropdown(lang: lang),
                ),
                // Color selector
                _SectionCard(
                  title: tr(lang, 'colorLabel'),
                  child: ColorGridWidget(
                    colors: kDefaultColors,
                    selectedHex: provider.selectedColorHex,
                    language: lang,
                    onColorSelected: (hex) => provider.selectColor(hex),
                  ),
                ),
                const SizedBox(height: 6),
                // Write button
                _ActionButton(
                  label: tr(lang, 'writeBtn'),
                  color: const Color(0xFF4CAF50),
                  gradientEnd: const Color(0xFF45a049),
                  onPressed: provider.isBusy ? null : () => _writeTag(context, provider, lang),
                ),
                const SizedBox(height: 8),
                // Read button
                _ActionButton(
                  label: tr(lang, 'readBtn'),
                  color: const Color(0xFF2196F3),
                  gradientEnd: const Color(0xFF1976D2),
                  onPressed: provider.isBusy ? null : () => _readTag(context, provider, lang),
                ),
                const SizedBox(height: 8),
                // Auto-detect toggle
                Center(
                  child: _AutoDetectButton(lang: lang),
                ),
                const SizedBox(height: 16),
                // Loading indicator
                if (provider.isBusy)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(lang, 'loadingText'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                // Status message
                if (!provider.isBusy && provider.statusMessageKey != null)
                  _StatusMessage(lang: lang),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _writeTag(
      BuildContext context, AppProvider provider, String lang) async {
    // Validate selections
    if (provider.selectedMaterialCode == null) {
      provider.setStatus(
          messageKey: 'selectMaterialError', isError: true);
      return;
    }
    if (provider.settings.useManufacturer &&
        provider.selectedManufacturerCode == null) {
      provider.setStatus(
          messageKey: 'selectManufacturerError', isError: true);
      return;
    }
    if (provider.selectedColorHex == null) {
      provider.setStatus(messageKey: 'selectColorError', isError: true);
      return;
    }

    final colorCode =
        kDefaultColors[provider.selectedColorHex!] ?? 0;
    final mfgCode =
        provider.settings.useManufacturer ? (provider.selectedManufacturerCode ?? kDefaultManufacturerCode) : kDefaultManufacturerCode;

    provider.setBusy(true);
    provider.clearStatus();

    // Show a bottom sheet telling the user to scan
    if (context.mounted) {
      _showScanSheet(context, lang);
    }

    try {
      await NfcService.instance.writeTag(
        materialCode: provider.selectedMaterialCode!,
        colorCode: colorCode,
        manufacturerCode: mfgCode,
      );
      if (context.mounted) Navigator.of(context).pop(); // close sheet
      provider.setStatus(messageKey: 'writeSuccess', isSuccess: true);
    } on NfcException catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      provider.setStatus(
        messageKey: e.messageKey,
        details: e.details,
        isError: true,
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      provider.setStatus(
        messageKey: 'unknownError',
        details: e.toString(),
        isError: true,
      );
    } finally {
      provider.setBusy(false);
    }
  }

  Future<void> _readTag(
      BuildContext context, AppProvider provider, String lang) async {
    provider.setBusy(true);
    provider.clearStatus();

    if (context.mounted) {
      _showScanSheet(context, lang);
    }

    try {
      final tagData = await NfcService.instance.readTag();
      if (context.mounted) Navigator.of(context).pop(); // close sheet
      provider.setLastReadTagData(tagData);
      provider.setStatus(messageKey: 'readSuccess', isSuccess: true);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => TagInfoDialog(
            tagData: tagData,
            materials: provider.materials,
            manufacturers: provider.manufacturers,
            language: lang,
          ),
        );
      }
    } on NfcException catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      provider.setStatus(
        messageKey: e.messageKey,
        details: e.details,
        isError: true,
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      provider.setStatus(
        messageKey: 'unknownError',
        details: e.toString(),
        isError: true,
      );
    } finally {
      provider.setBusy(false);
    }
  }

  /// Shows a bottom sheet instructing the user to hold a tag to the device.
  void _showScanSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScanBottomSheet(lang: lang),
    ).then((_) {
      // If the sheet was dismissed by the user, cancel any active NFC session
      final provider = context.read<AppProvider>();
      if (provider.isBusy) {
        NfcService.instance.cancelSession();
        provider.setBusy(false);
        provider.setStatus(messageKey: 'nfcSessionCancelled');
      }
    });
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────

class _NfcStatusDot extends StatelessWidget {
  final bool available;
  const _NfcStatusDot({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: available ? const Color(0xFF28a745) : const Color(0xFFdc3545),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEAA7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF856404), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFF856404), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MaterialDropdown extends StatelessWidget {
  final String lang;
  const _MaterialDropdown({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sortedEntries = provider.materials.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        return DropdownButtonFormField<int>(
          value: provider.selectedMaterialCode,
          isExpanded: true,
          decoration: _inputDecoration(),
          hint: Text(tr(lang, 'materialPlaceholder')),
          items: [
            ...sortedEntries.map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text('${e.value}  (${e.key})'),
              ),
            ),
          ],
          onChanged: (val) => provider.selectMaterial(val),
        );
      },
    );
  }
}

class _ManufacturerDropdown extends StatelessWidget {
  final String lang;
  const _ManufacturerDropdown({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sortedEntries = provider.manufacturers.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return DropdownButtonFormField<int>(
          value: provider.selectedManufacturerCode,
          isExpanded: true,
          decoration: _inputDecoration(),
          hint: Text(tr(lang, 'manufacturerPlaceholder')),
          items: sortedEntries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.value}  (${e.key})'),
                ),
              )
              .toList(),
          onChanged: (val) => provider.selectManufacturer(val),
        );
      },
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color gradientEnd;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.gradientEnd,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: onPressed != null ? 2 : 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        child: Text(label.toUpperCase()),
      ),
    );
  }
}

class _AutoDetectButton extends StatelessWidget {
  final String lang;
  const _AutoDetectButton({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final active = provider.autoReadActive;
        return TextButton.icon(
          onPressed: () => _toggleAutoRead(context, provider, lang),
          icon: Text(
            active ? '🟢' : '⭕',
            style: const TextStyle(fontSize: 14),
          ),
          label: Text(
            tr(lang, 'auto_detect'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF28a745) : Colors.grey[700],
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor:
                active ? const Color(0xFFD4EDDA) : Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        );
      },
    );
  }

  Future<void> _toggleAutoRead(
      BuildContext context, AppProvider provider, String lang) async {
    final newState = !provider.autoReadActive;
    provider.setAutoReadActive(newState);

    if (newState) {
      // Start continuous read loop
      provider.clearStatus();
      _autoReadLoop(context, provider, lang);
    } else {
      await NfcService.instance.cancelSession();
      provider.clearStatus();
    }
  }

  Future<void> _autoReadLoop(
      BuildContext context, AppProvider provider, String lang) async {
    while (provider.autoReadActive && context.mounted) {
      try {
        provider.setBusy(true);
        final tagData = await NfcService.instance.readTag();
        if (!context.mounted) break;
        provider.setBusy(false);
        provider.setLastReadTagData(tagData);
        provider.setStatus(messageKey: 'readSuccess', isSuccess: true);
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (_) => TagInfoDialog(
              tagData: tagData,
              materials: provider.materials,
              manufacturers: provider.manufacturers,
              language: lang,
            ),
          );
        }
      } on NfcException catch (e) {
        if (!context.mounted) break;
        provider.setBusy(false);
        if (e.messageKey == 'nfcSessionCancelled' ||
            !provider.autoReadActive) break;
        provider.setStatus(messageKey: e.messageKey, isError: true);
        await Future<void>.delayed(const Duration(seconds: 1));
      } catch (_) {
        if (!context.mounted) break;
        provider.setBusy(false);
        if (!provider.autoReadActive) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    if (context.mounted) {
      provider.setBusy(false);
      provider.setAutoReadActive(false);
    }
  }
}

class _StatusMessage extends StatelessWidget {
  final String lang;
  const _StatusMessage({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.statusMessageKey == null) return const SizedBox.shrink();
        final key = provider.statusMessageKey!;
        final text = tr(lang, key);
        final details = provider.statusDetails;
        final full = details != null ? '$text $details' : text;
        final isError = provider.statusIsError;
        final isSuccess = provider.statusIsSuccess;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError
                ? const Color(0xFFF8D7DA)
                : isSuccess
                    ? const Color(0xFFD4EDDA)
                    : const Color(0xFFD1ECF1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isError
                  ? const Color(0xFFF5C6CB)
                  : isSuccess
                      ? const Color(0xFFC3E6CB)
                      : const Color(0xFFBEE5EB),
            ),
          ),
          child: Text(
            full,
            style: TextStyle(
              color: isError
                  ? const Color(0xFF721C24)
                  : isSuccess
                      ? const Color(0xFF155724)
                      : const Color(0xFF0C5460),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}

class _ScanBottomSheet extends StatelessWidget {
  final String lang;
  const _ScanBottomSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nfc, size: 64, color: Color(0xFF667eea)),
          const SizedBox(height: 16),
          Text(
            tr(lang, 'scanTagPrompt'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(lang, 'cancelWarningBtn')),
          ),
        ],
      ),
    );
  }
}
