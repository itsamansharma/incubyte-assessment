/Users/aman/.rvm/scripts/rvm:29: operation not permitted: ps
# API reference

This document describes the Rails API in this repository. Examples use the local API base URL `http://localhost:3000`; replace it with the deployed API URL when needed. All API routes are under `/api/v1` and return JSON.

The API does not require authentication. It is intended for the assessment demo with synthetic data; do not use real employee or salary information on a publicly accessible deployment.

## Health check

### `GET /up`

Returns HTTP `200` when Rails is running. This is a health endpoint, not a JSON API response. The root path `/` is not defined.

## Employees

### `GET /api/v1/employees`

Returns a paginated employee list. All query parameters are optional.

| Parameter | Description |
| --- | --- |
| `page` | One-based page number; defaults to `1` and must be a positive integer. |
| `per_page` | Page size; defaults to `25` and is capped at `100`. |
| `q` | Search employee code, first name, last name, or email; up to 100 characters. |
| `country_code` | Two-letter country code, case-insensitive. |
| `department` | Department name or department code, case-insensitive. |
| `currency` | Three-letter currency code, case-insensitive. |
| `min_salary_usd_cents` | Minimum active salary converted to USD, in cents. |
| `max_salary_usd_cents` | Maximum active salary converted to USD, in cents. |
| `sort` | `name` (default), `employee_code`, `country_code`, `department`, `salary`, or `date_of_joining`. |
| `direction` | `asc` (default) or `desc`. |

Example request:

```http
GET /api/v1/employees?q=ACM&country_code=IN&department=ENG&currency=INR&min_salary_usd_cents=500000&sort=salary&direction=desc&page=1&per_page=25
```

Example response (`200 OK`):

```json
{
  "employees": [
    {
      "id": 1,
      "employee_code": "ACM-00001",
      "first_name": "Aarav",
      "last_name": "Sharma",
      "email": "acm-00001@example.com",
      "country_code": "IN",
      "department": "Engineering",
      "job_title": "Senior ENG",
      "job_level": "Senior",
      "date_of_joining": "2022-04-15",
      "compensation": {
        "amount_cents": 10000000,
        "currency": "INR",
        "amount_usd_cents": 120000,
        "effective_date": "2022-04-15"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 25,
    "total_count": 1,
    "total_pages": 1
  }
}
```

`compensation` is `null` if the employee has no active compensation. Salary values are integer minor currency units (cents/paise); USD filter and aggregate values are USD cents.

Invalid query values return `400 Bad Request`:

```json
{ "error": "direction must be asc or desc" }
```

### `GET /api/v1/employees/:id`

Returns one employee, current compensation, and compensation history (newest first).

Example response (`200 OK`):

```json
{
  "id": 1,
  "employee_code": "ACM-00001",
  "first_name": "Aarav",
  "last_name": "Sharma",
  "email": "acm-00001@example.com",
  "country_code": "IN",
  "department": { "name": "Engineering", "code": "ENG" },
  "job_title": "Senior ENG",
  "job_level": "Senior",
  "date_of_joining": "2022-04-15",
  "current_compensation": {
    "id": 1,
    "amount_cents": 10000000,
    "currency": "INR",
    "amount_usd_cents": 120000,
    "effective_date": "2022-04-15",
    "change_reason": "Initial Hire",
    "is_active": true
  },
  "compensation_history": [
    {
      "id": 1,
      "amount_cents": 10000000,
      "currency": "INR",
      "amount_usd_cents": 120000,
      "effective_date": "2022-04-15",
      "change_reason": "Initial Hire",
      "is_active": true
    }
  ]
}
```

An unknown or malformed ID returns `404 Not Found`:

```json
{ "error": "Employee not found" }
```

## Dashboard

### `GET /api/v1/dashboard/overview`

Returns employee headcount and active-compensation totals, in USD cents.

```json
{
  "headcount": 10000,
  "annual_payroll_usd_cents": 98234500000,
  "average_annual_salary_usd_cents": 9823450,
  "median_annual_salary_usd_cents": 9500000
}
```

Average and median are `null` when there are no active compensation records.

### `GET /api/v1/dashboard/breakdown`

Returns active-compensation totals grouped by department and country. Each department item has a `department` key; each country item has a `country_code` key.

```json
{
  "departments": [
    {
      "department": "Engineering",
      "headcount": 3000,
      "annual_payroll_usd_cents": 29470350000,
      "average_annual_salary_usd_cents": 9823450,
      "median_annual_salary_usd_cents": 9500000
    }
  ],
  "countries": [
    {
      "country_code": "IN",
      "headcount": 2000,
      "annual_payroll_usd_cents": 6880000000,
      "average_annual_salary_usd_cents": 3440000,
      "median_annual_salary_usd_cents": 3400000
    }
  ]
}
```

Employees without active compensation are included in group headcounts, but not in salary metrics. Averages and medians are `null` for groups with no active compensation.

### `GET /api/v1/dashboard/pay_bands`

Returns salary percentiles grouped by department and job level. Salary values are USD cents.

```json
{
  "groups": [
    {
      "department": "Engineering",
      "job_level": "Senior",
      "headcount": 750,
      "p25_annual_salary_usd_cents": 8500000,
      "median_annual_salary_usd_cents": 10500000,
      "p75_annual_salary_usd_cents": 13000000
    }
  ]
}
```

## Change compensation

### `POST /api/v1/employees/:employee_id/compensations`

Creates an active compensation record and marks the previous active record inactive. Send JSON with integer minor-unit salary, a supported currency code, an ISO date, and a reason of 1–100 characters.

Example request:

```http
POST /api/v1/employees/1/compensations
Content-Type: application/json
```

```json
{
  "compensation": {
    "amount_cents": 120000000,
    "currency": "INR",
    "effective_date": "2025-06-01",
    "change_reason": "Promotion"
  }
}
```

Example response (`201 Created`):

```json
{
  "employee_id": 1,
  "compensation": {
    "id": 2,
    "amount_cents": 120000000,
    "currency": "INR",
    "amount_usd_cents": 1440000,
    "effective_date": "2025-06-01",
    "change_reason": "Promotion",
    "is_active": true
  }
}
```

Possible errors:

- `404 Not Found` if the employee ID is unknown or malformed.
- `422 Unprocessable Entity` for missing or invalid fields, unsupported currency, or model validation errors.

Example validation response:

```json
{ "error": "unsupported currency" }
```

Some model validation failures use an `errors` array instead:

```json
{ "errors": ["Change reason can't be blank"] }
```

## CORS

Browser requests are allowed from the single origin configured by `FRONTEND_ORIGIN`. For a local frontend, the default is `http://localhost:3001`. If the frontend uses another origin, set `FRONTEND_ORIGIN` to that exact origin on the Rails service.
