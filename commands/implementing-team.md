---
description: "Dispatch an implementation team: Opus coder-reviewer agents implement tasks from existing plans with TDD, iterated review, and decision logging."
arguments:
  - name: mode
    description: "Execution mode: 'parallel' dispatches all tasks in isolated worktrees (independent tasks), 'sequential' chains tasks in the same tree (dependent tasks). Default: parallel"
    required: false
---

# /implementing-team

Dispatch an implementation team to execute existing plans using TDD. Each task gets an **Opus coder-reviewer agent** that implements, self-reviews via a reviewer sub-agent, and iterates until approved.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All tasks dispatched simultaneously, each in its own **git worktree** for true isolation. Orchestrator merges branches after.
  - `sequential`: Tasks dispatched one at a time. Each coder works in the tree left by the previous one. Use when tasks share files or build on each other.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you)
│
├── Phase 0: Context Gathering
│   ├── Locate plans, read project docs
│   └── Ensure feature branch exists
│
├── Phase 1: Dispatch Coder-Reviewer Agents
│   └── Per task: Opus agent (isolation: worktree if parallel)
│       ├── Implements with TDD (red → green → refactor)
│       ├── Commits implementation
│       ├── Dispatches Opus Reviewer sub-subagent
│       ├── Reads review, applies fixes, commits fixes
│       ├── Loops until LGTM (max 3 rounds)
│       └── Reports: status, files, tests, decision log
│
├── Phase 2: Merge (parallel mode only)
│   └── Merge worktree branches into feature branch
│
├── Phase 3: Verify, Push & PR
│   ├── Run full test suite
│   ├── Push
│   └── Open PR with summary + decision log
│
└── Phase 4: Report
    └── Summary table + decision log + next steps
```

## Your Role (Orchestrator)

1. **Locate the plans** — each task must have an existing plan. If no plan exists, stop and tell the user to run `/planning-team` first.
2. **Prepare context** — read project docs for conventions, detect the test command
3. **Create feature branch** if on main: `git checkout -b feature/<description>`
4. **Dispatch agents** — one Opus agent per task
5. **Merge worktree branches** (parallel mode) — merge each agent's branch into the feature branch
6. **Verify & push** — run tests yourself, push
7. **Preserve your context** — rely on agent status reports; do NOT read all the code changes

---

## Phase 0: Context Gathering

1. Read project docs (CLAUDE.md, AGENTS.md) for conventions, test command, and coding style
2. Identify the implementation plans from the user's prompt or the artifacts directory
3. Detect the test command (from project docs or common patterns like `Rscript -e "testthat::test_local()"`, `npm test`, `pytest`, etc.)
4. Ensure you're on a feature branch. If on main, create one: `git checkout -b feature/<description>`

---

## Phase 1: Dispatch Coder-Reviewer Agents

For each task, dispatch a **Task subagent** (`model: opus`, `subagent_type: general-purpose`).

**If mode is `parallel`**: dispatch ALL agents in a single response, each with `isolation: "worktree"`. Tasks get true file-system isolation — no conflict risk.

**If mode is `sequential`**: dispatch one at a time. Wait for completion before dispatching the next. No worktree — each coder works in the current tree.

### Coder-Reviewer Agent Prompt Template

````
You are a coder-reviewer agent. Implement a task from an existing plan using strict TDD, get your work reviewed, and iterate until approved.

## Task: <TASK_NAME>

## Implementation Plan

Read the plan FIRST: <PLAN_FILE_PATH>

## Project Conventions

<SUMMARY from CLAUDE.md / AGENTS.md — style, patterns, naming, frameworks>

## Test Command

<TEST_COMMAND>

## Working Directory

<ABSOLUTE_PATH_TO_REPO>

## Your Workflow

### Step 1: Read the Plan

Read the implementation plan thoroughly. Understand every step, every function signature, every test case before writing any code.

### Step 2: Implement with TDD

For each step in the plan:

1. **Read** every file you're about to modify
2. **Write a failing test** for the step
3. **Run tests** (`<TEST_COMMAND>`) — confirm the new test fails (red)
4. **Write the minimum code** to make the test pass
5. **Run tests** — confirm all tests pass (green)
6. **Refactor** if needed, run tests again
7. Move to the next step

**Lean approach**: write the smallest code that satisfies each requirement. No speculative features, no premature abstractions, no extra comments or docstrings beyond what's in the plan.

### Step 3: Commit Implementation

Once all plan steps are implemented and tests pass, commit:
```
git add <specific files> && git commit -m "feat: implement <task name>"
```
Use a descriptive message. This gives the reviewer a clean diff baseline.

### Step 4: Decision Log

As you implement, maintain a decision log for anything that deviates from or isn't covered by the plan:

- **DEVIATION**: Plan said X but reality required Y. Explain why.
- **AMBIGUITY**: Plan didn't specify how to handle case Z. Explain your choice.
- **SKIP**: Skipped plan step N. Explain why (already handled, unnecessary, etc.).

If the plan is followed exactly with no surprises, the decision log is empty. That's fine.

### Step 5: Dispatch Reviewer

After all plan steps are implemented and tests pass, dispatch an **Opus Reviewer subagent** (model: opus, subagent_type: code-reviewer) with this prompt:

```
You are a code reviewer. Review the implementation against the plan.

