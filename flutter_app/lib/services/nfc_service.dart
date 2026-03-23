// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import '../data/defaults.dart';
import '../models/tag_data.dart';

/// Custom exceptions for NFC operations.
class NfcException implements Exception {
  final String messageKey;
  final String? details;
  const NfcException(this.messageKey, [this.details]);
  @override
  String toString() =>
      'NfcException($messageKey${details != null ? ': $details' : ''})';
}

/// Handles all NFC / MIFARE Classic operations.
///
/// The QIDI Box uses MIFARE Classic 1K tags with:
///   - Block 4 (sector 1) for filament data
///   - Key D3:F7:D3:F7:D3:F7 (vendor key) or FF:FF:FF:FF:FF:FF (default key)
class NfcService {
  NfcService._();
  static final NfcService instance = NfcService._();

  /// Active completer for the current NFC session.
  _Cancelable? _activeCompleter;

  /// Check whether NFC hardware is available on this device.
  Future<bool> isAvailable() async {
    return NfcManager.instance.isAvailable();
  }

  /// Read filament data from a MIFARE Classic tag.
  ///
  /// Starts an NFC session, waits for a tag, authenticates sector 1,
  /// reads block 4, and returns the decoded [TagData].
  ///
  /// Throws [NfcException] on failure.
  Future<TagData> readTag() async {
    final completer = _TagCompleter<TagData>();
    _activeCompleter = completer;
    bool tagHandled = false;

    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (tagHandled) return;
      tagHandled = true;
      try {
        final mifareClassic = MifareClassic.from(tag);
        if (mifareClassic == null) {
          completer.completeError(const NfcException('nfcNotMifareClassic'));
          await NfcManager.instance.stopSession(
              errorMessage: 'Not a MIFARE Classic tag');
          return;
        }

        // Try authentication with each key in order
        bool authenticated = false;
        for (final key in kMifareAuthKeys) {
          try {
            final ok = await mifareClassic.authenticateSectorWithKeyA(
              sectorIndex: kTagDataSector,
              key: Uint8List.fromList(key),
            );
            if (ok) {
              authenticated = true;
              break;
            }
          } catch (authError) {
            // Try next key – auth with this key failed
            assert(() {
              debugPrint('[NfcService] Auth key ${key.map((b) => b.toRadixString(16)).join(':')} failed: $authError');
              return true;
            }());
          }
        }

        if (!authenticated) {
          completer.completeError(const NfcException('nfcAuthFailed'));
          await NfcManager.instance.stopSession(
              errorMessage: 'Authentication failed');
          return;
        }

        final blockData =
            await mifareClassic.readBlock(blockIndex: kTagDataBlock);
        final tagData = TagData.fromBytes(blockData.toList());
        completer.complete(tagData);
        await NfcManager.instance.stopSession();
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e is NfcException
              ? e
              : NfcException('unknownError', e.toString()));
        }
        await NfcManager.instance.stopSession(errorMessage: e.toString());
      } finally {
        _activeCompleter = null;
      }
    });

    return completer.future;
  }

  /// Write filament data to a MIFARE Classic tag.
  ///
  /// Starts an NFC session, waits for a tag, authenticates sector 1,
  /// and writes [materialCode], [colorCode], [manufacturerCode] to block 4.
  ///
  /// Throws [NfcException] on failure.
  Future<void> writeTag({
    required int materialCode,
    required int colorCode,
    required int manufacturerCode,
  }) async {
    final completer = _TagCompleter<void>();
    _activeCompleter = completer;
    bool tagHandled = false;

    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (tagHandled) return;
      tagHandled = true;
      try {
        final mifareClassic = MifareClassic.from(tag);
        if (mifareClassic == null) {
          completer.completeError(const NfcException('nfcNotMifareClassic'));
          await NfcManager.instance.stopSession(
              errorMessage: 'Not a MIFARE Classic tag');
          return;
        }

        // Try authentication with each key in order
        bool authenticated = false;
        for (final key in kMifareAuthKeys) {
          try {
            final ok = await mifareClassic.authenticateSectorWithKeyA(
              sectorIndex: kTagDataSector,
              key: Uint8List.fromList(key),
            );
            if (ok) {
              authenticated = true;
              break;
            }
          } catch (authError) {
            // Try next key – auth with this key failed
            assert(() {
              debugPrint('[NfcService] Auth key ${key.map((b) => b.toRadixString(16)).join(':')} failed: $authError');
              return true;
            }());
          }
        }

        if (!authenticated) {
          completer.completeError(const NfcException('nfcAuthFailed'));
          await NfcManager.instance.stopSession(
              errorMessage: 'Authentication failed');
          return;
        }

        // Build 16-byte block: [material, color, manufacturer, 0, ..., 0]
        final buf = Uint8List(16);
        buf[0] = materialCode & 0xFF;
        buf[1] = colorCode & 0xFF;
        buf[2] = manufacturerCode & 0xFF;
        // bytes 3–15 remain zero

        await mifareClassic.writeBlock(blockIndex: kTagDataBlock, data: buf);
        completer.complete(null);
        await NfcManager.instance.stopSession();
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e is NfcException
              ? e
              : NfcException('unknownError', e.toString()));
        }
        await NfcManager.instance.stopSession(errorMessage: e.toString());
      } finally {
        _activeCompleter = null;
      }
    });

    return completer.future;
  }

  /// Cancel any active NFC session.
  /// The pending read/write future will complete with a cancellation error.
  Future<void> cancelSession() async {
    // Signal the active completer (if any) that the session was cancelled
    _activeCompleter?.cancel();
    _activeCompleter = null;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}

/// A single-use completer that guards against completing twice.
class _TagCompleter<T> implements _Cancelable {
  final _completer = Completer<T>();
  bool get isCompleted => _completer.isCompleted;
  Future<T> get future => _completer.future;

  void complete(T value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) _completer.completeError(error);
  }

  @override
  void cancel() =>
      completeError(const NfcException('nfcSessionCancelled'));
}

/// Shared cancellation interface for active NFC completers.
abstract class _Cancelable {
  void cancel();
}
