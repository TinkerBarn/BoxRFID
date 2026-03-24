// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'package:flutter/foundation.dart';
import '../data/defaults.dart';
import '../models/app_settings.dart';
import '../models/tag_data.dart';
import '../services/settings_service.dart';

/// Application-wide state, managed with ChangeNotifier + Provider.
class AppProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  AppSettings get settings => _settings;

  // --- Selection state ---
  int? _selectedMaterialCode;
  int? get selectedMaterialCode => _selectedMaterialCode;

  int? _selectedManufacturerCode;
  int? get selectedManufacturerCode => _selectedManufacturerCode;

  /// Selected color hex (e.g. '#FAFAFA') or null
  String? _selectedColorHex;
  String? get selectedColorHex => _selectedColorHex;

  // --- NFC / operation state ---
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  /// Whether auto-read mode is active
  bool _autoReadActive = false;
  bool get autoReadActive => _autoReadActive;

  /// Latest status/feedback message key (from translations)
  String? _statusMessageKey;
  String? get statusMessageKey => _statusMessageKey;

  /// Auxiliary text appended to the status message (e.g. error details)
  String? _statusDetails;
  String? get statusDetails => _statusDetails;

  bool _statusIsError = false;
  bool get statusIsError => _statusIsError;

  bool _statusIsSuccess = false;
  bool get statusIsSuccess => _statusIsSuccess;

  /// Last successfully read tag data (shown in the tag info popup)
  TagData? _lastReadTagData;
  TagData? get lastReadTagData => _lastReadTagData;

  // Computed: effective materials/manufacturers (user's lists)
  Map<int, String> get materials => _settings.materials;
  Map<int, String> get manufacturers => _settings.manufacturers;
  Map<String, int> get colors => kDefaultColors;

  Future<void> init() async {
    _settings = await SettingsService.instance.load();
    notifyListeners();
  }

  // --- Settings mutations ---

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await SettingsService.instance.save(_settings);
    notifyListeners();
  }

  /// Resets general preferences (language, auto-read, manufacturer toggle)
  /// to their defaults while preserving custom materials and manufacturers.
  Future<void> clearPreferences() async {
    _settings = AppSettings.defaults().copyWith(
      materials: Map<int, String>.from(_settings.materials),
      manufacturers: Map<int, String>.from(_settings.manufacturers),
    );
    await SettingsService.instance.save(_settings);
    notifyListeners();
  }

  /// Resets both materials and manufacturers lists to their defaults.
  /// Preferences (language, auto-read, manufacturer toggle) are preserved.
  Future<void> resetToDefaults() async {
    _settings = _settings.copyWith(
      materials: Map<int, String>.from(kDefaultMaterials),
      manufacturers: Map<int, String>.from(kDefaultManufacturers),
    );
    await SettingsService.instance.save(_settings);
    notifyListeners();
  }

  // --- Selection setters ---

  void selectMaterial(int? code) {
    _selectedMaterialCode = code;
    notifyListeners();
  }

  void selectManufacturer(int? code) {
    _selectedManufacturerCode = code;
    notifyListeners();
  }

  void selectColor(String? hex) {
    _selectedColorHex = hex;
    notifyListeners();
  }

  // --- Status messages ---

  void setStatus({
    required String? messageKey,
    String? details,
    bool isError = false,
    bool isSuccess = false,
  }) {
    _statusMessageKey = messageKey;
    _statusDetails = details;
    _statusIsError = isError;
    _statusIsSuccess = isSuccess;
    notifyListeners();
  }

  void clearStatus() {
    _statusMessageKey = null;
    _statusDetails = null;
    _statusIsError = false;
    _statusIsSuccess = false;
    notifyListeners();
  }

  // --- Tag data ---

  void setLastReadTagData(TagData? data) {
    _lastReadTagData = data;
    notifyListeners();
  }

  // --- Busy state ---

  void setBusy(bool busy) {
    _isBusy = busy;
    notifyListeners();
  }

  // --- Auto-read ---

  void setAutoReadActive(bool active) {
    _autoReadActive = active;
    notifyListeners();
  }
}
