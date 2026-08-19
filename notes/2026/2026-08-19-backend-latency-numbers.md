---
date: 2026-08-19
track: backend
area: Backend & System Design
topic: 어림 계산 — 2의 거듭제곱과 지연시간 수치
source_repository: donnemartin/system-design-primer
source_file: README.md
status: completed
---

# 어림 계산(Back-of-the-envelope) — 모든 프로그래머가 알아야 할 지연시간 수치

## 출처

- 기준 레포: `donnemartin/system-design-primer`
- 원본 파일: `README.md` — `## Appendix` → `### Powers of two table`, `### Latency numbers every programmer should know`
- 영역: Backend / System Design
- 이전 학습: [[2026-08-18-backend-security]], [[2026-07-21-backend-latency-vs-throughput]]

## 질문

> **시스템 디자인에서 어림 계산은 왜 필요한가? 알아야 할 지연시간 수치는 무엇인가?**
>
> 원문: *Appendix — Powers of two table / Latency numbers every programmer should know*

## 핵심 개념

### 왜 필요한가

원문이 이유를 명시한다.

> **가끔 '어림 계산(back-of-the-envelope)' 추정을 요청받는다.** 예를 들어 디스크에서 이미지 썸네일 100개를 만드는 데 얼마나 걸릴지, 또는 어떤 자료구조가 메모리를 얼마나 쓸지 결정해야 할 수 있다.

**2의 거듭제곱 표**와 **지연시간 수치**가 그때 쓰는 편리한 참고자료다.

### 2의 거듭제곱 표

```text
Power           Exact Value         Approx Value        Bytes
---------------------------------------------------------------
7                             128
8                             256
10                           1024   1 thousand           1 KB
16                         65,536                       64 KB
20                      1,048,576   1 million            1 MB
30                  1,073,741,824   1 billion            1 GB
32                  4,294,967,296                        4 GB
40              1,099,511,627,776   1 trillion           1 TB
```

**핵심 감각**: `2^10 ≈ 1천`, `2^20 ≈ 1백만`, `2^30 ≈ 10억`, `2^40 ≈ 1조`

### 지연시간 수치 (원문 표)

```text
L1 cache reference                           0.5 ns
Branch mispredict                            5   ns
L2 cache reference                           7   ns              14x L1 cache
Mutex lock/unlock                           25   ns
Main memory reference                      100   ns              20x L2, 200x L1
Compress 1K bytes with Zippy            10,000   ns    10 us
Send 1 KB over 1 Gbps network           10,000   ns    10 us
Read 4 KB randomly from SSD            150,000   ns   150 us     ~1GB/sec SSD
Read 1 MB sequentially from memory     250,000   ns   250 us
Round trip within same datacenter      500,000   ns   500 us
Read 1 MB sequentially from SSD      1,000,000   ns     1 ms     4X memory
HDD seek                            10,000,000   ns    10 ms     20x datacenter roundtrip
Read 1 MB sequentially from 1 Gbps  10,000,000   ns    10 ms     40x memory, 10X SSD
Read 1 MB sequentially from HDD     30,000,000   ns    30 ms     120x memory, 30X SSD
Send packet CA->Netherlands->CA    150,000,000   ns   150 ms
```

**단위**
```text
1 ns = 10⁻⁹ 초
1 us = 10⁻⁶ 초 = 1,000 ns
1 ms = 10⁻³ 초 = 1,000 us = 1,000,000 ns
```

### 위 수치에서 나오는 편리한 지표

- **HDD 순차 읽기**: 30 MB/s
- **1 Gbps 이더넷 순차 읽기**: 100 MB/s
- **SSD 순차 읽기**: 1 GB/s
- **주 메모리 순차 읽기**: 4 GB/s
- **전 세계 왕복**: 초당 6~7회
- **데이터센터 내 왕복**: **초당 2,000회**

### 읽어야 할 계층 구조

수치를 외우기보다 **자릿수(order of magnitude)의 계단**을 잡는 것이 중요하다.

| 계층 | 대략 | 비고 |
|---|---|---|
| **CPU 캐시** | **ns** | L1 0.5ns → L2 7ns |
| **메모리** | **100 ns** | L1의 **200배** |
| **SSD 랜덤 읽기** | **150 us** | 메모리의 **1,500배** |
| **데이터센터 내 왕복** | **500 us** | |
| **디스크 탐색(HDD)** | **10 ms** | 데이터센터 왕복의 **20배** |
| **대륙 간 왕복** | **150 ms** | |

> **메모리 → SSD → 네트워크 → HDD → 대륙 간**으로 갈수록 자릿수가 뛴다.

## 기준 답변

기준 레포의 답변을 바탕으로 핵심만 재구성한다.

