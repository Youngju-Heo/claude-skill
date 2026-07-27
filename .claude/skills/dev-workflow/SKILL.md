---
name: dev-workflow
description: 새 기능 개발을 시작하거나 기획/설계, 상세개발계획, 구현/테스트, 최종리뷰 단계를 진행할 때 사용한다. 브랜치 생성 규칙, 설계·계획 문서의 저장 경로와 명명 규칙, 단계별 스킬·모델 규칙을 정의한다.
---

# 기능 개발 워크플로

모든 개발은 **기획/설계 → 상세계획 → 구현/테스트 → 최종리뷰** 순서로 진행한다.

## 단계별 스킬·모델 규칙

| 단계 | 스킬 | 모델 |
|------|------|------|
| 기획/설계 | superpowers/brainstorming | Opus |
| 상세개발계획 | superpowers/writing-plans | Opus |
| 구현/테스트 | superpowers/subagent-driven-development, superpowers/test-driven-development | Sonnet 5 |
| 최종리뷰 | superpowers/requesting-code-review | Opus |

- SDD 진행 중 태스크별 리뷰는 구현 단계에 속하므로 Sonnet 5로 진행한다.
- 최종리뷰는 전체 브랜치를 **1회만** 리뷰한다. 추가 리뷰 라운드나 재검증 패스를 스스로 만들지 마라.
- 리뷰에서는 발견한 이슈를 심각도와 무관하게 모두 보고하라.
- 실행 시 현재 기본 모델과 다를 시: 상세개발계획·최종리뷰는 해당 모델의 서브에이전트로 위임하고, 기획/설계(대화형)는 사용자에게 `/model` 전환을 요청한다.
- 위 단계에 정의된 것 외의 서브에이전트는 만들지 마라.

## 브랜치·커밋 규칙

- 새 기획 시작 시 `{feature-name}` 기반으로 브랜치를 만들고 시작하라.
- 작업 단계별로 git에 커밋하여 이력을 저장하라.
- 커밋 메시지는 한국어로 작성하라.

## 문서 규칙

- 기획/계획 작성 시 반드시 markdown 파일로 저장하라.
  - 설계: `docs/feature/yyyy-mm-dd-{day-sequence}-{feature-name}-design.md`
  - 계획: `docs/feature/yyyy-mm-dd-{day-sequence}-{feature-name}-plan.md`
  - `{day-sequence}`는 그날 순번 2자리, `01`부터. 계획은 해당 설계와 동일한 순번을 쓴다.
- 설계 문서에는 해당 기능의 주요 엔티티·모듈 네이밍 항목을 포함하라.
  구현은 이 네이밍을 따른다. (코드 네이밍 상세 규칙은 `.claude/rules/`의
  언어별 규칙을 따르라.)
- 문서는 결정 사항과 그 근거 중심으로 필요한 내용만 담아라. 상투적 요약,
  채우기 섹션, 중복 설명으로 분량을 늘리지 마라.
- 모든 문서는 한국어로 작성하라.
