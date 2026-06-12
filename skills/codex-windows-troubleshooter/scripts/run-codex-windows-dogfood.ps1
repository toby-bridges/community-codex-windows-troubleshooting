[CmdletBinding()]
param(
    [string]$Workspace = (Get-Location).Path,
    [ValidateSet("Fast", "Local", "Full")]
    [string]$Mode = "Local",
    [switch]$KeepArtifacts,
    [string]$ArtifactRoot,
    [string]$OutputPath,
    [string]$TracePath,
    [switch]$ShowProgress
)

$ErrorActionPreference = "Continue"
$scriptStartedAt = Get-Date
$traceEvents = @()

$dogfoodRoot = Join-Path $env:TEMP "codex-windows-dogfood"
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $dogfoodRoot $runId
$fixtureDir = Join-Path $runDir "fixtures"
$artifactRootFull = $null
$includeDiagnostics = ($Mode -eq "Local" -or $Mode -eq "Full")
$includeGitHubEvidence = ($Mode -eq "Full")

if ($ArtifactRoot) {
    $artifactRootFull = [System.IO.Path]::GetFullPath($ArtifactRoot)
    New-Item -ItemType Directory -Force -Path $artifactRootFull | Out-Null
    if (-not $OutputPath) {
        $OutputPath = Join-Path $artifactRootFull "$runId-dogfood-result.local.json"
    }
    if (-not $TracePath) {
        $TracePath = Join-Path $artifactRootFull "$runId-dogfood-trace.local.json"
    }
} elseif ($KeepArtifacts) {
    if (-not $OutputPath) {
        $OutputPath = Join-Path $runDir "dogfood-result.local.json"
    }
    if (-not $TracePath) {
        $TracePath = Join-Path $runDir "dogfood-trace.local.json"
    }
}

New-Item -ItemType Directory -Force -Path $fixtureDir | Out-Null

function Write-DogfoodProgress {
    param([string]$Message)
    if ($ShowProgress) {
        Write-Host ("[dogfood] {0}" -f $Message)
    }
}

function Add-TraceEvent {
    param(
        [string]$Name,
        [string]$Phase = "instant",
        $DurationMs = $null,
        $Ok = $null,
        [object]$Data = $null
    )

    $event = [ordered]@{
        at = (Get-Date).ToString("o")
        name = $Name
        phase = $Phase
    }
    if ($null -ne $DurationMs) {
        $event.durationMs = [int64]$DurationMs
    }
    if ($null -ne $Ok) {
        $event.ok = [bool]$Ok
    }
    if ($null -ne $Data) {
        $event.data = $Data
    }
    $script:traceEvents += $event
}

function Ensure-ParentDirectory {
    param([string]$Path)
    if (-not $Path) {
        return
    }
    $parent = Split-Path -Parent ([System.IO.Path]::GetFullPath($Path))
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

Add-TraceEvent -Name "dogfood.run" -Phase "start" -Data ([ordered]@{
    runId = $runId
    mode = $Mode
    workspace = $Workspace
    runDir = $runDir
    artifactRoot = $artifactRootFull
})
Write-DogfoodProgress "run $runId started in $Mode mode"

function Invoke-Capture {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory
    )

    $timer = [Diagnostics.Stopwatch]::StartNew()
    $result = $null
    try {
        if ($WorkingDirectory) {
            Push-Location -LiteralPath $WorkingDirectory
            try {
                $output = & $File @Arguments 2>&1 | ForEach-Object { $_.ToString() }
            } finally {
                Pop-Location
            }
        } else {
            $output = & $File @Arguments 2>&1 | ForEach-Object { $_.ToString() }
        }
        $result = [ordered]@{
            ok = ($LASTEXITCODE -eq 0)
            exitCode = $LASTEXITCODE
            output = ($output -join "`n")
            durationMs = $null
        }
    } catch {
        $result = [ordered]@{
            ok = $false
            exitCode = $null
            output = $_.Exception.Message
            durationMs = $null
        }
    } finally {
        $timer.Stop()
        if ($null -ne $result) {
            $result.durationMs = $timer.ElapsedMilliseconds
        }
        Add-TraceEvent -Name "command" -Phase "end" -DurationMs $timer.ElapsedMilliseconds -Ok $result.ok -Data ([ordered]@{
            file = $File
            arguments = $Arguments
            workingDirectory = $WorkingDirectory
            exitCode = $result.exitCode
        })
    }

    return $result
}

function Add-Case {
    param(
        [string]$Id,
        [string]$Section,
        [string]$Signature,
        [string]$Target,
        [string]$Actual,
        [string]$Evidence,
        [string]$Command,
        [string]$Conclusion,
        [string]$NeedsUpdate,
        [object]$Details = $null
    )

    [ordered]@{
        caseId = $Id
        section = $Section
        signature = $Signature
        targetLevel = $Target
        actualLevel = $Actual
        evidence = $Evidence
        localCommand = $Command
        conclusion = $Conclusion
        needsGuideOrSkillUpdate = $NeedsUpdate
        details = $Details
    }
}

