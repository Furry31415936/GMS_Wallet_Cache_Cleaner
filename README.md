# GMS Wallet Cache Cleaner

**分层清理系统 · 不退出账号 · 不解除手表配对 · 仅刷新风险状态**

A lightweight Magisk / KernelSU module for resolving Google Wallet's "device doesn't meet security requirements" error caused by cached local restriction states — **without** clearing your Google account or breaking Wear OS pairing.

---

## 🔬 Core Insight

After research and community validation (XDA, Reddit, X), the root cause is confirmed:

> **Play Store showing "certified" ≠ Wallet immediately trusting the device**

Google Wallet maintains **local persistent risk state** in GMS, separate from server-side integrity verification. After integrity is restored, old local verdicts can linger, causing Wallet to continue blocking NFC payments. This module clears those cached states while keeping your identity and pairing intact.

---

## 🏗️ Three-Level Cleaning System

| Level | Command | What It Cleans | Risk | Effect |
|-------|---------|---------------|------|--------|
| 🟢 **Safe** | `safe` | `cache/` + `code_cache/` | None | Clears temp files |
| 🟡 **Refresh** (⭐) | `refresh` | Cache + `kill gms.unstable` | Low | **Recommended** — flushes in-memory verdicts too |
| 🔴 **Experimental** | `experimental` | `files/` + `no_backup/` (safe-filtered) | Medium | Explores risk state storage |

> ⭐ **Refresh mode** is the recommended daily driver. It stops the `com.google.android.gms.unstable` process where DroidGuard and Integrity verdicts live in memory, then forces a clean restart.

---

## 🛡️ Protected Directories

The following are **never touched** to ensure account safety and watch pairing:

- `databases/` — Account databases
- `shared_prefs/` — Login & sync state
- `app_AccountData/` — Google identity data
- `app_SSO_authorization/` — SSO tokens
- `app_wearable/` — Wear OS pairing (critical!)
- `app_nearby/` — Nearby device identity
- `app_fcm/` — Push notification tokens

---

## 📦 Features

- **Backup** — Full data backup before major operations
- **Snapshot** — Record file states (size + mtime) for research
- **Diff** — Compare two snapshots to find changed files
- **List** — View all backups and snapshots
- **WebUI** — Clean interface for KernelSU / Magisk with WebUI support
- **Restore** → **Removed** — Full restore was too risky; use snapshots for targeted recovery

---

## ⚠️ Important Notes

> **Google's integrity detection is constantly evolving. No module can guarantee permanent results.**

- Local cache clearing is only a **temporary workaround**
- If your device has persistent integrity failures, fix the root cause first (valid keybox, locked bootloader, etc.)
- In some cases, server-side risk may need time to expire (hours to days)
- `restore` has been removed due to high risk of state inconsistency with GMS

---

## 📋 Recommended Workflow

```
1. Start with a snapshot:
   $ ./clear.sh snapshot

2. Apply Refresh mode:
   $ ./clear.sh refresh

3. Reboot device

4. Open Wallet — if resolved, great!

5. Take another snapshot and diff:
   $ ./clear.sh snapshot
   $ ./clear.sh diff

6. If unchanged, try Safe mode first, then Experimental
```

---

## 📥 Installation

1. Download the ZIP from [Releases](https://github.com/Furry31415936/GMS_Wallet_Cache_Cleaner/releases)
2. Install via Magisk Manager or KernelSU Manager
3. Reboot
4. Open WebUI from module manager
5. Start with **🟡 Refresh** mode

---

## 🔧 Building from Source

```bash
cd GMS_Wallet_Cache_Cleaner
zip -r ../GMS_Wallet_Cache_Cleaner.zip ./* -x ".git/*"
```

Or with Python:

```bash
python -c "
import zipfile, os
os.chdir('GMS_Wallet_Cache_Cleaner')
with zipfile.ZipFile('../GMS_Wallet_Cache_Cleaner.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk('.'):
        if '.git' in root.split(os.sep): continue
        for f in files: z.write(os.path.join(root, f))
"
```

---

## 📄 File Structure

```
GMS_Wallet_Cache_Cleaner/
├── clear.sh           # Core script (safe | refresh | experimental | snapshot | diff | ...)
├── customize.sh       # Magisk/KSU install script
├── module.prop        # Module metadata
├── README.md          # This file
├── service.sh         # Boot service (ensures backup dir)
├── uninstall.sh       # Cleanup backup directory on uninstall
├── META-INF/          # Magisk/KSU install structure
│   └── com/google/android/
│       ├── update-binary
│       └── updater-script
└── webroot/           # KernelSU WebUI
    ├── index.html
    └── script.js
```

---

## 📜 License

MIT — Use at your own risk. Always backup before major operations.

---

## 🙏 Credits

- Community insights from XDA, Reddit, X/Twitter, and Telegram
- ChatGPT analysis on GMS state layering and risk engineering
- Grok for cross-platform community research
- All root developers pushing the boundaries

---

> **This project is experimental. It does not bypass Play Integrity or device certification. It only attempts to clear cached local restriction states after integrity issues are resolved.**
