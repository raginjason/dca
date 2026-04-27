You are closing a planning session. Your job is to produce a structured, approved plan and export it to STANDALONE_PLAN.md so it survives the context boundary into an unattended dca session.

## Step 1 — Read context

Read the following if they exist:
- OUTCOME.md — what happened in the last execution session (completed work, discoveries, blockers, partial progress)
- STANDALONE_PLAN.md — previous plans, for continuity

## Step 2 — Draft the plan

Produce a structured plan for the upcoming execution session. The plan must be specific enough that Claude Code can execute it unattended — no ambiguous requirements, no unresolved decisions, no judgment calls left to the executor.

Before finalizing, identify and resolve:
- Ambiguous requirements or underspecified behavior
- File paths, names, or locations that haven't been confirmed
- Decisions where multiple approaches are valid and none has been chosen
- Anything that depends on runtime state Claude Code can't observe from the repo
- Edge cases that haven't been addressed

If any ambiguities exist, ask them now. Do not finalize until every question is answered.

Present the completed plan inline using the format below, then ask:

**Save this DCA plan? (yes / revise)**

## Plan — $DATE $TIME

### Goal
The specific desired end state of the execution session. Concrete enough that Claude Code can verify when it is done. If resuming, state explicitly what remains.

### Decisions
Every decision made during planning that Claude Code must honor, with reasoning. If a decision responds to something in OUTCOME.md, say so.

### Steps
An ordered list of specific steps to execute. Detailed enough that Claude Code does not need to infer intent or make judgment calls. If resuming, omit steps already completed in OUTCOME.md.

### Relevant Files
Files that will need to change or be read, with a one-line note on why each matters.

### Constraints
Anything Claude Code must not do, must preserve, or must work around. Be explicit — if it is not listed here, Claude Code may do it.

---

This file is the sole context for an unattended Claude Code session. If it is ambiguous, execution will go wrong.

## Step 3 — Save to STANDALONE_PLAN.md

Once the user confirms, append the plan as a new timestamped section to STANDALONE_PLAN.md at the repo root. Do not overwrite existing content.

Then tell the user:

**Plan saved to STANDALONE_PLAN.md. Run `dca run .` from your terminal to execute, or `/dca:implement` if running Claude Code CLI directly.**
