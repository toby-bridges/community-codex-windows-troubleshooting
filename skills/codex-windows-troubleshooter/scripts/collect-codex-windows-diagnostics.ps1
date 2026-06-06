[CmdletBinding()]
param(
    [string]$Workspace = (Get-Location).Path,
    [string]$OutputPath
)

$ErrorActionPreference = "Continue"

function Invoke-Capture {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$Arguments = @()
    )

    try {
        $output = & $File @Arguments 2>&1
        return [ordered]@{
            ok = ($LASTEXITCODE -eq 0)
            exitCode = $LASTEXITCODE
            output = ($output | ForEach-Object { $_.ToString() }) -join "`n"
        }
    } catch {
        return [ordered]@{
            ok = $false
            exitCode = $null
            output = $_.Exception.Message
        }
    }
}

function Get-FileSummary {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return $null
    }
    return [ordered]@{
        path = $item.FullName
        length = $item.Length
        lastWriteTime = $item.LastWriteTime.ToString("o")
    }
}

function Get-DirectorySummary {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return [ordered]@{
            path = $item.FullName
            exists = $true
            lastWriteTime = $item.LastWriteTime.ToString("o")
        }
    } catch {
        return [ordered]@{
            path = $Path
            exists = $false
            error = $_.Exception.Message
        }
    }
}

function Get-CommandLocations {
    param([string[]]$Names)
    $locations = [ordered]@{}
    foreach ($name in $Names) {
        try {
            $locations[$name] = @(
                Get-Command $name -ErrorAction SilentlyContinue |
                    Select-Object Name, Source, Version
            )
        } catch {
            $locations[$name] = @([ordered]@{ error = $_.Exception.Message })
        }
    }
    return $locations
}

function Get-ServiceSummary {
    param([string[]]$Names)

    $services = @()
    foreach ($name in $Names) {
        try {
            $service = Get-Service -Name $name -ErrorAction Stop
            $services += [ordered]@{
                name = $service.Name
                displayName = $service.DisplayName
                status = $service.Status.ToString()
                startType = $service.StartType.ToString()
            }
        } catch {
            $services += [ordered]@{
                name = $name
                error = $_.Exception.Message
            }
        }
    }
    return $services
}

function Get-StorePolicySummary {
    $paths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore",
        "HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore"
    )
    $results = @()
    foreach ($path in $paths) {
        try {
            if (Test-Path -LiteralPath $path) {
                $item = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
                $results += [ordered]@{
                    path = $path
                    exists = $true
                    removeWindowsStore = $item.RemoveWindowsStore
                    disableStoreApps = $item.DisableStoreApps
                    autoDownload = $item.AutoDownload
                }
            } else {
                $results += [ordered]@{
                    path = $path
                    exists = $false
                }
            }
        } catch {
            $results += [ordered]@{
                path = $path
                exists = $true
                error = $_.Exception.Message
            }
        }
    }
    return $results
}

