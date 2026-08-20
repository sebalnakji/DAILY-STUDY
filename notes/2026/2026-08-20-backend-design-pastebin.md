---
date: 2026-08-20
track: backend
area: Backend & System Design
topic: 실전 설계 — Pastebin / Bit.ly
source_repository: donnemartin/system-design-primer
source_file: solutions/system_design/pastebin/README.md
status: completed
---

# 실전 설계 — Pastebin(또는 Bit.ly) 설계하기

## 출처

- 기준 레포: `donnemartin/system-design-primer`
- 원본 파일: `solutions/system_design/pastebin/README.md`
- 영역: Backend / System Design
- 이전 학습: [[2026-08-19-backend-latency-numbers]] — **본문·부록을 마치고 실전 문제로 진입**

## 질문

> **Pastebin.com(또는 Bit.ly)을 설계하라.**
>
> 원문: *Design Pastebin.com (or Bit.ly)*

## 핵심 개념

시스템 디자인 면접의 **4단계 절차**를 그대로 따른다.

```text
① 사용 사례와 제약 정리  →  ② 상위 수준 설계  →  ③ 핵심 컴포넌트 설계  →  ④ 규모 확장
```

### Step 1. 사용 사례와 제약 정리

**요구사항을 모으고 문제 범위를 정한다. 명확히 하기 위해 질문하고, 가정을 논의한다.**

**범위에 포함**
- 사용자가 텍스트 블록을 입력하면 **무작위 생성된 링크**를 받는다 (만료 설정 가능, 기본은 만료 없음)
- 사용자가 paste의 URL을 입력해 **내용을 조회**한다
- 사용자는 **익명**이다
- 서비스가 **페이지 분석(월간 방문 통계)** 을 추적한다
- 서비스가 **만료된 paste를 삭제**한다
- 서비스는 **고가용성**을 갖는다

**범위 밖**: 계정 등록·로그인, 문서 편집, 공개 범위 설정, 사용자 지정 단축링크

**가정**
- 트래픽은 **고르게 분포하지 않는다**
- 단축 링크를 따라가는 것은 **빨라야 한다**
- paste는 **텍스트 전용**
- 페이지 조회 분석은 **실시간일 필요가 없다**
- 사용자 1천만 명 / 월 1천만 쓰기 / 월 1억 읽기 / **읽기:쓰기 = 10:1**

### 어림 계산 (Calculate usage)

paste 하나의 크기:

```text
내용                              1 KB
shortlink                         7 bytes
expiration_length_in_minutes      4 bytes
created_at                        5 bytes
paste_path                      255 bytes
────────────────────────────────────────
합계                          ~1.27 KB
```

- 월 신규 paste 내용 **12.7 GB** (1.27 KB × 1천만)
- **3년이면 ~450 GB**, 단축링크 **3.6억 개**
- 평균 **초당 4건 쓰기**, **초당 40건 읽기**

**유용한 환산 가이드**

```text
월 250만 초
초당 1건    = 월 250만 건
초당 40건   = 월 1억 건
초당 400건  = 월 10억 건
```

→ [[2026-08-19-backend-latency-numbers]]의 어림 계산이 실제로 쓰이는 자리

### Step 3. 핵심 컴포넌트 설계

#### 사용 사례 ①: 텍스트를 입력하고 링크를 받는다

**관계형 데이터베이스를 거대한 해시 테이블처럼** 사용해, 생성된 URL을 paste 파일이 있는 위치에 매핑한다.

- 파일 서버를 직접 관리하는 대신 **Amazon S3 같은 관리형 객체 저장소(Object Store)** 나 **NoSQL 문서 저장소**를 쓸 수 있다.
- 관계형 대신 **NoSQL 키-값 저장소**도 대안이다. → [[2026-08-10-backend-sql-or-nosql]]의 선택 기준 논의

**흐름**

```text
① 클라이언트 → 웹 서버(리버스 프록시로 동작)
② 웹 서버 → Write API 서버
③ Write API 서버:
   - 고유 URL 생성 (SQL DB에서 중복 확인, 중복이면 재생성)
   - pastes 테이블에 저장
   - paste 데이터를 Object Store에 저장
   - URL 반환
```

**`pastes` 테이블**

```sql
shortlink char(7) NOT NULL
expiration_length_in_minutes int NOT NULL
created_at datetime NOT NULL
paste_path varchar(255) NOT NULL
PRIMARY KEY(shortlink)
```

- `shortlink`를 **기본 키**로 두면 **인덱스가 생겨 고유성을 강제**한다.
- `created_at`에 **추가 인덱스**를 만들어 조회를 빠르게 하고(전체 스캔 대신 로그 시간) 데이터를 메모리에 유지한다.
- 원문 인용: **메모리에서 1MB 순차 읽기는 약 250us, SSD는 4배, 디스크는 80배 오래 걸린다.** → [[2026-08-19-backend-latency-numbers]]

