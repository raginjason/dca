You are beginning or resuming an unattended execution session. STANDALONE_PLAN.md contains a fully resolved plan — do not ask questions, do not pause for confirmation. Read the files, reconcile state, and execute.

## Step 1 — Read and reconcile

Read STANDALONE_PLAN.md to understand the goal, decisions, constraints, and suggested first steps.

If OUTCOME.md exists, read it to determine:
- What has already been completed
- What was in progress or partially done
- What was blocked and why
- Any discoveries that affect the approach

Reconcile the two files: identify what is done, what can be resumed, and what still needs to start. If resuming after a crash or interruption, pick up from the furthest safe point — do not redo completed work.

## Step 2 — Write an opening entry to OUTCOME.md

Append to OUTCOME.md (create it if it does not exist). Do not overwrite existing content.

Write a session header:

## Session — $DATE $TIME

### Resuming From
[If this is a fresh start: "New session". If resuming: brief note on what state was found in OUTCOME.md and where execution is picking up.]

### Plan
[One or two sentences on what this session intends to accomplish, given the current state.]

## Step 3 — Execute

Work through the plan. As you go, append brief notes to OUTCOME.md: completions, discoveries, decisions made during execution, anything that diverges from the plan.

Keep notes factual and terse — they are inputs to the next planning session, not a log.

## Step 4 — Write a closing summary when work is complete

When the session's work is done, append a closing block to the current session section in OUTCOME.md:

### Completed
What was actually finished. Reference specific files changed, problems solved, commands that now work.

### Diverged From Plan
Anything that changed from the plan and why — unexpected complexity, wrong assumption, better approach found.

### Blocked
What could not be completed and why. Include error messages or decisions that need human input.

### Discoveries
Anything learned that the planner should know — about the codebase, the approach, or the problem.

### Next Steps
What should happen next, in order. Written for the planner.
