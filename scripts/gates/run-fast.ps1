<#
.SYNOPSIS
  Fast quality gate: flutter analyze + flutter test.
.DESCRIPTION
  Runs flutter analyze and flutter test sequentially.
  Exit 0 = all passed, Exit 1 = failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir) }

Push-Location $repoRoot
try {
    # 1) flutter analyze
    Write-Host "[run-fast] Running flutter analyze..." -ForegroundColor Cyan
    flutter analyze 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[run-fast] flutter analyze FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "[run-fast] flutter analyze passed." -ForegroundColor Green

    # 2) flutter test
    Write-Host "[run-fast] Running flutter test..." -ForegroundColor Cyan
    flutter test 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[run-fast] flutter test FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "[run-fast] flutter test passed." -ForegroundColor Green

    Write-Host "[run-fast] All fast gates passed." -ForegroundColor Green
    exit 0
}
finally {
    Pop-Location
}
