import type { ReactNode } from "react";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import type { ThemePreference, Tab } from "../types";

interface MainLayoutProps {
  session: any;
  tab: Tab;
  setTab: (t: Tab) => void;
  setPage: (p: number) => void;
  setNotice: (n: string) => void;
  loading: boolean;
  busy: boolean;
  themePreference: ThemePreference;
  setThemePreference: (t: ThemePreference) => void;
  load: () => void;
  error: string;
  notice: string;
  children: ReactNode;
}

export function MainLayout(props: MainLayoutProps) {
  return (
    <div className="container">
      <Sidebar
        session={props.session}
        tab={props.tab}
        setTab={props.setTab}
        setPage={props.setPage}
        setNotice={props.setNotice}
        loading={props.loading}
        busy={props.busy}
        themePreference={props.themePreference}
        setThemePreference={props.setThemePreference}
      />
      <main className="main-content">
        <Topbar
          tab={props.tab}
          themePreference={props.themePreference}
          setThemePreference={props.setThemePreference}
          loading={props.loading}
          busy={props.busy}
          load={props.load}
        />
        <div className="content-scroll">
            {props.error && <div className="alert error" role="alert">{props.error}</div>}
            {props.notice && <div className="alert success" role="status">{props.notice}</div>}
            {props.loading && <p role="status" className="loading-message">Cargando informaci�n�</p>}
            {props.children}
        </div>
      </main>
    </div>
  );
}