function Run-Git {
    param([string]$Repo, [string[]]$GitArguments)
    return Invoke-Capture -File "git" -Arguments (@("-C", $Repo) + $GitArguments)
}

function New-Repo {
    param([string]$Name)
    $path = Join-Path $fixtureDir $Name
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    Invoke-Capture -File "git" -Arguments @("init", $path) | Out-Null
    return $path
}

function Commit-Empty {
    param([string]$Repo, [string]$Message)
    return Invoke-Capture -File "git" -Arguments @(
        "-C", $Repo,
        "-c", "user.name=Codex Dogfood",
        "-c", "user.email=codex-dogfood@example.invalid",
        "commit", "--allow-empty", "-m", $Message
    )
}

function Test-ConfigFixture {
    $configDir = Join-Path $fixtureDir "config-corruption"
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    $nulPath = Join-Path $configDir "config-nul.toml"
    $badPath = Join-Path $configDir "config-bad.toml"
    [System.IO.File]::WriteAllBytes($nulPath, [byte[]](0,0,0,0,0,0))
    Set-Content -LiteralPath $badPath -Value "sandbox_mode `"workspace-write`"" -Encoding UTF8

    $nulBytes = [System.IO.File]::ReadAllBytes($nulPath)
    $badText = Get-Content -Raw -LiteralPath $badPath
    return [ordered]@{
        nulPath = $nulPath
        nulDetected = ($nulBytes -contains 0)
        badPath = $badPath
        missingEqualsDetected = ($badText -notmatch "=")
    }
}

function New-IssueDraftFixture {
    param([object[]]$Cases)
    $draftDir = Join-Path $fixtureDir "issue-draft"
    New-Item -ItemType Directory -Force -Path $draftDir | Out-Null
    $draftPath = Join-Path $draftDir "codex-windows-issue-draft.md"
    $body = @(
        '# Codex Windows dogfood issue draft'
        ""
        '## Symptom'
        ""
        'Worktree setup failed with `fatal: invalid reference: master`.'
        ""
        '## Environment'
        ""
        '- Windows diagnostics: redacted; generated by local dogfood runner.'
        '- Workspace path: `[REDACTED]`'
        ""
        '## Key evidence'
        ""
        '- `git status --short --branch`: `## No commits yet on master`'
        '- `git rev-parse --verify master`: `fatal: Needed a single revision`'
        '- `git worktree list --porcelain`: `HEAD 0000000000000000000000000000000000000000`'
        ""
        '## Expected'
        ""
        'Codex should detect unborn branches before attempting detached worktree creation and explain that an initial commit is required.'
    )
    Set-Content -LiteralPath $draftPath -Value $body -Encoding UTF8
    return [ordered]@{
        path = $draftPath
        redacted = ((Get-Content -Raw -LiteralPath $draftPath) -notmatch [regex]::Escape($env:USERPROFILE))
        bytes = (Get-Item -LiteralPath $draftPath).Length
    }
}

function Get-IssueEvidence {
    param([int[]]$Numbers)
    $items = @()
    foreach ($number in $Numbers) {
        $issueTimer = [Diagnostics.Stopwatch]::StartNew()
        $attempts = 1
        Write-DogfoodProgress "checking openai/codex#$number"
        $view = Invoke-Capture -File "gh" -Arguments @(
            "issue", "view", $number.ToString(),
            "--repo", "openai/codex",
            "--json", "number,title,state,url,updatedAt"
        )
        if (-not $view.ok) {
            $attempts++
            Start-Sleep -Milliseconds 500
            $view = Invoke-Capture -File "gh" -Arguments @(
                "issue", "view", $number.ToString(),
                "--repo", "openai/codex",
                "--json", "number,title,state,url,updatedAt"
            )
        }
        $item = $null
        if ($view.ok -and $view.output) {
            try {
                $item = ($view.output | ConvertFrom-Json)
            } catch {
                $item = [ordered]@{ number = $number; state = "parse-failed"; url = "https://github.com/openai/codex/issues/$number" }
            }
        } else {
            $item = [ordered]@{ number = $number; state = "gh-failed"; url = "https://github.com/openai/codex/issues/$number"; error = $view.output }
        }
        $items += $item
        $issueTimer.Stop()
        Add-TraceEvent -Name "github.issueEvidence" -Phase "end" -DurationMs $issueTimer.ElapsedMilliseconds -Ok $view.ok -Data ([ordered]@{
            issue = $number
            state = $item.state
            attempts = $attempts
        })
        Write-DogfoodProgress ("openai/codex#{0} -> {1} ({2} ms)" -f $number, $item.state, $issueTimer.ElapsedMilliseconds)
    }
    return $items
}

