/**
 * BoxRFID – Filament Tag Manager
 *
 * Author: Tinkerbarn
 * License: CC BY-NC-SA 4.0 (SPDX-License-Identifier: CC-BY-NC-SA-4.0)
 */

const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const fsp = fs.promises;
// Workaround for some Windows setups (AV / Controlled Folder Access) that can block Chromium cache writes.
// This reduces noisy "Unable to create cache" errors and can help avoid rare startup issues.
app.commandLine.appendSwitch('disable-gpu-shader-disk-cache');
// Force Chromium disk cache into Electron userData to avoid restricted locations on some systems.
app.commandLine.appendSwitch('disk-cache-dir', path.join(app.getPath('userData'), 'cache'));

let mainWindow;

// NFC is expensive / can block on some Windows systems if no PC/SC service/driver is present.
// To keep startup fast and always show the UI, we lazy-load the NFC module only when required.
let NFCServiceCtor = null;
let nfcService = null;
let nfcInitFailedAt = 0;
let nfcInitLastErr = null;
const NFC_RETRY_AFTER_MS = 5000;

function tryGetNfcService() {
  return nfcService;
}

function getNfcService(options = {}) {
  if (nfcService) return nfcService;

  const forceRetry = !!options.forceRetry;
  const now = Date.now();
  if (!forceRetry && nfcInitFailedAt && (now - nfcInitFailedAt) < NFC_RETRY_AFTER_MS) {
    // Avoid repeated costly init attempts in a tight loop.
    throw new Error('NFC_NOT_CONNECTED');
  }

  try {
    if (!NFCServiceCtor) NFCServiceCtor = require('./nfc-service');
    nfcService = new NFCServiceCtor();
    nfcInitFailedAt = 0;
    nfcInitLastErr = null;
    return nfcService;
  } catch (e) {
    nfcService = null;
    nfcInitFailedAt = now;
    nfcInitLastErr = e;
    console.error('NFC init failed:', e && e.message ? e.message : e);
    throw new Error('NFC_NOT_CONNECTED');
  }
}
let isBusy = false;

function toMessageKey(err) {
  const msg = (err && err.message) ? String(err.message) : String(err || '');
  switch (msg) {
    case 'Busy':
      return 'busy';
    case 'NFC_NOT_CONNECTED':
      return 'nfcNotConnected';
    case 'NFC_AUTH_FAILED':
      return 'nfcAuthFailed';
    default:
      return 'unknownError';
  }
}


// Auto-read state
let autoEnabled = false;
let autoLoop = null;
let lastAutoUID = null;

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 600,
    height: 800,
    minWidth: 600,                 // min width 600
    minHeight: 800,                // min height 800
    backgroundColor: '#ffffff',    // white background
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: process.platform === 'win32'
    ? path.join(__dirname, 'assets', 'icon.ico')  // Windows: .ico
    : path.join(__dirname, 'assets', 'icon.png'), // Linux/macOS: .png
    title: 'QIDI RFID Tag Writer/Reader',
    show: false,
    autoHideMenuBar: true
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));
const SHOW_TIMEOUT_MS = 3000;
const showWindow = () => {
  if (mainWindow && !mainWindow.isDestroyed() && !mainWindow.isVisible()) {
    mainWindow.show();
  }
};

mainWindow.once('ready-to-show', () => {
  showWindow();

  // Optional: initialize NFC after UI is visible, so the connection indicator can turn green quickly
  // without risking a "headless" startup on systems where PC/SC init blocks.
  setTimeout(() => {
    try { getNfcService({ forceRetry: false }); } catch {}
  }, 800);
});

// Fallback: if ready-to-show never fires, still show a window so users don't see only a Task Manager entry.
setTimeout(showWindow, SHOW_TIMEOUT_MS);


  // If the renderer fails to load, the window may never become visible.
  // Log the error and show the window as a fallback so users don't end up with a "headless" process.
  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL) => {
    console.error('did-fail-load', { errorCode, errorDescription, validatedURL });
    if (!mainWindow.isVisible()) mainWindow.show();
  });

  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => { mainWindow = null; });
}

function sendAutoStatus(payload) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('rfid-auto-status', payload);
  }
}

