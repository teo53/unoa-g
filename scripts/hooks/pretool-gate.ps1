<#
.SYNOPSIS
  Claude Code PreToolUse hook — auto-gate for git commit/push.
.DESCRIPTION
  Reads JSON from stdin (Claude Code hook protocol).
  Detects git commit/push commands and runs appropriate gate scripts.
  Exit 0 = allow, Exit 2 = block (with stderr message).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$gatesDir = Join-Path (Split-Path -Parent $scriptDir) 'gates'

# Read stdin JSON
$inputJson = $null
try {
    $inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
}
catch {
    # If stdin parsing fails, allow (non-blocking)
    exit 0
}

if (-not $inputJson) { exit 0 }

# Extract the command from tool_input
$command = $null
if ($inputJson.tool_input -and $inputJson.tool_input.command) {
    $command = $inputJson.tool_input.command
}

if (-not $command) { exit 0 }

# Detect git commit
if ($command -match '\bgit\b.*\bcommit\b') {
    Write-Host "[pretool-gate] git commit detected. Running pre-commit gates..." -ForegroundColor Cyan

    # 1) Secret scan
    Write-Host "[pretool-gate] Running scan-secrets..." -ForegroundColor Cyan
    & powershell -NoProfile -File "$gatesDir\scan-secrets.ps1"
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("[pretool-gate] BLOCKED: Secrets detected in staged changes. Remove secrets before committing.")
        exit 2
    }

    # 2) Fast gates (analyze + test)
    Write-Host "[pretool-gate] Running run-fast..." -ForegroundColor Cyan
    & powershell -NoProfile -File "$gatesDir\run-fast.ps1"
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("[pretool-gate] BLOCKED: flutter analyze or test failed. Fix issues before committing.")
        exit 2
    }

    Write-Host "[pretool-gate] All pre-commit gates passed." -ForegroundColor Green
    exit 0
}

# Detect git push
if ($command -match '\bgit\b.*\bpush\b') {
    Write-Host "[pretool-gate] git push detected. Running pre-push gates..." -ForegroundColor Cyan

    # 1) Secret scan
    Write-Host "[pretool-gate] Running scan-secrets..." -ForegroundColor Cyan
    & powershell -NoProfile -File "$gatesDir\scan-secrets.ps1"
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("[pretool-gate] BLOCKED: Secrets detected. Remove secrets before pushing.")
        exit 2
    }

    # 2) Full gates (analyze + test + build)
    Write-Host "[pretool-gate] Running run-full..." -ForegroundColor Cyan
    & powershell -NoProfile -File "$gatesDir\run-full.ps1"
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("[pretool-gate] BLOCKED: Full gate failed. Fix issues before pushing.")
        exit 2
    }

    # 3) Supabase guard (non-blocking, warnings only)
    Write-Host "[pretool-gate] Running guard-supabase..." -ForegroundColor Cyan
    & powershell -NoProfile -File "$gatesDir\guard-supabase.ps1"

    Write-Host "[pretool-gate] All pre-push gates passed." -ForegroundColor Green
    exit 0
}

# Not a git commit/push — allow
exit 0