시스템 디자인 면접에서는 **'어림 계산' 추정**을 요청받는 경우가 있다. 예를 들어 디스크에서 이미지 썸네일 100개를 생성하는 데 얼마나 걸릴지, 자료구조가 메모리를 얼마나 차지할지 판단해야 할 수 있다. 이때 **2의 거듭제곱 표**와 **지연시간 수치**가 유용한 참고자료가 된다.

**2의 거듭제곱**에서 기억할 것은 `2^10 ≈ 1천(1KB)`, `2^20 ≈ 1백만(1MB)`, `2^30 ≈ 10억(1GB)`, `2^40 ≈ 1조(1TB)`다.

**주요 지연시간 수치**는 다음과 같다.

- L1 캐시 참조: **0.5 ns**
- L2 캐시 참조: **7 ns** (L1의 14배)
- 주 메모리 참조: **100 ns** (L1의 200배)
- 1 Gbps 네트워크로 1 KB 전송: **10 us**
- SSD에서 4 KB 랜덤 읽기: **150 us**
- 메모리에서 1 MB 순차 읽기: **250 us**
- 같은 데이터센터 내 왕복: **500 us**
- SSD에서 1 MB 순차 읽기: **1 ms** (메모리의 4배)
- HDD 탐색: **10 ms** (데이터센터 왕복의 20배)
- HDD에서 1 MB 순차 읽기: **30 ms** (메모리의 120배)
- 캘리포니아↔네덜란드 왕복: **150 ms**

여기서 도출되는 **편리한 지표**로는 HDD 순차 읽기 30 MB/s, 1 Gbps 이더넷 100 MB/s, SSD 1 GB/s, 주 메모리 4 GB/s, **전 세계 왕복 초당 6~7회**, **데이터센터 내 왕복 초당 2,000회**가 있다.

## 내가 정리한 내용

**1. 어림 계산은 왜 필요한가**

어림 계산을 해야 **필요한 자원을 추정**할 수 있고, 이를 통해 **한정된 자원을 효율적으로 사용**할 수 있기 때문이다.

목적은 정확한 값이 아니라 **자릿수(order of magnitude)** 를 맞히는 것이다. 시스템 디자인에서 *"썸네일 100개 생성에 얼마나 걸릴지"*, *"이 자료구조가 메모리를 얼마나 쓸지"* 같은 판단에 쓴다.

이때 **2의 거듭제곱**(`2^10≈1천`, `2^20≈1백만`, `2^30≈10억`, `2^40≈1조`)과 **지연시간 수치**가 참고자료가 된다.

**2. 지연시간의 계단**

```text
메모리 100 ns → SSD 150 us → 데이터센터 왕복 500 us → HDD 탐색 10 ms → 대륙 간 150 ms
     (나노초)        (마이크로초)                             (밀리초)
```

**뒤로 갈수록 자릿수가 뛴다.** 메모리와 SSD는 약 1,500배, HDD 탐색은 데이터센터 왕복의 20배 차이다.

여기서 나오는 실무 지표로 **HDD 30MB/s, 이더넷 100MB/s, SSD 1GB/s, 메모리 4GB/s**, 그리고 **대륙 간 왕복은 초당 6~7회, 데이터센터 내 왕복은 초당 2,000회**가 있다.

**3. 실제 설계에 어떻게 쓰이는가**

예를 들어 **한국 사용자가 미국 서버의 API를 호출**할 때, 페이지 하나 렌더링에 왕복이 5번 필요하다면 `150ms × 5 = **750ms**`가 **네트워크에서만** 소모된다. 숫자로 계산하면 **정확한 병목 지점을 확인**할 수 있고, 그에 맞는 개선을 적용해 근본적으로 해결할 수 있다.

이 경우 해법은 **서버·CDN을 사용자 가까이 배치**하거나, **BFF(Backend for Frontend)** 패턴으로 여러 API를 화면 단위로 묶어 **왕복을 1번으로 줄이는 것**이다.

## 검토 결과

### 확인된 부분

- **어림 계산의 목적을 "자원 추정 → 효율적 사용"** 으로 정확히 서술.
- **지연시간의 계단 순서**를 정확히 나열(메모리 → SSD → 데이터센터 → 디스크 → 대륙 간).
- 실습 Q1에서 `150ms × 5 = 750ms`를 정확히 계산하고, 해법 두 가지(서버 이전, API 통합)를 모두 제시.

### 보강 포인트

