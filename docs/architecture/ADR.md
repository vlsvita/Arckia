# ARCHITECTURE DECISION RECORD (ADR)

## CORE RULES (철학과 결합된 아키텍처/기술 규칙 및 사유 - 상시 상주)
- **[DB] 주 저장소 PostgreSQL 고정**
  - *Reason*: 금융 및 정산 데이터 연동을 위한 무결성(ACID) 보장이 필수적임. 과거 MongoDB 도입 시 분산 트랜잭션 이슈로 원장 데이터 오염을 겪은 후 대전환함. 향후 정산 관련 핵심 도메인에 NoSQL 재제안 절대 금지.

## RECENT DECISIONS (기술 선택, 구조 변경, 리팩토링 완료 시 태그별 부분 접근 영역)
- [2026-06] [NOTI] 카카오 알림톡 모듈 연동 및 프로덕션 반영 완료. (이유: ROADMAP 단기 목표 달성 및 SMS 발송 비용 절감)
