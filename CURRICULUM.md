# Curriculum

## 하루 학습 단위

매일 **AI·DA 1개**를 학습한다.

- AI·DA: 1개
- Backend: **중단** (아래 Track B 참고)

AI·DA 질문이 완료되면 해당 날짜를 완료한 학습일로 인정한다.

> ℹ️ 2026-09-03 이전은 AI·DA 1개 + Backend 1개로 하루 2문제였다. 대시보드의 완료 질문 수는 실제 완료된 노트 수로 집계된다.

## Track A. AI·DA

AI·DA는 다음 순서를 반복한다.

```text
Data Analysis → ML Engineering → LLM Engineering → 반복
```

| 순서 | 영역 | 기준 레포 | 현재 위치 | 상태 |
|---:|---|---|---|---|
| 1 | Data Analysis | `alexeygrigorev/data-science-interviews` | `theory.md` · Neural networks · 활성화 함수 완료(필요성·시그모이드 한계·ReLU) — 1·2번 질문은 기존 학습과 중복이라 건너뜀 (다음: 가중치 초기화 / 전부 0으로 두면?) | done |
| 2 | ML Engineering | `alirezadir/Machine-Learning-Interviews` | `src/ml-fundamental.md` · **Sample Questions 21번(역전파) 완료** — 19번(신경망 설명)·20번(딥러닝 vs 전통 ML)은 기존 학습과 중복이라 건너뜀 (다음: 22번 CNN 또는 23번 전이학습) | done |
| 3 | LLM Engineering | `amitshekhariitbhu/ai-engineering-interview-questions` | `README.md` · LLM Fundamentals · KV Cache 완료 — **다음: Model Distillation** | next |

> 10바퀴째 진행 중 — Data Analysis·ML Engineering 완료, 다음은 LLM Engineering.
>
> ℹ️ 2026-09-04: ML Engineering의 19·20번을 건너뛰었다. 20번(*What is deep learning and how does it differ from traditional machine learning?*)은 **"특징 공학의 자동화" 관점이 기존 노트와 완전히 겹치지는 않으므로 나중에 되짚을 여지를 남겨 둔다.**

## Track B. Backend — 완료

| 기준 레포 | 현재 위치 | 상태 |
|---|---|---|
| `donnemartin/system-design-primer` | 본문·부록 완주 + `solutions/` 실전 설계 **7종 완료** | **done** |

**완료한 실전 설계 7종**

| # | 주제 | 노트 |
|---:|---|---|
| 1 | Pastebin / Bit.ly | `2026-08-20-backend-design-pastebin` |
| 2 | 트위터 타임라인과 검색 | `2026-08-21-backend-design-twitter` |
| 3 | 웹 크롤러 | `2026-08-27-backend-design-web-crawler` |
| 4 | 수백만 사용자까지 확장 | `2026-08-28-backend-scaling-to-millions` |
| 5 | Mint.com | `2026-08-31-backend-design-mint` |
| 6 | 검색 결과 키-값 캐시 | `2026-09-01-backend-query-cache` |
| 7 | 소셜 네트워크 그래프 | `2026-09-02-backend-social-graph` |

> ℹ️ **2026-09-03 중단.** 실전 설계 단계가 개념 학습의 범위를 넘어선다고 판단해 트랙을 마감했다.
> - 미학습으로 남은 항목: `solutions/system_design/sales_rank` (Design the Amazon sales rank) 하나뿐이다.
> - 대시보드의 Backend 열은 이 날짜 이후 `-`로 표시된다.
> - **재개하려면**: 이 표의 상태를 `next`로 되돌리고, `AGENTS.md`의 `오늘의 공부!`·`공부 완료!` 절에서 Backend 관련 문구를 되살리면 된다. `scripts/finish-day.ps1`은 Backend 노트가 있으면 자동으로 함께 검사·커밋한다.

> ℹ️ 2026-08-31: "Design a key-value store"는 primer 인덱스에 개념 항목으로만 있고 `solutions/`에 설계 문서가 없어 Mint.com을 먼저 진행함.
> ℹ️ 2026-09-01: `query_cache`의 원제가 "Design a key-value cache to save the results of the most recent web server queries"라 키-값 저장소 설계에 가장 가까운 문제로 판단해 진행함. `solutions/system_design/`에 남은 미학습 항목은 `sales_rank`·`social_graph` 둘.

## 운영 원칙

- 하루에 질문을 정확히 1개만 학습한다 (AI·DA).
- Backend 트랙은 중단됐다. 재개 전까지 Backend 노트를 만들지 않는다.
- 질문은 반드시 기준 레포에 실제로 존재해야 한다.
- 구현 및 긴 코드 작성은 기본 범위에서 제외한다.
- 하나의 질문은 짧게 학습할 수 있는 범위로 제한한다.
- 학습 완료 후 현재 위치와 다음 영역을 갱신한다.
- 커밋은 노트가 완료된 후 하루 한 번만 수행한다.
- 스트릭은 주말을 포함한 연속된 달력 날짜로 계산한다.
