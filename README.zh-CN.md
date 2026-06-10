# Codex Windows 社区排障指南

![Community Codex Windows Troubleshooting Field Guide 题图](./assets/social-preview.jpg)

这是一个社区维护的 Codex Windows 排障、事实核查和 dogfood 项目。

[English](./README.md) · [报错指南](./WINDOWS-CODEX-ERROR-GUIDE.md) · [提交 case](https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml) · [运行诊断](#快速开始) · [参与贡献](#贡献一个-case)

> 非官方项目。本仓库不隶属于 OpenAI，也不代表 OpenAI 认可、赞助或背书。见 [Branding and Naming](./BRANDING.md)。

## 一句话总结

这个 GitHub 项目可以帮助 Windows 上的 Codex 用户把常见报错定位到已核查的 GitHub issue 和安全排障步骤，从而少走弯路地恢复可用工作流。

## 快速入口

| 我想要... | 从这里开始 |
| --- | --- |
| 解决一个 Codex Windows 报错 | 在 [Windows Codex 报错指南](./WINDOWS-CODEX-ERROR-GUIDE.md) 中搜索错误原文 |
| 分享一个新报错 | [提交脱敏 case report](https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml) |
| 补充 GitHub issue / 社区来源 | [提交来源线索](https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml) |
| 验证一个 workaround | [查看贡献规则](./CONTRIBUTING.md) |

## 这个项目解决什么问题

Codex Windows 用户经常遇到 UI 里难以判断的报错：

- worktree 创建失败
- Windows sandbox 启动失败
- Browser / Computer Use 插件不可用
- WSL 和 Windows 路径、配置、`CODEX_HOME` 混乱
- PowerShell、编码、用户名、执行策略问题
- 长 session 导致卡死或崩溃
- Microsoft Store、安装路径、ARM64、杀软拦截等边缘问题

本项目的目标不是堆 workaround，而是把每个结论分成：

- 错误签名
- 证据等级
- 官方/GitHub/社区来源
- 安全排查步骤
- 可验证 workaround
- 未解决占位
- dogfood 覆盖状态

## 快速开始

1. 在 [Windows Codex 报错指南](./WINDOWS-CODEX-ERROR-GUIDE.md) 中搜索你的错误原文。
2. 在 [Dogfood 覆盖矩阵](./DOGFOOD-MATRIX.md) 中查看这个 case 是否跑过。
3. 用只读诊断脚本采集本机状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\skills\codex-windows-troubleshooter\scripts\collect-codex-windows-diagnostics.ps1" -Workspace "<你的项目路径>"
```

公开提交 issue 前，先检查输出，删掉敏感路径、私有仓库名、token、邮箱和个人信息。

## 贡献一个 case

原始报错也欢迎提交。你不需要写 PR，也不需要理解整个指南，才能贡献一个有用的数据点。维护者会把有效 report 归一化成 case ID、指南更新、dogfood 行和 skill/reference 更新。

最快的有效提交格式是：

```text
错误原文：
使用入口：Windows App / CLI / WSL / Browser / Computer Use / Store / winget
Windows 版本：
Codex 版本：
发生了什么：
尝试过什么，是否解决：
相关链接：
```

如果你遇到新的 Codex Windows 报错、发现已有结论过期，或者验证了某个 workaround，优先走下面这些入口：

| 入口 | 适合情况 | 从这里开始 |
| --- | --- | --- |
| 报错反馈 | 你有准确报错文本、截图中的错误原文，或能稳定复现 | [提交脱敏 case report](https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml) |
| 来源补充 | 你找到了相关 `openai/codex` issue、Reddit、V2EX、X、博客或中文社区帖子 | [补充来源线索](https://github.com/toby-bridges/community-codex-windows-troubleshooting/issues/new?template=codex-windows-error.yml) |
| 解决方案验证 | 你在本机或临时 fixture 中安全验证了 workaround | [提交 Pull Request](./CONTRIBUTING.md) |
| 指南修正 | 某个章节不准确、过时、步骤太危险，或缺少风险提示 | [查看贡献规则](./CONTRIBUTING.md) |

一个高质量 case 通常包含：错误原文、Codex 使用入口（Windows App / CLI / WSL / Browser / Computer Use 等）、Windows 版本大类、Codex 版本、是否可复现、相关链接、尝试过的 workaround、是否只读或可逆。

不要提交 API key、token、cookie、私有仓库名、完整 `.codex` session 文件、包含个人信息的截图、用户名路径、邮箱或未脱敏 crash dump。

## 数据复利

每个有效贡献都应该变成可复用数据，而不是一次性的 support thread：

```text
原始报错 -> 归一化错误签名 -> case ID -> 指南更新 -> dogfood 校验 -> skill/reference 更新
```

维护者可以负责归一化和写入矩阵。贡献者只需要提供脱敏事实：错误原文、环境大类、尝试过什么、是否解决，以及相关 GitHub issue 或社区链接。

## 高频错误入口

| 错误签名 | 故障族群 | 从这里开始 |
| --- | --- | --- |
| `fatal: invalid reference: master` | Git worktree / 空仓库 unborn branch / 本地 ref 缺失 | [Worktree 创建失败](./WINDOWS-CODEX-ERROR-GUIDE.md#2-worktree-创建失败fatal-invalid-reference-mastermain) |
| `fatal: invalid reference: main` | Git worktree / 仓库没有本地 `main` | [Worktree 创建失败](./WINDOWS-CODEX-ERROR-GUIDE.md#2-worktree-创建失败fatal-invalid-reference-mastermain) |
| `Computer Use plugins unavailable` | bundled plugin marketplace / helper path | [Computer Use / Browser 插件不可用](./WINDOWS-CODEX-ERROR-GUIDE.md#3-computer-use--browser-插件不可用) |
| `No plugins found in marketplace openai-bundled` | bundled marketplace cache | [Computer Use / Browser 插件不可用](./WINDOWS-CODEX-ERROR-GUIDE.md#3-computer-use--browser-插件不可用) |
| `SetIsBorderRequired failed: 0x80004002` | Windows 10 Computer Use 截图 API | [Windows 10 Computer Use](./WINDOWS-CODEX-ERROR-GUIDE.md#4-windows-10-computer-use-截图失败) |
| `windows sandbox failed: spawn setup refresh` | Windows sandbox helper 启动 | [sandbox setup refresh](./WINDOWS-CODEX-ERROR-GUIDE.md#5-spawn-setup-refresh--os-error-740) |
| `The requested operation requires elevation. (os error 740)` | UAC / sandbox setup helper | [os error 740](./WINDOWS-CODEX-ERROR-GUIDE.md#5-spawn-setup-refresh--os-error-740) |
| `CreateProcessWithLogonW failed` | Windows sandbox 用户启动 | [其他 sandbox 启动错误](./WINDOWS-CODEX-ERROR-GUIDE.md#6-其他-windows-sandbox-启动错误) |
| `SetTokenInformation(TokenDefaultDacl) failed: 1344` | Windows sandbox DACL 边缘问题 | [其他 sandbox 启动错误](./WINDOWS-CODEX-ERROR-GUIDE.md#6-其他-windows-sandbox-启动错误) |
| `RangeError: Invalid string length` | 超大 session / rollout JSONL | [长会话与启动崩溃](./WINDOWS-CODEX-ERROR-GUIDE.md#10-长会话历史记录内存启动崩溃) |

## 当前交付物

- [Windows Codex 报错指南](./WINDOWS-CODEX-ERROR-GUIDE.md)
- [Dogfood 覆盖矩阵](./DOGFOOD-MATRIX.md)
- [Dogfood 运行日志](./DOGFOOD-LOG.md)
- [来源与监控清单](./RESEARCH-SOURCES.md)
- [2026-06-05 事实核查记录](./FACT-CHECK-2026-06-05.md)
- [Skill / Plugin 设计说明](./SKILL-PLUGIN-DESIGN.md)
- [分发策略](./DISTRIBUTION-STRATEGY.md)
- [GitHub Launch Checklist](./GITHUB-LAUNCH-CHECKLIST.md)
- [Release Notes](./RELEASE_NOTES.md)

## 相关项目

- [CodexGuide](https://github.com/freestylefly/CodexGuide)：更完整的 Codex 学习路线和实践指南，适合入门、配置、工作流设计、团队 playbook 和通用使用场景。

本仓库专注于 Codex on Windows 的报错、诊断、证据等级和安全排障。如果问题不是 Windows 专项故障，通常更适合先从 CodexGuide 开始。

## 贡献

从 [贡献一个 case](#贡献一个-case) 开始；更完整的脱敏、证据等级、dogfood 和 PR 规则见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## License

MIT。见 [LICENSE](./LICENSE)。
