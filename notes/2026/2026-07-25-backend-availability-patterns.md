---
date: 2026-07-25
track: backend
area: Backend & System Design
topic: 가용성 패턴 (Fail-over, Replication)
source_repository: donnemartin/system-design-primer
source_file: README.md
status: completed
---

# 고가용성을 위한 패턴: Fail-over와 Replication

## 출처

- 기준 레포: `donnemartin/system-design-primer`
- 원본 파일: `README.md` — `## Availability patterns` 섹션
- 영역: Backend / System Design
- 이전 학습: [[2026-07-22-backend-availability-vs-consistency]]

## 질문

> **고가용성(high availability)을 확보하는 패턴에는 무엇이 있는가? Fail-over와 Replication을 설명하라.**
>
> 원문: *Availability patterns — fail-over and replication*

## 핵심 개념

질문에 답하기 위해 필요한 핵심 개념을 정리한다.

- **가용성을 높이는 두 축**: **Fail-over(장애 조치)** 와 **Replication(복제)**. 상호 보완적이다.

### Fail-over (장애 조치)

- **Active-Passive (= master-slave)**
  - Active 서버만 트래픽을 처리하고, Passive는 대기(standby).
  - 둘 사이에 **heartbeat**(생존 신호)를 주고받다가, 신호가 끊기면 Passive가 Active의 IP를 넘겨받아 서비스 재개.
  - 다운타임 길이는 대기 방식에 따라 다름: **hot standby**(이미 켜져 대기, 빠름) vs **cold standby**(꺼져 있다 부팅, 느림).
- **Active-Active (= master-master)**
  - 두 서버가 **모두** 트래픽을 처리하며 부하를 분산.
  - 외부용이면 DNS가 두 서버의 공인 IP를 알아야 하고, 내부용이면 앱 로직이 두 서버를 알아야 함.
- **Fail-over의 단점**
  - 하드웨어와 복잡도가 늘어남.
  - Active가 죽기 직전 쓴 데이터가 Passive로 **복제되기 전이라면 유실** 위험.

### Replication (복제)

- **Master-Slave / Master-Master** 복제. (Database 섹션에서 더 자세히 다룸 — 다음 학습 후보)
- 데이터를 여러 노드에 복사해 한 노드가 죽어도 서비스가 지속되도록 함.

### Availability in numbers (가용성 수치)

- 가용성은 보통 **가동시간 %** 로 표현하며 "9의 개수"로 부른다.
  - **99.9% (three 9s)**: 연 약 8시간 46분 다운 허용
  - **99.99% (four 9s)**: 연 약 52분 다운 허용
- **직렬 vs 병렬** — 여러 컴포넌트로 구성된 서비스의 전체 가용성
  - **직렬(sequence)**: `전체 = A × B`. 곱하므로 **낮아진다.** (99.9% × 99.9% = 99.8%)
  - **병렬(parallel)**: `전체 = 1 − (1−A) × (1−B)`. **높아진다.** (99.9% 두 개 병렬 = 99.9999%)
  - 핵심 직관: 의존이 직렬로 쌓이면 약해지고, 이중화(병렬)하면 강해진다.

### 이전 학습과의 연결

- 어제 CAP에서 배운 **가용성(A)** 을 실제로 어떻게 확보하는지가 오늘 주제. → [[2026-07-22-backend-availability-vs-consistency]]
- Active-Passive의 데이터 유실 위험은 CAP의 "복제 지연" 문제와 같은 뿌리. 동기 복제로 막으려 하면 지연시간·가용성을 희생 → [[2026-07-21-backend-latency-vs-throughput]]

## 기준 답변

기준 레포의 답변을 바탕으로 핵심만 재구성한다.

고가용성을 지원하는 상호 보완적인 두 패턴은 **fail-over**와 **replication**이다.

**Fail-over**
- **Active-passive**: active와 passive(standby) 서버 사이에 heartbeat를 주고받는다. heartbeat가 끊기면 passive가 active의 IP를 넘겨받아 서비스를 재개한다. 다운타임은 passive가 hot standby냐 cold standby냐에 따라 달라진다. master-slave failover라고도 한다.
- **Active-active**: 두 서버가 모두 트래픽을 처리하며 부하를 나눈다. master-master failover라고도 한다.
- 단점: 하드웨어와 복잡도가 늘고, active가 죽기 전 새로 쓴 데이터가 복제되지 못하면 유실될 수 있다.

**Replication**
- master-slave 및 master-master 복제로 데이터를 여러 노드에 유지한다.

