---
name: rnd-weekly-excel-update
description: rnd-weekly-worklist로 만든 주간 작업 목록을 주간보고 합본 엑셀(SharePoint 원본 또는 로컬 복사본)의 "연구혁신" 시트 연구소·CLOUD LAB 칸에 입력할 때 사용한다. "주간보고 엑셀 갱신", "작업 목록을 엑셀에 반영" 요청에 해당한다.
argument-hint: "[작업 목록 md 경로 (생략 시 이번 주 파일)]"
---

# 주간보고 엑셀 갱신 (연구소 / CLOUD LAB)

주간 작업 목록 md를 **실행 중인 Excel 앱**에 COM으로 연결해 "연구혁신" 시트
"2. 진행 사항" 표의 연구소·CLOUD LAB 블록에 쓴다. 파일을 내려받아 다시 올리지
않는다(다른 LAB의 동시 편집을 덮어쓰지 않기 위해). 웹 Excel·브라우저 조작은 쓰지 않는다.

## 입력과 대상

- 작업 목록: `C:\work\preproj\668-rnd-monthly-report\output\yyyy-mm-{n}주차-주간보고-작업목록.md`
  (없으면 rnd-weekly-worklist를 먼저 실행하라고 안내하고 중단).
- 대상 통합 문서: 사용자가 Excel 앱에 열어 둔 파일.
  - 원본: SharePoint의 주간보고 합본. 사용자가 "데스크톱 앱에서 열기"로 열고 자동 저장이 켜져 있어야 한다.
  - 테스트: `668-rnd-monthly-report\reference\yyyy-mm-주간보고-합본(작성중).xlsx` 로컬 복사본.
  - 열려 있지 않으면 사용자에게 열어 달라고 요청한다. 직접 열거나 닫지 않는다.

## 시트 배치

| 열 | B | C / H | D / I | E / J | F / K | G / L |
|---|---|---|---|---|---|---|
| 내용 | LAB | 구분 | 담당 | 건명 | 진행사항 (F: 전주 진행 ← 작업 목록 "금주 진행", K: 금주 계획 ← 작업 목록 "차주 계획") | 비고 (항목 ID) |

- 항목 하나 = 한 행. 작업 목록의 최상위 줄(Issue 요약)만 옮기고, 들여쓴 하위 줄(Task 세부)은 넣지 않는다.
- 비고(G/L) 셀은 ID 글자를 보여주고 DevOps 작업 항목 링크(`https://dev.azure.com/cberrydevops/{프로젝트}/_workitems/edit/{ID}`)를 건다.
  셀당 링크는 하나이므로 ID가 여럿이면 첫 번째 ID로 연결한다. 프로젝트는 문장 끝 `(prod #…)`, 없으면 구분 제목의 프로젝트를 쓴다.
- 건명별 행 수 = max(진행 줄 수, 계획 줄 수). 블록 행을 삽입·삭제해 맞추고 B(LAB)·C/H(구분)·D/I(담당)를 다시 병합한다.
- 건명 구성: 연구소 → 공통/공통, CLOUD LAB → 제품개발(edge-device, site-manager, ai engine), 연동작업(연동).
- 장기 진행(지연 관리) 항목과 "변동 없음" 메모는 넣지 않는다(지연 항목은 담당자 공지용 관리 항목).
- 담당은 시트의 같은 건명 기존 값을 유지하고, 없으면 `build-excel-plan.py`의 `DEFAULT_OWNERS`를 쓴다.
- 블록 안 `기타` 행부터 끝까지와 다른 LAB은 건드리지 않는다.

## 절차

스크립트 위치: `$HOME/.claude/skills/rnd-weekly-excel-update/scripts/`. 중간 파일은 scratchpad에 둔다.

1. **계획 만들기**
   ```bash
   python -I build-excel-plan.py "<작업목록.md>" "<scratchpad>/plan.json"
   ```
2. **대상 확인(dry run)** — 반드시 Windows PowerShell 5.1(`powershell.exe`)로 실행한다(pwsh 7은 실행 중인 Excel에 붙지 못한다).
   ```bash
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<scripts>\apply-excel-plan.ps1" -PlanFile "<scratchpad>\plan.json" -OutFile "<scratchpad>\dry.json" -DryRun
   ```
   결과 JSON의 통합 문서 경로, 블록별 시작 행, 현재 행 수 → 필요 행 수를 사용자에게 보여주고 **쓰기 전에 확인받는다.**
   대상 시트를 가진 통합 문서가 여럿이면 `-WorkbookIndex`로 고르게 묻는다.
3. **적용** — `-DryRun` 없이 같은 명령, `-OutFile`은 `applied.json`.
4. **검증** — `applied.json`의 `rows`(C~L열 읽기 결과)를 plan과 대조해 각 건명의 F/G·K/L 값이 순서대로 일치하는지 확인하고, 병합 상태(B/C/D 열)를 보고한다.
5. **저장** — SharePoint 원본은 자동 저장에 맡긴다. 로컬 복사본은 저장 여부를 사용자에게 묻는다(`$wb.Save()`).

## 흔한 실수

| 실수 | 바로잡기 |
|---|---|
| `pwsh`로 실행해 GetActiveObject 실패 | `powershell.exe`(5.1)로 실행 |
| COM 호출이 거부됨(RPC_E_CALL_REJECTED) | 사용자가 셀 편집 중이다. 편집을 끝내 달라고 요청 후 재시도 |
| 스크립트에 한글 문자열을 넣어 5.1에서 깨짐 | 한글은 plan JSON으로만 넘기고 ps1은 ASCII로 유지 |
| 파일을 내려받아 수정 후 업로드 | 동시 편집을 덮어쓴다. 열린 Excel 앱에만 쓴다 |
| dry run 없이 바로 적용 | 블록 위치·행 수를 먼저 확인받는다 |
