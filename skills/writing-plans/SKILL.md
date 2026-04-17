---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans by keeping the controller in coordination mode, dispatching one writer subagent to draft the plan, and running a fresh reviewer subagent after each draft until the plan is approved or the round cap is reached.

Assume implementers will have limited context and will take the easiest path available. The plan must make the correct implementation the easiest implementation. It must not leave room for mock logic, placeholder behavior, fake integrations, or "real implementation later" escapes.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Execution context:** Approved plans are executed with `superpowers:subagent-driven-development`. Task worktree creation, merge-back, and cleanup belong to `superpowers:using-git-worktrees`; reference those skills instead of redefining their mechanics here.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- User preferences for plan location override this default.

## Skill Boundaries

- This skill owns plan authoring workflow, task decomposition, dependency design, parallelism design, and the writer/reviewer iteration loop.
- `superpowers:subagent-driven-development` owns execution of an approved plan.
- `superpowers:using-git-worktrees` owns task worktree and task branch lifecycle.
- The controller coordinates and records verdicts.
- The writer subagent writes and revises the plan.
- The reviewer subagent reviews and returns findings; it does not directly rewrite the plan.

## Mandatory Workflow

1. The controller reads the approved spec and enough repo context to explain the problem, architecture constraints, and existing patterns.
2. The controller chooses the target plan path.
3. The controller dispatches one writer subagent using `./plan-writer-prompt.md` with the same model as the controller and `xhigh` reasoning.
4. The writer subagent saves the initial plan draft to the target path and reports back.
5. The controller dispatches one fresh reviewer subagent using `./plan-document-reviewer-prompt.md` with the same model as the controller and `xhigh` reasoning.
6. The reviewer returns blocking and/or non-blocking findings. The controller records the verdict and immediately closes that reviewer.
7. The controller sends the findings back to the same writer subagent, which revises the same plan file.
8. After each writer revision, the controller dispatches a fresh reviewer. Do not reuse reviewers across rounds.
9. Keep the writer subagent through the write/review/revise loop unless the workflow pauses for user input. Close it once the plan is approved or the workflow pauses.
10. If the writer reports `NEEDS_CONTEXT` or `BLOCKED` because the spec or repo context is insufficient, resolve that first. Do not let the writer invent requirements to keep the loop moving.

## Review Focus And Round Control

Every plan review must explicitly evaluate:

- Architecture design rationality
- Functional coverage completeness against the spec
- Task decomposition granularity
- Dependency order and parallel execution safety
- Internal consistency across tasks, files, names, types, and commands
- Whether an implementer could follow the plan literally and still ship mock, stub, hardcoded, or placeholder logic instead of the real requirement

Use two severity levels only:

- `Blocking`: A serious issue that would cause the wrong architecture, missing functionality, unsafe or incorrect parallel execution, contradictory implementation steps, or a loophole where the task could be "completed" with mock/placeholder behavior instead of the required real implementation.
- `Non-blocking`: A real improvement, but the plan can still be implemented correctly without it.

Round limits are cumulative for the entire plan:

- A round is one writer draft or revision followed by one reviewer verdict on that draft.
- Rounds `1-5`: Fix both `Blocking` and `Non-blocking` findings.
- Rounds `6-10`: Fix `Blocking` findings only. Record remaining `Non-blocking` findings as advisory and stop iterating on them unless they are trivially adjacent to a blocking fix.
- If a review after round `5` finds only `Non-blocking` issues and no `Blocking` issues, accept the plan and proceed.
- If `Blocking` issues remain after round `10`, stop the loop and discuss the unresolved blockers with the user before continuing.
- Do not interpret this as "5 rounds plus 10 more." There is one cumulative round counter per plan.

## Scope Check

If the spec covers multiple independent subsystems, it should already have been decomposed during brainstorming. If it was not, stop and suggest separate plans instead of producing one plan that mixes independent projects together.

Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Prefer smaller, focused files over files that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase already uses larger files, do not force unrelated restructuring, but it is reasonable to plan targeted splits when they are required for this work.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Size Budgets

Every task MUST include explicit scope budgets and stay within them.

- Maximum write scope: `20` files per task (create + modify + test combined)
- Maximum code delta budget: `1000` added lines per task (planned estimate, excluding generated artifacts)
- If a requirement cannot fit both budgets, split it into multiple dependent tasks
- Do not hide oversized work in vague follow-up language; split concretely with file ownership and dependency order

## Dependency And Parallelism Design

Define task dependencies explicitly so execution can run independent work in parallel safely.

- Every task MUST declare `Depends on` and use `None` when no prerequisite task is required.
- Tasks can run in parallel only when dependencies are satisfied and their write scopes are disjoint.
- No plan may assume more than `5` concurrent task lanes. If more than `5` tasks become ready together, the plan must queue them explicitly.
- Execution assigns one isolated task worktree per active code-changing task lane via `superpowers:using-git-worktrees`.
- If two tasks modify the same file, they are not independent and must be sequenced by dependency.
- Keep task boundaries explicit enough that an executor can schedule ready tasks without guessing.

## Explicit Parallelism Plan

Every plan MUST include an explicit parallelism section before task details.