**가용성 수치**는 9의 개수로 표현하며(99.99% = four 9s), 컴포넌트가 직렬로 놓이면 전체 가용성이 낮아지고(곱셈), 병렬로 놓이면 높아진다.

## 내가 정리한 내용

**1. 고가용성을 위한 두 패턴**

- **Fail-over**: Active 서버가 죽었을 때 예비 서버로 갈아타는 것.
- **Replication**: 데이터가 유실되기 전에 미리 복제해놓는 것.
- 둘은 짝꿍이다. 갈아탈 서버에 최신 데이터가 있어야 하므로 Replication이 Fail-over를 받쳐준다.

**2. Active-Passive vs Active-Active**

- **Active-Passive**: Active만 트래픽을 처리하고 Passive는 대기한다. Active가 죽으면 heartbeat 끊김을 감지해 Passive가 IP를 넘겨받아 승격한다. 이때 대기 서버를 켜두면(hot) 전환이 빠르고, 꺼두면(cold) 비용은 싸지만 재가동에 시간이 걸린다.
- **Active-Active**: 두 서버가 모두 트래픽을 처리하며 부하를 나눈다. 한쪽이 죽으면 남은 쪽이 전부 감당한다. 자원 활용도가 높지만, 트래픽을 양쪽으로 분배하는 구성(DNS·로직)이 더 복잡하다.

**3. 직렬 vs 병렬 가용성**

직렬로 구성하면 가용성이 점점 떨어지고(곱셈), 병렬로 구성하면 점점 증가한다(이중화).

## 검토 결과

### 확인된 부분

- Fail-over와 Replication의 역할, 그리고 **둘의 인과 관계**("유실되기 전에 복제")를 정확히 짚음.
- 직렬↓ / 병렬↑ 방향을 정확히 이해. Q2에서 세 서비스 직렬 연결의 가용성 하락을 정확히 진단.
- Q1에서 cold standby의 장점(저비용)과 대가(재가동 지연 + 데이터 유실 가능)를 정확히 파악.

### 보강 포인트

- **"누가 일하나"(Active-Passive/Active) 와 "언제 켜나"(hot/cold)는 별개의 축이다.** (초기 답변에서 두 축을 하나로 합침 → 교정)

  ```
  Active-Passive ┬─ hot standby  (켜서 대기, 빠름·비쌈)
                 └─ cold standby (꺼서 대기, 느림·쌈)
  Active-Active     (예비 개념 없음, 둘 다 일함)
  ```

  - cold/hot은 **Active-Passive 안에서** 갈린다. Active-Active엔 "대기 서버" 자체가 없다(둘 다 트래픽 처리).
  - 따라서 "Active-Active = 항상 대기"는 틀림. Active-Active는 대기가 아니라 **둘 다 실제로 일하는** 것.
- **데이터 유실은 Active-Passive/Active로 갈리지 않는다.** 복제가 **동기냐 비동기냐**로 갈린다. Active-Passive라도 동기 복제면 유실이 없고, 비동기면 위험이 있다.
- **직렬 사슬의 위험(Q2)**: `99.9% × 99.9% × 99.9% ≈ 99.7%`. 각각 three 9s인데 직렬로 묶으면 전체가 추락한다. 컴포넌트가 많을수록 심해진다.
- **개선은 두 방향** — ② 를 ① 보다 먼저 고려하는 게 실무적.
  1. 각 단계를 **병렬 이중화**해 각 고리를 강하게.
  2. **직렬 사슬 자체를 짧게** — 안 거쳐도 되는 의존을 끊는다. 예: 결제 API는 모든 요청이 아니라 결제 시에만 타도록 경로 분리.
  - 원칙: **강하게 만들기 전에, 덜 의존하게 만들어라.**
  - 외부 의존(결제 API 등)은 우리가 이중화 못 하므로 **비동기로 빼거나 격리**한다(주문 먼저 받고 결제는 큐로). → 어제 AP의 "일단 응답, 나중에 처리" 감각.

### 이전 학습과의 연결

- **cold vs hot = 비용 ↔ 다운타임 트레이드오프.** 무엇을 고르냐는 "이 서비스가 몇 분 꺼져도 되는가" = **업무가 결정**. 트레이드오프 4연타의 연장. → [[2026-07-22-backend-availability-vs-consistency]]
- Active-Passive의 데이터 유실 위험은 CAP의 복제 지연과 같은 뿌리. 동기 복제로 막으면 지연시간·가용성을 희생. → [[2026-07-21-backend-latency-vs-throughput]]

