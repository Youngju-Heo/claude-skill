# preproj-workflow 스킬 설계

## 원 요청

> 새로운 클로드 스킬을 추가 하고 싶은데, 기본적으로 devops에 Epic/Issue/Task기반으로 처리를 하지만, 코딩보다는 요구사항분석/설계/자료분류 등의 개발 선행단계처리를 위한 업무를 진행하는 것을 목적으로 합니다.

## 목적

개발 착수 전 선행 업무(고객 요청 대응, 내부 아이디어 가능성 검토)를 Azure DevOps
Task 단위로 처리하고, 그 기록·산출물을 `preproj` 저장소의 Issue 폴더에 일관된
구조로 쌓는다. 기본은 개발 워크플로가 아닌 가벼운 Task 처리이며, 코드가 필요한
Task만 `dev-workflow`를 빌려 쓴다.

- 비목표: Issue/Epic 생성, 메일 발송, 정식 개발 프로젝트 관리.
- 실패로 볼 것: 사용자 확인 없이 보드(상태·제목)나 폴더 구조를 바꾸는 것,
  Task 하나를 위해 4단계 개발 절차를 강제하는 것.
- 아직 구상 단계라 이후 수정을 전제로 한다. 규칙을 과도하게 고정하지 않는다.

## 대상 환경 (고정)

- 프로젝트: `https://dev.azure.com/cberrydevops/study`
- 저장소: `https://dev.azure.com/cberrydevops/study/_git/preproj`

## Work Item 구조

| 계층 | 의미 | 생성 주체 |
|---|---|---|
| Epic | pre-project (선행 업무 묶음) | 사용자 |
| Issue | 대응 항목 하나 (예: A사 요청 건, 아이디어 X 검토) | 사용자 |
| Task | 진행 단위 | 사용자 |

스킬은 Work Item을 생성하지 않는다. 수정은 대상 Task의 **상태·댓글·제목**에 한한다.

### Task 종류와 머리말

Task 제목 앞 머리말로 종류를 구분한다.

| 머리말 | 내용 | 수명 |
|---|---|---|
| `[메일]` | 상대방 단위 메일 대응 | 회신이 오가는 동안 진행 중 유지, 사용자가 종료를 알릴 때 완료 |
| `[미팅]` | 미팅·현장 방문 정리 | 1회성 |
| `[조사]` | 자료 조사·탐색·가능성 검토 | 1회성 |
| `[정리]` | 요구사항 분석·설계·자료 분류 등 결과물 작성 | 1회성 |
| `[테스트개발]` | 평가용 테스트 코드 개발 | 1회성 |

머리말이 없으면 Task 제목·설명으로 종류를 추정해 머리말을 추천하고, 사용자 확인
후 제목에 머리말을 붙인다.

## 저장 구조

```
preproj/
└─ {issue-id}-{issue-slug}/
   ├─ docs/        # 분석·설계 문서, [테스트개발]의 설계·계획 문서
   ├─ meeting/
   │   └─ yymmdd-{대상}-{제목및내용}/
   ├─ mail/
   │   └─ yymmdd-{발신자}-{제목및간략내용}/   # 상대방 단위, 첫 메일 기준으로 명명
   │       ├─ yymmdd-hhmm-{in|out}-{제목}.eml  # 메일마다 누적
   │       ├─ attachments/
   │       └─ summary.md                      # 메일별 섹션을 시간순으로 누적
   ├─ output/      # 정리된 결과물
   ├─ reference/   # 외부 문서·자료
   └─ test/        # [테스트개발] 코드 (필요할 때만 생성)
```

- Issue 폴더나 고정 하위 폴더가 없으면 Issue 정보로 폴더명을 추천하고, 사용자
  확인 후 생성한다.
- `issue-slug`는 Issue 제목의 kebab-case 영문 요약이다.
- 메일·미팅 폴더명의 대상·제목 부분은 한글을 허용하되, eml 파일명·폴더명에서
  Windows 금지 문자(`\ / : * ? " < > |`)는 제거한다.
- `[미팅]`은 준비 단계에서 미팅 폴더명도 추천·생성(확인 후)하고, 사용자가 자료를 넣은
  뒤 진행한다. 재호출된 `[메일]`은 이전 결과 댓글의 경로 또는 폴더명의 `{발신자}`로
  기존 상대방 폴더를 찾는다.
- `{발신자}`는 사내 전달자가 아니라 실제 외부 상대방(조직·사람)이다. 고객 메일을
  사내에서 전달받았다면 고객 이름으로 만든다.
- 기존 구 구조 폴더는 2026-10-30에 새 구조로 이전했다(사용자 결정).

## 처리 흐름

1. **호출**: `/preproj-workflow {task-id}`만 허용한다. Task 번호가 없으면 묻고 중단한다.
   `disable-model-invocation: true`로 사용자 호출 전용이다.
2. **맥락 확인**: Task → 부모 Issue(→ Epic) 순으로 조회하고, Task 댓글과 Issue 폴더
   내용을 읽어 진행 이력을 파악한다. 부모가 Issue가 아니면 폴더를 정할 수 없으므로
   중단하고 사용자에게 Issue 연결을 요청한다(내 판단).
3. **준비**: `preproj` 로컬 클론 위치는 환경변수 `PREPROJ_ROOT`, 없으면 기본값
   `C:\work\preproj`(현재 사용자 환경)를 쓴다. 둘 다 클론이 아니면 위치를 묻고,
   클론이 없으면 클론 여부를 묻는다(내 판단). 작업 전 `git pull`로 최신화한다.
   Issue 폴더 확인·생성, 머리말 확인·추천, 진행 중 상태 전환을 한 번에 확인받는다.
   이미 갖춰진 항목(재호출된 `[메일]` 등)은 건너뛴다.
