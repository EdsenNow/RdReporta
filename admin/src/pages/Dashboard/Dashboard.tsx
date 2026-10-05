import type { Stats } from "../../api/client";

export function Dashboard({ stats }: { stats: Stats | null }) {
  const items = [
    ["Reportes totales", stats?.totalPosts],
    ["Incidencias activas", stats?.activePosts],
    ["Resueltas", stats?.resolvedPosts],
    ["Visualizaciones", stats?.totalViews],
    ["Reacciones", stats?.totalReactions],
    ["Denuncias pendientes", stats?.pendingReports],
  ] as const;

  return (
    <div className="stats-grid">
      {items.map(([label, value]) => (
        <div className="stat-card" key={label}>
          <div className="stat-header">{label}</div>
          <div className="stat-value">{value ?? "�"}</div>
        </div>
      ))}
    </div>
  );
}
