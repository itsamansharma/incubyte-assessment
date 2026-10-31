# AI-assisted engineering workflow

## Purpose and ownership

Codex was used as an engineering assistant to accelerate requirement analysis, code navigation, implementation, review, test design, and documentation. It supplied drafts and suggestions; the developer retained responsibility for scope, technical decisions, accepting changes, and the final submission.

The work was kept aligned with the assessment and the existing application. Changes were approached incrementally, with the expected behavior and the relevant part of the codebase established before implementation. AI-generated changes were reviewed in context rather than accepted as authoritative output.

## How the work was directed

Instructions emphasized concrete outcomes and constraints:

- **Start from the requirements and existing code.** Understand the assignment, inspect the current implementation, and identify functional gaps before proposing changes.
- **Keep changes scoped.** Work on one defined improvement at a time and avoid unrelated rewrites.
- **Preserve behavior.** When reviewing or refactoring, remove duplication and unnecessary code only where the existing application behavior can be retained.
- **Verify changes.** Add or update relevant tests, use the project's existing checks, and investigate failures rather than masking them.
- **Treat deployment as an integration check.** Confirm the deployed revision and exercise key read paths after a change, without using production-like data for write experiments.

## Representative instruction patterns

The examples below are editorial summaries of the instructions used during the work, not verbatim quotations.

### Requirement analysis

> Read the assessment and the existing implementation first. Turn the requirements into a concise list of expected behavior, identify any functional conflicts, and call out uncertainty before changing code.

### Focused implementation

> Make the employee directory support full-name search, usable pagination, and dropdown filters. Prevent invalid salary input with clear user feedback, and align the search icon with its field. Keep the change focused on these behaviors.

### Review and refactoring

> Review the Rails and frontend code for defects, duplicated logic, and unnecessary complexity. Refactor repeated behavior into reusable code where appropriate, preserve the product behavior, and explain the evidence used to validate the result.

### Test design

> Inspect the backend behavior and its edge cases, then add tests for the API's expected and invalid-input paths. Prefer tests that verify observable behavior and keep them consistent with the existing test conventions.

## Review and verification

AI suggestions were assessed against the assignment, existing code conventions, API/UI behavior, and the affected tests. Automated checks and manual application checks were used during development; the repository history records the incremental implementation. The performance measurements and reproduction steps are documented in [`../PERFORMANCE.md`](../PERFORMANCE.md).

Representative practices included:

- testing expected behavior as well as boundary and invalid-input cases;
- checking that employee search, filters, sorting, and pagination still work after related changes;
- checking the deployed frontend and API after the merge;
- keeping demo records synthetic and avoiding authentication or other features outside the assessment scope.

This note describes the AI-assisted process and its controls. It is not a claim that an AI system independently verified or guaranteed the correctness of the application.
