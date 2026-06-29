# Arckia — persistent architect memory for AI coding agents

Cross-platform plugin: one memory model (`docs/architecture/`), five harness adapters.

## Supported platforms

| Platform | Entry file | Adapter path |
|----------|------------|--------------|
| **Cursor** | `AGENTS.md` + `.cursor/rules/arckia.mdc` | always-on rule |
| **Claude Code** | `CLAUDE.md` + `.claude/rules/` | `@AGENTS.md` import |
| **Codex** | `AGENTS.md` | native discovery |
| **Devin / Windsurf** | `AGENTS.md` + `.devin/rules/` | model_decision + `/architect` workflow |
| **Antigravity** | `AGENTS.md` + `.agent/rules/` | model_decision |

Shared skill path: `.agents/skills/arckia/SKILL.md` (Cursor, Codex, Devin, Gemini CLI).

## Install

```bash
# Into current project (all platforms)
bash scripts/install.sh .

# Into another project
bash scripts/install.sh /path/to/your-app

# Specific platforms only
bash scripts/install.sh . cursor,claude,codex
```

Or via npm (local):

```bash
npm run install:all
npm run validate
```

## Usage

```
/architect [request]
```

Examples:
- `/architect [AUTH] OAuth2 소셜 로그인 스펙 추가`
- `/architect PostgreSQL 대신 Redis 캐시 레이어 제안 검토`
- `결제 모듈 구현 완료했어, 테스트 통과 — 확정` → triggers sub_append_adr

## Memory files

| File | Role |
|------|------|
| `docs/architecture/VISION.md` | Long-term philosophy (<300 tokens) |
| `docs/architecture/ROADMAP.md` | Unverified plans only |
| `docs/architecture/ADR.md` | Verified decisions + CORE RULES (<500 tokens) |
| `docs/architecture/archive/` | Fossilized history |

## Validate token discipline

```bash
bash scripts/validate.sh .
```

## Architecture

```
core/KERNEL.md          ← single source of truth (behavior)
AGENTS.md               ← cross-platform entry (Codex, Antigravity, Devin, Cursor)
.agents/skills/arckia ← cross-agent skill
adapters/               ← platform-specific thin wrappers
docs/architecture/      ← persistent project memory
```

## Improvements over v1 (.cursorrules-only)

1. **Cross-platform** — AGENTS.md + `.agents/skills/` standard instead of Cursor-only
2. **Archive path** — fossilization target exists
3. **Validation script** — token/line budget checks
4. **Context slicing via triggers** — Devin/Antigravity use `model_decision` to avoid loading architect rules on every message
5. **Non-destructive install** — never overwrites existing VISION/ROADMAP/ADR

## Known limits

- **User verification stays manual** — `consolidate.sh` runs only when you (or the agent after you say 확정) invoke it; nothing auto-marks features complete.
- **Structural enforcement** — `validate.sh` runs on `docs/architecture/` edits (optional pre-commit / Claude hook); blocks token drift and ROADMAP↔ADR inconsistency.
- Rule compliance for non-file actions is still LLM-dependent.
- Devin workspace rules cap at 12,000 chars per file — KERNEL stays well under this.

## CLI

```bash
npm run sync          # Regenerate AGENTS.md from core/KERNEL.md
npm run validate      # Structural checks (tokens, sync, ROADMAP/ADR consistency)
npm run consolidate -- --match "OAuth2" --rationale "E2E passed"  # After user confirms 완료
npm run fossilize -- --dry-run   # Preview archive when ADR > 25 lines
npm run fetch-context -- --domain DB --query "postgresql"
bash scripts/arckia install . all --sync-kernel --force-agents
```

Optional hooks (install copies templates):
- `templates/hooks/pre-commit` → `scripts/hooks/pre-commit` (copy to `.git/hooks/`)
- `templates/hooks/claude-settings.json` → merged into `.claude/settings.json` on claude platform install

See `Arckia.md` for the full product spec.
