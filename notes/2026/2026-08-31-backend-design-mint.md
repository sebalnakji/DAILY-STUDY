---
date: 2026-08-31
track: backend
area: System Design
topic: 실전 설계 — Mint.com(개인 재무 관리 서비스)
source_repository: donnemartin/system-design-primer
source_file: solutions/system_design/mint/README.md
status: completed
---

# 실전 설계 — Mint.com을 설계하라

## 출처

- 기준 레포: `donnemartin/system-design-primer`
- 원본 파일: `solutions/system_design/mint/README.md`
- 영역: Backend / System Design
- 이전 학습: [[2026-08-12-backend-asynchronism]], [[2026-08-11-backend-cache]], [[2026-08-19-backend-latency-numbers]], [[2026-08-20-backend-design-pastebin]], [[2026-08-27-backend-design-web-crawler]], [[2026-08-28-backend-scaling-to-millions]]

## 질문

> **Mint.com을 설계하라.**
>
> 원문: *Design Mint.com*

Mint.com은 사용자의 은행·카드 계좌를 연결해 **거래 내역을 자동으로 끌어와 카테고리별로 분류하고, 월별 지출을 집계해 예산과 비교해 주는** 개인 재무 관리(Personal Finance Management) 서비스다.

## 핵심 개념

질문에 답하기 위해 필요한 핵심 개념을 정리한다.

### 이 문제의 성격 — 쓰기 폭주 + 배치 집계

지금까지 푼 실전 문제와 성격이 다르다.

| 문제 | 성격 | 병목 |
|---|---|---|
| [[2026-08-20-backend-design-pastebin]] | 읽기 우세, 단순 조회 | 읽기 QPS·캐시 |
| [[2026-08-21-backend-design-twitter]] | 읽기 폭주, 팬아웃 | 타임라인 생성 |
| [[2026-08-27-backend-design-web-crawler]] | 외부 수집, 중복 제거 | 크롤 큐·중복 판정 |
| **Mint.com** | **쓰기 우세(10:1) + 주기적 집계** | **쓰기 처리량 · 집계 파이프라인** |

**쓰기:읽기 = 10:1.** 사용자는 매일 결제를 하지만 사이트에는 매일 안 들어온다. 이 한 줄이 설계 전체를 지배한다.

### Step 1 — 유스케이스와 제약

#### 유스케이스(범위 안)

| 주체 | 유스케이스 |
|---|---|
| 사용자 | 금융 계좌를 연결한다 |
| 서비스 | 계좌에서 **거래 내역을 추출**한다 (매일 갱신) |
| 서비스 | 거래를 **카테고리로 분류**한다 (사용자 수동 변경 허용, **자동 재분류는 없음**) |
| 서비스 | **카테고리별 월간 지출을 분석**한다 |
| 서비스 | **예산을 추천**한다 (사용자 직접 설정 가능) |
| 서비스 | 예산 근접·초과 시 **알림**을 보낸다 |
| 서비스 | **고가용성(High Availability)** 을 갖는다 |

범위 밖: 추가 로깅과 분석.

#### 가정과 제약

- 트래픽은 **고르게 분포하지 않는다**
- 자동 일일 갱신은 **최근 30일 내 활성 사용자에게만** 적용한다
- 계좌 추가·삭제는 **드물다**
- 예산 알림은 **즉시일 필요가 없다**
- 사용자 **1,000만 명**
  - 사용자당 예산 카테고리 10개 = **예산 항목 1억 개**
  - 카테고리 결정 근거는 **판매자(seller)** — 판매자 **5만 개**
- 금융 계좌 **3,000만 개**
- 월 **거래 50억 건**
- 월 **읽기 요청 5억 건**
- **쓰기:읽기 = 10:1**

#### Step 1 계산 — 어림 계산(Back-of-the-envelope)

거래 1건의 크기:

| 필드 | 크기 |
|---|---:|
| `user_id` | 8 bytes |
| `created_at` | 5 bytes |
| `seller` | 32 bytes |
| `amount` | 5 bytes |
| **합계** | **약 50 bytes** |

| 항목 | 계산 | 결과 |
|---|---|---:|
| 월간 신규 거래 데이터 | 50 B × 50억 | **250 GB/월** |
| 3년치 누적 | 250 GB × 36 | **9 TB** |
| 평균 쓰기 | 50억 ÷ 250만 초 | **2,000 TPS** |
| 평균 읽기 | 5억 ÷ 250만 초 | **200 QPS** |

