# answer-desk

고객 문의에 FAQ 근거로 답하거나, 근거가 부족하면 운영자에게 넘기는 RAG 답변 서비스입니다.

- 상태: 설계 단계. 결정은 [docs/adr/](docs/adr/)에 있습니다.
- 계획한 구성: Rails, PostgreSQL(pgvector), Solid Queue, 로컬 LLM(어댑터 뒤)
