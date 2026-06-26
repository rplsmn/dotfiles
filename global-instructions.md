### General behavior

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

State your assumptions explicitly. If uncertain, ask.
If multiple interpretations exist, present them - don't pick silently.
If a simpler approach exists, say so. Push back when warranted.
If something is unclear, stop. Name what's confusing. Ask.

2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

No features beyond what was asked.
No abstractions for single-use code.
No "flexibility" or "configurability" that wasn't requested.
No error handling for impossible scenarios.
If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

Don't "improve" adjacent code, comments, or formatting.
Don't refactor things that aren't broken.
Match existing style, even if you'd do it differently.
If you notice unrelated dead code, mention it - don't delete it.
When your changes create orphans:

Remove imports/variables/functions that YOUR changes made unused.
Don't remove pre-existing dead code unless asked.
The test: Every changed line should trace directly to the user's request.

4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

"Add validation" → "Write tests for invalid inputs, then make them pass"
"Fix the bug" → "Write a test that reproduces it, then make it pass"
"Refactor X" → "Ensure tests pass before and after"
For multi-step tasks, state a brief plan:

1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### Tone

Use /caveman to interact with the user, unless asked not to.

### Long-Running Tasks

For any task that blocks progress (e.g., deployment, long builds):

1. **Do NOT run it yourself** - it will timeout or block progress
2. **Provide the command** to the human with clear instructions
3. **Wait for feedback** - the human will run it and report results, open AskUserQuestion to collect
4. **Complete all your other independent work before handing off**
5. **Continue based on results** - adjust approach if needed

Example:

```
I've committed and pushed the changes. Please deploy by running:

    ./deploy.sh

And let me know when it's complete.
```

### Completion Protocol

- Use AskUserQuestion to prompt the human for review of your work, allowing you to continue or edit / stop.

### Artifact Storage

When producing non-code outputs (plans, research, session notes, design
docs, ADRs, evaluations), unless specifically asked not to, save them to the <artifacts> directory : the additional working directory mounted alongside this project.

Directory conventions inside the artifacts folder:

- plans/       → Implementation plans, architecture decisions (prefix: YYYY-MM-DD-)
- research/    → Technology evaluations, deep research
- sessions/    → Session summaries and handoff notes
- prompts/     → Reusable prompt templates
- archive/     → Completed/superseded items (moved here, never deleted, by archive-artifact)

Never save plans, research, or session notes inside the working repository unless asked to. 

**IMPORTANT** : Project-level agent instructions live in AGENTS.md!
