# BoxRFID – Filament Tag Manager

BoxRFID is a Windows desktop app (Electron) to read and write NFC/RFID tags used by QIDI Box, a multi color System for QIDI Plus 4 and QIDI Q2 3D printers. It lets you set material, color, and manufacturer codes (not yet supported by QIDI Box, Maybe in future), read tags, and auto‑read when a tag is detected.

- Platform: Windows (Electron)
- Version: 1.1.0
- License: CC BY‑NC‑SA 4.0

## Features
- Write filament data (material, color, manufacturer) to compatible tags
- Read and display tag data
- Auto‑read mode when a tag is presented; clears when removed
- Multi language support (DE, EN, FR, ES, PT, ZH)
- Support Import of "officiall_filas_list.cfg" - optional
- Support edit / delete filaments from Filament list and Vendor list
- Uses PC/SC (nfc-pcsc) for reader support (tested with ACR122U)

## What’s new in v1.1.0

Version **1.1.0** focuses on stability, startup performance, and proper internationalization.

### 🚀 Improvements
- **Much faster startup** (window opens in ~2–3 seconds instead of 20–30 seconds)
- **Reliable window opening** – app no longer runs headless in the background
- **Persistent settings**  
  Selected language, manufacturer usage, and preferences are now reliably restored on next startup
- **Improved Windows compatibility**  
  Chromium disk cache is redirected to Electron userData to avoid permission issues on locked-down systems

### 🌍 Internationalization (i18n)
- All NFC and status messages are now **fully localized**
- No more mixed German/English messages when another language is selected
- Consistent behavior across all supported languages (DE, EN, FR, ES, PT, ZH)

### 🧩 Technical
- Native modules are rebuilt correctly for the bundled Electron version
- Improved startup robustness on systems with antivirus or Controlled Folder Access

## REQUIREMENTS
- ACR122U USB reader/writer (i.e. https://www.amazon.com/ACR122U-Contactless-Reader-Lianshi-Writer/dp/B07DK9GX1N)
- Mifare classic 1K tags (i.e. https://www.amazon.com/BABIQT-Sticker-Classic-Self-Adhesive-Stickers/dp/B0BZRS35CT)

## 🚀 WINDOWS BINARIES – DOWNLOAD & START!

> **IMPORTANT:**  
> You do **not** need to compile the code yourself!  
> Simply download the latest Windows EXE directly from the release page:
>
> 👉 **[BoxRFID v1.1.0 – Download Windows EXE](https://github.com/TinkerBarn/BoxRFID/releases/tag/v1.1.0)**
>
> **This release is recommended for all users due to major stability and startup improvements.**


## HOW TO USE DIY RFID FILAMENT SPOOLS WITH THE QIDI BOX

- Curious how it works in practice?  
  Check out this short YouTube video and see how effortlessly you can switch filament spools using DIY RFID tags with your QIDI Box:

[![Watch the video](https://img.youtube.com/vi/LO6eAkdcSCA/hqdefault.jpg)](https://youtu.be/LO6eAkdcSCA)


## SCREENSHOTS
- Main Menu

![Main Menu](screenshots/Main%20Menu%20v1.0.0.png)


- Read tag Information and Show result

![Read Tag Information](screenshots/Read%20Tag%20Information%20v1.0.0.png)


- Write tag Information - ABS and Dark Blue selected - Write successfully

![Write Tag Information](screenshots/Write%20Tag%20Information%20v1.0.0.png)


- Setup Language

![Setup - Language](screenshots/Setup%20-%20Language%20v1.0.0.png)


- Setup Materials

![Setup - Materials](screenshots/Setup%20-%20Materials%20v1.0.0.png)


- Setup Manufacturers - only available if in Setup - General activated

![Setup - Manufacturers](screenshots/Setup%20-%20Manufacturers%20v1.0.0.png)


- Setup General

![Setup - General](screenshots/Setup%20-%20General%20v1.0.0.png)



## Windows Development Setup (PowerShell)

This guide will walk you through setting up a complete development environment for BoxRFID on Windows, and building your own EXE from the code.  
It is designed for users with little or no prior experience in Node.js or Electron development.

---

### **Prerequisites**

- **Operating System:** Windows 10 or 11  
- **Terminal:** PowerShell (default on Windows)
- **Admin Rights:** You may need administrator rights to install software

---

### **Step 1: Install Necessary Tools**

Open PowerShell as an administrator and run the following commands one by one.  
This will install Git (for downloading code) and Node.js LTS (needed to build and run Electron apps):

```powershell
winget install -e --id Git.Git
winget install -e --id OpenJS.NodeJS.LTS
```

If you get errors, make sure [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) is available, or install the tools manually from their websites.

---

### **Step 2: Download the BoxRFID Code**

Clone (download) the source code from GitHub:

```powershell
git clone https://github.com/TinkerBarn/BoxRFID.git
cd BoxRFID
```

---

### **Step 3: Install Project Dependencies**

Install the required packages using npm (Node Package Manager):

```powershell
npm install
```

---

### **Step 4: (Optional) Generate Application Icons**

If you want to customize or regenerate the app icon, place a square PNG (ideally 1024x1024) at `assets\source-icon.png`, then run:

```powershell
npm i -D sharp png-to-ico
node tools/generate-icons-from-png.js
```

If you don't need to change the icon, you can skip this step.

---

### **Step 5: Run the App in Development Mode**

You can test and develop the app before building the EXE:

```powershell
$env:NODE_ENV="development"
npm run dev
```

This will start the app in development mode. If you see errors about missing dependencies, double-check you ran `npm install`.

---

### **Step 6: Build the Windows Executable (EXE)**

To compile the app and create the Windows installer and portable EXE, run:

```powershell
npm run build-win
```

After building, you will find the following files in the `dist\` folder:

- `BoxRFID – Filament Tag Manager Setup <version>.exe` (Windows installer)
- `BoxRFID – Filament Tag Manager <version>.exe` (portable, runs without installation)

---

### **Notes & Troubleshooting**

- The EXE/installer icon is set in `assets/icon.ico`. If you change the icon, rebuild the EXE.
- If you have issues with permissions, try running PowerShell as Administrator.
- Some antivirus programs may flag newly built EXE files. This is a common false positive for Electron apps you build yourself.
- If you want to update the code, run `git pull` in the `BoxRFID` folder, then repeat the build steps.

---

### **Further Reading**

- [Electron Documentation](https://www.electronjs.org/docs)
- [Node.js Documentation](https://nodejs.org/en/docs/)
- [npm Documentation](https://docs.npmjs.com/)

---



## Notes
- EXE/installer icon comes from electron-builder `build.win.icon` → `assets/icon.ico`
- Window/taskbar icon set in `main.js`:
  ```js
  icon: process.platform === 'win32'
    ? path.join(__dirname, 'assets', 'icon.ico')
    : path.join(__dirname, 'assets', 'icon.png')
  ```

## Folder structure (excerpt)
```
assets/
  icon.ico
  icon.png
  source-icon.png        # optional input for generator
  tmp-icons/             # ignored
tools/
  generate-icons-from-png.js
main.js
preload.js
index.html
package.json
```

## License
Creative Commons Attribution‑NonCommercial‑ShareAlike 4.0 International (CC BY‑NC‑SA 4.0).
For commercial licensing, contact: boxrfid@tinkerbarn.de.
