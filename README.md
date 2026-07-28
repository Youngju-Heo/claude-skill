# CLAUDE.md + dev-workflow 스킬 적용법

Opus 5 출시에 맞춰 기존 카파시 스타일 CLAUDE.md를 조정한 구성입니다.
파일은 2개입니다: `CLAUDE.md`(판단 원칙), `dev-workflow/SKILL.md`(개발 절차).

## 1. 파일 배치

### CLAUDE.md

프로젝트 루트의 기존 `CLAUDE.md`를 이 파일로 교체합니다.

```
{프로젝트 루트}/CLAUDE.md
```

여러 프로젝트에 공통 적용하려면 전역 위치에 둘 수도 있습니다.

```
~/.claude/CLAUDE.md
```

(전역과 프로젝트 파일이 둘 다 있으면 둘 다 로드되므로, 내용이 중복되지 않게
한쪽에만 두는 것을 권장합니다.)

### dev-workflow 스킬

`SKILL.md`를 `dev-workflow` 폴더째로 스킬 디렉토리에 넣습니다.

프로젝트 전용으로 쓸 경우:

```
{프로젝트 루트}/.claude/skills/dev-workflow/SKILL.md
```

모든 프로젝트에서 쓸 경우:

```
~/.claude/skills/dev-workflow/SKILL.md
```

배치 후 Claude Code를 재시작하고, `/skills` 목록(또는 새 기능 개발을 시작해
보는 것)으로 스킬이 인식되는지 확인합니다. `dev-workflow`가 목록에 보이면
정상입니다. 기획/설계나 새 기능 개발을 시작하면 description에 의해 자동으로
로드되고, `/dev-workflow`로 직접 호출할 수도 있습니다.

## 2. 사전 조건

- 스킬 본문이 superpowers 플러그인의 스킬들(brainstorming, writing-plans,
  subagent-driven-development, test-driven-development,
  requesting-code-review)을 참조하므로, superpowers 플러그인이 설치되어
  있어야 합니다.
- 기존 CLAUDE.md에 있던 5번(문서화)·6번(개발 진행) 항목은 스킬로 이동했으니,
  교체 후 기존 파일에 남은 사본이 없는지 확인하세요. 같은 내용이 CLAUDE.md와
  스킬 양쪽에 있으면 중복 지시가 되어 Opus 5에서는 오히려 손해입니다.

## 3. 무엇이 왜 바뀌었나 (요약)

- **2번 단순함**: 첫머리에 "요청받은 것을, 의도된 범위에서 수행하라" 추가.
  Opus 5는 스스로 작업 범위를 넓히는 성향이 있어 명시적 경계가 필요합니다.
- **4번 목표 중심 실행**: 단계별 `→ 검증: [체크]` 템플릿 삭제, "성공 기준
  통과 시 완료, 별도 재확인 단계 금지"로 교체. Opus 5는 지시 없이도 스스로
  검증하므로 명시적 검증 지시는 과잉 검증과 토큰 낭비를 유발합니다.
- **5번 응답 스타일 신설**: Opus 5는 기본 응답이 길어졌고 effort 설정으로
  출력 길이가 제어되지 않아, 간결성 지시를 명시하는 것이 공식 권장입니다.
- **6번 서브에이전트 신설**: Opus 5는 서브에이전트 위임이 공격적으로 늘어난
  모델이라 위임 조건과 상한을 명시했습니다.
- **기존 5·6번 → 스킬 분리**: 판단 원칙이 아닌 작업 절차는 필요할 때만
  로드되도록 스킬로 분리(progressive disclosure). CLAUDE.md는 항상 로드되는
  비용을 지불하므로 짧을수록 좋습니다.
- **스킬 내 추가 사항**: "최종리뷰 1회" 유지(과잉 검증 방지), "심각도 무관
  전부 보고" 추가(Opus 5는 필터가 있으면 과소 보고), 문서 분량 제어 한 줄
  추가(길어진 출력 성향 대응).

## 4. 프로젝트별로 다른 dev-workflow 골라 쓰기

스킬 변형을 여러 개 만들어 두고(웹용, API용, 배치용 등) 프로젝트마다 골라
쓸 수 있습니다. 방법은 세 가지입니다.

### 방법 1 — 프로젝트별 배치 (권장, 가장 단순)

각 프로젝트의 `.claude/skills/dev-workflow/SKILL.md`에 그 프로젝트에 맞는
변형을 넣습니다. 프로젝트 레벨 스킬은 해당 프로젝트에서만 로드됩니다.
이름을 전부 `dev-workflow`로 통일하면 CLAUDE.md의 참조를 프로젝트마다
고칠 필요가 없습니다.

