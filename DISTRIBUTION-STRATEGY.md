# Distribution Strategy

目标：把 `community-codex-windows-troubleshooting` 分发给真正遇到 Codex Windows 问题的人，同时建立“可信、可复查、非官方社区指南”的影响力。

一句话定位：

> This GitHub project helps Codex users on Windows diagnose common failures, map them to verified upstream issues, and apply safe troubleshooting steps without guessing.

中文定位：

> 这个 GitHub 项目可以帮助 Windows 上的 Codex 用户把常见报错定位到已核查的 GitHub issue 和安全排障步骤，从而少走弯路地恢复可用工作流。

## 分发原则

- 不要“到处扔链接”。优先进入用户正在抱怨具体报错的上下文。
- 每次分发都带一个具体错误签名，例如 `fatal: invalid reference: master`、`Computer Use plugins unavailable`、`os error 740`。
- 对外主张是“社区事实核查 + 安全排障”，不是“万能修复器”。
- 所有帖子都明确非官方，避免被误解成 OpenAI 支持渠道。
- 不买 star，不刷量，不拉群互赞；AI/devtool 领域已经对假 star 和供应链风险敏感。

## 渠道优先级

### Tier 0：GitHub 原生分发

这是长期 SEO/GEO 的根。

动作：

- 仓库名：`community-codex-windows-troubleshooting`
- 描述：`Community field guide and read-only diagnostics for troubleshooting Codex on Windows.`
- Topics：`codex`、`windows`、`troubleshooting`、`openai-codex`、`powershell`、`wsl`、`sandbox`、`computer-use`、`browser-use`、`worktree`
- 首个 release：`v0.1.0 - First dogfooded Windows troubleshooting matrix`
- 开启 Discussions：`Q&A`、`Case reports`、`Source updates`
- Pin 一个 issue：`Submit a redacted Codex Windows error case`
- 每个高频错误签名都出现在 README 和 guide 标题/锚点里。

依据：

- GitHub 官方建议仓库应有 README、license、contribution guidelines 等基础文件。
- GitHub topics 能帮助仓库分类和发现。

参考：

- https://docs.github.com/en/repositories/creating-and-managing-repositories/best-practices-for-repositories
- https://docs.github.com/articles/classifying-your-repository-with-topics

### Tier 1：你的中文 X/Twitter 账号

你已有 1 万中文粉丝，这是第一波种子用户和反馈入口。

打法：

- 不要只发“我开源了”。发“我把自己遇到的 Codex Windows worktree 报错定位清楚了”。
- 首条 thread 用真实案例开头：`fatal: invalid reference: master`。
- 第二条解释项目方法论：证据等级、dogfood matrix、只读诊断脚本。
- 第三条邀请贡献：贴错误原文、不要贴 token/私有路径。
- 置顶 7 天，之后每修一个高频 case 发一次短更新。

建议首发标题：

```text
我开源了一个 Codex Windows 社区排障指南：把常见报错映射到 GitHub issue、事实核查和安全 workaround。
```

建议 thread 结构：

1. 痛点：Codex Windows 报错信息经常很短，用户只能猜。
2. 例子：`fatal: invalid reference: master` 实际是空 Git repo 的 unborn branch。
3. 方法：每个 case 标 L0/L1/L2 dogfood 等级。
4. 价值：避免乱删 `.codex`、乱改 sandbox、乱动 Store 包。
5. CTA：遇到 Windows Codex 报错，把错误原文和脱敏环境发 issue。

### Tier 2：中文开发者社区

这些渠道最容易找到“真实 Windows 用户”。

#### V2EX

优先节点：

- `Codex`
- `程序员`
- `Windows`
- `分享创造`

为什么值得发：

- V2EX 已有 Codex 节点，并且最近有 Windows、Chrome 插件、Computer Use 相关讨论。
- V2EX 用户会直接贴错误、代理、插件、Windows 环境，适合收集 case。

发帖角度：

```text
[分享创造] 我整理了一个 Codex Windows 报错排障指南：worktree、sandbox、Chrome/Computer Use、WSL
```

参考线索：

- https://global.v2ex.com/go/codex
- https://www.v2ex.com/t/1213866
- https://global.v2ex.com/t/1211095
- https://www.v2ex.com/t/1213455

#### Linux.do

适合主题：

- Codex Chrome 插件不显示
- Windows 用户、代理、浏览器插件问题
- AI 工具折腾用户

发帖角度：

