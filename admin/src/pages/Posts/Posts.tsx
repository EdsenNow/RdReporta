import type { ReactNode } from "react";
import type { CategoryItem, PostItem, PostStatus } from "../../api/client";

interface PostsProps {
  isDashboard?: boolean;
  posts: PostItem[];
  loading: boolean;
  error: string;
  labels: Record<PostStatus, string>;
  categories: CategoryItem[];
  search: string;
  setSearch: (v: string) => void;
  status: string;
  setStatus: (v: string) => void;
  category: string;
  setCategory: (v: string) => void;
  setPage: (p: number) => void;
  setQuery: (q: string) => void;
  setSelected: (p: PostItem) => void;
  pagination?: ReactNode;
}

export function Posts({ isDashboard, posts, loading, error, labels, categories, search, setSearch, status, setStatus, category, setCategory, setPage, setQuery, setSelected, pagination }: PostsProps) {
  return (
    <section className="content-card">
      <div className="card-header">
        <h2>{isDashboard ? "�ltimas publicaciones" : "Bandeja de publicaciones"}</h2>
      </div>
      {!isDashboard && (
        <form className="filters" onSubmit={e => { e.preventDefault(); setPage(1); setQuery(search.trim()); }}>
          <input aria-label="Buscar publicaciones" placeholder="Buscar t�tulo o descripci�n" value={search} maxLength={150} onChange={e => setSearch(e.target.value)} />
          <select aria-label="Estado" disabled={loading} value={status} onChange={e => { setStatus(e.target.value); setPage(1); }}>
            <option value="">Todos los estados</option>
            {Object.entries(labels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
          <select aria-label="Categor�a" disabled={loading} value={category} onChange={e => { setCategory(e.target.value); setPage(1); }}>
            <option value="">Todas las categor�as</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
          <button className="btn btn-primary" disabled={loading}>Buscar</button>
        </form>
      )}
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>Incidencia</th>
              <th>Ubicaci�n</th>
              <th>Visualizaciones</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {!loading && !error && posts.length === 0 && <tr><td colSpan={5} className="empty-state">No hay publicaciones con estos filtros.</td></tr>}
            {posts.map(p => (
              <tr key={p.id}>
                <td><strong>{p.title}</strong><small>{p.categoryName} � {p.authorUsername}</small></td>
                <td>{p.municipality}<small>{p.province}</small></td>
                <td>{p.viewsCount}</td>
                <td><span className={`badge ${p.status === "Hidden" ? "badge-danger" : p.status === "Resolved" ? "badge-success" : "badge-active"}`}>{labels[p.status]}</span></td>
                <td><button className="btn btn-outline btn-sm" onClick={() => setSelected(p)}>Ver detalle</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {!isDashboard && pagination}
    </section>
  );
}
