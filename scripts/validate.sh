#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/constants.sh
source "$SCRIPT_DIR/lib/constants.sh"

estimate_tokens() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "0"
    return
  fi
  local chars
  chars=$(wc -c < "$file" | tr -d ' ')
  echo $((chars / 4))
}

fail=0
warn=0

check_file() {
  local file="$1"
  local max_tokens="$2"
  local label="$3"

  if [[ ! -f "$file" ]]; then
    echo "MISSING: $file"
    fail=1
    return
  fi

  local tokens
  tokens=$(estimate_tokens "$file")
  if (( tokens > max_tokens )); then
    echo "FAIL: $label — ~${tokens} tokens (max ${max_tokens}): $file"
    fail=1
  else
    echo "OK: $label — ~${tokens} tokens: $file"
  fi
}

echo "Arckia validation: $ROOT"
echo ""

check_file "$ROOT/docs/architecture/VISION.md" 300 "VISION"
check_file "$ROOT/docs/architecture/ADR.md" 500 "ADR (active)"

if [[ -f "$ROOT/docs/architecture/ADR.md" ]]; then
  lines=$(grep -cve '^\s*$' "$ROOT/docs/architecture/ADR.md" || true)
  if (( lines > ADR_FOSSILIZE_TRIGGER )); then
    echo "FAIL: ADR.md has ${lines} non-empty lines (max ${ADR_FOSSILIZE_TRIGGER} — run: bash scripts/fossilize.sh --dry-run)"
    fail=1
  elif (( lines > ADR_WARN_LINES )); then
    echo "WARN: ADR.md has ${lines} non-empty lines (approaching fossilize threshold ${ADR_FOSSILIZE_TRIGGER})"
    warn=1
  else
    echo "OK: ADR.md line count (${lines})"
  fi
fi

for required in AGENTS.md core/KERNEL.md .agents/skills/arckia/SKILL.md scripts/consolidate.sh scripts/fossilize.sh scripts/fetch-context.sh scripts/validate.sh; do
  if [[ -f "$ROOT/$required" ]]; then
    echo "OK: $required present"
  else
    echo "MISSING: $required"
    fail=1
  fi
done

if [[ -d "$ROOT/docs/architecture/archive" ]]; then
  echo "OK: archive/ directory present"
else
  echo "MISSING: docs/architecture/archive/"
  fail=1
fi

# SSOT drift: AGENTS.md should match generated output from KERNEL.md
if [[ -f "$ROOT/core/KERNEL.md" && -x "$PLUGIN_ROOT/scripts/sync-agents.sh" ]]; then
  agents_tmp="$(mktemp)"
  KERNEL="$ROOT/core/KERNEL.md" AGENTS="$agents_tmp" bash -c '
    kernel_body="$(tail -n +2 "$KERNEL")"
    cat > "$AGENTS" <<EOF
<!-- AUTO-GENERATED from core/KERNEL.md — DO NOT EDIT.
     Edit core/KERNEL.md, then run: npm run sync  (or: bash scripts/sync-agents.sh) -->

# Arckia Architect

Persistent-memory senior architect agent. Memory files: \`docs/architecture/\`.

${kernel_body}

## Memory consolidation (manual — user must confirm first)

When the user explicitly confirms implementation is complete and verified (완료 / 확정 / end of task):
1. Do **not** edit ROADMAP.md or ADR.md RECENT DECISIONS by hand for the completion flow.
2. Run the deterministic consolidator (user or agent, after explicit user confirmation):

\`\`\`bash
bash scripts/consolidate.sh --match "<roadmap item fragment>" --rationale "<why>"
\`\`\`

Optional: \`--domain AUTH\`, \`--dry-run\`, \`--remove\` (delete ROADMAP line instead of marking [x]).

When ADR exceeds 25 lines, run \`bash scripts/fossilize.sh --dry-run\` then confirm with \`--yes\` or interactive prompt.

For architecture context, always use explicit domain:
\`\`\`bash
bash scripts/fetch-context.sh --domain DB [--query "optional filter"]
\`\`\`

After any edit under \`docs/architecture/\`, run: \`bash scripts/validate.sh\`
EOF
  '
  if [[ -f "$ROOT/AGENTS.md" ]] && ! cmp -s "$ROOT/AGENTS.md" "$agents_tmp"; then
    echo "FAIL: AGENTS.md is out of sync with core/KERNEL.md — run: npm run sync"
    fail=1
  else
    echo "OK: AGENTS.md in sync with KERNEL.md"
  fi
  rm -f "$agents_tmp"
fi

# ROADMAP: warn on [x] items without a matching ADR RECENT entry (substring match)
if [[ -f "$ROOT/docs/architecture/ROADMAP.md" && -f "$ROOT/docs/architecture/ADR.md" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^-\ \[\x\]\ \[[A-Z0-9_]+\]\ (.+) ]] || continue
    item_text="${BASH_REMATCH[1]}"
    key="$(echo "$item_text" | cut -c1-30)"
    if ! grep -qF "$key" "$ROOT/docs/architecture/ADR.md"; then
      echo "WARN: ROADMAP [x] item may be missing from ADR: ${key}..."
      warn=1
    fi
  done < "$ROOT/docs/architecture/ROADMAP.md"
fi

# Block unverified plans in ADR RECENT that still exist as unchecked ROADMAP items
if [[ -f "$ROOT/docs/architecture/ROADMAP.md" && -f "$ROOT/docs/architecture/ADR.md" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^-\ \[\ \]\ \[[A-Z0-9_]+\]\ (.+) ]] || continue
    item_text="${BASH_REMATCH[1]}"
    key="$(echo "$item_text" | cut -c1-40)"
    if grep -qF "$key" "$ROOT/docs/architecture/ADR.md"; then
      echo "FAIL: Unchecked ROADMAP item appears in ADR (use consolidate.sh after user confirms): ${key}..."
      fail=1
    fi
  done < "$ROOT/docs/architecture/ROADMAP.md"
fi

echo ""
if (( fail == 0 )); then
  if (( warn == 1 )); then
    echo "Validation passed with warnings."
  else
    echo "Validation passed."
  fi
  exit 0
fi

echo "Validation failed."
exit 1
