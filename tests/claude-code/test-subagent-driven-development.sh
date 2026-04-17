#!/usr/bin/env bash
# Test: subagent-driven-development skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: subagent-driven-development skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the subagent-driven-development skill? Describe its key steps briefly." 30)

if assert_contains "$output" "subagent-driven-development\|Subagent-Driven Development\|Subagent Driven" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Load Plan\|read.*plan\|extract.*tasks" "Mentions loading plan"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 1b: Verify skill covers independent failure/task-lane coordination
echo "Test 1b: Independent task-lane use case..."

output=$(run_claude "Should the subagent-driven-development skill be used when there are four unrelated failures in different modules that can be split into separate code-change tasks?" 30)

if assert_contains "$output" "independent\|parallel\|separate.*task\|task lane" "Mentions independent task lanes"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify skill describes correct workflow order
echo "Test 2: Workflow ordering..."

output=$(run_claude "In the subagent-driven-development skill, what comes first: spec compliance review or code quality review? Be specific about the order." 30)

if assert_order "$output" "spec.*compliance" "code.*quality" "Spec compliance before code quality"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-review is mentioned
echo "Test 3: Self-review requirement..."

output=$(run_claude "Does the subagent-driven-development skill require implementers to do self-review? What should they check?" 30)

if assert_contains "$output" "self-review\|self review" "Mentions self-review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "completeness\|Completeness" "Checks completeness"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify plan is read once
echo "Test 4: Plan reading efficiency..."

output=$(run_claude "In subagent-driven-development, how many times should the controller read the plan file? When does this happen?" 30)

if assert_contains "$output" "once\|one time\|single" "Read plan once"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Step 1\|beginning\|start\|Load Plan" "Read at beginning"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify spec compliance reviewer is skeptical
echo "Test 5: Spec compliance reviewer mindset..."

output=$(run_claude "What is the spec compliance reviewer's attitude toward the implementer's report in subagent-driven-development?" 30)

if assert_contains "$output" "not trust\|don't trust\|skeptical\|verify.*independently\|suspiciously" "Reviewer is skeptical"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "read.*code\|inspect.*code\|verify.*code" "Reviewer reads code"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify review loops
echo "Test 6: Review loop requirements..."

output=$(run_claude "In subagent-driven-development, what happens if a reviewer finds issues? Is it a one-time review or a loop?" 30)

if assert_contains "$output" "loop\|again\|repeat\|until.*approved\|until.*compliant" "Review loops mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "implementer.*fix\|fix.*issues" "Implementer fixes issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6b: Verify reviewer lifecycle on re-review
echo "Test 6b: Fresh reviewer for re-review..."

output=$(run_claude "In subagent-driven-development, if a reviewer finds issues, should that same reviewer stay open for the next pass or should the controller close it and dispatch a fresh reviewer after fixes?" 30)

if assert_contains "$output" "close.*reviewer\|fresh.*reviewer\|new.*reviewer" "Closes old reviewer and uses fresh reviewer"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6c: Verify fixes stay in same task worktree
echo "Test 6c: Fixes stay in assigned task worktree..."

output=$(run_claude "In subagent-driven-development, after review feedback arrives, where should the fixes be applied?" 30)

if assert_contains "$output" "same.*task worktree\|assigned.*task worktree" "Fixes stay in same task worktree"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify full task text is provided
echo "Test 7: Task context provision..."

output=$(run_claude "In subagent-driven-development, how does the controller provide task information to the implementer subagent? Does it make them read a file or provide it directly?" 30)

if assert_contains "$output" "provide.*directly\|full.*text\|paste\|include.*prompt" "Provides text directly"; then
    : # pass
else
    exit 1
fi

if assert_not_contains "$output" "read.*file\|open.*file" "Doesn't make subagent read file"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify worktree requirement
echo "Test 8: Worktree requirement..."

output=$(run_claude "What workflow skills are required before using subagent-driven-development? List any prerequisites or required skills." 30)

if assert_contains "$output" "using-git-worktrees\|worktree" "Mentions worktree requirement"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify main branch warning
echo "Test 9: Main branch red flag..."

output=$(run_claude "In subagent-driven-development, is it okay to start implementation directly on the main branch?" 30)

if assert_contains "$output" "worktree\|feature.*branch\|not.*main\|never.*main\|avoid.*main\|don't.*main\|consent\|permission" "Warns against main branch"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 10: Verify final controller branch completion stays in SDD
echo "Test 10: Final controller branch completion..."

output=$(run_claude "In subagent-driven-development, after all tasks are integrated and final review passes, what exact options should the controller present for the development branch? Does it hand off to another skill?" 30)

if assert_contains "$output" "merge.*locally\|merge.*development.*branch" "Mentions local merge option"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "pull request\|PR" "Mentions PR option"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "keep.*branch\|as-is\|as is" "Mentions keep-branch option"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "discard" "Mentions discard option"; then
    : # pass
else
    exit 1
fi

if assert_not_contains "$output" "finishing-a-development-branch" "Does not hand off to removed finishing skill"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All subagent-driven-development skill tests passed ==="
