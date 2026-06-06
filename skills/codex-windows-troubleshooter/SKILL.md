---
name: codex-windows-troubleshooter
description: "Unofficial community workflow to diagnose, fact-check, and maintain Codex Windows bug and issue research. Use when the user reports Codex Windows Desktop, CLI, IDE, worktree, Windows sandbox, WSL, Browser, Chrome, Computer Use, PowerShell, plugin, marketplace, Microsoft Store, session, or Git errors from screenshots, logs, or local state, or asks to produce a Codex Windows error guide with verified sources and workaround status."
---

# Community Codex Windows Troubleshooter

## Workflow

1. Classify the failure surface first: Windows app, CLI, IDE extension, native Windows, WSL, worktree, Browser, Chrome, Computer Use, sandbox, plugin/marketplace, PowerShell, network, or session/history.
2. Preserve exact evidence: error text, screenshot text, Codex app/CLI version, Windows build, install channel, agent environment, sandbox config, current Git branch, and whether the repo is native Windows or WSL-backed. Redact tokens, API keys, email addresses, and private repo names when sharing outside the machine.
3. Check official facts before community claims. Use `references/official-baseline.md` for stable Codex/Git boundaries, then browse official docs again if the user asks for current/latest status.
4. Match the error against `references/error-matrix.md`. If the symptom involves worktrees or `fatal: invalid reference`, read `references/worktree.md`.
5. Cross-check GitHub issues in `references/github-issue-map.md`, then use live GitHub search for state, duplicates, fixed versions, or new comments. Treat GitHub issues as stronger than Reddit/X/V2EX, but weaker than official docs or merged release notes.
6. When local diagnostics are useful, run `scripts/collect-codex-windows-diagnostics.ps1` from the affected workspace. It is read-only and emits redacted environment metadata.
7. When validating the guide itself, run `scripts/run-codex-windows-dogfood.ps1`. It writes only under `%TEMP%\codex-windows-dogfood\...` and cleans its fixture directory by default.
8. Deliver a diagnosis with evidence level, likely root cause, exact verification commands, safe workaround, risky workaround if any, and an unresolved placeholder when no solution is confirmed.

## Evidence Rules

- Mark claims as `A` when backed by official OpenAI/Git/Microsoft docs.
- Mark claims as `B` when backed by reproducible `openai/codex` GitHub issues plus system behavior.
- Mark claims as `C` when only community posts, blogs, Reddit, V2EX, X, or Xiaohongshu support the claim.
- Mark claims as `D` when they are engineering inference from logs and need more reproduction.
- Do not present a workaround as solved unless it has a confirmed version boundary or repeatable local verification.

## Reference Map

- `references/official-baseline.md`: official Codex and Git facts used as guardrails.
- `references/error-matrix.md`: known error strings, likely causes, and workaround status.
- `references/github-issue-map.md`: representative upstream issue links and search queries.
- `references/worktree.md`: detailed diagnosis for Codex worktree creation failures.

## Local Diagnostics

Run the diagnostics script from the skill root, and pass the affected repository with `-Workspace`. Do not assume the affected project contains this skill.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-root>\scripts\collect-codex-windows-diagnostics.ps1" -Workspace "<affected-repo>"
```

Or write the result to a file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-root>\scripts\collect-codex-windows-diagnostics.ps1" -Workspace "<affected-repo>" -OutputPath ".\codex-windows-diagnostics.json"
```

Review output before posting it publicly.

## Guide Dogfood

Run the full safe dogfood pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-root>\scripts\run-codex-windows-dogfood.ps1" -Workspace "<affected-repo>"
```

The runner covers C001-C020 from the research guide. It uses live GitHub issue checks, local read-only diagnostics, and `%TEMP%` fixtures for reversible reproductions. Use `-KeepArtifacts` only when the user explicitly wants to inspect temporary fixtures.
