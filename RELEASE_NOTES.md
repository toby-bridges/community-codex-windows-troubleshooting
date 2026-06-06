# v0.1.0 - First Dogfooded Windows Troubleshooting Matrix

Initial public release of the Community Codex Windows Troubleshooting Field Guide.

## Highlights

- Covers major Codex-on-Windows failure families:
  - worktree `fatal: invalid reference`
  - Browser and Computer Use plugin availability
  - Windows sandbox startup and `os error 740`
  - WSL / Windows path and `CODEX_HOME` split-brain
  - PowerShell, session, config, Store, and antivirus edge cases
- Adds a dogfood matrix covering C001-C016.
- Adds read-only local diagnostics for Windows Codex troubleshooting.
- Adds safe `%TEMP%` fixtures for reversible reproduction of selected cases.
- Adds issue templates, contribution rules, redaction rules, and security guidance.

## Dogfood Status

- 16/16 guide cases reached their target coverage level.
- L2 fixture reproduction exists for:
  - C001 worktree invalid reference
  - C011 `config.toml` corruption
  - C015 redacted issue draft generation
- L1 read-only diagnostics exist for local environment, plugin cache, WSL, PowerShell, sessions, Crashpad, and Store metadata.

## Safety

- Diagnostic scripts are read-only unless explicitly generating temporary fixtures.
- Fixture generation writes only under `%TEMP%\codex-windows-dogfood\...`.
- Public docs redact local paths, secrets, private repository names, and machine-specific fingerprints.

## Non-Affiliation

This is an unofficial community project. It is not affiliated with, endorsed by, sponsored by, or maintained by OpenAI.
