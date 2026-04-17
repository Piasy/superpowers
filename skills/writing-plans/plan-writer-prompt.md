# Plan Writer Prompt Template

Use this template when dispatching the writer subagent inside `superpowers:writing-plans`.

Dispatch this writer with the same model as the current controller agent and `xhigh` reasoning.
Keep this writer assigned to the same plan file through the write/review/revise loop until the plan is approved or the workflow pauses for user input.
Controller should close this writer once the plan is approved or the workflow pauses and the writer becomes idle.

**Template placeholders:**
- `{FEATURE_NAME}` - Short feature or plan target name
- `{PLAN_FILE_PATH}` - Target plan file path
- `{REVIEW_ROUND}` - `0` for the initial draft, otherwise the current revision round
- `{SPEC_FILE_PATH}` - Source spec file path
- `{SPEC_TEXT}` - Full approved spec text for this plan
- `{REPO_CONTEXT}` - Relevant codebase structure, constraints, known files, and architectural notes
- `{REVIEWER_FINDINGS}` - Prior reviewer findings for this revision, or `None` for the initial draft

```
Task tool (general-purpose):
  description: "Write implementation plan for {FEATURE_NAME}"
  prompt: |
    You are writing an implementation plan.

    ## Plan Output

    - Plan file path: {PLAN_FILE_PATH}
    - Save the full plan directly to that file before reporting back
    - Current review round: {REVIEW_ROUND}

    ## Source Spec

    Spec file: {SPEC_FILE_PATH}

    ```text
    {SPEC_TEXT}
    ```

    ## Repo Context

    {REPO_CONTEXT}

    ## Reviewer Findings For This Round

    {REVIEWER_FINDINGS}

    ## Your Job

    Produce a complete implementation plan that is ready for execution through
    `superpowers:subagent-driven-development`.

    The plan must:
    - Use explicit task dependencies
    - Include a `Parallel Execution Plan`
    - Keep each task within the declared file and line budgets
    - Use exact file paths, concrete code, and exact verification commands
    - Avoid placeholders, deferred decisions, mock logic, fake integrations, and "implement later" escapes
    - Make the correct implementation the easiest implementation

    Do not rely on the reviewer to fill in missing details later. Write the plan so an
    implementer with limited context can execute it correctly.

    ## Revision Loop

    You may receive reviewer findings after your first draft. When that happens:
    - Revise the same plan file instead of starting over
    - Treat `Blocking` findings as mandatory
    - Treat `Non-blocking` findings as mandatory only through round 5
    - After round 5, non-blocking findings may remain documented if they do not affect correctness

    ## Escalation Rule

    If the spec or repo context is insufficient to produce a correct plan, stop and report:
    - **Status:** NEEDS_CONTEXT or BLOCKED
    - What is missing
    - Why it blocks a correct plan

    Do not invent requirements, APIs, or architecture decisions just to keep moving.

    ## Before Reporting Back

    Check your draft for:
    - Full spec coverage
    - Internal consistency
    - Safe dependency and parallelism design
    - Real implementation paths (no mock/stub/placeholder loopholes)
    - Task budgets and concrete verification steps

    ## Report Format

    - **Status:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Plan file written
    - Summary of task decomposition
    - Any risks or concerns
```
