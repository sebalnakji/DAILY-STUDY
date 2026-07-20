# Daily Interview Study Instructions

## 목적

실제 면접 질문을 기반으로 매일 두 개의 핵심 주제를 학습한다.

- AI·Data 질문 1개
- Backend 질문 1개

AI는 질문 선정, 핵심 개념 설명, 기준 답변 작성, 사용자 정리 검토를 담당한다.
사용자는 학습한 내용을 자신의 언어로 정리한다.

## 기준 자료

기준 레포는 로컬 `.sources` 폴더에서 읽는다.

### AI·Data

- Data Analysis: `.sources/data-science-interviews`
- ML Engineering: `.sources/Machine-Learning-Interviews`
- LLM Engineering: `.sources/ai-engineering-interview-questions`

### Backend

- `.sources/system-design-primer`

## 하루 노트 생성 규칙

매일 정확히 두 파일을 생성한다.

```text
notes/YYYY/YYYY-MM-DD-ai-data-topic.md
notes/YYYY/YYYY-MM-DD-backend-topic.md
```

### AI·Data 질문

1. `CURRICULUM.md`에서 `next` 상태인 영역을 확인한다.
2. 해당 기준 레포에서 아직 학습하지 않은 질문을 하나 선택한다.
3. 기준 레포의 기존 목차와 질문 순서를 가능한 한 유지한다.
4. 학습 완료 후 다음 AI·Data 영역을 `next`로 변경한다.

### Backend 질문

1. `system-design-primer`의 개념 및 면접 문제 순서를 따른다.
2. 아직 학습하지 않은 질문을 하나 선택한다.

## 질문 선정 기준

- 질문은 기준 레포에 실제로 존재해야 한다.
- 출처 레포와 원본 파일 경로를 기록한다.
- 이미 완료한 질문은 다시 선택하지 않는다.
- 구현이나 긴 코드 작성이 필요한 질문은 제외한다.
- 하루에 짧게 학습할 수 있도록 질문 범위를 좁힌다.

## 노트 작성 규칙

`templates/daily-question.md`를 사용한다.

AI가 작성하는 영역:

- 출처
- 면접 질문
- 핵심 개념
- 기준 답변

사용자가 작성하는 영역:

- 내가 정리한 내용

사용자 작성 영역은 생성 시 비워 둔다.

## 설명 규칙

- 질문에 답하는 데 필요한 개념만 설명한다.
- 정의, 작동 원리, 트레이드오프, 실무 맥락을 우선한다.
- 원문을 장문 복사하지 않고 한국어로 재구성한다.
- 주변 지식과 불필요한 역사 설명은 제외한다.
- 기준 레포의 답이 불완전하거나 불명확하면 명시한다.

## 검토 규칙

사용자가 검토를 요청하면 `검토 결과`에만 다음을 작성한다.

- 정확하게 이해한 내용
- 빠진 핵심
- 잘못 이해한 내용
- 면접 답변으로 보완할 점

사용자가 작성한 내용은 직접 수정하지 않는다.

## 완료 조건

하루 학습은 다음 조건을 모두 충족하면 완료된다.

1. AI·Data 노트가 존재한다.
2. Backend 노트가 존재한다.
3. 두 노트의 `status`가 모두 `completed`다.

별도의 최종 답변, 한 줄 요약, 점수는 요구하지 않는다.

## 통합 커밋 규칙

개별 노트를 따로 커밋하지 않는다.

사용자가 명시적으로 학습 완료와 커밋을 요청한 경우에만 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finish-day.ps1
```

스크립트는 다음을 한 번에 처리한다.

1. 오늘의 두 노트 완료 여부 확인
2. README 대시보드 갱신
3. 관련 파일 스테이징
4. 하루 한 개의 통합 커밋 생성
5. 원격 저장소로 푸시

## 응답 언어

모든 설명과 검토는 한국어로 작성한다.