환산 치트시트 — [[2026-08-19-backend-latency-numbers]]에서 익힌 것:

```text
1개월 ≈ 250만 초
1 req/s   = 월 250만 요청
40 req/s  = 월 1억 요청
400 req/s = 월 10억 요청
```

> ⚠️ **여기서 "2,000 TPS는 평균"** 이라는 점이 중요하다. 트래픽이 고르지 않다고 이미 가정했으므로 **피크는 훨씬 높다**. Step 4에서 이걸 근거로 SQL 확장 패턴을 꺼낸다.

### Step 2 — 상위 수준 설계

```text
              ┌──────────────┐
   Client ──▶ │  Web Server  │ (리버스 프록시)
              └──────┬───────┘
           ┌─────────┴──────────┐
           ▼                    ▼
    ┌─────────────┐      ┌─────────────┐
    │ Accounts API│      │  Read API   │
    └──────┬──────┘      └──────┬──────┘
           │ 작업 등록           │ 조회
           ▼                    ▼
     ┌──────────┐         ┌──────────┐
     │  Queue   │         │ SQL DB   │
     └────┬─────┘         └──────────┘
          ▼
  ┌──────────────────────┐    ┌──────────────┐
  │ Transaction          │───▶│ Object Store │ (원본 로그)
  │ Extraction Service   │    └──────────────┘
  └──┬────────┬──────────┘
     ▼        ▼
 ┌─────────┐ ┌────────┐   ┌──────────────┐
 │Category │ │ Budget │──▶│ Notification │
 │ Service │ │Service │   │   Service    │
 └─────────┘ └────────┘   └──────────────┘
```

### Step 3 — 핵심 컴포넌트 설계

#### 유스케이스 1: 사용자가 금융 계좌를 연결한다

1. **Client** → **Web Server**(리버스 프록시)
2. **Web Server** → **Accounts API** 서버
3. **Accounts API**가 **SQL Database**의 `accounts` 테이블을 갱신

```sql
id                    int NOT NULL AUTO_INCREMENT
created_at            datetime NOT NULL
last_update           datetime NOT NULL
account_url           varchar(255) NOT NULL
account_login         varchar(32) NOT NULL
account_password_hash char(64) NOT NULL
user_id               int NOT NULL
PRIMARY KEY(id)
FOREIGN KEY(user_id) REFERENCES users(id)
```

`id`, `user_id`, `created_at`에 **인덱스**를 건다. 전체 스캔(선형) 대신 **로그 시간 조회**가 되고, 인덱스가 메모리에 상주한다.

> 메모리에서 1 MB 순차 읽기 ≈ **250 μs**, SSD는 **4배**, 디스크는 **80배** 느리다 — [[2026-08-19-backend-latency-numbers]]

- 외부 통신은 **REST API**, 내부 통신은 **RPC(Remote Procedure Call)** — [[2026-08-14-backend-rpc-rest]]

```bash
$ curl -X POST --data '{ "user_id": "foo", "account_url": "bar", \
    "account_login": "baz", "account_password": "qux" }' \
    https://mint.com/api/v1/account
```

#### 유스케이스 2: 서비스가 계좌에서 거래를 추출한다

추출이 필요한 시점 세 가지:

1. 사용자가 계좌를 **처음 연결**할 때
2. 사용자가 **수동 새로고침**할 때
3. **최근 30일 활성 사용자**에 대해 **매일 자동으로**

**데이터 흐름**

1. Client → Web Server → **Accounts API**
2. **Accounts API가 Queue에 작업을 넣는다** (Amazon SQS, RabbitMQ 등)
   - 외부 금융기관에서 거래를 끌어오는 데 시간이 오래 걸린다 → **비동기 처리**. 다만 복잡도가 늘어난다 — [[2026-08-12-backend-asynchronism]]
3. **Transaction Extraction Service**가 큐에서 꺼내:
   - 금융기관에서 거래를 추출해 **원본 로그 파일을 Object Store에 저장**
   - **Category Service**로 각 거래를 분류
   - **Budget Service**로 카테고리별 월간 지출을 집계
     - Budget Service가 **Notification Service**로 예산 근접·초과를 알림
   - `transactions` 테이블 갱신
   - `monthly_spending` 테이블 갱신
   - **Notification Service**로 완료를 알림 (여기도 **큐를 통해 비동기로**)

