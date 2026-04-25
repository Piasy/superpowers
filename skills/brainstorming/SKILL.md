---
name: brainstorming
description: Use when creating features, building components, adding functionality, or modifying behavior before implementation
---

# 把想法梳理成验收驱动的 Spec

通过自然、协作式对话，帮助把想法变成验收驱动的 spec。

先理解当前项目上下文，再一次只问一个问题来澄清需求。当你已经理解要交付什么、以及如何验证它时，向用户展示 spec 并获得批准。

## 硬性门禁

- **禁止：** 在 spec 获得用户批准前，调用任何实现类 skill、写代码、搭建项目脚手架，或采取任何实现动作。
- **禁止：** 在父子 spec 场景中一次性写完多个剩余子 spec。每轮只允许编写或修订一个当前子 spec；其他候选子 spec 留在父 spec 的 `Candidate Future Split Specs` 中，等待后续轮次处理。
- **适用范围：** 所有项目，无论看起来多简单。
- **恢复规则：** review 或用户反馈要求回退时，先判断反馈影响的是产品语义、范围拆分、当前 spec 内容，还是已写出的多份 spec 文档。回到能解决问题的最早必要阶段，不要无条件重跑整条流程。

## 反模式：“这个太简单了，不需要 Spec”

每个项目都要走这个流程。待办列表、单函数工具、配置改动——都一样。“简单”项目最容易因为未经检查的假设造成返工。spec 可以很短，但必须说明用户可见行为或公共接口会发生什么变化，以及如何验证完成。

## Checklist

你必须为以下每一项创建任务，并按顺序完成：

1. **探索项目上下文** — 检查文件、文档、近期提交
2. **提供视觉辅助**（如果接下来会涉及视觉问题）— 这必须是单独一条消息，不能和澄清问题混在一起。见下方“视觉辅助”章节
3. **提出澄清问题** — 一次只问一个问题，理解目标、约束、成功标准
4. **识别范围和工作量** — 判断是否需要拆成多个更小的验收驱动 spec
5. **定义验收证据** — 识别公共入口、可观察行为、失败模式、自动化验证
6. **提出 2-3 种方案** — 说明权衡，并给出你的推荐
7. **展示验收驱动的 spec** — 按复杂度分章节展示，每个章节都获取用户确认
8. **写入 spec 文档** — 保存到 `docs/superpowers/specs/YYYY-MM-DD-<topic>-spec.md`
9. **Subagent review spec** — 必须启动同模型、最高推理强度的 reviewer subagent，使用 `spec-document-reviewer-prompt.md` 审查 spec
10. **更新交接文档**（如果拆分成父子 spec）— 每写完或修订一个子 spec 后，更新 `./.tmp/brainstorming-handoff-YYYY-MM-DD-<topic>.md`
11. **Subagent review spec set**（如果拆分成父子 spec）— 父 spec 和所有子 spec 都通过单份 review 后，必须启动整体 reviewer subagent 审查整组 spec；未拆分的单份 spec 跳过此步骤
12. **用户 review 全部 spec** — 请用户 review 已写好的 spec；用户批准后，brainstorming 结束

## 流程图

```mermaid
flowchart TD
    A[探索项目上下文] --> B{接下来有视觉问题？}
    B -- 是 --> C["提供视觉辅助<br/>(单独消息，不含其他内容)"]
    B -- 否 --> D[澄清并判断影响范围]
    C --> D
    D -- 范围/拆分变化 --> E[确定范围与拆分策略]
    D -- 当前 spec 变化 --> F[梳理当前 spec<br/>范围、验收证据、2-3 种方案]
    D -- 已写文档修订 --> M[修订受影响的 spec 文档<br/>并重跑单份 review]
    E --> F[梳理当前 spec<br/>范围、验收证据、2-3 种方案]
    F --> G{用户批准当前 spec？}
    G -- 需澄清 --> D
    G -- 需修订 --> F
    G -- 批准 --> H[写入当前 spec 文档<br/>并单份 review]
    H --> J{单份 review 通过？}
    J -- 需澄清 --> D
    J -- 需修订 --> F
    J -- 通过，还有子 spec --> P[更新交接文档]
    P --> F
    J -- 全部通过，已拆分 --> P2[更新交接文档]
    P2 --> K[同步父 spec 并整体 review]
    J -- 全部通过，未拆分 --> N
    K --> L{整体 review 通过？}
    L -- 拆分/覆盖问题 --> E
    L -- 文档一致性问题 --> M[修订受影响的 spec 文档<br/>并重跑单份 review]
    M --> P2
    L -- 通过 --> N{用户 review 全部 spec？}
    N -- 产品修改 --> D
    N -- 文档修订 --> M
    N -- 批准 --> O(((Brainstorming 结束)))
```

