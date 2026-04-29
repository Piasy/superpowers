# 父 Spec 模板

当需求已经拆成多个子 spec，需要一个追踪整体边界和进度的父 spec 时，使用这个模板。
在填写本模板前，先遵循 [split-spec-conventions.md](./split-spec-conventions.md) 中的拆分追踪、命名、相对链接和 `Global Constraints` 继承规则。

```markdown
# [Feature Name] Spec

## Goal
[一句话描述整体用户可见结果]

## Global Constraints
- [所有子 spec 都适用的共享约束、兼容性、依赖限制]
- [只在父 spec 写一次；子 spec 通过相对链接引用这里，不要重复拷贝]
- 核心行为必须通过公共入口验证；mock/stub/no-op 路径不得满足验收。

## Split Specs

### [Slice Name]

- [ ] Implementation status: Not done
- Spec: [YYYY-MM-DD-<topic>-slice-x-<slice name>-spec.md](./YYYY-MM-DD-<topic>-slice-x-<slice name>-spec.md)
- Scope: [这个子 spec 负责的用户目标/公共入口/风险边界]
- Acceptance summary: [这个子 spec 完成后能被独立验收的结果]

## Candidate Future Split Specs

- [Candidate slice name]: [为什么可能需要拆成独立子 spec]
- [Candidate slice name]: [触发它进入 Split Specs 的条件]
```
