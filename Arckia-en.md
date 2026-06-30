# Arckia

---

## Arckia: Senior Architect Agent Skill — Project Lifecycle Synchronization Spec

## 1. Overview and Purpose

- **Background**: Existing LLM agents have a critical limitation: when a chat session closes, all memory is wiped (reset). When plans change, they suffer from context collapse (dual truth) between the spec and past records, forget accumulated history, and re-propose technologies that were previously rejected—a cognitive bug.
- **Purpose**: Achieve peer-level senior developer ownership and session-independent persistent context from day one of the project. Isolate philosophy (VISION), unfinished requirements (ROADMAP), and technical history (ADR), and fully synchronize the software lifecycle (SDLC) via [plan consumption → verified implementation → history migration].
- **Core operating principle**: While always holding the project's central pillars (VISION + CORE_RULES), the agent cross-validates only the tagged detail areas needed for technology selection, structural changes, and refactoring (Context Slicing), maintaining architecture judgment that stays 100% aligned with production code.

---

## 2. Core Architecture and Memory Management Strategy

Rather than spawning sub-agents that sever memory, the main agent that has worked alongside the developer continues the conversation context and dynamically invokes the four file layers below according to situational policy.

## File-System-Based Persistent Memory Mechanism

- **Session independence**: When the AI model's short-term memory (session) closes or the machine reboots, all settled memory is physically persisted as markdown text files on the local disk (`docs/architecture/`).
- **Long-term memory runtime restoration**: When a new chat (session) opens and the AI starts blank, the moment `/arckia` (aliases: `/arc`, `/architect`) is invoked on the first question, the `.cursorrules` switch pulls the brain files from disk and restores existing context at 100% sync rate.
- **Universality**: Regardless of environment setup or version control (Git), the markdown text on disk is the ultimate source of truth—from personal local projects to large repositories.

```
my-project/
├── .cursorrules (or AGENTS.md)     # 1. Main context (identity and command router)
└── docs/
    └── architecture/
        ├── VISION.md               # 2. [Ultra-light resident] Design direction and long-term philosophy (<200–300 tokens)
        ├── ROADMAP.md              # 3. Planned features / specs (unfinished specs only)
        └── ADR.md                  # 4. Compressed tech/architecture rules and rationale (tag-based management)
```

---

## 3. Single Entry Point and Sub-Skill Specification

Developers use **`/arckia`** (aliases: `/arc`, `/architect`) without managing files manually. Cross-editing between plan and history files and tag-based partial extraction are handled by the agent invoking sub-skills autonomously.

## Top-Level Router: /arckia [request]

- **Primary:** `/arckia` — **Aliases:** `/arc` (short), `/architect` (legacy)

- **Behavior**: Activates when the user requests adding, removing, or changing features; branches to sub-skills based on query intent.

## Sub-skill 1: sub_fetch_context (context expansion)

- **Behavior**: Activates on architecture change, technology selection, or refactoring requests. The user must **explicitly** specify a tag via `[DOMAIN]` or `--domain DOMAIN` (LLM inference forbidden). Deterministic slicing of VISION + ROADMAP/ADR via `fetch-context.sh --domain DOMAIN`.

## Sub-skill 2: sub_architect_reasoning (reasoning and review)

- **Behavior**: When a design conflicts with past decisions and philosophy (CORE_RULES), or a proposed structure does not fit future direction, emit `[WARNING]` at the top of the response and remind the rationale (Why) for past changes. Output final skeleton markdown including trade-off analysis.

## Sub-skill 3: sub_append_adr (plan consumption and long-term memory settlement)

