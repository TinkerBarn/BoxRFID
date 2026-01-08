/**
 * BoxRFID – Filament Tag Manager
 *
 * Author: Tinkerbarn
 * License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)
 */

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // RFID operations
  writeTag: (data) => ipcRenderer.invoke('rfid-write', data),
  readTag: () => ipcRenderer.invoke('rfid-read'),
  getStatus: () => ipcRenderer.invoke('rfid-status'),
  setAutoRead: (enable) => ipcRenderer.invoke('rfid-auto', { enable }),

  // Auto-read status stream
  onAutoStatus: (callback) => {
    ipcRenderer.removeAllListeners('rfid-auto-status');
    ipcRenderer.on('rfid-auto-status', (_event, status) => callback(status));
  },

  // File dialog and file system (for official cfg)
  openFileDialog: (options = {}) => ipcRenderer.invoke('dialog:openFile', options),
  readFile: (path, encoding = 'utf8') => ipcRenderer.invoke('fs:readFile', { path, encoding }),
  exists: (path) => ipcRenderer.invoke('fs:exists', { path }),

  // System info
  platform: process.platform,

  // Window controls
  minimizeWindow: () => ipcRenderer.invoke('minimize-window'),
  maximizeWindow: () => ipcRenderer.invoke('maximize-window'),
  closeWindow: () => ipcRenderer.invoke('close-window')
});

// Security: remove Node.js globals from renderer
try {
  delete window.require;
  delete window.exports;
  delete window.module;
} catch {}