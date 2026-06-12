# Contributing

Thanks for helping improve this community field guide.

## 60-Second Path

You do not need to write a pull request to contribute useful data.

Open the issue template when you have a new failure, source link, or workaround result:

https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml

The minimum useful report is:

```text
Error:
Surface:
Windows:
Codex version:
What happened:
What fixed it, if anything:
Related links:
```

Use a pull request when you are changing guide text, diagnostic scripts, the dogfood matrix, or skill references. Every new case should update the relevant guide section and, when possible, the dogfood matrix.

## Version Governance

The project keeps one current version source in `VERSION` and tracks user-visible changes in `CHANGELOG.md`.

Use the pull request template to declare the Version impact:

- `None`: editorial cleanup, typo fix, redaction, or internal-only maintenance.
- `Patch`: compatible bug fix, evidence correction, or documentation fix that does not add a new public workflow.
- `Minor`: new case, new diagnostic behavior, new script option, new output artifact, or new public workflow.
- `Major`: breaking change to a documented script parameter, JSON field, case ID, evidence meaning, or workflow. Before `1.0.0`, mark breaking changes clearly in `CHANGELOG.md` and normally bump the next minor version.

Coupled updates are expected:

- When code or scripts change, update the relevant docs, skill instructions, or usage examples.
- When docs describe a new workflow or behavior, update the related script, matrix, skill reference, or explicitly mark the code update as not needed.
- When a change is user-visible, add an entry under `CHANGELOG.md` `Unreleased`.
- Update `VERSION` only in release PRs unless the PR itself is the release preparation.

Before opening a pull request, run the change policy check against the target branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\check-change-policy.ps1" -BaseRef "origin/main"
```

For stacked pull requests, pass the branch that the PR targets as `-BaseRef`.

The same version and change policy checks run in GitHub Actions for pull requests. Fix policy failures in the same PR rather than merging follow-up documentation or changelog updates separately.

## Data Flywheel

The project turns contributions into reusable troubleshooting data:

```text
Raw report -> normalized error signature -> case ID -> guide update -> dogfood check -> skill/reference update
```

Maintainers can normalize raw reports into case IDs, matrix rows, guide sections, and skill references. Contributors only need to provide redacted facts.

## What To Submit

Good contributions usually include:

- exact error text
- Codex surface: Windows app, CLI, IDE, WSL, Browser, Chrome, or Computer Use
- Windows version family, not personally identifying machine details
- Codex app/CLI version if available
- whether the issue is reproducible
- related GitHub issue links
- safe workaround status

## Redaction Rules

Do not submit:

- API keys, tokens, cookies, or credentials
- full `.codex` session JSONL files
- private repository names or remote URLs
- raw screenshots containing personal data
- email addresses, usernames, home directory names, or organization names
- unredacted crash dumps

Use placeholders such as:

```text
<USERPROFILE>
<WORKSPACE>
<PRIVATE_REPO>
<TOKEN_REDACTED>
```

## Evidence Levels

- `A`: official docs or official engineering posts
- `B`: reproducible `openai/codex` GitHub issues plus system behavior
- `C`: community reports such as Reddit, V2EX, X, blogs, Xiaohongshu
- `D`: engineering inference that still needs reproduction

Do not mark a workaround as solved unless it has repeatable verification or a confirmed fixed version.

## Dogfood Requirements

New guide cases should include at least one of:

- `L0`: evidence check
- `L1`: local read-only diagnostic
- `L2`: safe fixture reproduction under `%TEMP%\codex-windows-dogfood\...`

Do not mutate real `.codex`, Microsoft Store app state, WSL global config, antivirus settings, or project Git history in a contribution.
