import { useCallback, useEffect, useState } from "react";
import { X } from "lucide-react";
import { api, getSession, imageUrl } from "./api/client";
import type { CategoryItem, ModerationReportItem, PostItem, PostStatus, Stats, UserItem } from "./api/client";
import { Modal } from "./components/Modal";
import type { Tab, ThemePreference } from "./types";

import { MainLayout } from "./layouts/MainLayout";
import { Login } from "./pages/Login/Login";
import { Dashboard } from "./pages/Dashboard/Dashboard";
import { Posts } from "./pages/Posts/Posts";
import { Moderation } from "./pages/Moderation/Moderation";
import { Categories } from "./pages/Categories/Categories";
import { Users } from "./pages/Users/Users";

const themeStorageKey = "rdreporta.theme";
const labels: Record<PostStatus, string> = { Active: "Activa", Resolved: "Resuelta", Hidden: "Oculta", Archived: "Archivada" };
const emptyCategory = { name: "", slug: "", description: "", iconName: "alert-circle", colorHex: "#31748F", displayOrder: 1 };
const message = (e: unknown) => e instanceof Error ? e.message : "No se pudo conectar con el servidor.";

export default function App() {
  const [themePreference, setThemePreference] = useState<ThemePreference>(() => {
    const saved = localStorage.getItem(themeStorageKey);
    return saved === "light" || saved === "system" ? saved : "dark";
  });
  const [session, setSession] = useState(getSession);
  const [tab, setTab] = useState<Tab>("dashboard");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [stats, setStats] = useState<Stats | null>(null);
  const [posts, setPosts] = useState<PostItem[]>([]);
  const [reports, setReports] = useState<ModerationReportItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [users, setUsers] = useState<UserItem[]>([]);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState("");
  const [category, setCategory] = useState("");
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [userSearch, setUserSearch] = useState("");
  const [userQuery, setUserQuery] = useState("");
  const [selected, setSelected] = useState<PostItem | null>(null);
  const [editor, setEditor] = useState<(typeof emptyCategory & { id?: number }) | null>(null);
  const [resolution, setResolution] = useState<{ report: ModerationReportItem; hide: boolean } | null>(null);
  const [notes, setNotes] = useState("");

  useEffect(() => {
    const media = window.matchMedia("(prefers-color-scheme: dark)");
    const applyTheme = () => {
      const resolved = themePreference === "system" ? (media.matches ? "dark" : "light") : themePreference;
      document.documentElement.dataset.theme = resolved;
      document.documentElement.style.colorScheme = resolved;
      localStorage.setItem(themeStorageKey, themePreference);
    };
    applyTheme();
    media.addEventListener("change", applyTheme);
    return () => media.removeEventListener("change", applyTheme);
  }, [themePreference]);

  useEffect(() => {
    const ended = () => { setSession(null); setStats(null); setPosts([]); setReports([]); setSelected(null); setEditor(null); setResolution(null); };
    window.addEventListener("session-ended", ended);
    return () => window.removeEventListener("session-ended", ended);
  }, []);

  const load = useCallback(async () => {
    if (!session) return;
    setLoading(true); setError("");
    try {
      const [summary, catalog] = await Promise.all([api.getStats(), api.getCategories()]);
      setStats(summary); setCategories(catalog);
      if (tab === "posts" || tab === "dashboard") {
        const params = new URLSearchParams({ page: String(tab === "dashboard" ? 1 : page), pageSize: "20" });
        if (tab === "posts") {
          if (status) params.set("status", status);
          if (category) params.set("categoryId", category);
          if (query) params.set("search", query);
        }
        const data = await api.getPosts(params); setPosts(data.items); setTotal(data.totalCount);
      }
      if (tab === "moderation") {
        const data = await api.getModerationReports(page); setReports(data.items); setTotal(data.totalCount);
      }
      if (tab === "users" && session.roles.includes("Administrador")) {
        const params = new URLSearchParams({ page: String(page), pageSize: "20" });
        if (userQuery) params.set("search", userQuery);
        const data = await api.getUsers(params); setUsers(data.items); setTotal(data.totalCount);
      }
    } catch (e) { setError(message(e)); } finally { setLoading(false); }
  }, [session, tab, page, status, category, query, userQuery]);

  useEffect(() => {
    const timer = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  async function act(work: () => Promise<unknown>, success: string) {
    setBusy(true); setError(""); setNotice("");
    try { await work(); setNotice(success); setEditor(null); setResolution(null); await load(); }
    catch (e) { setError(message(e)); }
    finally { setBusy(false); }
  }

  const pagination = (
    <div className="pagination">
      <button className="btn btn-outline" disabled={page <= 1 || loading} onClick={() => setPage(page - 1)}>Anterior</button>
      <span>P�gina {page} � {total} resultados</span>
      <button className="btn btn-outline" disabled={page * 20 >= total || loading} onClick={() => setPage(page + 1)}>Siguiente</button>
    </div>
  );

  if (!session) return (
    <Login
      themePreference={themePreference} setThemePreference={setThemePreference}
      email={email} setEmail={setEmail} password={password} setPassword={setPassword}
      error={error} busy={busy}
      onSubmit={async e => {
        e.preventDefault(); setBusy(true); setError("");
        try { setSession(await api.login(email.trim(), password)); setPassword(""); }
        catch (e) { setError(message(e)); } finally { setBusy(false); }
      }}
    />
  );

  return (
    <MainLayout
      session={session} tab={tab} setTab={setTab} setPage={setPage} setNotice={setNotice}
      loading={loading} busy={busy} themePreference={themePreference} setThemePreference={setThemePreference}
      load={load} error={error} notice={notice}
    >
      {tab === "dashboard" && <Dashboard stats={stats} />}

      {(tab === "dashboard" || tab === "posts") && (
        <Posts
          isDashboard={tab === "dashboard"} posts={posts} loading={loading} error={error}
          labels={labels} categories={categories} search={search} setSearch={setSearch}
          status={status} setStatus={setStatus} category={category} setCategory={setCategory}
          setPage={setPage} setQuery={setQuery} setSelected={setSelected} pagination={pagination}
        />
      )}

      {tab === "moderation" && (
        <Moderation
          reports={reports} loading={loading} error={error} busy={busy} act={act}
          setSelectedByReport={async (postId) => setSelected(await api.getPost(postId))}
          setResolution={setResolution} setNotes={setNotes} pagination={pagination}
        />
      )}

      {tab === "categories" && (
        <Categories categories={categories} session={session} setEditor={setEditor} emptyCategory={emptyCategory} />
      )}

      {tab === "users" && session.roles.includes("Administrador") && (
        <Users
          users={users} loading={loading} error={error} busy={busy}
          userSearch={userSearch} setUserSearch={setUserSearch} setPage={setPage}
          setUserQuery={setUserQuery} act={act} api={api} pagination={pagination}
        />
      )}

      {selected && (
        <Modal label="Detalle de publicaci�n" busy={busy} onClose={() => setSelected(null)}>
          <section className="modal-content">
            <div className="modal-header">
                <h2>{selected.title}</h2>
                <button className="modal-close btn btn-outline btn-icon" disabled={busy} aria-label="Cerrar detalle" onClick={() => setSelected(null)}><X size={20} /></button>
            </div>
            <p className="modal-desc">{selected.description}</p>
            <div className="modal-meta">
                <p>{selected.municipality}, {selected.province}</p>
                <small>{selected.latitude}, {selected.longitude} � {new Date(selected.createdAt).toLocaleString("es-DO")}</small>
            </div>
            <div className="photo-grid">
              {selected.images.map(url => <img key={url} src={imageUrl(url)} alt="Evidencia" />)}
            </div>
            <label>
              Estado
              <select value={selected.status} disabled={busy} onChange={e => { const next = e.target.value as PostStatus; void act(async () => { await api.setStatus(selected.id, next); setSelected({ ...selected, status: next }); }, "Estado actualizado."); }}>
                {Object.entries(labels).map(([k, v]) => <option value={k} key={k}>{v}</option>)}
              </select>
            </label>
            {error && <p className="alert error" role="alert">{error}</p>}
          </section>
        </Modal>
      )}

      {editor && (
        <Modal label="Editar categor�a" busy={busy} onClose={() => setEditor(null)}>
          <form className="modal-content" onSubmit={e => { e.preventDefault(); void act(() => api.saveCategory(editor, editor.id), "Categor�a guardada."); }}>
            <div className="modal-header">
                <h2>{editor.id ? "Editar categor�a" : "Nueva categor�a"}</h2>
            </div>
            <label>Nombre<input required maxLength={50} value={editor.name} onChange={e => setEditor({ ...editor, name: e.target.value })} /></label>
            <label>Identificador<input required pattern="[a-z0-9]+(-[a-z0-9]+)*" maxLength={60} value={editor.slug} placeholder="alumbrado-publico" onChange={e => setEditor({ ...editor, slug: e.target.value })} /></label>
            <label>Descripci�n<textarea value={editor.description} onChange={e => setEditor({ ...editor, description: e.target.value })} /></label>
            <label>�cono<input required maxLength={50} value={editor.iconName} onChange={e => setEditor({ ...editor, iconName: e.target.value })} /></label>
            <label>Color<input type="color" value={editor.colorHex} onChange={e => setEditor({ ...editor, colorHex: e.target.value })} /></label>
            <label>Orden<input type="number" required min={0} value={editor.displayOrder} onChange={e => setEditor({ ...editor, displayOrder: Number(e.target.value) })} /></label>
            {error && <p className="alert error" role="alert">{error}</p>}
            <div className="row-actions">
              <button type="button" className="btn btn-outline" disabled={busy} onClick={() => setEditor(null)}>Cancelar</button>
              <button className="btn btn-primary" disabled={busy}>Guardar</button>
            </div>
          </form>
        </Modal>
      )}

      {resolution && (
        <Modal label="Resolver denuncia" busy={busy} onClose={() => setResolution(null)}>
          <form className="modal-content" onSubmit={e => { e.preventDefault(); void act(() => api.resolve(resolution.report.id, resolution.hide, notes), "Denuncia resuelta."); }}>
            <div className="modal-header">
                <h2>{resolution.hide ? "Ocultar publicaci�n" : "Descartar denuncia"}</h2>
            </div>
            <p className="modal-desc">{resolution.report.postTitle}</p>
            <label>Notas de la revisi�n<textarea required maxLength={2000} value={notes} onChange={e => setNotes(e.target.value)} /></label>
            {error && <p className="alert error" role="alert">{error}</p>}
            <div className="row-actions">
              <button type="button" className="btn btn-outline" disabled={busy} onClick={() => setResolution(null)}>Cancelar</button>
              <button className="btn btn-primary" disabled={busy}>Confirmar resoluci�n</button>
            </div>
          </form>
        </Modal>
      )}
    </MainLayout>
  );
}
