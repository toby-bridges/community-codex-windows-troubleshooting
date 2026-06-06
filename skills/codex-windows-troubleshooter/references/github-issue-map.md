# GitHub Issue Map

Use `gh issue view <number> --repo openai/codex` or the GitHub web UI to refresh state before reporting latest status.

## Worktrees

- https://github.com/openai/codex/issues/12346 - no `main` or no local `main`, `fatal: invalid reference: main`.
- https://github.com/openai/codex/issues/22635 - remote-only branch shown in UI, short branch name passed to `git worktree add --detach`.
- https://github.com/openai/codex/issues/13618 - WSL-backed repo worktree git dir resolution.
- https://github.com/openai/codex/issues/13762 - WSL mode stores worktrees under Windows `CODEX_HOME`.
- https://github.com/openai/codex/issues/15314 - Windows handoff does not merge worktree changes back into `master`.
- https://github.com/openai/codex/issues/19315 - Windows elevated sandbox requires approval for Git worktree operations because `.git` is denied.

Search:

```text
repo:openai/codex is:issue "fatal: invalid reference" worktree
repo:openai/codex is:issue "Starting worktree creation"
repo:openai/codex is:issue label:worktrees windows
repo:openai/codex is:issue "remote-only branch" worktree
```

## Plugin, Browser, Chrome, Computer Use

- https://github.com/openai/codex/issues/26536 - Computer Use plugin unavailable.
- https://github.com/openai/codex/issues/26501 - bundled marketplace partial/corrupt.
- https://github.com/openai/codex/issues/25220 - EFS/Application Protected copy failures from WindowsApps.
- https://github.com/openai/codex/issues/26109 - Chrome/native host or plugin cache lock.
- https://github.com/openai/codex/issues/22114 - extension-host file lock.
- https://github.com/openai/codex/issues/25178 - Windows 10 `SetIsBorderRequired` Computer Use screenshot failure.
- https://github.com/openai/codex/issues/25411 - adjacent Computer Use screenshot/accessibility failure.

## Windows Sandbox

- https://github.com/openai/codex/issues/24050 - `setup.exe` UAC installer detection and `os error 740`.
- https://github.com/openai/codex/issues/26477 - node_repl/browser launch affected by `os error 740`.
- https://github.com/openai/codex/issues/26158 - CLI 0.136/0.137 Windows sandbox regression.
- https://github.com/openai/codex/issues/18620 - `CreateProcessWithLogonW failed`.
- https://github.com/openai/codex/issues/26438 - `SetTokenInformation(TokenDefaultDacl) failed: 1344`.
- https://github.com/openai/codex/issues/18675 - sandbox DNS/npm failures.
- https://github.com/openai/codex/issues/25207 - Windows sandbox network.

## WSL and Path Split-Brain

- https://github.com/openai/codex/issues/25216 - Windows Desktop + WSL umbrella/release gate.
- https://github.com/openai/codex/issues/22759 - Windows/WSL Codex home split-brain.
- https://github.com/openai/codex/issues/22376 - `WSL_DISTRO_NAME` freezes Windows-native app.
- https://github.com/openai/codex/issues/24884 - WSL access requires `danger-full-access` in some paths.
- https://github.com/openai/codex/issues/26096 - WSL workspace opened but agent routes as Windows_NT.

## Session, UI, Config, Install

- https://github.com/openai/codex/issues/22004 - `RangeError: Invalid string length` from huge rollout.
- https://github.com/openai/codex/issues/25430 - large session resume picker freeze.
- https://github.com/openai/codex/issues/26104 - old sessions fail after update.
- https://github.com/openai/codex/issues/25513 - maximized rendering transparency/freezes.
- https://github.com/openai/codex/issues/26421 - zero-filled `config.toml`.
- https://github.com/openai/codex/issues/19352 - Windows app blank.
- https://github.com/openai/codex/issues/25912 - Store app crashes on launch.
- https://github.com/openai/codex/issues/19629 - tool execution still initializes PowerShell.
- https://github.com/openai/codex/issues/16268 - non-ASCII username corrupt HOME.
- https://github.com/openai/codex/issues/17491 - Windows ARM64 emulation.

## Community-only Leads

- X community case, 2026-06-06: Windows 11 LTSC 2024 machine without Store UI; manual Codex MSIX install and later Store package restoration still left the desktop app unable to open; final root cause was a hijacked Microsoft-related hosts entry. Evidence level C until reproduced or mapped to an upstream issue.
- X community case, 2026-06-06: Microsoft Store stuck on checking updates; direct MSIX download/install succeeded, but install/workspace directory still mattered because Windows sandbox authorization could fail. Evidence level C until reproduced or mapped to an upstream issue.