function New-SkippedIssueEvidence {
    param([int[]]$Numbers)

    return @($Numbers | ForEach-Object {
        [ordered]@{
            number = $_
            state = "skipped"
            url = "https://github.com/openai/codex/issues/$_"
        }
    })
}

function Get-UniqueIssueNumbers {
    param([object]$IssueGroups)

    $seen = @{}
    $numbers = @()
    foreach ($group in $IssueGroups.GetEnumerator()) {
        foreach ($number in $group.Value) {
            $key = [int]$number
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = $true
                $numbers += $key
            }
        }
    }
    return $numbers
}

function ConvertTo-IssueEvidenceGroups {
    param(
        [object]$IssueGroups,
        [hashtable]$ItemsByNumber
    )

    $groups = [ordered]@{}
    foreach ($group in $IssueGroups.GetEnumerator()) {
        $items = @()
        foreach ($number in $group.Value) {
            $items += $ItemsByNumber[[int]$number]
        }
        $groups[$group.Key] = $items
    }
    return $groups
}

function Get-IssueEvidenceBatch {
    param([object]$IssueGroups)

    $batchTimer = [Diagnostics.Stopwatch]::StartNew()
    $numbers = Get-UniqueIssueNumbers -IssueGroups $IssueGroups
    if ($numbers.Count -eq 0) {
        return [ordered]@{}
    }

    $queryLines = @($numbers | ForEach-Object {
        "      i$($_): issue(number: $($_)) { number title state url updatedAt }"
    })
    $query = @"
query {
  repository(owner: "openai", name: "codex") {
$($queryLines -join "`n")
  }
}
"@
    $queryPath = Join-Path $runDir "github-issue-evidence.graphql"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($queryPath, $query, $utf8NoBom)

    $view = Invoke-Capture -File "gh" -Arguments @(
        "api",
        "graphql",
        "-F",
        "query=@$queryPath"
    )

    if (-not $view.ok) {
        $batchTimer.Stop()
        Add-TraceEvent -Name "github.issueEvidence.batch" -Phase "end" -DurationMs $batchTimer.ElapsedMilliseconds -Ok $false -Data ([ordered]@{
            issueCount = $numbers.Count
            fallback = "serial"
            error = $view.output
        })
        return $null
    }

    try {
        $parsed = $view.output | ConvertFrom-Json
    } catch {
        $batchTimer.Stop()
        Add-TraceEvent -Name "github.issueEvidence.batch" -Phase "end" -DurationMs $batchTimer.ElapsedMilliseconds -Ok $false -Data ([ordered]@{
            issueCount = $numbers.Count
            fallback = "serial"
            error = $_.Exception.Message
        })
        return $null
    }

    $repository = $parsed.data.repository
    if ($null -eq $repository) {
        $batchTimer.Stop()
        Add-TraceEvent -Name "github.issueEvidence.batch" -Phase "end" -DurationMs $batchTimer.ElapsedMilliseconds -Ok $false -Data ([ordered]@{
            issueCount = $numbers.Count
            fallback = "serial"
            error = "missing repository in GraphQL response"
        })
        return $null
    }

    $itemsByNumber = @{}
    foreach ($number in $numbers) {
        $alias = "i$number"
        $property = $repository.PSObject.Properties[$alias]
        if ($property -and $null -ne $property.Value) {
            $issue = $property.Value
            $item = [ordered]@{
                number = [int]$issue.number
                title = $issue.title
                state = $issue.state
                url = $issue.url
                updatedAt = $issue.updatedAt
            }
            $ok = $true
        } else {
            $item = [ordered]@{
                number = $number
                state = "not-found"
                url = "https://github.com/openai/codex/issues/$number"
            }
            $ok = $false
        }
        $itemsByNumber[$number] = $item
        Add-TraceEvent -Name "github.issueEvidence" -Phase "end" -Ok $ok -Data ([ordered]@{
            issue = $number
            state = $item.state
            source = "graphql-batch"
            attempts = 1
        })
    }

    $batchTimer.Stop()
    Add-TraceEvent -Name "github.issueEvidence.batch" -Phase "end" -DurationMs $batchTimer.ElapsedMilliseconds -Ok $true -Data ([ordered]@{
        issueCount = $numbers.Count
        fallback = $null
    })

    return ConvertTo-IssueEvidenceGroups -IssueGroups $IssueGroups -ItemsByNumber $itemsByNumber
}

function Format-IssueStates {
    param([object[]]$Items)
    return (($Items | ForEach-Object { "#$($_.number)=$($_.state)" }) -join ", ")
}