**终态是一个或多个已批准的验收驱动 spec。** 用户批准全部 spec 后，brainstorming 结束。如果需求范围过大、风险过高或验收矩阵过复杂，继续把需求拆成多个更小的验收驱动子 spec，要求每个子 spec 能被独立 review、独立实现、独立验收。未拆分的单份 spec 通过单份 subagent review 后进入用户 review；拆分后的父 spec 和所有子 spec 都必须通过单份 subagent review，整组 spec 也必须通过整体 subagent review。

## 流程细节

**理解想法：**

- 先检查当前项目状态（文件、文档、近期提交）
- 在深入提问前先评估范围：如果请求包含多个独立子系统（例如“做一个包含聊天、文件存储、计费和分析的平台”），立刻指出需要先拆分。不要把时间花在澄清一个本应先拆分的大项目细节上。
- 如果项目太大，无法放进单个 spec，帮助用户拆成子项目：哪些部分相互独立、它们如何关联、应该按什么顺序梳理。父 spec 只追踪整体目标和子 spec 进度；每个子项目都有自己的验收驱动子 spec。
- 对范围合适的项目，一次只问一个问题来澄清想法
- 优先使用多选问题；开放问题也可以
- 每条消息只问一个问题。如果一个主题需要继续深入，就拆成多个问题
- 重点理解：目标、约束、用户可见行为、公共接口、失败模式、非目标、成功标准
- 从 review gate 或用户 review 回到澄清阶段时，澄清后必须判断影响范围：如果改变目标、公共入口、风险边界或拆分方式，回到范围与拆分；如果只影响当前 spec，回到当前 spec 的范围、验收证据或方案；如果只影响已写文档表述，定位并修订受影响的 spec 文档。

**识别范围和工作量：**

- brainstorming 负责把需求切到可实现、可验收、可 review 的粒度。如果一个 spec 不能被一个 agent 在一次正常实现会话中完整理解、实现并通过验收验证，它就太大了，必须拆分。
- 任一信号命中时，优先考虑拆成多个 spec：包含 3 个以上独立用户目标；任一 slice 可以独立上线或独立验收；同时涉及 CLI、API、UI、配置、文件格式、事件协议等多个公共入口；涉及新持久化模型、迁移、权限、生命周期状态机、后台任务；预计影响 4 个以上主要模块/包；需要理解多个互不相邻的子系统；关键 AC 超过约 8-12 条；涉及数据迁移、兼容性破坏、用户数据、计费、安全、权限或外部集成；粗略预计新增/修改超过约 1-2k 行；可能演变成上万行新增代码。
- **Spec 长度信号：** 如果单个 spec 超过约 500 行，把它视为强拆分信号。优先寻找独立用户目标、公共入口、数据生命周期阶段或风险边界，将其拆成多个更小的验收驱动 spec。
- 只有当一个超过 500 行的 spec 仍然是单一内聚交付物，且长度主要来自必要的验收矩阵或接口示例，而不是实现步骤时，才保留它。
- 常见拆分维度：按用户 journey 拆；按公共入口拆；按数据生命周期拆；按风险边界拆；按可独立验收的 feature slice 拆。
- 拆分后保留父 spec。每次只写一个当前子 spec；禁止为了“省事”或“顺手”一次性写完所有剩余子 spec。父 spec 的 `Split Specs` 章节只列已经写出的子 spec，并为每个子 spec 添加实现进度 checkbox，例如 `- [ ] Implementation status: Not done`。
- 父 spec 的 `Candidate Future Split Specs` 章节列后续可能需要写的候选子 spec。候选项不加 checkbox，因为它们还不是已写出的可追踪子 spec。
- 子 spec 文件名必须继承父 spec 前缀：父 spec 使用 `docs/superpowers/specs/YYYY-MM-DD-<topic>-spec.md`；子 spec 使用 `docs/superpowers/specs/YYYY-MM-DD-<topic>-<slice>-spec.md`。不要为子 spec 换日期、换 topic 前缀或使用无关联命名。

