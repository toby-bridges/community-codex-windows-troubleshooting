# Submit a redacted Codex Windows error case

Use this pinned issue to contribute new Codex-on-Windows error cases to the community guide.

## What To Include

Please include:

- exact error text
- Codex surface: Windows app, CLI, IDE, WSL, Browser, Chrome, or Computer Use
- Windows version family, not hostnames or personal machine details
- Codex app/CLI version if available
- whether the issue is reproducible
- related upstream `openai/codex` issue links
- safe workaround status, if any

## Do Not Include

Do not post:

- API keys, tokens, cookies, or credentials
- full `.codex` session JSONL files
- private repository names or remotes
- raw screenshots containing personal data
- home directory paths or usernames
- unredacted crash dumps

Use placeholders:

```text
<USERPROFILE>
<WORKSPACE>
<PRIVATE_REPO>
<TOKEN_REDACTED>
```

## Optional Read-Only Diagnostics

From this repository:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\skills\codex-windows-troubleshooter\scripts\collect-codex-windows-diagnostics.ps1" -Workspace "<WORKSPACE>"
```

Review and redact the output before posting.

## Evidence Levels

- `A`: official docs or official engineering posts
- `B`: reproducible `openai/codex` GitHub issues plus system behavior
- `C`: community report only
- `D`: inference, needs reproduction

## Dogfood Levels

- `L0`: evidence check
- `L1`: local read-only diagnostic
- `L2`: safe fixture reproduction under `%TEMP%\codex-windows-dogfood\...`
