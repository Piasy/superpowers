# Plan Document Reviewer Prompt Template

Use this template when dispatching a fresh reviewer subagent inside `superpowers:writing-plans`.

Dispatch this reviewer with the same model as the current controller agent and `xhigh` reasoning.
Controller should close this reviewer immediately after recording the verdict.
Dispatch a fresh reviewer for every review round. Do not reuse reviewers across rounds.

**Template placeholders:**
- `{FEATURE_NAME}` - Short feature or plan target name
- `{REVIEW_ROUND}` - Current review round number
- `{PLAN_FILE_PATH}` - Plan file path to review
- `{SPEC_FILE_PATH}` - Source spec file path
- `{SPEC_TEXT}` - Full approved spec text that the plan must satisfy
- `{REPO_CONTEXT}` - Relevant codebase structure, constraints, known files, and architectural notes

```
Task tool (general-purpose):
  description: "Review implementation plan for {FEATURE_NAME} (round {REVIEW_ROUND})"
  prompt: |
    You are reviewing whether an implementation plan is actually safe to execute.

    Read the actual plan file. Do not review only a writer summary.

    ## Plan To Review

    - Plan file: {PLAN_FILE_PATH}

    ## Source Spec

    Spec file: {SPEC_FILE_PATH}

    ```text
    {SPEC_TEXT}
    ```

    ## Repo Context

    {REPO_CONTEXT}

    ## Review Focus

    Evaluate the plan for:
    - Architecture design rationality
    - Functional coverage completeness against the spec
    - Task decomposition granularity
    - Dependency order and parallel execution safety
    - Internal consistency across tasks, files, names, types, and commands
    - Whether an implementer could follow the plan literally and still ship mock, stub, placeholder, hardcoded, or fake behavior instead of the real requirement

    ## Mock-Escape Test

    Assume the implementer will take the easiest path available.
    Ask yourself:
    - Could any task be "completed" with fake data, stubbed behavior, no-op logic, or a placeholder integration?
    - Could the plan's tests pass without the real requirement being implemented?
    - Could an unclear task boundary cause someone to stop at scaffolding instead of finishing the feature?

    Any such loophole is a `Blocking` issue.

    ## Severity Calibration

    Use exactly two severities:

    - `Blocking`: A serious issue that would cause the wrong architecture, missing requirements, contradictory steps, unsafe parallel execution, or any path where the plan can be satisfied with mock/placeholder behavior instead of real functionality.
    - `Non-blocking`: A worthwhile improvement, but the plan can still be implemented correctly without it.

    Do not inflate stylistic preferences into findings.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Blocking Issues Found | Non-blocking Issues Found | Blocking + Non-blocking Issues Found

    **Blocking Issues:**
    - [Section/Task reference]: [specific issue] - [why it breaks correct implementation]

    **Non-blocking Issues:**
    - [Section/Task reference]: [specific issue] - [why it would improve the plan]

    **Mock-Escape Assessment:**
    - [State whether the plan leaves any path to ship mock/stub/placeholder behavior, and where]

    **Assessment:**
    - [1-2 sentence summary of readiness]
```

Reviewer returns: `Status`, `Blocking Issues`, `Non-blocking Issues`, `Mock-Escape Assessment`, `Assessment`