## Plan File
Read this: <PLAN_FILE_PATH>

## Test Command
<TEST_COMMAND>

## Review Process

1. **Run tests first**: Execute `<TEST_COMMAND>`. If tests fail, that's your first and most critical finding. Do not continue the review until you've documented which tests fail and why.

2. **Check the commit log**: Run `git log --oneline` to understand the change history. Use `git diff HEAD~1` to see the latest round's changes, or `git diff <first-implementation-commit>~1..HEAD` for the full diff.

3. **Review against the plan LINE BY LINE**:
   - Did the coder implement every step?
   - Do function signatures match the plan?
   - Are column names, join keys, guard conditions correct?
   - Are there gaps or deviations from the plan?

4. **Code quality**:
   - Clean, minimal, no dead code, no over-engineering?
   - Convention compliance (naming, patterns, style)?
   - Any risks to existing functionality?

5. **Test quality**:
   - Are tests meaningful? Do they test behavior, not implementation details?
   - Do they cover the edge cases listed in the plan?

## Output

For each issue:
- **Severity**: CRITICAL / IMPORTANT / SUGGESTION
- **File:line**: where the issue is
- **Problem**: what's wrong
- **Fix**: specific, actionable fix

End with verdict: **LGTM** or **NEEDS FIXES** (list which)
```

### Step 6: Fix Loop

If the reviewer says **NEEDS FIXES**:
1. Read the review carefully
2. Apply ALL CRITICAL and IMPORTANT fixes (you wrote the code — you understand the reasoning)
3. Run `<TEST_COMMAND>` to confirm tests still pass
4. Commit the fixes: `git commit -am "fix: address review round N feedback"`
5. Add any new decisions to the decision log
6. Dispatch the reviewer again, adding: "This is review round N. Verify previous fixes — use `git diff HEAD~1` to see just this round's changes. Look for NEW issues introduced by the fixes."
7. Repeat until **LGTM** or 3 review rounds

If not LGTM after 3 rounds, note remaining issues in your report.

### Step 7: Report

Report back with EXACTLY this format:

```
## Status: done / stuck (with reason)

## Files Created
- path/to/new_file.R

## Files Modified
- path/to/existing_file.R

## Tests
- X tests passing, Y new tests added
- Test command: <what you ran>

## Review
- Rounds: N
- Final verdict: LGTM / ISSUES REMAINING (count)

## Decision Log
- [DEVIATION] ...
- [AMBIGUITY] ...
(or: No deviations from plan.)
```
````

---

## Phase 2: Merge (Parallel Mode Only)

When all agents complete in parallel mode, each returns a worktree branch.

1. For each completed agent, merge its branch into the feature branch:
   ```
   git merge <worktree-branch> --no-edit
   ```
2. If a merge conflict occurs: **stop and report to the user**. Do NOT auto-resolve merge conflicts. Show which files conflict and between which tasks.
3. After successful merge, clean up the worktree branch:
   ```
   git branch -d <worktree-branch>
   ```
4. Run the full test suite after all merges to catch integration issues.

Skip this phase in sequential mode — agents already worked in the same tree.

---

## Phase 3: Verify, Push & PR

Agents have already committed their work. The orchestrator's job is to verify the integrated result, push, and open a PR.

1. **Run tests**: Execute the test command on the merged tree. Only check the summary; read full output only on failure.
2. **Check the log**: `git log --oneline` to see the commit history left by agents.
3. **Push**: `git push -u origin <branch>`
4. **Open PR**: Use `gh pr create` with:
   - Title: concise description of the feature/change
   - Body: the summary table + consolidated decision log from Phase 4 (write body first, then create PR)

---

## Phase 4: Report

Print a summary table:

```
| Task | Files | Tests | Rounds | Verdict | Decisions |
|------|-------|-------|--------|---------|-----------|
| <name> | <created>/<modified> | <new>/<total> passing | N | LGTM | N deviations |
```

Then print the **consolidated decision log** — all DEVIATION, AMBIGUITY, and SKIP entries across all tasks. This is the key information for the user: where reality diverged from the plan.

Finally: branch name, commit count, and the PR URL.

---

## Rules

- **Plans must exist** — this command implements existing plans, it does not create them
- **Coders and reviewers are Opus** — high-effort, maximum quality
- **TDD is non-negotiable** — red → green → refactor, always
- **Lean approach** — smallest code that works, no speculative features
- **Review is iterated** — loop until LGTM, max 3 rounds
- **No review artifacts** — reviews are ephemeral in the agent's context, not saved to disk
- **Decision log is mandatory** — every plan deviation or ambiguity resolution is logged and surfaced
- **Coder self-fixes** — the same agent that wrote the code applies review fixes (has full context)
- **Parallel uses worktrees** — `isolation: "worktree"` on each Task call for true isolation
- **Merge conflicts are human problems** — never auto-resolve, always report
- **Orchestrator verifies** — always run tests yourself before pushing
- **Coders commit their work** — implementation commit + fix commits per review round, giving reviewers clean diffs
- **Sequential preserves tree state** — each coder works in the tree the previous one left
