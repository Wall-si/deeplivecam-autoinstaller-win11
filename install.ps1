$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Ensure-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' is not installed or not in PATH."
    }
}

function Try-Install-WithWinget([string]$Id, [string]$Label) {
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        throw "'$Label' is missing and winget is not available for automatic installation."
    }
    Write-Step "Installing $Label via winget"
    winget install --id $Id --accept-source-agreements --accept-package-agreements --silent
}

Write-Step "Checking required tools"
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Try-Install-WithWinget -Id "Git.Git" -Label "Git"
}
if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Try-Install-WithWinget -Id "Python.Python.3.11" -Label "Python 3.11"
}
Ensure-Command "git"
Ensure-Command "python"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Join-Path $root "Deep-Live-Cam"
$venvDir = Join-Path $root ".venv"

Write-Step "Cloning (or updating) Deep-Live-Cam"
if (-not (Test-Path $projectDir)) {
    git clone https://github.com/hacksider/Deep-Live-Cam.git $projectDir
} else {
    git -C $projectDir pull
}

Write-Step "Creating virtual environment"
if (-not (Test-Path $venvDir)) {
    python -m venv $venvDir
}

$pythonExe = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    throw "Virtual environment python not found at $pythonExe"
}

Write-Step "Upgrading pip"
& $pythonExe -m pip install --upgrade pip

Write-Step "Installing Deep-Live-Cam dependencies"
& $pythonExe -m pip install -r (Join-Path $projectDir "requirements.txt")

Write-Step "Installing GFPGAN / BasicSR compatibility packages"
& $pythonExe -m pip install git+https://github.com/xinntao/BasicSR.git@master
& $pythonExe -m pip uninstall gfpgan -y
& $pythonExe -m pip install git+https://github.com/TencentARC/GFPGAN.git@master

Write-Step "Initial launch to trigger model download (can take time)"
& $pythonExe (Join-Path $projectDir "run.py")

Write-Host "`nDone. Use run.ps1 to start Deep-Live-Cam next time." -ForegroundColor Green
