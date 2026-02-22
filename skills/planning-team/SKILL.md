---
name: planning-team
description: "Brainstorm with the user, then dispatch Opus planners and reviewers to produce iterated-reviewed implementation plans for one or more tasks."
---

# /planning-team

Brainstorm interactively with the user to produce a validated spec, then dispatch Opus planner-reviewer agents to write detailed implementation plans with iterated review.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All plan-writing tasks dispatched simultaneously. Use when tasks are independent.
  - `sequential`: Tasks dispatched one at a time. Each receives the previous task's plan as context. Use when tasks depend on each other.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you)
│
├── Phase 0: Context Gathering
│   ├── Explore subagent → reads source files + project docs
│   └── Skill Discovery → finds relevant skills for the stack via specs-sync
│
├── Phase 1: Brainstorming (you + user, interactive)
│   ├── Ask questions one at a time
│   ├── Present design in sections, validate each
│   ├── Synthesize review criteria from skills + docs + context
│   └── Output: validated spec + task list + source file list + review criteria
│
├── Phase 2: Plan-Review Dispatch (per task)
│   └── Opus Planner-Reviewer agent
│       ├── Writes plan from validated spec
│       ├── Dispatches Opus Reviewer sub-subagent (critical-code-reviewer methodology)
│       ├── Reads review, applies fixes to its own plan
│       └── Loops until READY (max 3 rounds)
│
└── Phase 3: Report
    └── Summary table, file paths, blockers
```

## Your Role (Orchestrator)

You are the orchestrator. Your job is:

1. **Gather context** — dispatch Explore subagent, read project docs, discover relevant skills
2. **Brainstorm with the user** — interactive design session producing a validated spec and review criteria
3. **Dispatch planner-reviewer agents** — one Opus agent per task
4. **Collect results** — wait for all agents, report status
5. **Preserve your context** — do NOT read the full plans; rely on agent status reports

---

## Phase 0: Context Gathering

Before engaging the user:

1. Read project docs (CLAUDE.md, AGENTS.md, README) for conventions and structure
2. Dispatch an **Explore subagent** (`subagent_type: Explore`) to read source files relevant to the user's prompt
3. Identify the artifacts directory: `~/.artifacts/<project>/plans/` or the project's designated plans folder
4. **Discover relevant skills**: Run `specs-sync list` and `specs-sync search <terms>` (using terms from the project's stack, frameworks, domain) to find skills that provide expertise for this project's technology. Read the matched skills — they contain patterns, idioms, and common pitfalls that will inform review criteria in Phase 1. **Record the absolute file paths** of each relevant skill (e.g. `~/.local/share/llm-specs/skills/<name>/SKILL.md`) — these will be passed to subagents so they can read the full skill content themselves.

---

## Phase 1: Brainstorming (Interactive)

**Goal**: Produce a validated spec AND review criteria. ALL design decisions are made HERE, not by the planner.

**This phase is non-negotiable. It always happens before any plan dispatch.**

### Process

1. **Present understanding** — briefly summarize what the Explore subagent found and your initial read of the task
2. **Ask questions one at a time** — clarify design decisions, scope, constraints, naming
   - Prefer multiple choice when possible
   - ONE question per message — never batch questions
   - Focus on: purpose, composition model, naming conventions, scope boundaries, edge cases
3. **Explore approaches** — when a design fork appears, propose 2-3 options with trade-offs. Lead with your recommendation and explain why.
4. **Present design in sections** — 200-300 words each. After each section, ask the user if it looks right before continuing.
5. **Produce the validated spec** — a concise summary capturing:
   - Tasks identified (may be 1 or many — brainstorming may reveal decomposition)
   - Per task: what to build, data flow, naming, design decisions made + rationale
   - Source files each planner needs to read
   - Shared conventions and constraints
6. **Synthesize review criteria** — as the FINAL step before dispatch, derive review criteria from three sources and present them to the user:
   - **Skills**: What patterns, idioms, and pitfalls do the discovered skills highlight for this stack? What does "good" look like according to the expertise available?
   - **Project docs**: What conventions, priorities, architectural constraints, and testing strategies does the project mandate?
   - **Brainstorming context**: What did the user emphasize? What scope decisions create risk? What areas need extra scrutiny?

   Present the criteria as a short numbered list: "Here's what I'll hold the plans to — does this cover what matters?" The user validates or adjusts. These criteria become part of the spec.

**Exit criteria**: User explicitly confirms the spec AND review criteria are correct. No ambiguity in scope, approach, or evaluation standards.

### YAGNI

During brainstorming, actively push back on unnecessary complexity. Remove features that aren't clearly needed. The best plans are lean.

---

## Phase 2: Plan-Review Dispatch

For each task identified in Phase 1, dispatch a **Task subagent** (`model: opus`, `subagent_type: general-purpose`) that runs the full plan-review cycle internally.

**If mode is `parallel`**: dispatch ALL task agents in a single response using parallel Task tool calls.

**If mode is `sequential`**: dispatch one at a time. Wait for completion. Pass the previous task's plan file path as additional context to the next agent.

### Planner-Reviewer Agent Prompt Template

````
You are a planner-reviewer agent. Write a detailed implementation plan, get it reviewed against the source code, and iterate until the reviewer approves.

## Task: <TASK_NAME>

<TASK_DESCRIPTION from validated spec — include ALL design decisions, naming conventions, scope, rationale>

## Review Criteria

The orchestrator derived these criteria from the project's skills, documentation, and brainstorming context. The reviewer will evaluate your plan against them.

<REVIEW_CRITERIA>

## Reference Skills

The criteria above were derived from these skills. Read them for full stack-specific guidance (patterns, idioms, pitfalls):
<LIST_OF_SKILL_FILE_PATHS>

## Source Files to Read

You MUST read ALL of these files before writing the plan:
<LIST_OF_FILE_PATHS>

## Project Conventions

<SUMMARY from CLAUDE.md / AGENTS.md — style, patterns, naming, frameworks>

## Artifacts Directory

<ARTIFACTS_DIR>

## Your Workflow

### Step 1: Read Source Files

Read EVERY file listed above. Understand the current code before writing anything.

### Step 2: Write the Plan

Write a detailed implementation plan to:
`<ARTIFACTS_DIR>/<date>-<task-slug>-plan.md`

The plan MUST include:
- Complete function signatures with FULL code bodies (not skeletons or pseudocode)
- Explicit type contracts, method dispatch, guard conditions at API boundaries
- Pipeline wiring changes (how new code connects to existing code)
- Testing strategy with concrete test cases (reference the test command documented in project CLAUDE.md or AGENTS.md; never assume language-specific commands)
- Edge cases section
- Exit criteria / definition of done

The plan should be detailed enough that implementation is near copy-paste trivial.

### Step 3: Dispatch Reviewer

Dispatch a **Task subagent** (model: opus, subagent_type: code-reviewer) with this prompt:

```
You are a critical plan reviewer. Review the implementation plan against the actual source code using an adversarial mindset — guilty until proven exceptional.