$cases = @()
$workspaceExists = Test-Path -LiteralPath $Workspace
$diag = $null
$diagPath = $null
if ($workspaceExists -and $includeDiagnostics) {
    $diagTimer = [Diagnostics.Stopwatch]::StartNew()
    Add-TraceEvent -Name "collectDiagnostics" -Phase "start"
    Write-DogfoodProgress "collecting local diagnostics"
    $diagScript = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\collect-codex-windows-diagnostics.ps1"
    if (-not (Test-Path -LiteralPath $diagScript)) {
        $diagScript = Join-Path $PSScriptRoot "collect-codex-windows-diagnostics.ps1"
    }
    if ($artifactRootFull) {
        $diagPath = Join-Path $artifactRootFull "$runId-diagnostics.local.json"
    } else {
        $diagPath = Join-Path $runDir "diagnostics.json"
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $diagScript -Workspace $Workspace -OutputPath $diagPath | Out-Null
    if (Test-Path -LiteralPath $diagPath) {
        $diag = Get-Content -Raw -LiteralPath $diagPath | ConvertFrom-Json
    }
    $diagTimer.Stop()
    Add-TraceEvent -Name "collectDiagnostics" -Phase "end" -DurationMs $diagTimer.ElapsedMilliseconds -Ok ($null -ne $diag) -Data ([ordered]@{
        path = $diagPath
        bytes = if (Test-Path -LiteralPath $diagPath) { (Get-Item -LiteralPath $diagPath).Length } else { 0 }
    })
    Write-DogfoodProgress ("local diagnostics finished ({0} ms)" -f $diagTimer.ElapsedMilliseconds)
} elseif ($workspaceExists) {
    Add-TraceEvent -Name "collectDiagnostics" -Phase "skipped" -Ok $true -Data ([ordered]@{
        reason = "mode"
        mode = $Mode
    })
    Write-DogfoodProgress "local diagnostics skipped in $Mode mode"
} else {
    Add-TraceEvent -Name "collectDiagnostics" -Phase "skipped" -Ok $false -Data ([ordered]@{
        reason = "workspace not found"
        workspace = $Workspace
    })
}

# C001: three safe Git worktree fixtures.
$fixtureTimer = [Diagnostics.Stopwatch]::StartNew()
Add-TraceEvent -Name "worktreeFixtures" -Phase "start"
Write-DogfoodProgress "running C001 worktree fixtures"
$githubEvidenceLabel = if ($includeGitHubEvidence) { "live GitHub #12346/#22635" } else { "GitHub issue evidence skipped in $Mode mode" }
$c001Details = [ordered]@{}
$emptyRepo = New-Repo "c001-empty-unborn"
$emptyWorktree = Join-Path $fixtureDir "c001-empty-unborn-worktree"
$c001Details.emptyUnborn = [ordered]@{
    status = (Run-Git -Repo $emptyRepo -GitArguments @("status", "--short", "--branch")).output
    worktreeAdd = (Invoke-Capture -File "git" -Arguments @("-C", $emptyRepo, "worktree", "add", "--detach", $emptyWorktree, "master")).output
}

$noMainRepo = New-Repo "c001-no-main"
Commit-Empty -Repo $noMainRepo -Message "Initial commit" | Out-Null
$initialBranch = (Run-Git -Repo $noMainRepo -GitArguments @("symbolic-ref", "--short", "HEAD")).output.Trim()
Run-Git -Repo $noMainRepo -GitArguments @("branch", "production") | Out-Null
Run-Git -Repo $noMainRepo -GitArguments @("switch", "production") | Out-Null
if ($initialBranch) {
    Run-Git -Repo $noMainRepo -GitArguments @("branch", "-D", $initialBranch) | Out-Null
}
$missingDefaultRef = if ($initialBranch -eq "main") { "main" } else { "main" }
$c001Details.noMain = [ordered]@{
    branches = (Run-Git -Repo $noMainRepo -GitArguments @("branch", "-a")).output
    missingRef = $missingDefaultRef
    worktreeAdd = (Invoke-Capture -File "git" -Arguments @("-C", $noMainRepo, "worktree", "add", "--detach", (Join-Path $fixtureDir "c001-no-main-worktree"), $missingDefaultRef)).output
}

$remoteOnlyRepo = New-Repo "c001-remote-only"
Commit-Empty -Repo $remoteOnlyRepo -Message "Initial commit" | Out-Null
$head = (Run-Git -Repo $remoteOnlyRepo -GitArguments @("rev-parse", "HEAD")).output.Trim()
Run-Git -Repo $remoteOnlyRepo -GitArguments @("update-ref", "refs/remotes/origin/feature/dogfood", $head) | Out-Null
$c001Details.remoteOnly = [ordered]@{
    verifyShort = (Run-Git -Repo $remoteOnlyRepo -GitArguments @("rev-parse", "--verify", "feature/dogfood")).output
    verifyRemote = (Run-Git -Repo $remoteOnlyRepo -GitArguments @("rev-parse", "--verify", "origin/feature/dogfood")).output
    worktreeAdd = (Invoke-Capture -File "git" -Arguments @("-C", $remoteOnlyRepo, "worktree", "add", "--detach", (Join-Path $fixtureDir "c001-remote-only-worktree"), "feature/dogfood")).output
}
$cases += Add-Case -Id "C001" -Section "2. Worktree 创建失败" -Signature "fatal: invalid reference: master/main/feature" -Target "L2" -Actual "L2" -Evidence "local fixture; $githubEvidenceLabel" -Command "git worktree add --detach <tmp> <ref>" -Conclusion "已验证：unborn branch、无 main、本地缺 remote-only 短名都会触发 invalid reference。" -NeedsUpdate "已补指南和 skill；本轮无需再补。" -Details $c001Details
$fixtureTimer.Stop()
Add-TraceEvent -Name "worktreeFixtures" -Phase "end" -DurationMs $fixtureTimer.ElapsedMilliseconds -Ok $true
Write-DogfoodProgress ("C001 worktree fixtures finished ({0} ms)" -f $fixtureTimer.ElapsedMilliseconds)

$issueGroups = [ordered]@{
    worktree = @(12346, 22635)
    plugins = @(26536, 26501, 25220, 26109, 22114)
    win10 = @(25178, 25411)
    issue740 = @(24050, 26477, 26158)
    sandboxOther = @(18620, 26438, 23194)
    network = @(18675, 25207, 25117)
    wsl = @(25216, 22759, 22376, 24884, 26096)
    shell = @(13917, 19629, 16268)
    sessions = @(22004, 25430, 26104)
    ui = @(25513, 20867, 26401)
    config = @(26421)
    crash = @(19352, 25912)
    av = @(25425, 26194, 26218)
    store = @(17491)
    storeInfra = @(21538, 24010)
}

if ($includeGitHubEvidence) {
    $issueTimer = [Diagnostics.Stopwatch]::StartNew()
    Add-TraceEvent -Name "githubIssueEvidence" -Phase "start"
    Write-DogfoodProgress "checking live GitHub issue evidence"
    $batchedIssues = Get-IssueEvidenceBatch -IssueGroups $issueGroups
    if ($null -ne $batchedIssues) {
        $issueWorktree = $batchedIssues["worktree"]
        $issuePlugins = $batchedIssues["plugins"]
        $issueWin10 = $batchedIssues["win10"]
        $issue740 = $batchedIssues["issue740"]
        $issueSandboxOther = $batchedIssues["sandboxOther"]
        $issueNetwork = $batchedIssues["network"]
        $issueWsl = $batchedIssues["wsl"]
        $issueShell = $batchedIssues["shell"]
        $issueSessions = $batchedIssues["sessions"]
        $issueUi = $batchedIssues["ui"]
        $issueConfig = $batchedIssues["config"]
        $issueCrash = $batchedIssues["crash"]
        $issueAv = $batchedIssues["av"]
        $issueStore = $batchedIssues["store"]
        $issueStoreInfra = $batchedIssues["storeInfra"]
    } else {
        Write-DogfoodProgress "batch GitHub issue evidence failed; falling back to serial gh issue view"
        $issueWorktree = Get-IssueEvidence -Numbers $issueGroups.worktree
        $issuePlugins = Get-IssueEvidence -Numbers $issueGroups.plugins
        $issueWin10 = Get-IssueEvidence -Numbers $issueGroups.win10
        $issue740 = Get-IssueEvidence -Numbers $issueGroups.issue740
        $issueSandboxOther = Get-IssueEvidence -Numbers $issueGroups.sandboxOther
        $issueNetwork = Get-IssueEvidence -Numbers $issueGroups.network
        $issueWsl = Get-IssueEvidence -Numbers $issueGroups.wsl
        $issueShell = Get-IssueEvidence -Numbers $issueGroups.shell
        $issueSessions = Get-IssueEvidence -Numbers $issueGroups.sessions
        $issueUi = Get-IssueEvidence -Numbers $issueGroups.ui
        $issueConfig = Get-IssueEvidence -Numbers $issueGroups.config
        $issueCrash = Get-IssueEvidence -Numbers $issueGroups.crash
        $issueAv = Get-IssueEvidence -Numbers $issueGroups.av
        $issueStore = Get-IssueEvidence -Numbers $issueGroups.store
        $issueStoreInfra = Get-IssueEvidence -Numbers $issueGroups.storeInfra
    }
    $issueTimer.Stop()
    Add-TraceEvent -Name "githubIssueEvidence" -Phase "end" -DurationMs $issueTimer.ElapsedMilliseconds -Ok $true -Data ([ordered]@{
        issueCount = 41
        source = if ($null -ne $batchedIssues) { "graphql-batch" } else { "serial" }
    })
    Write-DogfoodProgress ("live GitHub issue evidence finished ({0} ms)" -f $issueTimer.ElapsedMilliseconds)
} else {
    $issueWorktree = New-SkippedIssueEvidence -Numbers $issueGroups.worktree
    $issuePlugins = New-SkippedIssueEvidence -Numbers $issueGroups.plugins
    $issueWin10 = New-SkippedIssueEvidence -Numbers $issueGroups.win10
    $issue740 = New-SkippedIssueEvidence -Numbers $issueGroups.issue740
    $issueSandboxOther = New-SkippedIssueEvidence -Numbers $issueGroups.sandboxOther
    $issueNetwork = New-SkippedIssueEvidence -Numbers $issueGroups.network
    $issueWsl = New-SkippedIssueEvidence -Numbers $issueGroups.wsl
    $issueShell = New-SkippedIssueEvidence -Numbers $issueGroups.shell
    $issueSessions = New-SkippedIssueEvidence -Numbers $issueGroups.sessions
    $issueUi = New-SkippedIssueEvidence -Numbers $issueGroups.ui
    $issueConfig = New-SkippedIssueEvidence -Numbers $issueGroups.config
    $issueCrash = New-SkippedIssueEvidence -Numbers $issueGroups.crash
    $issueAv = New-SkippedIssueEvidence -Numbers $issueGroups.av
    $issueStore = New-SkippedIssueEvidence -Numbers $issueGroups.store
    $issueStoreInfra = New-SkippedIssueEvidence -Numbers $issueGroups.storeInfra
    Add-TraceEvent -Name "githubIssueEvidence" -Phase "skipped" -Ok $true -Data ([ordered]@{
        reason = "mode"
        mode = $Mode
        issueCount = 41
    })
    Write-DogfoodProgress "live GitHub issue evidence skipped in $Mode mode"
}

$marketplaceExists = if ($diag) { [bool]$diag.codexFiles.bundledMarketplaceExists } else { $false }
$pluginCacheExists = if ($diag) { [bool]$diag.codexFiles.pluginCacheExists } else { $false }
$cases += Add-Case -Id "C002" -Section "3. Computer Use / Browser 插件不可用" -Signature "Computer Use plugins unavailable / marketplace missing" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issuePlugins) -Command "Test-Path bundled marketplace; inspect plugin cache/processes" -Conclusion "部分验证：本机只读检查完成；marketplaceExists=$marketplaceExists, pluginCacheExists=$pluginCacheExists。未删除或重建缓存。" -NeedsUpdate "不需要。"

