# 프로젝트 개요

Claude Code용 설정 템플릿 저장소입니다. 판단 원칙(CLAUDE.md), 개발
워크플로 스킬(dev-workflow), Azure DevOps 일감 연동 스킬(devops-workflow),
언어별 코드 규칙(rules)을 실제 운영 배치 구조 그대로 담고 있어, 실제
프로젝트 루트에 복사하면 바로 동작합니다.

## 구조

```
claude-skill/
├── README.md                  # 적용법 가이드 (배치·조정 이유·배치 결정 가이드)
├── PROJECT_OVERVIEW.md        # 이 문서
└── .claude/
    ├── CLAUDE.md              # 판단 원칙 — 항상 로드
    ├── skills/
    │   ├── dev-workflow/
    │   │   └── SKILL.md       # 기능 개발 워크플로 (기획→계획→구현→리뷰)
    │   └── devops-workflow/
    │       ├── SKILL.md       # Azure DevOps 일감 연동 — 선택 적용
    │       └── scripts/
    │           └── ado.ps1    # REST 헬퍼 — az CLI 비ASCII 유실 우회
    └── rules/
        ├── code-common.md     # 언어 공통 규칙 — paths 없음, 항상 로드
        ├── python.md          # Python 규칙 — **/*.py 작업 시 로드
        └── typescript.md      # TypeScript 규칙 — **/*.{ts,tsx} 작업 시 로드
```

## 각 파일의 역할

- **CLAUDE.md**: 추측 금지, 단순함 우선, 외과적 변경, 목표 중심 실행 등
  항상 적용되는 판단 원칙. 절차는 담지 않는다(스킬로 분리).
- **dev-workflow 스킬**: 새 기능 개발 시 단계별 스킬·모델 규칙,
  단계 전환(컨펌) 규칙, 브랜치·커밋 규칙, 설계·계획 문서 규칙.
  설계 결정이 없는 작은 변경은 경량 경로로 4단계를 건너뛴다.
  superpowers 플러그인 필요.
- **devops-workflow 스킬**: Azure DevOps Work Item에서 시작해 개발 절차는
  dev-workflow에 위임하고, PR 생성·결과 댓글·상태 전환까지 처리한다.
  접근은 az CLI 로그인 + 동봉 REST 헬퍼(ado.ps1)로 하며, Azure DevOps
  MCP 서버는 사용하지 않는다.
  `disable-model-invocation: true`라 사용자가 직접 호출할 때만 실행된다.
- **rules**: 하네스가 `paths` glob 매칭으로 자동 주입하는 코드 규칙.
  언어별 파일은 예시이며 팀 컨벤션에 맞게 수정해서 쓴다.

## 적용 방법

`.claude/` 폴더를 대상 프로젝트 루트에 복사한 뒤,
CLAUDE.md의 "7. 기능 개발 워크플로"에서 두 워크플로 중 프로젝트에 맞는
지시문 하나만 활성화한다(나머지는 HTML 주석 처리).
상세한 배치 옵션, 규칙 작성 요령, 새 규칙의 배치 결정 가이드는
[README.md](README.md)를 참조.


## Codex용 추가 구성

- AGENTS.md: 프로젝트 공통 판단 원칙, 한국어 정책, 언어별 규칙 참조.
- .agents/skills/dev-workflow/: 경량·전체 개발 경로. 외부 superpowers나 특정 모델에 의존하지 않음.
- .agents/skills/devops-workflow/: 명시적 호출 전용 Azure DevOps 절차. 원본 REST 헬퍼를 함께 제공.
- .agents/rules/: AGENTS.md가 조건부로 읽는 Python·TypeScript 규칙.
- CODEX-SETUP.md: 복사 방법, 호출 예, Azure 준비, 원본과의 차이점.

.claude/의 기존 파일은 변경하지 않습니다. Codex 적용 시 AGENTS.md와 .agents/를 프로젝트 루트에 복사합니다. 기존 파일이 있으면 덮어쓰지 않고 병합합니다.
