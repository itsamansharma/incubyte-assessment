"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";
import AppShell from "@/components/app-shell";

type Compensation = {
  id: number;
  amount_cents: number;
  currency: string;
  amount_usd_cents: number;
  effective_date: string;
  change_reason: string;
  is_active: boolean;
};

type EmployeeProfileData = {
  id: number;
  employee_code: string;
  first_name: string;
  last_name: string;
  email: string;
  country_code: string;
  department: { name: string; code: string };
  job_title: string;
  job_level: string;
  date_of_joining: string;
  current_compensation: Compensation | null;
  compensation_history: Compensation[];
};

const apiBaseUrl = (process.env.NEXT_PUBLIC_RAILS_API_URL ?? "http://127.0.0.1:3000").replace(/\/$/, "");

function formatMoney(cents: number, currency: string): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency, maximumFractionDigits: 0 }).format(cents / 100);
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat("en-US", { month: "long", day: "numeric", year: "numeric", timeZone: "UTC" }).format(new Date(`${value}T00:00:00Z`));
}

export default function EmployeeProfile() {
  const { id } = useParams<{ id: string }>();
  const [employee, setEmployee] = useState<EmployeeProfileData | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();
    fetch(`${apiBaseUrl}/api/v1/employees/${encodeURIComponent(id)}`, { signal: controller.signal })
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error ?? `Request failed (${response.status})`);
        return body as EmployeeProfileData;
      })
      .then(setEmployee)
      .catch((requestError: unknown) => {
        if (requestError instanceof DOMException && requestError.name === "AbortError") return;
        setError(requestError instanceof Error ? requestError.message : "Could not load this employee.");
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [id]);

  return (
    <AppShell activePage="employees">
      <section className="content-wrap profile-wrap">
        <Link className="back-to-directory" href="/employees">← <span>Back to employees</span></Link>
        {loading && <div className="profile-loading"><div className="loading-heading" /><div className="loading-panel profile-loading-panel" /></div>}
        {error && <div className="api-error directory-error" role="alert"><span className="error-symbol">!</span><div><strong>Couldn’t load this employee</strong><p>{error}</p></div></div>}
        {!loading && !error && employee && <>
          <section className="profile-header panel">
            <div className="profile-person">
              <div className="profile-avatar">{employee.first_name[0]}{employee.last_name[0]}</div>
              <div><p className="eyebrow">EMPLOYEE PROFILE</p><h1>{employee.first_name} {employee.last_name}</h1><p className="page-subtitle">{employee.job_title} · {employee.department.name}</p></div>
            </div>
            <span className="profile-code">{employee.employee_code}</span>
          </section>

          <section className="profile-overview-grid" aria-label="Employee information">
            <article className="panel profile-info-panel"><p className="panel-kicker">PERSONAL DETAILS</p><h2>About</h2>
              <dl className="profile-details">
                <div><dt>Email</dt><dd><a href={`mailto:${employee.email}`}>{employee.email}</a></dd></div>
                <div><dt>Location</dt><dd>{new Intl.DisplayNames(["en"], { type: "region" }).of(employee.country_code) ?? employee.country_code}</dd></div>
                <div><dt>Department</dt><dd>{employee.department.name} <span className="detail-code">{employee.department.code}</span></dd></div>
                <div><dt>Job level</dt><dd>{employee.job_level}</dd></div>
                <div><dt>Start date</dt><dd>{formatDate(employee.date_of_joining)}</dd></div>
              </dl>
            </article>
            <article className="panel current-pay-panel"><p className="panel-kicker">CURRENT COMPENSATION</p><h2>Annual salary</h2>
              {employee.current_compensation ? <>
                <strong className="current-salary">{formatMoney(employee.current_compensation.amount_cents, employee.current_compensation.currency)}</strong>
                <p className="salary-equivalent">{formatMoney(employee.current_compensation.amount_usd_cents, "USD")} USD equivalent</p>
                <div className="salary-effective">Effective {formatDate(employee.current_compensation.effective_date)}</div>
              </> : <p className="no-current-salary">No active compensation record</p>}
            </article>
          </section>

          <section className="panel history-panel">
            <div className="panel-heading"><div><p className="panel-kicker">COMPENSATION</p><h2>Salary history</h2><p className="panel-description">A record of compensation changes for this employee.</p></div><span className="history-count">{employee.compensation_history.length} {employee.compensation_history.length === 1 ? "record" : "records"}</span></div>
            {employee.compensation_history.length ? <div className="history-table-wrap"><table className="history-table"><thead><tr><th>EFFECTIVE DATE</th><th>ANNUAL SALARY</th><th>USD EQUIVALENT</th><th>CHANGE REASON</th><th>STATUS</th></tr></thead><tbody>
              {employee.compensation_history.map((compensation) => <tr key={compensation.id}>
                <td>{formatDate(compensation.effective_date)}</td>
                <td><strong>{formatMoney(compensation.amount_cents, compensation.currency)}</strong></td>
                <td>{formatMoney(compensation.amount_usd_cents, "USD")}</td>
                <td>{compensation.change_reason}</td>
                <td><span className={`compensation-status${compensation.is_active ? " active" : ""}`}>{compensation.is_active ? "Current" : "Previous"}</span></td>
              </tr>)}
            </tbody></table></div> : <div className="history-empty">No compensation history is available.</div>}
          </section>
        </>}
      </section>
    </AppShell>
  );
}
