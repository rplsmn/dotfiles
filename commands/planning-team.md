---
description: "Dispatch a planning team: Haiku messengers coordinate Opus planners and Opus reviewers to produce reviewed implementation plans for one or more tasks."
arguments:
  - name: mode
    description: "Execution mode: 'parallel' dispatches all tasks simultaneously (independent tasks), 'sequential' chains tasks so each builds on the previous output (dependent tasks). Default: parallel"
    required: false
---

# /planning-team

Dispatch a planning team to produce detailed, reviewed implementation plans. Each task gets a **Haiku messenger** that coordinates an **Opus planner** and an **Opus reviewer**, then incorporates feedback.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All tasks are dispatched simultaneously. Use when tasks are independent.
  - `sequential`: Tasks are dispatched one at a time. Each messenger receives the output of the previous task as additional context. Use when tasks have dependencies.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you)
├── Task A
│   └── Haiku Messenger
│       ├── 1. Opus Planner (model: claude-opus-4.6) → writes plan
│       ├── 2. Opus Reviewer (model: claude-opus-4.6) → writes review
│       └── 3. Opus Planner (model: claude-opus-4.6) → revises plan with feedback
├── Task B
│   └── Haiku Messenger (same structure)
└── ...
```

## Your Role (Orchestrator)

You are the orchestrator. Your job is:

1. **Collect task definitions** from the user's prompt (everything after the command and mode argument)
2. **Prepare context** — read relevant files, understand the codebase
3. **Dispatch messengers** — one Haiku messenger per task
4. **Collect results** — wait for all messengers, report status
5. **Preserve your context** — do NOT read the full plans yourself; rely on messenger status reports

## Phase 0: Context Gathering

1. Read project docs (CLAUDE.md, AGENTS.md, README) for conventions and structure
2. Identify the tasks from the user's prompt. Each task should have a clear name and scope.
3. Identify the artifacts directory. Use `~/.artifacts/<project>/plans/` or the project's designated plans folder.
4. For each task, identify which source files the planner will need to read.

## Phase 1: Dispatch Messengers

For each task, dispatch a **Task subagent** (`model: claude-haiku-4.5`, `agent_type: general-purpose`) with the prompt below.

**If mode is `parallel`**: dispatch ALL messengers in a single response using parallel Task tool calls.

**If mode is `sequential`**: dispatch one messenger at a time. Wait for completion. Pass the previous task's plan file path as additional context to the next messenger.

### Messenger Prompt Template

```
You are a messenger agent coordinating a planning cycle. Your job is to dispatch two sub-agents, pass feedback between them, and report back with a SHORT status (1-2 sentences max).

## Task: <TASK_NAME>

<TASK_DESCRIPTION — full scope, requirements, constraints>

## Context Files

The planner MUST read these files before writing the plan:
<LIST_OF_FILE_PATHS>

## Project Conventions

<SHORT_SUMMARY from CLAUDE.md / AGENTS.md — style, patterns, frameworks>

## Artifacts Directory

Save all artifacts to: <ARTIFACTS_DIR>

## Your Workflow

1. **Dispatch Opus Planner** (model: claude-opus-4.6, agent_type: general-purpose):
   - Give it the full task description, context file paths, and project conventions
   - Instruct it to READ the source files before planning
   - Instruct it to write a detailed implementation plan to:
     `<ARTIFACTS_DIR>/<date>-<task-slug>-plan.md`
   - The plan must include: overview, architecture decisions, numbered implementation steps, testing strategy, edge cases, exit criteria

2. **Dispatch Opus Reviewer** (model: claude-opus-4.6, agent_type: general-purpose):
   - Give it the plan file path
   - Give it the original task description for reference
   - Give it the project conventions
   - Instruct it to review for: completeness vs requirements, feasibility, missed edge cases, convention compliance, over-engineering
   - Instruct it to write the review to:
     `<ARTIFACTS_DIR>/<date>-<task-slug>-review.md`
   - The review must end with a verdict: APPROVE / APPROVE WITH CHANGES / NEEDS REVISION

3. **Dispatch Opus Planner again** (model: claude-opus-4.6, agent_type: general-purpose):
   - Give it both the plan and review file paths
   - Instruct it to read the review and incorporate ALL feedback into the plan
   - Instruct it to UPDATE the plan file in place

4. **Report back**: Tell the orchestrator in 1-2 sentences: done/stuck, any blockers, file paths produced.
```

## Phase 2: Collect Results

Wait for all messengers to complete. For each, extract:
- Status: done / stuck / failed
- Plan file path
- Review file path
- Any blockers or issues

## Phase 3: Report

Print a summary table:

```
| Task | Plan | Review | Status |
|------|------|--------|--------|
| <name> | <size> | <size> | Done / Stuck |
```

Plus total artifact count and any blockers that need human attention.

## Rules

- **Messengers are Haiku** — cheap, fast, coordination only
- **Planners and Reviewers are Opus 4.6** — high-effort, thorough reasoning
- **Each messenger is stateless** — give it complete context in the prompt
- **Orchestrator stays lean** — don't read plan contents, rely on messenger reports
- **Artifacts are permanent** — plans and reviews are written to disk, not ephemeral
- **Sequential mode chains context** — each messenger gets the previous task's plan path as "Prior work" context
- **Never start implementing** — this command produces plans only
