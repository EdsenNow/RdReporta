import { useState, useEffect } from 'react';
import { 
  LayoutDashboard, 
  AlertTriangle, 
  FileText, 
  Tag, 
  ShieldCheck, 
  RefreshCw, 
  MapPin, 
  CheckCircle2, 
  Eye,
  ThumbsUp
} from 'lucide-react';
import { api } from './api/client';
import type { PostItem, CategoryItem, ModerationReportItem } from './api/client';

export default function App() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'posts' | 'moderation' | 'categories'>('dashboard');
  const [posts, setPosts] = useState<PostItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [reports, setReports] = useState<ModerationReportItem[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [fetchedPosts, fetchedCategories, fetchedReports] = await Promise.all([
        api.getRecentPosts(),
        api.getCategories(),
        api.getModerationReports()
      ]);
      setPosts(fetchedPosts);
      setCategories(fetchedCategories);
      setReports(fetchedReports);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalConfirmations = posts.reduce((acc, p) => acc + (p.confirmationsCount || 0), 0);
  const totalReactions = posts.reduce((acc, p) => acc + (p.reactionsCount || 0), 0);

  return (
    <div className="container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="logo-container">
          <div className="logo-badge">RD</div>
          <div>
            <h2 style={{ fontSize: '18px', fontWeight: 'bold' }}>RDReporta</h2>
            <p style={{ fontSize: '12px', color: '#64748b' }}>Panel Administrativo</p>
          </div>
        </div>

        <nav className="nav-links">
          <button 
            className={`nav-btn ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <LayoutDashboard size={18} />
            Dashboard
          </button>
          <button 
            className={`nav-btn ${activeTab === 'posts' ? 'active' : ''}`}
            onClick={() => setActiveTab('posts')}
          >
            <FileText size={18} />
            Publicaciones ({posts.length})
          </button>
          <button 
            className={`nav-btn ${activeTab === 'moderation' ? 'active' : ''}`}
            onClick={() => setActiveTab('moderation')}
          >
            <AlertTriangle size={18} />
            Moderación ({reports.length})
          </button>
          <button 
            className={`nav-btn ${activeTab === 'categories' ? 'active' : ''}`}
            onClick={() => setActiveTab('categories')}
          >
            <Tag size={18} />
            Categorías ({categories.length})
          </button>
        </nav>

        <div style={{ marginTop: 'auto', borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: '#1e3a8a', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
              AD
            </div>
            <div>
              <p style={{ fontSize: '13px', fontWeight: '600' }}>Admin General</p>
              <p style={{ fontSize: '11px', color: '#94a3b8' }}>admin@rdreporta.do</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <header className="topbar">
          <div>
            <h1 style={{ fontSize: '24px', fontWeight: '700' }}>
              {activeTab === 'dashboard' && 'Resumen Operativo'}
              {activeTab === 'posts' && 'Gestión de Publicaciones'}
              {activeTab === 'moderation' && 'Cola de Reportes y Moderación'}
              {activeTab === 'categories' && 'Catálogo de Categorías Maestras'}
            </h1>
            <p style={{ color: '#64748b', fontSize: '14px', marginTop: '4px' }}>
              Supervisión de incidencias ciudadanas en la República Dominicana
            </p>
          </div>

          <button className="btn btn-outline" onClick={loadData} disabled={loading} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <RefreshCw size={16} className={loading ? 'spin' : ''} />
            Actualizar
          </button>
        </header>

        {/* Dashboard Tab */}
        {activeTab === 'dashboard' && (
          <div>
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-header">
                  <span>Reportes Totales</span>
                  <FileText size={18} color="#2563eb" />
                </div>
                <div className="stat-value">{posts.length}</div>
              </div>

              <div className="stat-card">
                <div className="stat-header">
                  <span>Confirmaciones Ciudadanas</span>
                  <CheckCircle2 size={18} color="#16a34a" />
                </div>
                <div className="stat-value">{totalConfirmations}</div>
              </div>

              <div className="stat-card">
                <div className="stat-header">
                  <span>Reacciones Generadas</span>
                  <ThumbsUp size={18} color="#d97706" />
                </div>
                <div className="stat-value">{totalReactions}</div>
              </div>

              <div className="stat-card">
                <div className="stat-header">
                  <span>Denuncias Pendientes</span>
                  <AlertTriangle size={18} color="#dc2626" />
                </div>
                <div className="stat-value">{reports.length}</div>
              </div>
            </div>

            <div className="content-card">
              <div className="card-header">
                <h3 style={{ fontSize: '16px', fontWeight: '600' }}>Últimas Incidencias Reportadas</h3>
              </div>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Categoría</th>
                    <th>Título</th>
                    <th>Ubicación</th>
                    <th>Autor</th>
                    <th>Confirmaciones</th>
                    <th>Estado</th>
                  </tr>
                </thead>
                <tbody>
                  {posts.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', color: '#64748b', padding: '32px' }}>
                        No hay publicaciones registradas aún o el backend está iniciando.
                      </td>
                    </tr>
                  ) : (
                    posts.slice(0, 5).map((p) => (
                      <tr key={p.id}>
                        <td>
                          <span style={{ 
                            background: p.categoryColor + '20', 
                            color: p.categoryColor, 
                            fontWeight: '600', 
                            padding: '4px 8px', 
                            borderRadius: '4px',
                            fontSize: '12px'
                          }}>
                            {p.categoryName}
                          </span>
                        </td>
                        <td style={{ fontWeight: '500' }}>{p.title}</td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#64748b' }}>
                            <MapPin size={14} />
                            {p.municipality}, {p.province}
                          </div>
                        </td>
                        <td>@{p.authorUsername}</td>
                        <td style={{ fontWeight: '600', color: '#16a34a' }}>
                          ✓ {p.confirmationsCount}
                        </td>
                        <td>
                          <span className={`badge ${p.status === 'Active' ? 'badge-active' : 'badge-danger'}`}>
                            {p.status}
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Posts Tab */}
        {activeTab === 'posts' && (
          <div className="content-card">
            <div className="card-header">
              <h3 style={{ fontSize: '16px', fontWeight: '600' }}>Listado Completo de Publicaciones</h3>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Categoría</th>
                  <th>Título & Descripción</th>
                  <th>Ubicación (RD)</th>
                  <th>Métricas</th>
                  <th>Estado</th>
                </tr>
              </thead>
              <tbody>
                {posts.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', color: '#64748b', padding: '32px' }}>
                      No se encontraron reportes.
                    </td>
                  </tr>
                ) : (
                  posts.map((p) => (
                    <tr key={p.id}>
                      <td style={{ color: '#64748b', whiteSpace: 'nowrap' }}>
                        {new Date(p.createdAt).toLocaleDateString()}
                      </td>
                      <td>
                        <span style={{ 
                          background: p.categoryColor + '20', 
                          color: p.categoryColor, 
                          fontWeight: '600', 
                          padding: '4px 8px', 
                          borderRadius: '4px',
                          fontSize: '12px'
                        }}>
                          {p.categoryName}
                        </span>
                      </td>
                      <td>
                        <p style={{ fontWeight: '600' }}>{p.title}</p>
                        <p style={{ fontSize: '13px', color: '#64748b' }}>{p.description}</p>
                      </td>
                      <td>
                        <p style={{ fontWeight: '500' }}>{p.municipality}</p>
                        <p style={{ fontSize: '12px', color: '#64748b' }}>{p.province}</p>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: '12px', fontSize: '12px', color: '#475569' }}>
                          <span><Eye size={12} /> {p.viewsCount}</span>
                          <span><ThumbsUp size={12} /> {p.reactionsCount}</span>
                          <span style={{ color: '#16a34a', fontWeight: 'bold' }}>✓ {p.confirmationsCount}</span>
                        </div>
                      </td>
                      <td>
                        <span className={`badge ${p.status === 'Active' ? 'badge-active' : 'badge-danger'}`}>
                          {p.status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Moderation Tab */}
        {activeTab === 'moderation' && (
          <div className="content-card">
            <div className="card-header">
              <h3 style={{ fontSize: '16px', fontWeight: '600' }}>Cola de Denuncias Pendientes</h3>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Publicación</th>
                  <th>Motivo</th>
                  <th>Detalle del Denunciante</th>
                  <th>Estado</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {reports.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', color: '#16a34a', padding: '32px' }}>
                      <ShieldCheck size={32} style={{ margin: '0 auto 8px', display: 'block' }} />
                      No hay denuncias pendientes de revisión.
                    </td>
                  </tr>
                ) : (
                  reports.map((r) => (
                    <tr key={r.id}>
                      <td style={{ color: '#64748b' }}>{new Date(r.createdAt).toLocaleDateString()}</td>
                      <td style={{ fontWeight: '600' }}>{r.postTitle}</td>
                      <td><span className="badge badge-pending">{r.reason}</span></td>
                      <td style={{ color: '#475569' }}>{r.description || 'Sin comentarios adicionales'}</td>
                      <td><span className="badge badge-pending">{r.status}</span></td>
                      <td>
                        <button className="btn btn-outline" style={{ marginRight: '8px' }}>Descartar</button>
                        <button className="btn btn-primary" style={{ background: '#dc2626' }}>Ocultar Post</button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Categories Tab */}
        {activeTab === 'categories' && (
          <div className="content-card">
            <div className="card-header">
              <h3 style={{ fontSize: '16px', fontWeight: '600' }}>Categorías de Incidencias en RD</h3>
              <button className="btn btn-primary">+ Nueva Categoría</button>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Orden</th>
                  <th>Nombre</th>
                  <th>Slug</th>
                  <th>Descripción</th>
                  <th>Ícono / Color</th>
                </tr>
              </thead>
              <tbody>
                {categories.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', color: '#64748b', padding: '32px' }}>
                      Cargando categorías...
                    </td>
                  </tr>
                ) : (
                  categories.map((c) => (
                    <tr key={c.id}>
                      <td>#{c.displayOrder}</td>
                      <td style={{ fontWeight: '600' }}>{c.name}</td>
                      <td style={{ color: '#64748b' }}><code>{c.slug}</code></td>
                      <td style={{ color: '#475569' }}>{c.description}</td>
                      <td>
                        <span style={{ 
                          background: c.colorHex, 
                          color: '#fff', 
                          fontWeight: 'bold', 
                          padding: '4px 10px', 
                          borderRadius: '6px',
                          fontSize: '12px'
                        }}>
                          {c.iconName} ({c.colorHex})
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}