**定义验收证据：**

- spec 是唯一持久化事实来源。它负责产品语义；不要把这些语义留给后续实现过程去发明。
- 找出行为被触发或观察到的每一种公共方式：CLI 命令、API endpoint、UI 流程、文件格式、配置项、事件、日志、持久化产物，或其他外部契约。
- 对每个 feature slice，定义尽可能通过公共入口执行的自动化验证。优先使用可在 CI 中运行的集成测试或端到端测试，并观察真实产物、状态变化、UI/API 输出或错误反馈，而不是断言内部实现细节。
- 每条验收标准都应该映射到一个自动化验证用例。如果用集成测试或端到端测试覆盖不合理，说明替代自动化检查方式，以及为什么它足够。
- 包含重要失败场景和边界场景。如果 feature slice 只描述 happy path，它就是不完整的。
- 写清非目标和边界，避免 agent 扩大范围或用臆造行为填补空白。
- 明确 mock/stub 边界。只有在不可避免时，才允许 fake 外部服务；核心行为不得通过 mock 逻辑、no-op 路径、硬编码 fixture 或直接状态修改来满足。

**探索方案：**

- 提出 2-3 种不同方案，并说明权衡
- 用对话方式展示选项，给出你的推荐和理由
- 先给推荐方案，再解释为什么

**展示 spec：**

- 当你已经理解要构建什么、以及如何验证它时，展示 spec
- 根据复杂度调整对话展示时的每个章节长度：简单问题几句话即可，复杂问题最多约 200-300 字；最终写入文档的 spec 可以更详细
- 每展示一个章节，都询问用户目前看起来是否正确
- 覆盖：feature slices、公共接口/UI、可观察行为、状态变化、错误处理、非目标、自动化验收
- 如果有内容不清楚，随时回到澄清阶段。澄清后按影响范围恢复：范围或拆分变化回到“识别范围和工作量”；当前 spec 内容变化回到“定义验收证据”或“探索方案”；纯文字修订回到对应 spec 文档修订。

**Spec 结构：**

除非用户要求其他格式，否则使用这个结构：

```markdown
# [Feature Name] Spec

## Goal
[一句话描述用户可见结果]

## Global Constraints
- [仓库/产品约束、兼容性、依赖限制]
- 核心行为必须通过公共入口验证；mock/stub/no-op 路径不得满足验收。

## Feature Slice 1: [用户可见能力]

- [ ] Implementation status: Not done

### Behavior
- [用户能做什么或观察到什么]
- [状态变化、输出、产物或副作用]

### Public Interface
- [CLI/API/UI/config/file/event 入口和契约]

### Error and Boundary Cases
- [失败模式和要求的用户/API 反馈]
- [重要限制、空状态、权限问题、非法输入等]

### Non-goals
- [明确不在范围内的行为]

### Acceptance Criteria
- AC-1: [必须成立的可观察行为]
- AC-2: [必须成立的失败/边界行为]
- 如果包含 trigger-driven workflow，AC 必须覆盖公共 trigger 到真实执行路径，以及可观察的进展或终态信号。

### Automated Verification
- [集成/E2E 测试类型、路径或命令；如果未知，写精确的 CI-runnable 验证场景]
- 每条 AC 至少映射到一个自动化测试用例。
- 测试必须执行 [public entrypoint] 并观察 [artifact/state/output]。
- 如果某条 AC 无法合理用集成/E2E 测试覆盖，说明更低层级的自动化验证方式，以及为什么它足够。
- 测试必须能在只有脚手架、硬编码成功、直接状态修改或绕过真实执行路径的实现上失败。

### Done When
- 所有验收标准都通过自动化验证。
- 没有核心需求是通过直接状态修改、硬编码数据、占位行为或 fake integration 满足的。
```

