<#
.SYNOPSIS
  Sentry Release & Source Map Upload Script for UNO A

.DESCRIPTION
  Creates a Sentry release, uploads Flutter web source maps,
  associates commits, and finalizes the release.

.PARAMETER Version
  Release version (default: from pubspec.yaml)

.PARAMETER Environment
  Deployment environment: production, staging, beta (default: production)

.EXAMPLE
  .\scripts\sentry-release.ps1
  .\scripts\sentry-release.ps1 -Version "1.0.0+42" -Environment staging
#>

param(
    [string]$Version = "",
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

# ── Helpers ─────────────────────────────────────────────────────
function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; exit 1 }

# ── Pre-checks ──────────────────────────────────────────────────
Write-Step "Pre-checks"

# Verify sentry-cli
if (-not (Get-Command sentry-cli -ErrorAction SilentlyContinue)) {
    Write-Fail "sentry-cli not found. Install: npm install -g @sentry/cli"
}
Write-Ok "sentry-cli $(sentry-cli --version)"

# Verify .sentryclirc exists
$rcFile = Join-Path $RepoRoot ".sentryclirc"
if (-not (Test-Path $rcFile)) {
    Write-Fail ".sentryclirc not found. Create it with your Sentry auth token."
}

# Check token is not placeholder
$rcContent = Get-Content $rcFile -Raw
if ($rcContent -match "YOUR_SENTRY_AUTH_TOKEN_HERE") {
    Write-Fail ".sentryclirc still has placeholder token. Set your real Sentry auth token."
}
Write-Ok ".sentryclirc configured"

# Verify build output exists
$buildDir = Join-Path $RepoRoot "build\web"
if (-not (Test-Path (Join-Path $buildDir "main.dart.js"))) {
    Write-Fail "build/web/main.dart.js not found. Run: flutter build web --release"
}
Write-Ok "Web build artifacts found"

# ── Determine version ──────────────────────────────────────────
if (-not $Version) {
    $pubspec = Get-Content (Join-Path $RepoRoot "pubspec.yaml") -Raw
    if ($pubspec -match 'version:\s+(\S+)') {
        $Version = $Matches[1]
    } else {
        Write-Fail "Could not parse version from pubspec.yaml"
    }
}

# Append git short SHA for uniqueness
$gitSha = git -C $RepoRoot rev-parse --short HEAD
$releaseVersion = "uno-a-flutter@$Version+$gitSha"

Write-Step "Creating release: $releaseVersion"

# ── Create release ──────────────────────────────────────────────
Write-Step "Creating Sentry release"
sentry-cli releases new $releaseVersion
if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to create release" }
Write-Ok "Release created"

# ── Associate commits ───────────────────────────────────────────
Write-Step "Associating commits"
sentry-cli releases set-commits $releaseVersion --auto
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Could not auto-associate commits (may need repo integration)"
} else {
    Write-Ok "Commits associated"
}

# ── Upload source maps ─────────────────────────────────────────
Write-Step "Uploading source maps from build/web/"
sentry-cli sourcemaps upload `
    --release $releaseVersion `
    --url-prefix "~/" `
    --validate `
    $buildDir
if ($LASTEXITCODE -ne 0) { Write-Fail "Source map upload failed" }
Write-Ok "Source maps uploaded"

# ── Finalize release ───────────────────────────────────────────
Write-Step "Finalizing release"
sentry-cli releases finalize $releaseVersion
if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to finalize release" }
Write-Ok "Release finalized"

# ── Create deployment ──────────────────────────────────────────
Write-Step "Recording deployment to '$Environment'"
sentry-cli releases deploys $releaseVersion new -e $Environment
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Could not record deployment"
} else {
    Write-Ok "Deployment recorded"
}

# ── Summary ─────────────────────────────────────────────────────
Write-Host "`n" -NoNewline
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Sentry Release Complete!" -ForegroundColor Green
Write-Host "  Release : $releaseVersion" -ForegroundColor Green
Write-Host "  Env     : $Environment" -ForegroundColor Green
Write-Host "  Maps    : build/web/ uploaded" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Verify in Sentry dashboard that source maps resolve correctly." -ForegroundColor Yellow
