import { Sun, Moon, Monitor } from 'lucide-react';
import type { ThemePreference } from '../types';

interface ThemeSelectorProps {
  value: ThemePreference;
  onChange: (theme: ThemePreference) => void;
  compact?: boolean;
}

export function ThemeSelector({ value, onChange, compact }: ThemeSelectorProps) {
  const options = [
    ['light', 'Claro', Sun],
    ['dark', 'Oscuro', Moon],
    ['system', 'Sistema', Monitor],
  ] as const;

  return (
    <div className={`theme-selector ${compact ? 'compact' : ''}`.trim()} role="group" aria-label="Tema de la interfaz">
      {options.map(([theme, label, Icon]) => (
        <button
          type="button"
          key={theme}
          className={value === theme ? 'selected' : ''}
          aria-pressed={value === theme}
          title={`Tema ${label}`}
          onClick={() => onChange(theme as ThemePreference)}
        >
          <Icon size={15} />
          <span>{label}</span>
        </button>
      ))}
    </div>
  );
}
