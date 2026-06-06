# Windows Codex Issue 来源与监控清单

更新日期：2026-06-05

## 已用主要来源

官方：

- [Codex app for Windows](https://developers.openai.com/codex/app/windows)
- [Windows platform](https://developers.openai.com/codex/windows)
- [Computer Use](https://developers.openai.com/codex/app/computer-use)
- [In-app browser](https://developers.openai.com/codex/app/browser)
- [Worktrees](https://developers.openai.com/codex/app/worktrees)
- [Building a safe, effective sandbox to enable Codex on Windows](https://openai.com/index/building-codex-windows-sandbox/)
- [Running Codex safely at OpenAI](https://openai.com/index/running-codex-safely/)
- [Git worktree 官方文档](https://git-scm.com/docs/git-worktree)

GitHub OpenAI/Codex：

- 主入口：[openai/codex issues](https://github.com/openai/codex/issues)
- Windows 标签：[label:windows-os](https://github.com/openai/codex/issues?q=is%3Aissue%20label%3Awindows-os)
- Windows sandbox：[label:windows-os label:sandbox](https://github.com/openai/codex/issues?q=is%3Aissue%20label%3Awindows-os%20label%3Asandbox)
- Computer Use：[label:windows-os label:computer-use](https://github.com/openai/codex/issues?q=is%3Aissue%20label%3Awindows-os%20label%3Acomputer-use)
- WSL 搜索：[Windows WSL](https://github.com/openai/codex/issues?q=is%3Aissue%20Windows%20WSL)

代表 issue：

- [#12346](https://github.com/openai/codex/issues/12346) worktree 无 `main` / 本地无 `main` 时 `fatal: invalid reference: main`
- [#22635](https://github.com/openai/codex/issues/22635) worktree remote-only branch 被短名传给 Git
- [#26536](https://github.com/openai/codex/issues/26536) Computer Use plugin unavailable
- [#26501](https://github.com/openai/codex/issues/26501) bundled marketplace partial
- [#25220](https://github.com/openai/codex/issues/25220) EFS-encrypted WindowsApps copyfile failure
- [#25178](https://github.com/openai/codex/issues/25178) Windows 10 Computer Use screenshot `SetIsBorderRequired`
- [#24050](https://github.com/openai/codex/issues/24050) sandbox setup helper UAC installer detection
- [#26477](https://github.com/openai/codex/issues/26477) node_repl os error 740
- [#26158](https://github.com/openai/codex/issues/26158) CLI 0.136/0.137 sandbox regression
- [#18620](https://github.com/openai/codex/issues/18620) `CreateProcessWithLogonW failed`
- [#26438](https://github.com/openai/codex/issues/26438) `SetTokenInformation(TokenDefaultDacl) failed: 1344`
- [#18675](https://github.com/openai/codex/issues/18675) npm/network DNS in sandbox
- [#25117](https://github.com/openai/codex/issues/25117) WSL proxy env missing
- [#25216](https://github.com/openai/codex/issues/25216) Windows Desktop + WSL umbrella
- [#22376](https://github.com/openai/codex/issues/22376) `WSL_DISTRO_NAME` freezes Windows-native app
- [#22004](https://github.com/openai/codex/issues/22004) `RangeError: Invalid string length`
- [#25430](https://github.com/openai/codex/issues/25430) large session resume picker freeze
- [#26104](https://github.com/openai/codex/issues/26104) old chat sessions fail after update
- [#25513](https://github.com/openai/codex/issues/25513) maximized rendering transparency/freezes
- [#26421](https://github.com/openai/codex/issues/26421) `config.toml` zero-filled
- [#19352](https://github.com/openai/codex/issues/19352) Windows app blank
- [#25912](https://github.com/openai/codex/issues/25912) Store app crashes on launch
- [#19629](https://github.com/openai/codex/issues/19629) tool execution still depends on PowerShell
- [#16268](https://github.com/openai/codex/issues/16268) non-ASCII username corrupt HOME
- [#17491](https://github.com/openai/codex/issues/17491) Windows ARM64 emulation

外部社区：

- Reddit r/codex：Windows/WSL 性能回归、UI 冻结、Browser/Computer Use 报错。
  - [Latest Codex App + Windows + WSL = serious performance regression](https://www.reddit.com/r/codex/comments/1twyl7w/lastest_codex_app_windows_wsl_serious_performance/)
  - [UI Codex freezing and sometime not responding](https://www.reddit.com/r/codex/comments/1stuej3/ui_codex_freezing_and_sometime_not_responding/)
  - [windows上的codex安装后无法使用应用内的浏览器](https://www.reddit.com/user/xzjpanda/comments/1tp4hcv/windows%E4%B8%8A%E7%9A%84codex%E5%AE%89%E8%A3%85%E5%90%8E%E6%97%A0%E6%B3%95%E4%BD%BF%E7%94%A8%E5%BA%94%E7%94%A8%E5%86%85%E7%9A%84%E6%B5%8F%E8%A7%88%E5%99%A8/)
- V2EX：
  - [Codex 节点](https://v2ex.com/go/codex)
  - [windows 的 codex 有非商店版的么？](https://www.v2ex.com/t/1207852)
- 中文博客：
  - [codex在Windows环境下沙箱执行命令无输出问题及解决](https://www.letr7.com/2026/02/13/codex-in-windows/)
  - [windows 下 CodeX 提示 Computer Use plugins unavailable](https://www.cnblogs.com/googlegis/p/20288340)
- OpenAI Developer Community：
  - [Codex VS Code extension stuck on infinite loading after frozen chat session](https://community.openai.com/t/codex-vs-code-extension-stuck-on-infinite-loading-after-frozen-chat-session/1367741)
  - [Codex CLI and IDE Prompting for Approval to Edit Files](https://community.openai.com/t/codex-cli-and-ide-prompting-for-approval-to-edit-files/1354993)

## 推荐监控源

一线源：

- GitHub issue label/search：最重要，含版本、日志、维护者标签、duplicate 链接。
- GitHub PR/commit/release：用于确认修复是否已合并/发布。
- OpenAI docs/manual/blog/status：只用于事实边界，不替代 issue 复现。
- Git 官方文档：用于判断 `git worktree`、ref、branch、tracking branch 的行为边界。

建议 GitHub 检索式：

```text
repo:openai/codex is:issue "fatal: invalid reference" worktree
repo:openai/codex is:issue label:worktrees windows
repo:openai/codex is:issue "Starting worktree creation"
repo:openai/codex is:issue "remote-only branch" worktree
repo:openai/codex is:issue "origin/HEAD" worktree
```

英语社区：

- Reddit：`r/codex`、`r/OpenAI`、`r/OpenaiCodex`。
- OpenAI Developer Community。
- X/Twitter：官方账号、OpenAI 工程师、关键词流。公开搜索可用性差，适合作为“发现传播热点”，不适合作为唯一事实来源。
- Hacker News、Lobsters、Stack Overflow、WindowsForum。

中文社区：

- V2EX `go/codex`。
- 博客园、CSDN/DeepSeek 技术社区、掘金、知乎。
- Linux.do、NodeSeek、Telegram/Discord 群内反馈（需要授权）。
- 微信公众号/知识星球/即刻/微博：适合舆情和 workaround 收集，但可检索性较差。
- 小红书：适合大陆普通用户报错截图和“怎么解决”的口语化反馈，但公开 Web 搜索覆盖很差。

平台/系统侧：

- Microsoft Store reviews。
- WinGet package/release 问题。
- PowerShell GitHub issue。
- Windows Insider / Feedback Hub。
- 安全软件社区：Defender、Norton、Symantec、CrowdStrike 等误报。

本机日志源：

- `%USERPROFILE%\.codex\config.toml`
- `%USERPROFILE%\.codex\sessions`
- `%USERPROFILE%\.codex\.tmp`
- `%USERPROFILE%\.codex\plugins\cache`
- Windows Event Viewer / Windows Error Reporting
- Electron/Crashpad dumps

## 小红书接入判断

当前搜索结果显示，小红书通用搜索/笔记/评论 API 主要是第三方聚合或爬虫服务；官方开放能力通常偏企业、蒲公英、创作者/品牌投放数据，不等于公开 issue 搜索 API。

建议：

1. 不把小红书作为第一阶段必需数据源。
2. 如果要接入，优先走合规授权或企业/蒲公英类官方路径。
3. 若使用第三方 API 或爬虫，先做 ToS、隐私和账号风控评估。
4. MVP 可以先人工关键词巡检：
   - `codex windows`
   - `codex computer use 不可用`
   - `codex 浏览器 用不了`
   - `codex 沙箱`
   - `spawn setup refresh`
   - `os error 740`
5. 收集时只记录公开笔记 URL、发布时间、报错关键词和匿名化摘要，不保存用户隐私截图原图。

## 后续工作

- 每周刷新 GitHub `windows-os`、`sandbox`、`computer-use`、`browser`、`app-server` 标签。
- 对每个高频报错维护“已修复版本 / 仍受影响版本 / workaround 是否仍有效”。
- 为每个 workaround 添加风险等级：安全、低风险、破坏性、非官方。
- 追加中文案例时，优先把原帖与对应 GitHub issue 建立映射。