**주의**: 같은 이름의 스킬이 여러 레벨에 있으면 개인(`~/.claude/skills`)이
프로젝트(`.claude/skills`)를 덮어씁니다(enterprise > personal > project).
이 방식을 쓸 때는 전역에 같은 이름의 `dev-workflow`를 남겨두지 마세요 —
전역 사본이 있으면 프로젝트별 변형이 무시됩니다.

### 방법 2 — 전역 라이브러리 + 프로젝트별 on/off

변형들을 서로 다른 이름으로 전역에 두고(`dev-workflow-web`,
`dev-workflow-api`, …) 각 프로젝트에서 안 쓰는 것을 끕니다. `/skills`
메뉴에서 스킬을 선택하고 `Space`로 상태를 바꾸면
`.claude/settings.local.json`에 저장됩니다.

```json
{
  "skillOverrides": {
    "dev-workflow-api": "off",
    "dev-workflow-batch": "off"
  }
}
```

`"off"`는 완전히 숨기고, `"name-only"`는 이름만 노출해 컨텍스트 비용을
줄입니다. 명시하지 않은 스킬은 `"on"`입니다. 이 방식은 프로젝트
CLAUDE.md의 참조 이름도 선택한 변형에 맞게 바꿔야 합니다.

### 방법 3 — 모노레포라면 중첩 스킬

Claude Code는 작업 디렉토리 하위의 `.claude/skills/`도 인식합니다.
`apps/web/.claude/skills/dev-workflow/`에 두면 그 패키지의 파일을 다룰 때
자동으로 활성화되고, 루트에 같은 이름이 있으면 `apps/web:dev-workflow`처럼
디렉토리 한정 이름으로 둘 다 사용할 수 있습니다. 패키지별로 워크플로가
다른 모노레포에 적합합니다.

**추가 팁**: 스킬 frontmatter의 `paths` 필드(glob 패턴)를 쓰면 특정 파일을
다룰 때만 스킬이 자동 활성화되게 할 수 있어, 방법 1·3과 조합 가능합니다.

정리: 독립 프로젝트 여러 개면 방법 1, 변형을 중앙에서 관리하고 싶으면
방법 2, 모노레포면 방법 3.

## 5. 코드 작성 규칙 — 언어별 적용 (.claude/rules/)

코드 규칙(네이밍 등)은 스킬이 아니라 `.claude/rules/` 디렉토리의
**path-scoped rules**로 관리합니다. frontmatter의 `paths` glob 패턴과
일치하는 파일을 Claude가 읽거나 수정할 때만 해당 규칙이 로드되므로,
언어별 적용이 정확하고 불필요한 컨텍스트 소비가 없습니다.
(dev-workflow 스킬에 넣지 않는 이유: 스킬은 기능 개발 워크플로를 탈 때만
로드되어, 간단한 버그 수정 세션에서는 코드 규칙이 빠지게 됩니다.)

### 파일 배치

```
{프로젝트 루트}/.claude/rules/
├── code-common.md   # paths 없음 → 항상 로드 (언어 공통: 로그는 영어 등)
├── python.md        # paths: "**/*.py" → Python 파일 작업 시만 로드
└── typescript.md    # paths: "**/*.{ts,tsx}" → TS 파일 작업 시만 로드
```

`paths`가 없는 규칙은 CLAUDE.md와 같은 우선순위로 항상 로드됩니다.
`paths`가 있는 규칙은 해당 패턴의 파일을 읽을 때 로드됩니다. 패턴은
glob 문법이며 brace 확장(`*.{ts,tsx}`), 복수 패턴 지정이 가능합니다.

```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "tests/**/*.test.ts"
---

# TypeScript 규칙
...
```