Feature slice 是后续实现阶段的进度检查点。checkbox 对应这个 slice 的验收已通过，而不是 brainstorming 阶段完成、创建文件、编写 helper、运行命令之类的实现杂项。

如果需求被拆成多个子 spec，父 spec 使用这个结构追踪整体进度：

```markdown
# [Feature Name] Spec

## Goal
[一句话描述整体用户可见结果]

## Split Specs

### [Slice Name]

- [ ] Implementation status: Not done
- Spec: `docs/superpowers/specs/YYYY-MM-DD-<topic>-<slice>-spec.md`
- Scope: [这个子 spec 负责的用户目标/公共入口/风险边界]
- Acceptance summary: [这个子 spec 完成后能被独立验收的结果]

## Candidate Future Split Specs

- [Candidate slice name]: [为什么可能需要拆成独立子 spec]
- [Candidate slice name]: [触发它进入 Split Specs 的条件]
```

父 spec 只负责说明整体目标、拆分边界、已写出子 spec 的链接和进度，以及未来候选拆分。具体行为、验收标准和自动化验证写在对应子 spec 中。`Candidate Future Split Specs` 不使用 checkbox；只有子 spec 实际写出后，才把它移动到 `Split Specs` 并添加状态 checkbox。

**父子 Spec 交接文档：**

如果需求被拆成父子 spec，每写完或修订一个子 spec 并通过单份 review 后，必须更新交接文档：

- 路径使用 `./.tmp/brainstorming-handoff-YYYY-MM-DD-<topic>.md`
- 如果交接文档不存在，自行创建并写入当前交接内容
- 交接文档使用中文编写
- 交接文档只记录后续 agent 恢复工作所需事实，不重复完整 spec 内容
- 交接文档不替代父 spec 的 `Split Specs` 和 `Candidate Future Split Specs`；候选子 spec 信息仍以父 spec 为准
- 未拆分的单份 spec 不需要交接文档

使用这个结构：

```markdown
# Brainstorming 交接：[Topic]

## 当前进展
- 父 spec：`docs/superpowers/specs/YYYY-MM-DD-<topic>-spec.md`
- 已写子 spec：
  - `docs/superpowers/specs/YYYY-MM-DD-<topic>-<slice>-spec.md` — 单份 review：Approved；用户确认：未确认
- 整体 review：未开始 / Approved / Issues Found
- 用户 review：未开始 / 已批准 / 需修改

## 下一步计划
- 下一步要写的子 spec：`[slice name]`
- 选择它作为下一步的原因：
- 开始前是否必须先问用户：是 / 否
- 如果需要提问，优先问这一题：

## 已确认决策
- [用户已经确认的产品语义、范围边界、非目标、公共入口或命名约定]
- [不要在新对话中重新发明或推翻，除非用户明确修改]

## 后续子 spec 所需信息
- 必读 spec：
  - `docs/superpowers/specs/YYYY-MM-DD-<topic>-spec.md`
- 必读代码或文档：
  - `[path]` — [为什么需要读]
- 必须保留的约束：
  - [兼容性、依赖限制、公共入口、验收证据、mock/stub 边界]

## 未决问题
- 问题：
  - 阻塞什么：
  - 为什么必须先澄清：

## Reviewer 备注
- 最近一次单份 review：Approved / Issues Found
- 最近一次整体 review：未开始 / Approved / Issues Found
- 已修复的问题：
- 仍需注意的问题：

## 恢复指令
新的 agent 对话应先读取本交接文档、父 spec 和所有已写子 spec。只继续编写“下一步计划”中的一个子 spec；禁止一次性写完所有剩余子 spec。不要重写已批准内容；只有用户反馈或 reviewer issues 要求时，才修订既有 spec。
```