function Test-PathContainsEntry {
    param([string]$Target)

    if (-not $Target -or -not $env:PATH) {
        return $false
    }

    try {
        $targetFull = [System.IO.Path]::GetFullPath($Target).TrimEnd("\")
    } catch {
        $targetFull = $Target.TrimEnd("\")
    }

    foreach ($entry in ($env:PATH -split [System.IO.Path]::PathSeparator)) {
        if (-not $entry) {
            continue
        }
        $expanded = [System.Environment]::ExpandEnvironmentVariables($entry)
        try {
            $entryFull = [System.IO.Path]::GetFullPath($expanded).TrimEnd("\")
        } catch {
            $entryFull = $expanded.TrimEnd("\")
        }
        if ($entryFull.Equals($targetFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-HostsMicrosoftEntries {
    $hostsPath = Join-Path $env:WINDIR "System32\drivers\etc\hosts"
    $patterns = '(?i)(microsoft|windows|store|msft|live\.com|microsoftonline|login|aka\.ms)'
    if (-not (Test-Path -LiteralPath $hostsPath)) {
        return [ordered]@{
            path = $hostsPath
            exists = $false
            entries = @()
        }
    }

    try {
        $lineNumber = 0
        $entries = @(
            Get-Content -LiteralPath $hostsPath -ErrorAction Stop | ForEach-Object {
                $lineNumber++
                $trimmed = $_.Trim()
                if ($trimmed -and -not $trimmed.StartsWith("#") -and $trimmed -match $patterns) {
                    [ordered]@{
                        line = $lineNumber
                        text = $trimmed
                    }
                }
            }
        )
        return [ordered]@{
            path = $hostsPath
            exists = $true
            entryCount = $entries.Count
            entries = @($entries | Select-Object -First 20)
        }
    } catch {
        return [ordered]@{
            path = $hostsPath
            exists = $true
            error = $_.Exception.Message
            entries = @()
        }
    }
}

function Resolve-DnsSummary {
    param([string[]]$Names)

    $results = @()
    foreach ($name in $Names) {
        try {
            $records = Resolve-DnsName -Name $name -ErrorAction Stop |
                Where-Object { $_.IPAddress -or $_.NameHost } |
                Select-Object -First 8 Name, Type, IPAddress, NameHost
            $results += [ordered]@{
                name = $name
                ok = $true
                records = @($records)
            }
        } catch {
            $results += [ordered]@{
                name = $name
                ok = $false
                error = $_.Exception.Message
                records = @()
            }
        }
    }
    return $results
}

function Get-WorkspacePathRisk {
    param([string]$Path)

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $root = [System.IO.Path]::GetPathRoot($item.FullName)
        $profile = $env:USERPROFILE
        $oneDrive = $env:OneDrive
        $attributes = $item.Attributes.ToString()
        $isEncrypted = (($item.Attributes -band [System.IO.FileAttributes]::Encrypted) -ne 0)
        $isReparsePoint = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        $isOneDrive = $false
        if ($oneDrive) {
            $isOneDrive = $item.FullName.StartsWith($oneDrive, [System.StringComparison]::OrdinalIgnoreCase)
        }

        return [ordered]@{
            fullName = $item.FullName
            root = $root
            attributes = $attributes
            isNonCDrive = ($root -and -not $root.StartsWith("C:", [System.StringComparison]::OrdinalIgnoreCase))
            isUnderUserProfile = ($profile -and $item.FullName.StartsWith($profile, [System.StringComparison]::OrdinalIgnoreCase))
            isUnderOneDrive = $isOneDrive
            isEncrypted = $isEncrypted
            isReparsePoint = $isReparsePoint
            sandboxPathRiskHints = @(
                if ($root -and -not $root.StartsWith("C:", [System.StringComparison]::OrdinalIgnoreCase)) { "non-C-drive" }
                if ($isOneDrive) { "onedrive" }
                if ($isEncrypted) { "encrypted" }
                if ($isReparsePoint) { "reparse-point" }
            )
        }
    } catch {
        return [ordered]@{
            fullName = $Path
            error = $_.Exception.Message
        }
    }
}

function Redact-Line {
    param([string]$Line)
    return ($Line `
        -replace '(?i)(api[_-]?key\s*=\s*).+', '$1[REDACTED]' `
        -replace '(?i)(token\s*=\s*).+', '$1[REDACTED]' `
        -replace '(?i)(secret\s*=\s*).+', '$1[REDACTED]' `
        -replace '(?i)(password\s*=\s*).+', '$1[REDACTED]')
}

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$configPath = Join-Path $codexHome "config.toml"
$sessionsPath = Join-Path $codexHome "sessions"
$bundledMarketplacePath = Join-Path $codexHome ".tmp\bundled-marketplaces\openai-bundled\.agents\plugins\marketplace.json"
$pluginCachePath = Join-Path $codexHome "plugins\cache"

$result = [ordered]@{
    generatedAt = (Get-Date).ToString("o")
    workspace = $Workspace
    environment = [ordered]@{
        userName = $env:USERNAME
        computerName = $env:COMPUTERNAME
        processorArchitecture = $env:PROCESSOR_ARCHITECTURE
        codexHome = $codexHome
        wslDistroName = $env:WSL_DISTRO_NAME
        httpProxySet = [bool]$env:HTTP_PROXY
        httpsProxySet = [bool]$env:HTTPS_PROXY
    }
    os = $null
    codexAppx = $null
    commands = [ordered]@{}
    git = [ordered]@{}
    workspacePath = [ordered]@{}
    powershell = [ordered]@{}
    wsl = [ordered]@{}
    windowsPackages = [ordered]@{}
    windowsServices = [ordered]@{}
    network = [ordered]@{}
    codexFiles = [ordered]@{}
    processes = @()
}

try {
    $os = Get-ComputerInfo -ErrorAction Stop
    $result.os = [ordered]@{
        windowsProductName = $os.WindowsProductName
        windowsVersion = $os.WindowsVersion
        osBuildNumber = $os.OsBuildNumber
        osArchitecture = $os.OsArchitecture
    }
} catch {
    $result.os = [ordered]@{ error = $_.Exception.Message }
}

try {
    $appx = Get-AppxPackage OpenAI.Codex -ErrorAction Stop
    $result.codexAppx = $appx | Select-Object Name, Version, PackageFullName, InstallLocation
} catch {
    $result.codexAppx = [ordered]@{ error = $_.Exception.Message }
}

try {
    $result.windowsPackages.storeRuntime = @(
        Get-AppxPackage Microsoft.WindowsStore, Microsoft.DesktopAppInstaller, Microsoft.VCLibs*, Microsoft.WindowsAppRuntime* -ErrorAction SilentlyContinue |
            Select-Object Name, Version, PackageFullName, InstallLocation
    )
} catch {
    $result.windowsPackages.storeRuntime = @([ordered]@{ error = $_.Exception.Message })
}

$result.windowsServices.storeRelated = Get-ServiceSummary -Names @(
    "AppXSvc",
    "ClipSVC",
    "InstallService",
    "wuauserv",
    "BITS",
    "DoSvc"
)
$result.windowsPackages.storePolicy = Get-StorePolicySummary
$localWindowsApps = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps" } else { $null }
try {
    $result.windowsPackages.winget = [ordered]@{
        appInstaller = @(
            Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
                Select-Object Name, Version, PackageFullName, InstallLocation
        )
        localWindowsApps = $localWindowsApps
        localWindowsAppsOnPath = (Test-PathContainsEntry -Target $localWindowsApps)
        localWingetAlias = if ($localWindowsApps) { Get-FileSummary -Path (Join-Path $localWindowsApps "winget.exe") } else { $null }
    }
} catch {
    $result.windowsPackages.winget = [ordered]@{ error = $_.Exception.Message }
}

$result.network.hostsMicrosoftEntries = Get-HostsMicrosoftEntries
$result.network.microsoftDns = Resolve-DnsSummary -Names @(
    "www.microsoft.com",
    "login.microsoftonline.com",
    "storeedgefd.dsx.mp.microsoft.com"
)

$result.commands.codexVersion = Invoke-Capture -File "codex" -Arguments @("--version")
$result.commands.codexDoctor = Invoke-Capture -File "codex" -Arguments @("doctor", "--summary")
$result.commands.gitVersion = Invoke-Capture -File "git" -Arguments @("--version")
$result.commands.wingetVersion = Invoke-Capture -File "winget" -Arguments @("--version")
$result.commands.locations = Get-CommandLocations -Names @("codex", "git", "pwsh", "powershell", "winget", "wsl")

$result.workspacePath = Get-WorkspacePathRisk -Path $Workspace

$result.powershell.version = $PSVersionTable.PSVersion.ToString()
try {
    $result.powershell.executionPolicy = Get-ExecutionPolicy -List | Select-Object Scope, ExecutionPolicy
} catch {
    $result.powershell.executionPolicy = @([ordered]@{ error = $_.Exception.Message })
}

$result.wsl.status = Invoke-Capture -File "wsl.exe" -Arguments @("--status")
$result.wsl.list = Invoke-Capture -File "wsl.exe" -Arguments @("-l", "-v")
$result.commands.wingetCodex = Invoke-Capture -File "winget" -Arguments @("list", "--name", "Codex")

$result.git.status = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "status", "--short", "--branch")
$result.git.currentBranch = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "symbolic-ref", "--short", "HEAD")
$result.git.branchAll = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "branch", "-a")
$result.git.remoteVerbose = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "remote", "-v")
$result.git.remoteShowOrigin = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "remote", "show", "origin")
$result.git.originHead = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "symbolic-ref", "refs/remotes/origin/HEAD")
$result.git.showRefHead = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "show-ref", "--head")
$result.git.lastCommit = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "log", "--oneline", "-1")
$result.git.verifyMaster = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "rev-parse", "--verify", "master")
$result.git.verifyMain = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "rev-parse", "--verify", "main")
$result.git.verifyOriginMaster = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "rev-parse", "--verify", "origin/master")
$result.git.verifyOriginMain = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "rev-parse", "--verify", "origin/main")
$result.git.worktrees = Invoke-Capture -File "git" -Arguments @("-C", $Workspace, "worktree", "list", "--porcelain")

