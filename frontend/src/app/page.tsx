import { Suspense } from "react";
import AppShell from "@/components/app-shell";

type Overview = {
  headcount: number;
  annual_payroll_usd_cents: number;
  average_annual_salary_usd_cents: number | null;
  median_annual_salary_usd_cents: number | null;
};

type GroupSummary = {
  department?: string;
  country_code?: string;
  headcount: number;
  annual_payroll_usd_cents: number;
  average_annual_salary_usd_cents: number | null;
  median_annual_salary_usd_cents: number | null;
};

type PayBand = {
  department: string;
  job_level: string;
  headcount: number;
  p25_annual_salary_usd_cents: number;
  median_annual_salary_usd_cents: number;
  p75_annual_salary_usd_cents: number;
};

type DashboardData = {
  overview: Overview;
  departments: GroupSummary[];
  countries: GroupSummary[];
  payBands: PayBand[];
};

const apiBaseUrl = (process.env.RAILS_API_URL ?? "http://127.0.0.1:3000").replace(/\/$/, "");

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, { cache: "no-store" });

  if (!response.ok) {
    throw new Error(`The payroll API returned ${response.status}.`);
  }

  return response.json() as Promise<T>;
}

async function loadDashboard(): Promise<DashboardData> {
  const [overview, breakdown, payBandResponse] = await Promise.all([
    fetchJson<Overview>("/api/v1/dashboard/overview"),
    fetchJson<{ departments: GroupSummary[]; countries: GroupSummary[] }>(
      "/api/v1/dashboard/breakdown",
    ),
    fetchJson<{ groups: PayBand[] }>("/api/v1/dashboard/pay_bands"),
  ]);

  return {
    overview,
    departments: breakdown.departments,
    countries: breakdown.countries,
    payBands: payBandResponse.groups,
  };
}

function formatMoney(cents: number | null, compact = false): string {
  if (cents === null) return "—";

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
    notation: compact ? "compact" : "standard",
  }).format(cents / 100);
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US").format(value);
}

function countryName(code: string): string {
  return new Intl.DisplayNames(["en"], { type: "region" }).of(code) ?? code;
}

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

async function DashboardContent() {
  let data: DashboardData;

  try {
    data = await loadDashboard();
  } catch {
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
              <p>Start the Rails API and refresh this page. The dashboard reads live data from your local payroll database.</p>
              <code>{apiBaseUrl}</code>
            </div>
          </div>
        </section>
      </AppShell>
    );
  }

  const topDepartments = [...data.departments]
    .sort((first, second) => second.annual_payroll_usd_cents - first.annual_payroll_usd_cents)
    .slice(0, 5);
  const highestDepartmentPayroll = Math.max(...topDepartments.map((department) => department.annual_payroll_usd_cents), 1);
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
            value={formatMoney(data.overview.annual_payroll_usd_cents, true)}
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
              {topDepartments.map((department, index) => {
                const amount = department.annual_payroll_usd_cents;
                const percentage = amount / highestDepartmentPayroll;
                return (
                  <div className="department-row" key={department.department}>
                    <div className="department-row-top">
                      <div className="department-name"><span className={`department-indicator color-${index + 1}`} />{department.department}</div>
                      <strong>{formatMoney(amount, true)}</strong>
                    </div>
                    <div className="department-row-bottom">
                      <span>{formatNumber(department.headcount)} employees</span>
                      <span>{formatMoney(department.average_annual_salary_usd_cents)} avg.</span>
                    </div>
                    <div className="progress-track department-track"><span className={`progress-fill department-fill color-${index + 1}`} style={{ width: `${Math.max(percentage * 100, 3)}%` }} /></div>
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