```sql
-- transactions
id         int NOT NULL AUTO_INCREMENT
created_at datetime NOT NULL
seller     varchar(32) NOT NULL
amount     decimal NOT NULL
user_id    int NOT NULL
PRIMARY KEY(id)
FOREIGN KEY(user_id) REFERENCES users(id)
-- 인덱스: id, user_id, created_at

-- monthly_spending
id         int NOT NULL AUTO_INCREMENT
month_year date NOT NULL
category   varchar(32)
amount     decimal NOT NULL
user_id    int NOT NULL
PRIMARY KEY(id)
FOREIGN KEY(user_id) REFERENCES users(id)
-- 인덱스: id, user_id
```

> 💡 `monthly_spending`은 **비정규화(denormalization)된 집계 테이블**이다. "이번 달 식비 얼마 썼지?"를 50억 행 스캔 없이 답하기 위해 **미리 계산해 저장**한다.

#### Category Service — 판매자→카테고리 사전

```text
판매자 5만 개 × 항목당 255 bytes 미만 ≈ 12 MB
```

**고작 12 MB**. 전부 메모리에 올려도 된다. 이런 계산을 해 두면 "분류 서비스에 DB가 필요한가?"라는 질문이 사라진다.

```python
class DefaultCategories(Enum):
    HOUSING = 0
    FOOD = 1
    GAS = 2
    SHOPPING = 3

seller_category_map = {}
seller_category_map['Exxon'] = DefaultCategories.GAS
seller_category_map['Target'] = DefaultCategories.SHOPPING
```

사전에 없는 판매자는 **크라우드소싱**으로 채운다 — 사용자들의 수동 카테고리 변경을 모아 **판매자별 최다 득표 카테고리**를 쓴다. **힙(heap)** 을 쓰면 최상위 항목을 **O(1)** 로 조회할 수 있다.

```python
def categorize(self, transaction):
    if transaction.seller in self.seller_category_map:
        return self.seller_category_map[transaction.seller]
    elif transaction.seller in self.seller_category_crowd_overrides_map:
        self.seller_category_map[transaction.seller] = \
            self.seller_category_crowd_overrides_map[transaction.seller].peek_min()
        return self.seller_category_map[transaction.seller]
    return None
```

#### 유스케이스 3: 서비스가 예산을 추천한다

**핵심 트릭 — 1억 개 예산 항목을 저장하지 않는다.**

소득 구간별 **일반 예산 템플릿**(주거 40%, 식비 20%, 교통 10%, 쇼핑 20%…)을 쓰면, **사용자가 직접 바꾼 것만** `budget_overrides` 테이블에 저장하면 된다.

```python
def create_budget_template(self):
    return {
        DefaultCategories.HOUSING:  self.income * .4,
        DefaultCategories.FOOD:     self.income * .2,
        DefaultCategories.GAS:      self.income * .1,
        DefaultCategories.SHOPPING: self.income * .2,
    }
```

> 💡 **저장 대신 계산.** 기본값이 규칙으로 표현되면 예외만 저장한다. 제약에 적힌 "예산 항목 1억 개"가 통째로 사라진다.

#### 집계 방법 두 가지

| 방식 | 설명 | 트레이드오프 |
|---|---|---|
| **SQL 쿼리** | `transactions` 테이블에 집계 쿼리를 돌려 `monthly_spending` 생성 | 단순하지만 **50억 행 DB에 부하**를 준다 |
| **MapReduce** | Object Store의 **원본 로그 파일**에 배치 잡을 돌린다 | **DB 부하를 크게 줄인다**. 지연은 늘어난다 |

`monthly_spending`은 전체 50억 거래보다 **행 수가 훨씬 적다**(사용자당 월 거래는 많지만 카테고리는 10개뿐). 사용자가 카테고리를 바꾸면 **Budget Service를 다시 호출해 재분석**한다.

**MapReduce 구현** — 로그 형식은 탭 구분 `user_id  timestamp  seller  amount`

```python
class SpendingByCategory(MRJob):

    def mapper(self, _, line):
        """(user_id, 2016-01, shopping), 25 형태로 방출"""
        user_id, timestamp, seller, amount = line.split('\t')
        category = self.categorizer.categorize(seller)
        period = self.extract_year_month(timestamp)
        if period == self.current_year_month:
            yield (user_id, period, category), amount

    def reducer(self, key, values):
        """키별로 합산 → (user_id, 2016-01, shopping), 125"""
        total = sum(values)
        yield key, total
```

