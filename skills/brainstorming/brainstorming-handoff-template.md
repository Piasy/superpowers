# Brainstorming 交接模板

当需求已经拆成父子 spec，且当前轮次写完或修订完一个子 spec 并通过单份 review 后，使用这个交接模板。

```markdown
# Brainstorming 交接：[Topic]

## 当前进展
- 父 spec：[YYYY-MM-DD-<topic>-spec.md](../docs/LittlePower/specs/YYYY-MM-DD-<topic>-spec.md)
- 已写子 spec：
  - [YYYY-MM-DD-<topic>-slice-x-<slice name>-spec.md](../docs/LittlePower/specs/YYYY-MM-DD-<topic>-slice-x-<slice name>-spec.md) — 单份 review：Approved；用户确认：未确认
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
  - [YYYY-MM-DD-<topic>-spec.md](../docs/LittlePower/specs/YYYY-MM-DD-<topic>-spec.md)
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
