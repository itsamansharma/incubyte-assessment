import { Suspense } from "react";
import AppShell from "@/components/app-shell";
import { dashboardApiBaseUrl, loadDashboard, type DashboardData, type PayBand } from "@/lib/dashboard-data";
import { countryName, formatMoney, formatNumber } from "@/lib/format";

function DashboardLoading() {
  return (
    <div className="dashboard-loading" aria-label="Loading payroll overview">
      <div className="loading-heading" />
      <div className="loading-cards">
        {[1, 2, 3, 4].map((item) => <div className="loading-card" key={item} />)}
      </div>
      <div className="loading-panels">
        <div className="loading-panel" />
        <div className="loading-panel" />
      </div>
    </div>
  );
}

function MetricCard({
  label,
  value,
  detail,
  icon,
  tone,
}: {
  label: string;
  value: string;
  detail: string;
  icon: string;
  tone: string;
}) {
  return (
    <article className="metric-card">
      <div className="metric-topline">
        <span className="metric-label">{label}</span>
        <span className={`metric-icon ${tone}`} aria-hidden="true">{icon}</span>
      </div>
      <strong className="metric-value">{value}</strong>
      <div className="metric-detail"><span className="detail-mark">↗</span>{detail}</div>
    </article>
  );
}

export function PayBandAnalysis({ bands }: { bands: PayBand[] }) {
  const departments = [...new Set(bands.map((band) => band.department))];
  const levelOrder = ["Junior", "Mid", "Senior", "Lead", "Manager", "Director"];

  return (
    <section className="panel pay-band-panel">
      <div className="panel-heading">
        <div><p className="panel-kicker">COMPENSATION ANALYTICS</p><h2>Salary ranges by department</h2><p className="panel-description">Annual USD-equivalent salary percentiles for each job level.</p></div>
        <span className="pay-band-legend"><i className="p25-dot" />P25 <i className="median-dot" />Median <i className="p75-dot" />P75</span>
      </div>
      <div className="pay-band-departments">
        {departments.map((department, index) => {
          const groups = bands
            .filter((band) => band.department === department)
            .sort((first, second) => levelOrder.indexOf(first.job_level) - levelOrder.indexOf(second.job_level));
          const departmentHeadcount = groups.reduce((total, group) => total + group.headcount, 0);

          return (
            <details className="pay-band-department" key={department} open={index === 0}>
              <summary><strong>{department}</strong><span>{formatNumber(departmentHeadcount)} employees</span></summary>
              <div className="pay-band-table-wrap">
                <table className="pay-band-table">
                  <thead><tr><th>JOB LEVEL</th><th>TEAM SIZE</th><th>P25</th><th>MEDIAN</th><th>P75</th></tr></thead>
                  <tbody>{groups.map((band) => <tr key={band.job_level}>
                    <td><strong>{band.job_level}</strong></td>
                    <td>{formatNumber(band.headcount)}</td>
                    <td>{formatMoney(band.p25_annual_salary_usd_cents)}</td>
                    <td className="pay-band-median">{formatMoney(band.median_annual_salary_usd_cents)}</td>
                    <td>{formatMoney(band.p75_annual_salary_usd_cents)}</td>
                  </tr>)}</tbody>
                </table>
              </div>
            </details>
          );
        })}
        {departments.length === 0 && <div className="history-empty">No active compensation data is available for pay-band analysis.</div>}
      </div>
      <div className="panel-footnote">Percentiles use employees with active compensation records. Amounts are normalized to USD.</div>
    </section>
  );
}

export function DashboardUnavailable() {
  return (
    <AppShell activePage="overview">
      <section className="content-wrap">
        <div className="page-heading">
          <div><p className="eyebrow">GLOBAL WORKFORCE</p><h1>Overview</h1></div>
        </div>
        <div className="api-error" role="status">
          <span className="error-symbol">!</span>
          <div>
            <strong>Payroll data is unavailable</strong>
            <p>Try again shortly or verify that the payroll API is available.</p>
            <code>{dashboardApiBaseUrl}</code>
          </div>
        </div>
      </section>
    </AppShell>
  );
}

async function DashboardContent() {
  let data: DashboardData;

  try {
    data = await loadDashboard();
  } catch {
    return <DashboardUnavailable />;
  }

  return <DashboardView data={data} />;
}

