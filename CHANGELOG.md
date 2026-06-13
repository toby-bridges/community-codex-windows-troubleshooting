# Changelog

All notable project changes are tracked here. This project follows Semantic Versioning for public troubleshooting surfaces and uses a Keep a Changelog-style layout.

## [Unreleased]

### Added

- Version governance baseline with a single `VERSION` source file.
- Pull request expectations for version impact, changelog entries, and coupled code/documentation updates.

## [0.1.0] - 2026-06-05

### Added

- Initial public release of the Community Codex Windows Troubleshooting Field Guide.
- Coverage for major Codex-on-Windows failure families:
  - worktree `fatal: invalid reference`
  - Browser and Computer Use plugin availability
  - Windows sandbox startup and `os error 740`
  - WSL / Windows path and `CODEX_HOME` split-brain
  - PowerShell, session, config, Store, and antivirus edge cases
- LTSC/Store/MSIX/hosts, Store checking update plus sandbox path, slim Windows dependency, and WinGet recognition troubleshooting cases.
- Dogfood matrix covering C001-C020.
- Read-only local diagnostics for Windows Codex troubleshooting.
- Safe `%TEMP%` fixtures for reversible reproduction of selected cases.
- Issue templates, contribution rules, redaction rules, and security guidance.

### Dogfood

- 20/20 guide cases reached their target coverage level.
- L2 fixture reproduction exists for C001 worktree invalid reference, C011 `config.toml` corruption, and C015 redacted issue draft generation.
- L1 read-only diagnostics exist for local environment, plugin cache, WSL, PowerShell, sessions, Crashpad, and Store metadata.

### Safety

- Diagnostic scripts are read-only unless explicitly generating temporary fixtures.
- Fixture generation writes only under `%TEMP%\codex-windows-dogfood\...`.
- Public docs redact local paths, secrets, private repository names, and machine-specific fingerprints.
