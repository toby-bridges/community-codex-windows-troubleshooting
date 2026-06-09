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
