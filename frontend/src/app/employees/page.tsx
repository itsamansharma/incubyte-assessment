"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import AppShell from "@/components/app-shell";
import { apiRequest } from "@/lib/api";
import { formatDate, formatMoney, formatNumber } from "@/lib/format";

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

const MAX_SALARY_USD = Number.MAX_SAFE_INTEGER / 100;
const COUNTRIES = [
  ["US", "United States"], ["GB", "United Kingdom"], ["IN", "India"], ["DE", "Germany"], ["SG", "Singapore"],
] as const;
const DEPARTMENTS = ["Engineering", "Product", "Sales", "Finance", "Human Resources", "Operations", "Marketing", "Customer Support"];
const CURRENCIES = ["USD", "EUR", "GBP", "INR", "SGD"];

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

    apiRequest<EmployeeResponse>(`/api/v1/employees?${params}`, { signal: controller.signal })
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

  function updateSalary(value: string, setValue: (salary: string) => void) {
    if (value === "") {
      setValue("");
      resetPage();
      return;
    }

    const amount = Number(value);
    const boundedAmount = Number.isFinite(amount) ? Math.min(Math.max(amount, 0), MAX_SALARY_USD) : MAX_SALARY_USD;
    setValue(String(boundedAmount));
    resetPage();
  }

  const resultPage = data?.pagination.page ?? page;
  const firstResult = data?.pagination.total_count ? (resultPage - 1) * data.pagination.per_page + 1 : 0;
  const lastResult = Math.min(resultPage * (data?.pagination.per_page ?? 25), data?.pagination.total_count ?? 0);

  return (
    <AppShell activePage="employees">
      <section className="content-wrap directory-wrap">
        <div className="page-heading directory-heading">
          <div>
            <p className="eyebrow">GLOBAL WORKFORCE</p>
            <h1>Employees</h1>
            <p className="page-subtitle">Search, filter, and explore your global team.</p>
          </div>
          <span className="employee-total">{data ? `${formatNumber(data.pagination.total_count)} employees` : "Employee directory"}</span>
        </div>

        <section className="directory-filters" aria-label="Employee filters">
          <label className="employee-search">
            <svg aria-hidden="true" viewBox="0 0 20 20"><circle cx="8.5" cy="8.5" r="5.5" /><path d="m13 13 4 4" /></svg>
            <input aria-label="Search employees" placeholder="Search name, email or ID..." value={query} onChange={(event) => { setQuery(event.target.value); resetPage(); }} />
          </label>
          <label className="filter-field"><span>Country</span><select aria-label="Country" value={country} onChange={(event) => { setCountry(event.target.value); resetPage(); }}><option value="">Any country</option>{COUNTRIES.map(([code, name]) => <option key={code} value={code}>{name}</option>)}</select></label>
          <label className="filter-field"><span>Department</span><select aria-label="Department" value={department} onChange={(event) => { setDepartment(event.target.value); resetPage(); }}><option value="">Any department</option>{DEPARTMENTS.map((name) => <option key={name} value={name}>{name}</option>)}</select></label>
          <label className="filter-field currency-filter"><span>Currency</span><select aria-label="Currency" value={currency} onChange={(event) => { setCurrency(event.target.value); resetPage(); }}><option value="">Any currency</option>{CURRENCIES.map((code) => <option key={code} value={code}>{code}</option>)}</select></label>
          <label className="filter-field salary-filter"><span>Min annual salary (USD)</span><input inputMode="decimal" type="number" min="0" max={MAX_SALARY_USD} step="0.01" placeholder="No minimum" value={minimumSalary} onChange={(event) => updateSalary(event.target.value, setMinimumSalary)} /></label>
          <label className="filter-field salary-filter"><span>Max annual salary (USD)</span><input inputMode="decimal" type="number" min="0" max={MAX_SALARY_USD} step="0.01" placeholder="No maximum" value={maximumSalary} onChange={(event) => updateSalary(event.target.value, setMaximumSalary)} /></label>
        </section>

        <div className="directory-toolbar">
          <span>{loading ? "Updating results…" : `Showing ${firstResult}–${lastResult} of ${formatNumber(data?.pagination.total_count ?? 0)}`}</span>
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
                <td><strong className="table-primary">{formatMoney(employee.compensation?.amount_cents ?? null, employee.compensation?.currency)}</strong><small className="table-secondary">{employee.compensation?.currency ?? "No active compensation"}</small></td>
                <td><span className="date-value">{formatDate(employee.date_of_joining)}</span></td>
              </tr>)}
              {!loading && !error && data?.employees.length === 0 && <tr><td className="empty-directory" colSpan={6}><strong>No employees found</strong><span>Try changing or clearing your filters.</span></td></tr>}
              {loading && !data && Array.from({ length: 6 }, (_, index) => <tr key={index}><td colSpan={6}><div className="table-skeleton" /></td></tr>)}
            </tbody>
          </table>
        </div>

        <div className="directory-pagination">
          <span>Page {resultPage} of {Math.max(data?.pagination.total_pages ?? 0, 1)}</span>
          <div><button type="button" disabled={resultPage <= 1 || loading} onClick={() => goToPage(Math.max(resultPage - 1, 1))}>Previous</button><button type="button" disabled={loading || !data || resultPage >= data.pagination.total_pages} onClick={() => goToPage(resultPage + 1)}>Next</button></div>
        </div>
      </section>
    </AppShell>
  );
}
