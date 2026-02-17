# deploy-sites.ps1
# Build Next.js static export, distribute to 4 Firebase Hosting sites, deploy.
# Usage: pwsh scripts/deploy-sites.ps1 [--skip-build] [--site web|agency|studio|admin]

param(
    [switch]$SkipBuild,
    [string]$Site = ""   # Deploy specific site only (empty = all)
)

$ErrorActionPreference = "Stop"
$webRoot = Split-Path -Parent $PSScriptRoot  # apps/web/

Write-Host "`n=== UNOA Firebase Multi-Site Deploy ===" -ForegroundColor Cyan

# --- Step 1: Build ---
if (-not $SkipBuild) {
    Write-Host "`n[1/4] Building Next.js static export..." -ForegroundColor Yellow
    Push-Location $webRoot
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Next.js build failed" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    Write-Host "Build complete." -ForegroundColor Green
} else {
    Write-Host "`n[1/4] Skipping build (--skip-build)" -ForegroundColor DarkGray
}

$outDir = Join-Path $webRoot "out"
if (-not (Test-Path $outDir)) {
    Write-Host "ERROR: out/ directory not found. Run build first." -ForegroundColor Red
    exit 1
}

# --- Step 2: Clean deploy directories ---
Write-Host "`n[2/4] Preparing deploy directories..." -ForegroundColor Yellow
$deployRoot = Join-Path $webRoot "deploy"
$sites = @("web", "agency", "studio", "admin")

foreach ($s in $sites) {
    $dir = Join-Path $deployRoot $s
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
    }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "Deploy directories ready." -ForegroundColor Green

# --- Step 3: Distribute files ---
Write-Host "`n[3/4] Distributing files to sites..." -ForegroundColor Yellow

# Common assets that every site needs (_next, favicon, etc.)
$commonItems = @("_next")
# Root files to copy (exclude index.html — each site gets its own)
$rootFiles = Get-ChildItem -Path $outDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "index.html" }

foreach ($s in $sites) {
    $dest = Join-Path $deployRoot $s

    # Copy _next/ (shared JS/CSS bundles)
    foreach ($item in $commonItems) {
        $src = Join-Path $outDir $item
        if (Test-Path $src) {
            Copy-Item -Recurse -Force $src (Join-Path $dest $item)
        }
    }

    # Copy root files (favicon.ico, robots.txt, sitemap.xml, etc.) — NOT index.html
    foreach ($file in $rootFiles) {
        Copy-Item -Force $file.FullName (Join-Path $dest $file.Name)
    }
}

# --- Site-specific content ---

# web: landing (index.html, 404.html), funding/, p/
$webDest = Join-Path $deployRoot "web"
$webItems = @("index.html", "404.html", "funding", "p")
foreach ($item in $webItems) {
    $src = Join-Path $outDir $item
    if (Test-Path $src) {
        if ((Get-Item $src).PSIsContainer) {
            Copy-Item -Recurse -Force $src (Join-Path $webDest $item)
        } else {
            Copy-Item -Force $src (Join-Path $webDest $item)
        }
    }
}

# agency: agency/ + redirect index.html
$agencySrc = Join-Path $outDir "agency"
if (Test-Path $agencySrc) {
    Copy-Item -Recurse -Force $agencySrc (Join-Path (Join-Path $deployRoot "agency") "agency")
}
$agencyRedirect = @'
<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=/agency/"><link rel="canonical" href="/agency/"><title>Redirecting...</title></head><body><p>Redirecting to <a href="/agency/">/agency/</a></p></body></html>
'@
Set-Content -Path (Join-Path (Join-Path $deployRoot "agency") "index.html") -Value $agencyRedirect -Encoding UTF8

# studio: studio/ + redirect index.html
$studioSrc = Join-Path $outDir "studio"
if (Test-Path $studioSrc) {
    Copy-Item -Recurse -Force $studioSrc (Join-Path (Join-Path $deployRoot "studio") "studio")
}
$studioRedirect = @'
<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=/studio/"><link rel="canonical" href="/studio/"><title>Redirecting...</title></head><body><p>Redirecting to <a href="/studio/">/studio/</a></p></body></html>
'@
Set-Content -Path (Join-Path (Join-Path $deployRoot "studio") "index.html") -Value $studioRedirect -Encoding UTF8

# admin: admin/ + redirect index.html
$adminSrc = Join-Path $outDir "admin"
if (Test-Path $adminSrc) {
    Copy-Item -Recurse -Force $adminSrc (Join-Path (Join-Path $deployRoot "admin") "admin")
}
$adminRedirect = @'
<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=/admin/"><link rel="canonical" href="/admin/"><title>Redirecting...</title></head><body><p>Redirecting to <a href="/admin/">/admin/</a></p></body></html>
'@
Set-Content -Path (Join-Path (Join-Path $deployRoot "admin") "index.html") -Value $adminRedirect -Encoding UTF8

# Report sizes
Write-Host "`nDeploy directory sizes:" -ForegroundColor Cyan
foreach ($s in $sites) {
    $dir = Join-Path $deployRoot $s
    $size = (Get-ChildItem -Recurse -Path $dir | Measure-Object -Property Length -Sum).Sum
    $sizeMb = [math]::Round($size / 1MB, 2)
    $fileCount = (Get-ChildItem -Recurse -File -Path $dir).Count
    Write-Host "  $s`: $sizeMb MB ($fileCount files)"
}
Write-Host "Distribution complete." -ForegroundColor Green

# --- Step 4: Deploy ---
Write-Host "`n[4/4] Deploying to Firebase Hosting..." -ForegroundColor Yellow
Push-Location $webRoot

if ($Site -ne "") {
    Write-Host "Deploying site: $Site" -ForegroundColor Cyan
    firebase deploy --only "hosting:$Site"
} else {
    Write-Host "Deploying all 4 sites..." -ForegroundColor Cyan
    firebase deploy --only hosting
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Firebase deploy failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

Write-Host "`n=== Deploy Complete ===" -ForegroundColor Green
Write-Host "Sites deployed:"
Write-Host "  Main:    https://unoa-web.web.app"
Write-Host "  Agency:  https://unoa-agency.web.app"
Write-Host "  Studio:  https://unoa-studio.web.app"
Write-Host "  Admin:   https://unoa-admin.web.app"
Write-Host ""
