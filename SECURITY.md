# Security Policy

This repository is a troubleshooting guide and diagnostic toolkit. It should never collect or publish secrets.

## Reporting Sensitive Issues

If your report includes secrets, private repositories, crash dumps, or personal information, do not open a public issue with raw artifacts. Redact first or summarize the relevant error text.

## Diagnostic Scripts

Scripts in this repository are intended to be read-only unless explicitly marked as a fixture generator. Fixture generators must write only under:

```text
%TEMP%\codex-windows-dogfood\
```

Before posting diagnostic output publicly, check for:

- API keys or tokens
- private repo names
- home directory paths
- email addresses
- private proxy URLs
- crash dumps or session contents

## Unsafe Workarounds

Avoid recommending broad deletion, global allowlists, disabling antivirus, changing Microsoft Store package files, or using `danger-full-access` unless the guide explicitly labels the risk.