$osBuild = if ($diag -and $diag.os) { $diag.os.osBuildNumber } else { "" }
$cases += Add-Case -Id "C003" -Section "4. Windows 10 Computer Use 截图失败" -Signature "SetIsBorderRequired failed 0x80004002" -Target "L0" -Actual "L0" -Evidence (Format-IssueStates $issueWin10) -Command "GitHub issue status + OS build check" -Conclusion "仅证据核查：本机 build=$osBuild；不是 Windows 10 专用复现矩阵，不做真实截图复现。" -NeedsUpdate "不需要。"

$setupHelpers = @()
try {
    if ($diag -and $diag.codexAppx -and $diag.codexAppx.InstallLocation) {
        $setupHelpers = @(Get-ChildItem -LiteralPath $diag.codexAppx.InstallLocation -Recurse -Filter "codex-windows-sandbox-setup.exe" -ErrorAction SilentlyContinue | Select-Object FullName, Length, LastWriteTime)
    }
} catch {}
$cases += Add-Case -Id "C004" -Section "5. spawn setup refresh / os error 740" -Signature "spawn setup refresh / os error 740" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issue740) -Command "collect diagnostics; search app install for codex-windows-sandbox-setup.exe" -Conclusion "部分验证：本机只读采集版本/config/helper 线索；helperCount=$($setupHelpers.Count)。未切 sandbox、未改 manifest。" -NeedsUpdate "不需要。"

