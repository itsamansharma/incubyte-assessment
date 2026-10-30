import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { DashboardUnavailable, DashboardView, PayBandAnalysis } from "@/app/page";
import type { DashboardData } from "@/lib/dashboard-data";

const dashboardData: DashboardData = {
  overview: {
    headcount: 12,
    annual_payroll_usd_cents: 2_400_000,
    average_annual_salary_usd_cents: 200_000,
    median_annual_salary_usd_cents: 180_000,
  },
  countries: [{
    country_code: "IN",
    headcount: 12,
    annual_payroll_usd_cents: 2_400_000,
    average_annual_salary_usd_cents: 200_000,
    median_annual_salary_usd_cents: 180_000,
  }],
  departments: [
    {
      department: "Engineering",
      headcount: 8,
      annual_payroll_usd_cents: 1_800_000,
      average_annual_salary_usd_cents: 225_000,
      median_annual_salary_usd_cents: 220_000,
    },
    {
      department: "People",
      headcount: 4,
      annual_payroll_usd_cents: 600_000,
      average_annual_salary_usd_cents: 150_000,
      median_annual_salary_usd_cents: 150_000,
    },
  ],
  payBands: [{
    department: "Engineering",
    job_level: "Mid",
    headcount: 8,
    p25_annual_salary_usd_cents: 180_000,
    median_annual_salary_usd_cents: 220_000,
    p75_annual_salary_usd_cents: 250_000,
  }],
};

describe("dashboard", () => {
  it("renders workforce metrics, country and department insights, and pay bands", () => {
    render(<DashboardView data={dashboardData} />);

    expect(screen.getByRole("heading", { name: "Overview" })).toBeTruthy();
    expect(screen.getByText("Total employees")).toBeTruthy();
    expect(screen.getByText("12", { selector: ".metric-value" })).toBeTruthy();
    expect(screen.getByText("India")).toBeTruthy();
    expect(screen.getByText("Engineering", { selector: ".department-name" })).toBeTruthy();
    expect(screen.getByRole("heading", { name: "Salary ranges by department" })).toBeTruthy();
    expect(screen.getByText("Mid", { selector: ".pay-band-table td strong" })).toBeTruthy();
  });

  it("orders departments by payroll and handles empty workforce data safely", () => {
    const { container, rerender } = render(<DashboardView data={dashboardData} />);
    const departmentNames = [...container.querySelectorAll(".department-name")].map((node) => node.textContent);
    expect(departmentNames).toEqual(["Engineering", "People"]);

    const emptyData: DashboardData = {
      overview: { headcount: 0, annual_payroll_usd_cents: 0, average_annual_salary_usd_cents: null, median_annual_salary_usd_cents: null },
      departments: [],
      countries: [],
      payBands: [],
    };
    rerender(<DashboardView data={emptyData} />);
    expect(screen.getByText("No active compensation data is available for pay-band analysis.")).toBeTruthy();
    expect(container.querySelector(".country-share")).toBeNull();
    expect(container.querySelectorAll(".level-row")).toHaveLength(6);
  });

  it("shows the unavailable API state", () => {
    render(<DashboardUnavailable />);
    expect(screen.getByRole("status").textContent).toContain("Payroll data is unavailable");
    expect(screen.getByRole("status").textContent).toContain("127.0.0.1:3000");
  });

  it("renders the no-data state when pay-band analysis has no groups", () => {
    render(<PayBandAnalysis bands={[]} />);
    expect(screen.getByText("No active compensation data is available for pay-band analysis.")).toBeTruthy();
  });
});
