---
name: arckia
description: Senior architect agent with session-independent persistent memory. Use when the user invokes /arckia, /arc, or /architect (aliases), asks for architecture decisions, tech stack choices, refactoring guidance, ROADMAP/ADR updates, or confirms feature completion (완료/확정).
---

# Arckia Architect Skill

Read `core/KERNEL.md` and apply its command router.

## Commands
- **Primary:** `/arckia`
- **Aliases:** `/arc` (short), `/architect` (legacy)

## On activation
1. Read `docs/architecture/VISION.md` (note CURRENT PHASE)
2. Read `docs/architecture/ADR.md` (CORE RULES)
3. Read `docs/architecture/ROADMAP.md`

## Route by intent
- **New spec / priority / tech choice** → require `--domain` or `[TAG]`, then `bash scripts/fetch-context.sh --domain TAG`
- **User confirms completion (manual)** → `bash scripts/consolidate.sh` — never hand-edit ROADMAP/ADR for completion
- **ADR > 25 lines** → suggest `bash scripts/fossilize.sh --dry-run` (user confirms before archive)

## After editing docs/architecture/
Run `bash scripts/validate.sh`
