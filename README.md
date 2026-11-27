# answer-desk

고객 문의에 FAQ 근거로 답하거나, 근거가 부족하면 운영자에게 넘기는 RAG 답변 서비스입니다.

- 상태: Rails 앱 골격만 있습니다(문의 처리·검색·콘솔은 아직 없음). 결정은 [docs/adr/](docs/adr/)에 있습니다.
- 구성: Rails 8, PostgreSQL, Solid Queue(큐 테이블도 같은 PostgreSQL), 로컬 LLM(어댑터 뒤). pgvector는 FAQ 검색을 만들 때 붙입니다.

## 개발 환경

명령은 [AGENTS.md](AGENTS.md)의 setup, check, test, build와 같습니다. `python3 -I .baseline/baseline.py run test`처럼 부릅니다(Ruby는 `.mise.toml`이 고정하고 mise가 설치합니다).

PostgreSQL 서버(`initdb`, `pg_ctl`)는 mise가 아니라 시스템에 설치되어 있어야 합니다. `bin/pg start`가 프로젝트 안(`tmp/pg`)에 시험용 서버를 소켓으로만 띄웁니다. 다른 서버를 쓰려면 `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`를 정합니다.
