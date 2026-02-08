<#
.SYNOPSIS
  Scan staged git diff for hardcoded secrets/API keys.
.DESCRIPTION
  Scans `git diff --cached` output for common secret patterns.
  Exit 0 = clean, Exit 1 = secrets found.
  Designed to run without external tools (git grep only).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Secret patterns to detect (regex)
$patterns = @(
    @{ Name = 'Anthropic API Key';   Regex = 'sk-ant-[a-zA-Z0-9_-]{20,}' }
    @{ Name = 'OpenAI API Key';      Regex = 'sk-proj-[a-zA-Z0-9_-]{20,}' }
    @{ Name = 'OpenAI Legacy Key';   Regex = 'sk-[a-zA-Z0-9]{20,}' }
    @{ Name = 'AWS Access Key';      Regex = 'AKIA[0-9A-Z]{16}' }
    @{ Name = 'Private Key';         Regex = '-----BEGIN\s*(RSA |EC |DSA )?PRIVATE KEY-----' }
    @{ Name = 'Supabase Service Role'; Regex = 'service_role[''"\s:=]+eyJ[a-zA-Z0-9_-]{20,}' }
    @{ Name = 'Payment Secret Key';  Regex = '(test_sk_|live_sk_|imp_)[a-zA-Z0-9]{10,}' }
    @{ Name = 'Sentry Auth Token';   Regex = 'sntrys_[a-zA-Z0-9]{20,}' }
    @{ Name = 'Firebase SA';         Regex = '"type"\s*:\s*"service_account"' }
)

# Files to exclude from scanning
$excludePatterns = @('\.env\.example$', '\.lock$', '\.md$', 'package-lock\.json$')

# Get staged diff (added lines only)
$diff = git diff --cached --unified=0 --diff-filter=ACMR 2>$null
if (-not $diff) {
    Write-Host "[scan-secrets] No staged changes to scan." -ForegroundColor Green
    exit 0
}

$findings = @()
$currentFile = ''
$lineNum = 0

foreach ($line in $diff -split "`n") {
    # Track current file
    if ($line -match '^\+\+\+ b/(.+)$') {
        $currentFile = $Matches[1]
        continue
    }

    # Track line numbers from hunk headers
    if ($line -match '^@@ .+\+(\d+)') {
        $lineNum = [int]$Matches[1] - 1
        continue
    }

    # Only scan added lines
    if ($line -match '^\+[^+]') {
        $lineNum++
        $content = $line.Substring(1)  # Remove leading '+'

        # Skip excluded files
        $skip = $false
        foreach ($exc in $excludePatterns) {
            if ($currentFile -match $exc) { $skip = $true; break }
        }
        if ($skip) { continue }

        # Check each secret pattern
        foreach ($pat in $patterns) {
            if ($content -match $pat.Regex) {
                # Redact the matched value
                $redacted = $content -replace $pat.Regex, '****REDACTED****'
                $findings += @{
                    File    = $currentFile
                    Line    = $lineNum
                    Pattern = $pat.Name
                    Snippet = $redacted.Trim()
                }
            }
        }
    }
    elseif ($line -notmatch '^[-+@\\]') {
        $lineNum++
    }
}

if ($findings.Count -gt 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host " SECRET SCAN FAILED - $($findings.Count) finding(s)" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    foreach ($f in $findings) {
        Write-Host "  [$($f.Pattern)]" -ForegroundColor Yellow -NoNewline
        Write-Host " $($f.File):$($f.Line)" -ForegroundColor White
        Write-Host "    $($f.Snippet)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Fix: Move secrets to environment variables or Edge Function secrets." -ForegroundColor Cyan
    Write-Host "     Then unstage the file: git reset HEAD <file>" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "[scan-secrets] No secrets detected in staged changes." -ForegroundColor Green
exit 0
