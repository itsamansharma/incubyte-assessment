import { describe, expect, it } from "vitest";
import { countryName, formatDate, formatMoney, formatNumber } from "@/lib/format";

describe("format helpers", () => {
  it("formats money from integer cents and returns a dash for missing values", () => {
    expect(formatMoney(123_456)).toBe("$1,235");
    expect(formatMoney(null)).toBe("—");
    expect(formatMoney(8_500_000, "INR")).toContain("₹");
  });

  it("supports compact payroll totals and localized numbers", () => {
    expect(formatMoney(79_100_000_000, "USD", true)).toBe("$791M");
    expect(formatNumber(10_000)).toBe("10,000");
  });

  it("formats calendar dates in UTC with short or long month names", () => {
    expect(formatDate("2025-01-02")).toBe("Jan 2, 2025");
    expect(formatDate("2025-01-02", "long")).toBe("January 2, 2025");
  });

  it("maps country codes to readable names", () => {
    expect(countryName("IN")).toBe("India");
  });
});