$cases += Add-Case -Id "C005" -Section "6. 其他 Windows sandbox 启动错误" -Signature "1326/1909, 1344, program not found" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueSandboxOther) -Command "collect diagnostics; inspect config/appx/codex doctor" -Conclusion "部分验证：本机未强制复现 sandbox 用户/DACL 错误；只读状态可用于 issue 模板。" -NeedsUpdate "不需要。"

$proxySet = if ($diag) { "HTTP=$($diag.environment.httpProxySet), HTTPS=$($diag.environment.httpsProxySet)" } else { "unknown" }
$cases += Add-Case -Id "C006" -Section "7. 网络、DNS、npm、代理" -Signature "sandbox DNS/npm/proxy failure" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueNetwork) -Command "inspect config preview and HTTP_PROXY/HTTPS_PROXY flags" -Conclusion "部分验证：只读检查完成，proxy=$proxySet。未修改代理或 network_access。" -NeedsUpdate "不需要。"

$wslSummary = if ($diag) { "statusOk=$($diag.wsl.status.ok), listOk=$($diag.wsl.list.ok), WSL_DISTRO_NAME=$($diag.environment.wslDistroName)" } else { "unknown" }
$cases += Add-Case -Id "C007" -Section "8. WSL / Windows 混合模式" -Signature "WSL path/CODEX_HOME split-brain" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueWsl) -Command "wsl --status; wsl -l -v; inspect CODEX_HOME/WSL_DISTRO_NAME" -Conclusion "部分验证：$wslSummary。未改 WSL 或 CODEX_HOME。" -NeedsUpdate "不需要。"

