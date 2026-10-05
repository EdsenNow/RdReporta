import { LayoutDashboard, FileText, AlertTriangle, Tag, BadgeCheck, LogOut } from "lucide-react";
import { ThemeSelector } from "../components/ThemeSelector";
import type { ThemePreference, Tab } from "../types";
import { api } from "../api/client";

interface SidebarProps {
  session: any;
  tab: Tab;
  setTab: (tab: Tab) => void;
  setPage: (page: number) => void;
  setNotice: (n: string) => void;
  loading: boolean;
  busy: boolean;
  themePreference: ThemePreference;
  setThemePreference: (t: ThemePreference) => void;
}

export function Sidebar({ session, tab, setTab, setPage, setNotice, loading, busy, themePreference, setThemePreference }: SidebarProps) {
  const tabs = [
    ["dashboard", "Resumen", LayoutDashboard],
    ["posts", "Publicaciones", FileText],
    ["moderation", "Moderaci�n", AlertTriangle],
    ["categories", "Categor�as", Tag],
    ...(session.roles.includes("Administrador") ? [["users", "Verificaciones", BadgeCheck] as const] : []),
  ] as const;

  return (
    <aside className="sidebar">
      <div className="logo-container">
        <div className="logo-badge">RD</div>
        <div>
          <h2>RDReporta</h2>
          <small>Panel administrativo</small>
        </div>
      </div>
      <nav className="nav-links">
        {tabs.map(([value, label, Icon]) => (
          <button key={value} className={`nav-btn ${tab === value ? "active" : ""}`} disabled={loading || busy}
            onClick={() => { setTab(value as Tab); setPage(1); setNotice(""); }}>
            <Icon size={18} />{label}
          </button>
        ))}
      </nav>
      <div className="session-info">
        <ThemeSelector compact value={themePreference} onChange={setThemePreference} />
        <strong>{session.username}</strong>
        <small>{session.email}</small>
        <button className="nav-btn" disabled={busy} onClick={() => { void api.logout().catch(() => {}); }}>
          <LogOut size={18} />Cerrar sesi�n
        </button>
      </div>
    </aside>
  );
}
