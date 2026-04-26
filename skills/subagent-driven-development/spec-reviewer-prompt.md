# Spec 一致性 Reviewer Prompt 模板

当需要派发 spec 一致性 reviewer subagent 时，使用这个模板。

派发这个 reviewer 时，使用与当前 controller agent 相同的模型，并设置 `xhigh` 推理强度。
Controller 应在记录 verdict 后立即关闭这个 reviewer。
Controller 不应仅因 `wait_agent` 超时或 reviewer running 时间较长而关闭或重启它。
如果环境不支持设置推理强度，使用最接近的默认值，并明确说明这个限制。

**目的：** 验证实现者是否构建了被要求的内容，不多也不少

```
派发一个 fresh subagent，使用下面的 prompt：
  description: "审查任务 N 的 spec 一致性"
  prompt: |
    你正在审查某个实现是否符合它的规格说明。

    ## 已批准的 Spec 上下文

    - Spec 文件：[SPEC_FILE_PATH or parent/child spec paths]
    - Feature slice 标识：[FEATURE_SLICE_NAME or heading/ID]
    - 验收标准 IDs：[AC IDs]
    - 公共入口提示：[CLI/API/UI/config/file/event entrypoints]
    - 预期自动化验证：[test/smoke command or scenario]
    - 任务 worktree：[assigned task worktree path]

    ## Review 轮次

    - Review 类型：[initial full review | focused re-review]
    - 上一轮阻塞 verdict（focused re-review 时必填）：[prior reviewer verdict]
    - Fixer 报告（focused re-review 时必填）：[fixer report]
    - Git index 约定（focused re-review 时必填）：staged changes 是上一轮已审基线；unstaged changes 是本轮修复

    Initial full review 必须完整审查当前任务的 spec/AC、公共入口、真实任务 diff、相关测试和运行时语义要求。
    Focused re-review 默认只聚焦上一轮 blocker、unstaged 本轮修复以及这些改动触及的最终文件；不要从头重复完整审查。
    在任务 worktree 内运行 `git diff` 查看本轮修复，必要时运行 `git diff --staged` 理解上一轮已审基线。
    如果 focused re-review 时没有 unstaged changes，返回 ❌ Issues found，要求 controller 确认 fixer 是否实际修改或是否误操作了 stage。
    如果本轮修复触及公共入口、测试策略、核心数据流或大范围重写，返回 ❌ Issues found，并要求 controller 升级为完整 review。

    ## 规格定位

    直接读取上面的 spec 文件，定位指定 feature slice 和 AC IDs。
    如果你找不到对应 feature slice、AC IDs 或必要公共入口，返回 ❌ Issues found，并说明缺失的定位信息。

    ## 实现者声称自己完成了什么

    [From implementer's report]

    ## 关键要求：不要相信这份报告

    实现者完成得可疑地快。他的报告可能不完整、不准确，或者过于乐观。
    你必须独立验证一切。

    **不要：**
    - 直接相信他们说自己实现了什么
    - 相信他们对完整性的自我判断
    - 接受他们对需求的个人解读

    **要做：**
    - 阅读他们实际写出的代码
    - 逐行把真实实现与需求对照
    - 检查他们声称做了、但其实缺失的部分
    - 查找他们没提到的额外功能

    ## 你的任务

    阅读实现代码，并验证：

    **缺失的需求：**
    - 他们是否实现了所有被要求的内容？
    - 是否有任何需求被跳过或遗漏？
    - 是否有他们声称“能工作”，但实际上并没实现的部分？
    - 验收标准是否通过 spec 要求的公共入口被真正覆盖？

    **额外/不需要的工作：**
    - 他们是否实现了未被要求的内容？
    - 是否过度设计或增加了不必要功能？
    - 是否加入了 spec 里没有的 “nice to have”？
    - 是否实现了其他子 spec、其他 feature slice，或者任何只出现在 `Candidate Future Split Specs` 里的内容？

    **误解：**
    - 他们是否按错误方式理解了需求？
    - 他们是否解决了错误的问题？
    - 他们是否做了正确的功能，但实现方向错了？

    **TDD 证据：**
    - 实现者是否在实现前报告了 RED 失败命令和预期失败摘要？
    - 实现后是否报告了 GREEN 通过命令？
    - 如果针对生产代码或行为变更缺少 TDD 证据，要明确标记出来。

    **Trigger-driven workflow 的运行时语义（仅当 spec/AC 要求）：**
    - 按运行时语义 gate 验证公共 trigger 路径（CLI/API/UI/automation）是否接到真实执行组件，并产生任务要求的进展或终态信号。
    - 如果实现只满足响应/状态契约、通过手动改状态伪造迁移，或留下未经批准的占位语义，要标记出来。
    - 不要为 spec 没要求的 trigger 额外发明运行语义。

    **通过读代码来验证，而不是相信报告。**

    输出：
    - ✅ Spec compliant（如果代码检查后确认一切匹配）
    - ✅ Re-review passed（focused re-review 时：上一轮 blocker 已解决，且修复未引入新的阻塞问题）
    - ❌ Issues found: [具体列出缺失或多余的内容，并附 file:line 引用]
```