- **Map**: 로그 한 줄 → `(사용자, 연월, 카테고리) → 금액` 키-값으로 변환
- **Reduce**: 같은 키의 금액을 **합산**
- `handle_budget_notifications`가 예산 근접·초과 시 알림 API를 호출

### Step 4 — 설계 확장하기

> ⚠️ **초기 설계에서 최종 설계로 바로 점프하지 말 것.**
> ① 벤치마크·부하 테스트 → ② 프로파일링으로 병목 탐지 → ③ 대안과 트레이드오프를 따져 병목 해소 → ④ 반복.
> 이 절차 자체를 말로 설명하는 것이 면접의 핵심이다 — [[2026-08-28-backend-scaling-to-millions]]

추가 유스케이스: **사용자가 요약과 거래 내역을 조회한다.**

**읽기 경로 (Cache-aside)**

1. Client → Web Server → **Read API**
   - 정적 콘텐츠는 **Object Store(S3)** 에서 제공하고 **CDN(Content Delivery Network)** 에 캐싱
2. **Read API**:
   - **Memory Cache**(Redis, Memcached) 확인
   - 있으면 캐시 내용 반환
   - 없으면 SQL Database에서 가져와 **캐시를 갱신**

세션, 카테고리별 집계 통계, 최근 거래를 캐시에 둔다 — [[2026-08-11-backend-cache]]

**데이터 계층 분리**

| 데이터 | 저장 위치 | 이유 |
|---|---|---|
| 최근 1개월 `transactions` | **SQL Database** | 실시간 조회 |
| 그 이전 거래 | **데이터 웨어하우스 / Object Store** | S3는 250 GB/월을 여유롭게 감당 |
| `monthly_spending` 집계 | **별도 Analytics Database** (Redshift, BigQuery) | 분석 쿼리를 운영 DB에서 분리 |

**병목별 대응**

| 병목 | 수치 | 대응 |
|---|---|---|
| 읽기 200 QPS(피크는 더 높음) | 인기 콘텐츠 | **Memory Cache**가 흡수. 불균등 트래픽·스파이크에도 유효 |
| 캐시 미스 | — | **SQL Read Replica**가 처리 (복제 부하에 짓눌리지 않는 한) |
| 쓰기 2,000 TPS(피크는 더 높음) | **단일 Master-Slave로는 버겁다** | **Federation · Sharding · Denormalization · SQL Tuning** |
| 그래도 부족하면 | — | 일부 데이터를 **NoSQL Database**로 이전 |

## 내가 정리한 내용

### 1. 이 문제의 성격

월 거래 50억 건, 월 읽기 5억 건으로 **읽기보다 쓰기가 10배 더 많기 때문에** 쓰기 중심 문제다.

### 2. 큐를 쓰는 이유와 대가

- **얻는 것**: 응답 즉시 반환, 장애 격리, 부하 평준화, 독립 확장, 재시도
- **잃는 것**: 결과적 일관성, 완료를 알릴 장치가 별도로 필요, 복잡도, 멱등성 요구, 백프레셔

### 3. 저장과 계산을 맞바꾼 두 장면 — 방향이 반대다

- **예산** — 저장을 버리고 계산을 택함. 기본값을 데이터가 아니라 **규칙으로 표현하고 예외만 저장**한다(소득 기반 템플릿 + `budget_overrides`). 1억 개 → 약 300만 개.
- **월별 집계** — 계산을 버리고 저장을 택함. 미리 집계해 `monthly_spending`에 **비정규화로 추가 저장**한다. 저장은 늘지만 50억 행 스캔을 피한다.
- 어느 쪽이 비싼지에 따라 방향이 정해진다. 예산은 계산이 싸서(곱셈 몇 번) 계산을, 집계는 계산이 비싸서(50억 행 스캔) 저장을 택했다.

### 4. 원본 로그를 따로 남기는 이유

- **재처리(reprocessing) 가능성** 때문. 원본 로그가 없으면 분류 로직에 오류·버그가 있었을 때 복구가 불가능하다.
- **비용 문제** — 모든 원본 로그를 SQL DB에 넣으면 비싸다. 상대적으로 싼 Object Store에 보관한다.

### 5. 확장 시 병목과 대응

**읽기 200 QPS(피크는 더 높음)**

