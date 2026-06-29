# PROJECT VISION (초경량 상주용: 200토큰 미만 명사 중심 작성)

## CURRENT PHASE
- **Phase 1 (now)**: Modular monolith — bounded modules, interface boundaries, single deployable.
- **Phase 2 (future)**: Event-driven extraction — only when module boundaries are proven in production.

## BIG GOAL
- **North star**: Event-driven MSA (long-term, not current sprint default).
- **Focus**: Global multi-language & auto-scalable infrastructure.

## ARCHITECTURAL PHILOSOPHY
- **KISS**: Optimize for **current phase** (Phase 1). No microservices/Kafka/k8s split unless ROADMAP explicitly schedules Phase 2 work.
- **DECOUPLING**: Interface-based modules within the monolith. Hard cross-module dependency forbidden.
