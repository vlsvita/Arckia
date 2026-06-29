#!/usr/bin/env bash
# Archive oldest ADR RECENT entries — manual confirmation required (unless --yes).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/constants.sh
source "$SCRIPT_DIR/lib/constants.sh"

ROOT="."
DRY_RUN=0
YES=0

usage() {
  cat <<EOF
Usage: fossilize.sh [options]

Archives the oldest RECENT DECISIONS entries when ADR.md exceeds ${ADR_FOSSILIZE_TRIGGER} lines.
One run archives up to ${ADR_BATCH_SIZE} entries (gradual, not cliff).

Options:
  --root PATH   Project root (default: .)
  --dry-run     Preview archive targets without writing
  --yes         Skip interactive confirmation (use only after manual review)
  -h, --help    Show this help

Example:
  bash scripts/fossilize.sh --dry-run
  bash scripts/fossilize.sh --yes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$ROOT" && pwd)"
ADR="$ROOT/docs/architecture/ADR.md"
ARCHIVE_DIR="$ROOT/docs/architecture/archive"

if [[ ! -f "$ADR" ]]; then
  echo "Error: missing $ADR" >&2
  exit 1
fi

adr_non_empty() {
  grep -cve '^\s*$' "$ADR" || true
}

lines=$(adr_non_empty)
if (( lines <= ADR_FOSSILIZE_TRIGGER )); then
  echo "ADR.md has ${lines} non-empty lines (fossilize triggers above ${ADR_FOSSILIZE_TRIGGER}). Nothing to do."
  exit 0
fi

recent_tmp="$(mktemp)"
grep -E '^- \[[0-9]{4}-[0-9]{2}\]' "$ADR" > "$recent_tmp" || true
total_recent=$(wc -l < "$recent_tmp" | tr -d ' ')

if (( total_recent == 0 )); then
  echo "Error: ADR exceeds line limit but no RECENT DECISIONS entries found." >&2
  rm -f "$recent_tmp"
  exit 1
fi

archive_count=$ADR_BATCH_SIZE
if (( archive_count > total_recent )); then
  archive_count=$total_recent
fi

archive_lines_tmp="$(mktemp)"
head -n "$archive_count" "$recent_tmp" > "$archive_lines_tmp"

month="$(date +%Y-%m)"
first_line="$(head -n 1 "$archive_lines_tmp")"
slug="batch"
if [[ "$first_line" =~ \[([A-Z0-9_]+)\] ]]; then
  slug="$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
fi
archive_file="$ARCHIVE_DIR/${month}-fossilize-${slug}-$(date +%s).md"

echo "ADR.md: ${lines} non-empty lines (trigger: > ${ADR_FOSSILIZE_TRIGGER})"
echo "Will archive ${archive_count} oldest RECENT entr$( (( archive_count == 1 )) && echo y || echo ies ):"
while IFS= read -r entry; do
  echo "  - $entry"
done < "$archive_lines_tmp"
echo "Target archive file: $archive_file"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "(dry-run — no files changed)"
  rm -f "$recent_tmp" "$archive_lines_tmp"
  exit 0
fi

if [[ $YES -eq 0 ]]; then
  read -r -p "Archive ${archive_count} entries? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    rm -f "$recent_tmp" "$archive_lines_tmp"
    exit 0
  fi
fi

mkdir -p "$ARCHIVE_DIR"
{
  echo "# Archived ADR entries — ${month}"
  echo ""
  echo "Fossilized manually via fossilize.sh (ADR exceeded ${ADR_FOSSILIZE_TRIGGER} lines)."
  echo ""
  cat "$archive_lines_tmp"
} > "$archive_file"

remove_tmp="$(mktemp)"
while IFS= read -r line; do
  echo "$line"
done < "$archive_lines_tmp" > "$remove_tmp"

tmp_adr="$(mktemp)"
awk -v remove_file="$remove_tmp" '
  BEGIN {
    while ((getline line < remove_file) > 0) remove[line] = 1
    close(remove_file)
    in_recent = 0
  }
  /^## RECENT DECISIONS/ { in_recent = 1; print; next }
  in_recent && /^## / { in_recent = 0 }
  in_recent && /^- \[[0-9]{4}-[0-9]{2}\]/ {
    if (!remove[$0]) print
    next
  }
  { print }
' "$ADR" > "$tmp_adr"
mv "$tmp_adr" "$ADR"

new_lines=$(adr_non_empty)
echo "Fossilized → $archive_file"
echo "ADR.md now: ${new_lines} non-empty lines (target: <= ${ADR_TARGET_LINES})"

if (( new_lines > ADR_FOSSILIZE_TRIGGER )); then
  echo "Hint: run fossilize.sh again if still above ${ADR_FOSSILIZE_TRIGGER} lines."
fi

rm -f "$recent_tmp" "$archive_lines_tmp" "$remove_tmp"

bash "$SCRIPT_DIR/validate.sh" "$ROOT"
