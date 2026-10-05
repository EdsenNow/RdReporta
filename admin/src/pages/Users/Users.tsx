import type { ReactNode } from "react";
import type { UserItem } from "../../api/client";
import { BadgeCheck } from "lucide-react";

interface UsersProps {
  users: UserItem[];
  loading: boolean;
  error: string;
  busy: boolean;
  userSearch: string;
  setUserSearch: (v: string) => void;
  setPage: (p: number) => void;
  setUserQuery: (q: string) => void;
  act: (work: () => Promise<unknown>, success: string) => void;
  api: any;
  pagination: ReactNode;
}

export function Users({ users, loading, error, busy, userSearch, setUserSearch, setPage, setUserQuery, act, api, pagination }: UsersProps) {
  return (
    <section className="content-card">
      <div className="card-header">
        <div>
          <h2>Perfiles ciudadanos</h2>
          <p>Selecciona qu� cuentas muestran la insignia oficial de RDReporta.</p>
        </div>
      </div>
      <form className="filters" onSubmit={e => { e.preventDefault(); setPage(1); setUserQuery(userSearch.trim()); }}>
        <input aria-label="Buscar perfiles" placeholder="Nombre, @usuario o correo" value={userSearch} maxLength={100} onChange={e => setUserSearch(e.target.value)} />
        <button className="btn btn-primary" disabled={loading}>Buscar</button>
      </form>
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>Perfil</th>
              <th>Correo</th>
              <th>Estado</th>
              <th>Acci�n</th>
            </tr>
          </thead>
          <tbody>
            {!loading && !error && users.length === 0 && <tr><td colSpan={4} className="empty-state">No se encontraron perfiles.</td></tr>}
            {users.map(user => (
              <tr key={user.id}>
                <td>
                  <strong>{user.displayName || user.username} {user.isVerified && <BadgeCheck size={16} className="verified-icon" aria-label="Perfil verificado" />}</strong>
                  <small>@{user.username}</small>
                </td>
                <td>{user.email}</td>
                <td><span className={`badge ${user.isVerified ? "badge-active" : ""}`}>{user.isVerified ? "Verificado" : "Sin verificar"}</span></td>
                <td>
                  <button className={`btn btn-sm ${user.isVerified ? "btn-outline" : "btn-primary"}`} disabled={busy} onClick={() => void act(() => api.setUserVerification(user.id, !user.isVerified), user.isVerified ? "Verificaci�n retirada." : "Perfil verificado.")}>
                    {user.isVerified ? "Retirar verificaci�n" : "Verificar perfil"}
                  </button>
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
