# Cursor Free VIP

> Forked from [yeongpin/cursor-free-vip](https://github.com/yeongpin/cursor-free-vip). This fork distributes an English-only experience and a custom Windows installer workflow.

Cursor Free VIP is a cross-platform helper that automates the tedious parts of managing Cursor accounts, configurations, and machine identifiers. It ships with menu-driven tooling (`main.py`), reset scripts, OAuth helpers, and packaging scripts that produce a standalone executable for Windows, macOS, or Linux.

---

## Requirements

- Python 3.10 or newer
- Windows, macOS, or Linux
- Git (optional but recommended)
- On Windows builds: `pyinstaller`, `python-dotenv`, and all packages from `requirements.txt`

Install dependencies once you have cloned the repository:

````powershell
python -m venv .venv
source .venv/bin/activate    # Windows: .\.venv\Scripts\Activate.ps1
````

---

## Quick Start (Windows Users)

1. Visit the Releases page and download the latest `CursorVipActivator.exe` (or share the `release` tag URL directly with end users).
2. Either double-click the executable (recommended: “Run as administrator”) **or** run the bundled installer script to download and launch it automatically:

````powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-Location "D:\Personal Project\Forked Repositories\cursor-free-vip"
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
````

3. Close the official Cursor app before running the activator so file operations succeed.
4. When a new version ships, repeat the download/installer step; the script replaces the old binary inside `D:\Program Files\Cursor Free Vip Activator`.

---

## Running From Source

After installing dependencies:

````powershell
pip install -r requirements.txt
````

````powershell
python main.py
````

The CLI prompts you to pick tasks such as resetting Cursor, managing OAuth, or generating new machine identifiers. Close the official Cursor app before running scripts and prefer elevated shells on Windows so all file operations succeed.

---

## Configuration Files

- **User config**: `%USERPROFILE%\Documents\.cursor-free-vip\config.ini` (Windows) or the matching path under `~/Documents` on macOS/Linux.
- **Environment metadata**: `.env` in the project root stores the current release version.

Sample `.env`:

````env
version=1.11.03+eng
VERSION=1.11.03+eng
````

Both keys should match; update them whenever you prepare a new build.

---

## Build & Package (Windows `.exe`)

1. **Install dependencies**

````powershell
pip install -r requirements.txt
pip install pyinstaller python-dotenv
````

2. **Build**

````powershell
python build.py
````

- `build.py` clears `build/`, reloads `.env`, and invokes PyInstaller with `build.spec`.
- Output lands in `dist/CursorVipActivator.exe`.

3. **Manual PyInstaller alternative**

````powershell
pyinstaller --clean --noconfirm build.spec
````

4. **Test the binary**  
Run the executable locally to ensure menus, locale loading, and config paths work.

---

## Publishing A Release

1. Go to your fork’s Releases page (`https://github.com/Krystal0212/cursor-free-vip/releases`) and click **Draft a new release**.
2. Set **Tag version** to `release` (or `v1.11.04` if you prefer semantic tags) and target the `main` branch.
3. Add a title/description; mark it as a pre-release if you are testing.
4. Drag the newly built `CursorVipActivator.exe` into the “Attach binaries” area.
5. Publish the release.

The installer script automatically detects assets whose names fit `CursorVipActivator.exe`. If no asset is available, it falls back to the `CURSOR_FREE_VIP_WINDOWS_URL` environment variable or constructs `https://github.com/Krystal0212/cursor-free-vip/releases/download/<tag>/CursorVipActivator.exe`.

---

## After Publishing

1. **Smoke test the installer**  
Run `scripts/install.ps1` from a clean Windows host to make sure it fetches the new asset and launches successfully.

2. **Verify upgrade paths**  
If you keep an older `CursorVipActivator.exe` around, rerun the installer to confirm it detects and replaces the previous file inside `D:\Program Files\Cursor Free Vip Activator`.

3. **Share the release link**  
Distribute `https://github.com/Krystal0212/cursor-free-vip/releases/latest` (or the specific tag URL) to testers/users once validation passes.

4. **Update `.env` for the next cycle**  
Bump `version` / `VERSION` so the next build command knows the upcoming release number.

---

## Development Scripts Overview

| Script | Purpose |
|--------|---------|
| `main.py` | Menu-driven UI to run the common automation tasks. |
| `build.py` | Cleans caches and wraps PyInstaller to create platform-specific binaries. |
| `build.spec` | PyInstaller spec file defining data files and executable metadata. |
| `scripts/install.ps1` | Windows installer that downloads/releases the packaged `.exe`. |
| `scripts/install.sh` | Bash installer for macOS/Linux (downloads the matching binary). |
| `scripts/reset.ps1` | Helper for resetting installations (Windows). |

Explore the `scripts/` directory for OS-specific automation helpers and `locales/` for translation files.

---

## License

Distributed under the [CC BY-NC-ND 4.0](LICENSE.md) license. Use responsibly and support the original Cursor project.
