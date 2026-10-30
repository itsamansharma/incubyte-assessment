# AI use and review notes

## How AI was used

Codex was used as an engineering assistant during this assessment to help read and summarize the requirements, plan work in small increments, review existing code, implement and refactor application code, expand backend and frontend tests, diagnose failures, and check the local and deployed application. The developer directed the scope and reviewed changes through repository inspection, automated checks, and live read-only smoke checks.

AI output was treated as a proposal to verify. The Rails suite, frontend tests, lint, TypeScript check, production build, and performance script provide the recorded checks for this repository. The results and limits of the performance measurements are in `PERFORMANCE.md`.

## Representative instructions

These excerpts are from the working conversation and illustrate the instructions that shaped the process:

> “start implementing in small setps and only one step at a time, do let me know which step is being processed and whats goal of each step before starting it”

> “before going further, please check the existing code and make relevant changes.”

> “now add the test cases in backend, do not leave any test cases unwritten, try to cover most of the cases”

> “now first do the code review, and make necessary changes, remove the garbage/unnecessary code, check if there is some repeting code (remove the repeting code and write the reusable code), optimise the code wherever needed.”

## Review trail

The repository history records focused increments from the initial requirements and implementation through API/UI cleanup, backend test coverage, and frontend test coverage. See `git log --oneline` for the commit sequence. The latest test-focused commit is `Add frontend tests for payroll screens`.
