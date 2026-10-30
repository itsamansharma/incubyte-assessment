import { afterEach, describe, expect, it, vi } from "vitest";
import { apiRequest } from "@/lib/api";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

describe("apiRequest", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("returns parsed JSON for successful responses", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({ headcount: 10 })));

    await expect(apiRequest<{ headcount: number }>("/api/v1/dashboard/overview"))
      .resolves.toEqual({ headcount: 10 });
  });

  it("uses the API error and validation messages from failed responses", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValueOnce(jsonResponse({ error: "Unsupported currency" }, 422)));
    await expect(apiRequest("/api/v1/employees/1/compensations"))
      .rejects.toThrow("Unsupported currency");

    vi.stubGlobal("fetch", vi.fn().mockResolvedValueOnce(jsonResponse({ errors: [ "Amount is invalid", "Date is required" ] }, 422)));
    await expect(apiRequest("/api/v1/employees/1/compensations"))
      .rejects.toThrow("Amount is invalid, Date is required");
  });

  it("falls back to the HTTP status if a failed response has no JSON error", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response("not-json", { status: 503 })));

    await expect(apiRequest("/api/v1/employees"))
      .rejects.toThrow("Request failed (503)");
  });
});
