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
  1. **REST 헬퍼** `scripts/ado.ps1` — 이 환경의 기본 수단이다.
     (아래 "인코딩 함정과 REST 우선" 참고)
  2. 읽기 전용이고 결과에 비ASCII 가 없다면 `az` CLI 도 무방:
     `az boards work-item show --id <id>`
  3. 둘 다 안 되면 사용자에게 설정을 요청하고 중단하라. 사용자에게
     **새 PAT 발급을 요구하지 마라** — 인증은 기존 az 로그인 세션에서만 얻는다.
- Azure DevOps MCP 서버는 사용하지 않음. **먼저 요구하기 전에는 다시 제안하지 마라.**

## 1. Task 확인

`$ARGUMENTS`로 받은 Work Item ID를 조회하라. ID가 없으면 사용자에게 물어라.

수집할 것:

- 제목, 설명(Description), 인수 조건(Acceptance Criteria)
- 부모 항목(User Story/PBI)의 제목과 설명 — Task만으로 맥락이 부족하면
  반드시 부모까지 읽어라
- 댓글(Discussion)과 연결된 항목(관련 Work Item, PR, 커밋)
  — `az` CLI로는 댓글 조회 명령이 없다. 아래 "인코딩 함정과 REST 우선" 참고
- 현재 상태(State)와 담당자(Assigned To)

정리한 요구사항을 사용자에게 요약해 보여줘라. 요구사항 자체를 확정하는
컨펌은 여기서 받지 마라 — dev-workflow의 기획/설계 단계 컨펌에서 받는다.
개발 절차의 컨펌 지점은 dev-workflow와 동일하게 유지한다.

단, 설명이 비어 있거나 인수 조건이 모호하면 코딩 전에 먼저 생각하라
원칙대로 질문하라 — Work Item이 빈약한 채로 추측 구현하지 마라.

## 2. 착수 처리

- **Work Item 상태 전환은 사용자 확인을 받은 뒤 수행하라.** 팀 보드에
  즉시 반영되는 조작이다. 1단계의 요구사항 요약과 함께 한 번에 물어라 —
  별도의 왕복을 만들지 마라.
- 확인을 받으면 진행 중 상태로 전환하라. 상태 이름은 프로젝트의
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
- 설계·계획 문서 경로는 dev-workflow 규칙을 그대로 따르되,
  `{feature-name}` 앞에 Work Item ID만 붙여라:
  `docs/feature/yyyy-mm/yyyy-mm-dd-{day-sequence}-{work-item-id}-{feature-name}-design.md`
- 커밋 메시지에 `#{work-item-id}`를 포함해 커밋이 Work Item에 연결되게
  하라. (GitHub 저장소 + Azure Boards 연동인 경우는 `AB#{work-item-id}`)

### 머지 범위 규칙

- 소스 머지는 **Work Item 브랜치(`{work-item-id}-{feature-name}`)
  단위까지만** 직접 수행하라. 구현 중 하위 작업 브랜치를 만들었다면
  Work Item 브랜치로만 머지하라.
- Work Item 브랜치를 main/develop 등 통합 브랜치에 직접 머지하는 것은
  금지다. 통합 브랜치로의 반영은 반드시 4단계의 PR로만 진행하라.

## 4. 일감 완료 처리

최종리뷰가 끝난 뒤에만 진행한다. dev-workflow의 경량 경로를 탄 경우는
변경 요약 보고가 끝난 뒤에 진행한다.

1. **PR을 생성하라.** Work Item 브랜치 → 통합 브랜치(main/develop 등,
   저장소의 기본 대상 브랜치)로 PR을 만들어라. 직접 머지는 금지다.
   - Azure Repos면 `New-AdoPullRequest`(scripts/ado.ps1), GitHub이면
     `gh pr create`를 사용하라. **`az repos pr create` 는 쓰지 마라** —
     제목·본문의 한글이 유실된다(아래 참고).
   - **대상 브랜치를 확인하고 만들어라.** 저장소의 기본 브랜치가 실제
     통합 브랜치가 아닐 수 있다. `git branch -r` 로 최근 갱신된 브랜치를
     보고, 작업 브랜치의 분기점이 어느 원격 브랜치의 tip 인지
     (`git merge-base` / `git log`) 확인한 뒤 정하라. 잘못 잡으면 수백
     커밋짜리 PR 이 만들어진다.
   - PR 설명에 포함할 것: 작업 요약, 설계/계획 문서 경로, 인수 조건별
     충족 여부. Work Item이 연결되도록 `#{work-item-id}`(또는
     `AB#{work-item-id}`)를 명시하라.
   - PR 머지는 수행하지 마라. 머지는 리뷰어/사용자의 결정이다.
2. Work Item에 결과 댓글을 남겨라. 포함할 것: 작업 요약(3~5줄),
   설계/계획 문서 경로, 브랜치명, PR 링크, 인수 조건별 충족 여부.
   **댓글 본문에 한글이 들어가므로 반드시 REST 로 작성하라** — 아래
   "인코딩 함정과 REST 우선" 참고. `az repos pr`에는 댓글 명령 자체가 없다.
