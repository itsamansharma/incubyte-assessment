# Local API performance baseline

This is a reproducible local baseline for the seeded development database. It measures HTTP response time from the benchmark process, including the loopback request, Rails/Puma handling, PostgreSQL query, and JSON serialization. It is a single-user development measurement, not a production capacity test or an SLA.

## Environment and data

- Measured: 2026-10-30
- Runtime: Ruby 3.4.12, Rails 8.1.4, PostgreSQL 18.6 (Postgres.app)
- Architecture: macOS arm64
- Dataset: 10,000 employees, 10,000 active compensation records, 8 departments
- Server: local development Rails/Puma server, one request at a time
- Cache: three warm-up requests per endpoint, followed by 20 measured requests
- Percentile: nearest-rank p95; median is the midpoint of the sorted samples

## Results

| Endpoint | Median | p95 | Response body |
| --- | ---: | ---: | ---: |
| `GET /api/v1/dashboard/overview` | 6.04 ms | 6.95 ms | 141 bytes |
| `GET /api/v1/dashboard/breakdown` | 14.44 ms | 14.97 ms | 2,164 bytes |
| `GET /api/v1/dashboard/pay_bands` | 10.21 ms | 10.99 ms | 8,797 bytes |
| `GET /api/v1/employees?page=100&per_page=25` | 10.87 ms | 19.99 ms | 8,788 bytes |
| `GET /api/v1/employees?q=ACM-09999&per_page=25` | 23.20 ms | 23.86 ms | 442 bytes |

## Reproduce

Start PostgreSQL and the Rails development server, seed the database with `bin/rails db:seed`, then run:

```sh
ruby script/benchmark_api.rb
```

The script defaults to `http://127.0.0.1:3000`, three warm-ups, and 20 samples. Override the API base URL or sample counts with `API_BASE_URL`, `BENCHMARK_WARMUPS`, and `BENCHMARK_SAMPLES`.

The search endpoint uses a substring match across employee code, first name, last name, and email. Its timing is higher than the other endpoints in this local baseline; it should be profiled with `EXPLAIN (ANALYZE, BUFFERS)` before drawing conclusions about larger datasets or production load.
