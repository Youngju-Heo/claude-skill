# preproj-workflow 스킬 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 원 요청

> 새로운 클로드 스킬을 추가 하고 싶은데, 기본적으로 devops에 Epic/Issue/Task기반으로 처리를 하지만, 코딩보다는 요구사항분석/설계/자료분류 등의 개발 선행단계처리를 위한 업무를 진행하는 것을 목적으로 합니다.

**Goal:** Task 번호로 호출해 선행 업무를 처리하고 `preproj` Issue 폴더에 산출물을 쌓는 `preproj-workflow` 스킬과, `preproj` 저장소의 사용 규칙 README·LFS 설정을 만든다.

**Architecture:** 산출물은 Markdown 문서뿐이다(실행 코드 없음). 스킬은 `devops-workflow`의 형식·문체와 REST 헬퍼(`ado.ps1`)를 재사용하고, `[테스트개발]`만 `dev-workflow`에 위임한다. `preproj` 저장소에는 사람용 README와 `.gitattributes`를 추가한다.

**Tech Stack:** Claude Code 스킬(SKILL.md frontmatter), PowerShell 7 + `ado.ps1`, Git LFS 3.8.

**Spec:** `docs/feature/2026-10/2026-10-30-01-preproj-workflow-design.md` — 실행자는 설계 문서를 함께 읽는다. 규칙 값(머리말, 폴더 구조, 명명, 확인 지점)은 설계 문서가 원본이다.

## Global Constraints

- 문서·SKILL.md는 한국어. 커밋 메시지는 `<type>: <제목>` 형식, `Co-Authored-By` 금지.
- 대상: 프로젝트 `https://dev.azure.com/cberrydevops/study`, 저장소 `preproj`, 로컬 `PREPROJ_ROOT` → 기본 `C:\work\preproj`.
- 호출: `/preproj-workflow {task-id}`, `disable-model-invocation: true`.
- Task 머리말: `[메일]` `[미팅]` `[조사]` `[정리]` `[테스트개발]`.
- 스킬이 수정하는 Work Item 필드: 대상 Task의 상태·댓글·제목만. Work Item 생성 금지.
- 보드 변경(상태·제목), 폴더 생성, 커밋·push는 모두 사용자 확인 후.
- `ado.ps1`은 `$HOME/.claude/skills/devops-workflow/scripts/ado.ps1`을 참조, 복사 금지. 비ASCII 조작은 REST. 새 PAT 요구 금지. MCP 미사용.
- `ado.ps1`의 기본 조직은 `az devops configure`에 의존하므로 SKILL.md는 `$env:ADO_ORG='https://dev.azure.com/cberrydevops'`, `$env:ADO_PROJECT='study'`를 먼저 설정하도록 쓴다.

## Review Focus

- 재호출된 `[메일]` Task: 상대방 폴더가 이미 있을 때 새 폴더를 만들지 않고 누적하는지, 준비 단계 확인을 건너뛰는지.
- 부모가 Issue가 아닌 Task(부모 없음, Epic 직속): 폴더를 추측해 만들지 않고 중단하는지.
- 머리말 없는 Task: 추정 머리말을 추천하고, 확인 전 제목을 바꾸지 않는지.
- 바이너리 첨부가 섞인 커밋: 파일 목록·크기를 보여주고 LFS 미추적 바이너리를 경고하는지.
- `C:\work\preproj`에 로컬 변경이 남아 있는 상태: `git pull` 전 사용자에게 알리는지.

이 문서들은 자동 테스트가 없으므로, 위 항목은 Task 1의 검증 단계에서 SKILL.md 본문에 해당 규칙이 명시돼 있는지로 확인한다.

---

### Task 1: preproj-workflow SKILL.md

**Files:**
- Create: `.claude/skills/preproj-workflow/SKILL.md`

**Interfaces:**
- Consumes: `devops-workflow/scripts/ado.ps1`의 `Get-AdoWorkItem`, `Invoke-Ado`, `Add-AdoWorkItemComment`, `Set-AdoWorkItemState`, `Set-AdoWorkItemField`. 부모 조회는 `Invoke-Ado -Path "_apis/wit/workitems/{id}?`$expand=relations"`의 `System.LinkTypes.Hierarchy-Reverse` 관계로 한다. 댓글 조회는 `Invoke-Ado -Path "study/_apis/wit/workItems/{id}/comments" -ApiVersion '7.1-preview.3'`.
- Produces: 스킬 이름 `preproj-workflow` (Task 2 문서가 참조).

- [ ] **Step 1: frontmatter 작성**

`name: preproj-workflow`, `description`(Task 번호로 선행 업무 처리·preproj 폴더 기록을 한 문장), `argument-hint: "[task-id]"`, `disable-model-invocation: true`.

- [ ] **Step 2: 본문 작성**

`devops-workflow/SKILL.md`의 섹션 형식(번호 붙은 `##` 단계, 마지막 `## 제약`)을 따른다. 섹션:

