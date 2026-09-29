import { useCallback, useEffect, useState } from 'react';
import { LayoutDashboard, FileText, AlertTriangle, Tag, RefreshCw, LogOut, X, Sun, Moon, Monitor, BadgeCheck } from 'lucide-react';
import { api, getSession, imageUrl } from './api/client';
import type { CategoryItem, ModerationReportItem, PostItem, PostStatus, Stats, UserItem } from './api/client';
import { Modal } from './components/Modal';

type Tab = 'dashboard' | 'posts' | 'moderation' | 'categories' | 'users';
type ThemePreference = 'light' | 'dark' | 'system';
const themeStorageKey = 'rdreporta.theme';
const labels: Record<PostStatus, string> = { Active: 'Activa', Resolved: 'Resuelta', Hidden: 'Oculta', Archived: 'Archivada' };
const emptyCategory = { name: '', slug: '', description: '', iconName: 'alert-circle', colorHex: '#31748F', displayOrder: 1 };
const message = (e: unknown) => e instanceof Error ? e.message : 'No se pudo conectar con el servidor.';

function ThemeSelector({ value, onChange, compact = false }: { value: ThemePreference; onChange: (theme: ThemePreference) => void; compact?: boolean }) {
  const options = [['light', 'Claro', Sun], ['dark', 'Oscuro', Moon], ['system', 'Sistema', Monitor]] as const;
  return <div className={`theme-selector ${compact ? 'compact' : ''}`} role="group" aria-label="Tema de la interfaz">{options.map(([theme, label, Icon]) => <button type="button" key={theme} className={value === theme ? 'selected' : ''} aria-pressed={value === theme} title={`Tema ${label.toLowerCase()}`} onClick={() => onChange(theme)}><Icon size={15} /><span>{label}</span></button>)}</div>;
}

