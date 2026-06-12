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

$scriptDir = $PSScriptRoot
$skillRoot = Split-Path -Parent $scriptDir
$repoRoot = Split-Path -Parent (Split-Path -Parent $skillRoot)
$runner = Join-Path $scriptDir "run-codex-windows-dogfood.ps1"
$artifactRoot = Join-Path $env:TEMP ("codex-dogfood-test-" + [Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner `
        -Workspace $repoRoot `
        -Mode Fast `
        -ArtifactRoot $artifactRoot

    Assert-True ($LASTEXITCODE -eq 0) "Runner exited with code $LASTEXITCODE"

    $result = ($output -join "`n") | ConvertFrom-Json
    Assert-True ($result.mode -eq "Fast") "Expected mode Fast, got '$($result.mode)'"
    Assert-True ($result.outputPath -and (Test-Path -LiteralPath $result.outputPath)) "Expected outputPath file to exist"
    Assert-True ($result.tracePath -and (Test-Path -LiteralPath $result.tracePath)) "Expected tracePath file to exist"
    Assert-True (-not $result.diagnosticsPath) "Fast mode should not write diagnostics"
    Assert-True ($result.cases.Count -ge 20) "Expected dogfood cases to still be emitted"

    $trace = Get-Content -Raw -LiteralPath $result.tracePath | ConvertFrom-Json
    $collectEvent = @($trace.events | Where-Object { $_.name -eq "collectDiagnostics" -and $_.phase -eq "skipped" })
    $githubEvent = @($trace.events | Where-Object { $_.name -eq "githubIssueEvidence" -and $_.phase -eq "skipped" })
    $ghCommands = @($trace.events | Where-Object { $_.name -eq "command" -and $_.data.file -eq "gh" })

    Assert-True ($collectEvent.Count -eq 1) "Expected collectDiagnostics to be skipped once"
    Assert-True ($githubEvent.Count -eq 1) "Expected githubIssueEvidence to be skipped once"
    Assert-True ($ghCommands.Count -eq 0) "Fast mode should not run gh commands"

    Write-Output "PASS dogfood runner fast mode"
} finally {
    if (Test-Path -LiteralPath $artifactRoot) {
        Remove-Item -LiteralPath $artifactRoot -Recurse -Force
    }
}
