# Changelog

All notable changes to the **BMAD Planning & Orchestrator** plugin are recorded
here. The plugin tracks the **BMAD Method v6.x** by the BMAD Code Organization;
each release notes the upstream line it follows.

## [0.6.0] — 2026-08-05

### Added
- **`bmad-todo` skill** and `hooks/scripts/refresh-tracking.sh`: idempotent,
  plain-language tracking refresh per project. Regenerates `todo.md` (next
  steps derived from story statuses, backlog, and manual notes) and
  `open-questions.md` (from `addendum.md`'s Open Questions table) on every
  run; scaffolds `manual-notes.md` (user-owned, never overwritten) and
  `daily-log.md` (header only — appended to by a separate daily-report
  workflow) on first run. Recognizes both the nested (`bmad-output/`) and
  root-level output-folder conventions.
- Wired `refresh-tracking.sh` into the `Stop` hook (alongside the existing
  `suggest-next.sh`), so tracking files stay fresh after every BMAD skill run
  without manual invocation.

## [0.5.0] — 2026-06-19

Initial public preview of the Claude Code **plugin** (pre-1.0). Tracks upstream
**BMAD Method v6.x** (skills-centric architecture, scale-adaptive tracks,
three-intent planning, decision log, two-document UX, SPEC kernel).

### Added
- Plugin packaging: `.claude-plugin/plugin.json` + marketplace
  (`bmad-method-harness`); install via `/plugin marketplace add` →
  `/plugin install`.
- **Orchestration spine:** `bmad-help` (next-step router), `bmad-init` (track
  selection, workspace, `decision-log.md`, `project-context.md`).
- **Analysis:** `bmad-brainstorm`, `bmad-research`, `bmad-product-brief`
  (Create/Update/Validate), `bmad-prfaq`, `bmad-spec`.
- **Planning:** `bmad-prd` (Create/Update/Validate; `prd.md` + `addendum.md` +
  `decision-log.md`), `bmad-tech-spec`.
- **Solutioning:** `bmad-ux` (two-document `DESIGN.md` + `EXPERIENCE.md`),
  `bmad-architecture` (ADRs, NFR coverage, semantic-conflict prevention),
  `bmad-epics-and-stories` (compiled-context stories with Owned File/Module
  Scope), `bmad-readiness-check` (PASS/CONCERNS/FAIL gate).
- **Orchestration & handoff:** `bmad-sprint-planning` (sequencing-only
  `sprint-status.yaml`), `bmad-parallel-plan` (dependency DAG → conflict-free
  waves), `bmad-handoff` (tool-agnostic `handoff-manifest.json`).
- **Cross-phase & meta:** `bmad-correct-course`, `bmad-investigate`,
  `bmad-document-project`, `bmad-builder`.
- Planning subagents (`story-author`, `epic-scoper`, `readiness-auditor`),
  next-step hooks, shared scripts (incl. `scope-conflict-check.sh`), and resource
  guides (`story-sizing-guide`, `track-selection-guide`,
  `conflict-avoidance-guide`, `bmad-method-mapping`).

### Changed
- Refocused the project to **planning and orchestration only**. Right-sizing now
  uses **tracks** (Quick Flow / BMad Method / Enterprise) instead of numbered
  Levels 0–4.
- Story sizing is **one-dev-day decomposition** with **count-based delivery**.

### Removed
- All **development execution**: the `developer` skill, the `/dev-story`
  workflow, and lint/coverage/pre-commit helpers. Implementation is handed off
  to external dev tools.
- **Fibonacci story points, velocity, and burndown** tracking.
- The `install-v6.sh` / `install-v6.ps1` installers (replaced by marketplace
  install) and the dual `bmad-v6/` + `bmad-skills/` source trees (collapsed into
  one plugin).

See [`../MIGRATION.md`](../MIGRATION.md) for upgrade steps.
