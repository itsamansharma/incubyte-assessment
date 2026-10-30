import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ACME | Payroll Overview",
  description: "Global headcount and compensation overview for ACME.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