$result.codexFiles.config = Get-FileSummary -Path $configPath
if (Test-Path -LiteralPath $configPath) {
    try {
        $lines = Get-Content -LiteralPath $configPath -TotalCount 120 -ErrorAction Stop
        $result.codexFiles.configPreview = @($lines | ForEach-Object { Redact-Line $_ })
        $bytes = [System.IO.File]::ReadAllBytes($configPath)
        $suspiciousLines = @()
        $lineNumber = 0
        foreach ($line in $lines) {
            $lineNumber++
            $trimmed = $line.Trim()
            if ($trimmed -and
                -not $trimmed.StartsWith("#") -and
                -not $trimmed.StartsWith("[") -and
                -not $trimmed.Contains("=")) {
                $suspiciousLines += [ordered]@{
                    line = $lineNumber
                    text = Redact-Line $trimmed
                }
            }
        }
        $result.codexFiles.configHealth = [ordered]@{
            nulByteDetected = ($bytes -contains 0)
            suspiciousLineCount = $suspiciousLines.Count
            suspiciousLines = @($suspiciousLines | Select-Object -First 10)
        }
    } catch {
        $result.codexFiles.configPreview = @("Could not read config: $($_.Exception.Message)")
        $result.codexFiles.configHealth = [ordered]@{ error = $_.Exception.Message }
    }
}
$result.codexFiles.bundledMarketplaceExists = Test-Path -LiteralPath $bundledMarketplacePath
$result.codexFiles.bundledMarketplace = Get-FileSummary -Path $bundledMarketplacePath
$result.codexFiles.pluginCacheExists = Test-Path -LiteralPath $pluginCachePath
$result.codexFiles.pluginCache = Get-DirectorySummary -Path $pluginCachePath
$result.codexFiles.tmpBundledMarketplaces = Get-DirectorySummary -Path (Join-Path $codexHome ".tmp\bundled-marketplaces")

