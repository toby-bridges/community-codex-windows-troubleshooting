[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo
)

$ErrorActionPreference = "Stop"

$description = "Community field guide and read-only diagnostics for troubleshooting Codex on Windows."
$topics = @(
    "codex",
    "windows",
    "troubleshooting",
    "openai-codex",
    "powershell",
    "wsl",
    "sandbox",
    "computer-use",
    "browser-use",
    "worktree"
)

Write-Output "Configuring GitHub repository metadata for $Repo"

gh repo edit $Repo `
    --description $description `
    --enable-issues `
    --enable-discussions

gh repo edit $Repo --add-topic ($topics -join ",")

Write-Output "Done."
Write-Output "Next manual steps:"
Write-Output "1. Create release v0.1.0 using RELEASE_NOTES.md."
Write-Output "2. Create and pin an issue using .github/PINNED-ISSUE.md."
Write-Output "3. Confirm Discussions categories: Q&A, Case reports, Source updates."