function startAutoLoop() {
  if (autoLoop) return;
  autoLoop = setInterval(async () => {
    try {
      if (!autoEnabled) return;
      if (isBusy) return;

      const svc = tryGetNfcService();
      if (!svc) return;
      const uid = svc.getCurrentUID();
      if (uid && uid !== lastAutoUID) {
        // New tag appeared or changed
        isBusy = true;
        try {
          const data = await svc.readTag();
          lastAutoUID = uid;
          sendAutoStatus({ present: true, tagData: data, error: null });
        } catch (err) {
          sendAutoStatus({ present: true, tagData: null, error: err.message || String(err) });
        } finally {
          isBusy = false;
        }
      } else if (!uid && lastAutoUID) {
        // Tag removed
        lastAutoUID = null;
        sendAutoStatus({ present: false, tagData: null, error: null });
      }
    } catch (err) {
      // On unexpected error, mark as not present
      lastAutoUID = null;
      sendAutoStatus({ present: false, tagData: null, error: err.message || String(err) });
    }
  }, 200); // fast, responsive
}

function stopAutoLoop() {
  if (autoLoop) {
    clearInterval(autoLoop);
    autoLoop = null;
  }
  lastAutoUID = null;
}

// IPC handlers: RFID
ipcMain.handle('rfid-write', async (_event, { materialCode, colorCode, manufacturerCode }) => {
  if (isBusy) return { success: false, messageKey: 'busy' };
  isBusy = true;
  try {
    await getNfcService({ forceRetry: true }).writeTag(
      parseInt(materialCode, 10),
      parseInt(colorCode, 10),
      parseInt(manufacturerCode || 1, 10)
    );
    return { success: true };
  } catch (err) {
    return { success: false, messageKey: toMessageKey(err), details: err && err.message ? String(err.message) : String(err) };
  } finally {
    isBusy = false;
  }
});

ipcMain.handle('rfid-read', async () => {
  if (isBusy) return { success: false, messageKey: 'busy' };
  isBusy = true;
  try {
    const data = await getNfcService({ forceRetry: true }).readTag();
    return { success: true, data };
  } catch (err) {
    return { success: false, messageKey: toMessageKey(err), details: err && err.message ? String(err.message) : String(err) };
  } finally {
    isBusy = false;
  }
});

ipcMain.handle('rfid-status', () => {
  // Do not initialize NFC on status polling; keep startup fast even without reader/driver.
  const svc = tryGetNfcService();
  if (!svc) {
    return { connected: false, readerName: null, cardPresent: false, uid: null };
  }
  return svc.getStatus();
});
ipcMain.handle('rfid-auto', async (_event, { enable }) => {
  autoEnabled = !!enable;

  if (autoEnabled) {
    // Auto-read should never block the UI: try to init NFC, otherwise fail fast.
    try {
      const svc = getNfcService({ forceRetry: true });
      startAutoLoop();

      // If a tag is already present, try a first read immediately
      const uid = svc.getCurrentUID();
      if (uid && !isBusy) {
        isBusy = true;
        try {
          const data = await svc.readTag();
          lastAutoUID = uid;
          sendAutoStatus({ present: true, tagData: data, error: null });
        } catch (err) {
          sendAutoStatus({ present: true, tagData: null, error: err && err.message ? String(err.message) : String(err) });
        } finally {
          isBusy = false;
        }
      }

      return { enabled: true };
    } catch (err) {
      autoEnabled = false;
      stopAutoLoop();
      sendAutoStatus({ present: false, tagData: null, error: 'NFC_NOT_CONNECTED' });
      return { enabled: false, messageKey: 'nfcNotConnected' };
    }
  } else {
    stopAutoLoop();
    sendAutoStatus({ present: false, tagData: null, error: null });
    return { enabled: false };
  }
});

// IPC handlers: File dialog and file system access for official cfg
ipcMain.handle('dialog:openFile', async (event, options = {}) => {
  const win = BrowserWindow.fromWebContents(event.sender);
  const result = await dialog.showOpenDialog(win, {
    properties: ['openFile'],
    ...options
  });
  return result; // { canceled: boolean, filePaths: string[] }
});

ipcMain.handle('fs:readFile', async (_event, { path: filePath, encoding = 'utf8' }) => {
  const data = await fsp.readFile(filePath, { encoding });
  return data.toString();
});

ipcMain.handle('fs:exists', async (_event, { path: filePath }) => {
  try {
    await fsp.access(filePath, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
});

// Window controls (optional)
ipcMain.handle('minimize-window', () => mainWindow && mainWindow.minimize());
ipcMain.handle('maximize-window', () => mainWindow && mainWindow.maximize());
ipcMain.handle('close-window', () => mainWindow && mainWindow.close());

// App lifecycle
app.whenReady().then(() => {
  createMainWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createMainWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('web-contents-created', (_event, contents) => {
  contents.on('new-window', (navigationEvent) => navigationEvent.preventDefault());
});