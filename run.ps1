$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonExe = Join-Path $root ".venv\Scripts\python.exe"
$projectDir = Join-Path $root "Deep-Live-Cam"

if (-not (Test-Path $pythonExe)) {
    throw "Virtual environment is missing. Run install.ps1 first."
}

if (-not (Test-Path $projectDir)) {
    throw "Deep-Live-Cam folder is missing. Run install.ps1 first."
}

& $pythonExe (Join-Path $projectDir "run.py")