export default function App() {
  const [themePreference, setThemePreference] = useState<ThemePreference>(() => {
    const saved = localStorage.getItem(themeStorageKey);
    return saved === 'light' || saved === 'system' ? saved : 'dark';
  });
  const [session, setSession] = useState(getSession);
  const [tab, setTab] = useState<Tab>('dashboard');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [stats, setStats] = useState<Stats | null>(null);
  const [posts, setPosts] = useState<PostItem[]>([]);
  const [reports, setReports] = useState<ModerationReportItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [users, setUsers] = useState<UserItem[]>([]);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [userSearch, setUserSearch] = useState('');
  const [userQuery, setUserQuery] = useState('');
  const [selected, setSelected] = useState<PostItem | null>(null);
  const [editor, setEditor] = useState<(typeof emptyCategory & { id?: number }) | null>(null);
  const [resolution, setResolution] = useState<{ report: ModerationReportItem; hide: boolean } | null>(null);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const applyTheme = () => {
      const resolved = themePreference === 'system' ? (media.matches ? 'dark' : 'light') : themePreference;
      document.documentElement.dataset.theme = resolved;
      document.documentElement.style.colorScheme = resolved;
      localStorage.setItem(themeStorageKey, themePreference);
    };
    applyTheme();
    media.addEventListener('change', applyTheme);
    return () => media.removeEventListener('change', applyTheme);
  }, [themePreference]);

  useEffect(() => {
    const ended = () => { setSession(null); setStats(null); setPosts([]); setReports([]); setSelected(null); setEditor(null); setResolution(null); };
    window.addEventListener('session-ended', ended);
    return () => window.removeEventListener('session-ended', ended);
  }, []);

  const load = useCallback(async () => {
    if (!session) return;
    setLoading(true); setError('');
    try {
      const [summary, catalog] = await Promise.all([api.getStats(), api.getCategories()]);
      setStats(summary); setCategories(catalog);
      if (tab === 'posts' || tab === 'dashboard') {
        const params = new URLSearchParams({ page: String(tab === 'dashboard' ? 1 : page), pageSize: '20' });
        if (tab === 'posts') {
          if (status) params.set('status', status);
          if (category) params.set('categoryId', category);
          if (query) params.set('search', query);
        }
        const data = await api.getPosts(params); setPosts(data.items); setTotal(data.totalCount);
      }
      if (tab === 'moderation') {
        const data = await api.getModerationReports(page); setReports(data.items); setTotal(data.totalCount);
      }
      if (tab === 'users' && session.roles.includes('Administrador')) {
        const params = new URLSearchParams({ page: String(page), pageSize: '20' });
        if (userQuery) params.set('search', userQuery);
        const data = await api.getUsers(params); setUsers(data.items); setTotal(data.totalCount);
      }
    } catch (e) { setError(message(e)); } finally { setLoading(false); }
  }, [session, tab, page, status, category, query, userQuery]);
  useEffect(() => {
    // The request synchronizes the view with the API whenever its filters change.
    const timer = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  async function act(work: () => Promise<unknown>, success: string) {
    setBusy(true); setError(''); setNotice('');
    try { await work(); setNotice(success); setEditor(null); setResolution(null); await load(); }
    catch (e) { setError(message(e)); }
    finally { setBusy(false); }
  }
  const pagination = <div className="pagination">
    <button className="btn btn-outline" disabled={page <= 1 || loading} onClick={() => setPage(page - 1)}>Anterior</button>
    <span>Página {page} · {total} resultados</span>
    <button className="btn btn-outline" disabled={page * 20 >= total || loading} onClick={() => setPage(page + 1)}>Siguiente</button>
  </div>;

  if (!session) return <main className="login-shell"><div className="login-theme"><ThemeSelector value={themePreference} onChange={setThemePreference} /></div><form className="login-card" onSubmit={async e => {
    e.preventDefault(); setBusy(true); setError('');
    try { setSession(await api.login(email.trim(), password)); setPassword(''); }
    catch (e) { setError(message(e)); } finally { setBusy(false); }
  }}>
    <div className="logo-badge">RD</div><h1>RDReporta</h1><p>Acceso al panel de administración y moderación</p>
    <label>Correo electrónico<input type="email" autoComplete="username" value={email} onChange={e => setEmail(e.target.value)} required /></label>
    <label>Contraseña<input type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required /></label>
    {error && <p className="alert error" role="alert">{error}</p>}
    <button className="btn btn-primary" disabled={busy}>{busy ? 'Ingresando…' : 'Iniciar sesión'}</button>
  </form></main>;

  return <div className="container">
    <aside className="sidebar"><div className="logo-container"><div className="logo-badge">RD</div><div><h2>RDReporta</h2><small>Panel administrativo</small></div></div>
      <nav className="nav-links">{([
        ['dashboard', 'Resumen', LayoutDashboard], ['posts', 'Publicaciones', FileText],
        ['moderation', 'Moderación', AlertTriangle], ['categories', 'Categorías', Tag],
        ...(session.roles.includes('Administrador') ? [['users', 'Verificaciones', BadgeCheck] as const] : []),
      ] as const).map(([value, label, Icon]) => <button key={value} className={`nav-btn ${tab === value ? 'active' : ''}`} disabled={loading || busy}
        onClick={() => { setTab(value); setPage(1); setNotice(''); }}><Icon size={18} />{label}</button>)}</nav>
      <div className="session-info"><ThemeSelector compact value={themePreference} onChange={setThemePreference} /><strong>{session.username}</strong><small>{session.email}</small>
        <button className="nav-btn" disabled={busy} onClick={() => { void api.logout().catch(() => {}); }}><LogOut size={18} />Cerrar sesión</button></div>
    </aside>
    <main className="main-content"><header className="topbar"><div><h1>{({ dashboard: 'Resumen operativo', posts: 'Publicaciones', moderation: 'Moderación ciudadana', categories: 'Categorías', users: 'Verificación de perfiles' })[tab]}</h1>
      <p>Información ciudadana de República Dominicana</p></div><div className="topbar-actions"><ThemeSelector compact value={themePreference} onChange={setThemePreference} /><button className="btn btn-outline" disabled={loading || busy} onClick={() => void load()}><RefreshCw size={16} /> Actualizar</button></div></header>
      {error && <div className="alert error" role="alert">{error}</div>}
      {notice && <div className="alert success" role="status">{notice}</div>}
      {loading && <p role="status" className="loading-message">Cargando información…</p>}
      {tab === 'dashboard' && <div className="stats-grid">{([
        ['Reportes totales', stats?.totalPosts], ['Incidencias activas', stats?.activePosts],
        ['Resueltas', stats?.resolvedPosts], ['Confirmaciones', stats?.totalConfirmations],
        ['Reacciones', stats?.totalReactions], ['Denuncias pendientes', stats?.pendingReports],
      ] as const).map(([label, value]) => <div className="stat-card" key={label}><div className="stat-header">{label}</div><div className="stat-value">{value ?? '—'}</div></div>)}</div>}

      {(tab === 'dashboard' || tab === 'posts') && <section className="content-card">
        <div className="card-header"><h2>{tab === 'dashboard' ? 'Últimas publicaciones' : 'Bandeja de publicaciones'}</h2></div>
        {tab === 'posts' && <form className="filters" onSubmit={e => { e.preventDefault(); setPage(1); setQuery(search.trim()); }}>
          <input aria-label="Buscar publicaciones" placeholder="Buscar título o descripción" value={search} maxLength={150} onChange={e => setSearch(e.target.value)} />
          <select aria-label="Estado" disabled={loading} value={status} onChange={e => { setStatus(e.target.value); setPage(1); }}><option value="">Todos los estados</option>{Object.entries(labels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select>
          <select aria-label="Categoría" disabled={loading} value={category} onChange={e => { setCategory(e.target.value); setPage(1); }}><option value="">Todas las categorías</option>{categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}</select>
          <button className="btn btn-primary" disabled={loading}>Buscar</button></form>}
        <div className="table-scroll"><table className="data-table"><thead><tr><th>Incidencia</th><th>Ubicación</th><th>Confirmaciones</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>
          {!loading && !error && posts.length === 0 && <tr><td colSpan={5} className="empty-state">No hay publicaciones con estos filtros.</td></tr>}
          {posts.map(p => <tr key={p.id}><td><strong>{p.title}</strong><small>{p.categoryName} · {p.authorUsername}</small></td><td>{p.municipality}<small>{p.province}</small></td><td>{p.confirmationsCount}</td>
            <td><span className={`badge ${p.status === 'Hidden' ? 'badge-danger' : 'badge-active'}`}>{labels[p.status]}</span></td>
            <td><button className="btn btn-outline" onClick={() => setSelected(p)}>Ver detalle</button></td></tr>)}
        </tbody></table></div>{tab === 'posts' && pagination}
      </section>}

      {tab === 'moderation' && <section className="content-card"><div className="card-header"><h2>Denuncias pendientes</h2></div><div className="table-scroll"><table className="data-table"><thead><tr><th>Publicación</th><th>Motivo</th><th>Denunciante</th><th>Acciones</th></tr></thead><tbody>
        {!loading && !error && reports.length === 0 && <tr><td colSpan={4} className="empty-state">No hay denuncias pendientes de revisión.</td></tr>}
        {reports.map(r => <tr key={r.id}><td><button className="btn btn-outline" disabled={busy} onClick={() => {
          void act(async () => setSelected(await api.getPost(r.postId)), '');
        }}>{r.postTitle}</button><small>{new Date(r.createdAt).toLocaleString('es-DO')}</small></td><td>{r.reason}<small>{r.description}</small></td><td>{r.reporterUsername}</td>
          <td className="row-actions"><button className="btn btn-outline" disabled={busy} onClick={() => { setResolution({ report: r, hide: false }); setNotes(''); }}>Descartar</button>
            <button className="btn btn-danger" disabled={busy} onClick={() => { setResolution({ report: r, hide: true }); setNotes(''); }}>Ocultar publicación</button></td></tr>)}
      </tbody></table></div>{pagination}</section>}

      {tab === 'categories' && <section className="content-card"><div className="card-header"><h2>Catálogo de incidencias</h2>
        {session.roles.includes('Administrador') && <button className="btn btn-primary" onClick={() => setEditor({ ...emptyCategory })}>Nueva categoría</button>}</div>
        <div className="category-grid">{categories.map(c => <article key={c.id} className="category-card"><span className="color-dot" style={{ background: c.colorHex }} /><h3>{c.name}</h3><p>{c.description}</p><small>{c.slug} · Orden {c.displayOrder}</small>
          {session.roles.includes('Administrador') && <button className="btn btn-outline" onClick={() => setEditor({ ...c, description: c.description || '' })}>Editar</button>}</article>)}</div></section>}

      {tab === 'users' && session.roles.includes('Administrador') && <section className="content-card">
        <div className="card-header"><div><h2>Perfiles ciudadanos</h2><p>Selecciona qué cuentas muestran la insignia oficial de RDReporta.</p></div></div>
        <form className="filters" onSubmit={e => { e.preventDefault(); setPage(1); setUserQuery(userSearch.trim()); }}>
          <input aria-label="Buscar perfiles" placeholder="Nombre, @usuario o correo" value={userSearch} maxLength={100} onChange={e => setUserSearch(e.target.value)} />
          <button className="btn btn-primary" disabled={loading}>Buscar</button>
        </form>
        <div className="table-scroll"><table className="data-table"><thead><tr><th>Perfil</th><th>Correo</th><th>Estado</th><th>Acción</th></tr></thead><tbody>
          {!loading && !error && users.length === 0 && <tr><td colSpan={4} className="empty-state">No se encontraron perfiles.</td></tr>}
          {users.map(user => <tr key={user.id}><td><strong>{user.displayName || user.username} {user.isVerified && <BadgeCheck size={16} aria-label="Perfil verificado" />}</strong><small>@{user.username}</small></td><td>{user.email}</td>
            <td><span className={`badge ${user.isVerified ? 'badge-active' : ''}`}>{user.isVerified ? 'Verificado' : 'Sin verificar'}</span></td>
            <td><button className={`btn ${user.isVerified ? 'btn-outline' : 'btn-primary'}`} disabled={busy} onClick={() => void act(() => api.setUserVerification(user.id, !user.isVerified), user.isVerified ? 'Verificación retirada.' : 'Perfil verificado.')}>{user.isVerified ? 'Retirar verificación' : 'Verificar perfil'}</button></td></tr>)}
        </tbody></table></div>{pagination}
      </section>}

      {selected && <Modal label="Detalle de publicación" busy={busy} onClose={() => setSelected(null)}><section className="modal-content"><button className="modal-close btn btn-outline" disabled={busy} aria-label="Cerrar detalle" onClick={() => setSelected(null)}><X size={20} /></button>
        <h2>{selected.title}</h2><p>{selected.description}</p><p>{selected.municipality}, {selected.province}</p><small>{selected.latitude}, {selected.longitude} · {new Date(selected.createdAt).toLocaleString('es-DO')}</small>
        <div className="photo-grid">{selected.images.map(url => <img key={url} src={imageUrl(url)} alt="Evidencia de la incidencia" />)}</div>
        <label>Estado<select value={selected.status} disabled={busy} onChange={e => { const next = e.target.value as PostStatus; void act(async () => { await api.setStatus(selected.id, next); setSelected({ ...selected, status: next }); }, 'Estado actualizado.'); }}>{Object.entries(labels).map(([k, v]) => <option value={k} key={k}>{v}</option>)}</select></label>
        {error && <p className="alert error" role="alert">{error}</p>}
      </section></Modal>}

      {editor && <Modal label="Editar categoría" busy={busy} onClose={() => setEditor(null)}><form className="modal-content" onSubmit={e => { e.preventDefault(); void act(() => api.saveCategory(editor, editor.id), 'Categoría guardada.'); }}>
        <h2>{editor.id ? 'Editar categoría' : 'Nueva categoría'}</h2>
        <label>Nombre<input required maxLength={50} value={editor.name} onChange={e => setEditor({ ...editor, name: e.target.value })} /></label>
        <label>Identificador<input required pattern="[a-z0-9]+(-[a-z0-9]+)*" maxLength={60} value={editor.slug} placeholder="alumbrado-publico" onChange={e => setEditor({ ...editor, slug: e.target.value })} /></label>
        <label>Descripción<textarea value={editor.description} onChange={e => setEditor({ ...editor, description: e.target.value })} /></label>
        <label>Ícono<input required maxLength={50} value={editor.iconName} onChange={e => setEditor({ ...editor, iconName: e.target.value })} /></label>
        <label>Color<input type="color" value={editor.colorHex} onChange={e => setEditor({ ...editor, colorHex: e.target.value })} /></label>
        <label>Orden<input type="number" required min={0} value={editor.displayOrder} onChange={e => setEditor({ ...editor, displayOrder: Number(e.target.value) })} /></label>
        {error && <p className="alert error" role="alert">{error}</p>}
        <div className="row-actions"><button type="button" className="btn btn-outline" disabled={busy} onClick={() => setEditor(null)}>Cancelar</button><button className="btn btn-primary" disabled={busy}>Guardar</button></div>
      </form></Modal>}

      {resolution && <Modal label="Resolver denuncia" busy={busy} onClose={() => setResolution(null)}><form className="modal-content" onSubmit={e => { e.preventDefault(); void act(() => api.resolve(resolution.report.id, resolution.hide, notes), 'Denuncia resuelta.'); }}>
        <h2>{resolution.hide ? 'Ocultar publicación' : 'Descartar denuncia'}</h2><p>{resolution.report.postTitle}</p>
        <label>Notas de la revisión<textarea required maxLength={2000} value={notes} onChange={e => setNotes(e.target.value)} /></label>
        {error && <p className="alert error" role="alert">{error}</p>}
        <div className="row-actions"><button type="button" className="btn btn-outline" disabled={busy} onClick={() => setResolution(null)}>Cancelar</button><button className="btn btn-primary" disabled={busy}>Confirmar resolución</button></div>
      </form></Modal>}
    </main>
  </div>;
}