**고유 URL 생성**

```python
url = base_encode(md5(ip_address + timestamp))[:URL_LENGTH]
```

- **MD5**: IP + 타임스탬프의 해시. 널리 쓰이는 128비트 해시이며 **균등 분포**한다.
- **Base 62 인코딩**: `[a-zA-Z0-9]`로 인코딩해 **URL에 적합**하다(특수문자 이스케이프 불필요). **결정적**이며, Base 64는 `+`와 `/` 때문에 URL에 문제가 된다.
- **앞 7자**를 취하면 `62^7`가지로, **3년간 3.6억 개**라는 제약을 감당하기에 충분하다.

**공개 API는 REST**, **내부 통신은 RPC**를 쓸 수 있다. → [[2026-08-14-backend-rpc-rest]]

```bash
curl -X POST --data '{ "expiration_length_in_minutes": "60", \
    "paste_contents": "Hello World!" }' https://pastebin.com/api/v1/paste
```

#### 사용 사례 ②: URL로 내용을 조회한다

```text
① 클라이언트 → 웹 서버
② 웹 서버 → Read API 서버
③ Read API 서버:
   - SQL DB에서 생성된 URL 확인
   - 있으면 Object Store에서 내용을 가져옴
   - 없으면 에러 메시지 반환
```

#### 사용 사례 ③: 페이지 분석 추적

**실시간이 요구사항이 아니므로**, 웹 서버 로그를 **MapReduce**로 처리해 조회수를 생성하면 된다.

```python
class HitCounts(MRJob):
    def mapper(self, _, line):
        url = self.extract_url(line)
        period = self.extract_year_month(line)
        yield (period, url), 1      # (2016-01, url0), 1

    def reducer(self, key, values):
        yield key, sum(values)      # (2016-01, url0), 2
```

#### 사용 사례 ④: 만료된 paste 삭제

**SQL DB를 스캔**해 만료 타임스탬프가 현재보다 오래된 항목을 찾아 **삭제(또는 만료로 표시)** 한다.

### Step 4. 규모 확장

> ⚠️ **원문의 경고: 초기 설계에서 최종 설계로 바로 뛰어들지 말 것.**
>
> **반복적으로** 진행한다고 말해야 한다. ① **벤치마크/부하 테스트** → ② **프로파일링**으로 병목 찾기 → ③ 대안과 트레이드오프를 평가하며 병목 해결 → ④ 반복.

→ [[2026-08-06-backend-sql-tuning-nosql]]의 "측정이 먼저"와 동일한 원칙

**적용할 요소들**

- **분석 DB**: Amazon Redshift, Google BigQuery 같은 **데이터 웨어하우스**
- **Object Store**: Amazon S3는 월 12.7 GB를 충분히 감당
- **메모리 캐시**: 초당 40건 읽기(피크는 더 높음)에 대해 **인기 콘텐츠는 캐시가 처리**한다. **고르지 않은 트래픽과 스파이크 흡수**에도 유용. → [[2026-08-11-backend-cache]]
- **SQL 읽기 복제본**: 캐시 미스를 처리한다. 단 **복제본이 쓰기 복제에 매달리지 않아야** 한다. → [[2026-08-05-backend-federation-sharding]]
- **쓰기**: 초당 4건은 단일 **SQL Write Master-Slave**로 가능. 부족하면 **페더레이션·샤딩·비정규화·SQL 튜닝**을 추가하고, 일부 데이터를 **NoSQL**로 옮기는 것도 고려한다.

## 기준 답변

기준 레포의 답변을 바탕으로 핵심만 재구성한다.

**Step 1 — 사용 사례와 제약**: 텍스트를 입력받아 무작위 링크 생성(만료 설정 가능), URL로 내용 조회, 익명 사용자, 월간 방문 통계, 만료 paste 삭제, 고가용성. 사용자 1천만 명, 월 1천만 쓰기, 월 1억 읽기, **읽기:쓰기 10:1**. paste당 약 **1.27 KB**로 월 **12.7 GB**, 3년 **450 GB**, 평균 **초당 4건 쓰기 / 40건 읽기**.

**Step 3 — 핵심 컴포넌트**: 관계형 DB를 **거대한 해시 테이블**처럼 써서 URL을 paste 파일 경로에 매핑하고, 실제 내용은 **Object Store(S3)** 에 둔다. `shortlink`를 기본 키로 삼아 인덱스로 **고유성을 강제**하고, `created_at`에 인덱스를 추가해 조회를 빠르게 한다.

