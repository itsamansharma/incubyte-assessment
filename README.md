# ACME Global Salary Management

Rails 8.1 API for the Incubyte Ruby on Rails developer assessment. Product scope and trade-offs are in [PRD.md](PRD.md).

## Requirements

- Ruby 3.4.12
- PostgreSQL 15 or later
- Bundler

## Setup

1. Install the gems with `bundle install`.
2. Set `DATABASE_URL` if your local PostgreSQL connection differs from the defaults in `config/database.yml`.
3. Prepare the database with `bin/rails db:prepare`.
4. Start the API with `bin/rails server`.

The health endpoint is `GET /up`. API routes live under `/api/v1`.

## Frontend

The Next.js dashboard is in [`frontend/`](frontend/README.md). Start PostgreSQL and Rails on port `3000`, then run:

```sh
cd frontend
pnpm install
pnpm dev
```

Open [http://localhost:3001](http://localhost:3001). If Rails runs elsewhere, set both `RAILS_API_URL` and `NEXT_PUBLIC_RAILS_API_URL` in `frontend/.env.local` to the API base URL.
