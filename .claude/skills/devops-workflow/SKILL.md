---
name: devops-workflow
description: Azure DevOps의 Task(Work Item)를 확인하고, 그 내용을 기반으로 기획/설계부터 구현·최종리뷰까지 진행한 뒤 일감을 완료 처리할 때 사용한다. Work Item 조회, 요구사항 정리, dev-workflow 절차 수행, 상태 전환과 결과 기록을 담당한다.
argument-hint: "[work-item-id]"
disable-model-invocation: true
---

# Azure DevOps 일감 기반 개발 워크플로

Azure DevOps의 Task를 출발점으로, 확인 → 개발 → 완료 처리까지 진행한다.
개발 절차 자체(단계·스킬·모델·문서 규칙)는 **dev-workflow 스킬을 그대로
따른다.** 이 스킬은 그 앞뒤에 Azure DevOps 연동 단계를 붙인다.

## 0. 사전 확인

- Azure DevOps 접근 수단을 확인하라. 우선순위:
  1. Azure DevOps MCP 도구가 연결되어 있으면 그것을 사용
  2. 없으면 `az` CLI(azure-devops 확장): `az boards work-item show --id <id>`
  3. 둘 다 없으면 사용자에게 설정을 요청하고 중단하라. 임의로 REST API
     토큰을 요구하거나 우회하지 마라.
- 조직/프로젝트 정보가 필요한데 알 수 없으면 사용자에게 물어라.

## 1. Task 확인

`$ARGUMENTS`로 받은 Work Item ID를 조회하라. ID가 없으면 사용자에게 물어라.

수집할 것:

- 제목, 설명(Description), 인수 조건(Acceptance Criteria)
- 부모 항목(User Story/PBI)의 제목과 설명 — Task만으로 맥락이 부족하면
  반드시 부모까지 읽어라
- 댓글(Discussion)과 연결된 항목(관련 Work Item, PR, 커밋)
- 현재 상태(State)와 담당자(Assigned To)

정리한 요구사항을 사용자에게 요약해 보여주고 진행 여부를 확인받아라.
설명이 비어 있거나 인수 조건이 모호하면 코딩 전에 먼저 생각하라 원칙대로
질문하라 — Work Item이 빈약한 채로 추측 구현하지 마라.

## 2. 착수 처리

- Work Item 상태를 진행 중 상태로 전환하라. 상태 이름은 프로젝트의
  프로세스 템플릿을 따른다(예: Agile은 Active, Scrum은 In Progress).
  전환 가능한 상태 목록을 확인한 뒤 맞는 것을 골라라.
- 브랜치는 dev-workflow 규칙에 Work Item ID를 붙여 만들어라:
  `{work-item-id}-{feature-name}`

## 3. 개발 진행

**dev-workflow 스킬의 절차를 그대로 수행하라**:
기획/설계 → 상세계획 → 구현/테스트 → 최종리뷰 (단계별 스킬·모델 규칙 포함).

이 스킬에서 추가되는 것만 다음과 같다:

- 기획/설계의 입력은 1단계에서 정리한 Work Item 요구사항이다. 인수 조건은
  설계 문서의 성공 기준으로 그대로 옮겨라.
- 설계·계획 문서 파일명의 `{feature-name}` 앞에 Work Item ID를 붙여라:
  `docs/feature/yyyy-mm-dd-{seq}-{work-item-id}-{feature-name}-design.md`
- 커밋 메시지에 `#{work-item-id}`를 포함해 커밋이 Work Item에 연결되게
  하라. (GitHub 저장소 + Azure Boards 연동인 경우는 `AB#{work-item-id}`)

### 머지 범위 규칙

- 소스 머지는 **Work Item 브랜치(`{work-item-id}-{feature-name}`)
  단위까지만** 직접 수행하라. 구현 중 하위 작업 브랜치를 만들었다면
  Work Item 브랜치로만 머지하라.
- Work Item 브랜치를 main/develop 등 통합 브랜치에 직접 머지하는 것은
  금지다. 통합 브랜치로의 반영은 반드시 4단계의 PR로만 진행하라.

## 4. 일감 완료 처리

최종리뷰가 끝난 뒤에만 진행한다.

1. **PR을 생성하라.** Work Item 브랜치 → 통합 브랜치(main/develop 등,
   저장소의 기본 대상 브랜치)로 PR을 만들어라. 직접 머지는 금지다.
   - Azure Repos면 MCP 도구 또는 `az repos pr create`, GitHub이면
     `gh pr create`를 사용하라.
   - PR 설명에 포함할 것: 작업 요약, 설계/계획 문서 경로, 인수 조건별
     충족 여부. Work Item이 연결되도록 `#{work-item-id}`(또는
     `AB#{work-item-id}`)를 명시하라.
   - PR 머지는 수행하지 마라. 머지는 리뷰어/사용자의 결정이다.
2. Work Item에 결과 댓글을 남겨라. 포함할 것: 작업 요약(3~5줄),
   설계/계획 문서 경로, 브랜치명, PR 링크, 인수 조건별 충족 여부.
3. 남은 작업량(Remaining Work) 필드가 있으면 0으로 갱신하라.
4. **사용자에게 완료 전환 여부를 확인받은 뒤** 상태를 완료 상태로
   전환하라(예: Agile은 Closed, Scrum은 Done). 확인 없이 상태를
   완료로 바꾸지 마라 — 팀 보드에 즉시 반영되는 조작이다. 팀 정책이
   "PR 머지 후 완료"라면 전환을 보류하고 그 사실을 보고하라.
5. 처리 후 최종 상태를 조회해 실제로 반영됐는지 확인하고 사용자에게
   Work Item 링크·PR 링크와 함께 보고하라.

## 제약

- 이 스킬이 수정할 수 있는 것은 대상 Work Item의 상태·댓글·Remaining
  Work뿐이다. 다른 Work Item을 생성·수정·삭제하지 마라.
- 인수 조건을 충족하지 못한 채 완료 처리하지 마라. 미충족 항목이 있으면
  그 사실을 댓글과 사용자 보고에 명시하고 상태 전환은 보류하라.
