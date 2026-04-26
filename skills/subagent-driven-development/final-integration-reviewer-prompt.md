# 收尾验证 Subagent Prompt 模板

当 `subagent-driven-development` 进入 `controller` 开发分支收尾阶段，需要派发一个 fresh 收尾验证 subagent 时，使用这个模板。

派发这个 subagent 时，使用与当前 controller agent 相同的模型，并设置当前环境支持的最高推理强度（通常为 `xhigh`/`max`）。
Controller 应在记录 verdict 后立即关闭这个 subagent。
Controller 不应仅因 `wait_agent` 超时或 subagent running 时间较长而关闭或重启它。
如果环境不支持设置推理强度，使用最接近的默认值，并明确说明这个限制。

**目的：** 用一个 subagent 完成 `controller` 开发分支收尾验证：首次执行完整测试、关键运行时 smoke check、最终全量实现 review；修复后执行 focused re-review。

**这不是任务级 review 的替代品。**
每个任务的 spec review 和 code-quality review 仍然必须先完成。
这个 subagent 关注的是：**整体集成后** 是否仍然成立，而不是重复复述单个任务的结论。

**这也是完整测试和 smoke check 的执行者。**
不要让 controller 自己执行这些验证，也不要为第 1、2、3 步分别派发不同 subagent，除非当前收尾验证 subagent 已经关闭后需要重新验证。

**发现问题时：** 返回 `Issues Found` verdict；不要自行修复。Controller 会关闭你，并派发新的 `xhigh` 收尾修复 subagent 在 `controller` 开发分支修复；修复后再派发新的 fresh 收尾验证 subagent。首次收尾验证使用 `initial full review`；修复后的验证默认使用 `focused re-review`。

