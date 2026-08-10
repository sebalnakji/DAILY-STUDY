# Curriculum

## 하루 학습 단위

매일 다음 두 질문을 학습한다.

- AI·DA: 1개
- Backend: 1개

두 질문이 모두 완료돼야 해당 날짜를 완료한 학습일로 인정한다.

## Track A. AI·DA

AI·DA는 다음 순서를 반복한다.

```text
Data Analysis → ML Engineering → LLM Engineering → 반복
```

| 순서 | 영역 | 기준 레포 | 현재 위치 | 상태 |
|---:|---|---|---|---|
| 1 | Data Analysis | `alexeygrigorev/data-science-interviews` | `theory.md` · Regularization(L1/L2) 완료 (다음: Feature selection) | waiting |
| 2 | ML Engineering | `alirezadir/Machine-Learning-Interviews` | `src/ml-fundamental.md` · Sample Questions 11번(결측 데이터) 완료 (7~10번은 기학습으로 건너뜀, 다음: 12번 decision tree) | waiting |
| 3 | LLM Engineering | `amitshekhariitbhu/ai-engineering-interview-questions` | `README.md` · LLM Fundamentals · Self-Attention/QKV 완료 (다음: Positional Encoding 또는 Multi-Head Attention) | next |

> 5바퀴째 진행 중(DA→ML→LLM 순환). 다음은 LLM Engineering.

## Track B. Backend

| 기준 레포 | 현재 위치 | 상태 |
|---|---|---|
| `donnemartin/system-design-primer` | `README.md` · SQL or NoSQL 완료 — **데이터 계층 마무리** (다음: Cache) | next |

## 운영 원칙

- 하루에 질문을 정확히 2개만 학습한다.
- AI·DA 1개와 Backend 1개를 생성한다.
- 질문은 반드시 기준 레포에 실제로 존재해야 한다.
- 구현 및 긴 코드 작성은 기본 범위에서 제외한다.
- 하나의 질문은 짧게 학습할 수 있는 범위로 제한한다.
- 학습 완료 후 현재 위치와 다음 영역을 갱신한다.
- 커밋은 두 노트가 모두 완료된 후 하루 한 번만 수행한다.
- 스트릭은 주말을 포함한 연속된 달력 날짜로 계산한다.