## Plan File
Read this file: <PLAN_FILE_PATH>

## Validated Spec (what was agreed with the user)
<SPEC_SUMMARY>

## Review Criteria (derived from project context)

Apply these project-specific criteria as your evaluation framework:

<REVIEW_CRITERIA>

## Reference Skills

Read these for full stack-specific guidance to inform your review:
<SAME SKILL FILE PATHS AS PLANNER>

## Source Files to Read (you MUST read these independently — do NOT trust the plan's claims about them)
<SAME FILE LIST AS PLANNER>

## Review Methodology

Apply the critical-code-reviewer approach: adversarial, thorough, zero tolerance for hand-waving.

1. Compare proposed function code against actual source code LINE BY LINE
2. Check every type contract, method dispatch, guard condition against actual code structures
3. Verify data flow: does each step's output match the next step's expected input?
4. Check for behavioral regressions: does the proposed code produce identical results to current code?
5. Verify API boundary contracts are correctly stated
6. Look for missing edge cases
7. Check convention compliance (naming, patterns, style)
8. Evaluate against EACH review criterion above — flag gaps explicitly

## Output Format

Use severity tiers:
- **BLOCKING**: Must fix before plan can proceed. Incorrect logic, wrong API contracts, missing critical steps.
- **REQUIRED**: Significant issues. Convention violations, missing edge cases, incomplete type contracts.
- **SUGGESTION**: Improvements. Better naming, cleaner structure, additional test cases.

For each issue:
- **Severity**: BLOCKING / REQUIRED / SUGGESTION
- **Location**: plan section + source file:line reference
- **Problem**: what's wrong
- **Fix**: specific suggested fix

End with verdict: **READY** or **NEEDS FIXES** (list which BLOCKING and REQUIRED issues must be fixed)
```

### Step 4: Apply Fixes

If the reviewer says **NEEDS FIXES**:
1. Read the review carefully
2. Apply ALL BLOCKING and REQUIRED fixes to the plan file (you wrote the plan — you understand the reasoning behind each decision, so you can apply fixes intelligently, not mechanically)
3. Go back to Step 3 — dispatch the reviewer again, adding to its prompt: "This is review round N. Verify previous fixes are correctly applied. Also look for NEW issues that the fixes may have introduced."
4. Repeat until the reviewer says **READY** or you reach 3 review rounds

If not READY after 3 rounds, add a `## Known Issues` section to the plan with remaining items.

### Step 5: Save Final Review

Write the final review to: `<ARTIFACTS_DIR>/<date>-<task-slug>-review.md`

### Step 6: Report

Report back with EXACTLY this format:
- Status: done / stuck (with reason)
- Plan file: <path>
- Review file: <path>
- Review rounds: N
- Final verdict: READY / ISSUES REMAINING (count)
````

### Orchestrator During Phase 2

While planner-reviewer agents work:
- Do NOT read the full plans — rely on agent status reports
- Report progress to the user as results come in: "Task A: done after 2 review rounds. Task B: still running."

---

## Phase 3: Report

Print a summary:

```
| Task | Plan | Review | Rounds | Verdict |
|------|------|--------|--------|---------|
| <name> | <path> | <path> | N | Ready / Issues |
```

Plus: total artifact count, any tasks needing human attention, and suggested next steps (e.g., "review the plans, then use /implementing-team to execute").

---

## Rules

- **Brainstorming is non-negotiable** — Phase 1 ALWAYS happens before any plan dispatch
- **One question at a time** — never batch questions during brainstorming
- **Review criteria are derived JIT** — synthesized from discovered skills, project docs, and brainstorming context; never hardcoded or assumed
- **Planners and reviewers are Opus** — thorough reasoning required
- **Planner revises its own plan** — it has the context of WHY each decision was made
- **Reviewer MUST read source code independently** — not just the plan
- **Reviewer uses critical-code-reviewer methodology** — adversarial mindset, severity tiers (BLOCKING > REQUIRED > SUGGESTION)
- **Review is iterated** — loop until READY, max 3 rounds
- **LINE BY LINE is the standard** — the reviewer compares proposed code against actual source
- **Orchestrator stays lean after Phase 1** — don't read plan contents during Phase 2
- **Final review persisted** — saved to disk alongside the plan for traceability
- **Artifacts are permanent** — written to `~/.artifacts/<project>/plans/`, never ephemeral
- **Sequential mode chains context** — each agent gets the previous task's plan path as "Prior work"
- **Never start implementing** — this command produces plans only
