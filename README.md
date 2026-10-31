# ACME Global Salary Management

Rails 8.1 API for the Incubyte Ruby on Rails developer assessment. Product scope and trade-offs are in [PRD.md](PRD.md).

## Requirements

- Ruby 3.4.12
- PostgreSQL 15 or later
- Bundler (version in `Gemfile.lock`)
- Node.js 20.9 or later
- pnpm 11.25.0

## Run locally

1. Install Ruby 3.4.12, PostgreSQL 15 or later, Node.js 20.9 or later, and pnpm 11.25.0. Start the PostgreSQL service.
2. From the repository root, install the Ruby dependencies and prepare the database:

   ```sh
   bundle install
   bin/rails db:prepare
   bin/rails db:seed
   ```

   The seed command creates the synthetic departments, exchange rates, and sample employees. If your PostgreSQL connection differs from the local defaults in `config/database.yml`, set `DATABASE_URL` in your shell before running the Rails commands.
3. Start the Rails API in one terminal:

   ```sh
   bin/rails server -p 3000
   ```

4. In a second terminal, configure and start the frontend:

   ```sh
   cd frontend
   cp .env.example .env.local
   pnpm install --frozen-lockfile
   pnpm dev
   ```

   The example environment file points both frontend API settings to `http://127.0.0.1:3000`; update them if Rails runs at another address. The dashboard is available at [http://localhost:3001](http://localhost:3001).

The API health endpoint is `GET http://localhost:3000/up`. The API root `/` does not serve a page. See the [API reference](docs/api.md) for endpoints, parameters, and request/response examples.

## Frontend

The Next.js dashboard source and frontend-specific notes are in [`frontend/`](frontend/README.md). Start PostgreSQL and the Rails API before starting the frontend.

## Deployment

The repository includes a Render Blueprint in [`render.yaml`](render.yaml) for the Rails API, Next.js dashboard, and PostgreSQL database. To deploy, connect the private GitHub repository to Render and create a Blueprint from the repository. The Blueprint currently uses free instances for a demo: web services sleep after 15 minutes of inactivity, and the free PostgreSQL database expires after 30 days. See [Render free-tier limits](https://render.com/docs/free) before deploying. Keep this demo dataset synthetic: the assessment API does not include authentication.

## Engineering artifacts

- [Architecture notes](docs/architecture.md) describe the system boundaries, data model, and query approach.
- [AI use and review notes](docs/ai-use.md) summarize the AI-assisted workflow and representative instructions.
- [Performance baseline](PERFORMANCE.md) records local API measurements and how to reproduce them.
