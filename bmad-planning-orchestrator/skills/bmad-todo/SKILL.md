---
name: bmad-todo
description: |
  Refreshes a project's plain-language tracking files — todo.md and open-questions.md — from current planning state (story statuses, addendum.md's Open Questions table), and scaffolds manual-notes.md and daily-log.md if they don't exist yet. Idempotent: running it twice with no state change produces identical output. Also runs automatically after every BMAD skill via the Stop hook, so manual invocation is only needed to refresh on demand (e.g. mid-session, or against a project the current session isn't already in). Use when the user says "refresh my todo list", "what are my next steps", "show open questions", "update the tracking files", "regenerate todo.md", or "what still needs to be done on this project".
allowed-tools: Bash, Read
---

# BMAD Todo — Tracking Refresh

Regenerates a project's plain-language next-steps list and open-questions tracker from
current planning state. Produces no new planning decisions — it only reflects what
already exists in `stories/*.story.md`, `addendum.md`, and the project's own
`manual-notes.md`.

**This skill produces no planning documents of its own.** It reads existing artifacts
and regenerates two derived views (`todo.md`, `open-questions.md`), plus scaffolds two
files intended for manual/append use (`manual-notes.md`, `daily-log.md`).

## When to use

- User asks "what's next", "what do I still need to do", "show my open questions", or
  wants tracking refreshed on demand.
- Automatically fires after every BMAD skill run via the plugin's `Stop` hook — you
  normally don't need to invoke this directly unless refreshing a project outside the
  current session's working directory, or checking on demand mid-session.

## How it works

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/refresh-tracking.sh [project-dir]
```

Defaults to the current directory. Recognizes both output-folder conventions used
across projects: nested (`bmad-output/project-context.md`) and root-level
(`project-context.md`, when `config.yaml`'s `paths.output_folder` is `.`). Exits
silently if the target directory isn't a BMAD project (no `project-context.md` found
either way) — safe to run speculatively.

**What it regenerates every run (idempotent — safe to overwrite):**
- `todo.md` — plain-language next steps, derived from story `Status:` fields
  (`ready-for-dev` → "hand off to the dev team", `in-progress`, `review`), a backlog
  list, an overall story-count summary, and anything found in `manual-notes.md`.
- `open-questions.md` — questions still marked `Open` (or `Open, deferred`) in
  `addendum.md`'s `## Open Questions` table. Once a question is answered, move it
  into `decision-log.md` per that file's normal entry format — the next refresh will
  stop listing it here.

**What it scaffolds once and never touches again:**
- `manual-notes.md` — the user's own notes and tasks. Created empty on first run;
  every later refresh reads it but never rewrites or removes its content.
- `daily-log.md` — header created on first run. A separate daily-report workflow
  (not this skill) appends dated entries here; this skill does not append to it.

## Notes for Claude

- Never edit `todo.md` or `open-questions.md` by hand — regenerate them by running the
  script; anything written there manually will be overwritten on the next refresh.
- Never overwrite `manual-notes.md`. If the user wants to add a note or task, append a
  new `- ` line under its `## Notes / tasks` section instead of rewriting the file.
- Jira/Slack/GitHub activity aggregation is a separate, not-yet-built workflow
  (`activity-log.md`) — this skill only covers local, file-based tracking. Do not
  attempt to pull external data here.
- If asked to run this across every project in a vault/workspace rather than just the
  current directory, loop the script over each project folder found (one that has
  `project-context.md`, at root or under `bmad-output/`).

> ---
> Part of the **BMAD Planning & Orchestrator** plugin — a Claude Code harness for the **BMAD Method** by the **BMAD Code Organization** (https://github.com/bmad-code-org/BMAD-METHOD).
