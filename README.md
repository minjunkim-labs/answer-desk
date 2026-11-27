# answer-desk

고객 문의에 FAQ 근거로 답하거나, 근거가 부족하면 운영자에게 넘기는 RAG 답변 서비스입니다.

- 상태: 설계 단계. 결정은 [docs/adr/](docs/adr/)에 있습니다. Rails 앱 골격(PostgreSQL, Solid Queue)만 있고 기능은 아직 없습니다.
- 계획한 구성: Rails, PostgreSQL(pgvector), Solid Queue, 로컬 LLM(어댑터 뒤)

## 개발 환경

- 툴체인: [mise](https://mise.jdx.dev)가 `.mise.toml`의 Ruby를 설치한다.
- PostgreSQL이 떠 있어야 한다. 연결은 로컬 소켓이 기본이고 `PGHOST`/`PGUSER`/`PGPASSWORD`로 바꾼다. `DATABASE_URL`은 개발과 시험이 같은 데이터베이스를 쓰게 되므로 쓰지 않는다.
- 시험은 migration을 처음부터 돌려 `db/schema.rb`와 같은지 확인한 뒤 시작한다. migration을 바꾸면 `db/schema.rb`도 함께 커밋한다.
- 명령은 [AGENTS.md](AGENTS.md)의 「명령」 칸과 같다: `python3 -I .baseline/baseline.py run setup|check|test`.
