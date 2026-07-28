---
date: 2026-07-28
track: backend
area: Backend & System Design
topic: DNS (Domain Name System)
source_repository: donnemartin/system-design-primer
source_file: README.md
status: completed
---

# DNS(Domain Name System)란 무엇이며 어떻게 동작하는가?

## 출처

- 기준 레포: `donnemartin/system-design-primer`
- 원본 파일: `README.md` — `## Domain name system` 섹션
- 영역: Backend / System Design
- 이전 학습: [[2026-07-25-backend-availability-patterns]]

## 질문

> **DNS란 무엇이며, 어떻게 도메인 이름을 IP 주소로 변환하는가?**
>
> 원문: *Domain name system*

## 핵심 개념

질문에 답하기 위해 필요한 핵심 개념을 정리한다.

- **DNS의 역할**: 사람이 읽는 도메인 이름(`www.example.com`)을 기계가 쓰는 **IP 주소**로 변환한다. "인터넷의 전화번호부".
- **계층 구조(hierarchical)**: 최상위에 소수의 **권한 있는(authoritative) 서버**가 있고 아래로 위임된다. 라우터/ISP가 어떤 DNS 서버에 물어볼지 알려준다.
- **캐싱과 TTL**
  - 하위 DNS 서버, 브라우저, OS가 조회 결과를 **캐싱**해 반복 조회를 줄인다.
  - 캐시 유효기간은 **TTL(Time To Live)** 로 정해진다.
  - **전파 지연(propagation delay)**: 레코드를 바꿔도 캐시 때문에 전 세계에 퍼지는 데 시간이 걸린다 → 캐시가 낡은(stale) 값을 줄 수 있음. → [[2026-07-22-backend-availability-vs-consistency]] (최종 일관성과 같은 뿌리)
- **주요 레코드 타입**
  - **A record**: 이름 → **IP 주소** 직접 매핑
  - **CNAME**: 이름 → **다른 이름**(별칭). 예: `example.com` → `www.example.com`
  - **NS record**: 해당 도메인/서브도메인을 담당하는 **DNS 서버** 지정
  - **MX record**: **메일 서버** 지정
- **트래픽 라우팅(관리형 DNS: Route 53, CloudFlare 등)** — DNS가 부하 분산·배포 전략의 도구가 된다
  - **Weighted round robin**: 가중치로 분배. 점검 중 서버 제외, 서로 다른 클러스터 크기 균형, A/B 테스트
  - **Latency-based**: 지연시간이 가장 낮은 곳으로
  - **Geolocation-based**: 사용자 위치 기반
- **단점**
  - DNS 조회 자체가 약간의 **지연**을 더한다(캐싱으로 완화). → [[2026-07-21-backend-latency-vs-throughput]]
  - 관리가 복잡하고 보통 정부·ISP·대기업이 운영.
  - **DDoS 표적**: DNS가 마비되면 IP를 직접 모르는 사용자는 사이트 접속 불가(2016 Dyn 공격으로 Twitter 등 마비).

## 기준 답변

기준 레포의 답변을 바탕으로 핵심만 재구성한다.

DNS는 `www.example.com` 같은 **도메인 이름을 IP 주소로 변환**한다.

DNS는 **계층적**이며, 최상위에 소수의 권한 있는 서버가 있다. 라우터나 ISP가 조회 시 어떤 DNS 서버에 접속할지 알려준다. 하위 DNS 서버들은 매핑을 **캐싱**하는데, 이는 전파 지연으로 인해 낡을 수 있다. 결과는 브라우저나 OS에도 **TTL**로 정해진 기간 동안 캐싱된다.

주요 레코드로 **A**(이름→IP), **CNAME**(이름→다른 이름), **NS**(도메인의 DNS 서버), **MX**(메일 서버)가 있다.

Route 53, CloudFlare 같은 관리형 DNS는 weighted round robin, latency-based, geolocation-based 등으로 트래픽을 라우팅할 수 있다.

**단점**으로는 조회로 인한 약간의 지연, 관리 복잡성, 그리고 DDoS 공격의 표적이 된다는 점이 있다.

## 내가 정리한 내용

**1. DNS란? 왜 계층적인가**

도메인 이름을 IP로 변환하는 시스템. 전 세계 도메인을 한 대가 감당할 수 없으니 위에서 아래로 **위임되는 구조**가 됐다. 즉 한 대가 모든 도메인을 알 필요 없이 **"나는 모르지만 저쪽이 안다"** 를 넘겨주는 구조다.

