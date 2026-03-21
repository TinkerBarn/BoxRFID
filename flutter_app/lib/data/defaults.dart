// BoxRFID – Filament Tag Manager
//
// Author: Tinkerbarn
// License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)

/// Default materials map: code -> name
const Map<int, String> kDefaultMaterials = {
  1: 'PLA',
  2: 'PLA Matte',
  3: 'PLA Metal',
  4: 'PLA Silk',
  5: 'PLA-CF',
  6: 'PLA-Wood',
  7: 'PLA Basic',
  8: 'PLA Matte Basic',
  11: 'ABS',
  12: 'ABS-GF',
  13: 'ABS-Metal',
  14: 'ABS-Odorless',
  18: 'ASA',
  19: 'ASA-AERO',
  24: 'UltraPA',
  25: 'PA12-CF',
  26: 'UltraPA-CF25',
  30: 'PAHT-CF',
  31: 'PAHT-GF',
  32: 'Support For PAHT',
  33: 'Support For PET/PA',
  34: 'PC/ABS-FR',
  37: 'PET-CF',
  38: 'PET-GF',
  39: 'PETG Basic',
  40: 'PETG-Though',
  41: 'PETG',
  44: 'PPS-CF',
  45: 'PETG Translucent',
  47: 'PVA',
  49: 'TPU-AERO',
  50: 'TPU',
};

/// Default manufacturers map: code -> name
const Map<int, String> kDefaultManufacturers = {
  0: 'Generic',
  1: 'QIDI',
};

/// Default colors map: hex -> code
/// Colors defined by the QIDI Box RFID tag spec
const Map<String, int> kDefaultColors = {
  '#FAFAFA': 1,
  '#060606': 2,
  '#D9E3ED': 3,
  '#5CF30F': 4,
  '#63E492': 5,
  '#2850FF': 6,
  '#FE98FE': 7,
  '#DFD628': 8,
  '#228332': 9,
  '#99DEFF': 10,
  '#1714B0': 11,
  '#CEC0FE': 12,
  '#CADE4B': 13,
  '#1353AB': 14,
  '#5EA9FD': 15,
  '#A878FF': 16,
  '#FE717A': 17,
  '#FF362D': 18,
  '#E2DFCD': 19,
  '#898F9B': 20,
  '#6E3812': 21,
  '#CAC59F': 22,
  '#F28636': 23,
  '#B87F2B': 24,
};

/// All available material codes (1–255), used for the code picker
const List<int> kAllMaterialCodes = [
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
  51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
  61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
  71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
  81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
  91, 92, 93, 94, 95, 96, 97, 98, 99, 100,
  101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
  111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
  121, 122, 123, 124, 125, 126, 127, 128, 129, 130,
  131, 132, 133, 134, 135, 136, 137, 138, 139, 140,
  141, 142, 143, 144, 145, 146, 147, 148, 149, 150,
  151, 152, 153, 154, 155, 156, 157, 158, 159, 160,
  161, 162, 163, 164, 165, 166, 167, 168, 169, 170,
  171, 172, 173, 174, 175, 176, 177, 178, 179, 180,
  181, 182, 183, 184, 185, 186, 187, 188, 189, 190,
  191, 192, 193, 194, 195, 196, 197, 198, 199, 200,
  201, 202, 203, 204, 205, 206, 207, 208, 209, 210,
  211, 212, 213, 214, 215, 216, 217, 218, 219, 220,
  221, 222, 223, 224, 225, 226, 227, 228, 229, 230,
  231, 232, 233, 234, 235, 236, 237, 238, 239, 240,
  241, 242, 243, 244, 245, 246, 247, 248, 249, 250,
  251, 252, 253, 254, 255,
];

/// Default manufacturer code used when "Use Manufacturer" is disabled.
const int kDefaultManufacturerCode = 1; // QIDI

/// All available manufacturer codes (0–20)
const List<int> kAllManufacturerCodes = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
];

/// MIFARE Classic authentication keys used by QIDI Box
/// Tried in order: vendor key first, then default key
final List<List<int>> kMifareAuthKeys = [
  [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7], // QIDI/vendor key
  [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], // Default MIFARE key
];

/// Block number where filament data is stored on the MIFARE Classic tag
const int kTagDataBlock = 4;

/// Sector index for block 4 (blocks 4–7 are in sector 1)
const int kTagDataSector = 1;