1. **Memory Cache**(Redis/Memcached)가 인기 콘텐츠를 흡수. 불균등 트래픽·스파이크에도 유효
2. **캐시 미스는 SQL Read Replica**가 처리
3. 정적 콘텐츠는 Object Store → **CDN**

**쓰기 2,000 TPS(피크는 더 높음)** — 단일 Master-Slave로는 버겁다

- **Federation** (기능별 세로 분할)
- **Sharding** (행 가로 분할, 샤드 키는 **`user_id`**) — 조회가 전부 `user_id`로 시작하므로 산개-수집(scatter-gather)이 없고, 시간 기반과 달리 핫스팟도 없다
- **Denormalization**, **SQL Tuning**
- 그래도 부족하면 일부를 **NoSQL**로

**데이터 계층 분리** — 최근 1개월 `transactions`만 SQL에, 나머지는 데이터 웨어하우스/Object Store로. `monthly_spending`은 별도 **Analytics DB**(Redshift/BigQuery).

## 검토 결과

### 확인된 부분

- **쓰기 우세 판단을 수치 근거로** 설명했다 — "쓰기가 많다"가 아니라 "월 50억 vs 5억이므로 10:1"이라고 근거를 붙였다. 어림 계산을 판단으로 연결하는 습관이다.
- **큐의 트레이드오프를 얻는 것 5개 / 잃는 것 5개**로 빠짐없이 정리했다. 특히 **멱등성**과 **백프레셔**는 처음 접하고 바로 정리한 항목이다.
- **원본 로그를 남기는 이유의 우선순위**가 정확하다 — **재처리 가능성이 첫째**, 비용이 둘째. 순서를 뒤집으면 "그냥 싼 데 두는 것"으로 오해된다.
- **멱등성 실전 문제**(워커가 절반만 넣고 죽고 메시지가 재전달됨)에 중복 삽입 문제를 짚고 **유니크 조합/키**로 방어하는 해법까지 스스로 도출했다.

### 보강 포인트

#### ① 저장 ↔ 계산 트레이드는 방향이 두 개다

| | 내용 |
|---|---|
| **전** | 기본값을 데이터가 아니라 규칙으로 표현하고 예외만 저장 |
| **후** | 저장과 계산을 맞바꾸는 장면이 **두 개이고 방향이 반대**다. **예산**은 저장을 버리고 계산을 택함(1억 → 300만). **월별 집계**는 계산을 버리고 저장을 택함(비정규화로 추가 저장) |

| 장면 | 무엇을 하나 | 저장량 | 무엇을 아끼나 |
|---|---|---|---|
| 예산 템플릿 | 규칙으로 계산, 예외만 저장 | **줄어든다** (1억 → 300만) | **저장 공간** |
| `monthly_spending` | 미리 계산해 추가 저장 | **늘어난다** (비정규화) | **읽기 비용** (50억 → 1억 행) |

"저장을 줄이는 게 좋은 설계"가 아니다. **어느 쪽이 비싼지 보고 방향을 정하는 것**이 설계다.

#### ② 확장 대응에 계층과 근거가 빠졌다

| | 내용 |
|---|---|
| **전** | 읽기 병목 → 메모리 캐시. 쓰기 병목 → Federation, Sharding 고려 |
| **후** | 위 `내가 정리한 내용` 5번의 계층 구조 전체. 특히 **캐시 미스를 받는 Read Replica 층**과 **샤드 키가 `user_id`인 근거** |

캐시는 만능이 아니라 **첫 번째 방어선**이다. 뚫린 요청을 받아 줄 두 번째 층(Read Replica)이 반드시 필요하다.

```text
읽기 경로
  CDN (정적)  →  Memory Cache  →  Read Replica  →  Master
                    첫 방어선        캐시 미스        최후

쓰기 경로
  Queue (평준화)  →  Master  →  [Federation → Sharding → NoSQL]
                                   버거우면 이 순서로 확장
```

### 심화: 멱등성 — 큐가 아니라 소비자의 책임

워커가 거래를 절반만 넣고 죽으면, 큐는 메시지를 다른 워커에 **재전달**한다. **"어디까지 넣었는지"를 워커가 알 방법이 없다**는 게 문제의 본질이다.

| 방어 층 | 방법 |
|---|---|
| **DB 층** | `(user_id, created_at, seller, amount)`에 유니크 제약, 또는 금융기관이 주는 **거래 ID**를 PK로. 재실행 시 `INSERT ... ON DUPLICATE KEY IGNORE`로 중복을 조용히 무시 |
| **작업 층** | 작업 ID를 부여하고 "이 계좌·이 기간 추출 완료" 상태를 기록. 재실행 시 완료 구간은 건너뜀 |