**2. 캐싱과 TTL, 그리고 그 문제**

캐싱은 매번 루트까지 물어보면 시간이 오래 걸리기 때문에 정보를 저장해두는 것이고, **TTL**은 그 저장된 정보를 유지하는 시간이다.

만약 서버의 IP가 바뀌었는데 TTL이 만료되지 않아 캐싱된 정보가 남아 있다면, 그 사용자는 **옛날 IP로 이동**하게 된다.

**3. DNS의 위험(단점)**

DNS는 각 서비스를 이용하기 위한 통로 역할을 한다. 따라서 DNS 서비스업체가 마비되면 **다른 서비스들은 아무 이상이 없음에도** 마비된다. 그래서 이 위험을 예방하고자 2개의 DNS를 두는 **DNS 이중화**를 적용한다.

또한 DNS 조회 자체가 **약간의 지연**을 추가하며, 이는 캐싱으로 완화한다. 관리가 복잡해 보통 정부·ISP·대기업이 운영한다.

## 검토 결과

### 확인된 부분

- 계층 구조의 이유를 **"나는 모르지만 저쪽이 안다"** 로 표현. 위임(delegation)의 본질을 비전문가도 이해할 수 있게 압축한 좋은 문장.
- 캐싱의 목적(지연 감소)과 TTL의 역할, 그리고 stale IP 문제를 인과로 연결함.
- Q1에서 원인(TTL 만료 전 캐시)과 대책(사전 TTL 단축)을 모두 정확히 제시.
- Q2에서 **"우리 서비스는 아무 문제가 없음"** 을 짚음. 직렬 의존의 핵심 — 서버는 멀쩡한데 사용자 입장에선 100% 다운 — 을 정확히 파악.
- 위험 → 결과 → **대책(DNS 이중화)** 까지 스스로 완결.

### 보강 포인트

- 단점 3종 중 **"조회 지연"** 이 초기 답변에서 누락 → 추가함. 2번과 이어짐: **캐싱은 이 지연을 줄이려 존재하고, 그 대가로 stale 문제를 낳는다.**
- **서버 이전 시 TTL 조정 실무 순서** (Q1 심화)
  1. 이전 며칠 전 → TTL을 3600 → 60초로 낮춤
  2. **낮춘 TTL이 전파될 때까지 기다림** (기존 TTL만큼)
  3. IP 변경 → 60초면 대부분 전환
  4. 안정 후 TTL 복구 (짧은 TTL은 조회가 잦아져 부하·지연 증가)
  - 함정: 2번을 놓치면 낮춘 TTL 자체가 아직 안 퍼져 효과가 없다. **"TTL 변경도 TTL의 지배를 받는다."**
- **직렬 의존이 천장을 결정한다 (Q2 심화)**

  ```text
  우리 인프라  99.99%  (열심히 만든 것)
  DNS 업체     99.9%   (남의 것)
  ─────────────────────────
  실제 가용성  99.89%  ← DNS가 천장을 결정
  ```

  내 것을 아무리 강화해도 직렬로 엮인 남의 것이 상한선이다. → [[2026-07-25-backend-availability-patterns]]
- **DNS 이중화 = secondary DNS.** NS 레코드에 복수 제공업체를 등록해 병렬화한다.
  ```text
  before: 도메인 → [Route 53]           ← 하나 죽으면 끝 (직렬)
  after:  도메인 → [Route 53] + [NS1]   ← 하나 죽어도 응답 (병렬)
  ```
  2016 Dyn DDoS 공격 당시 Dyn 하나만 쓴 Twitter·Netflix·GitHub는 마비됐고, 두 업체를 쓴 곳은 살아남았다.
  - **교훈: 내가 통제할 수 없는 직렬 의존을 찾아, 그것마저 병렬화하라.**

### 이전 학습과의 연결

- **DNS는 전형적인 AP 시스템.** 캐시의 옛 IP = stale data, TTL 만료 후 수렴 = 최종 일관성. 최신성을 조금 포기하고 속도·가용성을 얻는다. → [[2026-07-22-backend-availability-vs-consistency]]
- **레코드 4종 중 A와 CNAME 구분**이 면접 단골. A는 최종 목적지(IP)를 직접 가리키고, CNAME은 "저 이름한테 다시 물어봐"로 넘긴다.
- **DNS는 부하 분산 도구이기도 하다.** Weighted round robin(점검 서버 제외, A/B 테스트), Latency-based, Geolocation-based 라우팅.

