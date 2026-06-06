# Dogfood 运行日志

## 2026-06-05 / Case 001 / Worktree `invalid reference: master`

输入：

- 用户截图：`<SCREENSHOT_PATH>`
- 错误文本：

```text
[info] Starting worktree creation
fatal: invalid reference: master
[stderr] git worktree add failed: fatal: invalid reference: master
```

使用的 skill：

- `skills/codex-windows-troubleshooter/SKILL.md`
- `skills/codex-windows-troubleshooter/references/worktree.md`

运行结果：

- Skill 成功把问题分类为 `worktree` / Git ref 解析失败。
- 证据等级：B。
- 主要判断：Codex 创建 worktree 时传入 `master`，但出错仓库中没有本地可解析的 `master` ref；或 Codex UI/状态保存了 stale `master`。
- 交叉证据：OpenAI Worktrees 官方文档、Git worktree 官方文档、GitHub issue #12346、#22635。

本地验证状态：

- 用户提供出错项目路径：`<AFFECTED_REPO>`。
- 已完成本地验证。

关键输出：

```text
git status --short --branch
## No commits yet on master
?? .tmp-anthropic-knowledge-work-plugins/

git symbolic-ref --short HEAD
master

git rev-parse --verify master
fatal: Needed a single revision

git worktree list --porcelain
worktree <AFFECTED_REPO>
HEAD 0000000000000000000000000000000000000000
branch refs/heads/master
```

修正后的根因：

- 不是 remote-only branch。
- 不是默认分支叫 `main`/`master` 的选择问题。
- 精确根因是：这是一个还没有首个 commit 的 Git 仓库。`master` 是 unborn branch，不能作为 `git worktree add --detach` 的 starting commit。

已执行的核查命令：

```powershell
git status --short --branch
git branch --list master
git branch --list main
git branch -a
git remote -v
git remote show origin
git rev-parse --verify master
git rev-parse --verify origin/master
git symbolic-ref refs/remotes/origin/HEAD
git worktree list --porcelain
```

首轮 dogfood 发现：

- 原 `SKILL.md` 的诊断脚本示例假设 affected project 下存在 `.\skills\...`，这不符合真实排障。已改为从 skill root 调用脚本，并用 `-Workspace "<affected-repo>"` 指向出错仓库。
- `worktree.md` 和诊断脚本缺少对 unborn branch 的显式判断。已补充 `symbolic-ref --short HEAD`、`show-ref --head`、`log --oneline -1` 和空仓库修复建议。

建议修复路径：

- 最小修复：在 `<AFFECTED_REPO>` 里创建首个 commit。

```powershell
git commit --allow-empty -m "Initial commit"
```

- 如果要提交真实项目文件，先审查 `git status`，不要把 `.tmp-anthropic-knowledge-work-plugins/` 这类临时目录误提交。
- 创建首个 commit 后，再重试 Codex worktree 创建。

## 2026-06-05 / Full Pass 001 / C001-C016

输入：

- 计划：Codex Windows 指南全量 dogfood。
- 策略：只读优先 + 本机真实状态 + `%TEMP%` 安全 fixture。
- workspace：`<AFFECTED_REPO>`
- runner：`skills/codex-windows-troubleshooter/scripts/run-codex-windows-dogfood.ps1`

运行结果：

```text
runId: 20260605-212339
cases: 16
cleanup: cleaned
temp run dir: %TEMP%\codex-windows-dogfood\20260605-212339
```

覆盖结论：

- 16/16 case 达到目标等级。
- C001、C011、C015 达到 L2，均只写入 `%TEMP%` 临时 fixture，运行结束已清理。
- C002、C004、C005、C006、C007、C008、C009、C012、C014 达到 L1，只做本机只读检查。
- C003、C010、C013、C016 达到 L0，只做证据核查或优先级复核。

关键本机发现：

- C002：bundled marketplace 存在，plugin cache 存在。
- C003：本机不是 Windows 10 专用复现环境，不适合复现 Windows 10 `SetIsBorderRequired`。
- C004：本机安装中找到 1 个 `codex-windows-sandbox-setup.exe` helper。
- C006：检测到用户级代理变量状态；本轮未修改代理或 sandbox network。
- C007：`wsl --status` 和 `wsl -l -v` 可运行，`WSL_DISTRO_NAME` 为空。
- C009：已扫描 session JSONL 大小并记录为本地私有结果；未移动历史。
- C012：已只读扫描 crash/codex/crashpad candidates；未 repair/reset app。
- C014：已只读采集 Codex Appx version 和 CPU arch；公开日志不保留机器指纹。

C001 fixture 关键输出：

```text
empty unborn repo:
git status --short --branch
## No commits yet on master
git worktree add --detach <tmp> master
fatal: invalid reference: master

repo without main:
git branch -a
* production
git worktree add --detach <tmp> main
fatal: invalid reference: main

remote-only short name:
git rev-parse --verify feature/dogfood
fatal: Needed a single revision
git rev-parse --verify origin/feature/dogfood
<commit sha>
git worktree add --detach <tmp> feature/dogfood
fatal: invalid reference: feature/dogfood
```

C011/C015 fixture 结果：

- C011：坏 config fixture 检测到 NUL bytes 和缺少 `=` 的 TOML 行；真实 `%USERPROFILE%\.codex\config.toml` 未修改。
- C015：生成脱敏 issue draft fixture，`redacted=True`，大小 `627` bytes；fixture 已清理。

本轮 dogfood 改进：

- 新增 `DOGFOOD-MATRIX.md`，固定追踪 C001-C016 的目标等级、实际等级、证据、命令、结论和补充状态。
- 新增 `run-codex-windows-dogfood.ps1`，负责只读采集和 `%TEMP%` fixture 复现。
- 增强 `collect-codex-windows-diagnostics.ps1`：新增 PowerShell/WSL/winget/Crashpad/plugin cache 信息，以及 `configHealth`。
- 修复 runner 的 PowerShell Markdown 反引号转义问题。
- 修复 runner 的 `Run-Git` 参数名与 PowerShell `$Args` 自动变量冲突。
- 为 `gh issue view` 增加一次重试；#26194 首次瞬时失败，单独重查后确认为 OPEN。

反向更新状态：

- 指南：当前无需调整优先级；C001/C011 相关结论已覆盖。
- skill：新增 runner 脚本后需要在 `SKILL.md` 中补充 dogfood 入口。
- diagnostics：C011 提出的 config corruption 检测已补为 `configHealth`。
