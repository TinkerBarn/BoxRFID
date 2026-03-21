// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/defaults.dart';
import '../data/translations.dart';
import '../models/app_settings.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showManufacturersTab = false;

  @override
  void initState() {
    super.initState();
    _showManufacturersTab =
        context.read<AppProvider>().settings.useManufacturer;
    _tabController = TabController(
      length: _showManufacturersTab ? 4 : 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildTabs(bool showMfg) {
    setState(() {
      _showManufacturersTab = showMfg;
      _tabController.dispose();
      _tabController = TabController(
        length: showMfg ? 4 : 3,
        vsync: this,
      );
    });
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
              tr(lang, 'setupTitle'),
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF667eea),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF667eea),
              indicatorWeight: 3,
              tabs: [
                Tab(text: tr(lang, 'tabLanguage')),
                Tab(text: tr(lang, 'tabMaterials')),
                if (_showManufacturersTab)
                  Tab(text: tr(lang, 'tabManufacturers')),
                Tab(text: tr(lang, 'tabGeneral')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _LanguageTab(lang: lang),
              _MaterialsTab(lang: lang),
              if (_showManufacturersTab) _ManufacturersTab(lang: lang),
              _GeneralTab(
                lang: lang,
                onManufacturerToggled: (val) => _rebuildTabs(val),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Language Tab ─────────────────────────────────────────────────────────

class _LanguageTab extends StatelessWidget {
  final String lang;
  const _LanguageTab({required this.lang});

  static const _languages = [
    ('de', '🇩🇪 Deutsch'),
    ('en', '🇺🇸 English'),
    ('es', '🇪🇸 Español'),
    ('pt', '🇵🇹 Português'),
    ('fr', '🇫🇷 Français'),
    ('zh', '🇨🇳 中文 (简体)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              tr(lang, 'languageSelectLabel'),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            ..._languages.map((l) {
              final isSelected = provider.settings.language == l.$1;
              return RadioListTile<String>(
                value: l.$1,
                groupValue: provider.settings.language,
                title: Text(l.$2),
                activeColor: const Color(0xFF667eea),
                selected: isSelected,
                onChanged: (val) async {
                  if (val == null) return;
                  await provider.updateSettings(
                      provider.settings.copyWith(language: val));
                },
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Materials Tab ─────────────────────────────────────────────────────────

class _MaterialsTab extends StatefulWidget {
  final String lang;
  const _MaterialsTab({required this.lang});

  @override
  State<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<_MaterialsTab> {
  int? _editingCode;
  bool _isAdding = false;
  final _nameController = TextEditingController();
  int? _selectedCode;
  bool _showWarning = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startAdd() {
    setState(() {
      _isAdding = true;
      _editingCode = null;
      _nameController.clear();
      _selectedCode = null;
      _showWarning = false;
    });
  }

  void _startEdit(int code, String name, bool isStandard) {
    if (isStandard) {
      setState(() {
        _showWarning = true;
        _editingCode = code;
      });
      return;
    }
    _doEdit(code, name);
  }

  void _doEdit(int code, String name) {
    setState(() {
      _isAdding = true;
      _editingCode = code;
      _nameController.text = name;
      _selectedCode = code;
      _showWarning = false;
    });
  }

  void _cancel() {
    setState(() {
      _isAdding = false;
      _editingCode = null;
      _showWarning = false;
    });
  }

  Future<void> _save(AppProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCode == null) return;
    final updated = Map<int, String>.from(provider.settings.materials);
    updated[_selectedCode!] = name;
    await provider.updateSettings(
        provider.settings.copyWith(materials: updated));
    _cancel();
  }

  Future<void> _delete(AppProvider provider, int code, bool isStandard) async {
    if (isStandard) {
      final confirmed = await _showConfirmDialog(
        context,
        title: tr(widget.lang, 'deleteConfirm'),
        message: tr(widget.lang, 'deleteWarning'),
        confirmLabel: tr(widget.lang, 'confirmMaterialWarningBtn'),
        cancelLabel: tr(widget.lang, 'cancelMaterialWarningBtn'),
      );
      if (confirmed != true) return;
    }
    final updated = Map<int, String>.from(provider.settings.materials);
    updated.remove(code);
    await provider.updateSettings(
        provider.settings.copyWith(materials: updated));
  }

  Future<void> _reset(AppProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: tr(widget.lang, 'resetMaterialsBtn'),
      message: tr(widget.lang, 'resetConfirm'),
      confirmLabel: tr(widget.lang, 'confirmMaterialWarningBtn'),
      cancelLabel: tr(widget.lang, 'cancelMaterialWarningBtn'),
    );
    if (confirmed != true) return;
    await provider.updateSettings(provider.settings.copyWith(
      materials: Map<int, String>.from(kDefaultMaterials),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sortedEntries = provider.settings.materials.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr(lang, 'materialsListLabel'),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF555555))),
            const SizedBox(height: 8),
            // Materials list
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: sortedEntries.map((e) {
                  final isStandard = kDefaultMaterials.containsKey(e.key);
                  return _MaterialItem(
                    code: e.key,
                    name: e.value,
                    isStandard: isStandard,
                    lang: lang,
                    onEdit: () => _startEdit(e.key, e.value, isStandard),
                    onDelete: () => _delete(provider, e.key, isStandard),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Warning for standard material edit
            if (_showWarning)
              _WarningBox(
                title: tr(lang, 'warningTitle'),
                message: tr(lang, 'warningText'),
                onConfirm: () {
                  final code = _editingCode!;
                  final name = provider.settings.materials[code] ?? '';
                  _doEdit(code, name);
                },
                onCancel: () => setState(() => _showWarning = false),
                confirmLabel: tr(lang, 'confirmMaterialWarningBtn'),
                cancelLabel: tr(lang, 'cancelMaterialWarningBtn'),
              ),
            // Add/edit form
            if (_isAdding) ...[
              const SizedBox(height: 12),
              Text(tr(lang, 'materialFormTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: tr(lang, 'materialNamePlaceholder'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CodeDropdown(
                      allCodes: kAllMaterialCodes,
                      usedCodes: _editingCode != null
                          ? provider.settings.materials.keys
                              .where((c) => c != _editingCode)
                              .toSet()
                          : provider.settings.materials.keys.toSet(),
                      selectedCode: _selectedCode,
                      hint: tr(lang, 'codeSelectPlaceholder'),
                      onChanged: (val) => setState(() => _selectedCode = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _save(provider),
                    style: _greenBtnStyle(),
                    child: Text(tr(lang, 'saveMaterialBtn')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _cancel,
                    style: _redBtnStyle(),
                    child: Text(tr(lang, 'cancelMaterialBtn')),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (!_isAdding)
              ElevatedButton(
                onPressed: _startAdd,
                style: _greenBtnStyle(),
                child: Text(tr(lang, 'addMaterialBtn')),
              ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () => _reset(provider),
              style: _purpleBtnStyle(),
              child: Text(tr(lang, 'resetMaterialsBtn')),
            ),
          ],
        );
      },
    );
  }
}

// ─── Manufacturers Tab ─────────────────────────────────────────────────────

class _ManufacturersTab extends StatefulWidget {
  final String lang;
  const _ManufacturersTab({required this.lang});

  @override
  State<_ManufacturersTab> createState() => _ManufacturersTabState();
}

class _ManufacturersTabState extends State<_ManufacturersTab> {
  int? _editingCode;
  bool _isAdding = false;
  final _nameController = TextEditingController();
  int? _selectedCode;
  bool _showWarning = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startAdd() {
    setState(() {
      _isAdding = true;
      _editingCode = null;
      _nameController.clear();
      _selectedCode = null;
      _showWarning = false;
    });
  }

  void _startEdit(int code, String name, bool isStandard) {
    if (isStandard) {
      setState(() {
        _showWarning = true;
        _editingCode = code;
      });
      return;
    }
    _doEdit(code, name);
  }

  void _doEdit(int code, String name) {
    setState(() {
      _isAdding = true;
      _editingCode = code;
      _nameController.text = name;
      _selectedCode = code;
      _showWarning = false;
    });
  }

  void _cancel() {
    setState(() {
      _isAdding = false;
      _editingCode = null;
      _showWarning = false;
    });
  }

  Future<void> _save(AppProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCode == null) return;
    final updated = Map<int, String>.from(provider.settings.manufacturers);
    updated[_selectedCode!] = name;
    await provider.updateSettings(
        provider.settings.copyWith(manufacturers: updated));
    _cancel();
  }

  Future<void> _delete(AppProvider provider, int code, bool isStandard) async {
    if (isStandard) {
      final confirmed = await _showConfirmDialog(
        context,
        title: tr(widget.lang, 'deleteConfirm'),
        message: tr(widget.lang, 'deleteWarning'),
        confirmLabel: tr(widget.lang, 'confirmManufacturerWarningBtn'),
        cancelLabel: tr(widget.lang, 'cancelManufacturerWarningBtn'),
      );
      if (confirmed != true) return;
    }
    final updated = Map<int, String>.from(provider.settings.manufacturers);
    updated.remove(code);
    await provider.updateSettings(
        provider.settings.copyWith(manufacturers: updated));
  }

  Future<void> _reset(AppProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: tr(widget.lang, 'resetManufacturersBtn'),
      message: tr(widget.lang, 'resetConfirm'),
      confirmLabel: tr(widget.lang, 'confirmManufacturerWarningBtn'),
      cancelLabel: tr(widget.lang, 'cancelManufacturerWarningBtn'),
    );
    if (confirmed != true) return;
    await provider.updateSettings(provider.settings.copyWith(
      manufacturers: Map<int, String>.from(kDefaultManufacturers),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sortedEntries = provider.settings.manufacturers.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr(lang, 'manufacturersListLabel'),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF555555))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: sortedEntries.map((e) {
                  final isStandard = kDefaultManufacturers.containsKey(e.key);
                  return _MaterialItem(
                    code: e.key,
                    name: e.value,
                    isStandard: isStandard,
                    lang: lang,
                    onEdit: () => _startEdit(e.key, e.value, isStandard),
                    onDelete: () => _delete(provider, e.key, isStandard),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            if (_showWarning)
              _WarningBox(
                title: tr(lang, 'manufacturerWarningTitle'),
                message: tr(lang, 'manufacturerWarningText'),
                onConfirm: () {
                  final code = _editingCode!;
                  final name = provider.settings.manufacturers[code] ?? '';
                  _doEdit(code, name);
                },
                onCancel: () => setState(() => _showWarning = false),
                confirmLabel: tr(lang, 'confirmManufacturerWarningBtn'),
                cancelLabel: tr(lang, 'cancelManufacturerWarningBtn'),
              ),
            if (_isAdding) ...[
              const SizedBox(height: 12),
              Text(tr(lang, 'manufacturerFormTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: tr(lang, 'manufacturerNamePlaceholder'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CodeDropdown(
                      allCodes: kAllManufacturerCodes,
                      usedCodes: _editingCode != null
                          ? provider.settings.manufacturers.keys
                              .where((c) => c != _editingCode)
                              .toSet()
                          : provider.settings.manufacturers.keys.toSet(),
                      selectedCode: _selectedCode,
                      hint: tr(lang, 'codeSelectPlaceholder'),
                      onChanged: (val) => setState(() => _selectedCode = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _save(provider),
                    style: _greenBtnStyle(),
                    child: Text(tr(lang, 'saveManufacturerBtn')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _cancel,
                    style: _redBtnStyle(),
                    child: Text(tr(lang, 'cancelManufacturerBtn')),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (!_isAdding)
              ElevatedButton(
                onPressed: _startAdd,
                style: _greenBtnStyle(),
                child: Text(tr(lang, 'addManufacturerBtn')),
              ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () => _reset(provider),
              style: _purpleBtnStyle(),
              child: Text(tr(lang, 'resetManufacturersBtn')),
            ),
          ],
        );
      },
    );
  }
}

// ─── General Tab ───────────────────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  final String lang;
  final ValueChanged<bool> onManufacturerToggled;
  const _GeneralTab({
    required this.lang,
    required this.onManufacturerToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Use manufacturer toggle
            SwitchListTile(
              value: provider.settings.useManufacturer,
              activeColor: const Color(0xFF667eea),
              title: Text(tr(lang, 'manufacturerUseLabel')),
              onChanged: (val) async {
                if (val) {
                  final confirmed = await _showConfirmDialog(
                    context,
                    title: tr(lang, 'manufacturerUseLabel'),
                    message: tr(lang, 'manufacturerConfirm'),
                    confirmLabel: tr(lang, 'confirmWarningBtn'),
                    cancelLabel: tr(lang, 'cancelWarningBtn'),
                  );
                  if (confirmed != true) return;
                }
                await provider.updateSettings(
                    provider.settings.copyWith(useManufacturer: val));
                onManufacturerToggled(val);
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1ECF1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBEE5EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ℹ️'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(lang, 'manufacturerInfoText'),
                      style: const TextStyle(
                          color: Color(0xFF0C5460), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Clear preferences
            ElevatedButton(
              onPressed: () => _clearPrefs(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C757D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(tr(lang, 'clearPrefsBtn')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearPrefs(BuildContext context, AppProvider provider) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: tr(lang, 'clearPrefsTitle'),
      message: tr(lang, 'clearPrefsMessage'),
      confirmLabel: tr(lang, 'confirmWarningBtn'),
      cancelLabel: tr(lang, 'cancelWarningBtn'),
    );
    if (confirmed != true) return;
    await provider.clearPreferences();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(lang, 'clearPrefsSuccess'))),
      );
    }
  }
}

// ─── Shared helpers ─────────────────────────────────────────────────────────

class _MaterialItem extends StatelessWidget {
  final int code;
  final String name;
  final bool isStandard;
  final String lang;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialItem({
    required this.code,
    required this.name,
    required this.isStandard,
    required this.lang,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListTile(
        dense: true,
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('Code: $code',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'monospace')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmallBtn(
              label: '✏️',
              color: const Color(0xFFFFC107),
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            _SmallBtn(
              label: '🗑️',
              color: const Color(0xFFDC3545),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SmallBtn({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _WarningBox({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEAA7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF856404), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(color: Color(0xFF856404), fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: onConfirm,
                style: _redBtnStyle(),
                child: Text(confirmLabel,
                    style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onCancel,
                style: _greenBtnStyle(),
                child: Text(cancelLabel,
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeDropdown extends StatelessWidget {
  final List<int> allCodes;
  final Set<int> usedCodes;
  final int? selectedCode;
  final String hint;
  final ValueChanged<int?> onChanged;

  const _CodeDropdown({
    required this.allCodes,
    required this.usedCodes,
    required this.selectedCode,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final available = allCodes
        .where((c) => !usedCodes.contains(c) || c == selectedCode)
        .toList();
    return DropdownButtonFormField<int>(
      value: selectedCode,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: hint,
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 12)),
      items: available
          .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
          .toList(),
      onChanged: onChanged,
    );
  }
}

Future<bool?> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: _redBtnStyle(),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

ButtonStyle _greenBtnStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF28a745),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

ButtonStyle _redBtnStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFDC3545),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

ButtonStyle _purpleBtnStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6F42C1),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
