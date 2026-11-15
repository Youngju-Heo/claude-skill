# Codex 변경 이력

Codex용 지침·스킬·설정 및 관련 문서의 변경사항을 최신 날짜순으로 기록한다.
각 항목에는 변경 내용, 이유, 관련 파일을 포함한다.

## 2026-11-15

### PROJECT_OVERVIEW.md 부재 시 생성 의무 명시

- 문서가 없다는 이유로 갱신 대상에서 제외하는 해석을 막기 위해, PROJECT_OVERVIEW.md가 없으면 현재 프로젝트의 구조, 주요 구성 요소, 사용법을 담아 새로 작성하도록 명시했다.
- 관련 파일: `.codex/AGENTS.md`, `CODEX_HISTORY.md`.

### 단계별 모델·추론 수준과 전환 기준 조정

- 최종 결과의 만족도와 전체 토큰 사용량의 균형을 위해 경량 작업은 Sol / Light, 상세계획은 Sol / High, 구현·테스트는 Terra / High, 디버깅은 Sol / Medium으로 조정했다. 기획·설계와 최종리뷰는 Sol / High를 유지한다.
- 구현 난도의 사전 판단에 따른 전환 조건을 제거하고, Terra가 같은 구현 문제를 반복해서 해결하지 못할 때 해당 구현을 Sol / High로 전환하도록 정리했다.
- 디버깅은 단계와 관계없이 Sol / Medium을 우선 적용하며 원인 분석이 끝나면 원래 단계의 기본 설정으로 복귀하도록 명시했다. Sol로 전환한 구현이 끝난 경우도 원래 단계의 기본 설정으로 복귀한다.
- 승인된 설계의 재결정은 모델과 관계없이 기획·설계로 돌아가는 단계 전환 규칙으로 분리했다.
- 효율은 재시도·재구현·재검증을 포함한 총 토큰 사용량, 완료 시간, 사용자 수정 요구와 결과 품질로 판단하도록 변경했다.
- 관련 파일: `.agents/skills/dev-workflow/SKILL.md`, `PROJECT_OVERVIEW.md`, `CODEX-SETUP.md`, `CODEX_HISTORY.md`.

## 2026-10-27

### Sol/Terra 단계별 조합 적용

- 비슷한 결과 품질을 유지하면서 작업당 사용량·비용을 줄이기 위해 `dev-workflow`의 모델 배치를 변경했다.
- 기획·설계와 최종리뷰는 Sol / High를 유지한다.
- 상세계획과 디버깅은 Terra / High, 구현·테스트는 Terra / Medium, 경량 작업은 Terra / Light를 사용한다.
- 설계 재결정, 여러 모듈에 걸친 복잡한 구현·원인 분석, 반복 해결 실패 시 Sol로 전환하도록 명시했다.
- 모델 교체만으로 토큰 수 감소를 보장하지 않으며 재시도를 포함한 사용량·비용·완료 시간과 결과 품질로 효과를 판단하도록 명시했다.
- 관련 파일: `.agents/skills/dev-workflow/SKILL.md`, `PROJECT_OVERVIEW.md`.

### 변경 이력 관리 추가

- `CODEX_HISTORY.md`를 생성하고 이번 모델 배치 변경을 기록했다.
- 앞으로 Codex용 지침·스킬·설정 및 관련 문서를 변경할 때 이력을 함께 갱신하도록 `AGENTS.md`에 규칙을 추가했다.
- 관련 파일: `CODEX_HISTORY.md`, `AGENTS.md`, `PROJECT_OVERVIEW.md`.

### 배포용 코딩 지침에서 이력 관리 규칙 분리

- 룰 자체의 편집 이력 관리가 대상 프로젝트의 코딩 작업에 적용되지 않도록 `AGENTS.md`에서 이력 갱신 규칙을 제거했다.
- `CODEX_HISTORY.md`는 유지하며, 별도 관리 방식은 아직 도입하지 않았다.
- 관련 파일: `AGENTS.md`, `CODEX_HISTORY.md`.

### 저장소 유지보수 지침과 배포용 코딩 지침 분리

- 기존 루트 `AGENTS.md` 내용을 변경 없이 `.codex/AGENTS.md`로 보존했다.
- 루트 `AGENTS.md`를 저장소 유지보수 전용으로 교체하고 Codex 룰·스킬 편집 시 이력 갱신 규칙을 추가했다.
- 유지보수 규칙이 대상 프로젝트에 배포되지 않도록 설치 안내의 원본 경로를 `.codex/AGENTS.md`로 변경했다.
- 관련 파일: `AGENTS.md`, `.codex/AGENTS.md`, `README.md`, `PROJECT_OVERVIEW.md`, `CODEX-SETUP.md`, `CODEX_HISTORY.md`.
