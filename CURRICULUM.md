# Curriculum

## 하루 학습 단위

| 요일 | 하는 일 |
|---|---|
| **평일(월~금)** | **AI·DA 새 문제 1개** |
| **주말(토·일)** | **복습** — 기존 노트 3~4개를 인출 연습으로 다시 판다 |

- Backend: **중단** (아래 Track B 참고)

새 문제든 복습이든 노트가 완료되면 해당 날짜를 **완료한 학습일**로 인정한다(스트릭에 포함).
다만 대시보드의 **완료한 질문 수**는 `kind: review`가 아닌 노트만 센다. 복습은 **🔁 복습 횟수**로 따로 표시된다.

### 왜 주말 복습인가 — 2026-09-11 결정

전체 진도를 실측한 결과, 남은 질문이 **약 600개**였다. 하루 1개면 **약 1년 8개월**이다.

| 영역 | 완료 | 전체 |
|---|---:|---:|
| Data Analysis | 11 | 166 |
| ML Engineering | 11 | 23 (Sample Questions) + 레포 나머지 |
| LLM Engineering | 10 | 약 460 |

"완주 후 복습"으로 두면 **복습 시작이 2년 뒤**가 되고, 그사이 초기 학습분(선형회귀·검증·분류 지표 등)은 방치된다.
그래서 **복습을 주기적으로 삽입**하기로 했다. 주말 기준이라 **건너뛴 날에 영향받지 않고**, 복습 비중이 **주 2일(약 29%)** 로 확보된다.

**복습의 목적은 반복이 아니라 심화다.** 같은 내용을 다시 읽는 게 아니라, 잊었거나 얕았던 지점을 찾아 **한 겹 더 파고든다.** 세부 규칙은 `AGENTS.md`의 `복습!` 절.

> ℹ️ 2026-09-03 이전은 AI·DA 1개 + Backend 1개로 하루 2문제였다. 대시보드의 완료 질문 수는 실제 완료된 노트 수로 집계된다.

## Track A. AI·DA

AI·DA는 다음 순서를 반복한다.

```text
Data Analysis → ML Engineering → LLM Engineering → 반복
```

| 순서 | 영역 | 기준 레포 | 현재 위치 | 상태 |
|---:|---|---|---|---|
| 1 | Data Analysis | `alexeygrigorev/data-science-interviews` | `theory.md` · Neural networks 섹션 소진 — **다음: Optimization in neural networks 섹션** (CNN 섹션·전이학습 질문은 ML 트랙에서 다뤄 건너뜀) | waiting |
| 2 | ML Engineering | `alirezadir/Machine-Learning-Interviews` | `src/ml-fundamental.md` · **Sample Questions 목록 완주**(23번 전이학습까지, 19·20번은 중복으로 건너뜀) — **다음 바퀴에 레포의 다른 섹션으로 이동해야 함** | done |
| 3 | LLM Engineering | `amitshekhariitbhu/ai-engineering-interview-questions` | `README.md` · LLM Fundamentals · MoE / 밀집·희소 모델 완료 — **다음: Flash Attention 또는 Cross-Entropy Loss** | next |

> 12바퀴째 진행 중 — Data Analysis·ML Engineering 완료, 다음은 LLM Engineering.
>
> ℹ️ 2026-09-17: **ML Engineering의 `Sample Questions` 목록을 완주**했다. 다음 바퀴에 이 트랙 차례가 오면 `alirezadir/Machine-Learning-Interviews` 레포의 **다른 섹션**(ML system design, ML coding 등)에서 다음 위치를 정해야 한다.
>
> ℹ️ 2026-09-17: **트랙 간 중복 기록** — DA 트랙의 전이학습 질문(*What is transfer learning? How does it work?*)은 ML 트랙의 [[2026-09-17-ai-data-transfer-learning]]에서 함께 다뤘으므로 **DA 트랙에서는 건너뛴다.**
>
> ℹ️ 2026-09-11: **트랙 간 중복 기록** — DA 트랙(`data-science-interviews`)의 CNN 관련 질문(합성곱 층, 풀링, 왜 완전연결층으로는 안 되는가, 맥스 풀링 등)은 ML 트랙의 [[2026-09-11-ai-data-cnn]]에서 함께 다뤘으므로 **DA 트랙에서는 건너뛴다.**
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

- 평일에는 질문을 정확히 1개만 학습한다 (AI·DA).
- 주말에는 복습을 한다. 새 문제를 만들지 않는다.
- Backend 트랙은 중단됐다. 재개 전까지 Backend 노트를 만들지 않는다.
- 질문은 반드시 기준 레포에 실제로 존재해야 한다.
- 구현 및 긴 코드 작성은 기본 범위에서 제외한다.
- 하나의 질문은 짧게 학습할 수 있는 범위로 제한한다.
- 학습 완료 후 현재 위치와 다음 영역을 갱신한다.
- 커밋은 노트가 완료된 후 하루 한 번만 수행한다.
- 스트릭은 주말을 포함한 연속된 달력 날짜로 계산한다.
