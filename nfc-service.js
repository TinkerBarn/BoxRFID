/**
 * BoxRFID – Filament Tag Manager
 *
 * Author: Tinkerbarn
 * License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)
 */

const { NFC } = require('nfc-pcsc');

class NFCService {
  constructor() {
    this.nfc = new NFC();
    this.isConnected = false;
    this.currentReader = null;
    this.lastUID = null;
    this.lastError = null;
    this.lastErrorCode = null;
    this.lastErrorAt = null;
    this._busy = false;

    this._init();
  }

  _setError(err) {
    if (!err) {
      this.lastError = null;
      this.lastErrorCode = null;
      this.lastErrorAt = null;
      return;
    }
    const msg = err && err.message ? String(err.message) : String(err);
    this.lastError = msg;
    const upper = msg.toUpperCase();
    if (upper.includes('SCARD_E_NO_SERVICE') || upper.includes('SERVICE NOT RUNNING')) {
      this.lastErrorCode = 'PCSC_SERVICE_NOT_RUNNING';
    } else if (upper.includes('SCARD_E_NO_READERS_AVAILABLE') || upper.includes('NO READERS AVAILABLE')) {
      this.lastErrorCode = 'NO_READERS';
    } else {
      this.lastErrorCode = 'UNKNOWN';
    }
    this.lastErrorAt = Date.now();
  }

  _init() {
    this.nfc.on('reader', (reader) => {
      this.currentReader = reader;
      this.isConnected = true;
      this._setError(null);

      reader.on('card', (card) => {
        this.lastUID = card?.uid || null;
        reader.card = card;
      });

      reader.on('card.off', () => {
        this.lastUID = null;
        reader.card = null;
      });

      reader.on('error', (err) => {
        this._setError(err);
      });
      reader.on('end', () => {
        this.isConnected = false;
        this.currentReader = null;
        this.lastUID = null;
      });
    });

    this.nfc.on('error', (err) => {
      this.isConnected = false;
      this.currentReader = null;
      this.lastUID = null;
      this._setError(err);
    });
  }

  getCurrentUID() { return this.lastUID || null; }

  async _withLock(fn) {
    if (this._busy) throw new Error('Busy');
    this._busy = true;
    try { return await fn(); } finally { this._busy = false; }
  }

  // key sequence: Vendor (D3 F7 ...) then standard (FF ...)
  async _authenticateBlock(block = 4) {
    if (!this.currentReader) throw new Error('NFC_NOT_CONNECTED');
    const reader = this.currentReader;
    const KEY_TYPE_A = reader.KEY_TYPE_A || 0x60;
    const keys = [
      Buffer.from([0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7]),
      Buffer.from([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
    ];
    let lastErr = null;
    for (const key of keys) {
      try {
        await reader.authenticate(block, KEY_TYPE_A, key);
        return true;
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr || new Error('NFC_AUTH_FAILED');
  }

  async readTag() {
    if (!this.currentReader) throw new Error('NFC_NOT_CONNECTED');
    return this._withLock(async () => {
      await this._authenticateBlock(4);
      const data = await this.currentReader.read(4, 16, 16);
      const material = data[0] || 0;
      const color = data[1] || 0;
      const manufacturer = data[2] || 1;
      return { material, color, manufacturer, rawData: Array.from(data) };
    });
  }

  async writeTag(materialCode, colorCode, manufacturerCode = 1) {
    if (!this.currentReader) throw new Error('NFC_NOT_CONNECTED');
    return this._withLock(async () => {
      await this._authenticateBlock(4);
      const buf = Buffer.alloc(16, 0x00);
      buf[0] = Number(materialCode) || 0;
      buf[1] = Number(colorCode) || 0;
      buf[2] = Number(manufacturerCode) || 1;
      await this.currentReader.write(4, buf, 16);
      return true;
    });
  }

  getStatus() {
    return {
      connected: this.isConnected,
      readerName: this.currentReader ? this.currentReader.reader.name : null,
      cardPresent: !!(this.currentReader && this.currentReader.card),
      uid: this.lastUID,
      errorCode: this.lastErrorCode,
      errorMessage: this.lastError,
      errorAt: this.lastErrorAt
    };
  }
}

module.exports = NFCService;