- **Trigger timing**: Linked when the user clearly declares in chat that formal code implementation and verification are complete—e.g. "this feature is fully done" or "tests passed, let's finalize" (intent detection)—and directly modifies local disk files.
- **Process**:
  1. **Plan consumption**: Remove or check ([x]) the completed item from ROADMAP.md SHORT-TERM. (Also reflect plan changes/cancellations in ROADMAP immediately to stay in sync.)
  2. **History migration and settlement**: Move consumed short-term items into the matching domain tag section in ADR.md and record concrete design rationale. If a new decision overrides past records, delete or mark old entries `[Deprecated]` to prevent unbounded file growth.
  3. **Periodic fossilization**: When the active ADR list exceeds 25 lines, preview with `fossilize.sh --dry-run`, obtain user confirmation (`--yes` or interactive), and gradually migrate RECENT entries to `docs/architecture/archive/` two at a time. CORE RULES squash for entries older than 6 months is planned for a future version.

---

## 4. Per-File Runtime Access and Frequency (Life Cycle Master Table)

| File | Access | Read/Write Timing | Primary Trigger and Purpose |
| --- | --- | --- | --- |
| Main context (.cursorrules / AGENTS.md) | READ | Every conversation, always | Maintain default architect identity and routing switch |
| VISION.md (design direction) | READ | Every conversation, always | Keep long-term project vision and philosophy resident (ultra-light, always loaded) |
| VISION.md (design direction) | WRITE | When direction discussion reaches a finalized conclusion | Update on major tech stack pivot or macro direction agreement |
| ROADMAP.md (unfinished plans) | READ / WRITE | New features, priority decisions, current development direction | Track new specs, changes, cancellations, and implementation progress |
| ADR.md (CORE_RULES) | READ | Every conversation, always | Always hold confirmed architecture principles and prohibition rationale (Why) to prevent regression |
| ADR.md (CORE_RULES + target tag area) | READ / WRITE | Technology selection, structural change, refactoring | Extract only detailed history for relevant tags ([DB], etc.). Read [CORE_RULES + target tag area] together for macro–micro cross-validation. |

---

## 5. Standard Data Schema (docs/architecture/) (examples below; implementation in English)

## ① VISION.md (design direction schema)

```markdown
# PROJECT VISION (ultra-light resident: <200 tokens, noun phrases)

## BIG GOAL
- **Target**: Monolithic to Event-Driven MSA transition.
- **Focus**: Global multi-language & auto-scalable infrastructure.

## ARCHITECTURAL PHILOSOPHY
- **KISS**: Avoid over-engineering. Deliver pragmatic solutions for current phase.
- **DECOUPLING**: Enforce Interface-based programming. Hard-dependency is strictly forbidden.
```

## ② ROADMAP.md (unfinished plan schema)

```markdown
# CURRENT ROADMAP (unfinished plans and live spec changes)

## SHORT-TERM (near-term planned features)
- [ ] [PAYMENT] Extend settlement ledger schema with PostgreSQL partitioned tables (priority: high)
- [ ] [AUTH] Add OAuth2-based social login (priority: medium)
```

## ③ ADR.md (history schema settled by sub_append_adr, per domain)

```markdown
# ARCHITECTURE DECISION RECORD (ADR)

## CORE RULES (architecture/tech rules bound to philosophy and rationale — always resident)
- **[DB] Primary store fixed to PostgreSQL**
  - *Reason*: ACID integrity required for financial and settlement data integration. After ledger data corruption from distributed transaction issues with MongoDB, we pivoted. Re-proposing NoSQL for core settlement domains is strictly forbidden.

## RECENT DECISIONS (tag-scoped area for completed tech choices, structural changes, refactors)
- [2026-06] [NOTI] Kakao Alimtalk module integrated and deployed to production. (Reason: ROADMAP short-term goal achieved; SMS cost reduction)

```

---

## 6. Expected Outcomes

1. **Senior peer persona from day one**: By always holding philosophical pillars VISION and CORE_RULES, deliver principle-centered design leadership that does not waver across session resets or environments [INDEX].
2. **Eliminate dual truth and cognitive bugs at the source**: Until formal implementation, items live only in ROADMAP; they migrate to history only when the user explicitly confirms full implementation completion. Old records compress with prohibition rationale (Why), removing memory confusion for the model.
3. **Maximized context efficiency (token savings)**: Even on multi-year large projects, carry only a lightweight skeleton at all times and load associated tag blocks on demand—keeping model intelligence high while token cost stays bounded [INDEX].

---
