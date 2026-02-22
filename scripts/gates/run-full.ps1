<#
.SYNOPSIS
  Full quality gate: run-fast + flutter build web --release.
.DESCRIPTION
  Runs all fast gates, then builds for web.
  Set UNO_GATE_SKIP_WEB_BUILD=1 to skip the web build step.
  Exit 0 = all passed, Exit 1 = failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir) }

# 1) Run fast gates first
Write-Host "[run-full] Running fast gates..." -ForegroundColor Cyan
& "$scriptDir\run-fast.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[run-full] Fast gates failed. Aborting full gate." -ForegroundColor Red
    exit 1
}

# 2) Web build (skippable)
if ($env:UNO_GATE_SKIP_WEB_BUILD -eq '1') {
    Write-Host "[run-full] Skipping web build (UNO_GATE_SKIP_WEB_BUILD=1)." -ForegroundColor Yellow
}
else {
    Push-Location $repoRoot
    try {
        Write-Host "[run-full] Running flutter build web --release..." -ForegroundColor Cyan
        # Use 'Continue' to prevent stderr warnings (e.g., Wasm dry-run)
        # from being treated as terminating errors by PowerShell.
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        flutter build web --release 2>&1
        $ErrorActionPreference = $prevEAP
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[run-full] flutter build web FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }
        Write-Host "[run-full] flutter build web passed." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

Write-Host "[run-full] All full gates passed." -ForegroundColor Green
exit 0
