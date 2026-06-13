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

function Invoke-PolicyCheck {
    param(
        [string]$Repo,
        [string]$ScriptPath
    )

    Push-Location -LiteralPath $Repo
    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -BaseRef HEAD~1 2>&1
        return [ordered]@{
            exitCode = $LASTEXITCODE
            output = (($output | ForEach-Object { $_.ToString() }) -join "`n")
        }
    } finally {
        Pop-Location
    }
}

function New-PolicyFixture {
    param(
        [string]$Name,
        [scriptblock]$Change
    )

    $root = Join-Path $env:TEMP ("codex-policy-" + $Name + "-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    Push-Location -LiteralPath $root
    try {
        git init | Out-Null
        git config user.name "Codex Policy Test"
        git config user.email "codex-policy@example.invalid"
        New-Item -ItemType Directory -Force -Path "scripts", "skills\codex-windows-troubleshooter", "skills\codex-windows-troubleshooter\references" | Out-Null
        Set-Content -LiteralPath "VERSION" -Value "0.1.0" -Encoding UTF8
        Set-Content -LiteralPath "CHANGELOG.md" -Value "# Changelog`n`n## [Unreleased]`n" -Encoding UTF8
        Set-Content -LiteralPath "README.md" -Value "# README`n" -Encoding UTF8
        Set-Content -LiteralPath "skills\codex-windows-troubleshooter\SKILL.md" -Value "# Skill`n" -Encoding UTF8
        Set-Content -LiteralPath "skills\codex-windows-troubleshooter\references\error-matrix.md" -Value "# Error Matrix`n" -Encoding UTF8
        Set-Content -LiteralPath "DOGFOOD-MATRIX.md" -Value "# Dogfood`n" -Encoding UTF8
        Set-Content -LiteralPath "WINDOWS-CODEX-ERROR-GUIDE.md" -Value "# Guide`n" -Encoding UTF8
        Set-Content -LiteralPath "scripts\tool.ps1" -Value "Write-Output 'old'`n" -Encoding UTF8
        git add . | Out-Null
        git commit -m "baseline" | Out-Null
        & $Change
        git add . | Out-Null
        git commit -m "change" | Out-Null
    } finally {
        Pop-Location
    }
    return $root
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "scripts\check-change-policy.ps1"

Assert-True (Test-Path -LiteralPath $scriptPath) "check-change-policy.ps1 must exist"

$scriptOnlyRepo = New-PolicyFixture -Name "script-only" -Change {
    Set-Content -LiteralPath "scripts\tool.ps1" -Value "Write-Output 'new'`n" -Encoding UTF8
}
$scriptWithDocsRepo = New-PolicyFixture -Name "script-docs" -Change {
    Set-Content -LiteralPath "scripts\tool.ps1" -Value "Write-Output 'new'`n" -Encoding UTF8
    Add-Content -LiteralPath "CHANGELOG.md" -Value "- Changed script behavior."
    Add-Content -LiteralPath "skills\codex-windows-troubleshooter\SKILL.md" -Value "Updated script behavior."
}
$guideOnlyRepo = New-PolicyFixture -Name "guide-only" -Change {
    Add-Content -LiteralPath "WINDOWS-CODEX-ERROR-GUIDE.md" -Value "New case detail."
    Add-Content -LiteralPath "CHANGELOG.md" -Value "- Added guide case detail."
}
$guideWithMatrixRepo = New-PolicyFixture -Name "guide-matrix" -Change {
    Add-Content -LiteralPath "WINDOWS-CODEX-ERROR-GUIDE.md" -Value "New case detail."
    Add-Content -LiteralPath "DOGFOOD-MATRIX.md" -Value "New case row."
    Add-Content -LiteralPath "skills\codex-windows-troubleshooter\references\error-matrix.md" -Value "New case reference."
    Add-Content -LiteralPath "CHANGELOG.md" -Value "- Added guide case detail."
}

try {
    $scriptOnly = Invoke-PolicyCheck -Repo $scriptOnlyRepo -ScriptPath $scriptPath
    Assert-True ($scriptOnly.exitCode -ne 0) "Script-only change should fail"
    Assert-True ($scriptOnly.output -match "script changes require documentation") "Script-only failure should mention docs"
    Assert-True ($scriptOnly.output -match "user-visible changes require CHANGELOG") "Script-only failure should mention changelog"

    $scriptWithDocs = Invoke-PolicyCheck -Repo $scriptWithDocsRepo -ScriptPath $scriptPath
    Assert-True ($scriptWithDocs.exitCode -eq 0) "Script change with docs and changelog should pass: $($scriptWithDocs.output)"

    $guideOnly = Invoke-PolicyCheck -Repo $guideOnlyRepo -ScriptPath $scriptPath
    Assert-True ($guideOnly.exitCode -ne 0) "Guide-only case change should fail"
    Assert-True ($guideOnly.output -match "guide case changes require dogfood or reference updates") "Guide-only failure should mention matrix/reference"

    $guideWithMatrix = Invoke-PolicyCheck -Repo $guideWithMatrixRepo -ScriptPath $scriptPath
    Assert-True ($guideWithMatrix.exitCode -eq 0) "Guide change with matrix/reference and changelog should pass: $($guideWithMatrix.output)"

    Write-Output "PASS change policy checks"
} finally {
    foreach ($repo in @($scriptOnlyRepo, $scriptWithDocsRepo, $guideOnlyRepo, $guideWithMatrixRepo)) {
        if (Test-Path -LiteralPath $repo) {
            Remove-Item -LiteralPath $repo -Recurse -Force
        }
    }
}
