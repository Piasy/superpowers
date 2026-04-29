# 单份 Spec 模板

当需求不需要拆成父子 spec 时，使用这个模板。
如果后续范围变化并拆成父子 spec，请同时遵循 [split-spec-conventions.md](./split-spec-conventions.md) 中的共享约定。

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

#### Shared Verification Baseline
- 主路径：[用真实公共入口串起的 boilerplate，例如 `init -> source add -> scan start -> serve`；如不适用则写明]
- 默认断言层级：[DOM/HTTP/DB/artifact 等观察层级；调试产物保留到 `.tmp/<topic>/`]
- 防 mock 逃逸禁令：[本 slice 内对所有 AC 都生效的禁令，例如不得直接写 SQL、不得跳过 HTTP 表单、不得伪造 cookie 或绕过真实执行路径]
- 如果包含 trigger-driven workflow，所有 AC 都必须覆盖公共 trigger 到真实执行路径，以及可观察的进展或终态信号。
- 测试必须能在只有脚手架、硬编码成功、直接状态修改或绕过真实执行路径的实现上失败。

#### AC-1: [短标题]
- 触发：[谁通过哪个公共入口做了什么操作]
- 必须可观察：[完整行为契约：状态变化、产物、UI/API 输出、错误反馈等]
- 验证手段：[测试类型（Playwright E2E / 服务级集成 / 单元等）、复用入口、关键断言点；不重述行为契约]
- 降级理由：[如果使用低于集成/E2E 的层级，说明为什么集成/E2E 不合理；主路径直接覆盖时省略本子项]

#### AC-2: [失败/边界场景短标题]
- 触发：[失败/边界场景的触发动作]
- 必须可观察：[失败/边界行为契约]
- 验证手段：[...]
- 降级理由：[可选]

### Done When
- 所有 Acceptance Criteria 都通过对应的"验证手段"完成自动化验证。
- 没有核心需求是通过直接状态修改、硬编码数据、占位行为或 fake integration 满足的。
```
