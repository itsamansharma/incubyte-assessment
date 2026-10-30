/Users/aman/.rvm/scripts/rvm:29: operation not permitted: ps
# ACME Global Salary Management — Phase 1 PRD

**Version:** 1.0 · **Persona:** Global HR Manager · **Scale:** 10,000 employees in the US, UK, India, Germany, and Singapore

## Problem and goal

ACME's compensation data is fragmented across local spreadsheets. A Global HR Manager needs one dependable place to review worldwide payroll, compare pay across departments and countries, find employee records, and record salary changes. The MVP will make those workflows responsive at 10,000 employees and provide consistent USD reporting for cross-country analysis.

## Goals and in-scope features

- Provide a global overview of headcount, annual payroll in USD, and average and median annual salary.
- Break down headcount, payroll, and compensation statistics by department and country; show pay-band percentiles (P25, median, P75) by department and job level.
- Provide a searchable employee directory with server-side pagination, sorting, and filters for country, department, currency, and salary range.
- Show an employee's current compensation and salary-change history. Allow an HR Manager to record a new salary with an effective date and reason, preserving an auditable history.
- Store local compensation in integer cents and its USD equivalent using fixed, seeded exchange rates so reporting is reproducible.
- Seed 10,000 realistic employee and compensation records across the five countries, departments, job levels, and supported currencies.

## Success measures

- HR workflows work end to end in a deployed, responsive web application.
- Directory queries paginate and filter on the server; analytical summaries aggregate in the database rather than loading all employee records into application memory.
- Salary updates are atomic and preserve the previous compensation record and change rationale.
- Core behavior has deterministic automated tests; the repository shows incremental development through focused commits.

## Deliberate omissions and trade-offs

- No country-specific tax calculations or bank/payment execution: these belong to jurisdictional payroll and treasury systems, not compensation planning.
- No multi-tenant access model, complex role-based permissions, or SSO: Phase 1 serves one HR Manager persona and one organization.
- No live FX feed: fixed reference rates keep compensation comparisons predictable and auditable; rates can be revised deliberately as data.
- No job application, benefits, or full HRIS workflows: they do not support the core compensation questions in this assessment.

## Initial technical direction

Build a Ruby on Rails JSON API backed by PostgreSQL and a React/Next.js dashboard. Persist monetary values as integer cents, retain a USD reporting amount for efficient indexed aggregation, and keep pagination, filtering, and analytics in the API/database. Validate query performance against the seeded dataset and document measured results rather than assuming a latency target.

## Assessment deliverables

Commit this PRD before implementation. Deliver the working application, schema and realistic seed data, automated tests, a live deployment, a short walkthrough video, and concise engineering/AI-use artifacts such as architecture notes and verified prompt records. Submit the repository link by replying to the assessment email.
