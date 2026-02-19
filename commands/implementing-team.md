---
description: "Dispatch an implementation team: Haiku messengers coordinate Opus 4.6 coders (TDD, lean) and Opus 4.6 reviewers to implement tasks from existing plans."
arguments:
  - name: mode
    description: "Execution mode: 'parallel' dispatches all tasks simultaneously (independent tasks), 'sequential' chains tasks so each builds on the previous implementation (dependent tasks). Default: parallel"
    required: false
---

# /implementing-team

Dispatch an implementation team to execute plans using TDD and lean methodology. Each task gets a **Haiku messenger** that coordinates an **Opus 4.6 coder** and an **Opus 4.6 reviewer**, then passes feedback for fixes.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All tasks are dispatched simultaneously. Use when tasks touch independent files.
  - `sequential`: Tasks are dispatched one at a time. Each coder works in the tree left by the previous one. Use when tasks share files or build on each other.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you)
├── Task A
│   └── Haiku Messenger
│       ├── 1. Opus Coder (model: claude-opus-4.6) → implements (TDD)
│       ├── 2. Opus Reviewer (model: claude-opus-4.6) → reviews changes
│       └── 3. Opus Coder (model: claude-opus-4.6) → addresses feedback
├── Task B
│   └── Haiku Messenger (same structure)
└── ...
```

## Your Role (Orchestrator)

1. **Locate the plans** — each task must have an existing implementation plan. If no plan exists, stop and tell the user to run `/planning-team` first.
2. **Prepare context** — read project docs for conventions, detect the test command, identify the branch strategy
3. **Create branch** if not already on a feature branch
4. **Dispatch messengers** — one Haiku messenger per task
5. **Collect results** — wait for all, verify tests pass, commit
6. **Preserve your context** — rely on messenger status reports

## Phase 0: Context Gathering

1. Read project docs (CLAUDE.md, AGENTS.md) for conventions, test command, and coding style
2. Identify the implementation plans from the user's prompt or the artifacts directory
3. Detect the test command (from project docs or common patterns)
4. Ensure you're on a feature branch. If on main, create one: `git checkout -b feature/<description>`

## Phase 1: Dispatch Messengers

For each task, dispatch a **Task subagent** (`model: claude-haiku-4.5`, `agent_type: general-purpose`) with the prompt below.

**If mode is `parallel`**: dispatch ALL messengers in a single response. Tasks MUST NOT share files.

**If mode is `sequential`**: dispatch one at a time. Wait for completion before dispatching the next. The next coder works in the modified tree.

### Messenger Prompt Template

```
You are a messenger agent coordinating an implementation cycle. Your job is to dispatch two sub-agents, pass feedback between them, and report back with a SHORT status (1-2 sentences max).

## Task: <TASK_NAME>

## Implementation Plan

The coder MUST read the plan at: <PLAN_FILE_PATH>

## Project Conventions

<SHORT_SUMMARY — style, patterns, frameworks, test command>

## Test Command

<TEST_COMMAND>

## Working Directory

<ABSOLUTE_PATH_TO_REPO>

## Your Workflow

1. **Dispatch Opus Coder** (model: claude-opus-4.6, agent_type: general-purpose):

   Give it these instructions:

   - Read the implementation plan at `<PLAN_FILE_PATH>` first
   - Follow TDD methodology strictly:
     a. Read the plan step
     b. Write a failing test for the step
     c. Run `<TEST_COMMAND>` — confirm the test fails (red)
     d. Write the minimum code to make the test pass
     e. Run `<TEST_COMMAND>` — confirm the test passes (green)
     f. Refactor if needed, run tests again
     g. Move to the next step
   - Lean approach: write the smallest possible code that satisfies each requirement. No speculative features, no premature abstractions.
   - Read every file before modifying it
   - Do NOT commit — the orchestrator handles git
   - Do NOT modify documentation or agent docs
   - After completing all steps, report: files created/modified, test count, any deviations from the plan

2. **Dispatch Opus Reviewer** (model: claude-opus-4.6, agent_type: general-purpose):

   Give it these instructions:

   - Review the code changes made by the coder
   - Run `git diff` to see all changes
   - Read the implementation plan at `<PLAN_FILE_PATH>` for reference
   - Review criteria:
     a. **Plan adherence**: Did the coder follow the plan? Any gaps or deviations?
     b. **Test quality**: Are tests meaningful? Do they cover edge cases from the plan?
     c. **Code quality**: Clean, minimal, no dead code, no over-engineering?
     d. **Convention compliance**: Does the code follow project patterns?
     e. **Risks**: Anything that could break existing functionality?
   - Do NOT modify code yourself
   - Write your findings as a structured report. End with a verdict:
     LGTM / REQUEST CHANGES (with specific, actionable items)
   - If REQUEST CHANGES: list each required change with the file and what to fix

3. **If the reviewer requests changes**, dispatch the **Opus Coder again** (model: claude-opus-4.6, agent_type: general-purpose):

   - Give it the reviewer's findings
   - Instruct it to address each requested change
   - Instruct it to run `<TEST_COMMAND>` after each fix
   - Instruct it to report: what was fixed, final test count

   **If the reviewer says LGTM**, skip this step.

4. **Report back**: Tell the orchestrator in 1-2 sentences: done/stuck, test count, files changed, any blockers.
```

## Phase 2: Collect Results

Wait for all messengers. For each, extract:
- Status: done / stuck / failed
- Files created / modified
- Test count (pass/fail)
- Any blockers

## Phase 3: Verify and Commit

1. **Run tests yourself**: Execute the test command to confirm everything passes. Only check the summary; read full output only on failure.
2. **Review the diff**: `git --no-pager diff --stat` to see scope of changes
3. **Commit in logical chunks**: Group related changes into commits with conventional commit messages:
   ```
   feat: <description>

   - bullet points of key changes
   - test count: N tests passing

   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
   ```
4. **Push**: `git push -u origin <branch>`

## Phase 4: Report

Print a summary table:

```
| Task | Files | Tests | Review | Status |
|------|-------|-------|--------|--------|
| <name> | <count> | <count> passing | LGTM / Fixed | Done |
```

Plus: branch name, commit count, and whether to open a PR.

## Rules

- **Messengers are Haiku** — cheap, fast, coordination only
- **Coders and Reviewers are Opus 4.6** — high-effort, maximum quality
- **TDD is non-negotiable** — red → green → refactor, always
- **Lean approach** — smallest code that works, no speculative features
- **Each messenger is stateless** — give it complete context
- **Orchestrator verifies** — always run tests yourself before committing
- **Sequential mode preserves tree state** — each coder works in the tree the previous one left
- **Parallel mode requires file independence** — if tasks share files, use sequential
- **Plans must exist** — this command implements existing plans, it does not create them
- **Coders don't commit** — only the orchestrator touches git
