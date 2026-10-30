import { cleanup } from "@testing-library/react";
import { afterEach, vi } from "vitest";

vi.mock("next/link", async () => {
  const React = await import("react");

  type LinkProps = {
    href: string;
    children: React.ReactNode;
    className?: string;
    "aria-label"?: string;
    "aria-current"?: "page";
  };

  return {
    default: ({ href, children, ...props }: LinkProps) =>
      React.createElement("a", { href, ...props }, children),
  };
});

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});
