# LittlePower

> If you don't read Chinese, ask your agent to read for you :)

这是一组面向 vibe coding/spec driven development 的 coding agent skills，no superpower, only little power.

最初起源于 https://github.com/obra/superpowers ，针对 Piasy 的个人使用需求做了深度调整，大家按需取用。

我用 superpowers 面临的主要问题：

1. plan 太细，追求「clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow」，太细就必然导致太长，太长人就没法 review 了，不然还不如自己去古法编程了；
2. 我实践下来，即便是 Claude Code + Opus 4.6 或 Codex + gpt 5.4 都没法把 plan 写到这个程度，结果就是 agent 按照 plan 做出来的就是💩：能通过 spec/code quality review、test case 都能过、“功能/接口“都有，但没有实现任何实际功能，就是一大坨💩；
3. 我试过改进 superpowers（历史提交记录可以看到），推倒重来多次，结果每次都还是一大坨💩；

吸取了一些其他人分享的实践后，我去掉了 plan 环节，只保留「验收驱动的 spec」，清晰准确定义好功能和验收方式（验收方式也是需求/设计的一部分），如何根据 spec 做实现，放权给 agent。

除了 spec driven 的方式，这里也直接把 https://github.com/forrestchang/andrej-karpathy-skills 引入为 `karpathy-vibe`，作为纯 vibe coding 的指导 skill。_其实这里面的思想，superpowers 里也都有借鉴体现。_

## 仓库定位

- 目标：提供一组面向 coding agent 的通用工程 skills
- 使用方式：按任务需要显式使用具体 skill，不再依赖全局入口 skill
- 安装时不需要先手动 clone 仓库

LittlePower 现在主要支持两种工作流：

1. **纯 vibe coding**：人负责判断方向、验收和 review，agent 直接按你的要求改。
2. **spec + subagent driven**：当改动较大、风险较高，或者你不想自己承担验收和 review 时，先形成 approved spec，再让 subagents 在隔离 worktree 中实现、审查、修复和集成。

## 工作流一：纯 vibe coding

适合小改动、探索性修改、临时脚本、你愿意自己验收、读 diff 和 review 的场景。

典型用法：

```text
$karpathy-vibe <任务描述>
```

在这个模式下，不需要启动完整 spec 流程。你可以让 agent 直接改代码、跑必要验证，然后把 diff 和验证结果交给你判断。

仍然可以按需点名使用这些 skills：

- `test-driven-development`：希望这次改动先写失败测试、再实现时使用。
- `systematic-debugging`：遇到 bug、测试失败或异常行为时，用它先查根因，避免随机修补。
- `receiving-code-review`：当你或其他 reviewer 给出反馈，且反馈不清楚或技术上可疑时，用它先判断再修改。

这个模式的优势：

- 启动成本低，适合快节奏试错。
- 人保留 review 主导权，不把小问题流程化。
- 仍可在关键节点点名 TDD 或系统化调试，避免纯靠感觉改坏代码。

## 工作流二：spec + subagent driven

适合较大功能、跨模块改动、行为边界复杂、需要强 review，或者你不想自己完整 review agent 改动的场景。

推荐流程：

1. 用 `brainstorming` 把想法整理成验收驱动的 approved spec。
2. 用 `subagent-driven-development` 按 spec 中的 feature slice 顺序执行实现。

subagent-driven-development 会：
1. 每个任务由 implementer 以 TDD 实现，并经过两阶段 review：
   - spec 一致性 review：检查有没有少做、多做或误解需求。
   - code-quality review：检查真实 diff、最终代码、测试质量、维护性和运行时风险。
2. review 发现阻塞问题时，同一个任务 worktree 中修复，再派 fresh reviewer 复审。
3. 任务通过后立即集成回 controller 分支、更新 spec status、清理任务 worktree。
4. 如果本轮连续集成多个子 spec，再做 controller 分支收尾验证。

典型用法：

```text
$brainstorming <你的任何想法、设计、要求，不用多么严谨>
```