```
派发一个 fresh subagent，使用下面的 prompt：
  description: "验证 controller 分支收尾"
  prompt: |
    你正在验证 controller 开发分支 worktree 上的最终全量实现。

    ## 关键职责

    这是一次整体收尾 gate。
    不要把它降级成普通 diff review，也不要把单个任务已经通过 review 当作整体无问题的证明。
    如果本轮要求执行的测试或 smoke check 发现阻塞问题，返回 Issues Found，不要继续最终全量实现 review。
    对于因前置步骤失败而未执行的后续输出项，明确标记 `Not run` 并说明被哪个步骤阻塞。

    ## Review 轮次

    - Review 类型：[REVIEW_PASS_TYPE: initial full review | focused re-review]
    - Controller worktree：[WORKTREE_PATH]
    - 上一轮收尾 verdict（focused re-review 时必填）：[PRIOR_COMPLETION_VERDICT]
    - 收尾 fixer 报告（focused re-review 时必填）：[FINAL_FIXER_REPORT]
    - Git index 约定（focused re-review 时必填）：[GIT_INDEX_PROTOCOL: staged changes 是上一轮已审基线；unstaged changes 是本轮收尾修复]

    Initial full review 必须执行下面第 1、2、3 步的完整收尾验证。
    Focused re-review 默认只聚焦上一轮收尾 blocker、unstaged 本轮修复、必要测试/smoke 复验，以及这些修复触及的整体集成风险；不要从头重复完整收尾 review。
    在 controller worktree 内运行 `git diff` 查看本轮收尾修复，必要时运行 `git diff --staged` 理解上一轮已审基线。
    如果 focused re-review 时没有 unstaged changes，返回 Issues Found，要求 controller 确认 fixer 是否实际修改或是否误操作了 stage。
    如果本轮修复触及公共入口、测试策略、核心数据流或跨任务集成风险，返回 Issues Found，并要求 controller 改派 `initial full review` 模式重新完整收尾验证。

    ## 执行步骤

    **第 1 步：验证测试**
    在 `controller` 开发分支 worktree 上验证测试通过，并报告实际命令、退出码、失败数量和关键失败内容。Initial full review 时，使用 `VERIFICATION_EXPECTATIONS` 中的完整项目命令；未提供时按项目惯例选择，例如：

    ```bash
    npm test / cargo test / pytest / go test ./...
    ```

    如果测试失败，返回 Issues Found。不要自行修复。Focused re-review 时，至少重跑上一轮失败的测试命令、修复直接相关的测试命令，以及任何因本轮修复可能受影响的完整测试命令；如果无法判断哪些命令足够，要求升级为 `initial full review`。

    **第 2 步：验证关键运行时路径**
    对 spec/AC 要求的每个关键 trigger-driven workflow，按运行时语义 gate 至少跑一次公共入口 smoke check。没有这类 workflow 时，明确报告跳过原因；如果 smoke check 暴露出“只有状态变化，没有真实执行”，返回 Issues Found。Focused re-review 时，至少重跑上一轮失败的 smoke check 和本轮修复触及的 smoke check；如果修复可能影响其他关键入口，要求升级为 `initial full review`。

    **第 3 步：最终全量实现 Review**
    把 `controller` 开发分支当前 worktree 当作整体检查。Focused re-review 时，把 unstaged 修复和其触及文件的最终状态作为主要审查对象，并确认上一轮未受影响的收尾结论仍可沿用：
    - 所有标记为 `Implementation status: Done` 的 feature slice 都确实已实现。
    - 没有误实现 `Implementation status: Not done` 的 feature slice、其他子 spec 或 `Candidate Future Split Specs` 条目。
    - 公共入口、验收标准、自动化验证和运行时语义在完整测试与 smoke check 通过后依然成立。
    - 跨任务交互没有引入冲突、重复行为或范围漂移。

    如果发现问题，返回 Issues Found；如果是 spec 不完整，要求 controller 回到 `brainstorming`。最终 review 通过前，不得继续第 4 步。

    **第 4 步：形成完成 verdict**
    只有本轮要求执行的第 1、2、3 步都通过，才能返回 Approved。返回 verdict 后等待 controller 记录并关闭你；不要自行决定或执行后续分支处置。

    ## 已批准的 Spec 范围

    - Spec reference: [SPEC_REFERENCE]
    - Implemented slices (`Implementation status: Done`): [IMPLEMENTED_SLICES]
    - Must remain unimplemented: [OUT_OF_SCOPE_SLICES]
    - Critical public entrypoints / workflows: [CRITICAL_ENTRYPOINTS]
    - Verification commands and smoke checks you must run: [VERIFICATION_EXPECTATIONS]

    直接读取 `SPEC_REFERENCE` 指向的 spec 文件，确认 `IMPLEMENTED_SLICES`、`OUT_OF_SCOPE_SLICES`、关键公共入口和验证预期与 spec 真实状态一致。如果你找不到 spec 文件、对应 slice、AC 或必要公共入口，返回 Issues Found，并说明缺失的定位信息。

    ## 整体实现摘要

    [DESCRIPTION]

    ## Git 查看范围

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]

    Initial full review 时，审查本轮已集成结果：

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    Focused re-review 时，审查当前 worktree 中的收尾修复和已审基线：

    ```bash
    git diff --stat
    git diff
    git diff --staged --stat
    git diff --staged
    ```

    ## 关键要求：不要相信摘要或先前结论

    不要因为：
    - 每个任务都“单独通过过 review”
    - controller 说“现在已经全部集成了”
    - 某个任务之前被标记为 Done

    就默认整体结果正确。

    你必须直接阅读当前 worktree 中的最终代码，并把整体结果与已批准 spec 对照。Focused re-review 时，当前最终代码包含 unstaged 收尾修复。

    ## 你的检查项

    **1. Done Slice Coverage（已完成范围覆盖）**
    - 每个已标记 `Implementation status: Done` 的 slice，是否都真实存在于当前集成结果中？
    - 对应 AC 是否仍然能通过 spec 要求的公共入口被满足？
    - 集成后是否出现某个 slice 局部存在、但整体路径不再打通的情况？

    **2. Out-of-Scope Guard（越界防护）**
    - 是否有任何仍为 `Implementation status: Not done` 的 slice 被误实现？
    - 是否误实现了其他子 spec？
    - 是否误实现了 `Candidate Future Split Specs` 中的内容？
    - 是否因为多个任务拼接在一起，出现了未经批准的新行为、额外分支、或 scope creep？

    **3. Cross-Task Integration（跨任务整合）**
    - 各任务合并后是否存在冲突、重复逻辑、分叉实现、或互相覆盖？
    - 是否出现两个不同代码路径同时声称处理同一入口/状态/产物？
    - 配置、状态流、依赖 wiring、命名或接口是否在任务之间不一致？
    - 某个任务的实现是否破坏了另一任务已经满足的 AC？

    **4. Public Entrypoints + Runtime Semantics（公共入口与运行时语义）**
    - 关键公共入口在集成后是否仍然符合 spec/AC；对 trigger-driven workflow，是否按运行时语义 gate 保持真实执行，而不是被集成过程削成 status-only 行为？
    - 是否存在生产路径中的占位执行逃逸（例如 `"stub runner"`、`"real implementation later"`、`"minimum placeholder"`），导致整体行为看似完成、实则未完成？

    **5. Verification Integrity（验证完整性）**
    - 集成后的测试结构是否仍然验证公共行为，而不是变成只验证局部实现细节？
    - 是否有 slice 在单任务内有测试，但整体集成后测试映射已经失真？
    - 完整项目测试套件是否通过？报告实际命令、退出码、失败数量和关键失败内容。

    **6. Runtime Smoke Checks（运行时 smoke check）**
    - 对 spec/AC 要求的每个关键 trigger-driven workflow，按运行时语义 gate 至少跑一次公共入口 smoke check。
    - 如果没有这类 workflow，明确报告跳过原因。
    - 如果 smoke check 暴露出“只有状态变化，没有真实执行”，返回 Issues Found。

    ## 校准标准

    只报告会阻塞“报告 controller 开发分支已完成收尾验证”的真实问题。

    以下都属于阻塞问题：
    - 已标 Done 的 slice 事实上没完成
    - 未标 Done 的 slice / 子 spec / 候选未来 spec 被误实现
    - 公共入口被接错，或真实执行语义在集成后丢失
    - 跨任务集成导致冲突、重复行为、范围漂移或行为回退

    轻微风格问题、命名偏好、与最终收尾无关的小优化，不是这一步的重点。

    ## 输出格式

    ## Controller Branch Completion Verification

    **Status:** Approved | Issues Found
    **Review Pass:** Initial full review | Focused re-review

    **Full Test Verification:**
    - [实际命令、退出码、通过/失败结果；失败时列出失败数量和关键失败内容；focused re-review 时说明重跑了哪些命令、哪些前序结果仍沿用以及为什么]

    **Smoke Check Verification:**
    - [每个关键 trigger-driven workflow 的 smoke check 结果，或明确跳过原因；focused re-review 时说明重跑了哪些 smoke check、哪些前序结果仍沿用以及为什么]

    **Done Slice Coverage:**
    - [说明已标 Done 的 slice 是否都真实落地；若有缺口，指出具体 slice]

    **Out-of-Scope Audit:**
    - [说明未完成 slice / 子 spec / Candidate Future Split Specs 是否保持未实现]

    **Integration Findings:**
    - [说明是否存在跨任务冲突、重复行为、状态分叉、接口错位或范围漂移]

    **Runtime Semantics Findings:**
    - [说明关键公共入口和 trigger-driven workflow 在集成后是否仍保持真实执行语义]

    **Issues (if any):**
    - [file:line] [具体问题] - [为什么这会阻塞完成]

    **Assessment:**
    - [说明 controller 是否可以报告完成；如果不能，指出应派发收尾修复 subagent、重新打开哪个任务，或回到 brainstorming]
```

**Subagent 返回：** `Status`、`Review Pass`、`Full Test Verification`、`Smoke Check Verification`、`Done Slice Coverage`、`Out-of-Scope Audit`、`Integration Findings`、`Runtime Semantics Findings`、`Issues`、`Assessment`。
