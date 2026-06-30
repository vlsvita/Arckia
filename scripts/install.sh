#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
PLATFORMS="all"
SYNC_KERNEL=0
FORCE_AGENTS=0

usage() {
  cat <<EOF
Usage: install.sh [target] [platforms] [options]

Options:
  --sync-kernel    Regenerate AGENTS.md from KERNEL.md before install
  --force-agents   Overwrite target AGENTS.md (default: skip if exists)
  --force-skill    Overwrite .agents/skills/arckia (default: skip if exists)
  -h, --help       Show help

Examples:
  bash scripts/install.sh /path/to/project all --sync-kernel
  bash scripts/install.sh . cursor,claude --force-agents
EOF
}

positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync-kernel) SYNC_KERNEL=1; shift ;;
    --force-agents) FORCE_AGENTS=1; shift ;;
    --force-skill) FORCE_SKILL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) positional+=("$1"); shift ;;
  esac
done

TARGET="${positional[0]:-.}"
PLATFORMS="${positional[1]:-all}"
FORCE_SKILL="${FORCE_SKILL:-0}"

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

if [[ $SYNC_KERNEL -eq 1 ]]; then
  bash "$ROOT/scripts/sync-agents.sh"
fi

copy_tree() {
  local src="$1"
  local dest="$2"
  local src_real dest_real
  src_real="$(cd "$src" && pwd)"
  dest_real="$(mkdir -p "$dest" && cd "$dest" && pwd)"
  if [[ "$src_real" == "$dest_real" ]]; then
    echo "  skip (same path): $dest"
    return
  fi
  mkdir -p "$dest"
  cp -R "$src/." "$dest/"
}

merge_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    echo "  skip (exists): $dest"
  else
    cp "$src" "$dest"
    echo "  added: $dest"
  fi
}

force_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  updated: $dest"
}

install_platform() {
  local platform="$1"
  case "$platform" in
    cursor)
      if [[ -f "$TARGET/.cursor/rules/arckia.mdc" && $FORCE_AGENTS -eq 0 ]]; then
        merge_file "$ROOT/adapters/cursor/.cursor/rules/arckia.mdc" "$TARGET/.cursor/rules/arckia.mdc"
      else
        force_file "$ROOT/adapters/cursor/.cursor/rules/arckia.mdc" "$TARGET/.cursor/rules/arckia.mdc"
      fi
      for cmd in arckia.md arc.md architect.md; do
        merge_file "$ROOT/adapters/cursor/.cursor/commands/$cmd" "$TARGET/.cursor/commands/$cmd"
      done
      ;;
    claude)
      merge_file "$ROOT/adapters/claude/CLAUDE.md" "$TARGET/CLAUDE.md"
      merge_file "$ROOT/adapters/claude/.claude/rules/arckia-architect.md" "$TARGET/.claude/rules/arckia-architect.md"
      if [[ -f "$ROOT/templates/hooks/claude-settings.json" ]]; then
        merge_file "$ROOT/templates/hooks/claude-settings.json" "$TARGET/.claude/settings.json"
      fi
      ;;
    devin|windsurf)
      merge_file "$ROOT/adapters/devin/.devin/rules/arckia-architect.md" "$TARGET/.devin/rules/arckia-architect.md"
      merge_file "$ROOT/adapters/devin/.windsurf/rules/arckia-architect.md" "$TARGET/.windsurf/rules/arckia-architect.md"
      merge_file "$ROOT/adapters/devin/.devin/workflows/arckia.md" "$TARGET/.devin/workflows/arckia.md"
      merge_file "$ROOT/adapters/devin/.devin/workflows/arc.md" "$TARGET/.devin/workflows/arc.md"
      merge_file "$ROOT/adapters/devin/.devin/workflows/architect.md" "$TARGET/.devin/workflows/architect.md"
      ;;
    codex)
      if [[ $FORCE_AGENTS -eq 1 ]]; then
        force_file "$ROOT/AGENTS.md" "$TARGET/AGENTS.md"
      else
        merge_file "$ROOT/AGENTS.md" "$TARGET/AGENTS.md"
      fi
      ;;
    antigravity)
      merge_file "$ROOT/adapters/antigravity/.agent/rules/arckia-architect.md" "$TARGET/.agent/rules/arckia-architect.md"
      ;;
    *)
      echo "Unknown platform: $platform" >&2
      exit 1
      ;;
  esac
}

echo "Installing Arckia into: $TARGET"

copy_tree "$ROOT/core" "$TARGET/core"
copy_tree "$ROOT/scripts" "$TARGET/scripts"

if [[ $FORCE_AGENTS -eq 1 ]]; then
  force_file "$ROOT/AGENTS.md" "$TARGET/AGENTS.md"
else
  merge_file "$ROOT/AGENTS.md" "$TARGET/AGENTS.md"
fi

if [[ $FORCE_SKILL -eq 1 ]]; then
  mkdir -p "$TARGET/.agents/skills/arckia"
  force_file "$ROOT/.agents/skills/arckia/SKILL.md" "$TARGET/.agents/skills/arckia/SKILL.md"
else
  mkdir -p "$TARGET/.agents/skills/arckia"
  merge_file "$ROOT/.agents/skills/arckia/SKILL.md" "$TARGET/.agents/skills/arckia/SKILL.md"
fi

for f in VISION.md ROADMAP.md ADR.md; do
  merge_file "$ROOT/docs/architecture/$f" "$TARGET/docs/architecture/$f"
done
merge_file "$ROOT/docs/architecture/archive/README.md" "$TARGET/docs/architecture/archive/README.md"
merge_file "$ROOT/adapters/cursor/.cursorrules" "$TARGET/.cursorrules"
merge_file "$ROOT/templates/hooks/pre-commit" "$TARGET/scripts/hooks/pre-commit"

if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="cursor,claude,devin,codex,antigravity"
fi

IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"
for platform in "${PLATFORM_LIST[@]}"; do
  platform="${platform#"${platform%%[![:space:]]*}"}"
  platform="${platform%"${platform##*[![:space:]]}"}"
  [[ -z "$platform" ]] && continue
  echo "Platform: $platform"
  install_platform "$platform"
done

echo "Done. Run: bash $TARGET/scripts/validate.sh $TARGET"
