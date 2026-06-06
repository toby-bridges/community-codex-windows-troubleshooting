# Official Baseline

Use this file to anchor Codex Windows troubleshooting to stable official facts.

## Codex Windows App

- Official install path is Microsoft Store/winget. Source: https://developers.openai.com/codex/app/windows
- Native Windows environments use PowerShell and Windows sandbox. WSL environments use Linux/WSL behavior. Source: https://developers.openai.com/codex/windows
- `CODEX_HOME` differs between native Windows and WSL unless explicitly configured. Native Windows default is `%USERPROFILE%\.codex`; WSL CLI default is Linux `~/.codex`.
- WSL1 is not supported from Codex `0.115` onward; WSL2 is the supported WSL baseline.
- Windows LTSC/IoT LTSC may include Store service behavior without the normal Store browsing UI. Do not assume manual MSIX install and Store restoration are enough; verify MSIX framework dependencies and Microsoft/Store/login DNS. Sources: https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/microsoft-store-access and https://learn.microsoft.com/en-us/windows/msix/msix-troubleshooting-guide
- Third-party slim/debloated Windows images should be treated as environment-risk evidence, not a Codex root cause by themselves. Microsoft Store download troubleshooting checks the Store Appx package and dependencies, and Microsoft says completely uninstalling Microsoft Store is not supported. MSIX/Windows App SDK packages can depend on framework packages such as VCLibs and Windows App Runtime. Sources: https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/troubleshooting-microsoft-store-apps-download-failure, https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/framework-packages/framework-packages-overview, and https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/deploy-packaged-apps
- `winget` is provided by App Installer as the Windows Package Manager CLI. It is supported on Windows 10 1809/build 17763 or later, may require first-user Store registration, and can fail with "not recognized" when App Installer lacks WinGet, the app execution alias is disabled, `%LOCALAPPDATA%\Microsoft\WindowsApps` is missing from PATH, per-user registration is mismatched, or App Installer is broken. Sources: https://learn.microsoft.com/en-us/windows/package-manager/winget/ and https://github.com/microsoft/winget-cli/blob/master/doc/troubleshooting/README.md

## Windows Sandbox

- Windows sandbox supports `elevated` and `unelevated` implementations. Prefer official docs for current recommendations. Source: https://developers.openai.com/codex/windows
- OpenAI's Windows sandbox article describes a sandbox user, ACL setup, firewall rules, `codex-windows-sandbox-setup.exe`, and `codex-command-runner.exe`. Source: https://openai.com/index/building-codex-windows-sandbox/

## Browser, Chrome, and Computer Use

- In-app Browser does not share user Chrome cookies, extensions, or existing tabs. Use Chrome extension when logged-in browser state is required. Source: https://developers.openai.com/codex/app/browser
- Computer Use is available in Codex app on macOS and Windows, subject to regional availability. Windows Computer Use can operate only on the current foreground desktop and visible target windows. Source: https://developers.openai.com/codex/app/computer-use

## Worktrees

- Codex worktrees require Git repositories and use Git worktrees under the hood. Source: https://developers.openai.com/codex/app/worktrees
- Codex asks for a starting branch and creates managed worktrees under `$CODEX_HOME/worktrees`.
- Codex-managed worktrees start from the selected branch `HEAD` and normally use detached HEAD.
- Git `worktree add <path> [<commit-ish>]` requires the given commit-ish/ref to be resolvable. Source: https://git-scm.com/docs/git-worktree
- Git `worktree add --detach` creates a detached HEAD worktree; do not assume remote branch guessing will create a local tracking branch in this mode.

## Source Order

Use this priority when facts conflict:

1. Current official docs, release notes, and merged PRs.
2. Reproducible `openai/codex` GitHub issues with logs.
3. Local reproduction on the user's machine.
4. Community posts from Reddit, V2EX, X, blogs, Xiaohongshu, forums.
