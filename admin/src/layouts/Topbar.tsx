import { RefreshCw } from "lucide-react";
import { ThemeSelector } from "../components/ThemeSelector";
import type { ThemePreference, Tab } from "../types";

interface TopbarProps {
  tab: Tab;
  themePreference: ThemePreference;
  setThemePreference: (t: ThemePreference) => void;
  loading: boolean;
  busy: boolean;
  load: () => void;
}

export function Topbar({ tab, themePreference, setThemePreference, loading, busy, load }: TopbarProps) {
  const titles: Record<Tab, string> = {
    dashboard: "Resumen operativo",
    posts: "Publicaciones",
    moderation: "Moderaci�n ciudadana",
    categories: "Categor�as",
    users: "Verificaci�n de perfiles",
  };

  return (
    <header className="topbar">
      <div>
        <h1>{titles[tab]}</h1>
        <p>Informaci�n ciudadana de Rep�blica Dominicana</p>
      </div>
      <div className="topbar-actions">
        <ThemeSelector compact value={themePreference} onChange={setThemePreference} />
        <button className="btn btn-outline btn-refresh" disabled={loading || busy} onClick={() => void load()}>
          <RefreshCw size={16} className={loading ? "spin" : ""} /> Actualizar
        </button>
      </div>
    </header>
  );
}