**핵심 원리**: 대부분의 큐는 **at-least-once 전달**을 보장한다. 큐에게 "한 번만 보내줘"를 요구하는 대신, **몇 번 와도 결과가 같도록 소비자를 만든다.** 재무 앱에서 거래 중복 삽입은 치명적이라 이 방어가 선택이 아니다.

[[2026-08-27-backend-design-web-crawler]]의 URL 중복 판정과 같은 종류의 문제다.

### 심화: 샤드 키를 `user_id`로 잡는 이유

이 서비스의 읽기 요청은 전부 `user_id`로 시작한다.

```text
"내 이번 달 식비 얼마?"   → WHERE user_id = 42
"내 최근 거래 20건"       → WHERE user_id = 42 ORDER BY created_at
"내 카테고리별 월 집계"   → WHERE user_id = 42
```

| 샤드 키 | 한 사용자의 데이터 | 조회 1건이 닿는 샤드 |
|---|---|---|
| **`user_id`** | **한 샤드에 모여 있다** | **1개** ✅ |
| `transaction_id`(해시) | 모든 샤드에 흩어짐 | **전부** ❌ 산개-수집 |
| `created_at`(시간) | 시간순으로 흩어짐 | 여러 개 ❌ + 핫스팟 |

**산개-수집(scatter-gather)**: `transaction_id`로 샤딩하면 "내 거래 20건"에 모든 샤드를 물어보고 합쳐야 한다. 샤드 100개면 요청 1건이 쿼리 100개가 된다.

**핫스팟(hotspot)**: `created_at`으로 샤딩하면 쓰기가 전부 최신 샤드 하나에 몰린다.

```text
샤드 1 (2026-01)  ▁  놀고 있음
샤드 2 (2026-02)  ▁  놀고 있음
샤드 8 (2026-08)  ████████ 2,000 TPS 전부 여기 ← 핫스팟
```

샤딩을 한 이유(쓰기 분산)가 통째로 무효화된다. `user_id`는 1,000만 사용자의 거래가 무작위 시점에 발생하므로 **쓰기가 고르게 퍼진다.**

**대가**

| 대가 | 내용 |
|---|---|
| 사용자 간 분석이 어려움 | "판매자별 전체 통계" 같은 쿼리는 모든 샤드를 훑어야 함 → **Analytics DB로 분리**하는 이유 |
| 핫 유저 | 거래가 유난히 많은 사용자의 샤드만 무거워짐 |
| 리샤딩이 아픔 | 8개→16개면 데이터 절반이 이사 → **일관된 해싱(consistent hashing)** 으로 완화 |

`monthly_spending`도 **같은 키(`user_id`)로 샤딩**해야 한다. 다른 키로 나누면 샤드 간 조인이 생긴다.

### 심화: Federation vs Sharding — 세로냐 가로냐

| 패턴 | 자르는 방향 | Mint 적용 예 |
|---|---|---|
| **Federation**(연합) | **테이블/기능 단위**로 DB 분리 (세로) | `users` DB / `transactions` DB / `budgets` DB |
| **Sharding**(샤딩) | **같은 테이블의 행**을 분할 (가로) | `transactions`를 `user_id`로 16조각 |
| **Denormalization** | 조인을 없애려 데이터 중복 | `monthly_spending` 집계 테이블 자체 |
| **SQL Tuning** | 쿼리·인덱스·스키마 최적화 | 인덱스 재설계, `amount`를 정수 센트로 |

**Federation은 세로로, Sharding은 가로로** 자른다.

### 심화: 불변 로그 + 파생 뷰 아키텍처

```text
Object Store  : 원본 로그 (가공 전, 불변, 값쌈)     ← 진실의 원천
SQL Database  : 파싱·분류된 행 (질의 가능, 비쌈)    ← 서빙용 뷰
```

`transactions` 테이블은 **포인터를 담지 않는다.** 파싱된 거래 행을 그대로 담는다. 이미지 저장소처럼 "DB=메타데이터, S3=블롭" 구조가 아니라 **같은 사실을 두 가지 형태로** 갖고 있는 것이다.

