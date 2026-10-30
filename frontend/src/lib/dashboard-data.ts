export type Overview = {
  headcount: number;
  annual_payroll_usd_cents: number;
  average_annual_salary_usd_cents: number | null;
  median_annual_salary_usd_cents: number | null;
};

export type GroupSummary = {
  department?: string;
  country_code?: string;
  headcount: number;
  annual_payroll_usd_cents: number;
  average_annual_salary_usd_cents: number | null;
  median_annual_salary_usd_cents: number | null;
};

export type PayBand = {
  department: string;
  job_level: string;
  headcount: number;
  p25_annual_salary_usd_cents: number;
  median_annual_salary_usd_cents: number;
  p75_annual_salary_usd_cents: number;
};

export type DashboardData = {
  overview: Overview;
  departments: GroupSummary[];
  countries: GroupSummary[];
  payBands: PayBand[];
};

export const dashboardApiBaseUrl = (
  process.env.RAILS_API_URL ?? "http://127.0.0.1:3000"
).replace(/\/$/, "");

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${dashboardApiBaseUrl}${path}`, { cache: "no-store" });

  if (!response.ok) {
    throw new Error(`The payroll API returned ${response.status}.`);
  }

  return response.json() as Promise<T>;
}

export async function loadDashboard(): Promise<DashboardData> {
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
