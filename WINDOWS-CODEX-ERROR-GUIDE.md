# Windows Codex 报错指南（研究版）

更新日期：2026-06-05  
范围：Codex Windows 桌面应用、Windows 原生 CLI/IDE 扩展，以及与 Windows sandbox、WSL、Browser、Computer Use 相关的交叉问题。

## 0. 事实基线

- 官方文档显示，Codex Windows app 通过 Microsoft Store/winget 安装，原生模式使用 PowerShell + Windows sandbox，也可以切换到 WSL2。参考：[Codex app for Windows](https://developers.openai.com/codex/app/windows)。
- Windows 原生 sandbox 有 `elevated` 和 `unelevated` 两种实现；官方建议优先 `elevated`，失败时再用 `unelevated` 排查。参考：[Windows platform](https://developers.openai.com/codex/windows)。
- WSL2 使用 Linux sandbox。Codex `0.115` 起 WSL1 不再支持。Windows app 的默认 Codex home 是 `%USERPROFILE%\.codex`，WSL CLI 默认是 Linux `~/.codex`，除非显式设置 `CODEX_HOME`。
- Computer Use 官方说法：Codex app 上 macOS 和 Windows 可用，但启动阶段不包括 EEA、英国、瑞士；Windows 上只能操作当前前台桌面，目标窗口需要可见。参考：[Computer Use](https://developers.openai.com/codex/app/computer-use)。
- In-app Browser 不带用户登录态、cookie、扩展和已有标签页；需要登录态时用 Chrome extension。参考：[In-app browser](https://developers.openai.com/codex/app/browser)。
- Codex app 的 worktree 功能基于 Git worktree：创建时要选择 starting branch，Codex 会从所选分支的 `HEAD` commit 创建 detached HEAD worktree，位置在 `$CODEX_HOME/worktrees`。参考：[Worktrees](https://developers.openai.com/codex/app/worktrees)。
- OpenAI 2026-05-13 的 Windows sandbox 技术文章说明：当前 elevated sandbox 会创建专用 sandbox 用户、写入 ACL、配置防火墙规则，并用 `codex-windows-sandbox-setup.exe`、`codex-command-runner.exe` 等组件拼出完整边界。参考：[Building a safe, effective sandbox to enable Codex on Windows](https://openai.com/index/building-codex-windows-sandbox/)。

GitHub 热度参考（2026-06-05 用 GitHub Search API 拉取）：

- `repo:openai/codex is:issue label:windows-os`：2419 个，open 1443 个。
- `label:windows-os label:sandbox`：275 个，open 196 个。
- `label:windows-os label:computer-use`：75 个，open 66 个。
- `repo:openai/codex is:issue Windows WSL`：873 个，open 409 个。

## 1. 快速定位流程

先收集这些信息：

```powershell
codex --version
codex doctor --summary
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, OsArchitecture
Get-AppxPackage OpenAI.Codex | Select-Object Name, Version, InstallLocation
Get-Content -LiteralPath "$env:USERPROFILE\.codex\config.toml" -TotalCount 120
```

如果是桌面应用启动、插件、Computer Use、Browser 问题，再看：

```powershell
Get-Process Codex,codex,node_repl,extension-host,codex-computer-use -ErrorAction SilentlyContinue |
  Select-Object ProcessName,Id,Path

Test-Path "$env:USERPROFILE\.codex\.tmp\bundled-marketplaces\openai-bundled\.agents\plugins\marketplace.json"
Get-ChildItem "$env:USERPROFILE\.codex\plugins\cache\openai-bundled" -ErrorAction SilentlyContinue
```

任何删除/重建前先备份：

```powershell
Copy-Item "$env:USERPROFILE\.codex" "$env:USERPROFILE\.codex.backup-$(Get-Date -Format yyyyMMdd-HHmmss)" -Recurse
```

## 2. Worktree 创建失败：`fatal: invalid reference: master/main`

常见报错：

```text
[info] Starting worktree creation
fatal: invalid reference: master
[stderr] git worktree add failed: fatal: invalid reference: master
```

也可能是：

- `fatal: invalid reference: main`
- `fatal: invalid reference: feature/<name>`
- UI 能选到某个 branch，但创建 worktree 时立刻失败。

事实核查结论：

- 这类错误首先是 Git ref 解析失败，不是 Windows sandbox 独有问题。Codex 在创建 worktree 时把 `master`、`main` 或短分支名传给 `git worktree add`，但当前仓库里没有对应的本地可解析 ref。
- 还有一个已在本机 dogfood 复现的子类型：仓库刚 `git init`，还没有任何 commit。此时 `git status` 会显示 `No commits yet on master`，但 `master` 仍是 unborn branch，不是可用于 worktree 的 commit-ish。
- 官方 Codex 文档说明 worktree 起点来自用户选择的 starting branch；Git 官方文档说明 `git worktree add <path> [<commit-ish>]` 需要能 checkout 指定的 `<commit-ish>`，`--detach` 会创建 detached HEAD。
- 上游已有两个直接相邻 issue：
  - [#12346](https://github.com/openai/codex/issues/12346)：仓库没有 `main` 或本地没有 `main`，Codex 报 `fatal: invalid reference: main`。截至 2026-06-05 仍为 OPEN。
  - [#22635](https://github.com/openai/codex/issues/22635)：Codex UI 列出 remote-only branch，但实际传给 Git 的是短分支名，导致 `fatal: invalid reference: feature/...`。截至 2026-06-05 仍为 OPEN。

快速诊断：

```powershell
git status --short --branch
git symbolic-ref --short HEAD
git branch --list master
git branch --list main
git branch -r
git remote show origin
git rev-parse --verify master
git rev-parse --verify origin/master
git rev-parse --verify origin/HEAD
git show-ref --head
git worktree list --porcelain
```

判断方式：

- `git rev-parse --verify master` 失败，但 `origin/master` 成功：`master` 只是 remote-tracking branch，没有本地 `master`。
- `master` 和 `origin/master` 都失败，但 `main` 或 `origin/main` 成功：不要让 Codex 从 `master` 起 worktree，改选实际存在的分支。
- `origin/HEAD` 指向 `origin/production`、`origin/staging` 等：该仓库默认分支不是 `main/master`，Codex 应该使用实际默认分支或提示用户选择。
- `git status` 显示 `No commits yet on master`，`git worktree list --porcelain` 显示 `HEAD 0000000000000000000000000000000000000000`：这是空仓库/unborn branch。先创建首个 commit，再用 Codex worktree。

可尝试解决：

1. 在 Codex 新建 Worktree 的 branch picker 里选择一个本地存在的分支，而不是 stale 的 `master`。
2. 先刷新 remote refs：

```powershell
git fetch origin --prune
```

3. 如果远端确实有 `origin/master`，但本地没有 `master`，创建本地 tracking branch：

```powershell
git switch --track origin/master
```

或者不切换当前工作区，只创建本地分支：

```powershell
git branch --track master origin/master
```

4. 如果远端默认分支是 `main`，使用 `main`：

```powershell
git switch --track origin/main
```

5. 如果仓库根本没有 `master/main`，不要为了绕过 Codex 盲目创建假分支。改选真实分支，例如 `production`、`staging`、`develop`；如果 UI 仍强行用 `master/main`，把 branch 列表、`origin/HEAD`、截图和日志补到 [#12346](https://github.com/openai/codex/issues/12346) 或新 issue。
6. 如果仓库还没有任何 commit，最小修复是创建一个初始 commit。若暂时不想提交任何文件，可以用空提交建立第一个 commit：

```powershell
git commit --allow-empty -m "Initial commit"
```

如果已有项目文件，先审查 `git status`，只 `git add` 你确定要纳入版本库的文件，再提交。不要把临时目录、缓存、私密配置直接加进首个 commit。

失败后清理检查：

```powershell
git worktree list --porcelain
git worktree prune --dry-run
```

只有确认显示的是 stale/prunable worktree 后，再运行：

```powershell
git worktree prune
```

未解决占位：

- Codex 需要在 UI 和创建逻辑之间保留完整 ref，例如 `origin/feature/x`，或在 remote-only branch 被选择时自动创建 tracking branch。
- Codex 需要对没有 `main/master` 的仓库使用 `origin/HEAD` 或提示用户选择 base branch。

## 3. Computer Use / Browser 插件不可用

常见报错：

- `Computer Use plugins unavailable`
- `Computer Use native pipe path is unavailable`
- `Windows Computer Use helper paths are unavailable`
- `No plugins found in marketplace openai-bundled`
- Browser / Chrome / Computer Use 在设置里消失或显示 disconnected

已确认/高可信根因：

- Windows Store 包内的 `openai-bundled` marketplace 是完整的，但用户目录下 `.codex\.tmp\bundled-marketplaces\openai-bundled` 可能变成半写入状态，缺少 `.agents\plugins\marketplace.json`。代表 issue：[#26536](https://github.com/openai/codex/issues/26536)、[#26501](https://github.com/openai/codex/issues/26501)。
- WindowsApps 中的插件文件可能带 EFS/Application Protected 属性，普通 copy 失败，导致 Browser、Chrome、Computer Use、LaTeX 等 bundled 插件不可用。代表 issue：[#25220](https://github.com/openai/codex/issues/25220)。
- Chrome native host 或 extension-host 文件锁会阻止 bundled-marketplaces 重建。代表 issue：[#26109](https://github.com/openai/codex/issues/26109)、[#22114](https://github.com/openai/codex/issues/22114)。

可尝试解决：

1. 完全退出 Codex，结束残留 `Codex.exe`、`codex.exe`、`node_repl.exe`、`extension-host.exe`、`codex-computer-use.exe`。
2. 通过 Microsoft Store 检查更新，或运行 `winget upgrade Codex -s msstore`。
3. 备份 `.codex` 后，删除或移走 `.codex\.tmp\bundled-marketplaces\openai-bundled*`，重新启动 Codex 让它重建。
4. 如果日志出现 `copyfile`、`The specified file could not be encrypted`、`EFS`、`plugin_cache_windows_file_lock`，不要继续盲删插件缓存；优先等待官方修复或在 GitHub issue 中附日志。

未解决占位：

- 对 EFS/Application Protected 文件的官方耐久修复待确认。
- 手动 byte-level 复制插件文件有社区方案，但属于非官方 workaround，不建议作为通用指南默认步骤。

## 4. Windows 10 Computer Use 截图失败

常见报错：

- `SetIsBorderRequired failed: No such interface supported (0x80004002)`
- `SetIsBorderRequired failed: 不支持此接口 (0x80004002)`
- `call get_window_state before issuing coordinate input`

高可信根因：

- Windows 10 22H2 build `19045` 不支持 `GraphicsCaptureSession.IsBorderRequired` / `SetIsBorderRequired` 所需 API，Computer Use helper 对这个可选 API 调用失败后中止截图。代表 issue：[#25178](https://github.com/openai/codex/issues/25178)、[#25411](https://github.com/openai/codex/issues/25411)。

可尝试解决：

- 临时改用 Windows 11 机器或 VM。
- 只用 Browser/Chrome 插件处理网页类任务，不用 Computer Use 操作桌面 UI。
- 如果只需要读 UI 文本，部分机器上 `include_screenshot=false` 的 accessibility 路径仍可工作，但坐标点击通常仍不可用。

未解决占位：

- 需要 OpenAI 在 helper 中 feature-detect 该 API，或在不支持时跳过边框设置继续截图。

## 5. `spawn setup refresh` / `os error 740`

常见报错：

- `windows sandbox failed: spawn setup refresh`
- `setup refresh failed to spawn codex-windows-sandbox-setup.exe`
- `The requested operation requires elevation. (os error 740)`
- `请求的操作需要提升。 (os error 740)`
- Browser / node_repl / Computer Use 启动前失败

高可信根因：

- `codex-windows-sandbox-setup.exe` 文件名包含 `setup.exe`，且某些版本缺少显式 `asInvoker` manifest，Windows UAC installer detection 将它当作需要提权的安装器，非管理员上下文直接 `CreateProcess` 会返回 740。代表 issue：[#24050](https://github.com/openai/codex/issues/24050)、[#26477](https://github.com/openai/codex/issues/26477)。
- CLI 0.136/0.137 上也有回归报告，0.132.0 在部分机器上可用。代表 issue：[#26158](https://github.com/openai/codex/issues/26158)。
- Store/MSIX 安装目录或 workspace 路径如果落在 sandbox 用户/ACL 难以授权的位置，也可能表现为 sandbox 授权失败。社区 X case 中，Microsoft Store 一直卡在检查更新，用户通过直接 MSIX 安装成功，但仍需要注意安装目录，否则 sandbox 授权失败。证据等级 C，作为路径/ACL 排查线索。

可尝试解决：

1. 先升级到最新 Store/CLI 版本；如果是 CLI 且必须工作，可临时回退到已知可用版本（例如 issue 中提到的 0.132.0）。
2. 在 `config.toml` 中临时切换：

```toml
[windows]
sandbox = "unelevated"
```

3. 如果是 Browser/Computer Use 触发的 node_repl 错误，可先禁用相关插件，保证普通代码任务可做。
4. 对可信项目的短期应急可使用 `sandbox_mode = "danger-full-access"`，但这会移除 sandbox 边界，只适合本机可信仓库和明确风险接受。
5. 如果是 MSIX 绕过 Store 安装后出现 sandbox 授权失败，记录 Codex Appx `InstallLocation`、workspace 路径、是否非 C 盘/OneDrive/加密目录/企业重定向目录，并优先换到普通本地 NTFS 路径测试，例如 `%USERPROFILE%\source\<repo>`。

不建议：

- 不建议长期靠给 helper 二进制改 manifest、改名、手动替换 Store 包内文件；这会被更新覆盖，也可能破坏签名/更新路径。

未解决占位：

- 等官方版本为 helper 增加 manifest 或避免 installer detection。

## 6. 其他 Windows sandbox 启动错误

### `CreateProcessWithLogonW failed: 1326 / 1909`

含义：sandbox 命令还没进 PowerShell，Windows 在以 sandbox 用户启动 runner 时失败。代表 issue：[#18620](https://github.com/openai/codex/issues/18620)。

可尝试：

- 切换 `[windows] sandbox = "unelevated"`。
- 尝试“以管理员身份运行 Codex”，但不要假设一定有效。
- 企业/家庭策略、账号凭据、UAC、本地安全策略都可能影响；保留 sandbox 日志和 Windows Event Viewer 证据。

### `SetTokenInformation(TokenDefaultDacl) failed: 1344`

含义：workspace-write 构造 restricted token 默认 DACL 时 ACE 太多，可能和本地化用户目录、legacy junction、写根数量膨胀有关。代表 issue：[#26438](https://github.com/openai/codex/issues/26438)。

可尝试：

- 临时用 `read-only` 或 `danger-full-access`。
- 减少 writable roots，避免把整个用户目录或复杂 junction 树加入可写根。
- 等官方修复 DACL 构造/去重/上限处理。

### `program not found`

代表 issue：[#23194](https://github.com/openai/codex/issues/23194)。先检查安装是否完整、Store 是否更新中、`.codex`/runtime cache 是否被杀软隔离。

## 7. 网络、DNS、npm、代理

常见报错：

- npm / pnpm 在 Codex sandbox 中 DNS 失败，但普通 PowerShell 正常。
- `sandbox_workspace_write.network_access = true` 后仍不能访问。
- WSL 模式 UI 一直 reconnecting / AI calls timeout。

事实边界：

- Codex sandbox 默认不允许网络；`workspace-write` 下需要显式开启 `sandbox_workspace_write.network_access = true`。
- Windows sandbox 的 network path 仍有多起 open issue。代表 issue：[#18675](https://github.com/openai/codex/issues/18675)、[#25207](https://github.com/openai/codex/issues/25207)。
- WSL Desktop 模式可能直接通过 `wsl.exe <binary>` 启动，不经 login shell，因此不会加载 `~/.bashrc` 里的代理变量。代表 issue：[#25117](https://github.com/openai/codex/issues/25117)。

可尝试解决：

```toml
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = true
```

WSL 代理场景，把代理设置到 Windows 用户环境变量，而不是只写 WSL shell profile：

```powershell
[Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://127.0.0.1:7890", "User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://127.0.0.1:7890", "User")
```

然后完全重启 Codex。

临时方案：

- 依赖安装先在普通 PowerShell/Windows Terminal 外部执行。
- 对 pnpm/npx/npm 缓存目录单独加 writable roots；如果仍有 `EPERM realpath C:\Users\<user>`，参考 [#23483](https://github.com/openai/codex/issues/23483)，可能是 profile read/realpath 权限问题，不只是 cache 写权限问题。

## 8. WSL / Windows 混合模式

常见问题：

- Windows app 打开 WSL workspace，但 agent 仍按 Windows_NT 跑，`/bin/bash` 报 os error 2。
- WSL mode 读错 Windows/WSL 的 `config.toml`、`AGENTS.md`、`CODEX_HOME`。
- WSL app-server 使用 WSL `~/.codex` 而不是 Windows `%USERPROFILE%\.codex`。
- Windows 原生模式因为 Windows 环境里存在 `WSL_DISTRO_NAME`，同步调用 `wsl.exe` 导致 UI 卡顿。

代表 issue：

- [#25216](https://github.com/openai/codex/issues/25216)：Windows Desktop + WSL umbrella / release-gate。
- [#22759](https://github.com/openai/codex/issues/22759)：Windows/WSL Codex home split-brain。
- [#22376](https://github.com/openai/codex/issues/22376)：`WSL_DISTRO_NAME` 触发 Windows-native UI freeze。
- [#24884](https://github.com/openai/codex/issues/24884)：WSL mode 需要 `danger-full-access` 才能访问 WSL。
- [#26096](https://github.com/openai/codex/issues/26096)：打开 WSL workspace 但 agent 按 Windows_NT 跑。

建议策略：

- 二选一，不要半混合。
- Windows 原生工作流：项目放 Windows 文件系统，WSL 需要访问时用 `/mnt/c/...`。
- WSL 原生工作流：项目放 WSL `/home/<user>/code/...`，在 WSL 里安装并使用 Codex CLI。
- 不要随意让 Windows app 和 WSL CLI 共享同一个 SQLite state；如果确实要共享，明确设置 `CODEX_HOME` 并先备份。
- 如果 Windows 用户环境变量里有 `WSL_DISTRO_NAME`，而 Codex agent 选的是 Windows native，删除它并重启：

```powershell
[Environment]::SetEnvironmentVariable("WSL_DISTRO_NAME", $null, "User")
```

## 9. PowerShell / Shell / 编码 / 用户名

常见报错：

- `Internal Windows PowerShell error. Loading managed Windows PowerShell failed with error 8009001d`
- 设置 Integrated Terminal Shell 为 Command Prompt，但 tool execution 仍初始化 PowerShell。
- 非 ASCII Windows 用户名导致 `$HOME` / `~` 变成 mojibake。
- `npm.ps1 cannot be loaded because running scripts is disabled on this system.`

代表 issue：

- [#13917](https://github.com/openai/codex/issues/13917)：PowerShell host 8009001d。
- [#19629](https://github.com/openai/codex/issues/19629)：Integrated Terminal Shell 设为 cmd 仍依赖 PowerShell。
- [#16268](https://github.com/openai/codex/issues/16268)：用户名含 `é` 时 HOME 路径损坏。
- 中文博客：[codex在Windows环境下沙箱执行命令无输出问题及解决](https://www.letr7.com/2026/02/13/codex-in-windows/) 报告 Store 版 PowerShell 位于 WindowsApps 时导致 `CreateProcessAsUserW failed: 1920`，卸载 Store PowerShell、改用 GitHub/MSI 安装的 PowerShell 后恢复。

可尝试解决：

- PowerShell 执行策略：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

- 如果 `pwsh` 来自 Microsoft Store，改用 PowerShell 官方 MSI/GitHub release 安装，并确保 `where.exe pwsh` 优先指向普通安装路径而不是 WindowsApps。
- 非 ASCII 用户名问题暂无通用修复；保守 workaround 是使用 ASCII 用户目录的 Windows 账号，或把 Codex state 放到 ASCII 路径并显式设置 `CODEX_HOME`。这类改动前必须备份。

未解决占位：

- tool execution 是否应独立支持 cmd/Git Bash，以及 HOME 编码修复，均待官方。

## 10. 长会话、历史记录、内存、启动崩溃

常见报错：

- `RangeError: Invalid string length`
- `memory allocation failed`
- 打开旧聊天卡死，新聊天正常。
- `codex resume` 交互 picker 卡住，但 `codex resume <id>` 可用。

高可信根因：

- 过大的 rollout JSONL 被主进程/客户端一次性聚合或渲染，超过 V8 string limit 或导致 UI/内存崩溃。代表 issue：[#22004](https://github.com/openai/codex/issues/22004)、[#25430](https://github.com/openai/codex/issues/25430)、[#26104](https://github.com/openai/codex/issues/26104)。

可尝试解决：

1. 结束所有 Codex 进程。
2. 备份 `%USERPROFILE%\.codex\sessions`。
3. 按大小找异常 session：

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\sessions" -Recurse -Filter "*.jsonl" |
  Sort-Object Length -Descending |
  Select-Object -First 20 FullName,Length,LastWriteTime
```

4. 把超大 rollout 移到 `.codex\archived-large-sessions` 之类的目录外，再启动 Codex。
5. CLI 场景尝试直接 `codex resume <session-id>` 绕过 picker。

预防：

- 图片生成、长日志、长时间诊断不要堆在同一个 thread。
- 大输出优先落文件，不要让终端输出全部进对话。
- 重要工作及时开新 thread。

未解决占位：

- 需要官方实现分页/流式加载、rollout 大小上限、图片引用化存储。

## 11. UI 透明、最大化、卡顿

常见症状：

- 最大化后侧栏/顶部透明，露出后面的窗口。
- Codex 显示 Not Responding，但点击可能仍生效。
- 多线程、长 thread、MCP 自启动后 UI 越来越卡。

代表 issue：

- [#25513](https://github.com/openai/codex/issues/25513)：最大化透明/冻结。
- [#20867](https://github.com/openai/codex/issues/20867)：长线程、重复 MCP、非 Git workspace 导致 Windows desktop 卡顿。
- [#26401](https://github.com/openai/codex/issues/26401)：当前版本仍有 micro-freeze。

可尝试解决：

- Settings -> Appearance 里关闭 Translucent Sidebar。
- 不用原生最大化，改成“接近全屏的普通窗口”。
- 清理 Electron/GPU cache 后重启。
- 暂时禁用不需要的 bundled/third-party MCP/plugin，尤其是 Browser、security-guidance 这类会启动 helper 的插件。
- broad workspace 不要直接开 `D:\` 这类非 Git 根目录；尽量打开具体项目目录。

未解决占位：

- 最大化渲染、长 thread 虚拟化、MCP 去重仍待官方修复。

## 12. 配置文件损坏

常见报错：

- `failed to load configuration: ... config.toml: key with no value, expected =`
- `config.toml` 全部变成 NUL 字节。

代表 issue：[#26421](https://github.com/openai/codex/issues/26421)。

可尝试解决：

```powershell
Move-Item "$env:USERPROFILE\.codex\config.toml" "$env:USERPROFILE\.codex\config.toml.corrupt"
New-Item -ItemType File "$env:USERPROFILE\.codex\config.toml"
```

然后重新设置 sandbox、plugins、MCP、项目 trust。若曾经在 session 中输出过 config，可从 JSONL 里找回片段。

未解决占位：

- 需要官方将 `config.toml` 等关键文件改成 temp-write + flush + atomic rename。

## 13. 启动空白、直接闪退、Crashpad dump

常见症状：

- 打开后 blank / spinner。
- Store app 几秒后退出，Task Manager 里 Suspended 后消失。
- Crashpad reports 生成 `.dmp`。
- Windows 11 LTSC / IoT LTSC 机器上手动安装 MSIX、补 Store 组件后仍打不开。

代表 issue：

- [#19352](https://github.com/openai/codex/issues/19352)：Windows app blank。
- [#25912](https://github.com/openai/codex/issues/25912)：Store app 启动即 crash。

可尝试解决：

- 先用 CLI 登录/刷新 auth，再开桌面应用（社区有成功个例）。
- 清理 app cache、Repair/Reset、Store 更新。
- 检查 `C:\Windows\System32\drivers\etc\hosts` 是否劫持 Microsoft / Store / login 相关域名。社区 X case 中，Windows 11 LTSC 2024 无 Store UI、手装 MSIX 和补 Store 依赖都未解决，最终发现 hosts 文件里 Microsoft 相关域名被劫持。
- 若有 Crashpad dump，提交 GitHub issue 或 `/feedback`，不要只写“闪退”。

占位：

- 无通用解决方案；需要具体 dump 和日志。
- LTSC + Store 组件 + hosts 劫持叠加时，不能只按“缺 Store”处理；需要同时核查 App Installer / Store / Windows App Runtime 依赖和网络解析。

## 14. 杀软/Defender/企业安全软件拦截

已见报告：

- Norton 阻止 PowerShell 或 `.ps1` helper。代表 issue：[#25425](https://github.com/openai/codex/issues/25425)。
- Symantec 弹出 `powershell!g111` / `Terminate!g2`。代表 issue：[#26194](https://github.com/openai/codex/issues/26194)。
- Windows Defender 对 Codex 生成的 PowerShell reflection 命令报警。代表 issue：[#26218](https://github.com/openai/codex/issues/26218)。

建议：

- 不要盲目全盘白名单。先保存拦截事件、命令行、文件路径和 Codex 任务背景。
- 只对白名单 OpenAI 签名的 Codex 安装路径、明确可信 workspace、明确可信命令做最小例外。
- 反射、下载执行、混淆 PowerShell 命令即使来自 Codex 也应按安全流程审查。

## 15. Microsoft Store / 安装位置 / ARM64

安装与更新：

- 官方 Windows app 当前走 Microsoft Store / winget。V2EX 用户也讨论过是否有非商店版：[windows 的 codex 有非商店版的么？](https://www.v2ex.com/t/1207852)。
- Microsoft 文档说明，LTSC 场景可能有 Store 服务用于更新预装应用，但不一定包含用于浏览和安装应用的 Store UI。参考：[Microsoft Store Access](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/customize/microsoft-store-access)。
- Microsoft MSIX troubleshooting 文档说明，手动安装 MSIX 时可能缺 VCLibs、Windows App SDK / Windows App Runtime、.NET Native 等 framework package，表现为安装失败或安装后启动崩溃。参考：[MSIX troubleshooting guide](https://learn.microsoft.com/en-us/windows/msix/msix-troubleshooting-guide)。
- Reddit 中文用户报告：Windows 默认新应用安装位置改到 D 盘后，in-app browser 不可用；恢复默认到 C 盘、卸载重装后恢复。来源：[windows上的codex安装后无法使用应用内的浏览器](https://www.reddit.com/user/xzjpanda/comments/1tp4hcv/windows%E4%B8%8A%E7%9A%84codex%E5%AE%89%E8%A3%85%E5%90%8E%E6%97%A0%E6%B3%95%E4%BD%BF%E7%94%A8%E5%BA%94%E7%94%A8%E5%86%85%E7%9A%84%E6%B5%8F%E8%A7%88%E5%99%A8/)。
- X 社区 case：给 Windows 11 LTSC 2024 用户手装 Codex MSIX、补 Store 相关包、再从 Store 安装 Codex 仍打不开，最后发现 hosts 文件中 Microsoft 相关域名被劫持。证据等级 C，作为“LTSC/Store/网络解析叠加”的排查线索，不单独证明 Codex bug。
- X 社区 case：Microsoft Store 一直卡在“检查更新”，最终通过直接下载 MSIX 才成功安装；但还需要注意安装目录，否则 Windows sandbox 授权会失败。证据等级 C，作为“Store 更新卡住 + MSIX 绕过 + 路径/ACL 授权边界”的排查线索。
- Windows ARM64 仍以 x64 emulation 为主，有性能/电池/二进制缺失讨论。代表 issue：[#17491](https://github.com/openai/codex/issues/17491)。

建议：

- 优先 Store 官方渠道。
- 非 C 盘 Store app、企业重定向、EFS、OneDrive、加密目录都应作为插件/Browser/Computer Use 问题的排查变量。
- LTSC/无 Store UI 场景先确认这四层：系统版本是否 LTSC、Store/App Installer 是否存在、MSIX framework dependencies 是否完整、hosts/DNS 是否能正常解析 Microsoft/Store/login 域名。
- Store 卡在“检查更新”时，先把它作为 Store/Windows Update/网络/缓存层问题处理；MSIX 可以作为临时绕过安装渠道，但不是默认推荐通用路径。若走 MSIX，需要额外核查依赖包和安装/工作目录对 Windows sandbox ACL 是否友好。
- ARM64 社区 repackaging 只能作为研究线索，不作为默认推荐。

只读排查命令：

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber
Get-AppxPackage Microsoft.WindowsStore,Microsoft.DesktopAppInstaller,Microsoft.VCLibs*,Microsoft.WindowsAppRuntime* |
  Select-Object Name,Version,PackageFullName
Get-AppxPackage OpenAI.Codex | Select-Object Name,Version,InstallLocation
Get-Item "<WORKSPACE>" | Select-Object FullName,Attributes
Get-Content "$env:WINDIR\System32\drivers\etc\hosts" |
  Select-String -Pattern "microsoft|windows|store|msft|live.com|microsoftonline|login|aka.ms"
Resolve-DnsName www.microsoft.com
Resolve-DnsName login.microsoftonline.com
Resolve-DnsName storeedgefd.dsx.mp.microsoft.com
```

## 16. 报告 issue 模板

提交 GitHub issue 时至少包含：

- Codex app 版本、CLI 版本、插件 cache 版本。
- Windows 版本、build、CPU 架构、是否 ARM64、是否 Windows 10/11/Insider。
- 安装渠道：Store、winget、npm、standalone installer。
- Agent environment：Windows native / WSL。
- `sandbox_mode`、`[windows] sandbox`、`approval_policy`。
- 关键错误原文，不要只写“不能用”。
- 代表日志片段，敏感路径/用户名/token 先脱敏。
- 如果是启动崩溃，附 Crashpad/WER dump 信息。

## 17. 当前优先级

P0：

- `spawn setup refresh` / `os error 740` 导致 shell、node_repl、Browser、Computer Use 全部不可用。
- bundled marketplace 半更新导致 Browser/Computer Use 大面积缺失。
- 长 session / rollout 触发启动崩溃或旧聊天无法打开。

P1：

- Worktree 创建失败：Codex 使用不存在的 `master/main` 或 remote-only 短分支名。
- WSL/Windows split-brain：config、CODEX_HOME、path、plugins、exec routing。
- Windows 10 Computer Use screenshot API 不兼容。
- sandbox network 开启后仍无法出网。
- 最大化透明/冻结。

P2：

- PowerShell 编码、非 ASCII 用户名、Store PowerShell 路径。
- 杀软误报与企业安全软件拦截。
- Store 安装路径、ARM64、Microsoft Store 更新慢。
