import Link from "next/link";

export type DashboardPage = "overview" | "employees";

export default function AppShell({
  children,
  activePage,
}: {
  children: React.ReactNode;
  activePage: DashboardPage;
}) {
  const currentPage = activePage === "overview" ? "Overview" : "Employees";

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <Link className="brand" href="/" aria-label="ACME Payroll home">
          <span className="brand-mark">A</span>
          <span className="brand-copy">
            <strong>acme</strong>
            <small>PEOPLE &amp; PAYROLL</small>
          </span>
        </Link>

        <div className="workspace-label">WORKSPACE</div>
        <nav className="primary-nav" aria-label="Main navigation">
          <Link className={`nav-item${activePage === "overview" ? " active" : ""}`} href="/" aria-current={activePage === "overview" ? "page" : undefined}>
            <span className="nav-icon">◫</span>
            <span>Overview</span>
          </Link>
          <Link className={`nav-item${activePage === "employees" ? " active" : ""}`} href="/employees" aria-current={activePage === "employees" ? "page" : undefined}>
            <span className="nav-icon">⌕</span>
            <span>Employees</span>
          </Link>
          <span className="nav-item disabled" aria-disabled="true">
            <span className="nav-icon">↗</span>
            <span>Compensation</span>
            <span className="nav-soon">Soon</span>
          </span>
        </nav>

        <div className="sidebar-bottom">
          <div className="secure-note">
            <span className="secure-dot" />
            <span>Private workspace</span>
          </div>
          <div className="profile-row">
            <div className="avatar">AM</div>
            <div className="profile-copy">
              <strong>HR Manager</strong>
              <small>ACME Corporation</small>
            </div>
            <span className="profile-menu">···</span>
          </div>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div className="breadcrumbs"><span>Workspace</span><span className="crumb-divider">/</span><strong>{currentPage}</strong></div>
          <div className="topbar-actions">
            <span className="data-status"><span className="status-dot" />Live data</span>
            <button className="icon-button" type="button" aria-label="Notifications">♧<i /></button>
            <div className="top-avatar">AM</div>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}
