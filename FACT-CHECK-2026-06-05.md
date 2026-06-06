# 事实核查记录：2026-06-05

目标：把 Windows Codex 报错指南里的高风险结论拆成可复查的 claim，并标明证据来源、交叉验证状态和剩余不确定性。

## 证据等级

- A：官方文档或官方博客直接支持。
- B：GitHub `openai/codex` issue 中有可复现日志，且与官方文档/系统文档能互相解释。
- C：社区帖子、博客、Reddit、V2EX 等提供案例，但缺少维护者确认或可复现环境。
- D：根据错误文本和系统行为做的工程推断，需要更多复现。

## 本次重点：Worktree `fatal: invalid reference: master`

用户截图原文：

```text
[info] Starting worktree creation
fatal: invalid reference: master
[stderr] git worktree add failed: fatal: invalid reference: master
```

核查结论：B。

最可能根因：Codex 创建 worktree 时使用了 `master` 作为起点，但当前仓库没有本地可解析的 `master` ref；或者 UI/状态里保存了 stale branch。这个错误发生在 Git ref 解析阶段，不能先归因到 Windows sandbox。

本机 dogfood 精确复现补充：

- 出错项目：`<AFFECTED_REPO>`
- `git status --short --branch` 输出：`## No commits yet on master`
- `git rev-parse --verify master` 输出：`fatal: Needed a single revision`
- `git worktree list --porcelain` 显示 `HEAD 0000000000000000000000000000000000000000`
- 因此本案例的精确根因是空 Git 仓库的 unborn `master` branch：`master` 名字存在于 HEAD symbolic ref，但还没有任何 commit，不能作为 `git worktree add --detach` 的 starting commit。

交叉证据：

- 官方 Codex worktree 文档说明：worktree 需要 Git repo，用户选择 starting branch，Codex 从所选分支的 `HEAD` commit 创建 detached HEAD worktree，并放在 `$CODEX_HOME/worktrees`。来源：[OpenAI Worktrees](https://developers.openai.com/codex/app/worktrees)。
- Git 官方文档说明：`git worktree add <path> [<commit-ish>]` 会 checkout 指定 `<commit-ish>`；`--detach` 会在新 worktree 中 detached HEAD。来源：[Git worktree](https://git-scm.com/docs/git-worktree)。
- GitHub issue [#12346](https://github.com/openai/codex/issues/12346) 报告相同类别的 `fatal: invalid reference: main`，并指出没有本地 `main` 时也会发生。截至 2026-06-05 为 OPEN。
- GitHub issue [#22635](https://github.com/openai/codex/issues/22635) 报告 Codex UI 选到 remote-only branch 后把短分支名传给 `git worktree add --detach`，导致 `fatal: invalid reference: feature/...`。截至 2026-06-05 为 OPEN。

排查命令：

```powershell
git status --short --branch
git branch --list master
git branch --list main
git branch -r
git remote show origin
git rev-parse --verify master
git rev-parse --verify origin/master
git rev-parse --verify origin/HEAD
```

解决建议：

- 如果 `origin/master` 存在但本地 `master` 不存在，创建本地 tracking branch：`git branch --track master origin/master`，或切过去：`git switch --track origin/master`。
- 如果仓库实际默认分支是 `main`、`production`、`staging` 等，Codex worktree 起点应选择实际存在的本地分支，不要为了绕过报错创建假 `master`。
- 如果 Codex UI 仍强制使用 `master/main` 或 remote-only 短名，把 branch 列表、`origin/HEAD`、截图和日志补到 #12346/#22635 或新 issue。

## 其他核心 claim

| Claim | 等级 | 证据与备注 |
| --- | --- | --- |
| Windows app 原生模式使用 PowerShell + Windows sandbox，也可切到 WSL2 | A | [Codex app for Windows](https://developers.openai.com/codex/app/windows)、[Windows platform](https://developers.openai.com/codex/windows)。 |
| Windows elevated sandbox 会用 sandbox 用户、ACL、防火墙和 helper 组件建立边界 | A | [OpenAI Windows sandbox 技术文章](https://openai.com/index/building-codex-windows-sandbox/)。 |
| `spawn setup refresh` / `os error 740` 很可能和 Windows UAC installer detection 误判 `setup.exe` helper 有关 | B | GitHub [#24050](https://github.com/openai/codex/issues/24050)、[#26477](https://github.com/openai/codex/issues/26477)、[#26158](https://github.com/openai/codex/issues/26158)，并可用 Windows UAC 行为解释。官方耐久修复状态需持续跟踪。 |
| Windows 10 Computer Use `SetIsBorderRequired` 失败与旧系统 API 支持有关 | B | GitHub [#25178](https://github.com/openai/codex/issues/25178)、[#25411](https://github.com/openai/codex/issues/25411)。需要用 Microsoft API 文档持续核实最低系统版本。 |
| bundled marketplace 半更新会导致 Browser/Computer Use 插件不可用 | B | GitHub [#26536](https://github.com/openai/codex/issues/26536)、[#26501](https://github.com/openai/codex/issues/26501)、[#25220](https://github.com/openai/codex/issues/25220)。 |
| WSL/Windows `CODEX_HOME` split-brain 会造成配置、worktree、插件路径混乱 | B | GitHub [#22759](https://github.com/openai/codex/issues/22759)、[#13762](https://github.com/openai/codex/issues/13762)、[#25216](https://github.com/openai/codex/issues/25216)。 |
| 长 session / rollout JSONL 过大会导致桌面 app 卡死或崩溃 | B | GitHub [#22004](https://github.com/openai/codex/issues/22004)、[#25430](https://github.com/openai/codex/issues/25430)、[#26104](https://github.com/openai/codex/issues/26104)。 |
| 小红书适合收集普通用户截图，但不应作为第一阶段事实源 | C | 当前公开 Web/API 可检索性弱，且第三方 API/爬虫有 ToS、隐私和账号风控问题。适合做线索源，不适合单独定性。 |

## 待继续核查

- 每个 GitHub issue 的 `fixed-in` 版本、是否有 PR 合并、是否已经进入 Microsoft Store 版本。
- `SetIsBorderRequired` 的精确 Windows SDK/OS 支持矩阵。
- 中文社区案例与 GitHub issue 的一对一映射，尤其是 V2EX、博客园、CSDN、知乎、小红书。
- Microsoft Store review、Windows Event Viewer、Crashpad dump 的可自动化采集边界。
