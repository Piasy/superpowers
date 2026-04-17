---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace or before executing implementation plans
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Repo-root `.worktrees/` + one task branch per task worktree + merge-back into the controller development branch + immediate cleanup = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Single Source Of Truth

This skill is the single source of truth for task-worktree rules in this repo.

It owns:
- Controller development branch detection
- One task branch + one task worktree per code-changing task lane
- Stable task-worktree assignment for that lane until integration or explicit reset
- Merge-back into the controller development branch
- Immediate task-worktree cleanup after integration

Other skills should reference this skill instead of restating worktree mechanics.

## Fixed Directory Rule (Mandatory)

- Always create task worktrees under the repository root's `.worktrees/` directory.
- Do not use `worktrees/`, `~/.config/superpowers/worktrees/`, or any other alternate location.
- If `.worktrees/` does not exist, create it at the repo root before creating task worktrees.
- Record the branch checked out when the workflow begins. That controller development branch is the integration target for every task branch created during the run.
- Each active code-changing task lane gets exactly one task branch and one matching `.worktrees/<task-branch>` directory.
- Keep that same task branch and task worktree assigned to the task across implementation, review fixes, checkbox updates, and re-review until the task is integrated or explicitly reset.
- Never let multiple coding agents write in the same task worktree.
- Shared coordination files stay in the controller development branch workspace.
- If isolated task worktrees cannot be established, do not run parallel code edits; downgrade to sequential execution.

## Safety Verification

**MUST verify `.worktrees/` is ignored before creating any task worktree:**

```bash
git check-ignore -q .worktrees
```

**If NOT ignored:**

Per Jesse's rule "Fix broken things immediately":
1. Add `.worktrees/` to `.gitignore`
2. Commit the change
3. Proceed with task worktree creation

**Why critical:** Prevents accidentally committing task worktree contents to the repository.

## Creation Steps

### 1. Detect Repo Root and Controller Development Branch

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CONTROLLER_BRANCH=$(git branch --show-current)
```

**If `CONTROLLER_BRANCH` is empty:** Stop and ask your human partner how this detached HEAD should be handled before creating task branches.

### 2. Ensure `.worktrees/` Exists at Repo Root

```bash
mkdir -p "$REPO_ROOT/.worktrees"
git check-ignore -q .worktrees
```

### 3. Create Task Worktree and Task Branch

```bash
TASK_BRANCH="$BRANCH_NAME"
TASK_PATH="$REPO_ROOT/.worktrees/$TASK_BRANCH"

# Create worktree with new branch from the controller development branch
git worktree add "$TASK_PATH" -b "$TASK_BRANCH" "$CONTROLLER_BRANCH"
cd "$TASK_PATH"
```

### 4. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 5. Verify Clean Baseline

Run tests to ensure the task worktree starts clean:

```bash
# Examples - use the project-appropriate command
npm test
cargo test
pytest
go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 6. Report Location

```
Task worktree ready at <repo-root>/.worktrees/<task-branch>
Task branch <task-branch> created from <controller-branch>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Task Completion Cleanup

After final review passes and the controller integrates the task branch back into the controller development branch:

```bash
git -C "$REPO_ROOT" worktree remove "$TASK_PATH"
git -C "$REPO_ROOT" branch -d "$TASK_BRANCH"
```

The controller should clean up immediately after integration. Do not leave completed task worktrees sitting around.

If a session resumes and a task worktree already exists:
- Reuse it if the task is incomplete and its state matches tracked progress.
- Remove it immediately if the task is already integrated.

## Scope Boundary

This skill owns task worktree creation, per-task branch isolation, merge-back, and cleanup.

It does **not** decide when reviews happen, whether reviewers are reused or replaced, or how task review/fix/re-review loops run.

It does **not** decide what to do with the controller development branch after all task worktrees are gone.

When no task worktrees remain, return control to the calling workflow for the final merge/PR/keep/discard decision.

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` missing | Create it at repo root |
| `.worktrees/` exists | Verify ignored, then use it |
| `.worktrees/` not ignored | Add `.worktrees/` to `.gitignore` + commit |
| Controller development branch missing | Stop and ask |
| Need parallel code edits | Create one task worktree per code-changing task lane |
| Task complete and integrated | Remove the task worktree, then delete the task branch |
| Leftover completed task worktree on resume | Remove it immediately |
| No task worktrees remain | Return to the caller for the controller branch decision |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Task worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore -q .worktrees` before creating any task worktree

### Using the wrong directory

- **Problem:** Creates inconsistency, breaks cleanup expectations
- **Fix:** Always use repo-root `.worktrees/`

### Forgetting the controller development branch

- **Problem:** Task branches diverge and no longer have a single integration target
- **Fix:** Record the starting branch once and create every task branch from it

### Sharing one task worktree between multiple coding agents

- **Problem:** Agents interfere, overwrite each other, and make integration ambiguous
- **Fix:** Give each active code-changing task lane its own task worktree

### Moving review fixes to a different worktree

- **Problem:** Breaks task ownership, confuses status, and makes re-review ambiguous
- **Fix:** Keep review fixes in the same assigned task worktree until the task is integrated or explicitly reset

### Leaving completed task worktrees around

- **Problem:** Idle worktrees accumulate, confuse status, and waste slots
- **Fix:** Remove the task worktree and delete the task branch immediately after integration

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Using this skill for the final branch decision

- **Problem:** Mixes task-worktree mechanics with controller-branch workflow decisions
- **Fix:** Hand control back to the calling workflow once all task worktrees are gone

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (`package.json`, etc.)

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Record controller development branch: feature/auth]
[Create repo-root .worktrees/ if needed]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[Create worktree: git worktree add /repo/.worktrees/task-auth -b task-auth feature/auth]
[Run npm install]
[Run npm test - 47 passing]

Task worktree ready at /Users/jesse/myproject/.worktrees/task-auth
Task branch task-auth created from feature/auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature
```

## Red Flags

**Never:**
- Create a task worktree outside repo-root `.worktrees/`
- Create a task worktree without verifying `.worktrees/` is ignored
- Skip baseline test verification
- Proceed with failing tests without asking
- Forget which branch is the controller development branch
- Let multiple coding agents write in the same task worktree
- Leave a completed task worktree unremoved after integration
- Use this skill to decide the final fate of the controller development branch

**Always:**
- Use repo-root `.worktrees/`
- Verify `.worktrees/` is ignored
- Create each task branch from the controller development branch
- Give each active code-changing task lane its own task worktree
- Merge/cherry-pick each completed task back into the controller development branch
- Remove the task worktree immediately after integration
- Delete the task branch after the task worktree is gone
- Auto-detect and run project setup
- Verify a clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing code-changing tasks; owns review/fix/re-review orchestration for those isolated task worktrees
- Any workflow needing isolated task worktrees

**Referenced by review workflows:**
- **requesting-code-review** - Review requests may use the task-scoped branch/worktree context supplied by the caller, but that skill does not own worktree lifecycle