如果需求范围较大，brainstorming 会写成一组父子 spec，这个过程也会消耗很多上下文，如果你觉得上下文用多了/效果不太行了，可以在完成一个子 spec 之后，就 clear 上下文/启动新会话，.tmp 目录下会有交接文档，你用 brainstorming 时告诉 agent 就好：

```text
$brainstorming docs/superpowers/specs/xxxx-spec.md 写了我的需求 spec 的一部分了，.tmp/brainstorming-handoff-xxxx.md 是上一轮 spec 编写完之后的交接文档，你继续写剩余的子 spec
```

spec 都写完之后：

```text
$subagent-driven-development 实现 docs/superpowers/specs/xxxx-spec.md 里的 slice D
```

_你也可以明确让 agent 一次性实现多个，但不建议，至少 codex + gpt 模型，context compact 之后，效果会明显下降。_

这个模式的优势：

- approved spec 是事实来源，agent 不靠零散聊天记录猜需求。
- 每个任务有独立 worktree，减少并行/回滚/污染主工作区的风险。
- implementer、spec reviewer、code-quality reviewer 分工明确，减少“自己写自己批准”的问题。
- reviewer 必须看真实 diff 和最终代码，不能只相信实现者摘要。
- 阻塞问题进入 fix / fresh re-review 循环，不带问题继续推进。
- spec status、任务 commit 和 worktree 清理形成可追踪的交付轨迹。

## 当前 Skills

- `karpathy-vibe`：用 Karpathy 风格的行为约束来做 vibe coding，以减少 LLM 编码常见失误，强调先澄清、保持简单、外科式改动和可验证成功标准。
- `brainstorming`：把功能、组件、行为变更整理成验收驱动 spec，并在用户批准后结束。
- `subagent-driven-development`：基于 approved spec，使用任务级 subagents、隔离 worktree、两阶段 review 和 fix/re-review 循环完成实现。
- `using-git-worktrees`：为需要隔离的功能开发或 approved spec 实现准备 controller 分支、任务 worktree、基线验证和清理规则。
- `test-driven-development`：要求先写 RED 测试、确认失败，再写最小实现并确认 GREEN。
- `systematic-debugging`：遇到 bug、测试失败或异常行为时，先定位根因，再决定修复。
- `receiving-code-review`：处理 code review 反馈时先做技术判断，避免盲目接受不清楚或错误的建议。
- `writing-skills`：创建、修改或验证 skills 时使用，把 skill 文档当成需要测试的行为约束。

当前列表以 `skills/` 目录中可扫描到的 `SKILL.md` 为准。

## 安装命令

- 全量安装：`npx skills add Piasy/LittlePower -g -y`
- 单 skill 安装：`npx skills add Piasy/LittlePower -s subagent-driven-development -g -y`
- 本地安装（开发调试）：`npx skills add . -g -y`
- 列出可安装 skill：`npx skills add Piasy/LittlePower -g -y --list`

## 工作方式

skills 工具会拉取 source repository 并扫描其中的 `SKILL.md`。运行时入口位于各 skill 目录内部。

安装后，按具体任务点名 skill 即可，例如：

```text
use brainstorming
```

```text
use subagent-driven-development
```

不同 agent/harness 对 skills 的自动发现和触发支持不完全一致；最稳定的方式是直接在请求里写明要使用的 skill。

## 运行前提

- `git`
- 支持 Agent Skills 的 coding agent 或兼容工具
- 若使用 `subagent-driven-development`，当前环境需要支持 subagent 派发
- 若使用 `using-git-worktrees` / `subagent-driven-development`，项目需要能使用 Git worktree
- 若要求 TDD 或自动验证，项目需要有可运行的测试命令

## 取舍

纯 vibe coding 的核心是速度和人类判断；spec + subagent driven 的核心是可审查、可追踪、可复验。

如果只是小改动，直接 vibe coding 更合适。

如果你需要 agent 自己承担实现后的严肃审查，或者改动大到靠人肉 review 成本太高，就走 spec + subagent driven。

## License

本仓库使用 MIT License。