```text
整理了一个 Codex Windows 排障指南，先覆盖 Chrome/Computer Use 插件、sandbox 和 WSL
```

参考线索：

- https://linux.do/t/topic/2162384

#### 博客园 / 掘金 / 知乎专栏 / CSDN

这些不是首发引爆渠道，但利于长尾搜索。

建议文章：

1. `Codex Windows worktree failed: fatal invalid reference master 的真实原因`
2. `Codex Windows Chrome / Computer Use plugins unavailable 排查路线`
3. `不要先删 .codex：Codex Windows 报错的安全诊断顺序`

博客园已有同类高价值中文排查文，说明这个需求存在：

- https://www.cnblogs.com/0X78/articles/20313356

### Tier 3：英文问题社区

#### OpenAI Developer Community

适合发在 Codex 相关分类。

打法：

- 不要写成宣传帖。
- 发“community-maintained Windows troubleshooting matrix”，邀请补充 issue 映射。
- 每个结论都链回 upstream GitHub issue。

参考：

- https://community.openai.com/c/codex/37
- https://developers.openai.com/community

#### Reddit

优先 subreddit：

- `r/codex`
- `r/OpenaiCodex`
- `r/OpenAI`
- `r/coolgithubprojects`
- `r/SideProject` 只在后续版本更完整时发

打法：

- 在 `r/codex` 先发最精准贴。
- 标题带具体痛点，不要像广告。

建议标题：

```text
I made a community Codex Windows troubleshooting matrix for worktree, sandbox, Chrome, Computer Use, and WSL errors
```

为什么值得：

- 最近 Reddit 上有多条 Windows Chrome/Computer Use 相关问题贴。

参考线索：

- https://www.reddit.com/r/codex/comments/1tvdm86/codex_is_not_working_with_chrome_codex_and/
- https://www.reddit.com/r/OpenaiCodex/comments/1tvdqkn/codex_is_not_working_with_chrome_codex_and/
- https://www.reddit.com/r/codex/comments/1trsgpv/possible_fixworkaround_for_windows_codex_browser/
- https://www.reddit.com/r/codex/comments/1twccpt/anyone_uses_chrome_with_codex_on_windows/

### Tier 4：开发者发现平台

#### Hacker News

不要一开始强行 `Show HN`。

原因：

- HN 的 Show HN 官方规则强调必须是别人可以试用的东西；纯文章、列表、newsletter 不适合 Show HN。
- 当前项目有脚本，但核心仍是 field guide。可以先发普通提交，等 CLI/网站 demo 更明显后再发 Show HN。

建议普通提交标题：

```text
Community field guide for troubleshooting Codex on Windows
```

等后续有更强交互工具后，再考虑：

```text
Show HN: Read-only diagnostics for Codex Windows failures
```

参考：

- https://news.ycombinator.com/showhn.html

#### Product Hunt

不建议第一周发。

原因：

- 目前更像 dev support guide，不是完整产品。
- 等有一个小网站、搜索页、诊断脚本 demo 或 release asset 后再发。

适合时机：

- 版本 `v0.3` 后，有英文落地页 + 诊断脚本 + 10+ 外部贡献 case。

#### DEV.to / Hashnode / Medium / LinkedIn

适合发英文技术文章，而不是只发 repo。

建议标题：

```text
Debugging Codex on Windows: Worktrees, Sandbox, Browser, Computer Use, and WSL
```

### Tier 5：Awesome lists / AI tool directories

适合第二波，不适合第一天。

目标：

- `awesome-codex-cli`
- `awesome-ai-coding-tools`
- `awesome-ai-coding-agents`
- `awesome-vibe-coding`

打法：

- 先拿到 20-50 stars 和 3-5 个真实 issue。
- 再 PR 到 awesome lists，分类放在 `Troubleshooting / Diagnostics / Windows`。

参考：

- https://github.com/RoggeOhta/awesome-codex-cli
- https://github.com/ai-for-developers/awesome-ai-coding-tools
- https://github.com/BrethofAI/awesome-ai-coding-agents
- https://awesome-vibe-coding.com/

## 发布节奏

### Day -2 到 Day 0：准备

- GitHub repo 完成 description、topics、release、license、issue template。
- README 顶部有一句话定位、Quick Start、Top errors。
- 准备 2 张图：
  - dogfood matrix 截图
  - worktree `fatal invalid reference master` case flow
- 准备 1 个 60 秒短 demo：运行只读 diagnostics，展示输出结构。

### Day 1：中文首发

渠道：

