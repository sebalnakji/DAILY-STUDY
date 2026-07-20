## 단축 명령

### 오늘의 공부!

사용자가 정확히 `오늘의 공부!`라고 입력하면 추가 질문 없이 다음 작업을 수행한다.

1. 현재 날짜를 확인한다.
2. `CURRICULUM.md`에서 다음 학습 위치를 확인한다.
3. `.sources`의 기준 레포에서 아직 학습하지 않은 실제 면접 질문을 선택한다.
4. 다음 학습 노트 두 개를 생성한다.
   - AI·DA 질문 1개
   - Backend 질문 1개
5. `templates/daily-question.md` 형식을 사용한다.
6. 구현이나 긴 코드 작성이 필요한 질문은 제외한다.
7. 사용자 작성 영역인 `내가 정리한 내용`과 `검토 결과`는 비워 둔다.
8. Git 커밋과 Push는 수행하지 않는다.
9. 이미 오늘 날짜의 노트가 있다면 덮어쓰지 말고 기존 노트를 열어 학습을 이어간다.
10. 생성 또는 확인한 두 노트의 경로와 질문 제목만 간단히 안내한다.

생성 파일 형식:

- `notes/YYYY/YYYY-MM-DD-ai-data-topic.md`
- `notes/YYYY/YYYY-MM-DD-backend-topic.md`

### 공부 완료!

사용자가 정확히 `공부 완료!`라고 입력하면 추가 질문 없이 다음 작업을 수행한다.

1. 오늘 날짜의 AI·DA 노트와 Backend 노트가 모두 존재하는지 확인한다.
2. 두 노트의 학습 내용이 작성돼 있는지 확인한다.
3. 두 노트의 `status`를 `completed`로 변경한다.
4. `CURRICULUM.md`의 진행 위치를 갱신한다.
5. 아래 스크립트를 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finish-day.ps1