export function DashboardView({ data }: { data: DashboardData }) {
  const departmentsByPayroll = [...data.departments]
    .sort((first, second) => second.annual_payroll_usd_cents - first.annual_payroll_usd_cents);
  const highestDepartmentPayroll = Math.max(...departmentsByPayroll.map((department) => department.annual_payroll_usd_cents), 1);
  const headcountByLevel = ["Junior", "Mid", "Senior", "Lead", "Manager", "Director"].map((level) => {
    const bands = data.payBands.filter((band) => band.job_level === level);
    const population = bands.reduce((sum, band) => sum + band.headcount, 0);

    return { level, population };
  });
  const highestLevelHeadcount = Math.max(...headcountByLevel.map((item) => item.population), 1);

  return (
    <AppShell activePage="overview">
      <section className="content-wrap">
        <div className="page-heading">
          <div>
            <p className="eyebrow">GLOBAL WORKFORCE</p>
            <h1>Overview</h1>
            <p className="page-subtitle">A clear view of your people and payroll, across every region.</p>
          </div>
          <div className="period-select"><span className="calendar-icon">◷</span>Annual snapshot</div>
        </div>

        <section className="metrics-grid" aria-label="Global payroll metrics">
          <MetricCard
            label="Total employees"
            value={formatNumber(data.overview.headcount)}
            detail={`${data.countries.length} countries represented`}
            icon="♙"
            tone="blue"
          />
          <MetricCard
            label="Annual payroll"
            value={formatMoney(data.overview.annual_payroll_usd_cents, "USD", true)}
            detail="Converted to USD"
            icon="＄"
            tone="green"
          />
          <MetricCard
            label="Average salary"
            value={formatMoney(data.overview.average_annual_salary_usd_cents)}
            detail="Annual, USD equivalent"
            icon="⌁"
            tone="purple"
          />
          <MetricCard
            label="Median salary"
            value={formatMoney(data.overview.median_annual_salary_usd_cents)}
            detail="Annual, USD equivalent"
            icon="◒"
            tone="orange"
          />
        </section>

        <section className="insights-grid">
          <article className="panel country-panel">
            <div className="panel-heading">
              <div><p className="panel-kicker">PEOPLE</p><h2>Team by country</h2></div>
              <span className="panel-menu" aria-hidden="true">···</span>
            </div>
            <div className="country-list">
              {data.countries.map((country) => {
                const share = data.overview.headcount ? country.headcount / data.overview.headcount : 0;
                return (
                  <div className="country-row" key={country.country_code}>
                    <div className={`country-code country-${country.country_code?.toLowerCase()}`}>{country.country_code}</div>
                    <div className="country-details">
                      <div className="country-title"><strong>{countryName(country.country_code ?? "")}</strong><span>{formatNumber(country.headcount)}</span></div>
                      <div className="progress-track"><span className="progress-fill country-fill" style={{ width: `${Math.max(share * 100, 2)}%` }} /></div>
                      <div className="country-summary">
                        <span>Payroll <strong>{formatMoney(country.annual_payroll_usd_cents, "USD", true)}</strong></span>
                        <span>Avg <strong>{formatMoney(country.average_annual_salary_usd_cents, "USD", true)}</strong></span>
                        <span>Median <strong>{formatMoney(country.median_annual_salary_usd_cents, "USD", true)}</strong></span>
                      </div>
                    </div>
                    <span className="country-share">{Math.round(share * 100)}%</span>
                  </div>
                );
              })}
            </div>
            <div className="panel-footnote">Headcount across active employee records</div>
          </article>

          <article className="panel department-panel">
            <div className="panel-heading">
              <div><p className="panel-kicker">PAYROLL</p><h2>Payroll by department</h2></div>
              <span className="panel-menu" aria-hidden="true">···</span>
            </div>
            <div className="department-list">
              {departmentsByPayroll.map((department, index) => {
                const amount = department.annual_payroll_usd_cents;
                const percentage = amount / highestDepartmentPayroll;
                return (
                  <div className="department-row" key={department.department}>
                    <div className="department-row-top">
                    <div className="department-name"><span className={`department-indicator color-${(index % 5) + 1}`} />{department.department}</div>
                      <strong>{formatMoney(amount, "USD", true)}</strong>
                    </div>
                    <div className="department-row-bottom">
                      <span>{formatNumber(department.headcount)} employees</span>
                      <span>Avg {formatMoney(department.average_annual_salary_usd_cents, "USD", true)}</span>
                      <span>Median {formatMoney(department.median_annual_salary_usd_cents, "USD", true)}</span>
                    </div>
                    <div className="progress-track department-track"><span className={`progress-fill department-fill color-${(index % 5) + 1}`} style={{ width: `${Math.max(percentage * 100, 3)}%` }} /></div>
                  </div>
                );
              })}
            </div>
            <div className="panel-footnote">Annual compensation normalized to USD</div>
          </article>
        </section>

        <section className="panel pay-panel">
          <div className="panel-heading pay-heading">
            <div><p className="panel-kicker">WORKFORCE</p><h2>Team by career level</h2><p className="panel-description">Employee distribution across job levels.</p></div>
            <span className="legend"><i />Employees</span>
          </div>
          <div className="level-chart">
            {headcountByLevel.map((item) => {
              const width = Math.max((item.population / highestLevelHeadcount) * 100, 2);
              return (
                <div className="level-row" key={item.level}>
                  <div className="level-label"><strong>{item.level}</strong><span>{formatNumber(item.population)} people</span></div>
                  <div className="level-bar-area"><div className="level-track"><span className="level-fill" style={{ width: `${width}%` }} /></div></div>
                  <strong className="level-value">{formatNumber(item.population)}</strong>
                </div>
              );
            })}
          </div>
          <div className="panel-footnote">Counts are based on active employee records.</div>
        </section>

        <PayBandAnalysis bands={data.payBands} />

        <footer className="page-footer"><span>ACME payroll overview</span><span>Amounts shown in USD cents, rounded to whole dollars</span></footer>
      </section>
    </AppShell>
  );
}

export default function Home() {
  return (
    <Suspense fallback={<AppShell activePage="overview"><section className="content-wrap"><DashboardLoading /></section></AppShell>}>
      <DashboardContent />
    </Suspense>
  );
}
