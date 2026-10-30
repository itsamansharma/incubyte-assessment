import { describe, expect, it, vi } from "vitest";
import { loadDashboard } from "@/lib/dashboard-data";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

describe("loadDashboard", () => {
  it("loads overview, breakdown, and pay bands into the view model", async () => {
    const fetchMock = vi.fn((input: RequestInfo | URL, options?: RequestInit) => {
      void options;
      const url = String(input);
      if (url.endsWith("/overview")) {
        return Promise.resolve(jsonResponse({
          headcount: 10_000,
          annual_payroll_usd_cents: 79_100_000_000,
          average_annual_salary_usd_cents: 791_000,
          median_annual_salary_usd_cents: 712_000,
        }));
      }
      if (url.endsWith("/breakdown")) {
        return Promise.resolve(jsonResponse({ departments: [ { department: "Engineering", headcount: 5 } ], countries: [ { country_code: "IN", headcount: 5 } ] }));
      }
      return Promise.resolve(jsonResponse({ groups: [ { department: "Engineering", job_level: "Mid", headcount: 5 } ] }));
    });
    vi.stubGlobal("fetch", fetchMock);

    await expect(loadDashboard()).resolves.toMatchObject({
      overview: { headcount: 10_000 },
      departments: [ { department: "Engineering", headcount: 5 } ],
      countries: [ { country_code: "IN", headcount: 5 } ],
      payBands: [ { department: "Engineering", job_level: "Mid", headcount: 5 } ],
    });
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock.mock.calls.map(([url]) => String(url))).toEqual(expect.arrayContaining([
      expect.stringMatching(/\/api\/v1\/dashboard\/overview$/),
      expect.stringMatching(/\/api\/v1\/dashboard\/breakdown$/),
      expect.stringMatching(/\/api\/v1\/dashboard\/pay_bands$/),
    ]));
    expect(fetchMock.mock.calls.every(([, options]) => options?.cache === "no-store")).toBe(true);
  });

  it("fails if one required dashboard endpoint is unavailable", async () => {
    vi.stubGlobal("fetch", vi.fn().mockImplementation((input: RequestInfo | URL) => {
      return Promise.resolve(String(input).endsWith("/pay_bands")
        ? jsonResponse({ error: "Unavailable" }, 503)
        : jsonResponse({}));
    }));

    await expect(loadDashboard()).rejects.toThrow("The payroll API returned 503.");
  });
});