**隔离性和清晰性设计：**

- 把系统拆成更小的单元：每个单元都有清晰职责，通过明确接口通信，并且能被独立理解和测试
- 对每个单元都应该能回答：它做什么、如何使用它、它依赖什么
- 不读内部实现，别人能理解一个单元做什么吗？能在不破坏调用方的情况下替换内部实现吗？如果不能，边界就需要调整
- 小而边界清晰的单元也更便于 agent 工作：你能更好地在上下文中理解代码；当文件变得很大时，通常说明它承担了太多职责

**在现有代码库中工作：**

- 提出改动前，先探索当前结构。遵循现有模式。
- 如果现有代码的问题会影响当前工作（例如文件过大、边界不清、职责纠缠），把有针对性的改进写进 spec 约束或 feature slice 中——这就是优秀开发者在修改相关代码时会做的事。
- 不要提出无关重构。只做服务于当前目标的改动。

## 设计之后

**文档：**

- 把已验证的 spec 写入 `docs/superpowers/specs/YYYY-MM-DD-<topic>-spec.md`
  - 用户偏好的 spec 路径优先于这个默认路径
- 如果拆成多个子 spec，父 spec 保持 `YYYY-MM-DD-<topic>-spec.md`；当前已写出的子 spec 使用 `YYYY-MM-DD-<topic>-<slice>-spec.md`，并在父 spec 的 `Split Specs` 中用 `Implementation status` checkbox 追踪状态；未来候选子 spec 放在 `Candidate Future Split Specs`，不加 checkbox
- 不要自动提交 spec 文档；用户决定是否提交

**Spec Review Gate：**
写完单份或多份关联 spec 文档后，必须启动一个 reviewer subagent 审查已写好的 spec：

- **强制启动：** 必须启动 subagent；不要因为任何默认“不启动 subagent”的原则而跳过。
- **模型要求：** reviewer subagent 必须使用与当前 agent 相同的模型。
- **推理强度：** reviewer subagent 必须使用当前环境支持的最高推理强度（例如 `xhigh`、`max` 或等价设置）；如果环境不支持设置推理强度，使用可用默认值并说明。
- **Prompt：** 使用 `skills/brainstorming/spec-document-reviewer-prompt.md`，并传入实际 spec 文件路径。
- **职责：** reviewer 只审查 spec 是否验收驱动、范围合适、可独立 review/实现/验收、CI 验收充分、且没有 mock/stub/no-op 逃逸路径；不要让 reviewer 重写 spec。
- **处理结果：** 如果 reviewer 返回 Issues Found，按问题类型恢复流程：产品语义不清时回到澄清；范围过大或边界错误时回到范围与拆分；验收证据、方案、公共接口或文档表述有问题时修订当前 spec，并再次启动新的 reviewer subagent。只有 reviewer 返回 Approved 后，当前 spec 才能进入后续整体 review。

**Spec Set Review Gate（仅限拆分后的父子 spec）：**
父 spec 和所有已写出的子 spec 都分别通过单份 Subagent Review Gate 后，必须启动一个整体 reviewer subagent 审查整组 spec：