모든 프로젝트에 공통 적용하려면 `~/.claude/rules/`에 두면 됩니다.
사용자 레벨 규칙이 먼저 로드되고 프로젝트 규칙이 나중에 로드되므로,
충돌 시 프로젝트 규칙이 우선하는 효과가 있습니다. 여러 프로젝트에서
공유하려면 심볼릭 링크도 지원됩니다:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
```

### 작성 시 주의

- 동봉된 python.md / typescript.md의 규칙은 **예시**입니다. 팀 컨벤션에
  맞게 수정하고, 쓰지 않는 언어 파일은 삭제하세요. 다른 언어는 같은
  형식으로 추가하면 됩니다(예: go.md에 `paths: "**/*.go"`).
- 생태계 표준(PEP 8, camelCase 등)과 동일한 규칙은 삭제하세요. 모델이
  기본으로 따르므로 오버헤드만 됩니다. 남길 가치가 있는 것은 표준과
  다르거나 유추 불가능한 것들입니다: 도메인 용어 번역 규칙, 금지 패턴,
  팀 고유 컨벤션.
- 신규 프로젝트에서는 초기 파일들이 이후의 "주변 코드" 기준이 되므로
  규칙이 가장 큰 힘을 발휘합니다. 코드베이스가 쌓인 뒤에는 deletion
  test로 규칙을 슬림하게 줄여가세요.
- dev-workflow 스킬의 설계 문서에 "주요 엔티티·모듈 네이밍" 항목이
  포함되도록 갱신했습니다. 신규 프로젝트의 첫 기능부터 네이밍이 설계
  단계에서 고정되고 구현이 이를 따릅니다.
- 규칙은 지침이지 강제가 아닙니다. 반드시 지켜져야 하는 것(예: 커밋 전
  린트)은 hook으로 거는 것이 확실합니다.

## 6. devops-workflow 스킬 (Azure DevOps 일감 연동)

Azure DevOps의 Task를 확인하고 → dev-workflow 절차로 개발하고 → 일감을
완료 처리하는 스킬입니다. dev-workflow와 같은 위치에 배치합니다.

```
{프로젝트 루트}/.claude/skills/devops-workflow/SKILL.md
```

### 사전 조건

- dev-workflow 스킬이 함께 설치되어 있어야 합니다(개발 절차를 위임).
- Azure DevOps 접근 수단이 하나 필요합니다. 둘 중 하나:
  - **Azure DevOps MCP 서버** (권장): Microsoft 공식
    `microsoft/azure-devops-mcp`를 `claude mcp add`로 등록
  - **az CLI**: `az extension add --name azure-devops` 후
    `az devops login` (PAT 필요)

### 사용법

```
/devops-workflow 12345
```

`disable-model-invocation: true`로 설정되어 있어 사용자가 직접 호출할
때만 실행됩니다(Claude가 임의로 일감 상태를 바꾸는 것을 방지).
Work Item 조회·요구사항 확인 후 진행 여부를 물어보고, 완료 상태 전환도
반드시 사용자 확인을 받은 뒤 수행합니다.

### dev-workflow와의 선택 적용

두 스킬은 **함께 설치해 두고, 프로젝트별로 CLAUDE.md에서 하나를 선택**해
사용합니다. devops-workflow는 개발 절차를 dev-workflow에 위임하므로,
devops-workflow를 쓰는 프로젝트에도 dev-workflow가 반드시 설치되어
있어야 합니다.

선택 방법: CLAUDE.md의 "7. 기능 개발 워크플로" 섹션에 두 가지 지시문이
있습니다(일반 프로젝트용 / Azure DevOps 프로젝트용). 프로젝트에 맞는
쪽만 남기고 다른 쪽은 HTML 주석(`<!-- -->`)으로 감싸 두세요.

- HTML 주석은 컨텍스트에 로드되지 않으므로, 주석 처리해 두면 토큰
  비용 없이 파일 안에 보관됩니다. 나중에 전환할 때 주석만 바꾸면 됩니다.
- 일반 프로젝트: dev-workflow 지시문만 활성. Azure DevOps 없이도 기존과
  동일하게 동작합니다.
- Azure DevOps 프로젝트: devops-workflow 지시문만 활성. Claude는 Work
  Item 기반 요청을 받으면 `/devops-workflow {id}` 실행을 안내합니다
  (스킬 자체는 사용자만 호출 가능하도록 잠겨 있습니다).
- 두 지시문을 동시에 활성화하지 마세요. 어느 워크플로를 따를지 충돌이
  생겨 Claude가 임의로 하나를 고를 수 있습니다.

### 동작 요약

1. Work Item(+ 부모 항목·댓글) 조회 → 요구사항 요약 → 사용자 확인
2. 상태를 진행 중으로 전환, `{id}-{feature-name}` 브랜치 생성
3. dev-workflow 절차 수행 (인수 조건 → 설계 문서의 성공 기준으로 반영,
   커밋 메시지에 `#{id}` 포함해 Work Item 연결)
   - 머지 범위: 소스 머지는 Work Item 브랜치까지만. 통합 브랜치
     (main/develop) 직접 머지 금지
4. PR 생성(Work Item 브랜치 → 통합 브랜치, PR 머지는 사람의 결정) →
   결과 댓글(문서 경로·브랜치·PR·인수 조건 충족 여부) 작성 →
   사용자 확인 후 완료 상태 전환 → 반영 확인 및 보고

## 7. 적용 후 점검

한두 작업을 실제로 돌려보고 아래를 확인하세요.

- 검증이 과하게 반복되지 않는지 (반복되면 4번을 더 강하게: "테스트 1회
  통과로 종료")
- 응답·문서가 여전히 길면 5번 응답 스타일을 더 구체적으로 조정
- 새 기능 시작 시 dev-workflow 스킬이 자동으로 로드되는지

이후에는 deletion test로 다듬어 가세요: 규칙을 하나 지우고 결과 품질이
유지되면 그 규칙은 불필요한 오버헤드였던 것입니다. `claude doctor`로 현재
설정 진단도 가능합니다.
