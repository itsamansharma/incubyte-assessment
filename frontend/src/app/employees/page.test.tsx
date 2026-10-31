import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import EmployeesPage from "@/app/employees/page";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function employee(id: number, firstName = "Asha", lastName = "Rao") {
  return {
    id,
    employee_code: `ACM-${String(id).padStart(5, "0")}`,
    first_name: firstName,
    last_name: lastName,
    email: `${firstName.toLowerCase()}@example.com`,
    country_code: "IN",
    department: "Engineering",
    job_title: "Software Engineer",
    job_level: "Mid",
    date_of_joining: "2022-05-10",
    compensation: { amount_cents: 8_500_000, currency: "INR", amount_usd_cents: 1_020_000, effective_date: "2025-01-01" },
  };
}

function page(employees: ReturnType<typeof employee>[], currentPage = 1, totalPages = 1, totalCount = employees.length) {
  return { employees, pagination: { page: currentPage, per_page: 25, total_count: totalCount, total_pages: totalPages } };
}

describe("employee directory", () => {
  afterEach(() => vi.useRealTimers());

  it("renders employee details and links to the employee profile", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse(page([employee(7)]))));
    render(<EmployeesPage />);

    expect(await screen.findByRole("link", { name: "Asha Rao" })).toBeTruthy();
    expect(screen.getByText("ACM-00007 · asha@example.com")).toBeTruthy();
    expect(screen.getByRole("cell", { name: /Engineering/ })).toBeTruthy();
    expect(screen.getByText("IN")).toBeTruthy();
    expect(screen.getByText("Showing 1–1 of 1")).toBeTruthy();
    expect(screen.getByRole("link", { name: "Asha Rao" }).getAttribute("href")).toBe("/employees/7");
  });

  it("debounces search input and sends filter, sorting, and direction parameters", async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse(page([employee(7)])));
    vi.stubGlobal("fetch", fetchMock);
    render(<EmployeesPage />);
    await screen.findByRole("link", { name: "Asha Rao" });

    fireEvent.change(screen.getByRole("textbox", { name: "Search employees" }), { target: { value: "Asha Rao" } });
    fireEvent.change(screen.getByLabelText("Country"), { target: { value: "IN" } });
    fireEvent.change(screen.getByLabelText("Department"), { target: { value: "Engineering" } });
    fireEvent.change(screen.getByLabelText("Currency"), { target: { value: "INR" } });
    fireEvent.change(screen.getByLabelText("Min annual salary (USD)"), { target: { value: "50000.25" } });
    fireEvent.change(screen.getByLabelText("Max annual salary (USD)"), { target: { value: "100000" } });
    fireEvent.change(screen.getByLabelText("Sort by"), { target: { value: "salary" } });
    fireEvent.click(screen.getByRole("button", { name: "Sort descending" }));

    await waitFor(() => {
      const lastUrl = String(fetchMock.mock.calls.at(-1)?.[0]);
      expect(lastUrl).toContain("q=Asha+Rao");
      expect(lastUrl).toContain("country_code=IN");
      expect(lastUrl).toContain("department=Engineering");
      expect(lastUrl).toContain("currency=INR");
      expect(lastUrl).toContain("min_salary_usd_cents=5000025");
      expect(lastUrl).toContain("max_salary_usd_cents=10000000");
      expect(lastUrl).toContain("sort=salary");
      expect(lastUrl).toContain("direction=desc");
    });
    expect(fetchMock.mock.calls.length).toBeGreaterThan(1);
  });

  it("requests the next page and updates result counts", async () => {
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(jsonResponse(page([employee(1)], 1, 2, 26)))
      .mockResolvedValueOnce(jsonResponse(page([employee(26, "Ben", "Lee")], 2, 2, 26)));
    vi.stubGlobal("fetch", fetchMock);
    render(<EmployeesPage />);

    await screen.findByRole("link", { name: "Asha Rao" });
    expect(screen.getByRole("button", { name: "Next" }).hasAttribute("disabled")).toBe(false);
    expect(screen.getByRole("button", { name: "Previous" }).hasAttribute("disabled")).toBe(true);
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(await screen.findByRole("link", { name: "Ben Lee" })).toBeTruthy();
    expect(screen.getByText("Page 2 of 2")).toBeTruthy();
    expect(String(fetchMock.mock.calls.at(-1)?.[0])).toContain("page=2");
    expect(screen.getByRole("button", { name: "Next" }).hasAttribute("disabled")).toBe(true);
  });

  it("offers seeded filter dropdowns and caps salary input before sending cents", async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse(page([employee(7)])));
    vi.stubGlobal("fetch", fetchMock);
    render(<EmployeesPage />);

    await screen.findByRole("link", { name: "Asha Rao" });
    expect(screen.getByRole("option", { name: "India" })).toBeTruthy();
    expect(screen.getByRole("option", { name: "Engineering" })).toBeTruthy();
    expect(screen.getByRole("option", { name: "INR" })).toBeTruthy();

    fireEvent.change(screen.getByLabelText("Max annual salary (USD)"), { target: { value: "99999999999999999999" } });
    const salaryInput = screen.getByLabelText("Max annual salary (USD)") as HTMLInputElement;
    expect(Number(salaryInput.value)).toBeLessThanOrEqual(Number(salaryInput.max));
    expect(Math.round(Number(salaryInput.value) * 100)).toBeLessThanOrEqual(Number.MAX_SAFE_INTEGER);
    await waitFor(() => expect(String(fetchMock.mock.calls.at(-1)?.[0])).not.toContain("max_salary_usd_cents=99999999999999999999"));
  });

  it("shows empty and API error states", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse(page([]))));
    const { unmount } = render(<EmployeesPage />);
    expect(await screen.findByText("No employees found")).toBeTruthy();
    unmount();

    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({ error: "Database unavailable" }, 503)));
    render(<EmployeesPage />);
    expect(await screen.findByRole("alert")).toBeTruthy();
    expect(screen.getByRole("alert").textContent).toContain("Database unavailable");
  });
});
