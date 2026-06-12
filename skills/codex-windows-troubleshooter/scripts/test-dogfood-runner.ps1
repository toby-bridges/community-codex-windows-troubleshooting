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
$fakeBin = Join-Path $artifactRoot "bin"
$fakeGhLog = Join-Path $artifactRoot "fake-gh.log"

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

    New-Item -ItemType Directory -Force -Path $fakeBin | Out-Null
    $fakeGhScript = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GhArgs)

$logPath = $env:CODEX_DOGFOOD_FAKE_GH_LOG
Add-Content -LiteralPath $logPath -Value ($GhArgs -join " ")

if ($GhArgs.Count -ge 2 -and $GhArgs[0] -eq "api" -and $GhArgs[1] -eq "graphql") {
    $queryArg = $GhArgs | Where-Object { $_ -like "query=*" } | Select-Object -First 1
    $query = if ($queryArg) { $queryArg.Substring("query=".Length) } else { "" }
    if ($query.StartsWith("@")) {
        $query = Get-Content -Raw -LiteralPath $query.Substring(1)
    }
    $matches = [regex]::Matches($query, "i(\d+): issue\(number: \d+\)")
    $issues = [ordered]@{}
    foreach ($match in $matches) {
        $number = [int]$match.Groups[1].Value
        $issues["i$number"] = [ordered]@{
            number = $number
            title = "Issue $number"
            state = "OPEN"
            url = "https://github.com/openai/codex/issues/$number"
            updatedAt = "2026-06-12T00:00:00Z"
        }
    }
    [ordered]@{ data = [ordered]@{ repository = $issues } } | ConvertTo-Json -Depth 8
    exit 0
}

if ($GhArgs.Count -ge 3 -and $GhArgs[0] -eq "issue" -and $GhArgs[1] -eq "view") {
    $number = [int]$GhArgs[2]
    [ordered]@{
        number = $number
        title = "Issue $number"
        state = "OPEN"
        url = "https://github.com/openai/codex/issues/$number"
        updatedAt = "2026-06-12T00:00:00Z"
    } | ConvertTo-Json -Depth 4
    exit 0
}

Write-Error "Unexpected gh args: $($GhArgs -join ' ')"
exit 1
'@
    Set-Content -LiteralPath (Join-Path $fakeBin "gh.ps1") -Value $fakeGhScript -Encoding UTF8

    $oldPath = $env:PATH
    $oldFakeLog = $env:CODEX_DOGFOOD_FAKE_GH_LOG
    $env:PATH = "$fakeBin$([System.IO.Path]::PathSeparator)$oldPath"
    $env:CODEX_DOGFOOD_FAKE_GH_LOG = $fakeGhLog
    try {
        $fullOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner `
            -Workspace (Join-Path $artifactRoot "missing-workspace") `
            -Mode Full `
            -ArtifactRoot $artifactRoot
    } finally {
        $env:PATH = $oldPath
        $env:CODEX_DOGFOOD_FAKE_GH_LOG = $oldFakeLog
    }

    Assert-True ($LASTEXITCODE -eq 0) "Full runner exited with code $LASTEXITCODE"
    $fullResult = ($fullOutput -join "`n") | ConvertFrom-Json
    $fullTrace = Get-Content -Raw -LiteralPath $fullResult.tracePath | ConvertFrom-Json
    $fullGhCommands = @($fullTrace.events | Where-Object { $_.name -eq "command" -and $_.data.file -eq "gh" })
    $graphqlCommands = @($fullGhCommands | Where-Object { $_.data.arguments[0] -eq "api" -and $_.data.arguments[1] -eq "graphql" })
    $issueViewCommands = @($fullGhCommands | Where-Object { $_.data.arguments[0] -eq "issue" -and $_.data.arguments[1] -eq "view" })
    $fullIssueEvents = @($fullTrace.events | Where-Object { $_.name -eq "github.issueEvidence" })

    Assert-True ($graphqlCommands.Count -eq 1) "Full mode should issue one gh api graphql command, got $($graphqlCommands.Count)"
    Assert-True ($issueViewCommands.Count -eq 0) "Full mode should not call gh issue view when batch query succeeds"
    Assert-True ($fullIssueEvents.Count -eq 41) "Expected one trace event per issue"
    Assert-True (($fullResult.cases | Where-Object caseId -eq "C002").evidence -match "#26536=OPEN") "Expected batched issue states in case evidence"

    Write-Output "PASS dogfood runner full mode batches GitHub evidence"
} finally {
    if (Test-Path -LiteralPath $artifactRoot) {
        Remove-Item -LiteralPath $artifactRoot -Recurse -Force
    }
}
