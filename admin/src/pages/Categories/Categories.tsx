import type { CategoryItem } from "../../api/client";

interface CategoriesProps {
  categories: CategoryItem[];
  session: any;
  setEditor: (c: any) => void;
  emptyCategory: any;
}

export function Categories({ categories, session, setEditor, emptyCategory }: CategoriesProps) {
  return (
    <section className="content-card">
      <div className="card-header">
        <h2>Cat�logo de incidencias</h2>
        {session.roles.includes("Administrador") && <button className="btn btn-primary" onClick={() => setEditor({ ...emptyCategory })}>Nueva categor�a</button>}
      </div>
      <div className="category-grid">
        {categories.map(c => (
          <article key={c.id} className="category-card">
            <div className="category-color-wrapper">
                <span className="color-dot" style={{ background: c.colorHex }} />
            </div>
            <div className="category-info">
                <h3>{c.name}</h3>
                <p>{c.description}</p>
                <small>{c.slug} � Orden {c.displayOrder}</small>
            </div>
            {session.roles.includes("Administrador") && <button className="btn btn-outline btn-sm" onClick={() => setEditor({ ...c, description: c.description || "" })}>Editar</button>}
          </article>
        ))}
      </div>
    </section>
  );
}
