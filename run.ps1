$ErrorActionPreference = "Stop"

try {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Path
    $pythonExe = Join-Path $root ".venv\Scripts\python.exe"
    $projectDir = Join-Path $root "Deep-Live-Cam"

    if (-not (Test-Path $pythonExe) -or -not (Test-Path $projectDir)) {
        Write-Host "DeepLiveCam is not installed yet. Running install.ps1 first..." -ForegroundColor Yellow
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "install.ps1")
        if ($LASTEXITCODE -ne 0) {
            throw "Installation failed. Check error messages above."
        }
    }

    & $pythonExe (Join-Path $projectDir "run.py")
    if ($LASTEXITCODE -ne 0) {
        throw "DeepLiveCam exited with an error code: $LASTEXITCODE"
    }
} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
