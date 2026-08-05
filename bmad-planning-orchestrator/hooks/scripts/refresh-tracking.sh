#!/bin/bash
# BMAD Daily Pulse — idempotent tracking refresh
# Regenerates todo.md and open-questions.md from current project state.
# Scaffolds manual-notes.md and daily-log.md if missing (never overwrites them).
# Safe to run repeatedly: running twice in a row with no state change produces
# byte-identical todo.md / open-questions.md.
#
# Usage: refresh-tracking.sh [project-dir]   (default: current directory)
# Recognizes BOTH output-folder conventions used across projects:
#   - nested:  <project>/bmad-output/project-context.md
#   - root:    <project>/project-context.md   (config.yaml paths.output_folder: ".")

set -u
PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" || exit 0

resolve_output_folder() {
  if [ -f "bmad-output/project-context.md" ]; then
    echo "bmad-output"
  elif [ -f "project-context.md" ]; then
    echo "."
  else
    echo ""
  fi
}

OUT="$(resolve_output_folder)"
[ -z "$OUT" ] && exit 0   # not a BMAD project — stay silent

PROJECT_NAME=$(grep -m1 'name:' "$OUT/config.yaml" 2>/dev/null | head -1 | sed -E 's/^[^:]+:\s*"?([^"]*)"?\s*$/\1/')
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$(pwd)")

STORIES_DIR="$OUT/stories"
TODO_FILE="$OUT/todo.md"
QUESTIONS_FILE="$OUT/open-questions.md"
NOTES_FILE="$OUT/manual-notes.md"
LOG_FILE="$OUT/daily-log.md"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Scaffold manual-notes.md (created once, never overwritten again) ---
if [ ! -f "$NOTES_FILE" ]; then
  {
    echo "# Manual Notes — ${PROJECT_NAME}"
    echo ""
    echo "Your own notes and tasks. Nothing here is auto-generated or auto-removed —"
    echo "add anything that needs to be tracked but can't be automated. Every"
    echo "tracking refresh reads this file and folds it into todo.md as context."
    echo ""
    echo "## Notes / tasks"
    echo ""
    echo "- "
  } > "$NOTES_FILE"
fi

# --- Scaffold daily-log.md header (created once, appended to daily by the daily-pulse run) ---
if [ ! -f "$LOG_FILE" ]; then
  {
    echo "# Daily Log — ${PROJECT_NAME}"
    echo ""
    echo "A dated history of what still needed doing, appended once per day by the daily pulse run."
    echo ""
  } > "$LOG_FILE"
fi

story_field() { # $1 = file, $2 = field label e.g. 'Status:' or 'Story ID:'
  grep -m1 "\*\*$2\*\*" "$1" 2>/dev/null | sed -E "s/^\*\*$2\*\*\s*//" | sed -E 's/\s*<!--.*$//' | sed -E 's/\s+$//'
}
story_title() {
  grep -m1 '^# ' "$1" 2>/dev/null | sed -E 's/^# [^:]+:\s*//'
}

