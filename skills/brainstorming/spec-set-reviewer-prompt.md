# Spec Set Reviewer Prompt 模板

当父 spec 和所有已写出的子 spec 都已经分别通过单份 spec reviewer 后，使用这个模板派发整体 spec set reviewer subagent。

**目的：** 验证父 spec 与所有子 spec 作为一个整体是否一致、完整、可理解，并且已经准备好交给用户最终 review。

**派发时机：** 父 spec 和所有已写出的子 spec 都通过 `spec-document-reviewer-prompt.md` 后、用户 review 全部 spec 之前。首次整体 review 使用 `initial full review`；修订上一轮跨文档 blocker 后的整体 re-review 默认使用 `focused re-review`。

**派发约束：** 使用与当前 controller agent 相同的模型；推理强度使用 `xhigh`/`max`（当前环境支持的最高档）。如果环境不支持，使用最接近的默认值，并在 verdict 中注明。

```
派发一个 fresh subagent，使用下面的 prompt：
  description: "Review full spec set"
  prompt: |
    你是 spec set reviewer。请整体审查父 spec 和所有已写出的子 spec 是否一致、完整，并且已经准备好交给用户最终 review。

    **父 spec：** [PARENT_SPEC_FILE_PATH]
    **目标项目仓库：** [REPO_PATH]

    **子 spec 列表：**
    - [CHILD_SPEC_FILE_PATH]
    - [CHILD_SPEC_FILE_PATH]

    请直接读取父 spec 和每个子 spec 文件。
    如果需求被拆成多个子 spec，请同时读取 `skills/brainstorming/split-spec-conventions.md`，并按其中的拆分追踪、命名规则、链接规则和 `Global Constraints` 继承规则审查整组 spec。

    ## Review 轮次

    只选择下面一种模式填写。

    ### 模式 A：Initial full review
    - Review 类型：initial full review
    - 文档状态：controller 直接把当前父 spec 和全部子 spec 交给你做完整整体审查。

    ### 模式 B：Focused re-review
    - Review 类型：focused re-review
    - 上一轮整体阻塞 verdict：[PRIOR_SET_BLOCKER_VERDICT]
    - 修订摘要：[REVISION_REPORT]
    - Git index 状态：controller 已在上一轮 verdict 后固定已审 baseline；staged changes 是上一轮已审基线；unstaged changes 是本轮 spec set 修订

    Initial full review 必须完整审查父 spec 和所有子 spec 的整体关系。
    Focused re-review 默认只判断上一轮跨文档 blocker 是否解决、本轮 unstaged 修订是否引入新的跨文档阻塞问题、以及被修订文档的最终内容是否仍与整组 spec 一致。不要从头重复完整整体审查。
    Focused re-review 时，在目标项目仓库内运行 `git diff` 查看本轮修订，必要时运行 `git diff --staged` 理解上一轮已审基线。
    如果 focused re-review 时没有 unstaged changes，返回 Issues Found，要求 controller 确认是否实际修改或是否误操作了 stage。
    如果本轮修订改变拆分边界、增删子 spec、改变父 spec 交付地图、改变共享 `Global Constraints` 继承方式，或大范围重写父/子 spec，返回 Issues Found，并要求 controller 升级为 `initial full review`。

    ## 检查内容

    | 类别 | 要检查什么 |
    |------|------------|
    | 父子一致性 | 父 spec 的目标、拆分边界、scope summary、acceptance summary 是否与子 spec 内容一致 |
    | 覆盖完整性 | 所有已写子 spec 合起来是否覆盖父 spec 的当前交付目标 |
    | 漏洞 | 是否存在父 spec 声明的目标没有对应子 spec，或应该写出但仍留在 `Candidate Future Split Specs` 的项 |
    | 重叠冲突 | 子 spec 之间是否有重复范围、相互矛盾的行为、冲突的公共接口或不兼容的验收标准 |
    | 边界清晰度 | 每个子 spec 的边界是否清楚，是否能被独立 review、独立实现、独立验收 |
    | 命名与追踪 | 子 spec 文件名是否继承父 spec 前缀；父 spec 的 `Split Specs` 是否列出所有已写子 spec 并带 `Implementation status` checkbox；`Candidate Future Split Specs` 是否不带 checkbox |
    | 链接与路径 | 父 spec 指向子 spec、子 spec 回指父 spec 的引用是否都是 markdown 链接，且使用相对当前文档位置可解析的相对路径 |
    | 共享约束继承 | 共享 `Global Constraints` 是否在父 spec 收敛；子 spec 是否只通过相对链接引用共享约束并补充本子 spec 的增量约束，而不是重复抄写 |
    | 用户可 review 性 | 整组 spec 是否形成清晰的交付地图，用户能否理解已经写了什么、还候选什么、每个子 spec 负责什么 |
    | 范围漂移 | 子 spec 是否引入父 spec 没声明的额外目标、公共入口或风险边界 |

    ## 校准标准

    **只指出跨文档层面的真实问题。**
    单份 spec 内部的验收标准、CI 验证、mock 逃逸等问题应该已由单份 spec reviewer 处理；只有当这些问题体现为父子不一致、跨 spec 漏洞、冲突或范围漂移时才指出。

    不要因为措辞风格、章节顺序或非阻塞性表达偏好提出问题。

    ## 必须阻塞的问题

    以下任一情况都是问题：
    - 父 spec 的 `Split Specs` 漏掉已写出的子 spec
    - 已写子 spec 没有在父 spec 中用 `Implementation status` checkbox 追踪
    - `Candidate Future Split Specs` 中有 checkbox
    - 子 spec 文件名没有继承父 spec 前缀
    - 父 spec 到子 spec、或子 spec 到父 spec 的引用不是相对路径 markdown 链接
    - 共享 `Global Constraints` 没有在父 spec 收敛，导致 child spec 大段重复共享约束且没有明确引用父 spec
    - 子 spec 之间范围重叠到会导致实现冲突或重复验收
    - 父 spec 的当前交付目标没有被任何子 spec 覆盖
    - 子 spec 引入父 spec 未声明且用户未批准的范围
    - 用户无法从父 spec 理解每个子 spec 的职责和当前进度

    ## 输出格式

    ## Spec Set Review

    **Status:** Approved | Issues Found
    **Review Pass:** Initial full review | Focused re-review

    **Issues (if any):**
    - [Parent/Child spec reference]: [具体问题] - [为什么它会影响整体 spec 交付地图]

    **Coverage Assessment:**
    - [说明子 spec 合起来是否覆盖父 spec 当前交付目标]

    **Consistency Assessment:**
    - [说明父子 spec、子 spec 之间是否一致]

    **Tracking Assessment:**
    - [说明 `Split Specs`、`Candidate Future Split Specs`、`Implementation status` checkbox、父子 markdown 相对链接、共享 `Global Constraints` 继承方式和文件命名是否正确]

    **Recommendations (advisory, do not block approval):**
    - [改进建议]
```

**Reviewer 返回：** Status、Review Pass、Issues（如果有）、Coverage Assessment、Consistency Assessment、Tracking Assessment、Recommendations。
