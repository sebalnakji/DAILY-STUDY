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
| 1 | Data Analysis | `alexeygrigorev/data-science-interviews` | `theory.md` · **Parameter tuning 완료**(Grid/Random/Bayesian) (다음: Neural networks 섹션) | done |
| 2 | ML Engineering | `alirezadir/Machine-Learning-Interviews` | `src/ml-fundamental.md` · **Sample Questions 18번(SVM·Kernel SVM) 완료** (다음: 19번 신경망) | done |
| 3 | LLM Engineering | `amitshekhariitbhu/ai-engineering-interview-questions` | `README.md` · LLM Fundamentals · Temperature/Top-k/Top-p 완료 (다음: KV Cache 또는 Model Distillation) | next |

> 9바퀴째 진행 중 — Data Analysis·ML Engineering 완료, 다음은 LLM Engineering.

## Track B. Backend

| 기준 레포 | 현재 위치 | 상태 |
|---|---|---|
| `donnemartin/system-design-primer` | `solutions/` · **Query Cache(키-값 캐시) 완료** — 실전 6종 완료 (다음: Design the Amazon sales rank(`sales_rank`) 또는 Design a social network(`social_graph`)) | next |

> ℹ️ 2026-08-31: "Design a key-value store"는 primer 인덱스에 개념 항목으로만 있고 `solutions/`에 설계 문서가 없어 Mint.com을 먼저 진행함.
> ℹ️ 2026-09-01: `query_cache`의 원제가 "Design a key-value cache to save the results of the most recent web server queries"라 키-값 저장소 설계에 가장 가까운 문제로 판단해 진행함. `solutions/system_design/`에 남은 미학습 항목은 `sales_rank`·`social_graph` 둘.

## 운영 원칙

- 하루에 질문을 정확히 2개만 학습한다.
- AI·DA 1개와 Backend 1개를 생성한다.
- 질문은 반드시 기준 레포에 실제로 존재해야 한다.
- 구현 및 긴 코드 작성은 기본 범위에서 제외한다.
- 하나의 질문은 짧게 학습할 수 있는 범위로 제한한다.
- 학습 완료 후 현재 위치와 다음 영역을 갱신한다.
- 커밋은 두 노트가 모두 완료된 후 하루 한 번만 수행한다.
- 스트릭은 주말을 포함한 연속된 달력 날짜로 계산한다.