3. 남은 작업량(Remaining Work) 필드가 있으면 0으로 갱신하라.
4. **사용자에게 완료 전환 여부를 확인받은 뒤** 상태를 완료 상태로
   전환하라(예: Agile은 Closed, Scrum은 Done). 확인 없이 상태를
   완료로 바꾸지 마라 — 팀 보드에 즉시 반영되는 조작이다. 팀 정책이
   "PR 머지 후 완료"라면 전환을 보류하고 그 사실을 보고하라.
5. 처리 후 최종 상태를 조회해 실제로 반영됐는지 확인하고 사용자에게
   Work Item 링크·PR 링크와 함께 보고하라.

## 인코딩 함정과 REST 우선

**이 환경의 `az` CLI 는 비ASCII 를 신뢰할 수 없다.** 2026-08 세션에서 확인:

- `az repos pr create --title "한글..." --description @file.md` 로 만든 PR 은
  제목·본문의 **한글이 통째로 사라진 채** 저장됐다. 인자로 넘기든 `@파일`로
  넘기든 같았고, PowerShell 에서 실행해도 같았다.
- 응답도 마찬가지다. az 는 콘솔 코드페이지(cp949)로 출력하므로 일본어처럼
  cp949 에 없는 문자는 `Unable to encode the output with cp949 encoding.
  Unsupported characters are discarded.` 경고와 함께 버려진다. `chcp 65001`,
  `PYTHONIOENCODING=utf-8`, `[Console]::OutputEncoding` 모두 효과가 없었다.
- `az devops invoke` 는 **PR 갱신(PATCH)을 지원하지 않는다**
  (`The requested resource does not support http method 'PATCH'.`).

따라서 **비ASCII 가 한 글자라도 들어가는 조작은 쓰기든 읽기든 아래 헬퍼로
하라.** 순수 ASCII 읽기(상태 확인, ID 조회 등)에만 `az` CLI 를 써도 된다.

### 헬퍼 사용법

```powershell
. "$HOME/.claude/skills/devops-workflow/scripts/ado.ps1"

Add-AdoWorkItemComment -Project prod -Id 351 -Html "<b>완료</b><br>내용"
Set-AdoWorkItemState   -Id 351 -State "완료"
New-AdoPullRequest -Project prod -Repository crbengine `
  -SourceBranch 351-foo -TargetBranch crb-detector-build `
  -Title "feat: #351 제목" -Description $desc -WorkItemIds 351,353
Update-AdoPullRequest -Project prod -Repository crbengine -Id 59 -Description $desc
Add-AdoPullRequestComment -Project prod -Repository crbengine -Id 59 -Text "리뷰 코멘트"
Get-AdoPullRequest -Project prod -Repository crbengine -Id 59
Get-AdoWorkItem -Id 351
```

임의 엔드포인트는 `Invoke-Ado -Path <경로> -Method <메서드> -Body <해시테이블>`
로 호출한다. 요청 본문을 UTF-8 바이트로 직접 넘기고 `Invoke-RestMethod` 로
응답을 받으므로 인코딩이 흔들리지 않는다.

### 인증 규칙

헬퍼는 `az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798`
으로 **이미 로그인된 az 세션에서 파생된 토큰**을 쓴다. 이는 0단계가 금지하는
"토큰 우회"가 아니다 — 그 금지의 취지는 *사용자에게 새 PAT 를 발급받게 하지
말라*는 것이다. 새 자격증명을 요구하는 것만 금지이고, 기존 로그인 재사용은
허용된다. az 로그인이 만료되면 헬퍼도 함께 멈추므로 `az login` 을 안내하라.

### 그래도 az CLI 가 필요한 경우

`az` CLI 에 없는 기능은 `az devops invoke` 로도 가능하지만, 위 PATCH 제약과
인코딩 문제가 그대로 남으므로 **헬퍼를 먼저 쓰라.** invoke 를 굳이 쓴다면:

- `--http-method` 기본값은 GET 이다. 쓰기는 `POST` 를 명시하라.
- 본문은 인라인으로 못 넘긴다. **BOM 없는 UTF-8** JSON 파일을 `--in-file` 로 줘라.
- `--api-version` 을 반드시 명시하라(안정 리소스 `7.1`, work item comments 는
  `7.1-preview.3`).
- `--route-parameters` 는 REST 경로 이름 그대로: `project`, `repositoryId`,
  `pullRequestId`, `workItemId`.

## 제약

- 이 스킬이 수정할 수 있는 것은 대상 Work Item의 상태·댓글·Remaining
  Work뿐이다. 다른 Work Item을 생성·수정·삭제하지 마라.
- 인수 조건을 충족하지 못한 채 완료 처리하지 마라. 미충족 항목이 있으면
  그 사실을 댓글과 사용자 보고에 명시하고 상태 전환은 보류하라.