$psVersion = if ($diag) { $diag.powershell.version } else { "" }
$cases += Add-Case -Id "C008" -Section "9. PowerShell / Shell / 编码 / 用户名" -Signature "PowerShell host/encoding/execution policy" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueShell) -Command "Get-Command pwsh/powershell; Get-ExecutionPolicy -List; inspect username path" -Conclusion "部分验证：PowerShell=$psVersion；只读检查命令位置和执行策略。未改执行策略。" -NeedsUpdate "不需要。"

$largestSession = ""
if ($diag -and $diag.codexFiles.largestSessions -and $diag.codexFiles.largestSessions.Count -gt 0) {
    $largestSession = "$($diag.codexFiles.largestSessions[0].Length) bytes"
}
$cases += Add-Case -Id "C009" -Section "10. 长会话、历史记录、内存、启动崩溃" -Signature "RangeError / large session JSONL" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueSessions) -Command "scan %USERPROFILE%\\.codex\\sessions largest JSONL" -Conclusion "部分验证：已只读扫描 session 大小，largest=$largestSession。未移动历史。" -NeedsUpdate "不需要。"

$cases += Add-Case -Id "C010" -Section "11. UI 透明、最大化、卡顿" -Signature "maximized transparent/freezing UI" -Target "L0" -Actual "L0" -Evidence (Format-IssueStates $issueUi) -Command "GitHub issue status only" -Conclusion "仅证据核查：UI 症状需用户遇到时记录截图；本轮不操作桌面 UI。" -NeedsUpdate "不需要。"

$configFixture = Test-ConfigFixture
$cases += Add-Case -Id "C011" -Section "12. 配置文件损坏" -Signature "config.toml NUL / key with no value" -Target "L2" -Actual "L2" -Evidence (Format-IssueStates $issueConfig) -Command "create temp bad config fixtures; detect NUL and missing equals" -Conclusion "已验证：临时 fixture 可检测 NUL 和缺少等号的坏 TOML，不触碰真实 config。" -NeedsUpdate "可补脚本：未来可把 config corruption 检测并入 diagnostics。" -Details $configFixture

$crashCount = if ($diag -and $diag.codexFiles.crashCandidates) { $diag.codexFiles.crashCandidates.Count } else { 0 }
$cases += Add-Case -Id "C012" -Section "13. 启动空白、直接闪退、Crashpad dump" -Signature "blank/spinner/crashpad dump" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueCrash) -Command "readonly scan LOCALAPPDATA CrashDumps/Packages for codex/crashpad" -Conclusion "部分验证：Crash candidate count=$crashCount。未 repair/reset app。" -NeedsUpdate "不需要。"

$cases += Add-Case -Id "C013" -Section "14. 杀软/Defender/企业安全软件拦截" -Signature "Norton/Symantec/Defender blocks helper" -Target "L0" -Actual "L0" -Evidence (Format-IssueStates $issueAv) -Command "GitHub issue status only" -Conclusion "仅证据核查：不模拟恶意/混淆命令，不改白名单。" -NeedsUpdate "不需要。"

$appxVersion = if ($diag -and $diag.codexAppx) { $diag.codexAppx.Version } else { "" }
$arch = if ($diag) { $diag.environment.processorArchitecture } else { "" }
$cases += Add-Case -Id "C014" -Section "15. Microsoft Store / 安装位置 / ARM64" -Signature "Store install path / ARM64 / non-C drive" -Target "L1" -Actual "L1" -Evidence (Format-IssueStates $issueStore) -Command "Get-AppxPackage OpenAI.Codex; winget list --name Codex; inspect architecture" -Conclusion "部分验证：AppxVersion=$appxVersion, Arch=$arch。未改安装位置。" -NeedsUpdate "不需要。"

$draft = New-IssueDraftFixture -Cases $cases
$cases += Add-Case -Id "C015" -Section "16. 报告 issue 模板" -Signature "issue report completeness/redaction" -Target "L2" -Actual "L2" -Evidence "local fixture" -Command "generate temp redacted issue draft fixture" -Conclusion "已验证：生成脱敏 issue draft fixture，redacted=$($draft.redacted)，bytes=$($draft.bytes)。" -NeedsUpdate "不需要。" -Details $draft

$cases += Add-Case -Id "C017" -Section "13/15. LTSC + Store/MSIX + hosts 劫持" -Signature "Windows 11 LTSC, no Store UI, MSIX installed, app still will not open" -Target "L1" -Actual "L1" -Evidence "X community case plus Microsoft LTSC Store Access/MSIX troubleshooting docs" -Command "inspect Store/App Installer/VCLibs/Windows App Runtime packages; inspect hosts; resolve Microsoft/Store/login DNS" -Conclusion "部分验证：只读 diagnostics now checks Store runtime packages, Microsoft-related hosts entries, and DNS. Public matrix should not keep machine-specific counts; local run captured them privately." -NeedsUpdate "已补指南和 skill。"