if (Test-Path -LiteralPath $sessionsPath) {
    try {
        $result.codexFiles.largestSessions = @(
            Get-ChildItem -LiteralPath $sessionsPath -Recurse -Filter "*.jsonl" -ErrorAction SilentlyContinue |
                Sort-Object Length -Descending |
                Select-Object -First 10 FullName, Length, LastWriteTime
        )
    } catch {
        $result.codexFiles.largestSessions = @([ordered]@{ error = $_.Exception.Message })
    }
}

try {
    $result.codexFiles.pluginCacheTop = @(
        Get-ChildItem -LiteralPath $pluginCachePath -ErrorAction SilentlyContinue |
            Select-Object -First 20 FullName, LastWriteTime
    )
} catch {
    $result.codexFiles.pluginCacheTop = @([ordered]@{ error = $_.Exception.Message })
}

try {
    $crashRoots = @(
        Join-Path $env:LOCALAPPDATA "CrashDumps"
        Join-Path $env:LOCALAPPDATA "Packages"
    )
    $result.codexFiles.crashCandidates = @(
        foreach ($root in $crashRoots) {
            if (Test-Path -LiteralPath $root) {
                Get-ChildItem -LiteralPath $root -Recurse -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.Name -match '(?i)(codex|crashpad|\.dmp$)' -or
                        $_.FullName -match '(?i)(codex|crashpad)'
                    } |
                    Select-Object -First 40 FullName, Length, LastWriteTime
            }
        }
    )
} catch {
    $result.codexFiles.crashCandidates = @([ordered]@{ error = $_.Exception.Message })
}

try {
    $result.processes = @(
        Get-Process Codex, codex, node_repl, extension-host, codex-computer-use -ErrorAction SilentlyContinue |
            Select-Object ProcessName, Id, Path
    )
} catch {
    $result.processes = @([ordered]@{ error = $_.Exception.Message })
}

$json = $result | ConvertTo-Json -Depth 8

if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
    Write-Output "Wrote diagnostics to $OutputPath"
} else {
    Write-Output $json
}
