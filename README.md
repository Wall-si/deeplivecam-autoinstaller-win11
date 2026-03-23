# DeepLiveCam Auto Installer (Windows)

This is a ready-to-share Git repository.  
Your friend can clone it and run one script to download and install Deep-Live-Cam automatically.

## What this repo does

- clones official project: `hacksider/Deep-Live-Cam`
- creates local Python virtual environment (`.venv`)
- installs all required dependencies
- installs GFPGAN compatibility packages
- starts first run to download models
- tries to auto-install missing Git/Python via `winget`

## Requirements

- Windows
- Internet connection
- `winget` (recommended for auto-install of Git/Python)

## Installation (first run)

From this folder, run:

```powershell
.\install.bat
```

## Launch next times

```powershell
.\run.bat
```

## Share with a friend

1. Upload this repo to GitHub/GitLab.
2. Friend runs:

```powershell
git clone <your-repo-url>
cd deeplivecam-auto-installer
.\install.bat
```

## Notes

- Installed app source will be inside `Deep-Live-Cam/`.
- Virtual environment will be in `.venv/`.
- Installer removes broken ONNX pins from upstream requirements, then auto-tries several compatible ONNX packages (`gpu`, `directml`, `cpu`) until one installs.
