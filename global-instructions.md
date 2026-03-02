## LLM Agent Workflow

### The Development Loop

```
┌─────────────────────────────────────────────────────────┐
│ 1. READ DOCS (if exist)                                 │
│    └─ macro plan / implementation log / codebase map    │
├─────────────────────────────────────────────────────────┤
│ 2. CREATE BRANCH                                        │
│    └─ git checkout -b <feature/fix/docs>/<description>  │
├─────────────────────────────────────────────────────────┤
│ 3. CREATE PHASE PLAN                                    │
│    └─ plans/phase-X.X-name.md (detailed tasks, tests)   │
├─────────────────────────────────────────────────────────┤
│ 4. IMPLEMENT (TDD)                                      │
│    └─ Write tests first → code → test → review          │
├─────────────────────────────────────────────────────────┤
│ 5. COMMIT OFTEN                                         │
│    └─ Clear commit messages / smallest working commits  │
├─────────────────────────────────────────────────────────┤
│ 6. PUSH & CREATE PR                                     │
│    └─ Push when done -> Open PR → wait for human review │
├─────────────────────────────────────────────────────────┤
│ 7. UPDATE DOCS (after human approval) e.g :             │
│    ├─ implementation logs                               │
│    └─ codebase map                                      │
└─────────────────────────────────────────────────────────┘
        │                                        │
        └────────── Loop back to step 1 ─────────┘
```

### The Team

- The orchestrator is the one speaking to the human. His role is to dispatch agents and preserve his context window as much as possible. He is the safekeeper of the session goals.
- The orchestrator relies as much as possible on sub-agents, even other orchestrators, to preserve his context window

### Quick Development Steps

1. Read task requirements from a plan. **Have the human create one if there is none !**

**IF `task-X-plan.md` (detailed implementation plan for task X) DOESN'T EXIST:**

1. Create detailed implementation plan in `task-X-plan.md`
2. Commit with a detailed message to a branch (never to main)
3. Push branch and create PR for human review

Dispatch a *planning-specialist* agent for this task

**IF `task-X-plan.md` for the current task ALREADY EXISTS:**

1. Create TodoWrite list with specific subtasks and move to a branch
2. Write unit tests for core functionality first
3. Implement code, run the test suite after each new code addition
4. Verify all exit/success criteria and definition of done met
5. Commit often with conventional commit messages (WHY over HOW/WHAT)
6. Push branch and create PR for human review

Dispatch a *coding-specialist* agent for this task

### Long-Running Tasks

For any task that blocks progress (e.g., deployment, long builds):

1. **Do NOT run it yourself** - it will timeout or block progress
2. **Provide the command** to the human with clear instructions
3. **Wait for feedback** - the human will run it and report results
4. **Complete all your other independent work before handing off**
5. **Continue based on results** - adjust approach if needed

Example:

```
I've committed and pushed the changes. Please deploy by running:

    ./deploy.sh

And let me know when it's complete.
```

### Completion Protocol

- When working on a new phase/task independent of the previous one, create a new dedicated branch
- The human in the loop is responsible for reviewing your work through the PRs
- ALWAYS push to feature/fix/docs branches, NEVER directly to main

## Artifact Storage

When producing non-code outputs (plans, research, session notes, design
docs, ADRs, evaluations), save them to the artifacts directory that is
mounted alongside this project. It is the additional directory under
~/.akm/artifacts/<$REPO>/ visible via your file access.

Directory conventions inside the artifacts folder:

- plans/       → Implementation plans, architecture decisions (prefix: YYYY-MM-DD-)
- research/    → Technology evaluations, deep research
- sessions/    → Session summaries and handoff notes
- prompts/     → Reusable prompt templates
- archive/     → Completed/superseded items (moved here, never deleted, by archive-artifact)

Never save plans, research, or session notes inside the working repository.