| 상황 | 원본 로그가 없으면 | 있으면 |
|---|---|---|
| Category Service 사전 개선 | 과거 거래는 영영 잘못 분류된 채 | **전체 재분류 가능** |
| 분류 로직 버그 | 복구 불가 | 재실행으로 복구 |
| 사용자가 카테고리 수정 | 재집계 근거 부족 | 재집계 가능 |
| 새 분석 지표 추가 | 과거 데이터로 불가 | 소급 계산 가능 |

DB의 파싱된 행은 이미 **정보가 손실된 가공물**이고, 원본 로그는 **불변의 사실**이라 몇 번이든 다시 해석할 수 있다. **원본을 지우지 않으면 뷰는 언제든 버리고 다시 만들 수 있다** — 이것이 핵심 자산이다. 람다 아키텍처(Lambda Architecture)·이벤트 소싱(Event Sourcing)과 같은 뿌리.

### 심화: SQL 집계 vs MapReduce — 자원 경합 문제

| | (가) SQL 집계 쿼리 | (나) MapReduce on 원본 로그 |
|---|---|---|
| 장점 | 단순. 추가 인프라 0. 최신 반영 | **운영 DB 부하 0**. 수평 확장. 전체 재처리 가능 |
| 단점 | **50억 행 집계** → 사용자 조회가 같이 느려짐. 잠금·복제 지연 | 배치 주기만큼 지연. 별도 인프라 |

핵심은 **자원 경합**이다. 이미 쓰기 2,000 TPS로 헐떡이는 DB에 50억 행 집계를 얹으면 **거래 쓰기와 사용자 조회가 같이 죽는다.** MapReduce는 이 경합을 **다른 저장소로 밀어낸다.**

| 테이블 | 규모 |
|---|---:|
| `transactions` | **50억 행/월** |
| `monthly_spending` | 1,000만 × 10 카테고리 = **1억 행/월** |

**50배 축소** — 사용자당 월 거래는 수백 건이어도 카테고리는 10개뿐이다.

### 이전 학습과의 연결

- [[2026-08-12-backend-asynchronism]] — 큐를 통한 비동기 처리가 이 설계의 중심축. 그때 배운 **부하 평준화**와 **결과적 일관성** 트레이드오프가 실제 문제에서 어떻게 나타나는지 확인했다.
- [[2026-08-19-backend-latency-numbers]] — `1개월 ≈ 250만 초` 치트시트로 2,000 TPS / 200 QPS를 도출. 인덱스가 메모리에 상주해야 하는 이유(메모리 1 MB 순차 읽기 250 μs vs SSD 4배, 디스크 80배)도 여기서 왔다.
- [[2026-08-11-backend-cache]] — 읽기 경로의 **Cache-aside** 패턴을 그대로 적용.
- [[2026-08-27-backend-design-web-crawler]] — 외부 시스템에서 데이터를 끌어오는 구조와 **중복 판정** 문제가 같은 계열. 여기선 멱등성으로 나타났다.
- [[2026-08-28-backend-scaling-to-millions]] — "초기 설계에서 최종 설계로 바로 점프하지 말 것" 절차(벤치마크 → 프로파일링 → 병목 해소 → 반복)를 그대로 따랐다.
- [[2026-08-20-backend-design-pastebin]], [[2026-08-21-backend-design-twitter]] — 둘 다 읽기 우세 문제. Mint는 **쓰기 우세**라 병목과 처방이 반대편에 있다.
- [[2026-08-14-backend-rpc-rest]] — 외부는 REST, 내부는 RPC라는 구분이 여기서도 반복된다.

### 오늘 나온 축약어

| 축약어 | 풀네임 | 설명 |
|---|---|---|
| TPS | Transactions Per Second | 초당 트랜잭션 수 (쓰기) |
| QPS | Queries Per Second | 초당 쿼리 수 (읽기) |
| SQS | Simple Queue Service | AWS 관리형 메시지 큐 |
| CDN | Content Delivery Network | 콘텐츠 전송 네트워크 |
| RDBMS | Relational Database Management System | 관계형 데이터베이스 관리 시스템 |
| REST | Representational State Transfer | 외부 클라이언트용 HTTP API 스타일 |
| RPC | Remote Procedure Call | 내부 서비스 간 통신 방식 |
| S3 | Simple Storage Service | AWS 객체 저장소 |
| PK | Primary Key | 기본 키 |
| PFM | Personal Finance Management | 개인 재무 관리 — Mint.com의 서비스 분류 |
