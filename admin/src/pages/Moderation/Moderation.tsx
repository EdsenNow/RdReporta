import type { ReactNode } from "react";
import type { ModerationReportItem } from "../../api/client";

interface ModerationProps {
  reports: ModerationReportItem[];
  loading: boolean;
  error: string;
  busy: boolean;
  act: (work: () => Promise<unknown>, success: string) => void;
  setSelectedByReport: (postId: string) => Promise<void>;
  setResolution: (r: { report: ModerationReportItem; hide: boolean }) => void;
  setNotes: (n: string) => void;
  pagination: ReactNode;
}

export function Moderation({ reports, loading, error, busy, act, setSelectedByReport, setResolution, setNotes, pagination }: ModerationProps) {
  return (
    <section className="content-card">
      <div className="card-header">
        <h2>Denuncias pendientes</h2>
      </div>
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>Publicaci�n</th>
              <th>Motivo</th>
              <th>Denunciante</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {!loading && !error && reports.length === 0 && <tr><td colSpan={4} className="empty-state">No hay denuncias pendientes de revisi�n.</td></tr>}
            {reports.map(r => (
              <tr key={r.id}>
                <td>
                  <button className="btn btn-text" disabled={busy} onClick={() => { void act(async () => await setSelectedByReport(r.postId), ""); }}>
                    {r.postTitle}
                  </button>
                  <small>{new Date(r.createdAt).toLocaleString("es-DO")}</small>
                </td>
                <td>{r.reason}<small>{r.description}</small></td>
                <td>{r.reporterUsername}</td>
                <td className="row-actions">
                  <button className="btn btn-outline btn-sm" disabled={busy} onClick={() => { setResolution({ report: r, hide: false }); setNotes(""); }}>Descartar</button>
                  <button className="btn btn-danger btn-sm" disabled={busy} onClick={() => { setResolution({ report: r, hide: true }); setNotes(""); }}>Ocultar publicaci�n</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {pagination}
    </section>
  );
}