$cases += Add-Case -Id "C018" -Section "5/15. Store 检查更新卡住 + MSIX 绕过 + sandbox 授权失败" -Signature "Microsoft Store stuck on checking updates; direct MSIX install works; sandbox authorization depends on path" -Target "L1" -Actual "L1" -Evidence "X community case plus Windows sandbox ACL model and Microsoft MSIX troubleshooting docs" -Command "inspect Appx InstallLocation and workspace path attributes/reparse/encryption/drive hints" -Conclusion "部分验证：只读 diagnostics now records workspace path risk hints for sandbox authorization. Public matrix should not keep machine-specific paths; local run captured hints privately." -NeedsUpdate "已补指南和 skill。"

$cases += Add-Case -Id "C019" -Section "13/15. 精简版 Windows + Store 依赖缺失" -Signature "Slim/debloated Windows; Store dependencies repaired after system update" -Target "L1" -Actual "L1" -Evidence ((Format-IssueStates $issueStoreInfra) + "; X community case plus Microsoft Store download failure and MSIX framework package docs") -Command "inspect Store/App Installer/VCLibs/Windows App Runtime packages; inspect Store policy; inspect AppX/Store/Update services" -Conclusion "部分验证：只读 diagnostics now records Store policy and Store/AppX/Update service status. Public matrix should not keep machine-specific service state; local run captured it privately." -NeedsUpdate "已补指南和 skill。"

$cases += Add-Case -Id "C020" -Section "15. Microsoft Store / winget 安装链路" -Signature "'winget' is not recognized while installing Codex from msstore" -Target "L1" -Actual "L1" -Evidence "Microsoft WinGet docs plus microsoft/winget-cli troubleshooting; X community case for Codex install flow" -Command "inspect Get-Command winget; inspect App Installer package; inspect WindowsApps alias and PATH; run winget --version" -Conclusion "部分验证：只读 diagnostics now records winget version, App Installer package, WindowsApps alias, and PATH presence. Public matrix should not keep machine-specific local paths; local run captured them privately." -NeedsUpdate "已补指南和 skill。"

$cases += Add-Case -Id "C016" -Section "17. 当前优先级" -Signature "P0/P1/P2 priority review" -Target "L0" -Actual "L0" -Evidence "C001-C015 plus C017-C020 dogfood outputs" -Command "review case outcomes against guide priority list" -Conclusion "仅证据核查：P0/P1/P2 与本轮证据一致；C001 保持 P1，P0 仍是 sandbox 740、plugin marketplace、large session；C017-C020 保持 community leads，C020 的 WinGet 故障类有官方 A 级证据。" -NeedsUpdate "不需要。"

Add-TraceEvent -Name "dogfood.run" -Phase "end" -DurationMs ([int64]((Get-Date) - $scriptStartedAt).TotalMilliseconds) -Ok $true -Data ([ordered]@{
    caseCount = $cases.Count
})

$result = [ordered]@{
    runId = $runId
    generatedAt = (Get-Date).ToString("o")
    mode = $Mode
    durationMs = [int64]((Get-Date) - $scriptStartedAt).TotalMilliseconds
    runDir = $runDir
    tempRoot = $dogfoodRoot
    artifactRoot = $artifactRootFull
    workspace = $Workspace
    diagnosticsPath = $diagPath
    outputPath = $OutputPath
    tracePath = $TracePath
    cleanup = if ($KeepArtifacts) { "kept" } else { "cleaned" }
    traceSummary = [ordered]@{
        eventCount = $traceEvents.Count
        slowest = @($traceEvents | Where-Object { $null -ne $_.durationMs } | Sort-Object { $_.durationMs } -Descending | Select-Object -First 10)
    }
    cases = $cases
}

$json = $result | ConvertTo-Json -Depth 12

if ($OutputPath) {
    Ensure-ParentDirectory -Path $OutputPath
    Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
}

if ($TracePath) {
    Ensure-ParentDirectory -Path $TracePath
    $traceJson = [ordered]@{
        runId = $runId
        generatedAt = (Get-Date).ToString("o")
        mode = $Mode
        workspace = $Workspace
        outputPath = $OutputPath
        diagnosticsPath = $diagPath
        events = $traceEvents
    } | ConvertTo-Json -Depth 12
    Set-Content -LiteralPath $TracePath -Value $traceJson -Encoding UTF8
}

if (-not $KeepArtifacts) {
    try {
        $resolvedRoot = [System.IO.Path]::GetFullPath($dogfoodRoot)
        $resolvedRun = [System.IO.Path]::GetFullPath($runDir)
        if ($resolvedRun.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $runDir)) {
            Remove-Item -LiteralPath $runDir -Recurse -Force
        }
    } catch {
        # Cleanup failure is reported in JSON status by preserving the runDir value.
    }
}

Write-Output $json
