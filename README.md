# GMS Wallet Cache Cleaner

⚠️⚠️⚠️This module is currently in the testing phase; please do not install it

**A lightweight Magisk / KernelSU module for backing up, clearing, and restoring Google Play Services & Google Wallet cache.**

Designed for rooted users who frequently encounter the "Your device doesn't meet security requirements" error in Google Wallet and need to clear GMS data repeatedly.

### Features

- ✅ **Automatic backup** before clearing (stored in `/data/adb/gms_backup/` with timestamp)
- ✅ **One-click Cache Clear** (Recommended - does not log you out)
- ✅ **Selective Data Clear** (Use with caution)
- ✅ **One-click Restore** from latest backup
- ✅ Supports **Magisk** and **KernelSU**
- ✅ **KernelSU WebUI** support (visual web interface)
- ✅ Auto sets execution permissions on install
- ✅ Cleans backup folder on uninstall

### Targeted Packages

- `com.google.android.gms` — Google Play Services
- `com.google.android.apps.walletnfcrel` — Google Wallet
- `com.android.vending` — Play Store

---

### Installation

1. Download the latest `GMS_Wallet_Cache_Cleaner.zip` from Releases
2. Install via **Magisk** or **KernelSU** app
3. Reboot your device
4. Open the module's **WebUI** to use

> **Magisk Users**: Install [KSU WebUI Standalone](https://github.com/5ec1cff/KernelSU_WebUI_Standalone) or use a WebUI-compatible manager like MMRL.

---

### How to Use

After opening the WebUI, you will see:

- **📦 Backup Current Data** – Always recommended before clearing
- **🗑️ Clear Cache (Recommended)** – Safest option
- **⚠️ Selective Clear Data** – May require re-login, use carefully
- **🔄 Restore Latest Backup** – Restore from most recent backup
- **🔄 Reboot Device** – Suggested after cleaning

---

### Notes & Warnings

- This module only touches cache and temporary files. It does **not** modify system core files.
- Frequent GMS clearing may still be flagged by Google servers.
- **Always backup first** before clearing.
- Google’s integrity detection is constantly evolving. No module can guarantee permanent results.
- Use at your own risk. The author is not responsible for any data loss or issues caused by this module.

### FAQ

**Q: Wallet still shows security error after clearing?**  
A: Local cache clearing is only a temporary workaround. For better stability, combine with **TrickyStore** + **Play Integrity Fix** modules.

**Q: How much space do backups take?**  
A: Usually 50–300 MB per backup. The backup folder is automatically cleaned when the module is uninstalled.

---

### Disclaimer

This module is provided for educational and technical purposes only.  
Use it at your own risk.

---

### Support

Bug reports, feature requests, and pull requests are welcome.

Just let me know!
