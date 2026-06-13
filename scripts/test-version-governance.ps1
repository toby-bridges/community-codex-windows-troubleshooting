[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$versionPath = Join-Path $repoRoot "VERSION"
$changelogPath = Join-Path $repoRoot "CHANGELOG.md"
$prTemplatePath = Join-Path $repoRoot ".github\PULL_REQUEST_TEMPLATE.md"
$contributingPath = Join-Path $repoRoot "CONTRIBUTING.md"

Assert-True (Test-Path -LiteralPath $versionPath) "VERSION must exist"
Assert-True (Test-Path -LiteralPath $changelogPath) "CHANGELOG.md must exist"

$version = (Get-Content -Raw -LiteralPath $versionPath).Trim()
Assert-True ($version -match '^\d+\.\d+\.\d+$') "VERSION must contain a bare SemVer value"
Assert-True ($version -eq "0.1.0") "Initial VERSION should match the published v0.1.0 release"

$changelog = (Get-Content -Raw -LiteralPath $changelogPath) -replace "`r`n", "`n"
Assert-True ($changelog -match '(?m)^# Changelog$') "CHANGELOG.md must use a Changelog title"
Assert-True ($changelog -match '(?m)^## \[Unreleased\]$') "CHANGELOG.md must have an Unreleased section"
Assert-True ($changelog -match '(?m)^## \[0\.1\.0\] - 2026-06-05$') "CHANGELOG.md must preserve the v0.1.0 release"

$prTemplate = Get-Content -Raw -LiteralPath $prTemplatePath
foreach ($required in @(
    "## Change Type",
    "## Version Impact",
    "## Coupled Updates",
    "Documentation updated",
    "Code updated",
    "Changelog updated"
)) {
    Assert-True ($prTemplate.Contains($required)) "PR template missing '$required'"
}

$contributing = Get-Content -Raw -LiteralPath $contributingPath
foreach ($required in @(
    "Version Governance",
    "Version impact",
    "CHANGELOG.md",
    "VERSION"
)) {
    Assert-True ($contributing.Contains($required)) "CONTRIBUTING.md missing '$required'"
}

Write-Output "PASS version governance baseline"
