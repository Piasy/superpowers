# Code Quality Reviewer Prompt Template

Use this template when dispatching the code-quality review stage inside `superpowers:subagent-driven-development`.

**Purpose:** Add code-quality-specific checks on top of the standard code-reviewer defined by `superpowers:requesting-code-review`.

**Only dispatch after spec compliance review passes.**

Use the standard code-reviewer dispatch contract from `superpowers:requesting-code-review`:
- Same model as the current controller agent
- `xhigh` reasoning
- Same reviewer-closing rule after the verdict is recorded
- Same placeholders and standard output format

For this stage, map the standard placeholders as follows:
- `WHAT_WAS_IMPLEMENTED` - Implementer's report for this task
- `PLAN_REFERENCE` - Task N from [plan-file]
- `BASE_SHA` - Commit before this task's change set
- `HEAD_SHA` - Current task head
- `DESCRIPTION` - Task summary

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
- For trigger-driven workflows, does the external entrypoint (CLI/API/UI/automation) invoke real execution paths instead of only flipping status/metadata?
- For long-running or multi-stage work, do tests/smokes verify runtime progress or terminal outcomes beyond immediate contract success?
- Do acceptance checks avoid faking runtime transitions by directly mutating persistent state?
- Are there placeholder execution escapes in production code paths (for example "stub runner", "real implementation later", or equivalent deferred semantics not explicitly approved)?

**Code reviewer returns:** The standard `superpowers:requesting-code-review` output format: Strengths, Issues (Critical/Important/Minor), Assessment
