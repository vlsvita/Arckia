#!/usr/bin/env bash
# Deterministic sub_append_adr — run only after explicit user confirmation (완료/확정).
set -euo pipefail

ROOT="."
MATCH=""
RATIONALE=""
DOMAIN=""
DRY_RUN=0
REMOVE=0

usage() {
  cat <<EOF
Usage: consolidate.sh --match "<fragment>" --rationale "<why>" [options]

Moves a verified ROADMAP item into ADR RECENT DECISIONS. User verification is manual —
run this only after the user confirms completion (완료/확정).

Options:
  --root PATH       Project root (default: .)
  --match TEXT      Substring to find the ROADMAP SHORT-TERM item (required)
  --rationale TEXT  Design rationale for ADR entry (required)
  --domain TAG      Domain tag e.g. AUTH (default: parsed from [TAG] in item)
  --dry-run         Show changes without writing
  --remove          Remove ROADMAP line instead of marking [x]
  -h, --help        Show this help

Example:
  bash scripts/consolidate.sh --match "OAuth2" --rationale "E2E tests passed, prod deployed"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --match) MATCH="$2"; shift 2 ;;
    --rationale) RATIONALE="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --remove) REMOVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$MATCH" || -z "$RATIONALE" ]]; then
  echo "Error: --match and --rationale are required." >&2
  usage >&2
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"
ROADMAP="$ROOT/docs/architecture/ROADMAP.md"
ADR="$ROOT/docs/architecture/ADR.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/constants.sh
source "$SCRIPT_DIR/lib/constants.sh"

if [[ ! -f "$ROADMAP" || ! -f "$ADR" ]]; then
  echo "Error: missing ROADMAP.md or ADR.md under docs/architecture/" >&2
  exit 1
fi

matched_line=""
matched_num=0
in_short=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^##\ SHORT-TERM ]]; then
    in_short=1
    continue
  fi
  if [[ $in_short -eq 1 && "$line" =~ ^##\  ]]; then
    break
  fi
  if [[ $in_short -eq 1 && "$line" == *"$MATCH"* && "$line" =~ ^-\ \[\ \] ]]; then
    matched_line="$line"
    matched_num=$((matched_num + 1))
  fi
done < "$ROADMAP"

if [[ $matched_num -eq 0 ]]; then
  echo "Error: no unchecked ROADMAP item matching: $MATCH" >&2
  exit 1
fi
if [[ $matched_num -gt 1 ]]; then
  echo "Error: multiple unchecked items match '$MATCH'. Use a more specific --match." >&2
  exit 1
fi

rest=""
if [[ "$matched_line" =~ ^-\ \[( |x)\]\ (.+)$ ]]; then
  rest="${BASH_REMATCH[2]}"
else
  echo "Error: could not parse ROADMAP item format." >&2
  exit 1
fi

if [[ -z "$DOMAIN" && "$rest" =~ ^\[([A-Z0-9_]+)\][[:space:]]*(.*)$ ]]; then
  DOMAIN="${BASH_REMATCH[1]}"
  description="${BASH_REMATCH[2]}"
else
  description="$rest"
fi

if [[ -z "$DOMAIN" ]]; then
  echo "Error: could not parse domain tag. Pass --domain explicitly." >&2
  exit 1
fi

month="$(date +%Y-%m)"
adr_entry="- [${month}] [${DOMAIN}] ${description} (이유: ${RATIONALE})"

echo "ROADMAP match: $matched_line"
echo "ADR entry:     $adr_entry"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "(dry-run — no files changed)"
  exit 0
fi

tmp_roadmap="$(mktemp)"
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "$matched_line" ]]; then
    if [[ $REMOVE -eq 0 ]]; then
      echo "${matched_line/\[ \]/[x]}"
    fi
  else
    echo "$line"
  fi
done < "$ROADMAP" > "$tmp_roadmap"
mv "$tmp_roadmap" "$ROADMAP"

tmp_adr="$(mktemp)"
appended=0
while IFS= read -r line || [[ -n "$line" ]]; do
  echo "$line"
  if [[ $appended -eq 0 && "$line" =~ ^##\ RECENT\ DECISIONS ]]; then
    echo "$adr_entry"
    appended=1
  fi
done < "$ADR" > "$tmp_adr"

if [[ $appended -eq 0 ]]; then
  echo "" >> "$tmp_adr"
  echo "## RECENT DECISIONS" >> "$tmp_adr"
  echo "$adr_entry" >> "$tmp_adr"
fi
mv "$tmp_adr" "$ADR"

non_empty=$(grep -cve '^\s*$' "$ADR" || true)
if (( non_empty > ADR_FOSSILIZE_TRIGGER )); then
  echo "WARN: ADR.md has ${non_empty} non-empty lines (fossilize triggers above ${ADR_FOSSILIZE_TRIGGER})."
  echo "      Run: bash scripts/fossilize.sh --dry-run"
elif (( non_empty > ADR_WARN_LINES )); then
  echo "WARN: ADR.md has ${non_empty} non-empty lines (approaching fossilize threshold ${ADR_FOSSILIZE_TRIGGER})."
fi

echo "Consolidation complete."
bash "$SCRIPT_DIR/validate.sh" "$ROOT"
