import { Suspense } from "react";
import AppShell from "@/components/app-shell";
import EmployeeProfile from "./profile";

function ProfileLoading() {
  return (
    <AppShell activePage="employees">
      <section className="content-wrap"><div className="loading-heading" /><div className="loading-panel profile-loading-panel" /></section>
    </AppShell>
  );
}

export default function EmployeePage() {
  return <Suspense fallback={<ProfileLoading />}><EmployeeProfile /></Suspense>;
}
