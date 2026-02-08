<#
.SYNOPSIS
  Bootstrap script for new developer setup.
.DESCRIPTION
  1. Copies settings template if local settings don't exist.
  2. Checks MCP server dependencies and builds if needed.
  3. Prints next steps.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path) }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UNO A - Developer Bootstrap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1) Claude Code local settings
$localSettings = Join-Path (Join-Path $repoRoot '.claude') 'settings.local.json'
$templateSettings = Join-Path (Join-Path $repoRoot '.claude') 'settings.template.local.json'

if (-not (Test-Path $localSettings)) {
    if (Test-Path $templateSettings) {
        Copy-Item $templateSettings $localSettings
        Write-Host "[bootstrap] Created .claude/settings.local.json from template." -ForegroundColor Green
    }
    else {
        Write-Host "[bootstrap] No settings template found. Skipping local settings." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[bootstrap] .claude/settings.local.json already exists. Skipping." -ForegroundColor DarkGray
}

# 2) MCP servers
$mcpRoot = Join-Path (Join-Path $repoRoot 'tools') 'mcp'
if (Test-Path $mcpRoot) {
    $nodeModules = Join-Path $mcpRoot 'node_modules'
    if (-not (Test-Path $nodeModules)) {
        Write-Host "[bootstrap] Installing MCP server dependencies..." -ForegroundColor Cyan
        Push-Location $mcpRoot
        try {
            npm install 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[bootstrap] MCP dependencies installed." -ForegroundColor Green
                Write-Host "[bootstrap] Building MCP servers..." -ForegroundColor Cyan
                npm run build 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[bootstrap] MCP servers built." -ForegroundColor Green
                }
                else {
                    Write-Host "[bootstrap] MCP build failed. Run manually: cd tools/mcp && npm run build" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "[bootstrap] npm install failed. Check Node.js installation." -ForegroundColor Yellow
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host "[bootstrap] MCP node_modules already exists. Skipping install." -ForegroundColor DarkGray
    }
}
else {
    Write-Host "[bootstrap] No tools/mcp/ directory found. Skipping MCP setup." -ForegroundColor DarkGray
}

# 3) Flutter pub get
Write-Host ""
Write-Host "[bootstrap] Running flutter pub get..." -ForegroundColor Cyan
Push-Location $repoRoot
try {
    flutter pub get 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[bootstrap] Flutter dependencies installed." -ForegroundColor Green
    }
    else {
        Write-Host "[bootstrap] flutter pub get failed." -ForegroundColor Yellow
    }
}
finally {
    Pop-Location
}

# 4) Next steps
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Review .claude/settings.local.json and adjust permissions" -ForegroundColor White
Write-Host "    2. Run fast gate:  pwsh scripts/gates/run-fast.ps1" -ForegroundColor White
Write-Host "    3. Run full gate:  pwsh scripts/gates/run-full.ps1" -ForegroundColor White
Write-Host "    4. Start dev:     flutter run -d chrome" -ForegroundColor White
Write-Host ""
