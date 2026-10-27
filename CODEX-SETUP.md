# Claude와 Codex 함께 사용하기

## 포함한 파일

- `.claude/`: 원본 그대로 보존한 Claude 구성. README와 PROJECT_OVERVIEW에는 Codex 안내도 포함한다.
- `.codex/AGENTS.md`: 대상 프로젝트 루트의 `AGENTS.md`로 복사할 코딩 지침. 저장소 루트 `AGENTS.md`는 유지보수 전용이며 배포하지 않는다.
- `.agents/skills/dev-workflow/`: superpowers 스킬을 단계별로 적용하는 개발 절차.
- `.agents/skills/devops-workflow/`: 명시적으로 호출하는 Azure DevOps 절차와 원본 REST 헬퍼.
- `.agents/rules/`: AGENTS.md가 언어별로 읽도록 지정하는 규칙 문서. 자동 glob 주입 기능이 아니다.

원본: https://github.com/Youngju-Heo/claude-skill
검토 기준 커밋: `59f40c1352505cee87c129bda665b664cfc3f881`

## 사전 조건 — superpowers 설치

`dev-workflow`의 단계별 스킬을 사용하려면 **Codex에 superpowers 플러그인을 설치해야 한다**. 이 저장소의 `.agents` 폴더에는 superpowers가 포함되어 있지 않다. Claude Code에 설치했더라도 Codex에는 별도로 설치한다.

### Codex 클라이언트에서 설치하기

Codex 앱을 사용하는 경우 클라이언트 안에서 다음 순서로 설치한다.

1. 사이드바에서 **Plugins**를 연다.
2. **Coding** 항목의 **Superpowers**를 찾는다.
3. 옆의 **+** 버튼을 누르고 안내에 따라 설치한다.

### Codex CLI를 사용하는 경우

1. Codex CLI 대화창에 `/plugins`를 입력한다.
2. `superpowers`를 검색한다.
3. **Install Plugin**을 선택한다.

### 설치 확인

설치 후 새 Codex 채팅을 열고 다음과 같이 조회만 요청한다. 스킬이 보이지 않으면 앱 또는 CLI를 재시작한다. 이미 설치되어 있고 스킬이 발견되면 다시 설치하지 않는다.

> superpowers의 brainstorming, writing-plans, subagent-driven-development, executing-plans, test-driven-development, requesting-code-review 스킬이 발견되는지 확인해 주세요. 파일 수정과 외부 서비스 호출은 하지 마세요.

이 스킬들은 기획/설계, 상세계획, 구현/테스트, 최종리뷰에 사용한다. 직접 구현하는 경우에는 `subagent-driven-development` 대신 `executing-plans`를 적용한다. 서브에이전트 위임 범위와 모델·추론 수준, 승인 규칙은 프로젝트의 AGENTS.md와 dev-workflow를 따른다.

