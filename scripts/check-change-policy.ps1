[CmdletBinding()]
param(
    [string]$BaseRef = "origin/main",
    [switch]$AllowMissingBase
)

$ErrorActionPreference = "Stop"

function Invoke-GitLines {
    param([string[]]$Arguments)

    $output = & git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw (($output | ForEach-Object { $_.ToString() }) -join "`n")
    }
    return @($output | ForEach-Object { $_.ToString() })
}

function Test-AnyPath {
    param(
        [string[]]$Paths,
        [string[]]$Patterns
    )

    foreach ($path in $Paths) {
        foreach ($pattern in $Patterns) {
            if ($path -like $pattern) {
                return $true
            }
        }
    }
    return $false
}

function Add-Failure {
    param([string]$Message)
    $script:failures += $Message
}

$failures = @()

try {
    & git rev-parse --verify $BaseRef | Out-Null
} catch {
    if ($AllowMissingBase) {
        Write-Output "SKIP change policy: base ref '$BaseRef' is not available"
        exit 0
    }
    throw
}

$changedFiles = Invoke-GitLines -Arguments @("diff", "--name-only", "$BaseRef...HEAD")
if ($changedFiles.Count -eq 0) {
    Write-Output "PASS change policy: no changed files"
    exit 0
}

$changelogChanged = $changedFiles -contains "CHANGELOG.md"
$scriptChanged = Test-AnyPath -Paths $changedFiles -Patterns @("scripts/*.ps1", "skills/*/scripts/*.ps1")
$scriptDocsChanged = Test-AnyPath -Paths $changedFiles -Patterns @(
    "README.md",
    "README.zh-CN.md",
    "CONTRIBUTING.md",
    "SKILL-PLUGIN-DESIGN.md",
    "skills/*/SKILL.md",
    "skills/*/references/*.md"
)
$guideChanged = $changedFiles -contains "WINDOWS-CODEX-ERROR-GUIDE.md"
$guideCompanionChanged = Test-AnyPath -Paths $changedFiles -Patterns @(
    "DOGFOOD-MATRIX.md",
    "skills/*/references/*.md"
)

$userVisibleChanged = Test-AnyPath -Paths $changedFiles -Patterns @(
    "README.md",
    "README.zh-CN.md",
    "CONTRIBUTING.md",
    "WINDOWS-CODEX-ERROR-GUIDE.md",
    "DOGFOOD-MATRIX.md",
    "RESEARCH-SOURCES.md",
    "RELEASE_NOTES.md",
    "skills/*/SKILL.md",
    "skills/*/references/*.md",
    "scripts/*.ps1",
    "skills/*/scripts/*.ps1"
)

if ($userVisibleChanged -and -not $changelogChanged) {
    Add-Failure "user-visible changes require CHANGELOG.md updates"
}

if ($scriptChanged -and -not $scriptDocsChanged) {
    Add-Failure "script changes require documentation or skill/reference updates"
}

if ($guideChanged -and -not $guideCompanionChanged) {
    Add-Failure "guide case changes require dogfood or reference updates"
}

if ($failures.Count -gt 0) {
    Write-Output "FAIL change policy"
    Write-Output "Changed files:"
    $changedFiles | ForEach-Object { Write-Output "- $_" }
    Write-Output "Failures:"
    $failures | ForEach-Object { Write-Output "- $_" }
    exit 1
}

Write-Output "PASS change policy"
Write-Output "Changed files:"
$changedFiles | ForEach-Object { Write-Output "- $_" }
