"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import AppShell from "@/components/app-shell";

type Employee = {
  id: number;
  employee_code: string;
  first_name: string;
  last_name: string;
  email: string;
  country_code: string;
  department: string;
  job_title: string;
  job_level: string;
  date_of_joining: string;
  compensation: {
    amount_cents: number;
    currency: string;
    amount_usd_cents: number;
    effective_date: string;
  } | null;
};

type EmployeeResponse = {
  employees: Employee[];
  pagination: { page: number; per_page: number; total_count: number; total_pages: number };
};

const apiBaseUrl = (process.env.NEXT_PUBLIC_RAILS_API_URL ?? "http://127.0.0.1:3000").replace(/\/$/, "");

function formatSalary(employee: Employee): string {
  if (!employee.compensation) return "—";

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: employee.compensation.currency,
    maximumFractionDigits: 0,
  }).format(employee.compensation.amount_cents / 100);
}

function formatDate(date: string): string {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric", timeZone: "UTC" }).format(new Date(`${date}T00:00:00Z`));
}

export default function EmployeesPage() {
  const [query, setQuery] = useState("");
  const [search, setSearch] = useState("");
  const [country, setCountry] = useState("");
  const [department, setDepartment] = useState("");
  const [currency, setCurrency] = useState("");
  const [minimumSalary, setMinimumSalary] = useState("");
  const [maximumSalary, setMaximumSalary] = useState("");
  const [sort, setSort] = useState("name");
  const [direction, setDirection] = useState("asc");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<EmployeeResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const timer = window.setTimeout(() => setSearch(query.trim()), 250);
    return () => window.clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    const controller = new AbortController();
    const params = new URLSearchParams({ page: String(page), per_page: "25", sort, direction });
    if (search) params.set("q", search);
    if (country) params.set("country_code", country);
    if (department) params.set("department", department);
    if (currency) params.set("currency", currency);
    if (minimumSalary) params.set("min_salary_usd_cents", String(Math.round(Number(minimumSalary) * 100)));
    if (maximumSalary) params.set("max_salary_usd_cents", String(Math.round(Number(maximumSalary) * 100)));

    fetch(`${apiBaseUrl}/api/v1/employees?${params}`, { signal: controller.signal })
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error ?? `Request failed (${response.status})`);
        return body as EmployeeResponse;
      })
      .then(setData)
      .catch((requestError: unknown) => {
        if (requestError instanceof DOMException && requestError.name === "AbortError") return;
        setError(requestError instanceof Error ? requestError.message : "Could not load employees.");
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [search, country, department, currency, minimumSalary, maximumSalary, sort, direction, page]);

  function resetPage() {
    setPage(1);
    setLoading(true);
    setError("");
  }

  function goToPage(nextPage: number) {
    setPage(nextPage);
    setLoading(true);
    setError("");
  }

  const firstResult = data?.pagination.total_count ? (page - 1) * data.pagination.per_page + 1 : 0;
  const lastResult = Math.min(page * (data?.pagination.per_page ?? 25), data?.pagination.total_count ?? 0);

  return (
    <AppShell activePage="employees">
      <section className="content-wrap directory-wrap">
        <div className="page-heading directory-heading">
          <div>
            <p className="eyebrow">GLOBAL WORKFORCE</p>
            <h1>Employees</h1>
            <p className="page-subtitle">Search, filter, and explore your global team.</p>
          </div>
          <span className="employee-total">{data ? `${new Intl.NumberFormat("en-US").format(data.pagination.total_count)} employees` : "Employee directory"}</span>
        </div>

        <section className="directory-filters" aria-label="Employee filters">
          <label className="employee-search">
            <span aria-hidden="true">⌕</span>
            <input aria-label="Search employees" placeholder="Search name, email or ID..." value={query} onChange={(event) => { setQuery(event.target.value); resetPage(); }} />
          </label>
          <label className="filter-field"><span>Country</span><input placeholder="Any country" maxLength={2} value={country} onChange={(event) => { setCountry(event.target.value.toUpperCase()); resetPage(); }} /></label>
          <label className="filter-field"><span>Department</span><input placeholder="Any department" value={department} onChange={(event) => { setDepartment(event.target.value); resetPage(); }} /></label>
          <label className="filter-field currency-filter"><span>Currency</span><input placeholder="Any" maxLength={3} value={currency} onChange={(event) => { setCurrency(event.target.value.toUpperCase()); resetPage(); }} /></label>
          <label className="filter-field salary-filter"><span>Min annual salary (USD)</span><input inputMode="decimal" type="number" min="0" placeholder="No minimum" value={minimumSalary} onChange={(event) => { setMinimumSalary(event.target.value); resetPage(); }} /></label>
          <label className="filter-field salary-filter"><span>Max annual salary (USD)</span><input inputMode="decimal" type="number" min="0" placeholder="No maximum" value={maximumSalary} onChange={(event) => { setMaximumSalary(event.target.value); resetPage(); }} /></label>
        </section>

        <div className="directory-toolbar">
          <span>{loading ? "Updating results…" : `Showing ${firstResult}–${lastResult} of ${new Intl.NumberFormat("en-US").format(data?.pagination.total_count ?? 0)}`}</span>
          <div className="sort-controls">
            <label>Sort by <select value={sort} onChange={(event) => { setSort(event.target.value); resetPage(); }}>
              <option value="name">Name</option><option value="employee_code">Employee ID</option><option value="department">Department</option><option value="country_code">Country</option><option value="salary">Salary</option><option value="date_of_joining">Start date</option>
            </select></label>
            <button className="sort-direction" type="button" onClick={() => { setDirection(direction === "asc" ? "desc" : "asc"); resetPage(); }} aria-label={`Sort ${direction === "asc" ? "descending" : "ascending"}`}>{direction === "asc" ? "↑" : "↓"}</button>
          </div>
        </div>

        {error && <div className="api-error directory-error" role="alert"><span className="error-symbol">!</span><div><strong>Couldn’t load the employee directory</strong><p>{error}. Check that the Rails API is running and refresh this page.</p></div></div>}

        <div className="employee-table-wrap" aria-busy={loading}>
          <table className="employee-table">
            <thead><tr><th>EMPLOYEE</th><th>DEPARTMENT</th><th>LOCATION</th><th>JOB LEVEL</th><th>ANNUAL SALARY</th><th>START DATE</th></tr></thead>
            <tbody>
              {data?.employees.map((employee) => <tr key={employee.id}>
                <td><div className="employee-identity"><span className="employee-avatar">{employee.first_name[0]}{employee.last_name[0]}</span><span className="employee-identity-copy"><Link className="employee-name-link" href={`/employees/${employee.id}`}>{employee.first_name} {employee.last_name}</Link><small>{employee.employee_code} · {employee.email}</small></span></div></td>
                <td><strong className="table-primary">{employee.department}</strong><small className="table-secondary">{employee.job_title}</small></td>
                <td><span className="location-pill">{employee.country_code}</span></td>
                <td><span className="level-pill">{employee.job_level}</span></td>
                <td><strong className="table-primary">{formatSalary(employee)}</strong><small className="table-secondary">{employee.compensation?.currency ?? "No active compensation"}</small></td>
                <td><span className="date-value">{formatDate(employee.date_of_joining)}</span></td>
              </tr>)}
              {!loading && !error && data?.employees.length === 0 && <tr><td className="empty-directory" colSpan={6}><strong>No employees found</strong><span>Try changing or clearing your filters.</span></td></tr>}
              {loading && !data && Array.from({ length: 6 }, (_, index) => <tr key={index}><td colSpan={6}><div className="table-skeleton" /></td></tr>)}
            </tbody>
          </table>
        </div>

        <div className="directory-pagination">
          <span>Page {data?.pagination.page ?? page} of {Math.max(data?.pagination.total_pages ?? 0, 1)}</span>
          <div><button type="button" disabled={page <= 1 || loading} onClick={() => goToPage(Math.max(page - 1, 1))}>Previous</button><button type="button" disabled={loading || !data || page >= data.pagination.total_pages} onClick={() => goToPage(page + 1)}>Next</button></div>
        </div>
      </section>
    </AppShell>
  );
}
