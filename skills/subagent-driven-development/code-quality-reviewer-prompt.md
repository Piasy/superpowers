# 代码质量 Reviewer Prompt 模板

当在 `subagent-driven-development` 里派发代码质量 review 阶段时，使用这个模板。

**目的：** 在 `requesting-code-review` 定义的标准 code-reviewer 基础上，补充代码质量专项检查。

**只在 spec 一致性 review 通过之后派发。**

使用 `requesting-code-review` 的标准 code-reviewer 派发契约：
- 与当前 controller agent 使用相同模型
- 使用 `xhigh` 推理强度
- 如果环境不支持设置推理强度，使用最接近的默认值，并明确说明这个限制
- verdict 记录后遵循相同的 reviewer 关闭规则
- 使用相同的占位符和标准输出格式

在这个阶段，标准占位符映射如下：
- `WHAT_WAS_IMPLEMENTED` - 实现者对当前任务的报告
- `SPEC_REFERENCE` - `[spec file] / [feature slice] / [AC IDs]`
- `BASE_SHA` - 当前任务变更集之前的 commit
- `HEAD_SHA` - 当前任务的 head
- `DESCRIPTION` - 任务摘要

**除了标准代码质量关注项外，reviewer 还应检查：**
- 每个文件是否只有一个清晰职责，并暴露定义明确的接口？
- 模块划分是否足够清楚，以便独立理解和测试？
- 实现是否与 spec 以及现有文件结构保持一致？
- 这次实现是否新建了已经偏大的文件，或显著扩大了已有文件？（不要对历史遗留的大文件报问题，只关注这次变更新增的部分。）
- 报告里是否包含了针对生产代码或行为变更的 TDD RED/GREEN 证据？
- 测试验证的是 spec 定义的公共行为，而不是私有实现细节吗？
- 如果 spec/AC 要求 trigger-driven workflow，外部入口是否真的调用执行路径，并通过测试或 smoke check 观察到要求的进展或终态？
- 如适用，是否避免了 status-only 实现、直接改持久化状态伪造迁移，或未经任务明确批准的占位式执行逃逸？

**Code reviewer 返回：** `requesting-code-review` 的标准输出格式：Strengths、Issues（Critical/Important/Minor）、Assessment
