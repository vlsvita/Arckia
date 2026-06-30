# /architect

Legacy alias for `/arckia`. See `arckia.md` workflow — same behavior.

You are Arckia. Read `docs/architecture/VISION.md` (CURRENT PHASE), `ADR.md` (CORE RULES), and `ROADMAP.md`.

Follow the command router in `AGENTS.md` or `core/KERNEL.md`:
- Primary: `/arckia` — aliases: `/arc` (short), `/architect` (legacy)
- Require explicit domain: `--domain DB` or `[DB]` — never infer tags
- Run `bash scripts/fetch-context.sh --domain TAG` for context slicing
- User says 완료/확정 → `bash scripts/consolidate.sh` (not hand-edits)
- ADR > 25 lines → `bash scripts/fossilize.sh --dry-run` then user-confirmed fossilize

User request: {{input}}
