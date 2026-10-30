---
name: preproj-workflow
description: Azure DevOps의 Task 번호를 받아 개발 선행 업무(메일 대응, 미팅 정리, 조사, 요구사항 정리, 테스트 개발)를 처리하고, 산출물을 preproj 저장소의 Issue 폴더에 기록한 뒤 Task를 갱신할 때 사용한다.
argument-hint: "[task-id]"
disable-model-invocation: true
---

# 개발 선행 업무 워크플로 (preproj)

Epic(pre-project) → Issue(대응 항목) → Task(진행 단위) 구조의 Azure DevOps Task를
처리하고, 기록·산출물을 `preproj` 저장소의 Issue 폴더에 쌓는다. 기본은 가벼운
Task 처리이며, 코드가 필요한 `[테스트개발]`만 dev-workflow를 따른다.

대상: 프로젝트 `https://dev.azure.com/cberrydevops/study`, 저장소 `.../_git/preproj`.
아직 구상 단계이므로 규칙을 이 문서 밖으로 확장하지 마라.

## 0. 사전 확인

- Azure DevOps 접근은 devops-workflow의 방식을 따른다. **REST 헬퍼**
  `$HOME/.claude/skills/devops-workflow/scripts/ado.ps1`을 참조해 쓰고(복사 금지),
  비ASCII 조작은 REST로 하라(devops-workflow의 "인코딩 함정과 REST 우선"). 새 PAT를
  요구하지 말고, MCP 서버는 쓰지 마라.

  ```powershell
  . "$HOME/.claude/skills/devops-workflow/scripts/ado.ps1"
  $env:ADO_ORG = 'https://dev.azure.com/cberrydevops'; $env:ADO_PROJECT = 'study'
  ```

  `$HOME/.claude/skills/devops-workflow/scripts/ado.ps1`이 없으면
  `{cwd}/.claude/skills/devops-workflow/scripts/ado.ps1`을 시도하고, 그래도 없으면
  위치를 묻고 중단하라.

- `preproj` 로컬 클론 위치: 환경변수 `PREPROJ_ROOT`, 없으면 `C:\work\preproj`.
  이 경로가 git 클론이 아니면 위치를 묻고, 사용자가 클론이 없다고 하면 클론할지 물어라.
  git 명령은 `git -C <root>`로 실행하라.
- 작업 전 `git status`로 미커밋 변경을 확인하라. 있으면 사용자에게 알리고 처리
  방법을 물어라. 깨끗하면 `git pull`로 최신화하라.

## 1. Task·Issue 확인

`$ARGUMENTS`의 Task 번호만 받는다. 없으면 묻고 중단하라.

- Task 조회: `Get-AdoWorkItem -Id {id}` (제목, 설명, 상태).
- 부모 조회: 아래 경로의 `System.LinkTypes.Hierarchy-Reverse` 관계 URL 끝의 ID가
  부모다.

  ```powershell
  Invoke-Ado -Path '_apis/wit/workitems/{id}?$expand=relations'
  ```

  부모 ID로 `Get-AdoWorkItem`을 호출해 `fields.'System.WorkItemType' -eq 'Issue'`인지
  확인하고, Issue면 그 부모(Epic)도 조회하라.
- **부모가 Issue가 아니면 Issue 폴더를 정할 수 없다.** 중단하고 Issue 연결을
  요청하라.
- 댓글: `Invoke-Ado -Path "study/_apis/wit/workItems/{id}/comments" -ApiVersion '7.1-preview.3'`
- 이력 파악: Task 댓글과 Issue 폴더(`{issue-id}-*`로 찾는다)의 기존 내용을 읽어라.

## 2. 준비

다음 세 가지를 **한 번에** 확인받아라. 이미 갖춰진 항목(재호출된 `[메일]` 등)은
건너뛴다.

- **Issue 폴더** `{issue-id}-{issue-slug}`(기존 폴더는 `{issue-id}-*`로 찾는다)와 고정 하위 폴더 `docs` `meeting` `mail`
  `output` `reference`. 없으면 폴더명을 추천하라. `[미팅]`이면 미팅 폴더명
  (`yymmdd-{대상}-{제목및내용}`)도 추천해 확인 후 만들고, 사용자가 자료를 넣은 뒤
  진행하라. `[메일]`의 새 상대방 폴더 생성도 이 확인에 포함한다. `issue-slug`는 Issue 제목의
  kebab-case 영문 요약이다. `test/`는 `[테스트개발]`에서 필요할 때만 만든다.
- **머리말**: Task 제목 앞 머리말(`[메일]` `[미팅]` `[조사]` `[정리]` `[테스트개발]`)이
  없으면 제목·설명으로 종류를 추정해 추천하라. 확인 후 `Set-AdoWorkItemField`로
  제목에 붙인다.
- **진행 중 전환**: 팀 보드에 즉시 반영되므로 확인 후 전환하라. 상태명을 하드코딩하지
  마라. 전환은 `Set-AdoWorkItemState`로 하며, 전환 전에 `Invoke-Ado -Path "study/_apis/wit/workitemtypes/Task/states"`로 허용
  상태를 조회해 진행 중/완료에 해당하는 이름을 골라라(현재 `To Do` / `Doing` / `Done`).

## 3. 종류별 처리