상세 설치 내용과 클라이언트별 최신 지원 사항은 [Superpowers 공식 설치 안내](https://github.com/obra/superpowers#installation)를 참조한다. 위 메뉴가 보이지 않거나 설치 과정이 다른 경우에도 해당 안내를 확인한다.

## 프로젝트에 복사하기

1. 이 저장소를 내려받거나 로컬 저장소 폴더를 연다.
2. `.codex/AGENTS.md`를 대상 프로젝트 루트의 **AGENTS.md**로 복사하고, **.agents 폴더 전체**를 대상 프로젝트 루트에 복사한다. 숨김 폴더 `.agents`도 반드시 포함한다.
3. 대상에 같은 이름의 파일이 있으면 덮어쓰지 말고 내용을 병합한다. 기존 AGENTS.override.md가 있으면 충돌하는 지침이 있는지 확인한다.
4. 기존 Claude 설정은 그대로 둔다. `.claude/`와 이 저장소의 README·PROJECT_OVERVIEW를 대상 프로젝트 파일 위에 복사할 필요가 없다.
5. 프로젝트를 Codex에서 열고 새 채팅을 시작한다. 스킬이 보이지 않으면 앱을 재시작한다.

검증 요청 예:

> 적용 중인 AGENTS.md와 dev-workflow, devops-workflow의 발견 여부를 알려 주세요. 파일 수정과 외부 서비스 호출은 하지 마세요.

이 저장소의 기본 배치는 프로젝트 복사용이다. 여러 프로젝트에 같은 절차를 적용하려면 아래 공통 설치 방식을 선택할 수 있다. 파일을 내려받는 것만으로 사용자 전역 설정이 변경되지는 않는다.

## 여러 프로젝트에서 공통으로 사용하기

공통 기능을 프로젝트마다 복사할 필요는 없다. 개인 공통 지침·스킬을 한 번 설치하고, 프로젝트에는 차이점만 둔다.

| 용도 | Windows 기본 위치 | 넣을 내용 |
|---|---|---|
| 개인 공통 지침 | `%USERPROFILE%\.codex\AGENTS.md` | 한국어 응답, 최소 변경, 공통 작업 방식 |
| 개인 공통 스킬 | `%USERPROFILE%\.agents\skills\` | 공통 dev-workflow·devops-workflow |
| 프로젝트 지침 | `<프로젝트>\AGENTS.md` | 빌드·테스트 명령, 프로젝트별 예외 |
| 프로젝트 스킬 | `<프로젝트>\.agents\skills\` | 해당 프로젝트에만 필요한 절차 |

`CODEX_HOME`을 별도로 설정했다면 공통 지침은 그 디렉터리의 `AGENTS.md`에 둔다. 위 공통 스킬 경로는 사용자 홈 기준이다. 공통 지침과 프로젝트 지침은 함께 적용되며, 더 구체적인 프로젝트 지침으로 공통 규칙을 조정할 수 있다.

### 이 저장소를 공통 설치하는 순서

1. `.agents/skills/dev-workflow`와 `.agents/skills/devops-workflow` 폴더를 각각 `%USERPROFILE%\.agents\skills\` 아래로 복사한다. SKILL.md뿐 아니라 agents·scripts 하위 파일도 함께 복사한다.
2. 저장소의 `.codex/AGENTS.md` 내용을 검토해 공통으로 적용할 부분을 `%USERPROFILE%\.codex\AGENTS.md`에 병합한다. 기존 공통 지침을 통째로 덮어쓰지 않는다. 모든 프로젝트에 개발 승인 절차를 적용하고 싶지 않다면 워크플로 선택 지침은 프로젝트에 남긴다.
3. 언어별 규칙은 아래 두 방식 중 하나를 선택한다. 저장소의 `.codex/AGENTS.md`를 공통 위치에 그대로 복사하면 상대 경로가 프로젝트를 가리키므로, 참조를 반드시 함께 정리한다.
4. 각 프로젝트의 AGENTS.md에는 빌드·테스트 명령, 실제 통합 브랜치, 도메인 규칙 등 차이점만 적는다. DevOps 조직·프로젝트는 대상별로 지정하고 다른 프로젝트의 기본값을 그대로 사용하지 않는다.
5. 프로젝트에서 새 Codex 채팅을 열고 앞의 조회 전용 검증 요청으로 적용 지침과 스킬 발견 여부를 확인한다.

### 언어별 규칙의 위치 선택

**방식 A — 규칙은 프로젝트별 유지:** 각 프로젝트에 `.agents/rules/`만 복사한다. Python·TypeScript 규칙을 읽으라는 지시는 해당 프로젝트의 AGENTS.md에 둔다. 공통 AGENTS.md에서는 기존 상대 경로 참조를 제거한다. 팀별 규칙이 다를 때 권장한다.

**방식 B — 규칙까지 공통 관리:** 저장소의 `.agents/rules/`를 `%USERPROFILE%\.agents\rules\`로 복사하고, 공통 AGENTS.md의 규칙 참조를 사용자 홈 기준으로 바꾼다. 예:

```markdown
- Python 파일 수정 전 사용자 홈의 .agents/rules/python.md를 읽는다.
- TypeScript/TSX 파일 수정 전 사용자 홈의 .agents/rules/typescript.md를 읽는다.
- 이 경로는 프로젝트 기준이 아니라 사용자 홈 기준으로 해석한다.
- 프로젝트 AGENTS.md의 명시적인 언어 규칙과 기존 도구 설정을 우선한다.
```

공통 위치의 `.agents/rules/` 역시 자동 탐색·주입되는 폴더가 아니다. 지침에서 읽도록 지정하는 참조 문서다.

### 중복 설치 주의

- 같은 이름의 스킬을 개인 공통 위치와 프로젝트 위치에 동시에 두지 않는 편이 좋다. Codex에서는 두 스킬이 모두 표시될 수 있으므로 프로젝트 사본이 공통 사본을 자동으로 덮어쓴다고 가정하지 않는다.
- 프로젝트별 변형이 필요하면 공통 스킬과 다른 이름을 쓰고 SKILL.md의 name, 폴더명, 관련 지침의 참조를 함께 바꾼다. 또는 그 스킬을 프로젝트별로만 설치한다.
- 공통 스킬을 수정하면 이를 사용하는 여러 프로젝트에 영향을 준다. 특정 프로젝트만의 규칙은 프로젝트 AGENTS.md에 둔다.

## 사용 예

### 작은 수정

> `$dev-workflow` 로그인 폼의 오류 메시지 오타를 수정해 주세요.

경량 경로로 처리한다. 무엇을 왜 어떻게 고칠지 보고하고 컨펌을 받은 뒤 구현한다. 설계·계획 문서와 최종리뷰는 생략하지만 브랜치·커밋 규칙은 그대로 적용한다.

### 새 기능

> `$dev-workflow` 주문 목록에 날짜 필터를 추가해 주세요.

작업 브랜치 생성 → 설계 → 설계 승인 → 상세계획 → 계획 승인 → 구현·검증 → 최종리뷰 → 결과·이슈 보고 및 사용자 컨펌 순서다. 리뷰에서 발견한 이슈의 수정과 머지는 사용자가 결정한다. 기존에 승인한 범위와 단계는 반복 확인하지 않는다.

### DevOps 조회만

> `$devops-workflow` 12345를 조회해 요구사항만 정리해 주세요. 상태와 댓글은 변경하지 마세요.

### DevOps 전체 작업

> `$devops-workflow` 12345를 개발하고 PR 생성과 결과 댓글 기록까지 진행해 주세요. 진행 중·완료 상태 전환은 먼저 확인해 주세요.

스킬을 UI에서 선택할 수도 있다. `$skill-name`은 요청에서 스킬을 가리키는 표기이며 Claude의 `/skill-name` 명령이나 `$ARGUMENTS` 치환에 의존하지 않는다.

## Azure DevOps 준비

DevOps를 사용하지 않는 프로젝트는 이 설정이 필요 없다.

- PowerShell 7, Azure CLI, azure-devops 확장.
- 사용자가 직접 `az login`으로 로그인한 세션. 새 PAT는 필요하지 않다.
- 조직·프로젝트는 실제 값을 사용한다.

```powershell
az extension add --name azure-devops
az login
az devops configure --defaults organization=https://dev.azure.com/YOUR_ORG project=YOUR_PROJECT
$env:ADO_PROJECT = 'YOUR_PROJECT'
```

헬퍼의 댓글 함수는 az 기본 프로젝트를 자동으로 읽지 않는다. `-Project`를 명시하거나 해당 PowerShell 세션의 `ADO_PROJECT`를 설정한다. 설치·로그인은 이 패키지를 풀거나 복사한다고 자동 실행되지 않는다.

Codex는 선택된 스킬 경로를 기준으로 `scripts/ado.ps1`을 읽는다. 원본 헬퍼의 주석에 있는 `.claude` 경로는 기존 설치 예시이며 Codex 스킬의 실행 경로로 사용하지 않는다. 헬퍼는 원본과 동일하며 PowerShell 7에서 사용한다.

## Claude 원본과의 대응

관리 정책은 Claude 원본을 따른다. 도구별 경로·호출 방법과 기존 Codex 모델·추론 수준 설정만 구분한다. 규칙 변환을 이유로 승인·금지·의무·적용 범위를 임의로 변경하지 않는다.

| 항목 | Codex 구성 |
|---|---|
| 기본 지침 | 프로젝트 루트 AGENTS.md 또는 개인 공통 지침과 프로젝트 지침 조합 |
| 스킬 설치 | 프로젝트 .agents/skills 또는 개인 공통 .agents/skills |
| superpowers | Codex용 플러그인을 별도 설치하고 단계별 지정 스킬 적용. 승인·TDD·리뷰 의무 유지 |
| Opus/Sonnet 전환 | 기존 Sol·단계별 추론 수준 설정 유지. 불일치 시 변경 또는 현재 설정 진행 지시를 받음 |
| 작은 변경 | 보고·컨펌 후 구현. 브랜치·커밋 규칙 동일 적용 |
| 큰 변경 | 설계·계획 승인과 최종리뷰 후 컨펌 유지 |
| 브랜치·커밋 | 새 기획 시작 시 브랜치 생성, 단계별 커밋, 원본 메시지 형식 유지 |
| 검증 | 관련 검사와 최종리뷰 후 근거 없는 반복 금지 |
| DevOps 자동 실행 | agents/openai.yaml의 allow_implicit_invocation: false |
| 언어별 규칙 | AGENTS.md에서 조건부 읽기 지정 |
| 한국어 | 응답·문서·커밋·GUI 한국어, 로그·CLI 영어 |

공식 참고:
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
- https://learn.chatgpt.com/docs/build-skills

## 검증 범위

스킬의 단순 name/description frontmatter, 호출 정책, 동봉 참조 파일, 원본 헬퍼 동일성, PowerShell 구문 및 Git 공백 검사를 로컬에서 확인했다. 기본 quick_validate.py는 실행 환경의 PyYAML 누락으로 완료하지 못해 해당 형식은 별도 검사했다. 실제 모델의 스킬 선택이나 Azure 로그인·권한·API 동작, 한글 입출력의 실서비스 통합 검증은 수행하지 않았다. 프로젝트 적용 후 먼저 조회 전용 요청으로 확인한다.
