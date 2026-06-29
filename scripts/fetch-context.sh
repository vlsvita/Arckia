#!/usr/bin/env bash
# Deterministic sub_fetch_context — requires explicit --domain (no LLM tag inference).
set -euo pipefail

ROOT="."
DOMAIN=""
QUERY=""

usage() {
  cat <<EOF
Usage: fetch-context.sh --domain TAG [options]

Outputs a markdown context bundle for architecture work (VISION + sliced ROADMAP/ADR).

Options:
  --root PATH     Project root (default: .)
  --domain TAG    Domain tag e.g. DB, AUTH (required)
  --query TEXT    Optional secondary filter (substring match, not LLM)
  -h, --help      Show this help

Example:
  bash scripts/fetch-context.sh --domain DB --query "postgresql"
EOF
}

list_known_tags() {
  local file="$1"
  grep -oE '\[[A-Z0-9_]+\]' "$file" 2>/dev/null | tr -d '[]' | sort -u || true
}

matches_query() {
  local text="$1"
  if [[ -z "$QUERY" ]]; then
    return 0
  fi
  [[ "$text" == *"$QUERY"* ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --query) QUERY="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$DOMAIN" ]]; then
  echo "Error: --domain is required. Do not infer tags from natural language." >&2
  ROOT="$(cd "${ROOT}" && pwd)"
  ROADMAP="$ROOT/docs/architecture/ROADMAP.md"
  ADR="$ROOT/docs/architecture/ADR.md"
  echo "Known tags in ROADMAP:" >&2
  if [[ -f "$ROADMAP" ]]; then
    list_known_tags "$ROADMAP" | sed 's/^/  /' >&2 || true
  fi
  echo "Known tags in ADR:" >&2
  if [[ -f "$ADR" ]]; then
    list_known_tags "$ADR" | sed 's/^/  /' >&2 || true
  fi
  echo "Usage: bash scripts/fetch-context.sh --domain TAG" >&2
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"
VISION="$ROOT/docs/architecture/VISION.md"
ROADMAP="$ROOT/docs/architecture/ROADMAP.md"
ADR="$ROOT/docs/architecture/ADR.md"
TAG="[$DOMAIN]"

for f in "$VISION" "$ROADMAP" "$ADR"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: missing $f" >&2
    exit 1
  fi
done

echo "# Context bundle — domain ${TAG}"
echo ""
echo "## VISION"
echo ""
cat "$VISION"
echo ""
echo "## ROADMAP (SHORT-TERM, ${TAG})"
echo ""

in_short=0
found_roadmap=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^##\ SHORT-TERM ]]; then
    in_short=1
    continue
  fi
  if [[ $in_short -eq 1 && "$line" =~ ^##\  ]]; then
    break
  fi
  if [[ $in_short -eq 1 && "$line" == *"$TAG"* ]]; then
    if matches_query "$line"; then
      echo "$line"
      found_roadmap=1
    fi
  fi
done < "$ROADMAP"

if [[ $found_roadmap -eq 0 ]]; then
  echo "(no SHORT-TERM items for ${TAG})"
fi

echo ""
echo "## ADR — CORE RULES (always)"
echo ""

in_core=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^##\ CORE\ RULES ]]; then
    in_core=1
    continue
  fi
  if [[ $in_core -eq 1 && "$line" =~ ^##\  ]]; then
    break
  fi
  if [[ $in_core -eq 1 ]]; then
    echo "$line"
  fi
done < "$ADR"

echo ""
echo "## ADR — ${TAG} (sliced)"
echo ""

in_recent=0
found_adr=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" =~ ^##\ RECENT\ DECISIONS ]]; then
    in_recent=1
    continue
  fi
  if [[ $in_recent -eq 1 && "$line" =~ ^##\  ]]; then
    break
  fi
  if [[ "$line" == *"$TAG"* ]]; then
    if matches_query "$line"; then
      echo "$line"
      found_adr=1
    fi
  fi
done < "$ADR"

if [[ $found_adr -eq 0 ]]; then
  echo "(no RECENT entries for ${TAG})"
fi
