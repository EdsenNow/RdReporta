import type { FormEvent } from "react";
import { ThemeSelector } from "../../components/ThemeSelector";
import type { ThemePreference } from "../../types";

interface LoginProps {
  themePreference: ThemePreference;
  setThemePreference: (t: ThemePreference) => void;
  onSubmit: (e: FormEvent) => void;
  email: string;
  setEmail: (v: string) => void;
  password: string;
  setPassword: (v: string) => void;
  error: string;
  busy: boolean;
}

export function Login({ themePreference, setThemePreference, onSubmit, email, setEmail, password, setPassword, error, busy }: LoginProps) {
  return (
    <main className="login-shell">
      <div className="login-theme">
        <ThemeSelector value={themePreference} onChange={setThemePreference} />
      </div>
      <form className="login-card" onSubmit={onSubmit}>
        <div className="logo-badge">RD</div>
        <h1>RDReporta</h1>
        <p>Acceso al panel de administraci�n y moderaci�n</p>
        <label>
          Correo electr�nico
          <input type="email" autoComplete="username" value={email} onChange={e => setEmail(e.target.value)} required />
        </label>
        <label>
          Contrase�a
          <input type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required />
        </label>
        {error && <p className="alert error" role="alert">{error}</p>}
        <button className="btn btn-primary" disabled={busy}>
          {busy ? "Ingresando�" : "Iniciar sesi�n"}
        </button>
      </form>
    </main>
  );
}
