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

function Invoke-PythonPip {
    param(
        [string[]]$Arguments,
        [string]$ErrorMessage
    )
    & $pythonExe -m pip @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
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
$runtimeRoot = Join-Path $env:LOCALAPPDATA "DLC"
$projectDir = Join-Path $runtimeRoot "Deep-Live-Cam"
$venvDir = Join-Path $runtimeRoot ".venv"
if (-not (Test-Path $runtimeRoot)) {
    New-Item -ItemType Directory -Path $runtimeRoot | Out-Null
}
Write-Step "Using short runtime path: $runtimeRoot"

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
Invoke-PythonPip -Arguments @("install", "--upgrade", "pip") -ErrorMessage "Failed to upgrade pip."

Write-Step "Installing Deep-Live-Cam dependencies"
$requirementsPath = Join-Path $projectDir "requirements.txt"
$patchedRequirements = Join-Path $runtimeRoot "requirements.patched.txt"
$requirementsContent = Get-Content $requirementsPath
# Remove ONNX runtime pins from upstream requirements to avoid broken Windows/Python combinations.
$requirementsContent = $requirementsContent | Where-Object {
    $_ -notmatch "^onnxruntime([\-a-z]*)?=="
}
Set-Content -Path $patchedRequirements -Value $requirementsContent -Encoding ASCII
Invoke-PythonPip -Arguments @("install", "-r", $patchedRequirements) -ErrorMessage "Failed to install base requirements."

Write-Step "Installing ONNX runtime with safe fallback"
Invoke-PythonPip -Arguments @("uninstall", "-y", "onnxruntime-gpu", "onnxruntime-directml", "onnxruntime") -ErrorMessage "Failed to remove broken ONNX runtime packages."
$onnxCandidates = @(
    "onnxruntime-gpu==1.23.2",
    "onnxruntime-directml==1.21.0",
    "onnxruntime==1.23.2",
    "onnxruntime==1.21.0"
)
$onnxInstalled = $false
foreach ($candidate in $onnxCandidates) {
    Write-Host "Trying $candidate ..." -ForegroundColor DarkCyan
    & $pythonExe -m pip install $candidate
    if ($LASTEXITCODE -eq 0) {
        $onnxInstalled = $true
        Write-Host "Installed $candidate" -ForegroundColor Green
        break
    }
}
if (-not $onnxInstalled) {
    throw "Could not install any compatible ONNX runtime package."
}

Write-Step "Installing GFPGAN / BasicSR compatibility packages"
Invoke-PythonPip -Arguments @("install", "git+https://github.com/xinntao/BasicSR.git@master") -ErrorMessage "Failed to install BasicSR."
Invoke-PythonPip -Arguments @("uninstall", "-y", "gfpgan") -ErrorMessage "Failed to uninstall gfpgan."
Invoke-PythonPip -Arguments @("install", "git+https://github.com/TencentARC/GFPGAN.git@master") -ErrorMessage "Failed to install GFPGAN."

Write-Step "Initial launch to trigger model download (can take time)"
& $pythonExe (Join-Path $projectDir "run.py")

Write-Host "`nDone. Use run.ps1 to start Deep-Live-Cam next time." -ForegroundColor Green