- **"자릿수를 맞히는 것"** 이라는 목적을 명시할 것. 정확한 값을 구하는 게 아니라 **10배 단위의 규모**를 판단하는 도구다.
- **계단에 숫자를 붙일 것.** 순서만으로는 활용이 어렵다. **자릿수 차이(ns → us → ms)** 가 핵심 정보다.
- **API 통합의 이름은 BFF(Backend for Frontend)** 다. → [[2026-08-14-backend-rpc-rest]]에서 REST의 다중 왕복 문제를 다루며 배운 패턴.
  ```text
  전: GET /posts/1 + GET /users/5 + GET /comments  → 왕복 3번 = 450ms
  후: GET /screens/post-detail/1                   → 왕복 1번 = 150ms
  ```
  **REST 원칙(리소스 단위)을 포기하고 화면 단위로 묶는 대가로 300ms를 절약**한다. 그때 말한 "REST 순수성과 성능의 트레이드오프"의 **크기가 오늘 숫자로 드러난다.**

### 심화: B-트리를 숫자로 재해석 (Q2)

> ⚠️ **"수직 읽기가 수평 읽기보다 느리다"는 구분은 없다.** (초기 답변 → 교정)

진짜 이유는 이것이다.

> ### **트리의 높이 = 디스크 접근 횟수**

각 노드가 **디스크의 다른 위치**에 있으므로, 한 단계 내려갈 때마다 **디스크를 한 번 읽어야** 한다.

```text
HDD 탐색 = 10ms

이진 트리 (100만 건): 높이 20 → 20 × 10ms = 200ms  ❌
B-트리   (100만 건): 높이 3  →  3 × 10ms =  30ms  ✅
```

**같은 데이터인데 7배 차이.** 계산량이 아니라 **디스크를 몇 번 만지느냐**가 전부다.

**"넓게" 만드는 이유도 숫자에 있다** — 디스크는 **블록 단위로 읽으므로 1바이트를 읽든 4KB를 읽든 비용이 같다**(10ms).

```text
이진 트리: 4KB 읽어와서 키 1개만 사용   ← 낭비
B-트리:   4KB 읽어와서 키 수백 개 사용  ← 꽉 채움
```

> **높이를 낮추는 건 접근 횟수를 줄이려고, 넓게 만드는 건 한 번의 접근에서 최대한 얻으려고.**
> 둘 다 **"디스크 접근이 10ms로 압도적으로 비싸다"** 는 한 가지 사실에서 나온다. → [[2026-08-06-backend-sql-tuning-nosql]]

### 지금까지 배운 것이 이 숫자로 설명된다

| 배운 것 | 숫자로 보면 |
|---|---|
| **캐시가 빠른 이유** | 메모리 100ns vs SSD 150,000ns → **1,500배** → [[2026-08-11-backend-cache]] |
| **B-트리가 높이를 낮추는 이유** | HDD 탐색 10ms × 20회 = **200ms** → [[2026-08-06-backend-sql-tuning-nosql]] |
| **CDN이 필요한 이유** | 대륙 간 150ms vs 근거리 수 ms → [[2026-07-29-backend-content-delivery-network]] |
| **커넥션 풀링이 필요한 이유** | DC 내 왕복 500us도 쌓이면 큼 → [[2026-08-13-backend-http-tcp-udp]] |

> **"디스크는 느리다"가 막연한 말이 아니라 숫자였다.**

### 특히 강력한 두 지표

```text
전 세계 왕복        초당 6~7회
데이터센터 내 왕복   초당 2,000회
```

**대륙 간 왕복은 초당 6~7회밖에 못 한다.** CDN이 "사용자와 가까운 곳에서 제공한다"는 것이 왜 그렇게 중요한지가 이 숫자에 있다. 한국 사용자가 미국 서버를 쓰면 왕복 한 번에 150ms이고, 페이지 하나에 왕복 5번이면 **0.75초가 네트워크에서만** 날아간다.

### 전체 수치 표 (원문)

```text
L1 cache reference                           0.5 ns
Branch mispredict                            5   ns
L2 cache reference                           7   ns              14x L1
Mutex lock/unlock                           25   ns
Main memory reference                      100   ns              200x L1
Compress 1K bytes with Zippy            10,000   ns    10 us
Send 1 KB over 1 Gbps network           10,000   ns    10 us
Read 4 KB randomly from SSD            150,000   ns   150 us
Read 1 MB sequentially from memory     250,000   ns   250 us
Round trip within same datacenter      500,000   ns   500 us
Read 1 MB sequentially from SSD      1,000,000   ns     1 ms     4X memory
HDD seek                            10,000,000   ns    10 ms     20x DC roundtrip
Read 1 MB sequentially from 1 Gbps  10,000,000   ns    10 ms
Read 1 MB sequentially from HDD     30,000,000   ns    30 ms     120x memory
Send packet CA->Netherlands->CA    150,000,000   ns   150 ms
```

### 오늘 나온 축약어

| 축약어 | 풀네임 |
|---|---|
| ns / us / ms | nanosecond / microsecond / millisecond |
| SSD / HDD | Solid State Drive / Hard Disk Drive |
| DC | Data Center |
| BFF | Backend For Frontend |

