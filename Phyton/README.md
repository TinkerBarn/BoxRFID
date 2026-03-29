# BoxRFID – Python Alternative

This folder contains a very simple Python-based alternative to the main Electron version of **BoxRFID Manager**.

It was created for users who experience problems starting the Electron application on Windows systems.

## Purpose

The Python version is intended as a minimal fallback solution for writing QIDI Box NFC tags with an **ACR122U USB reader/writer**.

It is deliberately limited and is **not** meant to replace the full Electron application.

## Included files

- Source code: `source/box-rfid-V1.0.py`
- Windows executable: `BoxRFID Manager.exe`

## Supported hardware

- **NFC reader/writer:** ACR122U USB
- **Tags:** MIFARE Classic 1K tags compatible with QIDI Box

## Supported languages

- German
- English

No other languages are included in this version.

## Functional limitations

This Python version has the following fixed limitations:

- Only the **standard material list** based on **QIDI Plus 4 firmware V1.7.0** is supported
- Only the **colors available in firmware V1.7.0** can be selected
- The **material list cannot be edited or extended**
- The **manufacturer list cannot be edited or extended**
- This version is intended only for **ACR122U USB** usage

## Important notice

I provide this version only as a simple alternative for users who cannot run the Electron app.

### No support / no further development
- I do **not provide support** for this Python version
- I do **not plan to add features or improvements**
- I do **not plan to maintain or expand** it further

If someone wants to improve, modify, or extend it, please use the included source code and adapt it as needed.

## Use at your own responsibility

This software is provided as-is.  
Please verify your written tag data before relying on it in productive use.

## License

Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).