4. **종류별 처리**: 아래 표.
5. **기록**: 커밋 전에 추가·변경 파일 목록과 크기를 보여주고 확인받는다. 바이너리
   파일이 있는데 `.gitattributes`에 LFS 추적 규칙이 없으면 함께 경고한다. 확인 후
   main에 직접 커밋하고 push한다(`docs: #{task-id} 제목`, 제목은 머리말을 뺀 작업 요약. Co-Authored-By 없음). 스테이징은 이번 Task가
   만들거나 바꾼 파일을 경로로 지정하며(`git add <경로>`) `git add -A`, `commit -a`는 쓰지 않는다. Task에 결과 댓글(작업
   요약, 추가·변경 파일 경로)을 남긴다. 루트 `.gitignore`가 `*/output/*.pdf`,
   `*/output/*.docx`를 무시하므로 add가 거부되면 보존 여부를 묻고 보존할 때만
   `git add -f`를 쓴다.
6. **완료**: 사용자 확인 후 완료 상태로 전환한다. `[메일]`은 매 처리 끝에 대응
   종료 여부를 한 번 묻고, 종료할 때만 완료로 전환한다.

### 종류별 처리

| 종류 | 입력 | 처리 | 산출물 위치 |
|---|---|---|---|
| `[메일]` | 사용자가 다운로드 폴더 등에 받아 둔 `*.eml` (위치를 물어봄). 우리 쪽 발송본도 받아 두면 `out`으로 보관 | 상대방 폴더가 있으면 그곳에 누적, 없으면 첫 메일 기준으로 생성. 원본·첨부 저장, `summary.md`에 메일별 요약 섹션 추가. 회신 초안은 사용자가 요청할 때만 작성 | `mail/yymmdd-발신자-.../` (`*.eml`, `attachments/`, `summary.md`, `reply-draft.md`) |
| `[미팅]` | 사용자가 미팅 폴더에 넣어 둔 메모·자료 | 사용자 요청 방식에 맞춰 정리·요약 | 해당 `meeting/yymmdd-.../` |
| `[조사]` | Task 설명·사용자 지시 | 조사·탐색 수행, 수집 자료 보관, 결과 정리 | 자료 `reference/`, 결과 `output/` |
| `[정리]` | Issue 폴더의 기존 자료 | 요구사항 분석·설계·자료 분류 | `docs/` 또는 `output/` |
| `[테스트개발]` | Task 설명 | `dev-workflow` 절차 수행(경량/전체 경로 판단 포함) | 코드 `test/`, 문서 `docs/` |

`[테스트개발]`에서 `dev-workflow`를 따를 때의 차이:

- 설계·계획 문서는 `docs/feature/...` 대신 `{issue folder}/docs/`에
  `yyyy-mm-dd-{day-sequence}-{task-id}-{feature-name}-design.md` 형식으로 둔다.
- 계획 문서는 같은 위치에 `...-{feature-name}-plan.md`로 둔다.
- 브랜치 `{task-id}-{feature-name}`를 쓰고, 완료 후 PR 없이 main에 직접 머지한다.
  브랜치 커밋은 dev-workflow 규칙을 따르고, main 머지·push 직전에 기록 단계의 확인을
  1회 받는다.

## Azure DevOps 접근

`devops-workflow`의 방식을 그대로 따른다: `devops-workflow/scripts/ado.ps1`
REST 헬퍼를 참조해 사용(복사하지 않음), 비ASCII 조작은 REST, 새 PAT 요구 금지,
MCP 서버 미사용. 제목 변경은 헬퍼의 `Set-AdoWorkItemField`로 한다.

## 네이밍

| 대상 | 이름 |
|---|---|
| 스킬 | `preproj-workflow` |
| 스킬 위치 | `.claude/skills/preproj-workflow/SKILL.md` |
| Issue 폴더 | `{issue-id}-{issue-slug}` |
| 메일 요약 | `summary.md` |
| 메일 회신 초안 | `reply-draft.md` |
| 미팅 정리 | `summary.md` |

## preproj 저장소 README

`preproj/README.md`를 새로 만들어 사람이 읽는 사용 규칙을 둔다. 스킬과 같은
규칙을 담되 스킬 사용 없이도 이해되게 쓴다.

- 저장소 목적, Epic/Issue/Task 구조
- Issue 폴더 구조와 명명 규칙, Task 머리말
- 커밋 규칙(main 직접 커밋, 메시지 형식)
- Git LFS 설정법(`git lfs install`, `git lfs track`, `.gitattributes` 커밋)과
  기존 파일 처리 선택지(`--no-rewrite` / 이력 재작성)
- 루트 `.gitignore`가 `*/output/*.pdf`, `*/output/*.docx`(markdown에서 생성한 산출물)를 무시하며, 남길 파일은 `git add -f`로 추가한다는 안내

README와 함께 `.gitattributes`(LFS 추적 규칙)도 커밋해 LFS를 적용한다(사용자 결정).
기존 바이너리는 이력 재작성 없이 일반 커밋으로 LFS 전환했고, 기존 구 구조 폴더는 새 구조로 이전했다. 커밋·push는 사용자 확인 후 진행한다. 스킬의 SKILL.md는 이 README를
참조하지 않고 자체 규칙을 가진다(스킬이 저장소 상태에 의존하지 않게).

## 범위 밖 / 후속

- Codex용(`.agents/skills/preproj-workflow/`)은 이번에 만들지 않는다.
- 문서 갱신: `README.md`, `PROJECT_OVERVIEW.md`에 스킬 소개·배치를 추가한다.

## 빌더에게 맡기는 것

- SKILL.md의 문장 구성과 섹션 배치(기존 `devops-workflow` 문체를 따름).
- 결과 댓글의 HTML 형식.
