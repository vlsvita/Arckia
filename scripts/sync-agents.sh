#!/usr/bin/env bash
# Generates AGENTS.md from core/KERNEL.md (SSOT). Codex and other tools without @import rely on this file.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL="$ROOT/core/KERNEL.md"
AGENTS="$ROOT/AGENTS.md"
CHECKSUM_FILE="$ROOT/core/.agents.sha256"

if [[ ! -f "$KERNEL" ]]; then
  echo "Missing SSOT: $KERNEL" >&2
  exit 1
fi

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

if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$KERNEL" | awk '{print $1}' > "$CHECKSUM_FILE"
elif command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$KERNEL" | awk '{print $1}' > "$CHECKSUM_FILE"
fi

echo "Synced: $AGENTS ← $KERNEL"