- **强制启动：** 必须启动 subagent；不要因为任何默认“不启动 subagent”的原则而跳过。
- **模型要求：** 整体 reviewer subagent 必须使用与当前 agent 相同的模型。
- **推理强度：** 整体 reviewer subagent 必须使用当前环境支持的最高推理强度（例如 `xhigh`、`max` 或等价设置）；如果环境不支持设置推理强度，使用可用默认值并说明。
- **Prompt：** 使用 `skills/brainstorming/spec-set-reviewer-prompt.md`，并传入父 spec 路径和所有已写出的子 spec 路径。
- **职责：** reviewer 只审查父子 spec 的整体一致性、覆盖完整性、拆分追踪、命名规则、跨 spec 冲突和范围漂移；不要让 reviewer 重写 spec。
- **处理结果：** 如果整体 reviewer 返回 Issues Found，修订相关 spec；被修订的单份 spec 必须重新通过单份 reviewer，然后再次启动新的整体 reviewer subagent。只有整体 reviewer 返回 Approved 后，才能进入用户 Review Gate。

**用户 Review Gate：**
未拆分的单份 spec 通过单份 review 后，请用户 review 该 spec。拆分后的父 spec 和所有子 spec 都通过单份 review，且整组 spec 通过整体 review 后，请用户 review 全部已写好的 spec：

> "Spec 已写入。请 review 父 spec 和所有子 spec；如果你希望修改，请告诉我。"

等待用户回复。如果用户要求修改，先定位反馈影响哪些 spec 文档，再修订所有受影响的 spec。任何 spec 文档被修改后，该文档必须重新通过单份 reviewer；如果父子集合受影响，整组 spec 也必须重新通过整体 reviewer。未拆分 spec 在单份 reviewer 再次 Approved 且用户批准后结束；拆分 spec 只有整体 reviewer 再次 Approved 且用户批准后，brainstorming 才能结束。

**结束：**

- 用户批准 spec 后，brainstorming 到此结束。
- 如果用户批准后又发现缺少产品决策，回到 spec 继续澄清和修订。

## 核心原则

- **一次只问一个问题** — 不要同时抛出多个问题压倒用户
- **优先多选** — 多选通常比开放问题更容易回答
- **严格 YAGNI** — 从 spec 中移除不必要功能
- **探索替代方案** — 确定方案前，始终提出 2-3 种选择
- **增量验证** — 展示 spec 章节，获得批准后再继续
- **验收驱动范围** — 只有可观察行为和验证证据都明确后，功能才算被定义清楚
- **Spec 拥有语义** — 不要把产品/API/UI 行为决策推迟到实现阶段
- **保持灵活** — 有不清楚的地方就回头澄清

## 视觉辅助

浏览器版视觉辅助可用于在 brainstorming 期间展示 mockup、图表和视觉选项。它是一个工具，不是一种模式。用户接受视觉辅助，只表示后续遇到适合视觉表达的问题时可以使用；不表示每个问题都要通过浏览器处理。

**提供视觉辅助：** 当你预期接下来会涉及视觉内容（mockup、布局、图表）时，只询问一次用户是否同意：
> "接下来有些内容可能用浏览器展示会更容易理解。我可以在过程中做 mockup、图表、对比图和其他视觉材料。这个功能还比较新，也可能消耗较多 token。要试试吗？（需要打开一个本地 URL）"

**这必须是一条独立消息。** 不要把它和澄清问题、上下文总结或其他内容合并。这条消息只能包含上面的邀请语，不能有其他内容。等待用户回复后再继续。如果用户拒绝，就继续用纯文本 brainstorming。

**逐问题判断：** 即使用户同意使用视觉辅助，也要对每一个问题单独判断应该使用浏览器还是终端。判断标准是：**用户看到它会不会比读文字更容易理解？**

- **使用浏览器**：内容本身是视觉性的——mockup、wireframe、布局对比、架构图、并排视觉设计
- **使用终端**：内容本身是文本性的——需求问题、概念选择、权衡列表、A/B/C/D 文本选项、范围决策

关于 UI 的问题不一定就是视觉问题。“这里的 personality 是什么意思？”是概念问题，使用终端。“哪种 wizard 布局更好？”是视觉问题，使用浏览器。

如果用户同意视觉辅助，在继续前阅读详细指南：
`skills/brainstorming/visual-companion.md`
