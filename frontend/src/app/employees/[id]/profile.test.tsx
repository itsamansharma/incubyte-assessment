import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import EmployeeProfile from "./profile";

vi.mock("next/navigation", () => ({ useParams: () => ({ id: "42" }) }));

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function profile(overrides: Record<string, unknown> = {}) {
  const currentCompensation = {
    id: 9,
    amount_cents: 8_500_000,
    currency: "INR",
    amount_usd_cents: 1_020_000,
    effective_date: "2025-01-01",
    change_reason: "Promotion",
    is_active: true,
  };
  return {
    id: 42,
    employee_code: "ACM-00042",
    first_name: "Asha",
    last_name: "Rao",
    email: "asha@example.com",
    country_code: "IN",
    department: { name: "Engineering", code: "ENG" },
    job_title: "Software Engineer",
    job_level: "Mid",
    date_of_joining: "2022-05-10",
    current_compensation: currentCompensation,
    compensation_history: [currentCompensation],
    ...overrides,
  };
}

async function fillSalaryForm(amount: string) {
  fireEvent.change(screen.getByLabelText("Annual salary"), { target: { value: amount } });
  fireEvent.change(screen.getByLabelText("Reason"), { target: { value: "Annual review" } });
  fireEvent.submit(screen.getByRole("button", { name: "Save salary change" }).closest("form")!);
}

describe("employee profile", () => {
  it("renders employee details, current compensation, and history", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse(profile())));
    render(<EmployeeProfile />);

    expect(await screen.findByRole("heading", { name: "Asha Rao" })).toBeTruthy();
    expect(screen.getByText("ACM-00042")).toBeTruthy();
    expect(screen.getByText("India")).toBeTruthy();
    expect(screen.getByText("Software Engineer · Engineering")).toBeTruthy();
    expect(screen.getByText("Promotion")).toBeTruthy();
    expect(screen.getByText("Current")).toBeTruthy();
    expect(screen.getByText("1 record")).toBeTruthy();
  });

  it("handles an employee without compensation or history", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse(profile({ current_compensation: null, compensation_history: [] }))));
    render(<EmployeeProfile />);

    expect(await screen.findByText("No active compensation record")).toBeTruthy();
    expect(screen.getByText("No compensation history is available.")).toBeTruthy();
    expect(screen.getByText("0 records")).toBeTruthy();
  });

  it("reports a profile API error", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({ error: "Employee not found" }, 404)));
    render(<EmployeeProfile />);

    expect(await screen.findByRole("alert")).toBeTruthy();
    expect(screen.getByRole("alert").textContent).toContain("Employee not found");
  });

  it("validates salary locally and submits a valid salary before refreshing the profile", async () => {
    const updated = profile({
      current_compensation: { id: 10, amount_cents: 8_500_025, currency: "INR", amount_usd_cents: 1_020_003, effective_date: "2025-02-01", change_reason: "Annual review", is_active: true },
      compensation_history: [
        { id: 10, amount_cents: 8_500_025, currency: "INR", amount_usd_cents: 1_020_003, effective_date: "2025-02-01", change_reason: "Annual review", is_active: true },
        { id: 9, amount_cents: 8_500_000, currency: "INR", amount_usd_cents: 1_020_000, effective_date: "2025-01-01", change_reason: "Promotion", is_active: false },
      ],
    });
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(jsonResponse(profile()))
      .mockResolvedValueOnce(jsonResponse({ compensation: updated.current_compensation }, 201))
      .mockResolvedValueOnce(jsonResponse(updated));
    vi.stubGlobal("fetch", fetchMock);
    render(<EmployeeProfile />);
    await screen.findByRole("heading", { name: "Asha Rao" });

    await fillSalaryForm("0");
    expect((await screen.findByRole("alert")).textContent).toContain("Enter a salary greater than zero");
    expect(fetchMock).toHaveBeenCalledTimes(1);

    await fillSalaryForm("85000.25");
    expect((await screen.findByRole("status")).textContent).toContain("Salary change saved");
    expect(screen.getByText("2 records")).toBeTruthy();
    expect(fetchMock).toHaveBeenCalledTimes(3);

    const [, requestOptions] = fetchMock.mock.calls[1];
    expect(String(fetchMock.mock.calls[1][0])).toContain("/employees/42/compensations");
    expect(JSON.parse(String(requestOptions?.body))).toMatchObject({
      compensation: {
        amount_cents: 8_500_025,
        currency: "INR",
        change_reason: "Annual review",
      },
    });
  });

  it("shows save failures and explains when refresh fails after a successful save", async () => {
    const saveErrorFetch = vi.fn()
      .mockResolvedValueOnce(jsonResponse(profile()))
      .mockResolvedValueOnce(jsonResponse({ error: "Unsupported currency" }, 422));
    vi.stubGlobal("fetch", saveErrorFetch);
    const firstRender = render(<EmployeeProfile />);
    await screen.findByRole("heading", { name: "Asha Rao" });
    await fillSalaryForm("85000");
    expect((await screen.findByRole("alert")).textContent).toContain("Unsupported currency");
    firstRender.unmount();

    vi.stubGlobal("fetch", vi.fn()
      .mockResolvedValueOnce(jsonResponse(profile()))
      .mockResolvedValueOnce(jsonResponse({ compensation: {} }, 201))
      .mockResolvedValueOnce(jsonResponse({ error: "Temporary outage" }, 503)));
    render(<EmployeeProfile />);
    await screen.findByRole("heading", { name: "Asha Rao" });
    await fillSalaryForm("85000");
    await waitFor(() => expect(screen.getByRole("alert").textContent).toContain("Salary was saved, but the profile could not be refreshed"));
  });
});