# --- Build todo.md (fully regenerated every run — idempotent) ---
{
  echo "# Todo — ${PROJECT_NAME}"
  echo ""
  echo "_Auto-generated ${TS} — regenerated after every BMAD run. Edit manual-notes.md, not this file; edits here will be overwritten._"
  echo ""
  echo "## Next steps"
  echo ""

  NEXT_COUNT=0
  READY=0; INPROG=0; REVIEW=0; BACKLOG=0; DONE=0; CANCELLED=0
  if [ -d "$STORIES_DIR" ]; then
    for f in "$STORIES_DIR"/*.story.md; do
      [ -e "$f" ] || continue
      STATUS=$(story_field "$f" "Status:")
      TITLE=$(story_title "$f")
      SID=$(story_field "$f" "Story ID:")
      case "$STATUS" in
        ready-for-dev)
          echo "- **Next:** hand off \"${TITLE}\" (story ${SID}) to the dev team"
          NEXT_COUNT=$((NEXT_COUNT+1)); READY=$((READY+1)) ;;
        in-progress)
          echo "- **In progress:** \"${TITLE}\" (story ${SID})"
          NEXT_COUNT=$((NEXT_COUNT+1)); INPROG=$((INPROG+1)) ;;
        review)
          echo "- **In review:** \"${TITLE}\" (story ${SID}) — check for feedback"
          NEXT_COUNT=$((NEXT_COUNT+1)); REVIEW=$((REVIEW+1)) ;;
        backlog) BACKLOG=$((BACKLOG+1)) ;;
        done) DONE=$((DONE+1)) ;;
        cancelled) CANCELLED=$((CANCELLED+1)) ;;
      esac
    done
  fi
  [ "$NEXT_COUNT" -eq 0 ] && echo "_Nothing currently ready-for-dev, in-progress, or in review._"

  echo ""
  echo "## Planned, not yet started"
  echo ""
  BACKLOG_COUNT=0
  if [ -d "$STORIES_DIR" ]; then
    for f in "$STORIES_DIR"/*.story.md; do
      [ -e "$f" ] || continue
      STATUS=$(story_field "$f" "Status:")
      if [ "$STATUS" = "backlog" ]; then
        TITLE=$(story_title "$f")
        SID=$(story_field "$f" "Story ID:")
        echo "- \"${TITLE}\" (story ${SID})"
        BACKLOG_COUNT=$((BACKLOG_COUNT+1))
      fi
    done
  fi
  [ "$BACKLOG_COUNT" -eq 0 ] && echo "_Nothing in backlog._"

  if [ -f "$NOTES_FILE" ]; then
    NOTE_LINES=$(grep -E '^- .+' "$NOTES_FILE" 2>/dev/null | grep -v '^- $' || true)
    if [ -n "$NOTE_LINES" ]; then
      echo ""
      echo "## From your manual notes"
      echo ""
      echo "$NOTE_LINES"
    fi
  fi

  if [ -d "$STORIES_DIR" ]; then
    echo ""
    echo "## Overall story count"
    echo ""
    echo "- Ready for dev: ${READY}"
    echo "- In progress: ${INPROG}"
    echo "- In review: ${REVIEW}"
    echo "- Backlog: ${BACKLOG}"
    echo "- Done: ${DONE}"
    [ "$CANCELLED" -gt 0 ] && echo "- Cancelled: ${CANCELLED}"
  fi
} > "$TODO_FILE"

# --- Build open-questions.md from addendum.md's "Open Questions" table (fully regenerated every run) ---
{
  echo "# Open Questions — ${PROJECT_NAME}"
  echo ""
  echo "_Auto-generated ${TS}. Answered questions move to decision-log.md._"
  echo ""

  FOUND=0
  ADDENDUM="$OUT/addendum.md"
  if [ -f "$ADDENDUM" ]; then
    # Extract the Open Questions table: rows between the "## Open Questions" heading
    # and the next "## " heading, matching "| Q<n> | ... |" and still marked Open.
    awk '/^## Open Questions/{flag=1; next} /^## /{flag=0} flag' "$ADDENDUM" \
      | grep -E '^\| *Q[0-9]+ *\|' \
      | while IFS='|' read -r _ qnum question owner needed status _; do
          STATUS_TRIMMED=$(echo "$status" | sed -E 's/^\s+|\s+$//g')
          case "$(echo "$STATUS_TRIMMED" | tr '[:upper:]' '[:lower:]')" in
            open*)
              QNUM_T=$(echo "$qnum" | sed -E 's/^\s+|\s+$//g')
              Q_T=$(echo "$question" | sed -E 's/^\s+|\s+$//g')
              OWNER_T=$(echo "$owner" | sed -E 's/^\s+|\s+$//g')
              NEEDED_T=$(echo "$needed" | sed -E 's/^\s+|\s+$//g')
              echo "- **${QNUM_T}:** ${Q_T} _(owner: ${OWNER_T}; needed by: ${NEEDED_T})_"
              ;;
          esac
        done
  fi > /tmp/_oq_rows.$$
  if [ -s /tmp/_oq_rows.$$ ]; then
    cat /tmp/_oq_rows.$$
    FOUND=1
  fi
  rm -f /tmp/_oq_rows.$$

  [ "$FOUND" -eq 0 ] && echo "_No open questions currently marked Open in addendum.md._"
} > "$QUESTIONS_FILE"

exit 0