**고유 URL**은 `base_encode(md5(ip_address + timestamp))[:7]`로 만든다. MD5는 균등 분포하고, **Base 62**는 `[a-zA-Z0-9]`라 URL에 적합하다(Base 64는 `+`, `/` 때문에 부적합). 앞 7자면 `62^7`로 3년간 3.6억 개를 감당한다.

**공개 API는 REST**, 내부 통신은 **RPC**를 쓸 수 있다.

**분석**은 실시간이 아니어도 되므로 웹 서버 로그를 **MapReduce**로 집계한다. **만료 삭제**는 만료 타임스탬프가 지난 항목을 스캔해 삭제한다.

**Step 4 — 규모 확장**: **초기 설계에서 최종 설계로 바로 뛰지 말고**, 벤치마크 → 프로파일링 → 병목 해결 → 반복의 순서로 진행한다고 말해야 한다. 인기 콘텐츠는 **메모리 캐시**가 처리해 고르지 않은 트래픽과 스파이크를 흡수하고, **SQL 읽기 복제본**이 캐시 미스를 담당한다. 초당 4건 쓰기는 단일 마스터로 가능하며, 부족하면 페더레이션·샤딩·비정규화·SQL 튜닝을 적용하고 일부를 NoSQL로 옮긴다.

## 내가 정리한 내용

**1. 시스템 디자인 면접의 4단계 절차**

**① 사용 사례와 제약 정리 → ② 상위 수준 설계 → ③ 핵심 컴포넌트 설계 → ④ 규모 확장**

- **①** 에서는 **질문으로 범위를 좁히고**(무엇이 범위 밖인지 명시), **가정을 밝히며**, **어림 계산**으로 규모를 파악한다.
- **④** 에서는 **초기 설계에서 최종 설계로 바로 뛰어들지 않는다.** 벤치마크/부하 테스트 → 프로파일링으로 병목 찾기 → 대안과 트레이드오프를 평가하며 해결 → 반복의 순서로 진행한다고 말해야 한다.

**2. 본문을 Object Store에 두는 이유**

- **SQL DB가 가벼워진다.** 인덱스와 데이터가 **메모리에 더 많이 올라가고**, 조회 시 **불필요한 본문을 읽지 않으며**, **백업과 복제가 빨라진다.**
- **저장 비용이 S3가 RDBMS보다 훨씬 싸고 확장성이 높다.** S3는 사실상 무한 확장되며 관리가 필요 없다.
- 즉 성능이 좋아지는 것은 "S3가 빨라서"가 아니라 **"DB가 가벼워져서"** 다. 이는 *"큰 BLOB 저장을 피하고 객체의 위치를 저장하라"* 는 SQL 튜닝 원칙과 같다.

**3. 읽기 40 : 쓰기 4 상황의 확장 전략**

**읽기 우선 전략**을 쓴다. **캐시가 인기 콘텐츠를 처리**하고, **SQL 읽기 복제본이 캐시 미스를 담당**한다. 트래픽이 고르게 분포하지 않는다는 가정이 있으므로, 쏠림과 스파이크를 흡수하는 **캐시가 가장 앞단**에 온다.

단, **읽기 복제본이 쓰기 복제에 매달리지 않아야** 한다. 쓰기가 많아지면 복제본이 재생에 묶여 읽기를 제대로 처리하지 못한다.

초당 4건 쓰기는 단일 마스터로 감당 가능하며, 부족해지면 **페더레이션·샤딩·비정규화·SQL 튜닝**을 적용하고 일부 데이터를 NoSQL로 옮기는 것도 고려한다.

## 검토 결과

### 확인된 부분

- **4단계 절차를 정확히 기억함.** 이 틀 자체가 면접 답변의 골격이다.
- **캐시 → 읽기 복제본의 순서**를 정확히 파악. 트래픽 쏠림이라는 가정과 연결했다.
- Q1 교정을 정확히 흡수 — "S3가 빨라서"가 아니라 "DB가 가벼워져서".

### 보강 포인트

- ⚠️ **"S3가 읽기가 빠르다"는 사실이 아니다.** (Q1 초기 답변 → 교정)
  - S3는 **네트워크를 타는 객체 저장소라 지연이 오히려 크다.**

  ```text
  본문을 DB에 넣으면:  행 하나가 1.27 KB  →  450 GB 테이블
  본문을 S3로 빼면:    행 하나가 ~270 B   →  약 100 GB 테이블
  ```

  **DB가 4배 이상 가벼워지는 것**이 성능 향상의 실제 메커니즘이다. → [[2026-08-06-backend-sql-tuning-nosql]]
