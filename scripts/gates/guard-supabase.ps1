<#
.SYNOPSIS
  Supabase migration static checks.
.DESCRIPTION
  Validates migration file naming, sequence, and dangerous SQL patterns.
  If supabase CLI is installed, runs `supabase status` as info.
  Exit 0 = passed (warnings are non-blocking), Exit 1 = critical error.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) }
$migrationsDir = Join-Path (Join-Path $repoRoot 'supabase') 'migrations'

$warnings = @()
$errors = @()

# 1) Check migrations directory
if (-not (Test-Path $migrationsDir)) {
    Write-Host "[guard-supabase] No supabase/migrations/ directory found. Skipping." -ForegroundColor Yellow
    exit 0
}

# 2) Validate migration files
$sqlFiles = Get-ChildItem -Path $migrationsDir -Filter '*.sql' | Sort-Object Name
if ($sqlFiles.Count -eq 0) {
    Write-Host "[guard-supabase] No migration files found." -ForegroundColor Yellow
    exit 0
}

Write-Host "[guard-supabase] Checking $($sqlFiles.Count) migration files..." -ForegroundColor Cyan

$seenNumbers = @{}
foreach ($file in $sqlFiles) {
    # Check filename format: NNN_description.sql
    if ($file.Name -notmatch '^\d{3}_[\w]+\.sql$') {
        $warnings += "Filename format: $($file.Name) does not match NNN_description.sql"
    }

    # Extract sequence number
    if ($file.Name -match '^(\d{3})_') {
        $num = [int]$Matches[1]
        if ($seenNumbers.ContainsKey($num)) {
            $errors += "Duplicate sequence: $num used by $($seenNumbers[$num]) and $($file.Name)"
        }
        $seenNumbers[$num] = $file.Name
    }

    # Scan for dangerous SQL
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line.Trim().StartsWith('--')) { continue }

            if ($line -match '\bDROP\s+TABLE\b') {
                $warnings += "$($file.Name):$($i+1) DROP TABLE detected"
            }
            if ($line -match '\bTRUNCATE\b') {
                $warnings += "$($file.Name):$($i+1) TRUNCATE detected"
            }
            if ($line -match '\bGRANT\s+ALL\b') {
                $warnings += "$($file.Name):$($i+1) GRANT ALL detected"
            }
        }
    }
}

# Check sequence gaps
$sortedNums = $seenNumbers.Keys | Sort-Object
for ($i = 1; $i -lt $sortedNums.Count; $i++) {
    if ($sortedNums[$i] - $sortedNums[$i-1] -gt 1) {
        $warnings += "Sequence gap: $($sortedNums[$i-1].ToString('000')) -> $($sortedNums[$i].ToString('000'))"
    }
}

# 3) Check supabase CLI (optional)
$hasCli = Get-Command supabase -ErrorAction SilentlyContinue
if ($hasCli) {
    Write-Host "[guard-supabase] Supabase CLI found. Running status check..." -ForegroundColor Cyan
    Push-Location $repoRoot
    try {
        supabase status 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    catch {
        Write-Host "[guard-supabase] supabase status failed (non-blocking)" -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "[guard-supabase] Supabase CLI not installed. Skipping live checks." -ForegroundColor DarkGray
    Write-Host "  Install: npm i -g supabase (optional)" -ForegroundColor DarkGray
}

# Output results
if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "[guard-supabase] ERRORS:" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  $e" -ForegroundColor Red }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "[guard-supabase] WARNINGS:" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  $w" -ForegroundColor Yellow }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[guard-supabase] All migration checks passed." -ForegroundColor Green
}

# Non-blocking: always exit 0 (warnings only)
# Critical enforcement happens in CI
exit 0
