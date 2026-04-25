# Spec 文档 Reviewer Prompt 模板

当需要派发 spec 文档 reviewer subagent 时，使用这个模板。

**目的：** 验证 spec 是否验收驱动、完整、一致，并且已经准备好进入实现。

**派发时机：** spec 文档已经写入 `docs/superpowers/specs/` 之后。

**派发约束：** 使用与当前 controller agent 相同的模型；推理强度使用 `xhigh`/`max`（当前环境支持的最高档）。如果环境不支持，使用最接近的默认值，并在 verdict 中注明。

```
派发一个 fresh subagent，使用下面的 prompt：
  description: "Review spec document"
  prompt: |
    你是 spec 文档 reviewer。请验证这份 spec 是否完整、验收驱动，并且已经准备好进入实现。

    **要 review 的 spec：** [SPEC_FILE_PATH]
    请直接读取这个 spec 文件。

    ## 检查内容

    | 类别 | 要检查什么 |
    |------|------------|
    | 完整性 | TODO、占位符、"TBD"、未完成章节 |
    | 一致性 | 内部矛盾、相互冲突的需求 |
    | 清晰度 | 是否存在足以导致实现者做错的歧义 |
    | 验收 | 每个 feature slice 是否有具体验收标准，且每条 AC 是否映射到自动化验证 |
    | CI 验证 | 验证是否优先通过公共入口的集成/E2E 测试，并且能在 CI 中运行；更低层级替代方案是否有理由 |
    | 公共接口 | 用户可见行为、API、UI 状态、CLI 命令、文件格式或其他公共入口是否明确 |
    | 失败覆盖 | 重要错误状态、非法输入、边界场景是否已说明 |
    | Mock 逃逸抗性 | 验收是否无法被 stub、硬编码响应、no-op、fake integration 或直接状态修改满足 |
    | 范围 | 是否聚焦到一次可独立 review、实现和验收的工作，而不是覆盖多个独立子系统 |
    | 拆分信号 | 是否命中强拆分信号：独立用户目标过多、公共入口过多、跨模块过多、验收矩阵过复杂、风险过高、预计改动过大，或单个 spec 超过约 500 行 |
    | 拆分追踪 | 如果拆成多个子 spec，父 spec 是否用 `Split Specs` 追踪已写出子 spec，是否用 `Candidate Future Split Specs` 列未来候选，且子 spec 文件名是否继承父 spec 前缀 |
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

    ## 父子 Spec 规则

    如果需求被拆成多个子 spec，父 spec 必须保留，并用于追踪整体目标、拆分边界、已写出子 spec 链接和子 spec 进度。
    每次只写一个当前子 spec。父 spec 的 `Split Specs` 章节只列已经写出的子 spec；其中每个子 spec 都必须有实现进度 checkbox 状态，例如 `- [ ] Implementation status: Not done`。
    父 spec 的 `Candidate Future Split Specs` 章节列后续可能需要写的候选子 spec；候选项不加 checkbox，因为它们还不是已写出的可追踪子 spec。
    子 spec 文件名必须继承父 spec 前缀：父 spec 为 `YYYY-MM-DD-<topic>-spec.md` 时，子 spec 必须命名为 `YYYY-MM-DD-<topic>-<slice>-spec.md`。
    不要批准换日期、换 topic 前缀、无关联命名、已写出子 spec 缺少实现进度 checkbox，或候选未来子 spec 带 checkbox 的拆分方案。

    ## 验证标准

    每条验收标准都应该映射到一个自动化验证用例。
    优先使用通过公共入口执行、且能在 CI 中运行的集成测试或端到端测试。
    如果某条 AC 使用了更低层级测试，spec 必须解释为什么集成/E2E 覆盖不合理，以及为什么这个替代方案仍然足以证明行为。

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

    **Issues (if any):**
    - [Section X]: [具体问题] - [为什么它会影响实现]

    **Acceptance Coverage:**
    - [说明每个 feature slice 是否都有公共行为、验收标准，以及映射到 AC 的自动化验证]

    **CI Verification:**
    - [说明验证是否在合理情况下使用了通过公共入口的 CI-runnable 集成/E2E 测试，以及替代方案是否有理由]

    **Scope and Split Assessment:**
    - [说明 spec 是否足够小；是否命中拆分信号；如果超过约 500 行，说明是否应拆分；如果已拆分，说明 `Split Specs`、`Candidate Future Split Specs`、checkbox 使用和子 spec 命名是否正确]

    **Mock-Escape Assessment:**
    - [说明 fake/stub/no-op/direct-state 路径是否可能满足 spec，以及在哪里]

    **Recommendations (advisory, do not block approval):**
    - [改进建议]
```

**Reviewer 返回：** Status、Issues（如果有）、Acceptance Coverage、CI Verification、Scope and Split Assessment、Mock-Escape Assessment、Recommendations。
