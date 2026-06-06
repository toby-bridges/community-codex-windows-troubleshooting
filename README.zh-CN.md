# Codex Windows 社区排障指南

这是一个社区维护的 Codex Windows 排障、事实核查和 dogfood 项目。

> 非官方项目。本仓库不隶属于 OpenAI，也不代表 OpenAI 认可、赞助或背书。OpenAI、Codex、ChatGPT 及相关标识属于 OpenAI。本项目只在描述兼容性和排障范围时使用这些名称，不使用 OpenAI logo 或品牌素材。见 [Branding and Naming](./BRANDING.md)。

## 一句话总结

这个 GitHub 项目可以帮助 Windows 上的 Codex 用户把常见报错定位到已核查的 GitHub issue 和安全排障步骤，从而少走弯路地恢复可用工作流。

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

## 推荐仓库名

推荐 GitHub 仓库名：

```text
community-codex-windows-troubleshooting
```

推荐公开标题：

```text
Community Codex Windows Troubleshooting Field Guide
```

原因：

- `codex windows troubleshooting` 是最直接的搜索意图。
- 仓库名用 `community` 表达社区维护，README 和 disclaimer 继续明确写非官方，降低用户误以为这是 OpenAI 官方项目的风险。
- `Field Guide` 保留研究和实践手册的质感。

## 贡献

见 [CONTRIBUTING.md](./CONTRIBUTING.md)。不要提交密钥、token、私有仓库名、包含个人信息的截图，或完整 `.codex` session 文件。

## License

MIT。见 [LICENSE](./LICENSE)。
