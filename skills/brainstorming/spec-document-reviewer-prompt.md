# Spec 文档 Reviewer Prompt 模板

当需要派发 spec 文档 reviewer subagent 时，使用这个模板。

**目的：** 验证 spec 是否验收驱动、完整、一致，并且已经准备好进入实现。

**派发时机：** spec 文档已经写入 `docs/LittlePower/specs/` 之后。首次 review 使用 `initial full review`；修订上一轮 blocker 后的 re-review 默认使用 `focused re-review`。

**派发约束：** 使用与当前 controller agent 相同的模型；推理强度使用 `xhigh`/`max`（当前环境支持的最高档）。如果环境不支持，使用最接近的默认值，并在 verdict 中注明。

```
派发一个 fresh subagent，使用下面的 prompt：
  description: "Review spec document"
  prompt: |
    你是 spec 文档 reviewer。请验证这份 spec 是否完整、验收驱动，并且已经准备好进入实现。

    **要 review 的 spec：** [SPEC_FILE_PATH]
    **目标项目仓库：** [REPO_PATH]
    请直接读取这个 spec 文件。

    ## Review 轮次

    只选择下面一种模式填写。

    ### 模式 A：Initial full review
    - Review 类型：initial full review
    - 文档状态：controller 直接把当前 spec 文件交给你做完整审查。

    ### 模式 B：Focused re-review
    - Review 类型：focused re-review
    - 上一轮阻塞 verdict：[PRIOR_BLOCKER_VERDICT]
    - 修订摘要：[REVISION_REPORT]
    - Git index 状态：controller 已在上一轮 verdict 后固定已审 baseline；staged changes 是上一轮已审基线；unstaged changes 是本轮 spec 修订

    Initial full review 必须完整审查下面所有检查项。
    Focused re-review 默认只判断上一轮 blocker 是否解决、本轮 unstaged 修订是否引入新的阻塞问题、以及被修订章节的最终内容是否仍与 spec 整体一致。不要从头重复完整审查。
    Focused re-review 时，在目标项目仓库内运行 `git diff` 查看本轮修订，必要时运行 `git diff --staged` 理解上一轮已审基线。
    如果 focused re-review 时没有 unstaged changes，返回 Issues Found，要求 controller 确认是否实际修改或是否误操作了 stage。
    如果本轮修订改变了产品目标、拆分边界、公共入口、验收策略、核心失败模式，或大范围重写 spec，返回 Issues Found，并要求 controller 升级为 `initial full review`。

    ## 检查内容

    | 类别 | 要检查什么 |
    |------|------------|
    | 完整性 | TODO、占位符、"TBD"、未完成章节 |
    | 一致性 | 内部矛盾、相互冲突的需求 |
    | 清晰度 | 是否存在足以导致实现者做错的歧义 |
    | 验收（行为 + 验证） | 每个 feature slice 的 `Acceptance Criteria` 章节是否作为验收信息的唯一载体，同时覆盖行为契约和验证手段：每条 AC 是否包含"触发 / 必须可观察 / 验证手段"三项，且必要时给出"降级理由"；验证手段是否优先使用通过公共入口、CI-runnable 的集成/E2E 测试 |
    | 共享测试基线 | 是否存在 `Shared Verification Baseline` 子段，抽出 slice 通用的主路径 boilerplate、默认断言层级、防 mock 逃逸禁令、调试产物落盘约定 |
    | 不重复原则 | AC 内部的"验证手段"是否避免重述行为契约或与 `Shared Verification Baseline` 重复；行为契约是否完整写在"必须可观察"，而不是被推到"验证手段"里 |
    | 公共接口 | 用户可见行为、API、UI 状态、CLI 命令、文件格式或其他公共入口是否明确 |
    | 失败覆盖 | 重要错误状态、非法输入、边界场景是否已说明 |
    | Mock 逃逸抗性 | 验收是否无法被 stub、硬编码响应、no-op、fake integration 或直接状态修改满足 |
    | 范围 | 是否聚焦到一次可独立 review、实现和验收的工作，而不是覆盖多个独立子系统 |
    | 拆分信号 | 是否命中强拆分信号：独立用户目标过多、公共入口过多、跨模块过多、验收矩阵过复杂、风险过高、预计改动过大，或单个 spec 超过约 500 行 |
    | 拆分追踪 | 如果拆成多个子 spec，父 spec 是否用 `Split Specs` 追踪已写出子 spec，是否用 `Candidate Future Split Specs` 列未来候选，且子 spec 文件名是否继承父 spec 前缀 |
    | 链接与路径 | 父子 spec 的互相引用是否使用 markdown 链接，且链接目标使用相对当前文档位置可解析的相对路径，而不是纯文本路径 |
    | 共享约束继承 | 如果拆成多个子 spec，共享 `Global Constraints` 是否只保留在父 spec；子 spec 是否通过相对链接引用父 spec 的共享约束，并只写本子 spec 的增量约束 |
    | YAGNI | 是否包含未要求的功能或过度设计 |

    ## 校准标准

    **只指出会在实现期间造成真实问题的事项。**
    缺失章节、矛盾、足以产生两种解释的需求、或者会让假实现通过的验收缺口，都是问题。
    轻微措辞改进、风格偏好、以及“某些章节不如其他章节详细”不是问题。

    只有当 spec 明确说明要交付什么，以及 CI 可运行的自动化证据如何证明它时，才能批准。
    不要批准依赖后续实现计划来发明产品/API/UI 行为的 spec。

    ## 范围与拆分标准

    spec 必须足够小，能被独立 review、独立实现、独立验收。
    如果它包含多个可独立上线或独立验收的用户目标、同时涉及多个公共入口、跨越多个主要模块/包、关键 AC 超过约 8-12 条、涉及迁移/权限/安全/计费/外部集成等高风险边界，或粗略预计新增/修改超过约 1-2k 行，通常应该拆分。
    如果单个 spec 超过约 500 行，把它视为强拆分信号。只有当它仍然是单一内聚交付物，且长度主要来自必要验收矩阵或接口示例，而不是实现步骤时，才可以保留。

    ## 父子 Spec 共享约定

    如果需求被拆成多个子 spec，请同时读取 `skills/brainstorming/split-spec-conventions.md`，并按其中的拆分追踪、命名规则、链接规则和 `Global Constraints` 继承规则审查。
    不要批准任何违反该共享约定的拆分方案。

    ## 验收章节结构标准

    `Acceptance Criteria` 是 feature slice 中承载验收行为契约和验证手段的唯一章节，需同时覆盖二者。
    章节应包含一个 `Shared Verification Baseline` 子段，抽出 slice 通用的主路径、默认断言层级、防 mock 逃逸禁令、调试产物落盘约定，避免每条 AC 各自重述。
    每条 AC 必须有"触发"、"必须可观察"、"验证手段"三项；如果使用低于集成/E2E 的层级，还需"降级理由"子项说明为什么集成/E2E 不合理，以及为什么替代方案仍然足以证明行为。
    每条 AC 的"必须可观察"必须完整覆盖行为契约（状态变化、产物、UI/API 输出、错误反馈），不得为节省篇幅缩水；"验证手段"只补充测试技术细节，不重述行为契约。
    优先使用通过公共入口执行、且能在 CI 中运行的集成测试或端到端测试。

    ## Mock 逃逸测试

    假设实现者会选择最容易的路径。请自问：
    - 他们能否只用脚手架、stub、硬编码数据或 no-op 就勾选 feature slice？
    - 测试能否通过直接修改内部状态，而不是使用公共入口？
    - 测试能否在没有经过用户/API 调用方依赖的真实执行路径时通过？
    - 契约层面的成功是否会掩盖缺失的运行时行为或用户可见效果？

    任何这类漏洞都是问题。

    ## 输出格式

    ## Spec Review

    **Status:** Approved | Issues Found
    **Review Pass:** Initial full review | Focused re-review

    **Issues (if any):**
    - [Section X]: [具体问题] - [为什么它会影响实现]

    **Acceptance Coverage (行为 + 验证):**
    - [说明每个 feature slice 的 `Acceptance Criteria` 章节是否作为验收信息的唯一载体，同时覆盖行为契约（"必须可观察"）和验证手段；是否包含 `Shared Verification Baseline` 子段；是否避免在 AC 内重述 baseline；是否在合理情况下使用通过公共入口的 CI-runnable 集成/E2E 测试，更低层级方案是否有"降级理由"]

    **Scope and Split Assessment:**
    - [说明 spec 是否足够小；是否命中拆分信号；如果超过约 500 行，说明是否应拆分；如果已拆分，说明 `Split Specs`、`Candidate Future Split Specs`、checkbox 使用、父子 markdown 相对链接和子 spec 命名是否正确；同时说明共享 `Global Constraints` 是否在父 spec 收敛、子 spec 是否只做引用和增量补充]

    **Mock-Escape Assessment:**
    - [说明 fake/stub/no-op/direct-state 路径是否可能满足 spec，以及在哪里]

    **Recommendations (advisory, do not block approval):**
    - [改进建议]
```

**Reviewer 返回：** Status、Review Pass、Issues（如果有）、Acceptance Coverage（行为 + 验证）、Scope and Split Assessment、Mock-Escape Assessment、Recommendations。
