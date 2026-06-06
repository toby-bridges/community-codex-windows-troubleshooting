# Codex Windows 研究库的 Skill / Plugin 设计

结论：第一阶段做成一个 skill，不急着做 plugin。

理由：

- 当前核心价值是排障流程、证据分级、错误矩阵和 issue 映射，属于知识和工作流，最适合放在 skill。
- skill 可以用 `references/` 做渐进加载：平时只加载短 `SKILL.md`，遇到 worktree、sandbox、Computer Use 等具体问题时再读细分资料。
- plugin 适合需要 Codex UI 安装、分享、marketplace、多个 skills、MCP server、hooks、assets 或自动更新分发时使用。现在直接做 plugin 会增加结构和维护成本。

## 已创建 skill

路径：

```text
skills/codex-windows-troubleshooter/
```

结构：

```text
codex-windows-troubleshooter/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── official-baseline.md
│   ├── error-matrix.md
│   ├── github-issue-map.md
│   └── worktree.md
└── scripts/
    └── collect-codex-windows-diagnostics.ps1
```

验证状态：

```text
Skill is valid!
```

## 何时拆成多个 skills

保持一个 skill，直到出现以下任一情况：

- `SKILL.md` 超过 500 行，或者 trigger 描述变得含混。
- Windows sandbox、worktree、Computer Use/Browser、WSL、session 崩溃各自都有独立脚本和长参考材料。
- 用户经常只问其中一个领域，加载整个排障体系显得浪费。

可拆分方案：

- `codex-windows-troubleshooter`：总入口、证据分级、分流。
- `codex-worktree-debugger`：Git worktree、Handoff、branch/ref、WSL-backed repo。
- `codex-windows-sandbox-debugger`：elevated/unelevated sandbox、UAC、network、ACL、DACL。
- `codex-computer-use-debugger`：Browser、Chrome、Computer Use、plugin marketplace、native helper。

## 何时做成 plugin

当需要安装/分享给其他 Codex 环境时，再创建 plugin，例如：

```text
codex-windows-support/
├── .codex-plugin/
│   └── plugin.json
├── skills/
│   └── codex-windows-troubleshooter/
└── scripts/
    └── refresh-openai-codex-issues.ps1
```

plugin 版本可以加入：

- GitHub issue refresh 脚本。
- 本地诊断脚本。
- 模板化 GitHub issue 报告。
- 可选 MCP server，用于查询本地 `.codex` 状态或 issue 缓存。
- marketplace 元数据，方便在 Codex app 中查看和分享。

## 当前维护规则

- 新错误先进 `WINDOWS-CODEX-ERROR-GUIDE.md`。
- 新来源先进 `RESEARCH-SOURCES.md`。
- 高风险结论补到 `FACT-CHECK-YYYY-MM-DD.md`。
- 稳定、可复用的排障逻辑再同步进 skill 的 `references/`。
- 不把社区传闻直接写成已解决；必须标证据等级和 workaround 风险。
