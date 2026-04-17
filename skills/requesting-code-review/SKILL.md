---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch one code-reviewer reviewer agent/subagent to review one concrete change set before issues cascade. In environments with named plugin agents, that reviewer may be `superpowers:code-reviewer`. In environments without named agent dispatch, instantiate an equivalent reviewer from this skill's local `code-reviewer.md` template. Keep the review scoped to the actual diff and requirements.

**Core principle:** One focused reviewable unit + explicit diff/spec context + immediate findings handling = useful reviews.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## Review Scope

- Review one task branch/worktree, one feature diff, or one ad-hoc git range at a time.
- Give the reviewer only the diff and requirements for that unit.
- If 2 unrelated units need review, dispatch separate reviewers instead of mixing them into one review request.
- If you cannot summarize the review target in 1-2 sentences, narrow or split it first.

## Agent Naming

- `superpowers:requesting-code-review` is this skill.
- `superpowers:code-reviewer` refers to a reviewer agent type on platforms that support named plugin agents.
- `code-reviewer.md` in this skill directory is the local reviewer prompt template used to create an equivalent reviewer subagent when named agents are unavailable.

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Gather review context:**

- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_REFERENCE}` - What it should do
- `{DESCRIPTION}` - Brief summary of the scoped change set

**3. Dispatch one code-reviewer reviewer agent/subagent:**

Choose the environment-appropriate dispatch method:

- If the environment supports named plugin agents, use Task tool with `superpowers:code-reviewer`.
- Otherwise fill the local reviewer prompt template at `code-reviewer.md` and spawn an equivalent reviewer subagent.

Use the same model as the current controller agent and `xhigh` reasoning for every reviewer dispatch unless your human partner explicitly asks otherwise.

**Template placeholders:**
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_REFERENCE}` - What it should do
- `{DESCRIPTION}` - Brief summary

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)
- Once the controller has recorded the findings or handed them back to the implementer, release that reviewer immediately. In Codex, call `close_agent`.

## Workflow Boundary

- `superpowers:using-git-worktrees` owns task worktree and task branch lifecycle.
- `superpowers:subagent-driven-development` owns task-scoped review timing, parallel review scheduling, fix/re-review loops, and fresh-reviewer re-review.
- This skill owns reviewer dispatch context, the reviewer template, and how findings are categorized and consumed.
- Workflow-specific wrappers may add extra review-stage checks, but they should reuse this skill's dispatch contract instead of redefining it.

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer reviewer agent/subagent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_REFERENCE: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

[Controller records feedback and closes reviewer]
You: [Fix progress indicators]
[If another pass is needed, dispatch a fresh reviewer with the updated diff]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Use this skill's reviewer template and findings handling
- Let `subagent-driven-development` decide when review happens and how re-review loops run
- Let `using-git-worktrees` own task branch/task worktree isolation

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Send a reviewer vague or mixed scope
- Ask one reviewer to evaluate multiple unrelated diffs at once
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Keep a reviewer open after its verdict has been consumed
- Argue with valid technical feedback
- Treat this skill as the owner of task orchestration, worktree lifecycle, or re-review scheduling

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See local reviewer template at: requesting-code-review/code-reviewer.md
