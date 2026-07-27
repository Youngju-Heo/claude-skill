---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript 코드 규칙

<!-- 예시 규칙입니다. 팀 컨벤션에 맞게 수정하세요.
     생태계 표준(camelCase 등)과 동일한 항목은 삭제해도 됩니다. -->

## 네이밍

- 변수/함수: camelCase, 타입/인터페이스/컴포넌트: PascalCase,
  상수: UPPER_SNAKE_CASE
- 파일명: 일반 모듈은 kebab-case.ts, React 컴포넌트는 PascalCase.tsx
- 인터페이스에 I 접두사를 붙이지 마라.
- 도메인 용어는 영어로 번역해 사용하라(로마자 표기 금지).

## 스타일

- 이벤트 핸들러는 handle{Event}, props로 넘기는 콜백은 on{Event}.
- ESLint/Prettier 설정이 있으면 그것이 우선한다.