- Add a `Parallel Execution Plan` section that groups tasks into waves such as `Wave A`, `Wave B`.
- For each wave, list exactly which tasks can run concurrently and why.
- For each wave, list blocked tasks and what dependency unlocks them.
- No wave may schedule more than `5` concurrent tasks.
- Include at least one parallelizable wave whenever the spec has independent workstreams.
- If no safe parallelism exists, state that explicitly and justify why every task must be sequential.

## Bite-Sized Task Granularity

Each checkbox step should be one concrete action that usually takes about `2-5` minutes.

- "Write the failing test" is one step
- "Run it to make sure it fails" is one step
- "Implement the minimal real behavior to make the test pass" is one step
- "Run the tests and make sure they pass" is one step
- A domain-specific finalization action that must happen after the last verified step can use `Task completion action`
- `Task completion action` is optional and must never be used for git commit creation

## Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. Executors run dependency-free tasks in parallel when safe (default max concurrency: `5`). All subagents use the controller's current model; implementers use `medium` reasoning and reviewers use `xhigh` reasoning. Execution tracking, checkbox ownership, `Task completion action` timing, and task completion commit behavior follow `superpowers:subagent-driven-development`. Task worktree assignment, merge-back, and cleanup follow `superpowers:using-git-worktrees`.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Depends on:** None | Task M[, Task K]

**Scope Budget:**
- Max files: 20
- Estimated files touched: N
- Max added lines: 1000
- Estimated added lines: N

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal real implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Task completion action (not a checkbox step, optional):**
- [Only include this block when the task genuinely needs a final domain-specific action after the last verified step and before the controller marks the task complete.]
- Do not use this block for `git commit`; `superpowers:subagent-driven-development` owns the task completion commit after review-approved integration.
````

## Execution Tracking Model

- Plan checkbox state is the persistent progress source of truth.
- `TodoWrite` is session-local execution tracking and must be rebuilt from plan checkbox state after restarts.
- Checkbox ownership, merge-based checkbox propagation, `Task completion action` timing, and task completion commit behavior follow `superpowers:subagent-driven-development`.
- `Task completion action` is optional and never used for git commit creation.
- Do not create standalone progress-only commits.

## Dependency Validation

Before finalizing the plan, verify dependency correctness:

- Every task has an explicit `Depends on` field
- No circular dependencies exist
- Any overlapping file write scopes are ordered by dependency, not marked independent
- At least one task is dependency-free so execution can start

## Scope Validation

Before finalizing the plan, verify task budgets are respected:

- Every task has an explicit `Scope Budget` block
- Every task's estimated file touch count is `<= 20`
- Every task's estimated added lines is `<= 1000`
- Any over-budget work is split into additional dependent tasks

## No Placeholders Or Mock Escapes

Every step must contain the actual content an engineer needs. These are plan failures and must be treated as at least `Blocking` until fixed:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling", "add validation", or "handle edge cases" without exact logic
- "Write tests for the above" without actual test code
- "Similar to Task N" instead of repeating the required content
- Steps that describe what to do without showing how when concrete code or commands are required
- References to types, functions, APIs, or methods not defined in any task
- "Use a mock/stub/placeholder for now" or "wire the real integration later"
- Hardcoded success paths, fake data, or temporary no-op implementations that could satisfy the plan text without satisfying the real requirement

## Writer Draft Check

Before the writer subagent reports a draft or revision back to the controller, it should check:

1. Spec coverage: every requirement maps to one or more concrete tasks
2. Placeholder scan: none of the red flags from `No Placeholders Or Mock Escapes` remain
3. Consistency: names, types, file paths, commands, and architecture assumptions line up across tasks
4. Parallelism quality: the `Parallel Execution Plan` does not claim fake independence across overlapping write scopes
5. Mock-escape simulation: an implementer following the plan literally cannot complete a task with fake behavior and still claim success
6. Scope budgets: every task stays within the declared file and line budgets

This writer self-check does not replace independent review.

## Prompt Templates

- `./plan-writer-prompt.md` - Dispatch the plan writer subagent
- `./plan-document-reviewer-prompt.md` - Dispatch the fresh plan reviewer subagent for each round

## Red Flags

Never:

- Write the whole plan directly in the controller session when subagents are available
- Reuse the same reviewer across revision rounds
- Keep a reviewer open after its verdict is recorded
- Let the reviewer patch the plan directly instead of handing findings back to the writer
- Burn cycles on `Non-blocking` issues after round `5`
- Continue to round `11` when `Blocking` issues still remain after round `10`
- Approve a plan that can be "completed" with mock, stub, placeholder, or hardcoded behavior
- Use `Task completion action` for git commit creation
- Restate `superpowers:using-git-worktrees` mechanics here instead of referencing that skill

## Execution Handoff

After the plan is approved, close the reviewer immediately and close the writer if it is now idle.

If approval happens with only advisory `Non-blocking` findings remaining after round `5`, record those findings and proceed.

Then hand off with:

**"Plan approved and saved to `docs/superpowers/plans/<filename>.md`. Ready to execute with subagent-driven development?"**

- Required execution workflow: `superpowers:subagent-driven-development`
- Task worktree lifecycle: `superpowers:using-git-worktrees`
- Execution tracking, checkbox ownership, and review/fix/re-review loops: `superpowers:subagent-driven-development`

If `Blocking` issues still remain after round `10`, do not hand off to implementation. Stop and discuss the unresolved blockers with the user.