0. 사전 확인 — 접근 수단(devops-workflow 방식 요약 + `ado.ps1` 경로, `ADO_ORG`/`ADO_PROJECT` 설정), 로컬 위치 결정 규칙, 작업 전 `git status`로 미커밋 변경 확인 후 `git pull`.
1. Task·Issue 확인 — Task 번호 필수, 부모 Issue(→ Epic) 조회, 부모가 Issue가 아니면 중단, Task 댓글과 Issue 폴더 내용으로 이력 파악.
2. 준비 — Issue 폴더(`{issue-id}-{issue-slug}`)와 고정 하위 폴더(`docs` `meeting` `mail` `output` `reference`) 확인, 없으면 폴더명 추천; 머리말 없으면 제목·설명으로 추정해 추천; 진행 중 상태 전환. 이 셋을 한 번에 확인받는다. 이미 갖춰진 항목은 건너뛴다. 상태명은 이 조직 기준 할일/진행중/완료이되 실제 허용 상태를 확인한다.
3. 종류별 처리 — 설계 문서의 "종류별 처리" 표와 메일 폴더 구조(`yymmdd-hhmm-{in|out}-{제목}.eml`, `attachments/`, 누적 `summary.md`, 요청 시 `reply-draft.md`)를 옮긴다. `.eml`은 위치를 묻고 받는다. `[테스트개발]`은 dev-workflow 위임과 문서 경로·브랜치·직접 머지 차이를 명시.
4. 기록 — 파일 목록·크기 제시, `.gitattributes` 미추적 바이너리 경고, 확인 후 main 커밋·push(`docs: #{task-id} 제목`), Task 결과 댓글(HTML, 요약 + 파일 경로).
5. 완료 — 확인 후 완료 전환. `[메일]`은 매 처리 끝에 대응 종료 여부를 묻고 종료 시에만 전환. 전환 후 상태 재조회로 반영 확인.
제약 — 수정 가능 필드, Work Item 생성 금지, 메일 직접 발송 금지.

- [ ] **Step 3: 검증**

Run: `grep -c "disable-model-invocation: true" .claude/skills/preproj-workflow/SKILL.md` → `1`.
Review Focus 5개 항목과 Global Constraints의 확인 지점이 본문에 각각 명시돼 있는지 대조한다.
읽기 전용 동작 확인: `ado.ps1`을 로드해 `ADO_ORG`/`ADO_PROJECT`를 설정한 뒤, 스킬에 적은 부모 조회 호출이 `study` 프로젝트에서 오류 없이 동작하는지 `_apis/wit/wiql`로 임의 Task 하나를 찾아 확인한다(쓰기 금지).

- [ ] **Step 4: 커밋**

```bash
git add .claude/skills/preproj-workflow/SKILL.md
git commit -m "feat: preproj-workflow 스킬 추가"
```

### Task 2: claude-skill 저장소 문서 갱신

**Files:**
- Modify: `README.md` (6장 뒤에 preproj-workflow 장 추가, 서두 "구성은 4가지" 문장 갱신)
- Modify: `PROJECT_OVERVIEW.md` (구조 트리, 각 파일의 역할)

**Interfaces:**
- Consumes: Task 1의 스킬 이름·호출법·사전 조건.

- [ ] **Step 1: README.md에 장 추가**

내용: 목적(선행 업무), 배치 경로, 사전 조건(devops-workflow 설치 필수 — `ado.ps1` 참조, az 로그인, `PREPROJ_ROOT` 또는 `C:\work\preproj`), 사용법 `/preproj-workflow {task-id}`, Task 머리말 표, 동작 요약 5줄. 이후 장 번호를 하나씩 민다.

- [ ] **Step 2: PROJECT_OVERVIEW.md 갱신**

트리에 `preproj-workflow/SKILL.md` 추가, 역할 항목 1개 추가.

- [ ] **Step 3: 검증**

Run: `grep -n "preproj-workflow" README.md PROJECT_OVERVIEW.md` → 두 파일 모두 일치 행 존재. README 장 번호가 연속인지 확인.

- [ ] **Step 4: 커밋**

```bash
git add README.md PROJECT_OVERVIEW.md
git commit -m "docs: preproj-workflow 사용법 추가"
```

### Task 3: preproj 저장소 README와 LFS 적용

작업 위치: `C:\work\preproj` (main 브랜치, 이 저장소와 별개).

**Files:**
- Create: `C:\work\preproj\README.md`
- Create: `C:\work\preproj\.gitattributes`

- [ ] **Step 1: 최신화**

Run: `git -C C:/work/preproj status -sb` → 미커밋 변경 없음 확인 후 `git -C C:/work/preproj pull`.

- [ ] **Step 2: LFS 추적 설정**

```powershell
git -C C:/work/preproj lfs install
git -C C:/work/preproj lfs track "*.pdf" "*.eml" "*.zip" "*.png" "*.jpg" "*.docx" "*.xlsx" "*.pptx"
```

Expected: `.gitattributes`에 8개 패턴이 `filter=lfs diff=lfs merge=lfs -text`로 생성.

- [ ] **Step 3: README.md 작성**

설계 문서 "preproj 저장소 README" 절의 항목(목적, Epic/Issue/Task 구조, 폴더 구조·명명, 머리말, 커밋 규칙, LFS 설정법과 기존 파일 처리 선택지)을 사람용으로 쓴다. 스킬 없이도 이해되게 쓰고, 스킬은 "있으면 `/preproj-workflow {task-id}`로 처리 가능" 한 줄로만 언급.

- [ ] **Step 4: 사용자 확인 후 커밋·push**

추가 파일 목록을 보여주고 확인받은 뒤:

```bash
git -C C:/work/preproj add .gitattributes README.md
git -C C:/work/preproj commit -m "docs: 저장소 사용 규칙 README와 LFS 추적 설정 추가"
git -C C:/work/preproj push
```

Expected: `git -C C:/work/preproj lfs track`이 8개 패턴을 출력하고, `git status -sb`가 `## main...origin/main`.
