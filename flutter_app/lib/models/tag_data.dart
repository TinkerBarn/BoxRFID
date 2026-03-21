// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

/// Data read from or to be written to a MIFARE Classic RFID tag.
/// The QIDI Box stores filament metadata in block 4:
///   byte[0] = materialCode
///   byte[1] = colorCode
///   byte[2] = manufacturerCode
///   bytes[3..15] = reserved / zeros
class TagData {
  final int materialCode;
  final int colorCode;
  final int manufacturerCode;
  final List<int> rawBytes;

  const TagData({
    required this.materialCode,
    required this.colorCode,
    required this.manufacturerCode,
    required this.rawBytes,
  });

  factory TagData.fromBytes(List<int> bytes) {
    return TagData(
      materialCode: bytes.isNotEmpty ? bytes[0] : 0,
      colorCode: bytes.length > 1 ? bytes[1] : 0,
      manufacturerCode: bytes.length > 2 ? bytes[2] : 1,
      rawBytes: List<int>.unmodifiable(bytes),
    );
  }

  @override
  String toString() =>
      'TagData(material: $materialCode, color: $colorCode, manufacturer: $manufacturerCode)';
}
