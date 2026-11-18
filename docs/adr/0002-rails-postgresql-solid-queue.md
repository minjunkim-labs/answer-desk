# 0002. Rails, PostgreSQL(pgvector), Solid Queue로 만든다

- 상태: 제안
- 날짜: 2026-11-18

## 맥락

이 서비스는 웹 애플리케이션이다. 운영자 콘솔(로그인, 넘겨받은 문의 목록, FAQ와 평가셋 관리)과 접수 API, 비동기 워커가 함께 있다. 기대 부하는 로컬 한 대에서 초당 수십 건의 접수다.

기술은 두 기준으로 고른다. 작성자가 처음부터 정한 방향(웹 애플리케이션은 Rails), 그리고 이 프로젝트에 맞고 일반적인 모범 사례인가.

## 결정

1. 웹 애플리케이션과 API는 Rails로 만든다.
2. 데이터와 벡터 검색은 PostgreSQL과 pgvector 하나로 한다.
3. 작업 큐는 Solid Queue(Rails 8 기본값)로 한다. 운영할 DB를 하나로 두려고 큐 테이블도 앱과 같은 PostgreSQL에 둔다(Solid Queue README의 "Single database configuration"). Solid Queue 설치 기본값은 큐 전용 DB다.
4. 문의가 유실되지 않는 근거는 큐가 아니라 문의 행의 상태다. 큐와 앱 데이터가 한 트랜잭션에 묶이는 동작에는 기대지 않는다. Solid Queue README가 이 동작에 기대는 설계를 경고하고, 큐를 다른 DB나 다른 백엔드로 옮기면 동작이 바뀌기 때문이다.
5. 문의는 상태(`received`, `processing`, `answered`, `handed_off`), 처리 기한(`lease_expires_at`), 처리 차수(`attempt`)를 가진다. `answered`와 `handed_off`는 끝난 상태다. 끝난 상태의 행은 다시 바뀌지 않는다.
6. 모든 상태 전이는 아래 표의 조건부 갱신 하나로 한다. 갱신된 행이 0개면 그 전이는 일어나지 않은 것이고, 하던 일(가져가기, 결과 쓰기)을 버린다.

| 전이 | 누가 | 조건(WHERE) | 바꾸는 값 |
| --- | --- | --- | --- |
| 접수 | 접수 API | 새 행 | `received`, `attempt = 0`, 짧은 처리 기한 `T_recv` |
| 가져가기 | 워커 | `status = received` 이고 `attempt = 작업에 실린 차수` | `processing`, 처리 기한 `T_proc` |
| 결과 쓰기 | 워커 | `status = processing` 이고 `attempt = 가져간 차수` | `answered` 또는 `handed_off`, 결과 |
| 재등록 | 반복 작업 | `status IN (received, processing)` 이고 처리 기한 지남 이고 `attempt < 한도` | `received`, `attempt + 1`, 짧은 처리 기한 `T_recv` |
| 한도 초과 넘김 | 반복 작업 | `status IN (received, processing)` 이고 처리 기한 지남 이고 `attempt >= 한도` | `handed_off` |

7. 큐에 넣는 일은 접수와 재등록의 갱신이 커밋된 뒤에 한다(`enqueue_after_transaction_commit`). 작업에는 그때의 `attempt`를 싣는다. 큐 넣기가 실패해도 행은 `received`와 짧은 처리 기한 `T_recv`를 가지므로, 다음 반복 작업이 다시 찾는다.
8. 같은 문의에 작업이 둘 이상 생겨도(재등록, 큐의 재시도) 차수가 맞는 작업 하나만 가져가고, 결과도 그 작업만 쓴다. 끝난 문의를 다시 여는 전이는 없다.

## 버린 대안

- Rust(axum) API: 성능 이야기는 강하지만 운영자 콘솔을 따로 만들어야 한다. 이 부하에서는 Rails로 충분하다.
- Sidekiq + Redis: 빠르고 널리 쓰이지만 Redis를 하나 더 운영해야 한다.
- 큐와 앱 데이터의 한 트랜잭션에 기대기: 위 4번의 이유로 버린다.
- RabbitMQ, Kafka: 여러 서비스 사이에 메시지를 흘릴 때 맞다. 서비스 하나의 작업 큐로는 과하다.
- 별도 벡터 DB(Chroma 등): FAQ 규모에서는 pgvector로 충분하고, 저장소가 하나 줄어든다.

## 결과

- 운영할 저장소는 PostgreSQL 하나다.
- 큐 길이와 대기 시간을 DB에서 바로 볼 수 있다. 포화(Saturation) 지표로 쓴다(0004).
- 큐 처리량이 PostgreSQL 한계에 닿으면 큐를 바꾸는 결정을 새 ADR로 남긴다. 유실 방지는 문의 상태에 있으므로 큐를 바꿔도 이 보장은 그대로다.
- 워커가 처리 중에 죽으면, 재처리가 시작되기까지 최대 `T_proc` + 반복 주기 + 큐 대기가 걸린다. 큐 넣기가 실패하면 `T_recv` + 반복 주기가 더해진다. 0004의 "60초 안 재처리 시작"을 지키도록 `T_proc`, `T_recv`, 반복 주기를 큐 대기를 잰 뒤 정한다. 목표는 강제 종료 시험으로 끝에서 끝까지 잰다.
- `T_recv`는 평소 큐 대기보다 길어야 한다. 짧으면 아직 기다리는 정상 작업이 재등록되어 차수가 바뀌고, 그 작업은 버려진다. 큐 대기 p99를 잰 뒤 정한다.
- 표의 전이마다 구현 PR에서 테스트를 둔다. 특히 늦게 끝난 워커, 같은 문의의 중복 작업, 큐 넣기 실패를 시험한다.
