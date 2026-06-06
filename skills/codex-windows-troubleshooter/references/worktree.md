# Worktree Creation Failures

Use this reference when Codex shows `Worktree setup failed`, `Starting worktree creation`, or `fatal: invalid reference`.

## Symptom

```text
[info] Starting worktree creation
fatal: invalid reference: master
[stderr] git worktree add failed: fatal: invalid reference: master
```

Equivalent forms include `main`, `feature/<name>`, or any branch selected in the Codex worktree UI.

## Diagnosis

This is a Git ref resolution failure before project setup scripts run. The selected starting point is not resolvable by Git in the current repository.

Common cases:

- Local `master` does not exist, but Codex UI or saved repo state selected `master`.
- The real default branch is `main`, `production`, `staging`, `develop`, or another branch.
- The branch exists only as `origin/<name>` and not as local `<name>`.
- Codex showed a remote-only branch in the picker but passed only the short branch name to `git worktree add --detach`.
- The repository was created locally but has no commits or no valid branch yet.
- The repository is on an unborn branch: `git status` says `No commits yet on master`, but `master` is not a valid commit-ish yet.

## Commands

Run from the affected repository:

```powershell
git status --short --branch
git symbolic-ref --short HEAD
git branch --list master
git branch --list main
git branch -a
git remote -v
git remote show origin
git rev-parse --verify master
git rev-parse --verify main
git rev-parse --verify origin/master
git rev-parse --verify origin/main
git symbolic-ref refs/remotes/origin/HEAD
git show-ref --head
git worktree list --porcelain
```

Interpretation:

- `git rev-parse --verify master` succeeds: local `master` is valid; look for a different Codex state/UI mismatch.
- `master` fails but `origin/master` succeeds: create a local tracking branch or select `origin/master` only if Codex can pass the full remote ref.
- `master` and `origin/master` fail: do not create `master` blindly; use the actual branch.
- `origin/HEAD` points elsewhere: use that branch as the base.
- `No commits yet on master` plus `worktree list` showing `HEAD 0000000000000000000000000000000000000000`: create the first commit before using Codex worktrees.

## Workarounds

Refresh refs:

```powershell
git fetch origin --prune
```

Create local tracking branch when remote exists:

```powershell
git branch --track master origin/master
```

or:

```powershell
git switch --track origin/master
```

For `main`:

```powershell
git branch --track main origin/main
```

For custom default branches:

```powershell
git switch production
```

If the branch is remote-only:

```powershell
git switch --track origin/feature/name
```

Then re-open the Codex worktree flow and select the local branch.

For an empty repository with no commits:

```powershell
git commit --allow-empty -m "Initial commit"
```

If project files should be tracked, review `git status`, add only intended files, and commit them instead. Do not add temporary folders, caches, secrets, or generated plugin scratch directories just to unblock worktree creation.

## Stale Worktree Cleanup

If Git failed before creating the worktree, no cleanup is usually needed. If the UI left stale registrations:

```powershell
git worktree list --porcelain
git worktree prune --dry-run
```

Run `git worktree prune` only after verifying the listed entries are stale.

## Upstream Tracking

- https://github.com/openai/codex/issues/12346 - `fatal: invalid reference: main` when repo lacks local/main branch.
- https://github.com/openai/codex/issues/22635 - remote-only branches shown by UI but short names fail with detached worktree creation.

When filing an issue, include:

- Exact worktree log block.
- `git branch -a`.
- `git remote show origin`.
- `git symbolic-ref refs/remotes/origin/HEAD`.
- Whether the selected branch exists locally or only as `origin/<branch>`.
