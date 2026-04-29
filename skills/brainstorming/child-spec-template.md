# 子 Spec 模板

当需求已经拆成父子 spec，且当前轮次要写一个已批准子 spec 时，使用这个模板。
在填写本模板前，先遵循 [split-spec-conventions.md](./split-spec-conventions.md) 中的拆分追踪、命名、相对链接和 `Global Constraints` 继承规则。

```markdown
# [Feature Name] Spec

## Parent Spec
- Parent Spec: [YYYY-MM-DD-<topic>-spec.md](./YYYY-MM-DD-<topic>-spec.md)
- Current Approval Scope: [说明这个子 spec 在父 spec 当前批准范围中的角色]
- Sibling Specs: [已写出的 sibling spec 链接；如果暂无则写明暂无，未来候选仍以父 spec 为准]

## Global Constraints
- Shared constraints: 继承父 spec 的共享约束，见 [YYYY-MM-DD-<topic>-spec.md](./YYYY-MM-DD-<topic>-spec.md) 的 `Global Constraints`。
- [仅写本子 spec 独有的额外约束；如果没有，可以写“无额外约束”]

## Feature Slice 1: [用户可见能力]

- [ ] Implementation status: Not done

### Behavior
- [用户能做什么或观察到什么]

### Public Interface
- [CLI/API/UI/config/file/event 入口和契约]

### Error and Boundary Cases
- [失败模式和边界场景]

### Non-goals
- [明确不在范围内的行为]

### Acceptance Criteria

#### Shared Verification Baseline
- [同单份 spec 模板结构]

#### AC-1: [短标题]
- 触发：[...]
- 必须可观察：[...]
- 验证手段：[...]
- 降级理由：[可选]

### Done When
- 所有 Acceptance Criteria 都通过对应的"验证手段"完成自动化验证。
- 没有核心需求是通过直接状态修改、硬编码数据、占位行为或 fake integration 满足的。
```