- **각 단계에서 무엇을 하는지** 한마디씩 붙일 것. 특히 ①의 **질문·가정·어림 계산**과 ④의 **반복적 접근**이 채점 포인트다.
- **복제본의 한계**를 함께 말하면 강하다. 원문도 *"복제본이 쓰기 복제에 매달리지 않는 한"* 이라는 조건을 단다. → [[2026-08-05-backend-federation-sharding]]

### Step 1 — 범위 정하기와 어림 계산

**범위 밖을 명시하는 것이 중요하다** — 계정 등록·로그인·편집·사용자 지정 링크는 제외. 다 하려 들면 아무것도 못 한다.

```text
paste 하나 ≈ 1.27 KB (내용 1KB + 메타데이터 ~270B)
× 월 1천만 = 월 12.7 GB
× 3년 = 450 GB, 단축링크 3.6억 개

평균 초당 쓰기 4건 / 읽기 40건
```

**환산 가이드**

```text
월 250만 초
초당 1건   = 월 250만 건
초당 40건  = 월 1억 건
초당 400건 = 월 10억 건
```

→ [[2026-08-19-backend-latency-numbers]]의 어림 계산이 실제로 쓰이는 자리.

### 단축 URL 생성 — 면접 단골

```python
url = base_encode(md5(ip_address + timestamp))[:7]
```

- **왜 Base 62인가**: `[a-zA-Z0-9]`라 **URL에 그대로 쓸 수 있다.** Base 64는 `+`, `/` 때문에 **이스케이프가 필요**하다.
- **왜 7자인가**: `62^7 ≈ 3.5조`. 제약이 3년간 3.6억 개이므로 충분하다. **숫자로 근거를 댄 것.**
- MD5는 **균등 분포**하는 128비트 해시이며, Base 62는 **결정적**이다(무작위성 없음).

### 테이블 설계

```sql
shortlink char(7) NOT NULL      -- PRIMARY KEY (인덱스로 고유성 강제)
expiration_length_in_minutes int
created_at datetime             -- 추가 인덱스 (만료 삭제용)
paste_path varchar(255)         -- S3 경로
```

원문이 어제 배운 숫자를 직접 인용한다.

> **메모리에서 1MB 순차 읽기는 약 250us, SSD는 4배, 디스크는 80배 오래 걸린다.**

**인덱스를 거는 목적이 "데이터를 메모리에 유지"** 하는 것이라는 점이 드러난다. → [[2026-08-19-backend-latency-numbers]]

### 배운 것들이 그대로 적용된다

| 설계 요소 | 배운 날 |
|---|---|
| 웹 서버를 **리버스 프록시**로 | [[2026-07-31-backend-reverse-proxy]] |
| **공개 API는 REST, 내부는 RPC** | [[2026-08-14-backend-rpc-rest]] |
| 분석은 **비동기 배치(MapReduce)** | [[2026-08-12-backend-asynchronism]] |
| 인기 콘텐츠는 **메모리 캐시** | [[2026-08-11-backend-cache]] |
| 캐시 미스는 **읽기 복제본** | [[2026-08-04-backend-database-rdbms]] |
| 쓰기 부족 시 **페더레이션·샤딩** | [[2026-08-05-backend-federation-sharding]] |
| 큰 BLOB 대신 **위치 저장** | [[2026-08-06-backend-sql-tuning-nosql]] |
| **측정이 먼저**(벤치마크·프로파일) | [[2026-08-06-backend-sql-tuning-nosql]] |

> **부품을 배우는 단계에서 조립하는 단계로 넘어온 첫 문제.**

### 사용 사례별 설계 요약

**① 텍스트 입력 → 링크 반환**
```text
클라이언트 → 웹 서버(리버스 프록시) → Write API
  → 고유 URL 생성 (SQL DB에서 중복 확인)
  → pastes 테이블에 저장
  → paste 데이터를 Object Store에 저장
  → URL 반환
```

**② URL → 내용 조회**
```text
클라이언트 → 웹 서버 → Read API
  → SQL DB에서 URL 확인
  → 있으면 Object Store에서 내용을 가져옴, 없으면 에러
```

**③ 분석 추적** — 실시간이 요구사항이 아니므로 웹 서버 로그를 **MapReduce**로 집계한다.

**④ 만료 삭제** — SQL DB를 스캔해 만료 타임스탬프가 지난 항목을 삭제(또는 만료 표시)한다.

### 오늘 나온 축약어

| 축약어 | 풀네임 |
|---|---|
| MD5 | Message-Digest algorithm 5 |
| S3 | Simple Storage Service |
| RDBMS | Relational Database Management System |
| BLOB | Binary Large Object |
| REST / RPC | REpresentational State Transfer / Remote Procedure Call |

