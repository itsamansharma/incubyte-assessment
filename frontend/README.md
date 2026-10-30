# ACME Payroll Dashboard

Next.js frontend for the ACME global salary management application. The overview page reads live metrics from the Rails API.

## Run locally

1. Start PostgreSQL and the Rails API on port `3000` from the repository root.
2. Copy `.env.example` to `.env.local` if the API runs at a different address.
3. Install packages and start the frontend:

   ```sh
   pnpm install
   pnpm dev
   ```

Open [http://localhost:3001](http://localhost:3001). The overview uses the server-side `RAILS_API_URL`; employee search and profiles use `NEXT_PUBLIC_RAILS_API_URL` in the browser. Both default to `http://127.0.0.1:3000` and should point to the same Rails API.

## Available commands

- `pnpm dev` starts the development server on port `3001`.
- `pnpm lint` runs ESLint.
- `pnpm build` creates a production build.
- `pnpm start` serves the production build on port `3001`.

In hosted environments, `pnpm start` uses the platform-provided `PORT` and listens on all network interfaces.
