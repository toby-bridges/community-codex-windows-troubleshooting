# GitHub Launch Checklist

Use this checklist before announcing the repository publicly.

## Repository Settings

Recommended repository name:

```text
community-codex-windows-troubleshooting
```

Description:

```text
Community field guide and read-only diagnostics for troubleshooting Codex on Windows.
```

Website:

```text
https://github.com/<OWNER>/community-codex-windows-troubleshooting
```

Topics:

```text
codex
windows
troubleshooting
openai-codex
powershell
wsl
sandbox
computer-use
browser-use
worktree
```

Features to enable:

- Issues
- Discussions
- Wiki disabled unless needed later
- Projects optional

Discussions categories:

- `Q&A`
- `Case reports`
- `Source updates`

## First Release

Create release:

```text
v0.1.0 - First dogfooded Windows troubleshooting matrix
```

Use [RELEASE_NOTES.md](./RELEASE_NOTES.md) as the release body.

## Pinned Issue

Create an issue with the content from:

```text
.github/PINNED-ISSUE.md
```

Suggested title:

```text
Submit a redacted Codex Windows error case
```

Pin the issue after creation.

## Verification Before Launch

Run:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" ".\skills\codex-windows-troubleshooter"
```

Run script parse checks:

```powershell
[scriptblock]::Create((Get-Content -Raw ".\skills\codex-windows-troubleshooter\scripts\collect-codex-windows-diagnostics.ps1")) | Out-Null
[scriptblock]::Create((Get-Content -Raw ".\skills\codex-windows-troubleshooter\scripts\run-codex-windows-dogfood.ps1")) | Out-Null
```

Run a final private-info scan:

```powershell
rg -n -e 'C:\\Users\\<YOUR_USER>' -e '<PRIVATE_REPO>' -e '<TOKEN>' .
```

## Optional CLI Setup

After adding a GitHub remote, run:

```powershell
.\scripts\configure-github-repo.ps1 -Repo "<OWNER>/community-codex-windows-troubleshooting"
```

The script configures description and topics with GitHub CLI. It does not create a public repository by itself.