- 中文 X/Twitter 主 thread
- V2EX `Codex` 或 `分享创造`
- Linux.do

目标：

- 不是追求 star，而是收集第一批真实 Windows case。

### Day 2-3：英文精准分发

渠道：

- OpenAI Developer Community
- Reddit `r/codex`
- Reddit `r/OpenaiCodex`

目标：

- 收集英文用户的 Windows/WSL/Chrome/Computer Use case。

### Day 4-7：内容长尾

渠道：

- 博客园 / 掘金 / 知乎专栏 / CSDN
- DEV.to / Hashnode / Medium

目标：

- 用具体错误签名吃搜索长尾。

### Week 2：二次扩散

渠道：

- Hacker News 普通提交
- Awesome list PR
- LinkedIn / Bluesky / GitHub Discussions

条件：

- 至少 3 个外部用户 case。
- 至少 1 个从 issue 到指南更新的闭环。

### Week 3+：产品化扩散

条件：

- 有搜索页或 docs site。
- 有 release asset。
- 有更多 dogfood cases。

渠道：

- Product Hunt
- AI/devtool directories
- Newsletter outreach

## 内容模板

### 中文 X/Twitter 首发

```text
我开源了一个 Codex Windows 社区排障指南：

community-codex-windows-troubleshooting

它解决的问题很具体：Codex Windows 报错时，不再靠猜。

目前覆盖：
- worktree: fatal invalid reference master/main
- Browser / Computer Use plugins unavailable
- sandbox os error 740
- WSL / CODEX_HOME 混乱
- PowerShell / session / config.toml / Store 安装问题

每个 case 都标了：
- 证据等级 A/B/C/D
- dogfood 等级 L0/L1/L2
- 对应 GitHub issue
- 安全 workaround

非官方社区项目，欢迎提交脱敏 case。
```

### V2EX

```text
标题：[分享创造] 做了一个 Codex Windows 报错排障指南，覆盖 worktree / sandbox / Chrome / Computer Use / WSL

最近 Windows 版 Codex 的 Browser、Chrome、Computer Use、worktree、sandbox 报错挺多，我把自己遇到的问题和 GitHub issue 做了一个社区排障指南。

重点不是收集吐槽，而是每个错误都尽量标：
- 错误签名
- upstream GitHub issue
- 证据等级
- 是否 dogfood 过
- 安全 workaround

如果你遇到 Windows Codex 报错，欢迎贴脱敏错误原文，不要贴 token、私有路径和完整截图。
```

### Reddit

```text
Title: I made a community troubleshooting matrix for Codex on Windows

I kept running into Codex-on-Windows failures where the UI error was too short to know what to do next.

So I built a community field guide that maps Windows Codex errors to:
- exact error signatures
- upstream openai/codex issues
- evidence levels
- safe first checks
- dogfood coverage
- read-only diagnostics

Covered so far: worktrees, sandbox, Chrome/Computer Use plugins, WSL, PowerShell, large sessions, config.toml corruption, Store install edge cases.

Unofficial project. No affiliation with OpenAI. Happy to add more redacted cases.
```

## 衡量指标

不要只看 stars。

第一周核心指标：

- 10 个真实用户 issue 或 comments
- 3 个外部复现 case
- 2 个来自社区的 workaround 修正
- 1 个 upstream GitHub issue 被链接或引用
- 50+ GitHub stars 是结果，不是目标

第一个月核心指标：

- 30+ case reports
- 5+ contributors
- 2-3 个 awesome list 收录
- 至少 1 个英文社区和 1 个中文社区形成自然引用

## 不建议做的事

- 不要在每个 openai/codex issue 下复制粘贴 repo 链接。
- 不要用 “official / support / certified” 这类词。
- 不要把未经验证的社区 workaround 写成已解决。
- 不要发小红书作为第一波主渠道；它更适合后续收集截图和普通用户问题，不适合作为事实源。
- 不要买 star 或互赞；AI/devtool 开源生态对供应链和假星很敏感。

## 最小执行清单

1. GitHub repo 完成 topics、description、v0.1 release。
2. 中文 X thread 首发，置顶 7 天。
3. V2EX Codex 节点发一次，不刷楼。
4. Linux.do 发一次，重点收集插件不可用 case。
5. Reddit `r/codex` 发英文版。
6. OpenAI Developer Community 发事实核查/矩阵帖。
7. 一周后写第一篇中文长文：`Codex Windows fatal invalid reference master 的真实原因`。
8. 两周后 PR 到 awesome lists。