| 종류 | 입력 | 처리 | 산출물 위치 |
|---|---|---|---|
| `[메일]` | `*.eml` (위치를 묻고 받는다). 우리 쪽 발송본도 받으면 `out`으로 보관 | 상대방 폴더가 있으면 누적(재호출 시 이전 결과 댓글의 경로 또는 폴더명의 `{발신자}`로 찾는다), 없으면 첫 메일 기준으로 생성. 원본·첨부 저장, `summary.md`에 메일별 섹션 추가. 회신 초안은 사용자가 요청할 때만 | `mail/yymmdd-{발신자}-{제목및간략내용}/` (`{발신자}`는 사내 전달자가 아니라 실제 외부 상대방(조직·사람). 고객 메일을 사내에서 전달받았다면 고객 이름) |
| `[미팅]` | 사용자가 미팅 폴더에 넣은 메모·자료 | 사용자 요청 방식대로 정리·요약(`summary.md`) | `meeting/yymmdd-{대상}-{제목및내용}/` |
| `[조사]` | Task 설명·사용자 지시 | 조사·탐색, 수집 자료 보관, 결과 정리 | 자료 `reference/`, 결과 `output/` |
| `[정리]` | Issue 폴더의 기존 자료 | 요구사항 분석·설계·자료 분류 | `docs/` 또는 `output/` |
| `[테스트개발]` | Task 설명 | dev-workflow 절차 수행(경량/전체 경로 판단 포함) | 코드 `test/`, 문서 `docs/` |

메일 폴더 구조:

```
mail/yymmdd-{발신자}-{제목및간략내용}/   # 상대방 단위
├─ yymmdd-hhmm-{in|out}-{제목}.eml        # 메일마다 누적
├─ attachments/
├─ summary.md                            # 메일별 섹션을 시간순으로 누적
└─ reply-draft.md                        # 요청 시에만
```

메일·미팅 폴더명의 대상·제목 부분은 한글을 허용한다. eml 파일명·폴더명에서는
Windows 금지 문자(`\ / : * ? " < > |`)를 제거한다(예: "FW:" → "FW").

`[테스트개발]`에서 dev-workflow를 따를 때의 차이:

- 설계·계획 문서는 `docs/feature/...` 대신 `{issue folder}/docs/`에
  `yyyy-mm-dd-{day-sequence}-{task-id}-{feature-name}-design.md` 형식으로 둔다.
- 계획 문서는 같은 위치에 `yyyy-mm-dd-{day-sequence}-{task-id}-{feature-name}-plan.md`로
  둔다.
- 브랜치는 `{task-id}-{feature-name}`이며, 완료 후 **PR 없이 main에 직접 머지**한다.
  브랜치 커밋은 dev-workflow 규칙을 따르고, main 머지·push 직전에 아래 §4 확인(파일
  목록·크기)을 1회 받는다.

## 4. 기록

1. 추가·변경 파일 목록과 크기를 보여주고 확인받아라.
2. 바이너리 파일이 있는데 저장소 `.gitattributes`에 LFS 추적 규칙이 없으면 함께
   경고하라.
3. 확인 후 main에 직접 커밋하고 push하라. 메시지는 `docs: #{task-id} 제목`이며
   제목은 머리말을 뺀 작업 요약이다(예: `docs: #601 고객사 2차 회신 정리`).
   Co-Authored-By는 넣지 마라.
   스테이징은 이번 Task가 만들거나 바꾼 파일을 경로로 지정하라(`git add <경로>`).
   `git add -A`와 `git commit -a`는 쓰지 마라.
   preproj 루트 `.gitignore`가 `*/output/*.pdf`, `*/output/*.docx`를 무시한다. add가
   ignore로 거부되면 사용자에게 보존 여부를 묻고, 보존할 때만 `git add -f <경로>`를
   쓴다.
4. **push할 때마다** Task에 결과 댓글을 1건 남겨라(HTML). `[테스트개발]`의 브랜치
   push도 포함한다. 이번 push의 커밋 메시지, 작업 내용 간략 요약, 추가·변경 파일
   경로를 담는다. 한글이 들어가므로 `Add-AdoWorkItemComment`(REST)로 작성하라.

## 5. 완료

- 사용자 확인 후 완료 상태로 전환하라. 확인 없이 전환하지 마라.
- `[메일]`은 매 처리 끝에 대응 종료 여부를 한 번 묻고, **종료할 때만** 완료로
  전환하라. 그 외에는 진행 중을 유지한다.
- 완료 전환 직전에 Task와 부모 Issue의 Description(`System.Description`)을 확인하라.
  비어 있거나, 제목을 반복한 수준이거나, 목적·범위를 알 수 없으면 부실로 본다.
  부실하면 최초 결과 댓글과 산출물을 바탕으로 목적·범위·주요 결과를 요약한 초안을
  보여주고 확인받은 뒤 `Set-AdoWorkItemField`(HTML)로 반영하라. 기존 내용은
  지우지 말고 요약을 덧붙인다. 둘 다 충분하면 건너뛴다.
- 완료 전환도 `Set-AdoWorkItemState`로 한다.
- 전환 후 Task를 다시 조회해 상태가 반영됐는지 확인하라.

## 제약

- 수정 가능한 것은 대상 Task의 상태·댓글·제목·Description과 부모 Issue의
  Description뿐이다.
- Work Item(Epic/Issue/Task)을 생성·삭제하지 마라.
- 메일을 직접 발송하지 마라. 회신 초안 작성까지만 한다.
- 사용자 확인 없이 보드(상태·제목)나 폴더 구조를 바꾸지 마라.
